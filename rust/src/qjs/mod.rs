use anyhow::{Context, Result, anyhow};
use dashmap::DashMap;
use ferrous_opencc::{OpenCC, config::BuiltinConfig};
use flutter_rust_bridge::DartFnFuture;
use rquickjs_playground::web_runtime::native_buffer_take_raw;
use rquickjs_playground::{
    AsyncHostRuntime, AsyncHostRuntimeBuilder, HttpClientConfig, WebRuntimeOptions,
    configure_http_client, configure_js_error_stack, configure_log_http_endpoint,
    register_bridge_route_async_handler, register_bridge_route_blocking_handler,
    register_bridge_route_sync_handler,
};
use serde_json::{Value, json};
use std::collections::{HashMap, HashSet};
use std::sync::{Arc, Mutex, OnceLock, RwLock as StdRwLock};
use tokio::sync::{Mutex as AsyncMutex, Notify, RwLock};

type QjsRuntimeMap = HashMap<String, Arc<AsyncHostRuntime>>;
type QjsInFlightTaskMap = HashMap<String, HashSet<u64>>;
type QjsTrackedTaskMap = HashMap<String, HashMap<u64, Arc<TrackedQjsTask>>>;
type PersistentCallback =
    Arc<dyn Fn(String, String, String) -> DartFnFuture<String> + Send + Sync + 'static>;

static QJS_RUNTIMES: OnceLock<RwLock<QjsRuntimeMap>> = OnceLock::new();
static QJS_IN_FLIGHT_TASKS: OnceLock<RwLock<QjsInFlightTaskMap>> = OnceLock::new();
static QJS_TRACKED_TASKS: OnceLock<RwLock<QjsTrackedTaskMap>> = OnceLock::new();
static QJS_RUNTIME_INIT_LOCK: OnceLock<AsyncMutex<()>> = OnceLock::new();

const BIKA_JS_BUNDLE: &str = include_str!("../../assets/bika-comic.bundle.cjs");
const JM_JS_BUNDLE: &str = include_str!("../../assets/jm-comic.bundle.cjs");
const BIKA_PLUGIN_UUID: &str = "0a0e5858-a467-4702-994a-79e608a4589d";
const JM_PLUGIN_UUID: &str = "bf99008d-010b-4f17-ac7c-61a9b57dc3d9";
const QJS_RUNTIME_CANCELLED_ERROR_CODE: &str = "__QJS_RUNTIME_CANCELLED__";
const BRIDGE_ROUTE_OPENCC_CONVERT: &str = "opencc.convert";
const BRIDGE_ROUTE_SAVE_PLUGIN_CONFIG: &str = "save_plugin_config";
const BRIDGE_ROUTE_LOAD_PLUGIN_CONFIG: &str = "load_plugin_config";
const BRIDGE_ROUTE_CACHE_GET: &str = "cache.get";
const BRIDGE_ROUTE_CACHE_SET: &str = "cache.set";
const BRIDGE_ROUTE_CACHE_SET_IF_ABSENT: &str = "cache.set_if_absent";
const BRIDGE_ROUTE_CACHE_COMPARE_AND_SET: &str = "cache.compare_and_set";
const BRIDGE_ROUTE_CACHE_DELETE: &str = "cache.delete";
const BRIDGE_ROUTE_RUNTIME_GC: &str = "runtime.gc";

static SAVE_PLUGIN_CONFIG_CALLBACK: OnceLock<StdRwLock<Option<PersistentCallback>>> =
    OnceLock::new();
static LOAD_PLUGIN_CONFIG_CALLBACK: OnceLock<StdRwLock<Option<PersistentCallback>>> =
    OnceLock::new();
static HOST_CACHE_STORE: OnceLock<DashMap<String, Value>> = OnceLock::new();

fn opencc_convert_by_config(text: &str, config_name: &str) -> Result<String> {
    if !config_name.ends_with(".json") {
        return Err(anyhow!(
            "opencc config 必须是 OpenCC 配置文件名，例如 t2s.json"
        ));
    }

    let builtin = BuiltinConfig::from_filename(config_name)
        .map_err(|err| anyhow!("不支持的 OpenCC 转换配置: {config_name} ({err})"))?;

    let converter =
        OpenCC::from_config(builtin).map_err(|err| anyhow!("初始化 OpenCC 失败: {err}"))?;

    Ok(converter.convert(text))
}

fn opencc_convert_with_json_arg(arg: &Value) -> Result<String> {
    let obj = arg
        .as_object()
        .ok_or_else(|| anyhow!("opencc 参数必须是 JSON 对象"))?;

    let text = obj
        .get("text")
        .and_then(Value::as_str)
        .ok_or_else(|| anyhow!("opencc 参数缺少 text 字段"))?;

    let config_name = obj
        .get("config")
        .and_then(Value::as_str)
        .ok_or_else(|| anyhow!("opencc 参数缺少 config 字段，例如 t2s.json"))?;

    opencc_convert_by_config(text, config_name)
}

#[derive(Clone)]
enum TrackedQjsTaskKind {
    Call,
    CallBytes,
}

#[derive(Clone)]
enum TrackedQjsTaskOutput {
    Json(String),
    Bytes(Vec<u8>),
}

struct TrackedQjsTaskState {
    outcome: Mutex<Option<std::result::Result<TrackedQjsTaskOutput, String>>>,
    notify: Notify,
}

struct TrackedQjsTask {
    kind: TrackedQjsTaskKind,
    group_key: String,
    cancel_runtime_name: String,
    state: Arc<TrackedQjsTaskState>,
}

#[derive(Debug, Clone)]
pub struct QjsCancelTaskResult {
    pub status: String,
}

#[derive(Debug, Clone)]
pub struct QjsCancelTasksByGroupResult {
    pub cancelled: i32,
    pub not_found: i32,
    pub failed_runtime_groups: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct QjsRuntimeBundleBuild {
    pub bundle_name: String,
    pub bundle_js: String,
}

#[derive(Debug, Clone)]
pub struct QjsRuntimeBuildRequest {
    pub runtime_name: String,
    pub inject_filesystem: bool,
    pub enable_wasi: bool,
    pub bundle: Option<QjsRuntimeBundleBuild>,
}

#[derive(Debug, Clone)]
pub struct QjsRuntimeBuilder {
    runtime_name: String,
    options: WebRuntimeOptions,
    bundle: Option<QjsRuntimeBundleBuild>,
}

impl QjsRuntimeBuilder {
    pub fn new(runtime_name: impl Into<String>) -> Self {
        Self {
            runtime_name: runtime_name.into(),
            options: WebRuntimeOptions::default(),
            bundle: None,
        }
    }

    pub fn filesystem(mut self, enabled: bool) -> Self {
        self.options.fs = enabled;
        self
    }

    pub fn wasi(mut self, enabled: bool) -> Self {
        self.options.wasi = enabled;
        self
    }

    pub fn bundle(mut self, bundle_name: impl Into<String>, bundle_js: impl Into<String>) -> Self {
        self.bundle = Some(QjsRuntimeBundleBuild {
            bundle_name: bundle_name.into(),
            bundle_js: bundle_js.into(),
        });
        self
    }

    pub fn with_bundle(mut self, bundle: QjsRuntimeBundleBuild) -> Self {
        self.bundle = Some(bundle);
        self
    }

    pub async fn build(self) -> Result<()> {
        let runtime_name = self.runtime_name.trim().to_string();
        if runtime_name.is_empty() {
            return Err(anyhow!("runtime_name 不能为空"));
        }

        if let Some(bundle) = self.bundle {
            let bundle_name = bundle.bundle_name.trim().to_string();
            if bundle_name.is_empty() {
                return Err(anyhow!("bundle_name 不能为空"));
            }
            if bundle.bundle_js.trim().is_empty() {
                return Err(anyhow!("bundle_js 不能为空"));
            }
            return create_qjs_runtime_with_bundle_and_options(
                &runtime_name,
                &bundle_name,
                &bundle.bundle_js,
                self.options,
            )
            .await;
        }

        let _runtime = qjs_runtime_with_options(&runtime_name, self.options).await?;
        Ok(())
    }
}

fn qjs_runtime_map() -> &'static RwLock<QjsRuntimeMap> {
    QJS_RUNTIMES.get_or_init(|| RwLock::new(HashMap::new()))
}

fn qjs_in_flight_task_map() -> &'static RwLock<QjsInFlightTaskMap> {
    QJS_IN_FLIGHT_TASKS.get_or_init(|| RwLock::new(HashMap::new()))
}

fn qjs_tracked_task_map() -> &'static RwLock<QjsTrackedTaskMap> {
    QJS_TRACKED_TASKS.get_or_init(|| RwLock::new(HashMap::new()))
}

fn qjs_runtime_init_lock() -> &'static AsyncMutex<()> {
    QJS_RUNTIME_INIT_LOCK.get_or_init(|| AsyncMutex::new(()))
}

fn save_plugin_config_callback_cell() -> &'static StdRwLock<Option<PersistentCallback>> {
    SAVE_PLUGIN_CONFIG_CALLBACK.get_or_init(|| StdRwLock::new(None))
}

fn load_plugin_config_callback_cell() -> &'static StdRwLock<Option<PersistentCallback>> {
    LOAD_PLUGIN_CONFIG_CALLBACK.get_or_init(|| StdRwLock::new(None))
}

fn host_cache_store_cell() -> &'static DashMap<String, Value> {
    HOST_CACHE_STORE.get_or_init(DashMap::new)
}

fn scoped_route_key(runtime: &str, key: &str) -> String {
    format!("{runtime}::{key}")
}

impl TrackedQjsTaskState {
    fn new() -> Self {
        Self {
            outcome: Mutex::new(None),
            notify: Notify::new(),
        }
    }

    fn complete(&self, outcome: std::result::Result<TrackedQjsTaskOutput, String>) {
        let Ok(mut guard) = self.outcome.lock() else {
            return;
        };

        if guard.is_none() {
            *guard = Some(outcome);
            drop(guard);
            self.notify.notify_waiters();
        }
    }

    fn is_ready(&self) -> bool {
        self.outcome
            .lock()
            .map(|guard| guard.is_some())
            .unwrap_or(true)
    }

    async fn wait(&self) -> Result<TrackedQjsTaskOutput> {
        loop {
            if let Ok(guard) = self.outcome.lock() {
                if let Some(outcome) = guard.clone() {
                    return outcome.map_err(|err| anyhow!(err));
                }
            }

            self.notify.notified().await;
        }
    }
}

fn complete_tracked_task_as_cancelled(task: &TrackedQjsTask) {
    task.state
        .complete(Err(QJS_RUNTIME_CANCELLED_ERROR_CODE.to_string()));
}

async fn insert_tracked_task(runtime_name: &str, task_id: u64, task: Arc<TrackedQjsTask>) {
    let mut map = qjs_tracked_task_map().write().await;
    map.entry(runtime_name.to_owned())
        .or_default()
        .insert(task_id, task);
}

async fn get_tracked_task(runtime_name: &str, task_id: u64) -> Option<Arc<TrackedQjsTask>> {
    let map = qjs_tracked_task_map().read().await;
    map.get(runtime_name)
        .and_then(|tasks| tasks.get(&task_id))
        .cloned()
}

async fn remove_tracked_task(runtime_name: &str, task_id: u64) -> Option<Arc<TrackedQjsTask>> {
    let mut map = qjs_tracked_task_map().write().await;
    let tasks = map.get_mut(runtime_name)?;
    let removed = tasks.remove(&task_id);
    if tasks.is_empty() {
        map.remove(runtime_name);
    }
    removed
}

async fn tracked_task_ids_by_group(runtime_name: &str, group_key: &str) -> Vec<u64> {
    let map = qjs_tracked_task_map().read().await;
    let Some(tasks) = map.get(runtime_name) else {
        return Vec::new();
    };

    tasks
        .iter()
        .filter_map(|(task_id, task)| {
            if task.group_key == group_key {
                Some(*task_id)
            } else {
                None
            }
        })
        .collect()
}

fn spawn_tracked_task_waiter(
    handle: rquickjs_playground::RuntimeTaskHandle,
    state: Arc<TrackedQjsTaskState>,
    kind: TrackedQjsTaskKind,
) {
    tokio::spawn(async move {
        let outcome = match handle.wait_async().await {
            Ok(raw) => match kind {
                TrackedQjsTaskKind::Call => parse_ok_json_payload(&raw)
                    .and_then(|payload| {
                        serde_json::to_string(&payload).context("序列化调用结果失败")
                    })
                    .map(TrackedQjsTaskOutput::Json),
                TrackedQjsTaskKind::CallBytes => parse_ok_json_payload(&raw)
                    .and_then(native_bytes_from_payload)
                    .map(TrackedQjsTaskOutput::Bytes),
            },
            Err(err) => Err(anyhow!(err)),
        };

        state.complete(outcome.map_err(|err| err.to_string()));
    });
}

fn spawn_tracked_bundle_once_task_waiter(
    handle: rquickjs_playground::RuntimeTaskHandle,
    state: Arc<TrackedQjsTaskState>,
    kind: TrackedQjsTaskKind,
) {
    tokio::spawn(async move {
        let outcome = match handle.wait_async().await {
            Ok(raw) => match kind {
                TrackedQjsTaskKind::Call => parse_ok_json_payload(&raw)
                    .and_then(|payload| {
                        serde_json::to_string(&payload).context("序列化一次性调用结果失败")
                    })
                    .map(TrackedQjsTaskOutput::Json),
                TrackedQjsTaskKind::CallBytes => parse_ok_json_payload(&raw)
                    .and_then(native_bytes_from_payload)
                    .map(TrackedQjsTaskOutput::Bytes),
            },
            Err(err) => Err(anyhow!(err)),
        };

        state.complete(outcome.map_err(|err| err.to_string()));
    });
}

async fn create_qjs_runtime_with_options(
    runtime_name: &str,
    options: WebRuntimeOptions,
) -> Result<AsyncHostRuntime> {
    let runtime = AsyncHostRuntimeBuilder::new(runtime_name)
        .filesystem(options.fs)
        .wasi(options.wasi)
        .build()
        .map_err(|err| anyhow!(err))?;
    let init_script = r#"(async () => {
            return "ok";
    })()"#;
    let task = runtime
        .spawn(init_script)
        .map_err(|err| anyhow!("提交 QJS 初始化任务失败: {err}"))?;
    task.wait_async()
        .await
        .map_err(|err| anyhow!("等待 QJS 初始化任务失败: {err}"))?;
    Ok(runtime)
}

fn ensure_runtime_options(
    runtime_name: &str,
    runtime: &AsyncHostRuntime,
    expected: WebRuntimeOptions,
) -> Result<()> {
    let actual = runtime.options();
    if actual == expected {
        return Ok(());
    }
    Err(anyhow!(
        "runtime '{runtime_name}' 已存在且配置不匹配 (existing: wasi={}, fs={}; requested: wasi={}, fs={})",
        actual.wasi,
        actual.fs,
        expected.wasi,
        expected.fs
    ))
}

async fn qjs_runtime_with_options(
    runtime_name: &str,
    options: WebRuntimeOptions,
) -> Result<Arc<AsyncHostRuntime>> {
    if runtime_name.trim().is_empty() {
        return Err(anyhow!("runtime_name 不能为空"));
    }

    {
        let map = qjs_runtime_map().read().await;
        if let Some(runtime) = map.get(runtime_name) {
            ensure_runtime_options(runtime_name, runtime, options)?;
            return Ok(runtime.clone());
        }
    }

    let _init_guard = qjs_runtime_init_lock().lock().await;

    {
        let map = qjs_runtime_map().read().await;
        if let Some(runtime) = map.get(runtime_name) {
            ensure_runtime_options(runtime_name, runtime, options)?;
            return Ok(runtime.clone());
        }
    }

    let new_runtime = Arc::new(create_qjs_runtime_with_options(runtime_name, options).await?);

    let mut map = qjs_runtime_map().write().await;
    map.insert(runtime_name.to_owned(), new_runtime.clone());

    tracing::info!(
        "新建了一个 qjs 实例: {runtime_name} (wasi={}, fs={})，thread id : {:?}",
        options.wasi,
        options.fs,
        std::thread::current().id()
    );
    Ok(new_runtime)
}

async fn qjs_runtime(runtime_name: &str) -> Result<Arc<AsyncHostRuntime>> {
    if runtime_name.trim().is_empty() {
        return Err(anyhow!("runtime_name 不能为空"));
    }

    {
        let map = qjs_runtime_map().read().await;
        if let Some(runtime) = map.get(runtime_name) {
            return Ok(runtime.clone());
        }
    }

    qjs_runtime_with_options(runtime_name, WebRuntimeOptions::default()).await
}

async fn create_qjs_runtime_with_bundle_and_options(
    runtime_name: &str,
    bundle_name: &str,
    bundle_js: &str,
    options: WebRuntimeOptions,
) -> Result<()> {
    if runtime_name.trim().is_empty() {
        return Err(anyhow!("runtime_name 不能为空"));
    }
    if bundle_name.trim().is_empty() {
        return Err(anyhow!("bundle_name 不能为空"));
    }
    if bundle_js.trim().is_empty() {
        return Err(anyhow!("bundle_js 不能为空"));
    }

    let _init_guard = qjs_runtime_init_lock().lock().await;

    {
        let map = qjs_runtime_map().read().await;
        if let Some(existing_runtime) = map.get(runtime_name) {
            ensure_runtime_options(runtime_name, existing_runtime, options)?;
            replace_bundle_inner(existing_runtime, bundle_name, bundle_js).await?;
            tracing::info!("复用 qjs 实例并替换 bundle: {runtime_name} -> {bundle_name}");
            return Ok(());
        }
    }

    let new_runtime = Arc::new(create_qjs_runtime_with_options(runtime_name, options).await?);
    load_bundle_inner(&new_runtime, bundle_name, bundle_js).await?;

    let mut map = qjs_runtime_map().write().await;
    map.insert(runtime_name.to_owned(), new_runtime);

    tracing::info!(
        "新建 qjs 实例并加载 bundle: {runtime_name} -> {bundle_name} (wasi={}, fs={})",
        options.wasi,
        options.fs
    );
    Ok(())
}

fn parse_args_array(args_json: &str) -> Result<Value> {
    let args: Value = serde_json::from_str(args_json).context("调用参数不是合法 JSON")?;
    Ok(match args {
        Value::Array(_) => args,
        Value::Null => Value::Array(Vec::new()),
        other => Value::Array(vec![other]),
    })
}

fn is_cancelled_error_text(message: &str) -> bool {
    let lower = message.to_ascii_lowercase();
    lower.contains("cancel")
        || lower.contains("abort")
        || lower.contains("interrupted")
        || message.contains("取消")
}

fn parse_ok_json_payload(raw: &str) -> Result<Value> {
    let payload: Value = serde_json::from_str(raw).context("解析 JS 返回 JSON 失败")?;
    if payload.get("ok").and_then(Value::as_bool) == Some(true) {
        Ok(payload.get("data").cloned().unwrap_or(Value::Null))
    } else {
        let error_message = payload
            .get("error")
            .and_then(Value::as_str)
            .unwrap_or("执行失败");
        if is_cancelled_error_text(error_message) {
            tracing::info!("QJS 任务被取消(解析返回体): {error_message}");
            return Err(anyhow!(QJS_RUNTIME_CANCELLED_ERROR_CODE));
        }
        Err(anyhow!("{}", error_message))
    }
}

async fn insert_runtime_task_id(runtime_name: &str, task_id: u64) {
    let mut map = qjs_in_flight_task_map().write().await;
    map.entry(runtime_name.to_owned())
        .or_default()
        .insert(task_id);
}

async fn remove_runtime_task_id(runtime_name: &str, task_id: u64) {
    let mut map = qjs_in_flight_task_map().write().await;
    let Some(task_ids) = map.get_mut(runtime_name) else {
        return;
    };
    task_ids.remove(&task_id);
    if task_ids.is_empty() {
        map.remove(runtime_name);
    }
}

async fn take_runtime_task_ids(runtime_name: &str) -> Vec<u64> {
    let mut map = qjs_in_flight_task_map().write().await;
    let Some(task_ids) = map.remove(runtime_name) else {
        return Vec::new();
    };
    task_ids.into_iter().collect()
}

fn cancel_runtime_tasks_many(runtime: &AsyncHostRuntime, task_ids: &[u64]) -> bool {
    runtime.cancel_many(task_ids.to_vec())
}

async fn load_bundle_inner(runtime: &AsyncHostRuntime, name: &str, bundle_js: &str) -> Result<()> {
    runtime
        .bundle_load(name, bundle_js)
        .await
        .map_err(|err| anyhow!("加载 QJS bundle 失败: {err}"))
}

async fn replace_bundle_inner(
    runtime: &AsyncHostRuntime,
    name: &str,
    bundle_js: &str,
) -> Result<()> {
    let names = runtime
        .bundle_list()
        .await
        .map_err(|err| anyhow!("读取 bundle 列表失败: {err}"))?;

    for existing in names {
        runtime
            .bundle_unload(&existing)
            .await
            .map_err(|err| anyhow!("卸载旧 bundle 失败({existing}): {err}"))?;
    }

    load_bundle_inner(runtime, name, bundle_js).await
}

async fn call_loaded_bundle_inner(
    runtime_name: &str,
    runtime: &AsyncHostRuntime,
    name: &str,
    fn_path: &str,
    args: &Value,
) -> Result<Value> {
    let handle = runtime
        .bundle_call_start(name, fn_path, args)
        .await
        .map_err(|err| anyhow!(err))?;

    let task_id = handle.id();
    insert_runtime_task_id(runtime_name, task_id).await;

    let raw = handle.wait_async().await;
    remove_runtime_task_id(runtime_name, task_id).await;

    let raw = match raw {
        Ok(raw) => raw,
        Err(err) => {
            let message = err.to_string();
            if is_cancelled_error_text(&message) {
                tracing::info!("QJS 任务被取消(等待结果): {message}");
                return Err(anyhow!(QJS_RUNTIME_CANCELLED_ERROR_CODE));
            }
            return Err(anyhow!(err));
        }
    };
    parse_ok_json_payload(&raw)
}

async fn call_loaded_bundle_start(
    runtime_name: &str,
    runtime: &AsyncHostRuntime,
    name: &str,
    fn_path: &str,
    args: &Value,
    task_group_key: &str,
    kind: TrackedQjsTaskKind,
) -> Result<u64> {
    let handle = runtime
        .bundle_call_start(name, fn_path, args)
        .await
        .map_err(|err| anyhow!(err))?;

    let task_id = handle.id();
    let state = Arc::new(TrackedQjsTaskState::new());
    let task = Arc::new(TrackedQjsTask {
        kind: kind.clone(),
        group_key: task_group_key.to_owned(),
        cancel_runtime_name: runtime_name.to_owned(),
        state: Arc::clone(&state),
    });
    insert_tracked_task(runtime_name, task_id, task).await;
    spawn_tracked_task_waiter(handle, state, kind);

    Ok(task_id)
}

async fn call_bundle_once_start_by_json(
    runtime_name: &str,
    bundle_js: &str,
    fn_path: &str,
    args_json: &str,
    task_group_key: &str,
    kind: TrackedQjsTaskKind,
) -> Result<u64> {
    if bundle_js.trim().is_empty() {
        return Err(anyhow!("bundle_js 不能为空"));
    }

    let runtime = qjs_runtime(runtime_name).await?;
    let args = parse_call_input(fn_path, args_json)?;
    let handle = runtime
        .bundle_call_once_start(bundle_js, fn_path, &args)
        .await
        .map_err(|err| anyhow!(err))?;
    let task_id = handle.id();
    let state = Arc::new(TrackedQjsTaskState::new());
    let task = Arc::new(TrackedQjsTask {
        kind: kind.clone(),
        group_key: task_group_key.to_owned(),
        cancel_runtime_name: runtime_name.to_owned(),
        state: Arc::clone(&state),
    });

    insert_tracked_task(runtime_name, task_id, task).await;
    spawn_tracked_bundle_once_task_waiter(handle, state, kind);

    Ok(task_id)
}

async fn call_current_bundle_inner(
    runtime_name: &str,
    runtime: &AsyncHostRuntime,
    fn_path: &str,
    args: &Value,
) -> Result<Value> {
    let Some(name) = current_bundle_name(runtime).await? else {
        return Err(anyhow!(
            "当前 runtime 未加载 bundle，请先调用 qjs_replace_bundle"
        ));
    };
    call_loaded_bundle_inner(runtime_name, runtime, &name, fn_path, args).await
}

async fn call_current_bundle_start(
    runtime_name: &str,
    runtime: &AsyncHostRuntime,
    fn_path: &str,
    args: &Value,
    task_group_key: &str,
    kind: TrackedQjsTaskKind,
) -> Result<u64> {
    let Some(name) = current_bundle_name(runtime).await? else {
        return Err(anyhow!(
            "当前 runtime 未加载 bundle，请先调用 qjs_replace_bundle"
        ));
    };

    call_loaded_bundle_start(
        runtime_name,
        runtime,
        &name,
        fn_path,
        args,
        task_group_key,
        kind,
    )
    .await
}

async fn call_bundle_once_inner(
    runtime: &AsyncHostRuntime,
    bundle_js: &str,
    fn_path: &str,
    args: &Value,
) -> Result<Value> {
    runtime
        .bundle_call_once(bundle_js, fn_path, args)
        .await
        .map_err(|err| anyhow!(err))
}

fn native_bytes_from_payload(payload: Value) -> Result<Vec<u8>> {
    let native_buffer_id = payload
        .get("nativeBufferId")
        .and_then(Value::as_u64)
        .ok_or_else(|| anyhow!("JS 返回缺少 nativeBufferId"))?;

    native_buffer_take_raw(native_buffer_id)
        .ok_or_else(|| anyhow!("native buffer 不存在或已被消费: {native_buffer_id}"))
}

fn parse_call_input(fn_path: &str, args_json: &str) -> Result<Value> {
    if fn_path.trim().is_empty() {
        return Err(anyhow!("fn_path 不能为空"));
    }
    parse_args_array(args_json)
}

async fn call_current_bundle_by_json(
    runtime_name: &str,
    fn_path: &str,
    args_json: &str,
) -> Result<Value> {
    let runtime = qjs_runtime(runtime_name).await?;
    let args = parse_call_input(fn_path, args_json)?;
    call_current_bundle_inner(runtime_name, &runtime, fn_path, &args).await
}

async fn call_current_bundle_start_by_json(
    runtime_name: &str,
    fn_path: &str,
    args_json: &str,
    task_group_key: &str,
    kind: TrackedQjsTaskKind,
) -> Result<u64> {
    let runtime = qjs_runtime(runtime_name).await?;
    let args = parse_call_input(fn_path, args_json)?;
    call_current_bundle_start(runtime_name, &runtime, fn_path, &args, task_group_key, kind).await
}

async fn call_bundle_once_by_json(
    runtime_name: &str,
    bundle_js: &str,
    fn_path: &str,
    args_json: &str,
) -> Result<Value> {
    if bundle_js.trim().is_empty() {
        return Err(anyhow!("bundle_js 不能为空"));
    }

    let runtime = qjs_runtime(runtime_name).await?;
    let args = parse_call_input(fn_path, args_json)?;
    call_bundle_once_inner(&runtime, bundle_js, fn_path, &args).await
}

async fn call_current_bundle_bytes_by_json(
    runtime_name: &str,
    fn_path: &str,
    args_json: &str,
) -> Result<Vec<u8>> {
    let payload = call_current_bundle_by_json(runtime_name, fn_path, args_json).await?;
    native_bytes_from_payload(payload)
}

async fn call_bundle_once_bytes_by_json(
    runtime_name: &str,
    bundle_js: &str,
    fn_path: &str,
    args_json: &str,
) -> Result<Vec<u8>> {
    let payload = call_bundle_once_by_json(runtime_name, bundle_js, fn_path, args_json).await?;
    native_bytes_from_payload(payload)
}

async fn current_bundle_name(runtime: &AsyncHostRuntime) -> Result<Option<String>> {
    let mut names = runtime
        .bundle_list()
        .await
        .map_err(|err| anyhow!("读取 bundle 列表失败: {err}"))?;
    if names.is_empty() {
        return Ok(None);
    }
    Ok(Some(names.swap_remove(0)))
}

async fn wait_tracked_task_output(
    runtime_name: &str,
    task_id: u64,
    expected_kind: TrackedQjsTaskKind,
) -> Result<TrackedQjsTaskOutput> {
    let task: Arc<TrackedQjsTask> = get_tracked_task(runtime_name, task_id)
        .await
        .ok_or_else(|| anyhow!("任务不存在: {task_id}"))?;

    let kind_matches = matches!(
        (&task.kind, &expected_kind),
        (TrackedQjsTaskKind::Call, TrackedQjsTaskKind::Call)
            | (TrackedQjsTaskKind::CallBytes, TrackedQjsTaskKind::CallBytes,)
    );

    if !kind_matches {
        return Err(anyhow!("任务类型不匹配: {task_id}"));
    }

    let outcome = task.state.wait().await;
    let _ = remove_tracked_task(runtime_name, task_id).await;
    outcome
}

pub async fn qjs_replace_bundle(
    runtime_name: String,
    bundle_name: String,
    bundle_js: String,
) -> Result<()> {
    let runtime = qjs_runtime(&runtime_name).await?;
    replace_bundle_inner(&runtime, &bundle_name, &bundle_js).await
}

pub async fn qjs_call(runtime_name: String, fn_path: String, args_json: String) -> Result<String> {
    let data = call_current_bundle_by_json(&runtime_name, &fn_path, &args_json).await?;
    serde_json::to_string(&data).context("序列化调用结果失败")
}

pub async fn qjs_call_task_start(
    runtime_name: String,
    task_group_key: String,
    fn_path: String,
    args_json: String,
) -> Result<u64> {
    call_current_bundle_start_by_json(
        &runtime_name,
        &fn_path,
        &args_json,
        &task_group_key,
        TrackedQjsTaskKind::Call,
    )
    .await
}

pub async fn qjs_call_task_wait(runtime_name: String, task_id: u64) -> Result<String> {
    match wait_tracked_task_output(&runtime_name, task_id, TrackedQjsTaskKind::Call).await? {
        TrackedQjsTaskOutput::Json(raw) => Ok(raw),
        TrackedQjsTaskOutput::Bytes(_) => Err(anyhow!("任务类型不匹配: {task_id}")),
    }
}

pub async fn qjs_call_once(
    runtime_name: String,
    bundle_js: String,
    fn_path: String,
    args_json: String,
) -> Result<String> {
    let data = call_bundle_once_by_json(&runtime_name, &bundle_js, &fn_path, &args_json).await?;
    serde_json::to_string(&data).context("序列化一次性调用结果失败")
}

pub async fn qjs_call_once_task_start(
    runtime_name: String,
    bundle_js: String,
    fn_path: String,
    args_json: String,
    task_group_key: String,
) -> Result<u64> {
    call_bundle_once_start_by_json(
        &runtime_name,
        &bundle_js,
        &fn_path,
        &args_json,
        &task_group_key,
        TrackedQjsTaskKind::Call,
    )
    .await
}

pub async fn qjs_call_once_task_wait(runtime_name: String, task_id: u64) -> Result<String> {
    match wait_tracked_task_output(&runtime_name, task_id, TrackedQjsTaskKind::Call).await? {
        TrackedQjsTaskOutput::Json(raw) => Ok(raw),
        TrackedQjsTaskOutput::Bytes(_) => Err(anyhow!("任务类型不匹配: {task_id}")),
    }
}

pub async fn qjs_clear_bundle(runtime_name: String) -> Result<bool> {
    let runtime = qjs_runtime(&runtime_name).await?;
    let Some(name) = current_bundle_name(&runtime).await? else {
        return Ok(false);
    };
    runtime
        .bundle_unload(&name)
        .await
        .map_err(|err| anyhow!("清空当前 bundle 失败: {err}"))
}

pub async fn qjs_current_bundle(runtime_name: String) -> Result<String> {
    let runtime = qjs_runtime(&runtime_name).await?;
    let current = current_bundle_name(&runtime).await?;
    serde_json::to_string(&current).context("序列化当前 bundle 信息失败")
}

pub async fn qjs_drop_runtime(runtime_name: String) -> Result<bool> {
    if runtime_name.trim().is_empty() {
        return Err(anyhow!("runtime_name 不能为空"));
    }

    let _init_guard = qjs_runtime_init_lock().lock().await;

    let mut map = qjs_runtime_map().write().await;
    let runtime = map.remove(&runtime_name);
    drop(map);

    let task_ids = take_runtime_task_ids(&runtime_name).await;
    if let Some(runtime) = runtime.as_deref() {
        if !task_ids.is_empty() {
            tracing::info!(
                "销毁 qjs 实例并取消任务: runtime={}, task_count={}",
                runtime_name,
                task_ids.len()
            );
        }
        let _ = cancel_runtime_tasks_many(runtime, &task_ids);
    }

    let _ = qjs_tracked_task_map().write().await.remove(&runtime_name);

    Ok(runtime.is_some())
}

pub async fn qjs_cancel_task(runtime_name: String, task_id: u64) -> Result<QjsCancelTaskResult> {
    let Some(task) = get_tracked_task(&runtime_name, task_id).await else {
        return Ok(QjsCancelTaskResult {
            status: "not_found".to_string(),
        });
    };

    if task.state.is_ready() {
        let _ = remove_tracked_task(&runtime_name, task_id).await;
        return Ok(QjsCancelTaskResult {
            status: "not_found".to_string(),
        });
    }

    let runtime = qjs_runtime(&task.cancel_runtime_name).await?;
    if !runtime.cancel(task_id) {
        return Err(anyhow!("取消任务失败: runtime 不可用"));
    }

    complete_tracked_task_as_cancelled(&task);
    let _ = remove_tracked_task(&runtime_name, task_id).await;
    Ok(QjsCancelTaskResult {
        status: "cancelled".to_string(),
    })
}

pub async fn qjs_cancel_tasks_by_group(
    runtime_name: String,
    task_group_key: String,
) -> Result<QjsCancelTasksByGroupResult> {
    let task_ids = tracked_task_ids_by_group(&runtime_name, &task_group_key).await;
    if task_ids.is_empty() {
        return Ok(QjsCancelTasksByGroupResult {
            cancelled: 0,
            not_found: 0,
            failed_runtime_groups: Vec::new(),
        });
    }

    let mut cancelled = 0usize;
    let mut not_found = 0usize;
    let mut failed_runtime_groups = Vec::new();
    let mut cancel_ids_by_runtime: HashMap<String, Vec<u64>> = HashMap::new();

    for task_id in task_ids {
        let Some(task) = get_tracked_task(&runtime_name, task_id).await else {
            not_found += 1;
            continue;
        };

        if task.state.is_ready() {
            let _ = remove_tracked_task(&runtime_name, task_id).await;
            not_found += 1;
            continue;
        }

        cancel_ids_by_runtime
            .entry(task.cancel_runtime_name.clone())
            .or_default()
            .push(task_id);
    }

    for (cancel_runtime_name, ids) in cancel_ids_by_runtime {
        let cancel_runtime = qjs_runtime(&cancel_runtime_name).await?;
        if cancel_runtime_tasks_many(&cancel_runtime, &ids) {
            for task_id in ids {
                if let Some(task) = get_tracked_task(&runtime_name, task_id).await {
                    complete_tracked_task_as_cancelled(&task);
                }
                let _ = remove_tracked_task(&runtime_name, task_id).await;
                cancelled += 1;
            }
        } else {
            failed_runtime_groups.push(format!(
                "{}:[{}]",
                cancel_runtime_name,
                ids.iter()
                    .map(|id| id.to_string())
                    .collect::<Vec<_>>()
                    .join(",")
            ));
        }
    }

    Ok(QjsCancelTasksByGroupResult {
        cancelled: cancelled as i32,
        not_found: not_found as i32,
        failed_runtime_groups,
    })
}

pub async fn qjs_fetch_image_bytes(
    runtime_name: String,
    fn_path: String,
    args_json: String,
) -> Result<Vec<u8>> {
    call_current_bundle_bytes_by_json(&runtime_name, &fn_path, &args_json).await
}

pub async fn qjs_fetch_image_bytes_task_start(
    runtime_name: String,
    task_group_key: String,
    fn_path: String,
    args_json: String,
) -> Result<u64> {
    call_current_bundle_start_by_json(
        &runtime_name,
        &fn_path,
        &args_json,
        &task_group_key,
        TrackedQjsTaskKind::CallBytes,
    )
    .await
}

pub async fn qjs_fetch_image_bytes_task_wait(
    runtime_name: String,
    task_id: u64,
) -> Result<Vec<u8>> {
    match wait_tracked_task_output(&runtime_name, task_id, TrackedQjsTaskKind::CallBytes).await? {
        TrackedQjsTaskOutput::Bytes(bytes) => Ok(bytes),
        TrackedQjsTaskOutput::Json(_) => Err(anyhow!("任务类型不匹配(期望二进制): {task_id}")),
    }
}

pub async fn qjs_fetch_image_bytes_once(
    runtime_name: String,
    bundle_js: String,
    fn_path: String,
    args_json: String,
) -> Result<Vec<u8>> {
    call_bundle_once_bytes_by_json(&runtime_name, &bundle_js, &fn_path, &args_json).await
}

pub async fn qjs_fetch_image_bytes_once_task_start(
    runtime_name: String,
    bundle_js: String,
    fn_path: String,
    args_json: String,
    task_group_key: String,
) -> Result<u64> {
    call_bundle_once_start_by_json(
        &runtime_name,
        &bundle_js,
        &fn_path,
        &args_json,
        &task_group_key,
        TrackedQjsTaskKind::CallBytes,
    )
    .await
}

pub async fn qjs_fetch_image_bytes_once_task_wait(
    runtime_name: String,
    task_id: u64,
) -> Result<Vec<u8>> {
    match wait_tracked_task_output(&runtime_name, task_id, TrackedQjsTaskKind::CallBytes).await? {
        TrackedQjsTaskOutput::Bytes(bytes) => Ok(bytes),
        TrackedQjsTaskOutput::Json(_) => Err(anyhow!("任务类型不匹配(期望二进制): {task_id}")),
    }
}

pub fn set_http_proxy(proxy: String) -> Result<()> {
    configure_http_client(HttpClientConfig {
        use_http_proxy: true,
        use_socks5_proxy: false,
        http_proxy: Some(proxy),
        socks5_proxy: None,
        disable_tls_verify: true,
    })
    .map_err(|err| anyhow!("设置 http 代理失败: {err}"))
}

pub fn set_socks5_proxy(proxy: String) -> Result<()> {
    configure_http_client(HttpClientConfig {
        use_http_proxy: false,
        use_socks5_proxy: true,
        http_proxy: None,
        socks5_proxy: Some(proxy),
        disable_tls_verify: false,
    })
    .map_err(|err| anyhow!("设置 socks5 代理失败: {err}"))
}

pub fn set_qjs_error_stack_enabled(enabled: bool) -> Result<()> {
    configure_js_error_stack(enabled);
    Ok(())
}

pub fn register_load_plugin_config(
    dart_callback: impl Fn(String, String, String) -> DartFnFuture<String> + Send + Sync + 'static,
) -> Result<()> {
    let callback: PersistentCallback = Arc::new(dart_callback);
    {
        let mut guard = load_plugin_config_callback_cell()
            .write()
            .map_err(|_| anyhow!("load_plugin_config 回调锁已损坏"))?;
        *guard = Some(callback);
    }

    register_bridge_route_async_handler(
        BRIDGE_ROUTE_LOAD_PLUGIN_CONFIG,
        |runtime, args| async move {
            let key = args
                .first()
                .and_then(Value::as_str)
                .ok_or_else(|| anyhow!("load_plugin_config 参数无效: 缺少 key"))?
                .to_string();
            let value = args
                .get(1)
                .and_then(Value::as_str)
                .ok_or_else(|| anyhow!("load_plugin_config 参数无效: 缺少 value"))?
                .to_string();
            let callback = load_plugin_config_callback_cell()
                .read()
                .map_err(|_| anyhow!("load_plugin_config 回调锁已损坏"))?
                .clone()
                .ok_or_else(|| anyhow!("load_plugin_config 回调未注册"))?;
            let out = callback(runtime, key, value).await;
            Ok(json!(out))
        },
    )?;
    Ok(())
}

pub fn register_save_plugin_config(
    dart_callback: impl Fn(String, String, String) -> DartFnFuture<String> + Send + Sync + 'static,
) -> Result<()> {
    let callback: PersistentCallback = Arc::new(dart_callback);
    {
        let mut guard = save_plugin_config_callback_cell()
            .write()
            .map_err(|_| anyhow!("save_plugin_config 回调锁已损坏"))?;
        *guard = Some(callback);
    }

    register_bridge_route_async_handler(
        BRIDGE_ROUTE_SAVE_PLUGIN_CONFIG,
        |runtime, args| async move {
            let key = args
                .first()
                .and_then(Value::as_str)
                .ok_or_else(|| anyhow!("save_plugin_config 参数无效: 缺少 key"))?
                .to_string();
            let value = args
                .get(1)
                .and_then(Value::as_str)
                .ok_or_else(|| anyhow!("save_plugin_config 参数无效: 缺少 value"))?
                .to_string();
            let callback = save_plugin_config_callback_cell()
                .read()
                .map_err(|_| anyhow!("save_plugin_config 回调锁已损坏"))?
                .clone()
                .ok_or_else(|| anyhow!("save_plugin_config 回调未注册"))?;
            let out = callback(runtime, key, value).await;
            Ok(json!(out))
        },
    )?;
    Ok(())
}

pub fn set_log_http_forward(url: String) -> Result<()> {
    configure_log_http_endpoint(Some(url));
    Ok(())
}

pub fn get_js_bundle(name: String) -> Result<String> {
    match name.as_str() {
        BIKA_PLUGIN_UUID => Ok(BIKA_JS_BUNDLE.to_string()),
        JM_PLUGIN_UUID => Ok(JM_JS_BUNDLE.to_string()),
        _ => Ok("".to_string()),
    }
}

pub async fn is_qjs_runtime_initialized(name: String) -> Result<bool> {
    let map = qjs_runtime_map().read().await;
    Ok(map.contains_key(&name))
}

pub async fn build_qjs_runtime(request: QjsRuntimeBuildRequest) -> Result<()> {
    let mut builder = QjsRuntimeBuilder::new(request.runtime_name)
        .filesystem(request.inject_filesystem)
        .wasi(request.enable_wasi);

    if let Some(bundle) = request.bundle {
        builder = builder.with_bundle(bundle);
    }

    builder.build().await
}

pub fn register_function(
    function_name: String,
    dart_callback: impl Fn(String) -> DartFnFuture<String> + Send + Sync + 'static,
) -> Result<()> {
    let dart_callback = Arc::new(dart_callback);

    register_bridge_route_async_handler(function_name, move |runtime, args| {
        let runtime_name = runtime.to_string();
        let dart_callback = Arc::clone(&dart_callback);

        async move {
            let input = args
                .get(0)
                .and_then(Value::as_str)
                .unwrap_or_default()
                .to_string();

            let out = dart_callback(input).await;

            Ok(json!({
                "runtime": runtime_name,
                "data": out
            }))
        }
    })?;

    Ok(())
}

pub fn init_rust_functions() -> Result<()> {
    register_bridge_route_blocking_handler(BRIDGE_ROUTE_OPENCC_CONVERT, |_, args| {
        let arg: &Value = args
            .first()
            .ok_or_else(|| anyhow!("opencc 需要一个 JSON 参数"))?;

        let out = opencc_convert_with_json_arg(arg)?;
        Ok(json!(out))
    })?;

    register_bridge_route_sync_handler(BRIDGE_ROUTE_CACHE_GET, |runtime, args| {
        let key = args
            .first()
            .and_then(Value::as_str)
            .ok_or_else(|| anyhow!("cache.get 参数无效: 缺少 key"))?;
        let fallback = args.get(1).cloned().unwrap_or(Value::Null);
        let scoped_key = scoped_route_key(&runtime, key);
        let out = host_cache_store_cell()
            .get(&scoped_key)
            .map(|v| v.clone())
            .unwrap_or(fallback);
        Ok(out)
    })?;

    register_bridge_route_sync_handler(BRIDGE_ROUTE_CACHE_SET, |runtime, args| {
        let key = args
            .first()
            .and_then(Value::as_str)
            .ok_or_else(|| anyhow!("cache.set 参数无效: 缺少 key"))?;
        let value = args.get(1).cloned().unwrap_or(Value::Null);
        let scoped_key = scoped_route_key(&runtime, key);
        host_cache_store_cell().insert(scoped_key, value);
        Ok(json!(true))
    })?;

    register_bridge_route_sync_handler(BRIDGE_ROUTE_CACHE_SET_IF_ABSENT, |runtime, args| {
        let key = args
            .first()
            .and_then(Value::as_str)
            .ok_or_else(|| anyhow!("cache.set_if_absent 参数无效: 缺少 key"))?;
        let value = args.get(1).cloned().unwrap_or(Value::Null);
        let scoped_key = scoped_route_key(&runtime, key);
        let cache = host_cache_store_cell();
        if let dashmap::mapref::entry::Entry::Vacant(entry) = cache.entry(scoped_key) {
            entry.insert(value);
            return Ok(json!(true));
        }
        Ok(json!(false))
    })?;

    register_bridge_route_sync_handler(BRIDGE_ROUTE_CACHE_COMPARE_AND_SET, |runtime, args| {
        let key = args
            .first()
            .and_then(Value::as_str)
            .ok_or_else(|| anyhow!("cache.compare_and_set 参数无效: 缺少 key"))?;
        let expected = args.get(1).cloned().unwrap_or(Value::Null);
        let next = args.get(2).cloned().unwrap_or(Value::Null);
        let scoped_key = scoped_route_key(&runtime, key);
        let cache = host_cache_store_cell();
        let updated = match cache.get_mut(&scoped_key) {
            Some(mut current) if *current == expected => {
                *current = next;
                true
            }
            _ => false,
        };
        Ok(json!(updated))
    })?;

    register_bridge_route_sync_handler(BRIDGE_ROUTE_CACHE_DELETE, |runtime, args| {
        let key = args
            .first()
            .and_then(Value::as_str)
            .ok_or_else(|| anyhow!("cache.delete 参数无效: 缺少 key"))?;
        let scoped_key = scoped_route_key(&runtime, key);
        let deleted = host_cache_store_cell().remove(&scoped_key).is_some();
        Ok(json!(deleted))
    })?;

    register_bridge_route_async_handler(BRIDGE_ROUTE_RUNTIME_GC, |runtime_name, _| async move {
        let runtime = qjs_runtime(&runtime_name).await?;
        runtime.run_gc().await.map_err(|e| anyhow!(e))?;
        Ok(json!(true))
    })?;

    Ok(())
}

pub fn opencc_convert(text: String, config: String) -> Result<String> {
    opencc_convert_by_config(&text, &config)
}
