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
    let response = install_bundle(
        &state,
        &plugin_id,
        &request.version,
        &request.bundle,
        request.enabled,
    )
    .await?;
    super::plugin_store::notify_plugin_updated(
        &state,
        &response.plugin_id,
        &response.version,
        "installed",
    );
    Ok(Json(response))
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
    let plugin_id_for_database = plugin_id.to_owned();
    let version_for_database = version.trim().to_owned();
    let storage_key_for_database = storage_key.clone();
    let bundle_hash_for_database = bundle_hash.clone();
    let updated_at = now_millis();
    let bundle_original_size = bundle.len() as i64;
    let record = state
        .database
        .run_blocking(move |database| {
            database.upsert_plugin(
                &plugin_id_for_database,
                &version_for_database,
                &storage_key_for_database,
                &bundle_hash_for_database,
                enabled,
                &updated_at,
            )
        })
        .await?;
    let bundle_hash_for_object = bundle_hash.clone();
    let storage_key_for_object = storage_key.clone();
    let updated_at = now_millis();
    state
        .database
        .run_blocking(move |database| {
            database.upsert_plugin_object(
                &bundle_hash_for_object,
                "brotli",
                bundle_original_size,
                compressed_size,
                &storage_key_for_object,
                &updated_at,
            )
        })
        .await?;
    let orphans = state
        .database
        .run_blocking(|database| database.remove_unreferenced_plugin_objects())
        .await?;
    for orphan in orphans {
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
