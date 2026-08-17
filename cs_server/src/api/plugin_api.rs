use std::path::{Path, PathBuf};

use axum::{
    Json,
    body::Body,
    extract::{Path as AxumPath, State},
    http::{HeaderMap, StatusCode, header::CONTENT_TYPE},
    response::Response,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::app_state::AppState;

use super::{auth::current_user, error::ApiError};

#[derive(Deserialize)]
pub struct InvokeRequest {
    pub function: String,
    pub args: Value,
    #[serde(default, rename = "taskGroupKey")]
    pub task_group_key: Option<String>,
}

#[derive(Deserialize)]
pub struct CancelTaskGroupRequest {
    #[serde(rename = "taskGroupKey")]
    pub task_group_key: String,
}

#[derive(Default, Deserialize)]
pub struct SemanticRequest {
    #[serde(default)]
    pub core: Value,
    #[serde(default, rename = "extern")]
    pub extern_data: Value,
}

#[derive(Serialize)]
pub struct PluginDetailResponse {
    pub plugin_id: String,
    pub name: Option<String>,
    pub info: Value,
    pub version: String,
    pub bundle_hash: String,
    pub enabled: bool,
    pub debug: bool,
    pub debug_url: Option<String>,
    pub updated_at: String,
}

#[derive(Serialize)]
pub struct PluginListResponse {
    pub items: Vec<PluginDetailResponse>,
}

pub async fn plugin_detail(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(plugin_id): AxumPath<String>,
) -> Result<Json<PluginDetailResponse>, ApiError> {
    let user = current_user(&state, &headers)?;
    Ok(Json(
        plugin_detail_for_user(&state, &user.id, &plugin_id).await?,
    ))
}

pub async fn list(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Json<PluginListResponse>, ApiError> {
    let user = current_user(&state, &headers)?;
    let plugins = state.database.list_user_plugins(&user.id)?;
    let mut items = Vec::with_capacity(plugins.len());
    for plugin in plugins {
        items.push(plugin_detail_for_user(&state, &user.id, &plugin.plugin_id).await?);
    }
    Ok(Json(PluginListResponse { items }))
}

pub async fn invoke(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(plugin_id): AxumPath<String>,
    Json(request): Json<InvokeRequest>,
) -> Result<Json<Value>, ApiError> {
    let user = current_user(&state, &headers)?;
    validate_invoke_request(&request)?;
    let value = invoke_json_for_user_with_task_group(
        &state,
        &user.id,
        &plugin_id,
        &request.function,
        &request.args,
        request.task_group_key.as_deref(),
    )
    .await?;
    Ok(Json(value))
}

pub async fn invoke_bytes(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(plugin_id): AxumPath<String>,
    Json(request): Json<InvokeRequest>,
) -> Result<Response, ApiError> {
    let user = current_user(&state, &headers)?;
    validate_invoke_request(&request)?;
    let bytes = invoke_bytes_for_user_with_task_group(
        &state,
        &user.id,
        &plugin_id,
        &request.function,
        &request.args,
        request.task_group_key.as_deref(),
    )
    .await?;
    Response::builder()
        .status(StatusCode::OK)
        .header(CONTENT_TYPE, "application/octet-stream")
        .body(Body::from(bytes))
        .map_err(|error| anyhow::anyhow!(error).into())
}

pub async fn cancel_task_group(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(plugin_id): AxumPath<String>,
    Json(request): Json<CancelTaskGroupRequest>,
) -> Result<Json<Value>, ApiError> {
    let user = current_user(&state, &headers)?;
    validate_task_group_key(&request.task_group_key)?;
    let _ = plugin_for_user(&state, &user.id, &plugin_id)?;
    state
        .plugin_runtime
        .cancel_task_group(&user.id, &request.task_group_key);
    Ok(Json(serde_json::json!({
        "cancelled": true,
        "taskGroupKey": request.task_group_key,
    })))
}

pub async fn search(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath(plugin_id): AxumPath<String>,
    Json(request): Json<SemanticRequest>,
) -> Result<Json<Value>, ApiError> {
    semantic_invoke(&state, &headers, &plugin_id, "searchComic", request).await
}

pub async fn detail(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath((plugin_id, comic_id)): AxumPath<(String, String)>,
    Json(mut request): Json<SemanticRequest>,
) -> Result<Json<Value>, ApiError> {
    merge_string_field(&mut request.core, "comicId", comic_id)?;
    semantic_invoke(&state, &headers, &plugin_id, "getComicDetail", request).await
}

pub async fn chapter(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath((plugin_id, comic_id, chapter_id)): AxumPath<(String, String, String)>,
    Json(mut request): Json<SemanticRequest>,
) -> Result<Json<Value>, ApiError> {
    merge_string_field(&mut request.core, "comicId", comic_id)?;
    merge_string_field(&mut request.core, "chapterId", chapter_id)?;
    semantic_invoke(&state, &headers, &plugin_id, "getChapter", request).await
}

pub async fn read(
    State(state): State<AppState>,
    headers: HeaderMap,
    AxumPath((plugin_id, comic_id)): AxumPath<(String, String)>,
    Json(mut request): Json<SemanticRequest>,
) -> Result<Json<Value>, ApiError> {
    merge_string_field(&mut request.core, "comicId", comic_id)?;
    semantic_invoke(&state, &headers, &plugin_id, "getReadSnapshot", request).await
}

async fn semantic_invoke(
    state: &AppState,
    headers: &HeaderMap,
    plugin_id: &str,
    function: &str,
    request: SemanticRequest,
) -> Result<Json<Value>, ApiError> {
    let user = current_user(state, headers)?;
    let args = build_plugin_args(request)?;
    Ok(Json(
        invoke_json_for_user(state, &user.id, plugin_id, function, &args).await?,
    ))
}

fn build_plugin_args(request: SemanticRequest) -> Result<Value, ApiError> {
    let mut core = match request.core {
        Value::Object(map) => map,
        Value::Null => serde_json::Map::new(),
        _ => return Err(ApiError::BadRequest("core 必须是 JSON 对象".to_owned())),
    };
    let extern_data = match request.extern_data {
        Value::Object(map) => Value::Object(map),
        Value::Null => Value::Object(serde_json::Map::new()),
        _ => return Err(ApiError::BadRequest("extern 必须是 JSON 对象".to_owned())),
    };
    core.insert("extern".to_owned(), extern_data);
    Ok(Value::Array(vec![Value::Object(core)]))
}

fn merge_string_field(target: &mut Value, field: &str, value: String) -> Result<(), ApiError> {
    let map = target
        .as_object_mut()
        .ok_or_else(|| ApiError::BadRequest("core 必须是 JSON 对象".to_owned()))?;
    map.insert(field.to_owned(), Value::String(value));
    Ok(())
}

pub(crate) async fn invoke_json_for_user(
    state: &AppState,
    user_id: &str,
    plugin_id: &str,
    function: &str,
    args: &Value,
) -> Result<Value, ApiError> {
    invoke_json_for_user_with_task_group(state, user_id, plugin_id, function, args, None).await
}

pub(crate) async fn invoke_json_for_user_with_task_group(
    state: &AppState,
    user_id: &str,
    plugin_id: &str,
    function: &str,
    args: &Value,
    task_group_key: Option<&str>,
) -> Result<Value, ApiError> {
    let (plugin, user_plugin) = plugin_for_user(state, user_id, plugin_id)?;
    if !plugin.enabled || !user_plugin.enabled {
        return Err(ApiError::Conflict("插件未启用".to_owned()));
    }
    let bundle_source = load_bundle_for_user(state, &plugin, &user_plugin).await?;
    let value = state
        .plugin_runtime
        .invoke_json_with_task_group(
            user_id,
            plugin_id,
            &bundle_source,
            function,
            args,
            task_group_key,
        )
        .await
        .map_err(map_plugin_runtime_error)?;
    if matches!(function, "getSettingsBundle" | "getCapabilitiesBundle") {
        return Ok(filter_browser_login_settings(value));
    }
    if contains_browser_login_descriptor(&value) {
        return Err(ApiError::PluginBrowserLoginUnsupported);
    }
    Ok(value)
}

pub(crate) async fn invoke_bytes_for_user_with_task_group(
    state: &AppState,
    user_id: &str,
    plugin_id: &str,
    function: &str,
    args: &Value,
    task_group_key: Option<&str>,
) -> Result<Vec<u8>, ApiError> {
    let (plugin, user_plugin) = plugin_for_user(state, user_id, plugin_id)?;
    if !plugin.enabled || !user_plugin.enabled {
        return Err(ApiError::Conflict("插件未启用".to_owned()));
    }
    let bundle_source = load_bundle_for_user(state, &plugin, &user_plugin).await?;
    let result = match task_group_key {
        Some(task_group_key) => {
            state
                .plugin_runtime
                .invoke_bytes_with_task_group(
                    user_id,
                    plugin_id,
                    &bundle_source,
                    function,
                    args,
                    Some(task_group_key),
                )
                .await
        }
        None => {
            state
                .plugin_runtime
                .invoke_bytes(user_id, plugin_id, &bundle_source, function, args)
                .await
        }
    };
    result.map_err(map_plugin_runtime_error)
}

pub(crate) async fn plugin_detail_for_user(
    state: &AppState,
    user_id: &str,
    plugin_id: &str,
) -> Result<PluginDetailResponse, ApiError> {
    let (plugin, user_plugin) = plugin_for_user(state, user_id, plugin_id)?;
    let info = load_plugin_info(state, user_id, &plugin, &user_plugin).await?;
    let name = info.get("name").and_then(Value::as_str).map(str::to_owned);
    Ok(PluginDetailResponse {
        plugin_id: plugin.plugin_id,
        name,
        info,
        version: plugin.version,
        bundle_hash: plugin.bundle_hash,
        enabled: user_plugin.enabled && plugin.enabled,
        debug: user_plugin.debug,
        debug_url: user_plugin.debug_url,
        updated_at: user_plugin.updated_at,
    })
}

fn plugin_for_user(
    state: &AppState,
    user_id: &str,
    plugin_id: &str,
) -> Result<(crate::db::PluginRecord, crate::db::UserPluginRecord), ApiError> {
    let plugin = state
        .database
        .find_plugin(plugin_id)?
        .ok_or(ApiError::NotFound)?;
    let user_plugin = state
        .database
        .find_user_plugin(user_id, plugin_id)?
        .ok_or(ApiError::NotFound)?;
    Ok((plugin, user_plugin))
}

async fn load_plugin_info(
    state: &AppState,
    user_id: &str,
    plugin: &crate::db::PluginRecord,
    user_plugin: &crate::db::UserPluginRecord,
) -> Result<Value, ApiError> {
    let bundle_source = load_bundle_for_user(state, plugin, user_plugin).await?;
    state
        .plugin_runtime
        .invoke_json(
            user_id,
            &plugin.plugin_id,
            &bundle_source,
            "getInfo",
            &Value::Array(Vec::new()),
        )
        .await
        .map_err(map_plugin_runtime_error)
}

fn map_plugin_runtime_error(error: String) -> ApiError {
    if let Some(details) = extract_plugin_error_payload(&error)
        && details.get("type").and_then(Value::as_str) == Some("unauthorized")
    {
        return ApiError::PluginUnauthorized(details);
    }
    ApiError::Internal(anyhow::anyhow!(error))
}

fn extract_plugin_error_payload(error: &str) -> Option<Value> {
    let start = error.find('{')?;
    let end = error.rfind('}')?;
    if end < start {
        return None;
    }
    serde_json::from_str(&error[start..=end]).ok()
}

fn filter_browser_login_settings(mut value: Value) -> Value {
    let Some(scheme) = value.get_mut("scheme").and_then(Value::as_object_mut) else {
        return value;
    };

    if let Some(sections) = scheme.get_mut("sections").and_then(Value::as_array_mut) {
        sections.retain_mut(|section| {
            let Some(fields) = section.get_mut("fields").and_then(Value::as_array_mut) else {
                return true;
            };
            fields.retain(|field| !contains_browser_login_descriptor(field));
            !fields.is_empty()
        });
    }
    if let Some(actions) = scheme.get_mut("actions").and_then(Value::as_array_mut) {
        actions.retain(|action| !contains_browser_login_descriptor(action));
    }
    value
}

fn contains_browser_login_descriptor(value: &Value) -> bool {
    let Some(object) = value.as_object() else {
        return false;
    };

    for key in [
        "openUrl",
        "redirectWatchUrl",
        "setCookieFnPath",
        "cookiePollIntervalMs",
        "ignoreCookieNames",
    ] {
        if object.contains_key(key) {
            return true;
        }
    }

    for key in ["type", "kind", "fnPath"] {
        let value = object
            .get(key)
            .and_then(Value::as_str)
            .unwrap_or_default()
            .to_ascii_lowercase();
        if value.contains("openweb")
            || value.contains("weblogin")
            || value.contains("browserlogin")
            || value.contains("externalbrowser")
            || value.contains("chromium")
        {
            return true;
        }
    }

    object
        .get("action")
        .is_some_and(contains_browser_login_descriptor)
        || object
            .get("payload")
            .is_some_and(contains_browser_login_descriptor)
}

async fn load_bundle_for_user(
    state: &AppState,
    plugin: &crate::db::PluginRecord,
    user_plugin: &crate::db::UserPluginRecord,
) -> Result<String, ApiError> {
    if user_plugin.debug {
        if let Some(debug_url) = user_plugin
            .debug_url
            .as_deref()
            .map(str::trim)
            .filter(|url| !url.is_empty())
        {
            match load_debug_bundle(state, debug_url).await {
                Ok(bundle) => return Ok(bundle),
                Err(error) => {
                    tracing::warn!(
                        plugin_id = %plugin.plugin_id,
                        debug_url,
                        error = %error,
                        "调试插件 bundle 加载失败，回退已安装 bundle"
                    );
                }
            }
        }
    }

    let bundle_path = resolve_bundle_path(&state.config.plugin_root, &plugin.bundle_path)?;
    crate::plugin_store::read_plugin_bundle_file_verified(&bundle_path, &plugin.bundle_hash)
        .await
        .map_err(|error| anyhow::anyhow!("failed to read plugin bundle: {error}").into())
}

async fn load_debug_bundle(state: &AppState, debug_url: &str) -> anyhow::Result<String> {
    let response = state
        .http_client
        .get(debug_url)
        .send()
        .await
        .map_err(|error| anyhow::anyhow!("调试插件下载失败: {error}"))?
        .error_for_status()
        .map_err(|error| anyhow::anyhow!("调试插件下载失败: {error}"))?;
    let bytes = response
        .bytes()
        .await
        .map_err(|error| anyhow::anyhow!("调试插件读取失败: {error}"))?;
    let is_brotli = debug_url
        .split_once('?')
        .map(|(path, _)| path)
        .unwrap_or(debug_url)
        .to_ascii_lowercase()
        .ends_with(".br");
    crate::plugin_store::decode_plugin_bundle(&bytes, is_brotli)
        .map_err(|error| anyhow::anyhow!("调试插件 bundle 无效: {error}"))
}

fn validate_invoke_request(request: &InvokeRequest) -> Result<(), ApiError> {
    if request.function.trim().is_empty() || !request.args.is_array() {
        return Err(ApiError::BadRequest(
            "function 不能为空，args 必须是 JSON 数组".to_owned(),
        ));
    }
    if serde_json::to_vec(&request.args)?.len() > 1024 * 1024 {
        return Err(ApiError::BadRequest("插件参数不能超过 1 MiB".to_owned()));
    }
    if let Some(task_group_key) = request.task_group_key.as_deref() {
        validate_task_group_key(task_group_key)?;
    }
    Ok(())
}

fn validate_task_group_key(task_group_key: &str) -> Result<(), ApiError> {
    if task_group_key.trim().is_empty() || task_group_key.len() > 512 {
        return Err(ApiError::BadRequest("taskGroupKey 不合法".to_owned()));
    }
    Ok(())
}

fn resolve_bundle_path(root: &Path, stored_path: &str) -> Result<PathBuf, ApiError> {
    let root = std::fs::canonicalize(root).map_err(|_| ApiError::NotFound)?;
    let relative = Path::new(stored_path);
    if relative.is_absolute()
        || relative
            .components()
            .any(|component| matches!(component, std::path::Component::ParentDir))
    {
        return Err(ApiError::Forbidden);
    }
    let candidate = std::fs::canonicalize(root.join(relative)).map_err(|_| ApiError::NotFound)?;
    if !candidate.starts_with(&root) {
        return Err(ApiError::Forbidden);
    }
    Ok(candidate)
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::{contains_browser_login_descriptor, filter_browser_login_settings};

    #[test]
    fn filters_browser_login_fields_and_actions_from_settings() {
        let filtered = filter_browser_login_settings(json!({
            "scheme": {
                "sections": [
                    {
                        "title": "账号",
                        "fields": [
                            {"key": "username", "kind": "text"},
                            {"key": "browser", "kind": "action", "openUrl": "https://example.com"}
                        ]
                    },
                    {
                        "title": "浏览器登录",
                        "fields": [
                            {"key": "browser", "fnPath": "startWebLogin"}
                        ]
                    }
                ],
                "actions": [
                    {"title": "普通操作", "fnPath": "clearSession"},
                    {"title": "浏览器登录", "fnPath": "startEhentaiWebLogin"}
                ]
            }
        }));

        assert_eq!(
            filtered["scheme"]["sections"][0]["fields"]
                .as_array()
                .unwrap()
                .len(),
            1
        );
        assert_eq!(filtered["scheme"]["sections"].as_array().unwrap().len(), 1);
        assert_eq!(filtered["scheme"]["actions"].as_array().unwrap().len(), 1);
        assert_eq!(filtered["scheme"]["actions"][0]["fnPath"], "clearSession");
    }

    #[test]
    fn detects_nested_browser_login_descriptor() {
        assert!(contains_browser_login_descriptor(&json!({
            "action": {
                "type": "openWeb",
                "payload": {"url": "https://example.com"}
            }
        })));
        assert!(!contains_browser_login_descriptor(&json!({
            "title": "普通登录",
            "fnPath": "loginWithPassword"
        })));
    }
}
