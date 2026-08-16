use std::path::{Path, PathBuf};

use axum::{
    Json,
    body::Body,
    extract::{Path as AxumPath, State},
    http::{HeaderMap, StatusCode, header::CONTENT_TYPE},
    response::Response,
};
use serde::Deserialize;
use serde_json::Value;

use crate::app_state::AppState;

use super::{auth::current_user, error::ApiError};

#[derive(Deserialize)]
pub struct InvokeRequest {
    pub function: String,
    pub args: Value,
}

pub async fn invoke(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(plugin_id): AxumPath<String>,
    Json(request): Json<InvokeRequest>,
) -> Result<Json<Value>, ApiError> {
    let user = current_user(&state, &headers)?;
    let plugin = state
        .database
        .find_plugin(&plugin_id)?
        .ok_or(ApiError::NotFound)?;
    if !plugin.enabled {
        return Err(ApiError::Conflict("插件未启用".to_owned()));
    }
    if request.function.trim().is_empty() || !request.args.is_array() {
        return Err(ApiError::BadRequest(
            "function 不能为空，args 必须是 JSON 数组".to_owned(),
        ));
    }
    if serde_json::to_vec(&request.args)?.len() > 1024 * 1024 {
        return Err(ApiError::BadRequest("插件参数不能超过 1 MiB".to_owned()));
    }

    let bundle_path = resolve_bundle_path(&state.config.plugin_root, &plugin.bundle_path)?;
    let bundle_source = tokio::fs::read_to_string(&bundle_path)
        .await
        .map_err(|error| anyhow::anyhow!("failed to read plugin bundle: {error}"))?;
    let value = state
        .plugin_runtime
        .invoke_json(&user.id, &bundle_source, &request.function, &request.args)
        .await
        .map_err(|error| anyhow::anyhow!(error))?;
    Ok(Json(value))
}

pub async fn invoke_bytes(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(plugin_id): AxumPath<String>,
    Json(request): Json<InvokeRequest>,
) -> Result<Response, ApiError> {
    let user = current_user(&state, &headers)?;
    let plugin = state
        .database
        .find_plugin(&plugin_id)?
        .ok_or(ApiError::NotFound)?;
    if !plugin.enabled {
        return Err(ApiError::Conflict("插件未启用".to_owned()));
    }
    validate_invoke_request(&request)?;
    let bundle_path = resolve_bundle_path(&state.config.plugin_root, &plugin.bundle_path)?;
    let bundle_source = tokio::fs::read_to_string(&bundle_path)
        .await
        .map_err(|error| anyhow::anyhow!("failed to read plugin bundle: {error}"))?;
    let bytes = state
        .plugin_runtime
        .invoke_bytes(&user.id, &bundle_source, &request.function, &request.args)
        .await
        .map_err(|error| anyhow::anyhow!(error))?;
    Response::builder()
        .status(StatusCode::OK)
        .header(CONTENT_TYPE, "application/octet-stream")
        .body(Body::from(bytes))
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
