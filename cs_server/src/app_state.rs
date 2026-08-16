use std::sync::Arc;

use reqwest::Client;

use crate::config::ServerConfig;
use crate::db::Database;

#[derive(Clone)]
pub struct AppState {
    pub config: Arc<ServerConfig>,
    pub database: Database,
    #[allow(dead_code)]
    pub http_client: Client,
    pub http_config: rquickjs_playground::HttpClientConfig,
    pub websocket_hub: Arc<crate::websocket::WebSocketHub>,
    pub plugin_capabilities: crate::plugin::PluginRuntimeCapabilities,
    pub plugin_runtime: Arc<crate::plugin::PluginRuntimeService>,
}

impl AppState {
    pub fn new(
        config: Arc<ServerConfig>,
        database: Database,
        http_config: rquickjs_playground::HttpClientConfig,
        http_client: Client,
    ) -> anyhow::Result<Self> {
        let websocket_hub = Arc::new(crate::websocket::WebSocketHub::default());
        let plugin_runtime = Arc::new(crate::plugin::PluginRuntimeService::new(
            database.clone(),
            Arc::clone(&websocket_hub),
        )?);
        Ok(Self {
            config,
            database,
            http_client,
            http_config,
            websocket_hub,
            plugin_capabilities: crate::plugin::PluginRuntimeCapabilities::default(),
            plugin_runtime,
        })
    }
}
