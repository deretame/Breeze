use std::{future::Future, path::PathBuf, time::Duration};

use axum::{
    Json, Router,
    body::Body,
    extract::{Path as AxumPath, State},
    http::{HeaderMap, StatusCode, header::CONTENT_TYPE},
    response::Response,
    routing::{delete, get, post},
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::{app_state::AppState, db::DownloadTaskRecord};

use super::{
    auth::{current_user, now_millis},
    error::ApiError,
    plugin_api::{invoke_bytes_for_user_with_task_group, invoke_json_for_user_with_task_group},
};

const DOWNLOAD_MAX_ATTEMPTS: usize = 3;
const DOWNLOAD_RETRY_DELAY: Duration = Duration::from_millis(250);

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/tasks", get(list_tasks).post(create_task))
        .route("/tasks/{task_id}", get(get_task))
        .route("/tasks/{task_id}/cancel", post(cancel_task))
        .route("/comics/{comic_key}/manifest", get(get_manifest))
        .route("/comics/{comic_key}", delete(delete_comic))
        .route("/assets/{asset_id}", get(get_asset))
}

#[derive(Deserialize)]
struct CreateTaskRequest {
    plugin_id: String,
    comic_id: String,
    #[serde(default)]
    chapter_ids: Vec<String>,
    #[serde(default)]
    options: Value,
}

#[derive(Serialize)]
struct TaskListResponse {
    items: Vec<TaskResponse>,
}

#[derive(Serialize)]
struct TaskResponse {
    task_id: String,
    status: String,
    progress: i64,
    payload: Value,
    error: Option<String>,
    updated_at: String,
}

#[derive(Serialize)]
struct ManifestResponse {
    comic_key: String,
    manifest: Value,
}

async fn create_task(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(request): Json<CreateTaskRequest>,
) -> Result<Json<TaskResponse>, ApiError> {
    let user = current_user(&state, &headers).await?;
    validate_task_request(&request)?;
    let user_id = user.id.clone();
    let plugin_id = request.plugin_id.clone();
    if state
        .database
        .run_blocking(move |database| database.find_user_plugin(&user_id, &plugin_id))
        .await?
        .is_none()
    {
        return Err(ApiError::NotFound);
    }

    let task_id = Uuid::new_v4().to_string();
    let payload = json!({
        "plugin_id": request.plugin_id,
        "comic_id": request.comic_id,
        "chapter_ids": request.chapter_ids,
        "options": request.options,
    });
    let user_id = user.id.clone();
    let payload_json = serde_json::to_string(&payload)?;
    let updated_at = now_millis();
    let task_id_for_database = task_id.clone();
    let task = state
        .database
        .run_blocking(move |database| {
            database.create_download_task(
                &user_id,
                &task_id_for_database,
                &payload_json,
                &updated_at,
            )
        })
        .await?;
    state.websocket_hub.publish_event(
        &user.id,
        "downloads.status",
        json!({
            "task_id": task_id,
            "status": task.status,
            "progress": task.progress,
            "payload": payload,
        }),
    );
    let worker_state = state.clone();
    let worker_user_id = user.id;
    let worker_task_id = task_id.clone();
    tokio::spawn(async move {
        run_task(worker_state, worker_user_id, worker_task_id).await;
    });
    Ok(Json(to_task_response(task)?))
}

async fn list_tasks(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<TaskListResponse>, ApiError> {
    let user = current_user(&state, &headers).await?;
    let user_id = user.id.clone();
    let items = state
        .database
        .run_blocking(move |database| database.list_download_tasks(&user_id))
        .await?
        .into_iter()
        .map(to_task_response)
        .collect::<Result<Vec<_>, _>>()?;
    Ok(Json(TaskListResponse { items }))
}

async fn get_task(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(task_id): AxumPath<String>,
) -> Result<Json<TaskResponse>, ApiError> {
    let user = current_user(&state, &headers).await?;
    let user_id = user.id.clone();
    let task_id_for_database = task_id.clone();
    let task = state
        .database
        .run_blocking(move |database| database.find_download_task(&user_id, &task_id_for_database))
        .await?
        .ok_or(ApiError::NotFound)?;
    Ok(Json(to_task_response(task)?))
}

async fn cancel_task(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(task_id): AxumPath<String>,
) -> Result<Json<TaskResponse>, ApiError> {
    let user = current_user(&state, &headers).await?;
    let user_id = user.id.clone();
    let task_id_for_database = task_id.clone();
    let task = state
        .database
        .run_blocking(move |database| database.find_download_task(&user_id, &task_id_for_database))
        .await?
        .ok_or(ApiError::NotFound)?;
    if matches!(task.status.as_str(), "completed" | "failed" | "cancelled") {
        return Ok(Json(to_task_response(task)?));
    }
    state.plugin_runtime.cancel_task_group(&user.id, &task_id);
    update_status(
        &state,
        &user.id,
        &task_id,
        "cancelling",
        task.progress,
        None,
    )
    .await?;
    let user_id = user.id.clone();
    let task_id_for_database = task_id.clone();
    let task = state
        .database
        .run_blocking(move |database| database.find_download_task(&user_id, &task_id_for_database))
        .await?
        .ok_or(ApiError::NotFound)?;
    Ok(Json(to_task_response(task)?))
}

async fn get_manifest(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(comic_key): AxumPath<String>,
) -> Result<Json<ManifestResponse>, ApiError> {
    let user = current_user(&state, &headers).await?;
    let user_id = user.id.clone();
    let comic_key_for_database = comic_key.clone();
    let manifest = state
        .database
        .run_blocking(move |database| database.find_manifest(&user_id, &comic_key_for_database))
        .await?
        .ok_or(ApiError::NotFound)?;
    Ok(Json(ManifestResponse {
        comic_key,
        manifest: serde_json::from_str(&manifest)?,
    }))
}

async fn get_asset(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(asset_id): AxumPath<String>,
) -> Result<Response, ApiError> {
    let user = current_user(&state, &headers).await?;
    let user_id = user.id.clone();
    let asset_id_for_database = asset_id.clone();
    let asset = state
        .database
        .run_blocking(move |database| database.find_asset(&user_id, &asset_id_for_database))
        .await?
        .ok_or(ApiError::NotFound)?;
    let root = std::fs::canonicalize(state.config.asset_root()).map_err(|_| ApiError::NotFound)?;
    let path =
        std::fs::canonicalize(root.join(&asset.storage_key)).map_err(|_| ApiError::NotFound)?;
    if !path.starts_with(&root) {
        return Err(ApiError::Forbidden);
    }
    let bytes = tokio::fs::read(path).await?;
    Response::builder()
        .status(StatusCode::OK)
        .header(CONTENT_TYPE, asset.media_type)
        .header("content-length", asset.byte_size)
        .header("etag", format!("\"{}\"", asset.content_hash))
        .header("cache-control", "private, max-age=3600")
        .body(Body::from(bytes))
        .map_err(|error| anyhow::anyhow!(error).into())
}

async fn delete_comic(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(comic_key): AxumPath<String>,
) -> Result<StatusCode, ApiError> {
    let user = current_user(&state, &headers).await?;
    let user_id = user.id.clone();
    let comic_key_for_database = comic_key.clone();
    let storage_keys = state
        .database
        .run_blocking(move |database| {
            database.delete_download_comic(&user_id, &comic_key_for_database)
        })
        .await?;

    let root = std::fs::canonicalize(state.config.asset_root()).map_err(|_| ApiError::NotFound)?;
    for storage_key in storage_keys {
        let path = root.join(&storage_key);
        if let Ok(canonical_path) = std::fs::canonicalize(&path)
            && canonical_path.starts_with(&root)
        {
            let _ = tokio::fs::remove_file(canonical_path).await;
        }
    }
    Ok(StatusCode::NO_CONTENT)
}

async fn run_task(state: AppState, user_id: String, task_id: String) {
    let mut artifacts = Vec::new();
    let mut manifest_saved = false;
    let result = run_task_inner(
        &state,
        &user_id,
        &task_id,
        &mut artifacts,
        &mut manifest_saved,
    )
    .await;
    if let Err(error) = result {
        tracing::error!(%task_id, error = %error, "server download task failed");
        if is_download_cancelled(&state, &user_id, &task_id, &error).await {
            let lookup_user_id = user_id.clone();
            let lookup_task_id = task_id.clone();
            if let Ok(Some(task)) = state
                .database
                .run_blocking(move |database| {
                    database.find_download_task(&lookup_user_id, &lookup_task_id)
                })
                .await
            {
                if task.status != "cancelled" {
                    let _ =
                        update_status(&state, &user_id, &task_id, "cancelled", task.progress, None)
                            .await;
                }
            }
        } else {
            let _ = update_status(
                &state,
                &user_id,
                &task_id,
                "failed",
                0,
                Some(&error.to_string()),
            )
            .await;
        }
        if !manifest_saved {
            cleanup_artifacts(&state, &user_id, artifacts).await;
        }
    }
    state.plugin_runtime.clear_task_group(&user_id, &task_id);
}

async fn run_task_inner(
    state: &AppState,
    user_id: &str,
    task_id: &str,
    artifacts: &mut Vec<DownloadArtifact>,
    manifest_saved: &mut bool,
) -> anyhow::Result<()> {
    let lookup_user_id = user_id.to_owned();
    let lookup_task_id = task_id.to_owned();
    let task = state
        .database
        .run_blocking(move |database| database.find_download_task(&lookup_user_id, &lookup_task_id))
        .await?
        .ok_or_else(|| anyhow::anyhow!("download task not found"))?;
    let payload: Value = serde_json::from_str(&task.payload_json)?;
    let plugin_id = payload["plugin_id"]
        .as_str()
        .ok_or_else(|| anyhow::anyhow!("download task has no plugin_id"))?;
    let comic_id = payload["comic_id"]
        .as_str()
        .ok_or_else(|| anyhow::anyhow!("download task has no comic_id"))?;
    let chapter_ids = payload["chapter_ids"]
        .as_array()
        .ok_or_else(|| anyhow::anyhow!("download task has no chapter_ids"))?;
    let options = payload.get("options").cloned().unwrap_or_else(|| json!({}));

    // 封面和章节图片使用同一套服务端 asset 存储，但在 manifest 中明确
    // 区分 cover_asset 与 pages，避免封面被当成章节页或被同名文件覆盖。
    let cover_asset_id = resolve_cover_asset(
        state, user_id, task_id, plugin_id, comic_id, &options, artifacts,
    )
    .await?;

    update_status(&state, user_id, task_id, "resolving", 0, None).await?;
    let mut pages = Vec::new();
    for chapter_id in chapter_ids {
        let chapter_id = chapter_id
            .as_str()
            .ok_or_else(|| anyhow::anyhow!("chapter id must be string"))?;
        check_not_cancelled(&state, user_id, task_id).await?;
        let snapshot = retry_download_step(state, user_id, task_id, || async {
            invoke_json_for_user_with_task_group(
                state,
                user_id,
                plugin_id,
                "getReadSnapshot",
                &json!([{
                    "comicId": comic_id,
                    "chapterId": chapter_id,
                    "extern": {},
                    "taskGroupKey": task_id,
                }]),
                Some(task_id),
            )
            .await
            .map_err(|error| anyhow::anyhow!(error_message(error)))
        })
        .await?;
        pages.extend(extract_pages(&snapshot, chapter_id));
    }
    if pages.is_empty() {
        return Err(anyhow::anyhow!("插件没有返回可下载的图片"));
    }

    let total = pages.len() as i64;
    let mut manifest_pages = Vec::with_capacity(pages.len());
    for (index, page) in pages.into_iter().enumerate() {
        check_not_cancelled(&state, user_id, task_id).await?;
        update_status(
            &state,
            user_id,
            task_id,
            "downloading",
            (index as i64 * 100 / total).min(99),
            None,
        )
        .await?;
        let page_url = page.url.clone();
        let page_extern = page.extern_data.clone();
        let bytes = retry_download_step(state, user_id, task_id, || async {
            invoke_bytes_for_user_with_task_group(
                state,
                user_id,
                plugin_id,
                "fetchImageBytes",
                &json!([{
                    "url": page_url.clone(),
                    "timeoutMs": 30000,
                    "taskGroupKey": task_id,
                    "extern": page_extern.clone(),
                }]),
                Some(task_id),
            )
            .await
            .map_err(|error| anyhow::anyhow!(error_message(error)))
        })
        .await?;
        let asset_id =
            persist_download_asset(state, user_id, bytes, "application/octet-stream", artifacts)
                .await?;
        manifest_pages.push(json!({
            "asset_id": asset_id,
            "chapter_id": page.chapter_id,
            "name": page.name,
            "url": page.url,
        }));
    }

    let comic_key = format!("{plugin_id}:{comic_id}");
    let manifest_json = serde_json::to_string(&json!({
        "plugin_id": plugin_id,
        "comic_id": comic_id,
        "options": options,
        "cover_asset": cover_asset_id.map(|asset_id| json!({
            "asset_id": asset_id,
        })),
        "pages": manifest_pages,
    }))?;
    let user_id_for_database = user_id.to_owned();
    let comic_key_for_database = comic_key.clone();
    let updated_at = now_millis();
    state
        .database
        .run_blocking(move |database| {
            database.save_manifest(
                &user_id_for_database,
                &comic_key_for_database,
                &manifest_json,
                &updated_at,
            )
        })
        .await?;
    *manifest_saved = true;
    update_status(&state, user_id, task_id, "completed", 100, None).await?;
    Ok(())
}

async fn resolve_cover_asset(
    state: &AppState,
    user_id: &str,
    task_id: &str,
    plugin_id: &str,
    comic_id: &str,
    options: &Value,
    artifacts: &mut Vec<DownloadArtifact>,
) -> anyhow::Result<Option<String>> {
    let option_cover = options.get("cover").unwrap_or(&Value::Null);
    let mut cover_url = first_string(option_cover, &["url", "fileServer"]);
    let mut cover_extern = option_cover
        .get("extern")
        .cloned()
        .unwrap_or_else(|| json!({}));

    if cover_url.is_empty() {
        let detail = retry_download_step(state, user_id, task_id, || async {
            invoke_json_for_user_with_task_group(
                state,
                user_id,
                plugin_id,
                "getComicDetail",
                &json!([{
                    "comicId": comic_id,
                    "extern": {},
                    "taskGroupKey": task_id,
                }]),
                Some(task_id),
            )
            .await
            .map_err(|error| anyhow::anyhow!(error_message(error)))
        })
        .await;
        if let Ok(detail) = detail {
            if let Some(cover) = find_cover_value(&detail) {
                cover_url = first_string(&Value::Object(cover.clone()), &["url", "fileServer"]);
                cover_extern = cover.get("extern").cloned().unwrap_or_else(|| json!({}));
            }
        }
    }

    if cover_url.is_empty() {
        return Ok(None);
    }

    let bytes = match retry_download_step(state, user_id, task_id, || async {
        invoke_bytes_for_user_with_task_group(
            state,
            user_id,
            plugin_id,
            "fetchImageBytes",
            &json!([{
                "url": cover_url.clone(),
                "timeoutMs": 30000,
                "taskGroupKey": task_id,
                "extern": cover_extern.clone(),
            }]),
            Some(task_id),
        )
        .await
        .map_err(|error| anyhow::anyhow!(error_message(error)))
    })
    .await
    {
        Ok(bytes) => bytes,
        Err(error) => {
            tracing::warn!(%error, "download cover failed, continue without cover");
            return Ok(None);
        }
    };
    let asset_id =
        persist_download_asset(state, user_id, bytes, "application/octet-stream", artifacts)
            .await?;
    Ok(Some(asset_id))
}

fn find_cover_value(value: &Value) -> Option<&serde_json::Map<String, Value>> {
    value
        .get("data")
        .and_then(|data| data.get("normal"))
        .and_then(|normal| normal.get("comicInfo"))
        .and_then(|comic| comic.get("cover"))
        .and_then(Value::as_object)
        .or_else(|| {
            value
                .get("data")
                .and_then(|data| data.get("comicInfo"))
                .and_then(|comic| comic.get("cover"))
                .and_then(Value::as_object)
        })
        .or_else(|| {
            value
                .get("normal")
                .and_then(|normal| normal.get("comicInfo"))
                .and_then(|comic| comic.get("cover"))
                .and_then(Value::as_object)
        })
        .or_else(|| {
            value
                .get("comicInfo")
                .and_then(|comic| comic.get("cover"))
                .and_then(Value::as_object)
        })
        .or_else(|| {
            value
                .get("data")
                .and_then(|data| data.get("comicInfo"))
                .and_then(|comic| comic.get("cover"))
                .and_then(Value::as_object)
        })
}

fn first_string(value: &Value, keys: &[&str]) -> String {
    keys.iter()
        .filter_map(|key| value.get(*key).and_then(Value::as_str))
        .map(str::trim)
        .find(|value| !value.is_empty())
        .unwrap_or_default()
        .to_owned()
}

async fn persist_download_asset(
    state: &AppState,
    user_id: &str,
    bytes: Vec<u8>,
    media_type: &str,
    artifacts: &mut Vec<DownloadArtifact>,
) -> anyhow::Result<String> {
    let asset_id = Uuid::new_v4().to_string();
    let storage_key = format!("{user_id}/{asset_id}.bin");
    let path = state.config.asset_root().join(&storage_key);
    if let Some(parent) = path.parent() {
        tokio::fs::create_dir_all(parent).await?;
    }
    if let Err(error) = tokio::fs::write(&path, &bytes).await {
        let _ = tokio::fs::remove_file(&path).await;
        return Err(error.into());
    }
    let mut hasher = Sha256::new();
    hasher.update(&bytes);
    let content_hash = format!("{:x}", hasher.finalize());
    let user_id_for_database = user_id.to_owned();
    let asset_id_for_database = asset_id.clone();
    let storage_key_for_database = storage_key.clone();
    let media_type_for_database = media_type.to_owned();
    let updated_at = now_millis();
    if let Err(error) = state
        .database
        .run_blocking(move |database| {
            database.create_asset(
                &user_id_for_database,
                &asset_id_for_database,
                &storage_key_for_database,
                &media_type_for_database,
                bytes.len() as i64,
                &content_hash,
                &updated_at,
            )
        })
        .await
    {
        let _ = tokio::fs::remove_file(&path).await;
        return Err(error);
    }
    artifacts.push(DownloadArtifact {
        asset_id: asset_id.clone(),
        path,
    });
    Ok(asset_id)
}

#[derive(Clone)]
struct DownloadPage {
    chapter_id: String,
    name: String,
    url: String,
    extern_data: Value,
}

struct DownloadArtifact {
    asset_id: String,
    path: PathBuf,
}

fn extract_pages(response: &Value, chapter_id: &str) -> Vec<DownloadPage> {
    let chapter = response
        .get("data")
        .and_then(|value| value.get("chapter"))
        .or_else(|| response.get("chapter"))
        .unwrap_or(response);
    chapter
        .get("pages")
        .or_else(|| chapter.get("docs"))
        .and_then(Value::as_array)
        .into_iter()
        .flatten()
        .filter_map(|page| {
            let url = page
                .get("url")
                .or_else(|| page.get("fileServer"))
                .and_then(Value::as_str)?
                .to_owned();
            if url.is_empty() {
                return None;
            }
            Some(DownloadPage {
                chapter_id: chapter_id.to_owned(),
                name: page["name"].as_str().unwrap_or_default().to_owned(),
                url,
                extern_data: page.get("extern").cloned().unwrap_or_else(|| json!({})),
            })
        })
        .collect()
}

async fn retry_download_step<T, F, Fut>(
    state: &AppState,
    user_id: &str,
    task_id: &str,
    mut operation: F,
) -> anyhow::Result<T>
where
    F: FnMut() -> Fut,
    Fut: Future<Output = anyhow::Result<T>>,
{
    let mut last_error = None;
    for attempt in 1..=DOWNLOAD_MAX_ATTEMPTS {
        check_not_cancelled(state, user_id, task_id).await?;
        match operation().await {
            Ok(value) => return Ok(value),
            Err(error)
                if is_retryable_download_error(&error) && attempt < DOWNLOAD_MAX_ATTEMPTS =>
            {
                tracing::warn!(
                    task_id,
                    attempt,
                    error = %error,
                    "download plugin step failed, retrying"
                );
                last_error = Some(error);
                tokio::time::sleep(DOWNLOAD_RETRY_DELAY * attempt as u32).await;
            }
            Err(error) => return Err(error),
        }
    }
    Err(last_error.unwrap_or_else(|| anyhow::anyhow!("download step failed")))
}

fn is_retryable_download_error(error: &anyhow::Error) -> bool {
    let text = error.to_string().to_ascii_lowercase();
    if text.contains("cancel") || text.contains("unauthorized") {
        return false;
    }
    [
        "timeout",
        "timed out",
        "connection reset",
        "connection refused",
        "connection closed",
        "network",
        "fetch failed",
        "502",
        "503",
        "504",
        "408",
        "429",
    ]
    .iter()
    .any(|marker| text.contains(marker))
}

async fn is_download_cancelled(
    state: &AppState,
    user_id: &str,
    task_id: &str,
    error: &anyhow::Error,
) -> bool {
    if error.to_string().contains("cancel") {
        return true;
    }
    let user_id = user_id.to_owned();
    let task_id = task_id.to_owned();
    state
        .database
        .run_blocking(move |database| database.find_download_task(&user_id, &task_id))
        .await
        .ok()
        .flatten()
        .is_some_and(|task| matches!(task.status.as_str(), "cancelling" | "cancelled"))
}

async fn cleanup_artifacts(state: &AppState, user_id: &str, artifacts: Vec<DownloadArtifact>) {
    for artifact in artifacts {
        if let Err(error) = tokio::fs::remove_file(&artifact.path).await
            && error.kind() != std::io::ErrorKind::NotFound
        {
            tracing::warn!(
                asset_id = %artifact.asset_id,
                error = %error,
                "failed to remove partial download asset"
            );
        }
        let user_id_for_database = user_id.to_owned();
        let asset_id = artifact.asset_id.clone();
        if let Err(error) = state
            .database
            .run_blocking(move |database| database.delete_asset(&user_id_for_database, &asset_id))
            .await
        {
            tracing::warn!(
                asset_id = %artifact.asset_id,
                error = %error,
                "failed to remove partial download asset record"
            );
        }
    }
}

async fn check_not_cancelled(state: &AppState, user_id: &str, task_id: &str) -> anyhow::Result<()> {
    let user_id_for_database = user_id.to_owned();
    let task_id_for_database = task_id.to_owned();
    let task = state
        .database
        .run_blocking(move |database| {
            database.find_download_task(&user_id_for_database, &task_id_for_database)
        })
        .await?
        .ok_or_else(|| anyhow::anyhow!("download task disappeared"))?;
    if task.status == "cancelling" {
        update_status(state, user_id, task_id, "cancelled", task.progress, None).await?;
        anyhow::bail!("download task cancelled");
    }
    Ok(())
}

async fn update_status(
    state: &AppState,
    user_id: &str,
    task_id: &str,
    status: &str,
    progress: i64,
    error: Option<&str>,
) -> anyhow::Result<()> {
    let user_id_for_database = user_id.to_owned();
    let task_id_for_database = task_id.to_owned();
    let status_for_database = status.to_owned();
    let error_for_database = error.map(ToOwned::to_owned);
    let updated_at = now_millis();
    state
        .database
        .run_blocking(move |database| {
            database.update_download_task(
                &user_id_for_database,
                &task_id_for_database,
                &status_for_database,
                progress,
                error_for_database.as_deref(),
                &updated_at,
            )
        })
        .await?;
    let payload = json!({
        "task_id": task_id,
        "status": status,
        "progress": progress,
        "error": error,
    });
    state
        .websocket_hub
        .publish_event(user_id, "downloads.progress", payload.clone());
    if matches!(status, "completed" | "failed" | "cancelled") {
        state
            .websocket_hub
            .publish_event(user_id, "downloads.status", payload);
    }
    Ok(())
}

fn validate_task_request(request: &CreateTaskRequest) -> Result<(), ApiError> {
    if request.plugin_id.trim().is_empty() || request.plugin_id.len() > 128 {
        return Err(ApiError::BadRequest("plugin_id 不合法".to_owned()));
    }
    if request.comic_id.trim().is_empty() || request.comic_id.len() > 512 {
        return Err(ApiError::BadRequest("comic_id 不合法".to_owned()));
    }
    if request.chapter_ids.is_empty() || request.chapter_ids.len() > 100 {
        return Err(ApiError::BadRequest(
            "chapter_ids 数量必须为 1 到 100".to_owned(),
        ));
    }
    if request
        .chapter_ids
        .iter()
        .any(|id| id.is_empty() || id.len() > 512)
    {
        return Err(ApiError::BadRequest("chapter_id 不合法".to_owned()));
    }
    Ok(())
}

fn to_task_response(task: DownloadTaskRecord) -> Result<TaskResponse, ApiError> {
    Ok(TaskResponse {
        task_id: task.task_id,
        status: task.status,
        progress: task.progress,
        payload: serde_json::from_str(&task.payload_json)?,
        error: task.error_text,
        updated_at: task.updated_at,
    })
}

fn error_message(error: ApiError) -> String {
    match error {
        ApiError::BadRequest(message) | ApiError::Conflict(message) => message,
        ApiError::Unauthorized => "需要登录".to_owned(),
        ApiError::Forbidden => "没有权限".to_owned(),
        ApiError::PluginBrowserLoginUnsupported => "CS 模式不支持插件浏览器登录".to_owned(),
        ApiError::PluginUnauthorized(details) => details
            .get("message")
            .and_then(serde_json::Value::as_str)
            .unwrap_or("插件登录已失效，请重新登录")
            .to_owned(),
        ApiError::NotFound => "资源不存在".to_owned(),
        ApiError::Internal(error) => error.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::{extract_pages, is_retryable_download_error};

    #[test]
    fn extracts_pages_from_nested_chapter_payloads() {
        let pages = extract_pages(
            &json!({
                "data": {
                    "chapter": {
                        "pages": [
                            {"url": "https://example.test/1.jpg", "name": "001"},
                            {"fileServer": "https://example.test/2.jpg", "extern": {"token": "x"}},
                            {"url": ""}
                        ]
                    }
                }
            }),
            "chapter-1",
        );

        assert_eq!(pages.len(), 2);
        assert_eq!(pages[0].chapter_id, "chapter-1");
        assert_eq!(pages[0].name, "001");
        assert_eq!(pages[1].url, "https://example.test/2.jpg");
        assert_eq!(pages[1].extern_data, json!({"token": "x"}));
    }

    #[test]
    fn retries_network_failures_but_not_authentication_or_cancellation() {
        assert!(is_retryable_download_error(&anyhow::anyhow!(
            "request timed out"
        )));
        assert!(is_retryable_download_error(&anyhow::anyhow!("HTTP 503")));
        assert!(!is_retryable_download_error(&anyhow::anyhow!(
            "unauthorized"
        )));
        assert!(!is_retryable_download_error(&anyhow::anyhow!(
            "download task cancelled"
        )));
    }
}
