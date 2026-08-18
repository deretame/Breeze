use std::collections::HashMap;
use std::sync::{
    Arc, Mutex,
    atomic::{AtomicBool, Ordering},
};
use std::time::{Duration, Instant};

use anyhow::{Result, anyhow};
use ferrous_opencc::{OpenCC, config::BuiltinConfig};
use serde_json::Value;
use sha2::{Digest, Sha256};
use tokio::sync::Notify;
use tracing::warn;

use crate::db::Database;

mod cache;

const RUNTIME_IDLE_TTL: Duration = Duration::from_secs(30 * 60);
const CANCELLATION_SIGNAL_TTL: Duration = Duration::from_secs(5);
const TASK_CANCELLED_ERROR: &str = "plugin task cancelled";

struct RuntimeEntry {
    runtime: Arc<rquickjs_playground::AsyncHostRuntime>,
    last_used: Instant,
    active_calls: usize,
}

#[derive(Clone, Default)]
struct TaskCancellationRegistry {
    signals: Arc<Mutex<HashMap<String, Arc<TaskCancellationSignal>>>>,
    active_tasks:
        Arc<Mutex<HashMap<String, HashMap<u64, Arc<rquickjs_playground::AsyncHostRuntime>>>>>,
}

struct TaskCancellationSignal {
    cancelled: AtomicBool,
    notify: Notify,
}

impl TaskCancellationRegistry {
    fn key(user_id: &str, task_group_key: &str) -> String {
        format!("{user_id}\u{1f}{task_group_key}")
    }

    fn register(
        &self,
        user_id: &str,
        task_group_key: &str,
        runtime: Arc<rquickjs_playground::AsyncHostRuntime>,
        task_id: u64,
    ) -> Arc<TaskCancellationSignal> {
        let key = Self::key(user_id, task_group_key);
        let signal = {
            let mut signals = self
                .signals
                .lock()
                .unwrap_or_else(|error| error.into_inner());
            Arc::clone(signals.entry(key.clone()).or_insert_with(|| {
                Arc::new(TaskCancellationSignal {
                    cancelled: AtomicBool::new(false),
                    notify: Notify::new(),
                })
            }))
        };
        self.active_tasks
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .entry(key)
            .or_default()
            .insert(task_id, runtime);
        signal
    }

    fn unregister(&self, user_id: &str, task_group_key: &str, task_id: u64) {
        let key = Self::key(user_id, task_group_key);
        let mut active_tasks = self
            .active_tasks
            .lock()
            .unwrap_or_else(|error| error.into_inner());
        if let Some(tasks) = active_tasks.get_mut(&key) {
            tasks.remove(&task_id);
            if tasks.is_empty() {
                active_tasks.remove(&key);
                self.signals
                    .lock()
                    .unwrap_or_else(|error| error.into_inner())
                    .remove(&key);
            }
        }
    }

    fn cancel(&self, user_id: &str, task_group_key: &str) {
        let key = Self::key(user_id, task_group_key);
        let signal = {
            let mut signals = self
                .signals
                .lock()
                .unwrap_or_else(|error| error.into_inner());
            Arc::clone(signals.entry(key.clone()).or_insert_with(|| {
                Arc::new(TaskCancellationSignal {
                    cancelled: AtomicBool::new(false),
                    notify: Notify::new(),
                })
            }))
        };
        signal.cancelled.store(true, Ordering::Release);
        signal.notify.notify_waiters();

        let tasks = self
            .active_tasks
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .get(&key)
            .map(|tasks| {
                tasks
                    .iter()
                    .map(|(task_id, runtime)| (*task_id, Arc::clone(runtime)))
                    .collect::<Vec<_>>()
            })
            .unwrap_or_default();
        for (task_id, runtime) in tasks {
            let _ = runtime.cancel(task_id);
        }

        let registry = self.clone();
        let user_id = user_id.to_owned();
        let task_group_key = task_group_key.to_owned();
        tokio::spawn(async move {
            tokio::time::sleep(CANCELLATION_SIGNAL_TTL).await;
            registry.clear_signal_if_idle(&user_id, &task_group_key);
        });
    }

    fn is_cancelled(&self, user_id: &str, task_group_key: &str) -> bool {
        let key = Self::key(user_id, task_group_key);
        self.signals
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .get(&key)
            .is_some_and(|signal| signal.cancelled.load(Ordering::Acquire))
    }

    fn clear(&self, user_id: &str, task_group_key: &str) {
        let key = Self::key(user_id, task_group_key);
        self.active_tasks
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .remove(&key);
        self.signals
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .remove(&key);
    }

    fn clear_signal_if_idle(&self, user_id: &str, task_group_key: &str) {
        let key = Self::key(user_id, task_group_key);
        let is_idle = !self
            .active_tasks
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .contains_key(&key);
        if is_idle {
            self.signals
                .lock()
                .unwrap_or_else(|error| error.into_inner())
                .remove(&key);
        }
    }
}

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
    runtimes: Arc<Mutex<HashMap<String, RuntimeEntry>>>,
    initialized_bundles: Mutex<HashMap<String, String>>,
    cancellations: TaskCancellationRegistry,
}

impl PluginRuntimeService {
    pub fn new(
        database: Database,
        websocket_hub: std::sync::Arc<crate::websocket::WebSocketHub>,
    ) -> anyhow::Result<Self> {
        let runtimes = Arc::new(Mutex::new(HashMap::new()));
        let cancellations = TaskCancellationRegistry::default();
        register_config_routes(database.clone())?;
        cache::register_cache_routes()?;
        register_opencc_route()?;
        websocket_hub.register_bridge_routes()?;
        register_runtime_control_routes(Arc::clone(&runtimes), cancellations.clone())?;
        Ok(Self {
            options: runtime_options(),
            runtimes,
            initialized_bundles: Mutex::new(HashMap::new()),
            cancellations,
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
        self.invoke_json_with_task_group(user_id, plugin_id, bundle_source, fn_path, args, None)
            .await
    }

    pub async fn invoke_json_with_task_group(
        &self,
        user_id: &str,
        plugin_id: &str,
        bundle_source: &str,
        fn_path: &str,
        args: &Value,
        task_group_key: Option<&str>,
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
        let result = self
            .call_json_task(user_id, &runtime, plugin_id, fn_path, args, task_group_key)
            .await;
        self.release_runtime(&runtime.0);
        result
    }

    pub async fn invoke_bytes(
        &self,
        user_id: &str,
        plugin_id: &str,
        bundle_source: &str,
        fn_path: &str,
        args: &Value,
    ) -> Result<Vec<u8>, String> {
        self.invoke_bytes_with_task_group(user_id, plugin_id, bundle_source, fn_path, args, None)
            .await
    }

    pub async fn invoke_bytes_with_task_group(
        &self,
        user_id: &str,
        plugin_id: &str,
        bundle_source: &str,
        fn_path: &str,
        args: &Value,
        task_group_key: Option<&str>,
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
        let result = self
            .call_bytes_task(user_id, &runtime, plugin_id, fn_path, args, task_group_key)
            .await;
        self.release_runtime(&runtime.0);
        result
    }

    pub fn cancel_task_group(&self, user_id: &str, task_group_key: &str) {
        self.cancellations.cancel(user_id, task_group_key);
    }

    pub fn clear_task_group(&self, user_id: &str, task_group_key: &str) {
        self.cancellations.clear(user_id, task_group_key);
    }

    pub fn drop_plugin_runtime(&self, user_id: &str, plugin_id: &str) -> bool {
        let key = format!("{user_id}:{plugin_id}");
        let removed = self
            .runtimes
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .remove(&key)
            .is_some();
        self.initialized_bundles
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .remove(&key);
        removed
    }

    pub fn reap_idle(&self) -> usize {
        let mut removed_keys = Vec::new();
        self.runtimes
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .retain(|key, entry| {
                let keep = entry.active_calls > 0 || entry.last_used.elapsed() < RUNTIME_IDLE_TTL;
                if !keep {
                    removed_keys.push(key.clone());
                }
                keep
            });
        if !removed_keys.is_empty() {
            let mut initialized = self
                .initialized_bundles
                .lock()
                .unwrap_or_else(|error| error.into_inner());
            for key in &removed_keys {
                initialized.remove(key);
            }
        }
        removed_keys.len()
    }

    async fn runtime_for_plugin(
        &self,
        user_id: &str,
        plugin_id: &str,
        bundle_source: &str,
    ) -> Result<(String, Arc<rquickjs_playground::AsyncHostRuntime>), String> {
        self.reap_idle();
        let key = format!("{user_id}:{plugin_id}");
        let existing = self
            .runtimes
            .lock()
            .map_err(|_| "plugin runtime lock poisoned".to_owned())?
            .get_mut(&key)
            .map(|entry| {
                entry.active_calls += 1;
                entry.last_used = Instant::now();
                Arc::clone(&entry.runtime)
            });
        if let Some(runtime) = existing {
            if let Err(error) = runtime
                .bundle_load(plugin_id, bundle_source)
                .await
                .map_err(|error| format!("failed to refresh plugin bundle: {error}"))
            {
                self.release_runtime(&key);
                return Err(error);
            }
            self.ensure_plugin_initialized(&key, &runtime, plugin_id, bundle_source)
                .await;
            return Ok((key, runtime));
        }
        let runtime = rquickjs_playground::AsyncHostRuntime::new_with_options(
            format!("cs-server-user-{user_id}--plugin-{plugin_id}"),
            self.options,
        )
        .map_err(|error| format!("failed to initialize plugin runtime: {error}"))?;
        let runtime = Arc::new(runtime);
        self.runtimes
            .lock()
            .map_err(|_| "plugin runtime lock poisoned".to_owned())?
            .insert(
                key.clone(),
                RuntimeEntry {
                    runtime: Arc::clone(&runtime),
                    last_used: Instant::now(),
                    active_calls: 1,
                },
            );
        if let Err(error) = runtime
            .bundle_load(plugin_id, bundle_source)
            .await
            .map_err(|error| format!("failed to load plugin bundle: {error}"))
        {
            self.drop_plugin_runtime(user_id, plugin_id);
            return Err(error);
        }
        self.ensure_plugin_initialized(&key, &runtime, plugin_id, bundle_source)
            .await;
        Ok((key, runtime))
    }

    fn release_runtime(&self, key: &str) {
        if let Ok(mut runtimes) = self.runtimes.lock() {
            if let Some(entry) = runtimes.get_mut(key) {
                entry.active_calls = entry.active_calls.saturating_sub(1);
                entry.last_used = Instant::now();
            }
        }
    }

    async fn call_json_task(
        &self,
        user_id: &str,
        runtime: &(String, Arc<rquickjs_playground::AsyncHostRuntime>),
        plugin_id: &str,
        fn_path: &str,
        args: &Value,
        task_group_key: Option<&str>,
    ) -> Result<Value, String> {
        let handle = runtime
            .1
            .bundle_call_start(plugin_id, fn_path, args)
            .await?;
        let raw = self
            .wait_for_task(user_id, runtime, handle, task_group_key)
            .await?;
        let payload: Value = serde_json::from_str(&raw).map_err(|error| error.to_string())?;
        if payload.get("ok").and_then(Value::as_bool) != Some(true) {
            return Err(payload
                .get("error")
                .and_then(Value::as_str)
                .unwrap_or("plugin call failed")
                .to_owned());
        }
        Ok(payload.get("data").cloned().unwrap_or(Value::Null))
    }

    async fn call_bytes_task(
        &self,
        user_id: &str,
        runtime: &(String, Arc<rquickjs_playground::AsyncHostRuntime>),
        plugin_id: &str,
        fn_path: &str,
        args: &Value,
        task_group_key: Option<&str>,
    ) -> Result<Vec<u8>, String> {
        let handle = runtime
            .1
            .bundle_call_start(plugin_id, fn_path, args)
            .await?;
        self.wait_for_bytes_task(user_id, runtime, handle, task_group_key)
            .await
    }

    async fn wait_for_task(
        &self,
        user_id: &str,
        runtime: &(String, Arc<rquickjs_playground::AsyncHostRuntime>),
        handle: rquickjs_playground::RuntimeTaskHandle,
        task_group_key: Option<&str>,
    ) -> Result<String, String> {
        let Some(task_group_key) = task_group_key.filter(|key| !key.trim().is_empty()) else {
            return handle.wait_async().await;
        };
        let task_id = handle.id();
        let signal =
            self.cancellations
                .register(user_id, task_group_key, Arc::clone(&runtime.1), task_id);
        let notified = signal.notify.notified();
        let result = if signal.cancelled.load(Ordering::Acquire) {
            let _ = runtime.1.cancel(task_id);
            Err(TASK_CANCELLED_ERROR.to_owned())
        } else {
            tokio::select! {
                result = handle.wait_async() => result,
                _ = notified => {
                    let _ = runtime.1.cancel(task_id);
                    Err(TASK_CANCELLED_ERROR.to_owned())
                }
            }
        };
        let result = if signal.cancelled.load(Ordering::Acquire) {
            Err(TASK_CANCELLED_ERROR.to_owned())
        } else {
            result
        };
        self.cancellations
            .unregister(user_id, task_group_key, task_id);
        result
    }

    async fn wait_for_bytes_task(
        &self,
        user_id: &str,
        runtime: &(String, Arc<rquickjs_playground::AsyncHostRuntime>),
        handle: rquickjs_playground::RuntimeTaskHandle,
        task_group_key: Option<&str>,
    ) -> Result<Vec<u8>, String> {
        let Some(task_group_key) = task_group_key.filter(|key| !key.trim().is_empty()) else {
            return handle.wait_bytes_async().await;
        };
        let task_id = handle.id();
        let signal =
            self.cancellations
                .register(user_id, task_group_key, Arc::clone(&runtime.1), task_id);
        let notified = signal.notify.notified();
        let result = if signal.cancelled.load(Ordering::Acquire) {
            let _ = runtime.1.cancel(task_id);
            Err(TASK_CANCELLED_ERROR.to_owned())
        } else {
            tokio::select! {
                result = handle.wait_bytes_async() => result,
                _ = notified => {
                    let _ = runtime.1.cancel(task_id);
                    Err(TASK_CANCELLED_ERROR.to_owned())
                }
            }
        };
        let result = if signal.cancelled.load(Ordering::Acquire) {
            Err(TASK_CANCELLED_ERROR.to_owned())
        } else {
            result
        };
        self.cancellations
            .unregister(user_id, task_group_key, task_id);
        result
    }

    async fn ensure_plugin_initialized(
        &self,
        runtime_key: &str,
        runtime: &rquickjs_playground::AsyncHostRuntime,
        plugin_id: &str,
        bundle_source: &str,
    ) {
        let mut hasher = Sha256::new();
        hasher.update(bundle_source.as_bytes());
        let bundle_hash = format!("{:x}", hasher.finalize());
        let should_initialize = self
            .initialized_bundles
            .lock()
            .map(|mut initialized| {
                if initialized.get(runtime_key) == Some(&bundle_hash) {
                    false
                } else {
                    initialized.insert(runtime_key.to_owned(), bundle_hash);
                    true
                }
            })
            .unwrap_or(true);
        if !should_initialize {
            return;
        }

        if let Err(error) = runtime
            .bundle_call(plugin_id, "init", &serde_json::json!([{}]))
            .await
        {
            if !error.contains("target is not function: init") {
                warn!(plugin_id, error = %error, "CS 插件 init 执行失败，继续提供插件调用");
            }
        }
    }
}

fn register_runtime_control_routes(
    runtimes: Arc<Mutex<HashMap<String, RuntimeEntry>>>,
    cancellations: TaskCancellationRegistry,
) -> anyhow::Result<()> {
    let runtime_map = Arc::clone(&runtimes);
    rquickjs_playground::register_bridge_route_async_handler(
        "runtime.gc",
        move |runtime_name, _| {
            let runtime_map = Arc::clone(&runtime_map);
            async move {
                let runtime = runtime_map
                    .lock()
                    .unwrap_or_else(|error| error.into_inner())
                    .get(&runtime_name)
                    .map(|entry| Arc::clone(&entry.runtime));
                if let Some(runtime) = runtime {
                    runtime.run_gc().await.map_err(|error| anyhow!(error))?;
                }
                Ok(serde_json::json!(true))
            }
        },
    )?;

    rquickjs_playground::register_bridge_route_sync_handler(
        "runtime.is_task_group_cancelled",
        move |runtime_name, args| {
            let Some(task_group_key) = args.first().and_then(Value::as_str) else {
                return Ok(serde_json::json!(false));
            };
            let Ok((user_id, _)) = runtime_scope(&runtime_name) else {
                return Ok(serde_json::json!(false));
            };
            Ok(serde_json::json!(
                cancellations.is_cancelled(&user_id, task_group_key,)
            ))
        },
    )?;
    Ok(())
}

pub async fn run_reaper(service: Arc<PluginRuntimeService>) {
    let mut interval = tokio::time::interval(Duration::from_secs(5 * 60));
    loop {
        interval.tick().await;
        let removed = service.reap_idle();
        if removed > 0 {
            tracing::debug!(removed, "reaped idle CS plugin runtimes");
        }
    }
}

fn register_opencc_route() -> Result<()> {
    rquickjs_playground::register_bridge_route_blocking_handler("opencc.convert", |_, args| {
        let object = args
            .first()
            .and_then(Value::as_object)
            .ok_or_else(|| anyhow!("opencc.convert 参数必须是对象"))?;
        let text = object
            .get("text")
            .and_then(Value::as_str)
            .ok_or_else(|| anyhow!("opencc.convert 缺少 text"))?;
        let config = object
            .get("config")
            .and_then(Value::as_str)
            .ok_or_else(|| anyhow!("opencc.convert 缺少 config"))?;
        if !config.ends_with(".json") {
            return Err(anyhow!("opencc.convert 配置文件名无效"));
        }
        let builtin = BuiltinConfig::from_filename(config)
            .map_err(|error| anyhow!("opencc.convert 配置不支持: {error}"))?;
        let converter = OpenCC::from_config(builtin)
            .map_err(|error| anyhow!("opencc.convert 初始化失败: {error}"))?;
        Ok(Value::String(converter.convert(text)))
    })?;
    Ok(())
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
                let config = database.plugin_config(&user_id, &plugin_id).await?;
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
                let current = database.plugin_config(&user_id, &plugin_id).await?;
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
                    )
                    .await?
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
    use std::sync::{Arc, Mutex, OnceLock};

    use crate::db::Database;
    use serde_json::json;

    use super::PluginRuntimeService;

    static RUNTIME_TEST_LOCK: OnceLock<Mutex<()>> = OnceLock::new();

    fn runtime_test_guard() -> std::sync::MutexGuard<'static, ()> {
        RUNTIME_TEST_LOCK
            .get_or_init(|| Mutex::new(()))
            .lock()
            .expect("runtime test lock should not be poisoned")
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn cancels_an_in_flight_bundle_call_and_releases_the_runtime_task() {
        let _guard = runtime_test_guard();
        let database = test_database();
        database
            .run_blocking(|database| {
                database.upsert_plugin(
                    "plugin-cancel",
                    "1.0.0",
                    "plugin-cancel.cjs",
                    "hash",
                    true,
                    "1",
                )
            })
            .await
            .expect("plugin should exist for config foreign key");
        database
            .run_blocking(|database| {
                database.create_user("user-cancel", "cancel-user", "hash", "1")
            })
            .await
            .expect("user should exist for config foreign key");
        let service = Arc::new(
            PluginRuntimeService::new(
                database,
                Arc::new(crate::websocket::WebSocketHub::default()),
            )
            .expect("service should initialize"),
        );
        let source = r#"
            module.exports = {
              wait: async () => new Promise(() => {})
            };
        "#;
        let call_service = Arc::clone(&service);
        let call = tokio::spawn(async move {
            call_service
                .invoke_json_with_task_group(
                    "user-cancel",
                    "plugin-cancel",
                    source,
                    "wait",
                    &json!([]),
                    Some("download-cancel"),
                )
                .await
        });

        tokio::time::sleep(std::time::Duration::from_millis(100)).await;
        service.cancel_task_group("user-cancel", "download-cancel");
        let error = tokio::time::timeout(std::time::Duration::from_secs(2), call)
            .await
            .expect("cancelled call should finish")
            .expect("call task should not panic")
            .expect_err("cancelled call should return an error");
        assert!(
            error.contains("cancel"),
            "unexpected cancellation error: {error}"
        );
        service.clear_task_group("user-cancel", "download-cancel");
        assert!(service.drop_plugin_runtime("user-cancel", "plugin-cancel"));
    }

    #[tokio::test(flavor = "multi_thread", worker_threads = 2)]
    async fn invokes_a_bundle_in_a_user_scoped_runtime() {
        let _guard = runtime_test_guard();
        let database = test_database();
        database
            .run_blocking(|database| {
                database.upsert_plugin("plugin-1", "1.0.0", "plugin-1.cjs", "hash", true, "1")
            })
            .await
            .expect("plugin should exist for config foreign key");
        database
            .run_blocking(|database| database.create_user("user-1", "alice", "hash", "1"))
            .await
            .expect("user should exist for config foreign key");
        let service = PluginRuntimeService::new(
            database.clone(),
            Arc::new(crate::websocket::WebSocketHub::default()),
        )
        .expect("service should initialize");
        let source = r#"
            module.exports = {
              init: async () => {
                await bridge.call("save_plugin_config", "auth.token", "server-login-state");
              },
              echo: async (value) => ({ value }),
              config: async () => bridge.call("load_plugin_config", "auth.token", "missing"),
              convert: async () => bridge.call("opencc.convert", {
                text: "繁體字",
                config: "t2s.json",
              }),
            };
        "#;
        let result = service
            .invoke_json("user-1", "plugin-1", source, "echo", &json!(["hello"]))
            .await
            .expect("plugin invocation should succeed");
        assert_eq!(result, json!({"value": "hello"}));
        service
            .invoke_json("user-1", "plugin-1", source, "init", &json!([{}]))
            .await
            .expect("plugin config init should succeed");
        assert_eq!(
            database
                .plugin_config("user-1", "plugin-1")
                .await
                .expect("plugin config should be stored in SQLite")
                .config_json,
            r#"{"auth.token":"server-login-state"}"#
        );
        let config = service
            .invoke_json("user-1", "plugin-1", source, "config", &json!([]))
            .await
            .expect("plugin config should be readable");
        assert_eq!(config, json!(r#"{"ok":true,"value":"server-login-state"}"#));
        let converted = service
            .invoke_json("user-1", "plugin-1", source, "convert", &json!([]))
            .await
            .expect("OpenCC bridge should be available");
        assert_eq!(converted, json!("繁体字"));
        assert_eq!(
            database
                .plugin_config("user-2", "plugin-1")
                .await
                .expect("other user config should remain isolated")
                .config_json,
            "{}"
        );
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
