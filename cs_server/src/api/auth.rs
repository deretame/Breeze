use std::time::{Duration, SystemTime, UNIX_EPOCH};

use argon2::password_hash::{SaltString, rand_core::OsRng};
use argon2::{Argon2, PasswordHash, PasswordHasher, PasswordVerifier};
use axum::{
    Json, Router,
    extract::State,
    http::{HeaderMap, header::AUTHORIZATION},
    routing::{get, post},
};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::{app_state::AppState, db::UserRecord};

use super::error::ApiError;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/register", post(register))
        .route("/login", post(login))
        .route("/logout", post(logout))
        .route("/me", get(me))
}

#[derive(Deserialize)]
struct Credentials {
    username: String,
    password: String,
}

#[derive(Serialize)]
pub struct UserResponse {
    pub id: String,
    pub username: String,
    pub created_at: String,
}

#[derive(Serialize)]
pub struct SessionResponse {
    pub access_token: String,
    pub token_type: &'static str,
    pub expires_at: String,
    pub user: UserResponse,
}

async fn register(
    State(state): State<AppState>,
    Json(credentials): Json<Credentials>,
) -> Result<Json<SessionResponse>, ApiError> {
    if !state.config.registration_enabled {
        return Err(ApiError::Forbidden);
    }
    validate_credentials(&credentials)?;
    if state
        .database
        .find_user_by_username(&credentials.username)?
        .is_some()
    {
        return Err(ApiError::Conflict("用户名已存在".to_owned()));
    }

    let password_hash = hash_password(&credentials.password)?;
    let now = now_millis();
    let user = state.database.create_user(
        &Uuid::new_v4().to_string(),
        &credentials.username,
        &password_hash,
        &now,
    )?;
    create_session(&state, user)
}

async fn login(
    State(state): State<AppState>,
    Json(credentials): Json<Credentials>,
) -> Result<Json<SessionResponse>, ApiError> {
    validate_credentials(&credentials)?;
    let Some(user) = state
        .database
        .find_user_by_username(&credentials.username)?
    else {
        return Err(ApiError::Unauthorized);
    };
    let Some(password_hash) = user.password_hash.as_deref() else {
        return Err(ApiError::Unauthorized);
    };
    let parsed_hash = PasswordHash::new(password_hash).map_err(|_| ApiError::Unauthorized)?;
    Argon2::default()
        .verify_password(credentials.password.as_bytes(), &parsed_hash)
        .map_err(|_| ApiError::Unauthorized)?;
    create_session(&state, user)
}

async fn logout(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<LogoutResponse>, ApiError> {
    let token = bearer_token(&headers).ok_or(ApiError::Unauthorized)?;
    state.database.delete_session(&hash_token(token))?;
    Ok(Json(LogoutResponse { logged_out: true }))
}

async fn me(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<UserResponse>, ApiError> {
    let user = current_user(&state, &headers)?;
    Ok(Json(user_response(user)))
}

pub fn current_user(state: &AppState, headers: &HeaderMap) -> Result<UserRecord, ApiError> {
    let token = bearer_token(headers).ok_or(ApiError::Unauthorized)?;
    let user_id = state
        .database
        .find_user_id_by_session(&hash_token(token), &now_millis())?
        .ok_or(ApiError::Unauthorized)?;
    state
        .database
        .find_user_by_id(&user_id)?
        .ok_or(ApiError::Unauthorized)
}

fn create_session(state: &AppState, user: UserRecord) -> Result<Json<SessionResponse>, ApiError> {
    let access_token = Uuid::new_v4().to_string();
    let created_at = now_millis();
    let expires_at_value = SystemTime::now()
        .checked_add(Duration::from_secs(
            state.config.session_ttl_days.saturating_mul(86_400),
        ))
        .ok_or_else(|| anyhow::anyhow!("session expiry overflow"))?
        .duration_since(UNIX_EPOCH)
        .map_err(|error| anyhow::anyhow!(error))?
        .as_millis();
    let expires_at = expires_at_value.to_string();
    state.database.create_session(
        &Uuid::new_v4().to_string(),
        &user.id,
        &hash_token(&access_token),
        &created_at,
        &expires_at,
    )?;
    Ok(Json(SessionResponse {
        access_token,
        token_type: "Bearer",
        expires_at,
        user: user_response(user),
    }))
}

fn validate_credentials(credentials: &Credentials) -> Result<(), ApiError> {
    let username_length = credentials.username.chars().count();
    if !(3..=64).contains(&username_length) {
        return Err(ApiError::BadRequest(
            "用户名长度必须为 3 到 64 个字符".to_owned(),
        ));
    }
    if credentials.username.trim() != credentials.username {
        return Err(ApiError::BadRequest("用户名不能包含首尾空格".to_owned()));
    }
    if !(8..=256).contains(&credentials.password.chars().count()) {
        return Err(ApiError::BadRequest(
            "密码长度必须为 8 到 256 个字符".to_owned(),
        ));
    }
    Ok(())
}

fn hash_password(password: &str) -> Result<String, ApiError> {
    let salt = SaltString::generate(&mut OsRng);
    Argon2::default()
        .hash_password(password.as_bytes(), &salt)
        .map(|hash| hash.to_string())
        .map_err(|error| anyhow::anyhow!(error).into())
}

fn bearer_token(headers: &HeaderMap) -> Option<&str> {
    headers
        .get(AUTHORIZATION)
        .and_then(|value| value.to_str().ok())
        .and_then(|value| value.strip_prefix("Bearer "))
        .filter(|value| !value.trim().is_empty())
}

fn hash_token(token: &str) -> String {
    let mut hasher = Sha256::new();
    hasher.update(token.as_bytes());
    format!("{:x}", hasher.finalize())
}

pub(crate) fn now_millis() -> String {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("system clock should be after Unix epoch")
        .as_millis()
        .to_string()
}

fn user_response(user: UserRecord) -> UserResponse {
    UserResponse {
        id: user.id,
        username: user.username,
        created_at: user.created_at,
    }
}

#[derive(Serialize)]
struct LogoutResponse {
    logged_out: bool,
}
