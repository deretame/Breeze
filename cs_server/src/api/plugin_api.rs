use std::path::{Path, PathBuf};

use axum::{
    Json,
    body::Body,
    extract::{Path as AxumPath, State},
    http::{HeaderMap, StatusCode, header::CONTENT_TYPE},
    response::Response,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::app_state::AppState;

use super::{auth::current_user, error::ApiError};

#[derive(Deserialize)]
pub struct InvokeRequest {
    pub function: String,
    pub args: Value,
}

#[derive(Default, Deserialize)]
pub struct SemanticRequest {
    #[serde(default)]
    pub core: Value,
    #[serde(default, rename = "extern")]
    pub extern_data: Value,
}

#[derive(Serialize)]
pub struct PluginDetailResponse {
    pub plugin_id: String,
    pub version: String,
    pub bundle_hash: String,
    pub enabled: bool,
    pub updated_at: String,
}

pub async fn plugin_detail(
    State(state): State<AppState>,
    AxumPath(plugin_id): AxumPath<String>,
) -> Result<Json<PluginDetailResponse>, ApiError> {
    let plugin = state
        .database
        .find_plugin(&plugin_id)?
        .ok_or(ApiError::NotFound)?;
    Ok(Json(PluginDetailResponse {
        plugin_id: plugin.plugin_id,
        version: plugin.version,
        bundle_hash: plugin.bundle_hash,
        enabled: plugin.enabled,
        updated_at: plugin.updated_at,
    }))
}

pub async fn invoke(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(plugin_id): AxumPath<String>,
    Json(request): Json<InvokeRequest>,
) -> Result<Json<Value>, ApiError> {
    let user = current_user(&state, &headers)?;
    validate_invoke_request(&request)?;
    let value = invoke_json_for_user(
        &state,
        &user.id,
        &plugin_id,
        &request.function,
        &request.args,
    )
    .await?;
    Ok(Json(value))
}

pub async fn invoke_bytes(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(plugin_id): AxumPath<String>,
    Json(request): Json<InvokeRequest>,
) -> Result<Response, ApiError> {
    let user = current_user(&state, &headers)?;
    validate_invoke_request(&request)?;
    let bytes = invoke_bytes_for_user(
        &state,
        &user.id,
        &plugin_id,
        &request.function,
        &request.args,
    )
    .await?;
    Response::builder()
        .status(StatusCode::OK)
        .header(CONTENT_TYPE, "application/octet-stream")
        .body(Body::from(bytes))
        .map_err(|error| anyhow::anyhow!(error).into())
}

pub async fn search(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(plugin_id): AxumPath<String>,
    Json(request): Json<SemanticRequest>,
) -> Result<Json<Value>, ApiError> {
    semantic_invoke(&state, &headers, &plugin_id, "searchComic", request).await
}

pub async fn detail(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath((plugin_id, comic_id)): AxumPath<(String, String)>,
    Json(mut request): Json<SemanticRequest>,
) -> Result<Json<Value>, ApiError> {
    merge_string_field(&mut request.core, "comicId", comic_id)?;
    semantic_invoke(&state, &headers, &plugin_id, "getComicDetail", request).await
}

pub async fn chapter(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath((plugin_id, comic_id, chapter_id)): AxumPath<(String, String, String)>,
    Json(mut request): Json<SemanticRequest>,
) -> Result<Json<Value>, ApiError> {
    merge_string_field(&mut request.core, "comicId", comic_id)?;
    merge_string_field(&mut request.core, "chapterId", chapter_id)?;
    semantic_invoke(&state, &headers, &plugin_id, "getChapter", request).await
}

pub async fn read(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath((plugin_id, comic_id)): AxumPath<(String, String)>,
    Json(mut request): Json<SemanticRequest>,
) -> Result<Json<Value>, ApiError> {
    merge_string_field(&mut request.core, "comicId", comic_id)?;
    semantic_invoke(&state, &headers, &plugin_id, "getReadSnapshot", request).await
}

async fn semantic_invoke(
    state: &AppState,
    headers: &HeaderMap,
    plugin_id: &str,
    function: &str,
    request: SemanticRequest,
) -> Result<Json<Value>, ApiError> {
    let user = current_user(state, headers)?;
    let args = build_plugin_args(request)?;
    Ok(Json(
        invoke_json_for_user(state, &user.id, plugin_id, function, &args).await?,
    ))
}

fn build_plugin_args(request: SemanticRequest) -> Result<Value, ApiError> {
    let mut core = match request.core {
        Value::Object(map) => map,
        Value::Null => serde_json::Map::new(),
        _ => return Err(ApiError::BadRequest("core 必须是 JSON 对象".to_owned())),
    };
    let extern_data = match request.extern_data {
        Value::Object(map) => Value::Object(map),
        Value::Null => Value::Object(serde_json::Map::new()),
        _ => return Err(ApiError::BadRequest("extern 必须是 JSON 对象".to_owned())),
    };
    core.insert("extern".to_owned(), extern_data);
    Ok(Value::Array(vec![Value::Object(core)]))
}

fn merge_string_field(target: &mut Value, field: &str, value: String) -> Result<(), ApiError> {
    let map = target
        .as_object_mut()
        .ok_or_else(|| ApiError::BadRequest("core 必须是 JSON 对象".to_owned()))?;
    map.insert(field.to_owned(), Value::String(value));
    Ok(())
}

pub(crate) async fn invoke_json_for_user(
    state: &AppState,
    user_id: &str,
    plugin_id: &str,
    function: &str,
    args: &Value,
) -> Result<Value, ApiError> {
    let plugin = state
        .database
        .find_plugin(plugin_id)?
        .ok_or(ApiError::NotFound)?;
    if !plugin.enabled {
        return Err(ApiError::Conflict("插件未启用".to_owned()));
    }
    let bundle_path = resolve_bundle_path(&state.config.plugin_root, &plugin.bundle_path)?;
    let bundle_source = tokio::fs::read_to_string(&bundle_path)
        .await
        .map_err(|error| anyhow::anyhow!("failed to read plugin bundle: {error}"))?;
    state
        .plugin_runtime
        .invoke_json(user_id, plugin_id, &bundle_source, function, args)
        .await
        .map_err(|error| anyhow::anyhow!(error).into())
}

pub(crate) async fn invoke_bytes_for_user(
    state: &AppState,
    user_id: &str,
    plugin_id: &str,
    function: &str,
    args: &Value,
) -> Result<Vec<u8>, ApiError> {
    let plugin = state
        .database
        .find_plugin(plugin_id)?
        .ok_or(ApiError::NotFound)?;
    if !plugin.enabled {
        return Err(ApiError::Conflict("插件未启用".to_owned()));
    }
    let bundle_path = resolve_bundle_path(&state.config.plugin_root, &plugin.bundle_path)?;
    let bundle_source = tokio::fs::read_to_string(&bundle_path)
        .await
        .map_err(|error| anyhow::anyhow!("failed to read plugin bundle: {error}"))?;
    state
        .plugin_runtime
        .invoke_bytes(user_id, plugin_id, &bundle_source, function, args)
        .await
        .map_err(|error| anyhow::anyhow!(error).into())
}

fn validate_invoke_request(request: &InvokeRequest) -> Result<(), ApiError> {
    if request.function.trim().is_empty() || !request.args.is_array() {
        return Err(ApiError::BadRequest(
            "function 不能为空，args 必须是 JSON 数组".to_owned(),
        ));
    }
    if serde_json::to_vec(&request.args)?.len() > 1024 * 1024 {
        return Err(ApiError::BadRequest("插件参数不能超过 1 MiB".to_owned()));
    }
    Ok(())
}

fn resolve_bundle_path(root: &Path, stored_path: &str) -> Result<PathBuf, ApiError> {
    let root = std::fs::canonicalize(root).map_err(|_| ApiError::NotFound)?;
    let relative = Path::new(stored_path);
    if relative.is_absolute()
        || relative
            .components()
            .any(|component| matches!(component, std::path::Component::ParentDir))
    {
        return Err(ApiError::Forbidden);
    }
    let candidate = std::fs::canonicalize(root.join(relative)).map_err(|_| ApiError::NotFound)?;
    if !candidate.starts_with(&root) {
        return Err(ApiError::Forbidden);
    }
    Ok(candidate)
}
