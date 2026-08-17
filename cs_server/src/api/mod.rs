mod admin;
pub mod auth;
mod downloads;
pub(crate) mod error;
mod library;
mod plugin_api;
mod plugin_config;
mod plugin_store;
mod settings;

use axum::{
    Json, Router,
    extract::State,
    routing::{get, post},
};
use serde::Serialize;
use serde_json::Value;

use crate::app_state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/health", get(health))
        .route("/capabilities", get(capabilities))
        .route("/ws", get(crate::websocket::upgrade))
        .route("/plugins/catalog", get(plugin_store::catalog))
        .route(
            "/plugins/catalog/install",
            post(plugin_store::install_catalog),
        )
        .route("/plugins/install-url", post(plugin_store::install_url))
        .route(
            "/plugins/install-bundle",
            post(plugin_store::install_bundle),
        )
        .route("/plugins", get(plugins))
        .route("/plugins/{plugin_id}", get(plugin_api::plugin_detail))
        .route("/plugins/{plugin_id}/invoke", post(plugin_api::invoke))
        .route(
            "/plugins/{plugin_id}/invoke-bytes",
            post(plugin_api::invoke_bytes),
        )
        .route(
            "/plugins/{plugin_id}/config",
            get(plugin_config::get).patch(plugin_config::update),
        )
        .route("/plugins/{plugin_id}/search", post(plugin_api::search))
        .route(
            "/plugins/{plugin_id}/comic/{comic_id}/detail",
            post(plugin_api::detail),
        )
        .route(
            "/plugins/{plugin_id}/comic/{comic_id}/chapter/{chapter_id}",
            post(plugin_api::chapter),
        )
        .route(
            "/plugins/{plugin_id}/comic/{comic_id}/read",
            post(plugin_api::read),
        )
        .nest("/admin", admin::router())
        .nest("/downloads", downloads::router())
        .nest("/auth", auth::router())
        .route(
            "/settings/account",
            get(settings::get_account_settings).patch(settings::update_account_settings),
        )
        .nest("/library", library::router())
}

async fn health(State(state): State<AppState>) -> Json<HealthResponse> {
    let database = state.database.schema_version();
    Json(HealthResponse {
        status: "ok",
        service: "breeze-cs-server",
        version: env!("CARGO_PKG_VERSION"),
        db_schema_version: database.unwrap_or_default(),
        web_frontend: state.config.web_frontend_enabled(),
        server_download: state.config.server_download_enabled,
    })
}

async fn capabilities(State(state): State<AppState>) -> Json<CapabilitiesResponse> {
    Json(CapabilitiesResponse {
        protocol_version: "v1",
        server_version: env!("CARGO_PKG_VERSION"),
        server_download: state.config.server_download_enabled,
        browser_frontend: state.config.web_frontend_enabled(),
        plugin_runtime: PluginRuntimeCapabilityResponse {
            quickjs: state.plugin_capabilities.quickjs,
            filesystem: state.plugin_capabilities.filesystem,
            cancellation: state.plugin_capabilities.cancellation,
        },
        plugin_management: state.config.plugin_install_enabled,
        authentication: AuthenticationCapabilityResponse {
            bearer_sessions: true,
            registration: state.config.registration_enabled,
        },
        http: HttpCapabilityResponse {
            shared_reqwest_client: true,
            tls_verification_disabled: state.http_config.disable_tls_verify,
            private_network_allowed: state.http_config.allow_private_network,
        },
    })
}

async fn plugins(State(state): State<AppState>) -> Json<PluginsResponse> {
    let records = state.database.list_plugins().unwrap_or_default();
    let mut items = Vec::with_capacity(records.len());
    for record in records {
        let name = plugin_api::invoke_json_for_user(
            &state,
            "__plugin_catalog__",
            &record.plugin_id,
            "getInfo",
            &Value::Array(Vec::new()),
        )
        .await
        .ok()
        .and_then(|value| value.get("name").and_then(Value::as_str).map(str::to_owned));
        items.push(PluginResponse {
            plugin_id: record.plugin_id,
            name,
            version: record.version,
            bundle_hash: record.bundle_hash,
            enabled: record.enabled,
            updated_at: record.updated_at,
        });
    }
    Json(PluginsResponse { items })
}

#[derive(Serialize)]
struct HealthResponse {
    status: &'static str,
    service: &'static str,
    version: &'static str,
    db_schema_version: i64,
    web_frontend: bool,
    server_download: bool,
}

#[derive(Serialize)]
struct CapabilitiesResponse {
    protocol_version: &'static str,
    server_version: &'static str,
    server_download: bool,
    browser_frontend: bool,
    plugin_runtime: PluginRuntimeCapabilityResponse,
    authentication: AuthenticationCapabilityResponse,
    http: HttpCapabilityResponse,
    plugin_management: bool,
}

#[derive(Serialize)]
struct PluginRuntimeCapabilityResponse {
    quickjs: bool,
    filesystem: bool,
    cancellation: bool,
}

#[derive(Serialize)]
struct AuthenticationCapabilityResponse {
    bearer_sessions: bool,
    registration: bool,
}

#[derive(Serialize)]
struct HttpCapabilityResponse {
    shared_reqwest_client: bool,
    tls_verification_disabled: bool,
    private_network_allowed: bool,
}

#[derive(Serialize)]
struct PluginsResponse {
    items: Vec<PluginResponse>,
}

#[derive(Serialize)]
struct PluginResponse {
    plugin_id: String,
    name: Option<String>,
    version: String,
    bundle_hash: String,
    enabled: bool,
    updated_at: String,
}
