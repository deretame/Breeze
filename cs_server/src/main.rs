mod api;
mod app_state;
mod config;
mod db;
mod http;
mod plugin;
mod websocket;

use std::sync::Arc;

use anyhow::Context;
use tokio::net::TcpListener;
use tracing::info;

use crate::app_state::AppState;
use crate::config::ServerConfig;
use crate::db::Database;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            std::env::var("RUST_LOG")
                .unwrap_or_else(|_| "breeze_cs_server=info,tower_http=info".to_owned()),
        )
        .init();

    let config = Arc::new(ServerConfig::from_env()?);
    let database = Database::open(&config.data_dir)?;

    let http_config = config.http_client_config();
    rquickjs_playground::configure_http_client(http_config.clone())
        .context("failed to configure the global QuickJS HTTP client")?;
    let http_client = rquickjs_playground::build_http_client(&http_config)
        .context("failed to build the shared reqwest client")?;

    let state = AppState::new(config.clone(), database, http_config, http_client)
        .context("failed to initialize CS application state")?;
    let router = http::build_router(state.clone());
    let listener = TcpListener::bind(config.bind_addr())
        .await
        .with_context(|| format!("failed to bind {}", config.bind_addr()))?;

    info!(
        address = %listener.local_addr()?,
        data_dir = %config.data_dir.display(),
        web_root = %config.web_root.display(),
        web_frontend = config.web_frontend_enabled(),
        admin_token_configured = config.admin_token.is_some(),
        server_download = config.server_download_enabled,
        "Breeze CS server started"
    );

    axum::serve(listener, router)
        .with_graceful_shutdown(shutdown_signal())
        .await
        .context("CS server stopped unexpectedly")?;

    Ok(())
}

async fn shutdown_signal() {
    #[cfg(unix)]
    {
        use tokio::signal::unix::{SignalKind, signal};

        let mut interrupt = signal(SignalKind::interrupt()).expect("install SIGINT handler");
        let mut terminate = signal(SignalKind::terminate()).expect("install SIGTERM handler");

        tokio::select! {
            _ = interrupt.recv() => {},
            _ = terminate.recv() => {},
            _ = tokio::signal::ctrl_c() => {},
        }
    }

    #[cfg(not(unix))]
    {
        tokio::signal::ctrl_c()
            .await
            .expect("install Ctrl+C handler");
    }

    info!("shutdown signal received");
}
