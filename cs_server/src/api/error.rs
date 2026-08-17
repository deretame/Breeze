use axum::{
    Json,
    http::StatusCode,
    response::{IntoResponse, Response},
};
use serde::Serialize;
use serde_json::Value;

#[derive(Debug)]
pub enum ApiError {
    BadRequest(String),
    Unauthorized,
    Forbidden,
    Conflict(String),
    PluginBrowserLoginUnsupported,
    PluginUnauthorized(Value),
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

impl From<std::io::Error> for ApiError {
    fn from(error: std::io::Error) -> Self {
        Self::Internal(error.into())
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let (status, code, message, details) = match self {
            Self::BadRequest(message) => (StatusCode::BAD_REQUEST, "bad_request", message, None),
            Self::Unauthorized => (
                StatusCode::UNAUTHORIZED,
                "unauthorized",
                "需要登录".to_owned(),
                None,
            ),
            Self::Forbidden => (
                StatusCode::FORBIDDEN,
                "forbidden",
                "没有权限".to_owned(),
                None,
            ),
            Self::Conflict(message) => (StatusCode::CONFLICT, "conflict", message, None),
            Self::PluginBrowserLoginUnsupported => (
                StatusCode::UNPROCESSABLE_ENTITY,
                "plugin_browser_login_unsupported",
                "CS 模式不支持插件浏览器登录".to_owned(),
                None,
            ),
            Self::PluginUnauthorized(details) => (
                StatusCode::UNAUTHORIZED,
                "plugin_unauthorized",
                details
                    .get("message")
                    .and_then(Value::as_str)
                    .unwrap_or("插件登录已失效，请重新登录")
                    .to_owned(),
                Some(details),
            ),
            Self::NotFound => (
                StatusCode::NOT_FOUND,
                "not_found",
                "资源不存在".to_owned(),
                None,
            ),
            Self::Internal(error) => {
                tracing::error!(error = %error, "CS API request failed");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    "internal_error",
                    "服务端内部错误".to_owned(),
                    None,
                )
            }
        };
        (
            status,
            Json(ErrorResponse {
                code,
                message,
                details,
            }),
        )
            .into_response()
    }
}

#[derive(Serialize)]
struct ErrorResponse {
    code: &'static str,
    message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    details: Option<Value>,
}
