use axum::{Json, Router, extract::State, routing::get};
use serde::Serialize;

use crate::app_state::AppState;

pub fn router() -> Router<AppState> {
    Router::new()
        .route("/health", get(health))
        .route("/capabilities", get(capabilities))
        .route("/plugins", get(plugins))
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
            quickjs: state.plugin_runtime.quickjs,
            filesystem: state.plugin_runtime.filesystem,
            cancellation: state.plugin_runtime.cancellation,
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
    Json(PluginsResponse {
        items: records
            .into_iter()
            .map(|record| PluginResponse {
                plugin_id: record.plugin_id,
                version: record.version,
                bundle_hash: record.bundle_hash,
                enabled: record.enabled,
                updated_at: record.updated_at,
            })
            .collect(),
    })
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
    http: HttpCapabilityResponse,
}

#[derive(Serialize)]
struct PluginRuntimeCapabilityResponse {
    quickjs: bool,
    filesystem: bool,
    cancellation: bool,
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
    version: String,
    bundle_hash: String,
    enabled: bool,
    updated_at: String,
}
