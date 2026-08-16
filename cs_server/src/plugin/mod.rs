use std::collections::HashMap;
use std::sync::{Arc, Mutex};

use serde_json::Value;

use crate::db::Database;

mod cache;

#[derive(Clone, Debug)]
pub struct PluginRuntimeCapabilities {
    pub quickjs: bool,
    pub filesystem: bool,
    pub cancellation: bool,
}

impl Default for PluginRuntimeCapabilities {
    fn default() -> Self {
        let options = runtime_options();
        Self {
            quickjs: true,
            filesystem: options.fs,
            cancellation: true,
        }
    }
}

pub fn runtime_options() -> rquickjs_playground::WebRuntimeOptions {
    rquickjs_playground::WebRuntimeOptions { fs: false }
}

/// 按用户隔离 QuickJS runtime，插件默认只能使用 Web Runtime 能力，不能访问宿主文件系统。
pub struct PluginRuntimeService {
    options: rquickjs_playground::WebRuntimeOptions,
    runtimes: Mutex<HashMap<String, Arc<rquickjs_playground::AsyncHostRuntime>>>,
}

impl PluginRuntimeService {
    pub fn new(database: Database) -> anyhow::Result<Self> {
        register_config_routes(database)?;
        cache::register_cache_routes()?;
        Ok(Self {
            options: runtime_options(),
            runtimes: Mutex::new(HashMap::new()),
        })
    }

    pub async fn invoke_json(
        &self,
        user_id: &str,
        plugin_id: &str,
        bundle_source: &str,
        fn_path: &str,
        args: &Value,
    ) -> Result<Value, String> {
        if bundle_source.len() > 8 * 1024 * 1024 {
            return Err("plugin bundle exceeds 8 MiB limit".to_owned());
        }
        if fn_path.trim().is_empty() || !args.is_array() {
            return Err("plugin function path and array arguments are required".to_owned());
        }
        let runtime = self
            .runtime_for_plugin(user_id, plugin_id, bundle_source)
            .await?;
        runtime.bundle_call(plugin_id, fn_path, args).await
    }

    pub async fn invoke_bytes(
        &self,
        user_id: &str,
        plugin_id: &str,
        bundle_source: &str,
        fn_path: &str,
        args: &Value,
    ) -> Result<Vec<u8>, String> {
        if bundle_source.len() > 8 * 1024 * 1024 {
            return Err("plugin bundle exceeds 8 MiB limit".to_owned());
        }
        if fn_path.trim().is_empty() || !args.is_array() {
            return Err("plugin function path and array arguments are required".to_owned());
        }
        let runtime = self
            .runtime_for_plugin(user_id, plugin_id, bundle_source)
            .await?;
        runtime.bundle_call_bytes(plugin_id, fn_path, args).await
    }

    async fn runtime_for_plugin(
        &self,
        user_id: &str,
        plugin_id: &str,
        bundle_source: &str,
    ) -> Result<Arc<rquickjs_playground::AsyncHostRuntime>, String> {
        let key = format!("{user_id}:{plugin_id}");
        let existing = self
            .runtimes
            .lock()
            .map_err(|_| "plugin runtime lock poisoned".to_owned())?
            .get(&key)
            .cloned();
        if let Some(runtime) = existing {
            runtime
                .bundle_load(plugin_id, bundle_source)
                .await
                .map_err(|error| format!("failed to refresh plugin bundle: {error}"))?;
            return Ok(runtime);
        }
        let runtime = rquickjs_playground::AsyncHostRuntime::new_with_options(
            format!("cs-server-user-{user_id}--plugin-{plugin_id}"),
            self.options,
        )
        .map_err(|error| format!("failed to initialize plugin runtime: {error}"))?;
        let runtime = Arc::new(runtime);
        runtime
            .bundle_load(plugin_id, bundle_source)
            .await
            .map_err(|error| format!("failed to load plugin bundle: {error}"))?;
        self.runtimes
            .lock()
            .map_err(|_| "plugin runtime lock poisoned".to_owned())?
            .insert(key, Arc::clone(&runtime));
        Ok(runtime)
    }
}

fn register_config_routes(database: Database) -> anyhow::Result<()> {
    let load_database = database.clone();
    rquickjs_playground::register_bridge_route_async_handler(
        "load_plugin_config",
        move |runtime, args| {
            let database = load_database.clone();
            async move {
                let (user_id, plugin_id) = runtime_scope(&runtime)?;
                let key = args.first().and_then(Value::as_str).unwrap_or_default();
                let fallback = args.get(1).cloned().unwrap_or(Value::Null);
                let config = database.plugin_config(&user_id, &plugin_id)?;
                let object = serde_json::from_str::<Value>(&config.config_json)
                    .unwrap_or_else(|_| Value::Object(Default::default()));
                let value = if key.is_empty() {
                    object
                } else {
                    object.get(key).cloned().unwrap_or(fallback)
                };
                Ok(Value::String(
                    serde_json::json!({"ok": true, "value": value}).to_string(),
                ))
            }
        },
    )?;

    rquickjs_playground::register_bridge_route_async_handler(
        "save_plugin_config",
        move |runtime, args| {
            let database = database.clone();
            async move {
                let (user_id, plugin_id) = runtime_scope(&runtime)?;
                let key = args.first().and_then(Value::as_str).unwrap_or_default();
                let value = args.get(1).cloned().unwrap_or(Value::Null);
                let current = database.plugin_config(&user_id, &plugin_id)?;
                let mut object = serde_json::from_str::<Value>(&current.config_json)
                    .unwrap_or_else(|_| Value::Object(Default::default()));
                if key.is_empty() {
                    let replacement = if value.is_string() {
                        value
                            .as_str()
                            .and_then(|text| serde_json::from_str(text).ok())
                            .unwrap_or(value)
                    } else {
                        value
                    };
                    object = replacement;
                } else {
                    let Some(map) = object.as_object_mut() else {
                        return Err(anyhow::anyhow!("plugin config must be a JSON object"));
                    };
                    map.insert(key.to_owned(), value);
                }
                database
                    .update_plugin_config(
                        &user_id,
                        &plugin_id,
                        &serde_json::to_string(&object)?,
                        Some(current.revision),
                        &crate::api::auth::now_millis(),
                    )?
                    .ok_or_else(|| anyhow::anyhow!("plugin config revision changed"))?;
                Ok(Value::String("{\"ok\":true}".to_owned()))
            }
        },
    )?;
    Ok(())
}

fn runtime_scope(runtime: &str) -> anyhow::Result<(String, String)> {
    let value = runtime
        .strip_prefix("cs-server-user-")
        .ok_or_else(|| anyhow::anyhow!("invalid server runtime scope"))?;
    let (user_id, plugin_id) = value
        .split_once("--plugin-")
        .ok_or_else(|| anyhow::anyhow!("invalid server plugin runtime scope"))?;
    if user_id.is_empty() || plugin_id.is_empty() {
        return Err(anyhow::anyhow!("empty server runtime scope"));
    }
    Ok((user_id.to_owned(), plugin_id.to_owned()))
}

#[cfg(test)]
mod tests {
    use crate::db::Database;
    use serde_json::json;

    use super::PluginRuntimeService;

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn invokes_a_bundle_in_a_user_scoped_runtime() {
        let service =
            PluginRuntimeService::new(test_database()).expect("service should initialize");
        let source = r#"
            module.exports = {
              echo: async (value) => ({ value }),
            };
        "#;
        let result = service
            .invoke_json("user-1", "plugin-1", source, "echo", &json!(["hello"]))
            .await
            .expect("plugin invocation should succeed");
        assert_eq!(result, json!({"value": "hello"}));
    }

    fn test_database() -> Database {
        let suffix = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .expect("clock should be valid")
            .as_nanos();
        Database::open(&std::env::temp_dir().join(format!("breeze-plugin-test-{suffix}")))
            .expect("database should open")
    }
}
