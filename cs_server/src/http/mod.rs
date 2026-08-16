use axum::Router;
use tower_http::cors::CorsLayer;
use tower_http::services::{ServeDir, ServeFile};
use tower_http::trace::TraceLayer;

use crate::api;
use crate::app_state::AppState;

pub fn build_router(state: AppState) -> Router {
    let web_root = state.config.web_root.clone();
    let index_file = web_root.join("index.html");
    let static_service = ServeDir::new(web_root).fallback(ServeFile::new(index_file));

    Router::new()
        .nest("/api/v1", api::router())
        .fallback_service(static_service)
        .layer(TraceLayer::new_for_http())
        .layer(cors_layer(&state))
        .with_state(state)
}

fn cors_layer(state: &AppState) -> CorsLayer {
    let base = CorsLayer::new()
        .allow_methods(tower_http::cors::Any)
        .allow_headers(tower_http::cors::Any);

    match state.config.cors_origin.clone() {
        Some(origin) => base.allow_origin(origin),
        None => base,
    }
}
