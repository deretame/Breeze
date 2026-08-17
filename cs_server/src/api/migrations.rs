use axum::{
    Json,
    body::Bytes,
    extract::{Query, State},
    http::HeaderMap,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::{app_state::AppState, db::MigrationImportCounts};

use super::{admin, auth::current_user, error::ApiError};

const MAX_SNAPSHOT_BYTES: usize = 64 * 1024 * 1024;
const MAX_ASSET_BYTES: usize = 64 * 1024 * 1024;

#[derive(Deserialize)]
pub struct ImportRequest {
    pub snapshot: Value,
}

#[derive(Serialize)]
pub struct ImportResponse {
    pub imported: bool,
    pub counts: MigrationImportCounts,
}

#[derive(Deserialize)]
pub struct AssetQuery {
    pub comic_key: String,
    pub path: String,
    pub media_type: Option<String>,
}

#[derive(Serialize)]
pub struct AssetResponse {
    pub asset_id: String,
    pub byte_size: usize,
    pub content_hash: String,
}

#[derive(Deserialize, Default)]
pub struct ExportQuery {
    #[serde(default)]
    pub include_downloads: bool,
}

/// 导出当前用户在服务端的数据，用于关闭 CS 模式时覆盖本地数据。
///
/// 插件 bundle 会从服务端插件目录读出并随 JSON 返回；下载图片只返回元数据，
/// 文件本体通过已有的下载资源接口逐个读取，避免把大文件塞进 JSON。
pub async fn export(
    State(state): State<AppState>,
    headers: HeaderMap,
    Query(query): Query<ExportQuery>,
) -> Result<Json<Value>, ApiError> {
    let user = current_user(&state, &headers)?;
    let mut data = state
        .database
        .export_migration_data(&user.id, query.include_downloads)?;

    let plugins = state.database.list_user_plugins(&user.id)?;
    let plugin_root = std::fs::canonicalize(&state.config.plugin_root)?;
    let mut plugin_values = Vec::with_capacity(plugins.len());
    for plugin in plugins {
        let path = std::fs::canonicalize(plugin_root.join(&plugin.bundle_path))?;
        if !path.starts_with(&plugin_root) {
            return Err(ApiError::Forbidden);
        }
        let bundle =
            crate::plugin_store::read_plugin_bundle_file_verified(&path, &plugin.bundle_hash)
                .await?;
        plugin_values.push(serde_json::json!({
            "id": 0,
            "uuid": plugin.plugin_id,
            "version": plugin.version,
            "originScript": bundle,
            "lastLoadSuccess": true,
            "lastLoadError": null,
            "insertedAt": plugin.updated_at,
            "updatedAt": plugin.updated_at,
            "isEnabled": plugin.enabled,
            "isDeleted": false,
            "deletedAt": null,
            "debug": plugin.debug,
            "debugUrl": plugin.debug_url,
            "getInfoJson": "",
        }));
    }
    data["plugins"] = Value::Array(plugin_values);

    let snapshot = serde_json::json!({
        "schema_version": 1,
        "generated_at": super::auth::now_millis(),
        "include_downloads": query.include_downloads,
        "data": data,
    });
    if serde_json::to_vec(&snapshot)?.len() > MAX_SNAPSHOT_BYTES {
        return Err(ApiError::BadRequest("导出快照不能超过 64 MiB".to_owned()));
    }
    Ok(Json(snapshot))
}

/// 导入客户端一次性导出的 JSON 快照。
///
/// 普通业务数据在一个 SQLite 事务中导入；插件脚本先由服务端运行时校验并写入
/// 服务端插件目录，再建立当前用户的插件启用状态。导入不会删除服务端已有数据。
pub async fn import(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(request): Json<ImportRequest>,
) -> Result<Json<ImportResponse>, ApiError> {
    let user = current_user(&state, &headers)?;
    let snapshot_size = serde_json::to_vec(&request.snapshot)?.len();
    if snapshot_size > MAX_SNAPSHOT_BYTES {
        return Err(ApiError::BadRequest("迁移快照不能超过 64 MiB".to_owned()));
    }
    let schema_version = request
        .snapshot
        .get("schema_version")
        .and_then(Value::as_i64)
        .unwrap_or_default();
    if schema_version != 1 {
        return Err(ApiError::BadRequest("不支持的迁移快照版本".to_owned()));
    }

    let data = request.snapshot.get("data").unwrap_or(&request.snapshot);
    let include_downloads = request
        .snapshot
        .get("include_downloads")
        .and_then(Value::as_bool)
        .unwrap_or(false);

    // 插件脚本属于服务端资源，不能仅写入用户业务表。先安装/校验脚本，
    // 失败时不会进入后续业务数据导入。
    if let Some(plugins) = data.get("plugins").and_then(Value::as_array) {
        for plugin in plugins {
            let Some(plugin_id) = string_field(plugin, "uuid") else {
                continue;
            };
            let Some(bundle) = string_field(plugin, "originScript") else {
                continue;
            };
            if plugin_id.is_empty() || bundle.is_empty() {
                continue;
            }
            let version = string_field(plugin, "version").unwrap_or_else(|| "0.0.0".to_owned());
            let enabled = bool_field(plugin, "isEnabled").unwrap_or(true);
            let response =
                admin::install_bundle(&state, &plugin_id, &version, &bundle, enabled).await?;
            state.database.upsert_user_plugin(
                &user.id,
                &response.plugin_id,
                enabled,
                bool_field(plugin, "debug").unwrap_or(false),
                string_field(plugin, "debugUrl").as_deref(),
                &super::auth::now_millis(),
            )?;
        }
    }

    let counts = state
        .database
        .import_migration_snapshot(&user.id, data, include_downloads)?;
    Ok(Json(ImportResponse {
        imported: true,
        counts,
    }))
}

pub async fn upload_asset(
    State(state): State<AppState>,
    headers: HeaderMap,
    Query(query): Query<AssetQuery>,
    body: Bytes,
) -> Result<Json<AssetResponse>, ApiError> {
    let user = current_user(&state, &headers)?;
    validate_asset_query(&query)?;
    if body.is_empty() || body.len() > MAX_ASSET_BYTES {
        return Err(ApiError::BadRequest(
            "迁移文件不能为空且不能超过 64 MiB".to_owned(),
        ));
    }

    let asset_id = Uuid::new_v4().to_string();
    let storage_key = format!("{}/migration/{}.bin", user.id, asset_id);
    let root = std::fs::canonicalize(state.config.asset_root())?;
    let target = root.join(&storage_key);
    if !target.starts_with(&root) {
        return Err(ApiError::Forbidden);
    }
    if let Some(parent) = target.parent() {
        tokio::fs::create_dir_all(parent).await?;
    }
    tokio::fs::write(&target, &body).await?;

    let mut hasher = Sha256::new();
    hasher.update(&body);
    let content_hash = format!("{:x}", hasher.finalize());
    state.database.create_asset(
        &user.id,
        &asset_id,
        &storage_key,
        query
            .media_type
            .as_deref()
            .unwrap_or("application/octet-stream"),
        body.len() as i64,
        &content_hash,
        &super::auth::now_millis(),
    )?;
    state.database.append_migration_asset_page(
        &user.id,
        &query.comic_key,
        &query.path,
        &asset_id,
        &super::auth::now_millis(),
    )?;

    Ok(Json(AssetResponse {
        asset_id,
        byte_size: body.len(),
        content_hash,
    }))
}

fn validate_asset_query(query: &AssetQuery) -> Result<(), ApiError> {
    if query.comic_key.trim().is_empty() || query.comic_key.len() > 1024 {
        return Err(ApiError::BadRequest("漫画唯一键不合法".to_owned()));
    }
    if query.path.trim().is_empty() || query.path.len() > 2048 {
        return Err(ApiError::BadRequest("迁移文件路径不合法".to_owned()));
    }
    let path = std::path::Path::new(&query.path);
    if path.is_absolute()
        || path
            .components()
            .any(|component| matches!(component, std::path::Component::ParentDir))
    {
        return Err(ApiError::BadRequest("迁移文件路径不能越界".to_owned()));
    }
    if let Some(media_type) = query.media_type.as_deref()
        && (media_type.is_empty() || media_type.len() > 128)
    {
        return Err(ApiError::BadRequest("文件媒体类型不合法".to_owned()));
    }
    Ok(())
}

fn string_field(value: &Value, key: &str) -> Option<String> {
    value
        .get(key)
        .and_then(Value::as_str)
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .map(ToOwned::to_owned)
}

fn bool_field(value: &Value, key: &str) -> Option<bool> {
    value.get(key).and_then(Value::as_bool)
}
