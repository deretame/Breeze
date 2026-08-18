use axum::{Json, extract::State, http::HeaderMap};
use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::app_state::AppState;

use super::{auth::current_user, error::ApiError};

#[derive(Serialize)]
pub struct AccountSettingsResponse {
    pub settings: Value,
    pub revision: i64,
    pub updated_at: String,
}

#[derive(Deserialize)]
pub struct UpdateAccountSettingsRequest {
    pub settings: Value,
    pub expected_revision: Option<i64>,
}

pub async fn get_account_settings(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<AccountSettingsResponse>, ApiError> {
    let user = current_user(&state, &headers).await?;
    let user_id = user.id.clone();
    let record = state
        .database
        .run_blocking(move |database| database.account_settings(&user_id))
        .await?;
    Ok(Json(to_response(record)?))
}

pub async fn update_account_settings(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(request): Json<UpdateAccountSettingsRequest>,
) -> Result<Json<AccountSettingsResponse>, ApiError> {
    let user = current_user(&state, &headers).await?;
    let settings_json = serde_json::to_string(&request.settings)?;
    let updated_at = super::auth::now_millis();
    let user_id = user.id.clone();
    let Some(record) = state
        .database
        .run_blocking(move |database| {
            database.update_account_settings(
                &user_id,
                &settings_json,
                request.expected_revision,
                &updated_at,
            )
        })
        .await?
    else {
        return Err(ApiError::Conflict(
            "账号设置版本已变化，请重新读取后再提交".to_owned(),
        ));
    };
    Ok(Json(to_response(record)?))
}

fn to_response(
    record: crate::db::AccountSettingsRecord,
) -> Result<AccountSettingsResponse, ApiError> {
    Ok(AccountSettingsResponse {
        settings: serde_json::from_str(&record.settings_json)?,
        revision: record.revision,
        updated_at: record.updated_at,
    })
}
