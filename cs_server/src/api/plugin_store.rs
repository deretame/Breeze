use axum::{
    Json,
    extract::{Path as AxumPath, State},
    http::{HeaderMap, StatusCode},
};
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
    plugin_api,
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
    #[serde(default)]
    expected_plugin_id: Option<String>,
}

#[derive(Deserialize)]
pub struct BundleInstallRequest {
    file_name: String,
    bundle_base64: String,
    #[serde(default)]
    expected_plugin_id: Option<String>,
}

#[derive(Deserialize)]
pub struct UpdatePluginStateRequest {
    pub enabled: Option<bool>,
    pub debug: Option<bool>,
    pub debug_url: Option<String>,
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
    let user_id = authorize_plugin_install(&state, &headers)?;
    let plugin_id = request.plugin_id.trim();
    if plugin_id.is_empty() {
        return Err(ApiError::BadRequest("plugin_id 不能为空".to_owned()));
    }

    let catalog = plugin_store::fetch_catalog(&state.http_client).await?;
    let item = catalog
        .iter()
        .find(|item| item.manifest.uuid == plugin_id)
        .ok_or_else(|| ApiError::NotFound)?;
    let response = install_catalog_item(&state, item).await?;
    link_user_plugin(&state, &user_id, &response)?;
    Ok(Json(response))
}

pub(crate) async fn install_catalog_item(
    state: &AppState,
    item: &CloudPluginItem,
) -> Result<InstallPluginResponse, ApiError> {
    let bundle = plugin_store::download_catalog_bundle(&state.http_client, item).await?;
    install_validated_bundle(state, &item.manifest.uuid, &item.manifest.version, &bundle).await
}

pub async fn install_url(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(request): Json<UrlInstallRequest>,
) -> Result<Json<InstallPluginResponse>, ApiError> {
    let user_id = authorize_plugin_install(&state, &headers)?;
    let url = request.url.trim();
    if url.is_empty() {
        return Err(ApiError::BadRequest("插件 URL 不能为空".to_owned()));
    }
    let bundle = plugin_store::download_bundle_from_url(&state.http_client, url).await?;
    let response = install_validated_bundle(
        &state,
        request.expected_plugin_id.as_deref().unwrap_or_default(),
        "0.0.0",
        &bundle,
    )
    .await?;
    link_user_plugin(&state, &user_id, &response)?;
    Ok(Json(response))
}

pub async fn install_bundle(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(request): Json<BundleInstallRequest>,
) -> Result<Json<InstallPluginResponse>, ApiError> {
    let user_id = authorize_plugin_install(&state, &headers)?;
    let bytes = BASE64
        .decode(request.bundle_base64.trim())
        .map_err(|error| ApiError::BadRequest(format!("插件 bundle 不是合法 Base64: {error}")))?;
    let bundle = plugin_store::decode_plugin_bundle(
        &bytes,
        request.file_name.to_ascii_lowercase().ends_with(".br"),
    )?;
    let response = install_validated_bundle(
        &state,
        request.expected_plugin_id.as_deref().unwrap_or_default(),
        "0.0.0",
        &bundle,
    )
    .await?;
    link_user_plugin(&state, &user_id, &response)?;
    Ok(Json(response))
}

pub async fn update_state(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(plugin_id): AxumPath<String>,
    Json(request): Json<UpdatePluginStateRequest>,
) -> Result<Json<plugin_api::PluginDetailResponse>, ApiError> {
    let user = current_user(&state, &headers)?;
    let current = state
        .database
        .find_user_plugin(&user.id, &plugin_id)?
        .ok_or(ApiError::NotFound)?;
    let debug_url = request
        .debug_url
        .or(current.debug_url)
        .map(|url| url.trim().to_owned())
        .filter(|url| !url.is_empty());
    state.database.upsert_user_plugin(
        &user.id,
        &plugin_id,
        request.enabled.unwrap_or(current.enabled),
        request.debug.unwrap_or(current.debug),
        debug_url.as_deref(),
        &super::auth::now_millis(),
    )?;
    if request.enabled == Some(false) {
        state
            .plugin_runtime
            .drop_plugin_runtime(&user.id, &plugin_id);
    }
    Ok(Json(
        plugin_api::plugin_detail_for_user(&state, &user.id, &plugin_id).await?,
    ))
}

pub async fn uninstall(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(plugin_id): AxumPath<String>,
) -> Result<StatusCode, ApiError> {
    let user = current_user(&state, &headers)?;
    if state
        .database
        .find_user_plugin(&user.id, &plugin_id)?
        .is_none()
    {
        return Err(ApiError::NotFound);
    }
    state.database.remove_user_plugin(&user.id, &plugin_id)?;
    state.database.delete_plugin_config(&user.id, &plugin_id)?;
    state
        .plugin_runtime
        .drop_plugin_runtime(&user.id, &plugin_id);
    Ok(StatusCode::NO_CONTENT)
}

pub(crate) async fn install_validated_bundle(
    state: &AppState,
    expected_plugin_id: &str,
    fallback_version: &str,
    bundle: &str,
) -> Result<InstallPluginResponse, ApiError> {
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
    Ok(admin::install_bundle(state, &plugin_id, &version, bundle, true).await?)
}

fn link_user_plugin(
    state: &AppState,
    user_id: &str,
    plugin: &InstallPluginResponse,
) -> Result<(), ApiError> {
    let current = state
        .database
        .find_user_plugin(user_id, &plugin.plugin_id)?;
    state.database.upsert_user_plugin(
        user_id,
        &plugin.plugin_id,
        current
            .as_ref()
            .map(|item| item.enabled)
            .unwrap_or(plugin.enabled),
        current.as_ref().map(|item| item.debug).unwrap_or(false),
        current.as_ref().and_then(|item| item.debug_url.as_deref()),
        &super::auth::now_millis(),
    )?;
    Ok(())
}

fn authorize_plugin_install(state: &AppState, headers: &HeaderMap) -> Result<String, ApiError> {
    if !state.config.plugin_install_enabled {
        return Err(ApiError::Forbidden);
    }
    Ok(current_user(state, headers)?.id)
}
