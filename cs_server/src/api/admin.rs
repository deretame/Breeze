use axum::{Json, Router, extract::State, http::HeaderMap, routing::put};
use serde::{Deserialize, Serialize};

use crate::app_state::AppState;
use crate::plugin_store::{MAX_BUNDLE_BYTES, store_plugin_bundle};

use super::{auth::now_millis, error::ApiError};

pub fn router() -> Router<AppState> {
    Router::new().route("/plugins/{plugin_id}", put(install_plugin))
}

#[derive(Deserialize)]
struct InstallPluginRequest {
    version: String,
    bundle: String,
    #[serde(default = "default_enabled")]
    enabled: bool,
}

#[derive(Serialize)]
pub(crate) struct InstallPluginResponse {
    pub(crate) plugin_id: String,
    pub(crate) version: String,
    pub(crate) bundle_hash: String,
    pub(crate) enabled: bool,
}

async fn install_plugin(
    State(state): State<AppState>,
    headers: HeaderMap,
    axum::extract::Path(plugin_id): axum::extract::Path<String>,
    Json(request): Json<InstallPluginRequest>,
) -> Result<Json<InstallPluginResponse>, ApiError> {
    authorize(&state, &headers)?;
    validate_plugin_id(&plugin_id)?;
    Ok(Json(
        install_bundle(
            &state,
            &plugin_id,
            &request.version,
            &request.bundle,
            request.enabled,
        )
        .await?,
    ))
}

pub(crate) async fn install_bundle(
    state: &AppState,
    plugin_id: &str,
    version: &str,
    bundle: &str,
    enabled: bool,
) -> Result<InstallPluginResponse, ApiError> {
    validate_plugin_id(plugin_id)?;
    if version.trim().is_empty() || version.len() > 128 {
        return Err(ApiError::BadRequest("插件版本不合法".to_owned()));
    }
    if bundle.is_empty() || bundle.len() > MAX_BUNDLE_BYTES {
        return Err(ApiError::BadRequest(
            "插件 bundle 不能为空且不能超过 8 MiB".to_owned(),
        ));
    }

    tokio::fs::create_dir_all(&state.config.plugin_root).await?;
    let (storage_key, bundle_hash) = store_plugin_bundle(&state.config.plugin_root, bundle).await?;
    let root = std::fs::canonicalize(&state.config.plugin_root)?;
    let object_path = root.join(&storage_key);
    if !object_path.starts_with(&root) {
        return Err(ApiError::Forbidden);
    }
    let compressed_size = tokio::fs::metadata(&object_path).await?.len() as i64;
    let record = state.database.upsert_plugin(
        plugin_id,
        version.trim(),
        &storage_key,
        &bundle_hash,
        enabled,
        &now_millis(),
    )?;
    state.database.upsert_plugin_object(
        &bundle_hash,
        "brotli",
        bundle.len() as i64,
        compressed_size,
        &storage_key,
        &now_millis(),
    )?;
    for orphan in state.database.remove_unreferenced_plugin_objects()? {
        let orphan_path = root.join(&orphan);
        if orphan_path.starts_with(&root) {
            if let Err(error) = tokio::fs::remove_file(&orphan_path).await {
                tracing::warn!(path = %orphan_path.display(), ?error, "删除未引用插件对象失败");
            }
        }
    }
    Ok(InstallPluginResponse {
        plugin_id: record.plugin_id,
        version: record.version,
        bundle_hash: record.bundle_hash,
        enabled: record.enabled,
    })
}

fn authorize(state: &AppState, headers: &HeaderMap) -> Result<(), ApiError> {
    let Some(expected) = state.config.admin_token.as_deref() else {
        return Err(ApiError::Forbidden);
    };
    let actual = headers
        .get("x-breeze-admin-token")
        .and_then(|value| value.to_str().ok())
        .unwrap_or_default();
    if actual.is_empty() || !constant_time_equal(actual.as_bytes(), expected.as_bytes()) {
        return Err(ApiError::Unauthorized);
    }
    Ok(())
}

pub(crate) fn validate_plugin_id(plugin_id: &str) -> Result<(), ApiError> {
    if plugin_id.is_empty()
        || plugin_id.len() > 128
        || !plugin_id
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'.' | b'_' | b'-'))
    {
        return Err(ApiError::BadRequest("插件 ID 不合法".to_owned()));
    }
    Ok(())
}

fn constant_time_equal(left: &[u8], right: &[u8]) -> bool {
    if left.len() != right.len() {
        return false;
    }
    left.iter()
        .zip(right)
        .fold(0u8, |difference, (a, b)| difference | (a ^ b))
        == 0
}

fn default_enabled() -> bool {
    true
}
