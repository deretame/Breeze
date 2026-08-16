use axum::{
    Json,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use serde::Serialize;

pub enum ApiError {
    BadRequest(String),
    Unauthorized,
    Forbidden,
    Conflict(String),
    NotFound,
    Internal(anyhow::Error),
}

impl From<anyhow::Error> for ApiError {
    fn from(error: anyhow::Error) -> Self {
        Self::Internal(error)
    }
}

impl From<serde_json::Error> for ApiError {
    fn from(error: serde_json::Error) -> Self {
        Self::Internal(error.into())
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, code, message) = match self {
            Self::BadRequest(message) => (StatusCode::BAD_REQUEST, "bad_request", message),
            Self::Unauthorized => (
                StatusCode::UNAUTHORIZED,
                "unauthorized",
                "需要登录".to_owned(),
            ),
            Self::Forbidden => (StatusCode::FORBIDDEN, "forbidden", "没有权限".to_owned()),
            Self::Conflict(message) => (StatusCode::CONFLICT, "conflict", message),
            Self::NotFound => (StatusCode::NOT_FOUND, "not_found", "资源不存在".to_owned()),
            Self::Internal(error) => {
                tracing::error!(error = %error, "CS API request failed");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "internal_error",
                    "服务端内部错误".to_owned(),
                )
            }
        };
        (status, Json(ErrorResponse { code, message })).into_response()
    }
}

#[derive(Serialize)]
struct ErrorResponse {
    code: &'static str,
    message: String,
}
