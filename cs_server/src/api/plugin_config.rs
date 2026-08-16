use axum::{Json, extract::State, http::HeaderMap};
use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::app_state::AppState;

use super::{auth::current_user, error::ApiError};

#[derive(Serialize)]
pub struct PluginConfigResponse {
    pub plugin_id: String,
    pub config: Value,
    pub revision: i64,
    pub updated_at: String,
}

#[derive(Deserialize)]
pub struct UpdatePluginConfigRequest {
    pub config: Value,
    pub expected_revision: Option<i64>,
}

pub async fn get(
    State(state): State<AppState>,
    headers: HeaderMap,
    axum::extract::Path(plugin_id): axum::extract::Path<String>,
) -> Result<Json<PluginConfigResponse>, ApiError> {
    let user = current_user(&state, &headers)?;
    ensure_plugin(&state, &plugin_id)?;
    let record = state.database.plugin_config(&user.id, &plugin_id)?;
    Ok(Json(to_response(&plugin_id, record)?))
}

pub async fn update(
    State(state): State<AppState>,
    headers: HeaderMap,
    axum::extract::Path(plugin_id): axum::extract::Path<String>,
    Json(request): Json<UpdatePluginConfigRequest>,
) -> Result<Json<PluginConfigResponse>, ApiError> {
    let user = current_user(&state, &headers)?;
    ensure_plugin(&state, &plugin_id)?;
    if !request.config.is_object() {
        return Err(ApiError::BadRequest("插件配置必须是 JSON 对象".to_owned()));
    }
    if serde_json::to_vec(&request.config)?.len() > 1024 * 1024 {
        return Err(ApiError::BadRequest("插件配置不能超过 1 MiB".to_owned()));
    }
    let Some(record) = state.database.update_plugin_config(
        &user.id,
        &plugin_id,
        &serde_json::to_string(&request.config)?,
        request.expected_revision,
        &super::auth::now_millis(),
    )?
    else {
        return Err(ApiError::Conflict(
            "插件配置版本已变化，请重新读取后再提交".to_owned(),
        ));
    };
    Ok(Json(to_response(&plugin_id, record)?))
}

fn ensure_plugin(state: &AppState, plugin_id: &str) -> Result<(), ApiError> {
    if state.database.find_plugin(plugin_id)?.is_none() {
        return Err(ApiError::NotFound);
    }
    Ok(())
}

fn to_response(
    plugin_id: &str,
    record: crate::db::PluginConfigRecord,
) -> Result<PluginConfigResponse, ApiError> {
    Ok(PluginConfigResponse {
        plugin_id: plugin_id.to_owned(),
        config: serde_json::from_str(&record.config_json)?,
        revision: record.revision,
        updated_at: record.updated_at,
    })
}
