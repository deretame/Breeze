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
    pub plugin_runtime: crate::plugin::PluginRuntimeCapabilities,
}

impl AppState {
    pub fn new(
        config: Arc<ServerConfig>,
        database: Database,
        http_config: rquickjs_playground::HttpClientConfig,
        http_client: Client,
    ) -> Self {
        Self {
            config,
            database,
            http_client,
            http_config,
            plugin_runtime: crate::plugin::PluginRuntimeCapabilities::default(),
        }
    }
}
