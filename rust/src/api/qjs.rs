use anyhow::{Context, Result, anyhow};
use flutter_rust_bridge::{DartFnFuture, frb};
use rquickjs_playground::web_runtime::native_buffer_take_raw;
use rquickjs_playground::{
    AsyncHostRuntime, HttpClientConfig, configure_http_client, configure_js_error_stack,
    configure_log_http_endpoint, register_load_plugin_config_handler,
    register_save_plugin_config_handler,
};
use serde_json::Value;
use std::collections::{HashMap, HashSet};
use std::sync::{Arc, Mutex, OnceLock};
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
static DART_CALLBACK_RT: OnceLock<Mutex<tokio::runtime::Runtime>> = OnceLock::new();

const BIKA_JS_BUNDLE: &str = include_str!("../../assets/bikaComic.bundle.cjs");
const JM_JS_BUNDLE: &str = include_str!("../../assets/JmComic.bundle.cjs");
const QJS_RUNTIME_CANCELLED_ERROR_CODE: &str = "__QJS_RUNTIME_CANCELLED__";

#[derive(Clone)]
enum TrackedQjsTaskKind {
    Call,
    FetchImageBytes,
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

fn dart_callback_runtime() -> Result<&'static Mutex<tokio::runtime::Runtime>> {
    if let Some(rt) = DART_CALLBACK_RT.get() {
        return Ok(rt);
    }

    let runtime = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .map_err(|err| anyhow!(err.to_string()))?;

    match DART_CALLBACK_RT.set(Mutex::new(runtime)) {
        Ok(()) => Ok(DART_CALLBACK_RT
            .get()
            .expect("dart callback runtime 初始化后必须可读取")),
        Err(_runtime) => Ok(DART_CALLBACK_RT
            .get()
            .expect("dart callback runtime 并发初始化后必须可读取")),
    }
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
                TrackedQjsTaskKind::Call => Ok(TrackedQjsTaskOutput::Json(raw)),
                TrackedQjsTaskKind::FetchImageBytes => parse_ok_json_payload(&raw)
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
                TrackedQjsTaskKind::FetchImageBytes => parse_ok_json_payload(&raw)
                    .and_then(native_bytes_from_payload)
                    .map(TrackedQjsTaskOutput::Bytes),
            },
            Err(err) => Err(anyhow!(err)),
        };

        state.complete(outcome.map_err(|err| err.to_string()));
    });
}

async fn create_qjs_runtime(runtime_name: &str) -> Result<AsyncHostRuntime> {
    let runtime = AsyncHostRuntime::new(runtime_name).map_err(|err| anyhow!(err))?;
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

    let _init_guard = qjs_runtime_init_lock().lock().await;

    {
        let map = qjs_runtime_map().read().await;
        if let Some(runtime) = map.get(runtime_name) {
            return Ok(runtime.clone());
        }
    }

    let new_runtime = Arc::new(create_qjs_runtime(runtime_name).await?);

    let mut map = qjs_runtime_map().write().await;
    map.insert(runtime_name.to_owned(), new_runtime.clone());

    tracing::info!(
        "新建了一个 qjs 实例: {runtime_name}，thread id : {:?}",
        std::thread::current().id()
    );
    Ok(new_runtime)
}

async fn create_qjs_runtime_with_bundle(
    runtime_name: &str,
    bundle_name: &str,
    bundle_js: &str,
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
            replace_bundle_inner(existing_runtime, bundle_name, bundle_js).await?;
            tracing::info!("复用 qjs 实例并替换 bundle: {runtime_name} -> {bundle_name}");
            return Ok(());
        }
    }

    let new_runtime = Arc::new(create_qjs_runtime(runtime_name).await?);
    load_bundle_inner(&new_runtime, bundle_name, bundle_js).await?;

    let mut map = qjs_runtime_map().write().await;
    map.insert(runtime_name.to_owned(), new_runtime);

    tracing::info!("新建 qjs 实例并加载 bundle: {runtime_name} -> {bundle_name}");
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
        if existing != name {
            runtime
                .bundle_unload(&existing)
                .await
                .map_err(|err| anyhow!("卸载旧 bundle 失败({existing}): {err}"))?;
        }
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
            | (
                TrackedQjsTaskKind::FetchImageBytes,
                TrackedQjsTaskKind::FetchImageBytes,
            )
    );

    if !kind_matches {
        return Err(anyhow!("任务类型不匹配: {task_id}"));
    }

    let outcome = task.state.wait().await;
    let _ = remove_tracked_task(runtime_name, task_id).await;
    outcome
}

#[frb]
pub async fn qjs_replace_bundle(
    runtime_name: String,
    bundle_name: String,
    bundle_js: String,
) -> Result<()> {
    let runtime = qjs_runtime(&runtime_name).await?;
    replace_bundle_inner(&runtime, &bundle_name, &bundle_js).await
}

#[frb]
pub async fn qjs_call(runtime_name: String, fn_path: String, args_json: String) -> Result<String> {
    let data = call_current_bundle_by_json(&runtime_name, &fn_path, &args_json).await?;
    serde_json::to_string(&data).context("序列化调用结果失败")
}

#[frb]
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

#[frb]
pub async fn qjs_call_task_wait(runtime_name: String, task_id: u64) -> Result<String> {
    match wait_tracked_task_output(&runtime_name, task_id, TrackedQjsTaskKind::Call).await? {
        TrackedQjsTaskOutput::Json(raw) => Ok(raw),
        TrackedQjsTaskOutput::Bytes(_) => Err(anyhow!("任务类型不匹配: {task_id}")),
    }
}

#[frb]
pub async fn qjs_call_once(
    runtime_name: String,
    bundle_js: String,
    fn_path: String,
    args_json: String,
) -> Result<String> {
    let data = call_bundle_once_by_json(&runtime_name, &bundle_js, &fn_path, &args_json).await?;
    serde_json::to_string(&data).context("序列化一次性调用结果失败")
}

#[frb]
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

#[frb]
pub async fn qjs_call_once_task_wait(runtime_name: String, task_id: u64) -> Result<String> {
    match wait_tracked_task_output(&runtime_name, task_id, TrackedQjsTaskKind::Call).await? {
        TrackedQjsTaskOutput::Json(raw) => Ok(raw),
        TrackedQjsTaskOutput::Bytes(_) => Err(anyhow!("任务类型不匹配: {task_id}")),
    }
}

#[frb]
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

#[frb]
pub async fn qjs_current_bundle(runtime_name: String) -> Result<String> {
    let runtime = qjs_runtime(&runtime_name).await?;
    let current = current_bundle_name(&runtime).await?;
    serde_json::to_string(&current).context("序列化当前 bundle 信息失败")
}

#[frb]
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

#[frb]
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

#[frb]
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

#[frb]
pub async fn qjs_fetch_image_bytes(
    runtime_name: String,
    fn_path: String,
    args_json: String,
) -> Result<Vec<u8>> {
    let payload = call_current_bundle_by_json(&runtime_name, &fn_path, &args_json)
        .await
        .map_err(|e| anyhow!(e))?;

    native_bytes_from_payload(payload)
}

#[frb]
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
        TrackedQjsTaskKind::FetchImageBytes,
    )
    .await
}

#[frb]
pub async fn qjs_fetch_image_bytes_task_wait(
    runtime_name: String,
    task_id: u64,
) -> Result<Vec<u8>> {
    match wait_tracked_task_output(&runtime_name, task_id, TrackedQjsTaskKind::FetchImageBytes)
        .await?
    {
        TrackedQjsTaskOutput::Bytes(bytes) => Ok(bytes),
        TrackedQjsTaskOutput::Json(_) => Err(anyhow!("任务类型不匹配: {task_id}")),
    }
}

#[frb]
pub async fn qjs_fetch_image_bytes_once(
    runtime_name: String,
    bundle_js: String,
    fn_path: String,
    args_json: String,
) -> Result<Vec<u8>> {
    let payload = call_bundle_once_by_json(&runtime_name, &bundle_js, &fn_path, &args_json)
        .await
        .map_err(|e| anyhow!(e))?;

    native_bytes_from_payload(payload)
}

#[frb]
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
        TrackedQjsTaskKind::FetchImageBytes,
    )
    .await
}

#[frb]
pub async fn qjs_fetch_image_bytes_once_task_wait(
    runtime_name: String,
    task_id: u64,
) -> Result<Vec<u8>> {
    match wait_tracked_task_output(&runtime_name, task_id, TrackedQjsTaskKind::FetchImageBytes)
        .await?
    {
        TrackedQjsTaskOutput::Bytes(bytes) => Ok(bytes),
        TrackedQjsTaskOutput::Json(_) => Err(anyhow!("任务类型不匹配: {task_id}")),
    }
}

#[frb]
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

#[frb]
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

#[frb(sync)]
pub fn set_qjs_error_stack_enabled(enabled: bool) -> Result<()> {
    configure_js_error_stack(enabled);
    Ok(())
}

#[frb]
pub fn register_load_plugin_config(
    dart_callback: impl Fn(String, String, String) -> DartFnFuture<String> + Send + Sync + 'static,
) -> Result<()> {
    let callback: PersistentCallback = Arc::new(dart_callback);
    register_load_plugin_config_handler(move |name, key, value| {
        run_dart_callback_blocking(Arc::clone(&callback), name, key, value)
            .map_err(|err| anyhow!(err.to_string()))
    });
    Ok(())
}

#[frb]
pub fn register_save_plugin_config(
    dart_callback: impl Fn(String, String, String) -> DartFnFuture<String> + Send + Sync + 'static,
) -> Result<()> {
    let callback: PersistentCallback = Arc::new(dart_callback);
    register_save_plugin_config_handler(move |name, key, value| {
        run_dart_callback_blocking(Arc::clone(&callback), name, key, value)
            .map_err(|err| anyhow!(err.to_string()))
    });
    Ok(())
}

fn run_dart_callback_blocking(
    callback: PersistentCallback,
    name: String,
    key: String,
    value: String,
) -> Result<String> {
    let rt = dart_callback_runtime()?;
    let guard = rt
        .lock()
        .map_err(|_| anyhow!("dart callback runtime 锁已损坏"))?;
    let out = guard.block_on(callback(name, key, value));
    Ok(out)
}

#[frb(sync)]
pub fn set_log_http_forward(url: String) -> Result<()> {
    configure_log_http_endpoint(Some(url));
    Ok(())
}

#[frb(sync)]
pub fn get_js_bundle(name: String) -> Result<String> {
    match name.as_str() {
        "bikaComic" => Ok(BIKA_JS_BUNDLE.to_string()),
        "jmComic" => Ok(JM_JS_BUNDLE.to_string()),
        _ => Ok("".to_string()),
    }
}

#[frb]
pub async fn init_qjs_runtime(name: String) -> Result<()> {
    let _runtime = qjs_runtime(&name).await?;
    Ok(())
}

#[frb]
pub async fn init_qjs_runtime_with_bundle(
    runtime_name: String,
    bundle_name: String,
    bundle_js: String,
) -> Result<()> {
    create_qjs_runtime_with_bundle(&runtime_name, &bundle_name, &bundle_js).await
}
