use axum::{
    Json, Router,
    extract::{Path, Query, State},
    http::HeaderMap,
    routing::{delete, get},
};
use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::{
    app_state::AppState,
    db::{LibraryKind, LibraryRecord},
};

use super::{auth::current_user, error::ApiError};

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/{kind}", get(list).post(upsert))
        .route("/{kind}/{unique_key}", delete(remove))
}

#[derive(Deserialize, Default)]
pub struct ListQuery {
    #[serde(default)]
    pub include_deleted: bool,
}

#[derive(Deserialize)]
pub struct UpsertRequest {
    pub unique_key: String,
    #[serde(default)]
    pub source: String,
    #[serde(default)]
    pub comic_id: String,
    pub payload: Value,
}

#[derive(Serialize)]
pub struct LibraryListResponse {
    pub items: Vec<LibraryResponse>,
}

#[derive(Serialize)]
pub struct LibraryResponse {
    pub unique_key: String,
    pub source: String,
    pub comic_id: String,
    pub payload: Value,
    pub updated_at: String,
    pub deleted_at: Option<String>,
}

#[derive(Serialize)]
pub struct DeleteResponse {
    pub deleted: bool,
    pub unique_key: String,
}

async fn list(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(kind): Path<String>,
    Query(query): Query<ListQuery>,
) -> Result<Json<LibraryListResponse>, ApiError> {
    let user = current_user(&state, &headers)?;
    let kind = parse_kind(&kind)?;
    let items = state
        .database
        .list_library_records(&user.id, kind, query.include_deleted)?
        .into_iter()
        .map(to_response)
        .collect::<Result<Vec<_>, _>>()?;
    Ok(Json(LibraryListResponse { items }))
}

async fn upsert(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(kind): Path<String>,
    Json(request): Json<UpsertRequest>,
) -> Result<Json<LibraryResponse>, ApiError> {
    let user = current_user(&state, &headers)?;
    let kind = parse_kind(&kind)?;
    validate_request(&request)?;
    let record = state.database.upsert_library_record(
        &user.id,
        kind,
        &request.unique_key,
        &request.source,
        &request.comic_id,
        &serde_json::to_string(&request.payload)?,
        &super::auth::now_millis(),
    )?;
    Ok(Json(to_response(record)?))
}

async fn remove(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path((kind, unique_key)): Path<(String, String)>,
) -> Result<Json<DeleteResponse>, ApiError> {
    let user = current_user(&state, &headers)?;
    let kind = parse_kind(&kind)?;
    if unique_key.is_empty() || unique_key.len() > 512 {
        return Err(ApiError::BadRequest("unique_key 长度不合法".to_owned()));
    }
    let deleted = state.database.delete_library_record(
        &user.id,
        kind,
        &unique_key,
        &super::auth::now_millis(),
    )?;
    if !deleted {
        return Err(ApiError::NotFound);
    }
    Ok(Json(DeleteResponse {
        deleted: true,
        unique_key,
    }))
}

fn parse_kind(value: &str) -> Result<LibraryKind, ApiError> {
    LibraryKind::parse(value).ok_or_else(|| ApiError::BadRequest("不支持的业务数据类型".to_owned()))
}

fn validate_request(request: &UpsertRequest) -> Result<(), ApiError> {
    if request.unique_key.trim().is_empty() || request.unique_key.len() > 512 {
        return Err(ApiError::BadRequest("unique_key 长度不合法".to_owned()));
    }
    if request.source.len() > 256 || request.comic_id.len() > 512 {
        return Err(ApiError::BadRequest("漫画来源或 ID 长度不合法".to_owned()));
    }
    let payload_size = serde_json::to_vec(&request.payload)?.len();
    if payload_size > 1024 * 1024 {
        return Err(ApiError::BadRequest(
            "业务数据 payload 不能超过 1 MiB".to_owned(),
        ));
    }
    Ok(())
}

fn to_response(record: LibraryRecord) -> Result<LibraryResponse, ApiError> {
    Ok(LibraryResponse {
        unique_key: record.unique_key,
        source: record.source,
        comic_id: record.comic_id,
        payload: serde_json::from_str(&record.payload_json)?,
        updated_at: record.updated_at,
        deleted_at: record.deleted_at,
    })
}
