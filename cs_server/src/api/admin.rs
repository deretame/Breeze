use axum::{Json, Router, extract::State, http::HeaderMap, routing::put};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::app_state::AppState;

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
struct InstallPluginResponse {
    plugin_id: String,
    version: String,
    bundle_hash: String,
    enabled: bool,
}

async fn install_plugin(
    State(state): State<AppState>,
    headers: HeaderMap,
    axum::extract::Path(plugin_id): axum::extract::Path<String>,
    Json(request): Json<InstallPluginRequest>,
) -> Result<Json<InstallPluginResponse>, ApiError> {
    authorize(&state, &headers)?;
    validate_plugin_id(&plugin_id)?;
    if request.version.trim().is_empty() || request.version.len() > 128 {
        return Err(ApiError::BadRequest("插件版本不合法".to_owned()));
    }
    if request.bundle.is_empty() || request.bundle.len() > 8 * 1024 * 1024 {
        return Err(ApiError::BadRequest(
            "插件 bundle 不能为空且不能超过 8 MiB".to_owned(),
        ));
    }

    tokio::fs::create_dir_all(&state.config.plugin_root).await?;
    let filename = format!("{}.cjs", plugin_id);
    let root = std::fs::canonicalize(&state.config.plugin_root)?;
    let target = root.join(&filename);
    if !target.starts_with(&root) {
        return Err(ApiError::Forbidden);
    }
    let temporary = root.join(format!(".{}.{}.tmp", plugin_id, uuid::Uuid::new_v4()));
    tokio::fs::write(&temporary, request.bundle.as_bytes()).await?;
    tokio::fs::rename(&temporary, &target).await?;

    let mut hasher = Sha256::new();
    hasher.update(request.bundle.as_bytes());
    let bundle_hash = format!("{:x}", hasher.finalize());
    let record = state.database.upsert_plugin(
        &plugin_id,
        request.version.trim(),
        &filename,
        &bundle_hash,
        request.enabled,
        &now_millis(),
    )?;
    Ok(Json(InstallPluginResponse {
        plugin_id: record.plugin_id,
        version: record.version,
        bundle_hash: record.bundle_hash,
        enabled: record.enabled,
    }))
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

fn validate_plugin_id(plugin_id: &str) -> Result<(), ApiError> {
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
