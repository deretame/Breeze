use axum::{Json, extract::State, http::HeaderMap};
use base64::{Engine as _, engine::general_purpose::STANDARD as BASE64};
use serde::{Deserialize, Serialize};
use serde_json::json;

use crate::{
    app_state::AppState,
    plugin_store::{self, CloudPluginItem},
};

use super::{
    admin::{self, InstallPluginResponse},
    auth::current_user,
    error::ApiError,
};

#[derive(Serialize)]
pub struct CatalogResponse {
    pub items: Vec<CloudPluginItem>,
    pub source: &'static str,
}

#[derive(Deserialize)]
pub struct CatalogInstallRequest {
    plugin_id: String,
}

#[derive(Deserialize)]
pub struct UrlInstallRequest {
    url: String,
}

#[derive(Deserialize)]
pub struct BundleInstallRequest {
    file_name: String,
    bundle_base64: String,
}

pub async fn catalog(State(state): State<AppState>) -> Result<Json<CatalogResponse>, ApiError> {
    let items = plugin_store::fetch_catalog(&state.http_client).await?;
    Ok(Json(CatalogResponse {
        items,
        source: "https://api.windy-78.site/plugin-list",
    }))
}

pub async fn install_catalog(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(request): Json<CatalogInstallRequest>,
) -> Result<Json<InstallPluginResponse>, ApiError> {
    authorize_plugin_install(&state, &headers)?;
    let plugin_id = request.plugin_id.trim();
    if plugin_id.is_empty() {
        return Err(ApiError::BadRequest("plugin_id 不能为空".to_owned()));
    }

    let catalog = plugin_store::fetch_catalog(&state.http_client).await?;
    let item = catalog
        .iter()
        .find(|item| item.manifest.uuid == plugin_id)
        .ok_or_else(|| ApiError::NotFound)?;
    let bundle = plugin_store::download_catalog_bundle(&state.http_client, item).await?;
    install_validated_bundle(&state, &item.manifest.uuid, &item.manifest.version, &bundle).await
}

pub async fn install_url(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(request): Json<UrlInstallRequest>,
) -> Result<Json<InstallPluginResponse>, ApiError> {
    authorize_plugin_install(&state, &headers)?;
    let url = request.url.trim();
    if url.is_empty() {
        return Err(ApiError::BadRequest("插件 URL 不能为空".to_owned()));
    }
    let bundle = plugin_store::download_bundle_from_url(&state.http_client, url).await?;
    install_validated_bundle(&state, "", "0.0.0", &bundle).await
}

pub async fn install_bundle(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(request): Json<BundleInstallRequest>,
) -> Result<Json<InstallPluginResponse>, ApiError> {
    authorize_plugin_install(&state, &headers)?;
    let bytes = BASE64
        .decode(request.bundle_base64.trim())
        .map_err(|error| ApiError::BadRequest(format!("插件 bundle 不是合法 Base64: {error}")))?;
    let bundle = plugin_store::decode_plugin_bundle(
        &bytes,
        request.file_name.to_ascii_lowercase().ends_with(".br"),
    )?;
    install_validated_bundle(&state, "", "0.0.0", &bundle).await
}

async fn install_validated_bundle(
    state: &AppState,
    expected_plugin_id: &str,
    fallback_version: &str,
    bundle: &str,
) -> Result<Json<InstallPluginResponse>, ApiError> {
    let info = state
        .plugin_runtime
        .invoke_json(
            "plugin-store",
            if expected_plugin_id.is_empty() {
                "pending"
            } else {
                expected_plugin_id
            },
            bundle,
            "getInfo",
            &json!([]),
        )
        .await
        .map_err(|error| anyhow::anyhow!(error))?;
    let plugin_id = plugin_store::plugin_info_field(&info, "uuid");
    if plugin_id.is_empty() {
        return Err(ApiError::BadRequest("插件 getInfo 缺少 uuid".to_owned()));
    }
    if !expected_plugin_id.is_empty() && plugin_id != expected_plugin_id {
        return Err(ApiError::BadRequest(format!(
            "插件 id 不一致，期望={expected_plugin_id}, 实际={plugin_id}"
        )));
    }
    let version = {
        let version = plugin_store::plugin_info_field(&info, "version");
        if version.is_empty() {
            fallback_version.to_owned()
        } else {
            version
        }
    };
    admin::validate_plugin_id(&plugin_id)?;
    Ok(Json(
        admin::install_bundle(state, &plugin_id, &version, bundle, true).await?,
    ))
}

fn authorize_plugin_install(state: &AppState, headers: &HeaderMap) -> Result<(), ApiError> {
    if !state.config.plugin_install_enabled {
        return Err(ApiError::Forbidden);
    }
    let _ = current_user(state, headers)?;
    Ok(())
}
