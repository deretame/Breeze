use anyhow::{Context, Result, anyhow};
use flutter_rust_bridge::{DartFnFuture, frb};
use rquickjs_playground::web_runtime::native_buffer_take_raw;
use rquickjs_playground::{
    AsyncHostRuntime, HttpClientConfig, RuntimeTaskHandle, configure_http_client,
    configure_js_error_stack, register_load_plugin_config_handler,
    register_save_plugin_config_handler,
};
use serde_json::Value;
use std::collections::HashMap;
use std::sync::{Arc, Mutex, OnceLock};
use tokio::sync::RwLock;

type QjsRuntimeMap = HashMap<String, Arc<AsyncHostRuntime>>;
type QjsCallTaskMap = HashMap<String, HashMap<u64, RuntimeTaskHandle>>;
type PersistentCallback =
    Arc<dyn Fn(String, String, String) -> DartFnFuture<String> + Send + Sync + 'static>;

static QJS_RUNTIMES: OnceLock<RwLock<QjsRuntimeMap>> = OnceLock::new();
static QJS_CALL_TASKS: OnceLock<RwLock<QjsCallTaskMap>> = OnceLock::new();
static DART_CALLBACK_RT: OnceLock<Mutex<tokio::runtime::Runtime>> = OnceLock::new();

fn qjs_runtime_map() -> &'static RwLock<QjsRuntimeMap> {
    QJS_RUNTIMES.get_or_init(|| RwLock::new(HashMap::new()))
}

fn qjs_call_task_map() -> &'static RwLock<QjsCallTaskMap> {
    QJS_CALL_TASKS.get_or_init(|| RwLock::new(HashMap::new()))
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

    let new_runtime = Arc::new(create_qjs_runtime(runtime_name).await?);

    let mut map = qjs_runtime_map().write().await;
    let runtime = map
        .entry(runtime_name.to_owned())
        .or_insert_with(|| new_runtime.clone())
        .clone();

    tracing::info!("新建了一个 qjs 实例: {runtime_name}");
    Ok(runtime)
}

async fn qjs_runtime_if_exists(runtime_name: &str) -> Option<Arc<AsyncHostRuntime>> {
    let map = qjs_runtime_map().read().await;
    map.get(runtime_name).cloned()
}

async fn insert_qjs_call_task(runtime_name: &str, task: RuntimeTaskHandle) {
    let task_id = task.id();
    let mut map = qjs_call_task_map().write().await;
    map.entry(runtime_name.to_owned())
        .or_default()
        .insert(task_id, task);
}

async fn take_qjs_call_task(runtime_name: &str, task_id: u64) -> Option<RuntimeTaskHandle> {
    let mut map = qjs_call_task_map().write().await;
    let runtime_tasks = map.get_mut(runtime_name)?;
    let task = runtime_tasks.remove(&task_id);
    if runtime_tasks.is_empty() {
        map.remove(runtime_name);
    }
    task
}

async fn clear_runtime_call_tasks(runtime_name: &str) {
    let mut map = qjs_call_task_map().write().await;
    map.remove(runtime_name);
}

fn parse_args_array(args_json: &str) -> Result<Value> {
    let args: Value = serde_json::from_str(args_json).context("调用参数不是合法 JSON")?;
    Ok(match args {
        Value::Array(_) => args,
        Value::Null => Value::Array(Vec::new()),
        other => Value::Array(vec![other]),
    })
}

fn parse_ok_json_payload(raw: &str) -> Result<Value> {
    let payload: Value = serde_json::from_str(raw).context("解析 JS 返回 JSON 失败")?;
    if payload.get("ok").and_then(Value::as_bool) == Some(true) {
        Ok(payload.get("data").cloned().unwrap_or(Value::Null))
    } else {
        Err(anyhow!(
            "{}",
            payload
                .get("error")
                .and_then(Value::as_str)
                .unwrap_or("执行失败")
        ))
    }
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
    runtime: &AsyncHostRuntime,
    name: &str,
    fn_path: &str,
    args: &Value,
) -> Result<Value> {
    runtime
        .bundle_call(name, fn_path, args)
        .await
        .map_err(|err| anyhow!(err))
}

async fn call_current_bundle_inner(
    runtime: &AsyncHostRuntime,
    fn_path: &str,
    args: &Value,
) -> Result<Value> {
    let Some(name) = current_bundle_name(runtime).await? else {
        return Err(anyhow!(
            "当前 runtime 未加载 bundle，请先调用 qjs_replace_bundle"
        ));
    };
    call_loaded_bundle_inner(runtime, &name, fn_path, args).await
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
    call_current_bundle_inner(&runtime, fn_path, &args).await
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

async fn start_current_bundle_call_by_json(
    runtime_name: &str,
    fn_path: &str,
    args_json: &str,
) -> Result<u64> {
    let runtime = qjs_runtime(runtime_name).await?;
    let args = parse_call_input(fn_path, args_json)?;
    qjs_call_start_inner(runtime_name, &runtime, fn_path, &args).await
}

async fn wait_call_payload(runtime_name: &str, task_id: u64) -> Result<Value> {
    let handle = take_qjs_call_task(runtime_name, task_id)
        .await
        .ok_or_else(|| anyhow!("调用任务不存在或已完成: {task_id}"))?;

    let raw = handle
        .wait_async()
        .await
        .map_err(|err| anyhow!("等待 QJS 调用结果失败: {err}"))?;
    parse_ok_json_payload(&raw)
}

async fn qjs_call_start_inner(
    runtime_name: &str,
    runtime: &AsyncHostRuntime,
    fn_path: &str,
    args: &Value,
) -> Result<u64> {
    let Some(bundle_name) = current_bundle_name(runtime).await? else {
        return Err(anyhow!(
            "当前 runtime 未加载 bundle，请先调用 qjs_replace_bundle"
        ));
    };

    let handle = runtime
        .bundle_call_start(&bundle_name, fn_path, args)
        .await
        .map_err(|err| anyhow!("提交 QJS 调用任务失败: {err}"))?;
    let task_id = handle.id();
    insert_qjs_call_task(runtime_name, handle).await;
    Ok(task_id)
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
pub async fn qjs_call_start(
    runtime_name: String,
    fn_path: String,
    args_json: String,
) -> Result<u64> {
    start_current_bundle_call_by_json(&runtime_name, &fn_path, &args_json).await
}

#[frb]
pub async fn qjs_call_wait(runtime_name: String, task_id: u64) -> Result<String> {
    let data = wait_call_payload(&runtime_name, task_id).await?;
    serde_json::to_string(&data).context("序列化调用结果失败")
}

#[frb]
pub async fn qjs_call_cancel(runtime_name: String, task_id: u64) -> Result<bool> {
    if runtime_name.trim().is_empty() {
        return Err(anyhow!("runtime_name 不能为空"));
    }

    let Some(runtime) = qjs_runtime_if_exists(&runtime_name).await else {
        let _ = take_qjs_call_task(&runtime_name, task_id).await;
        return Ok(true);
    };

    let cancelled = runtime.cancel(task_id);
    if cancelled {
        let _ = take_qjs_call_task(&runtime_name, task_id).await;
        return Ok(true);
    }

    Ok(false)
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

    clear_runtime_call_tasks(&runtime_name).await;
    let mut map = qjs_runtime_map().write().await;
    Ok(map.remove(&runtime_name).is_some())
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
pub async fn qjs_fetch_image_bytes_start(
    runtime_name: String,
    fn_path: String,
    args_json: String,
) -> Result<u64> {
    start_current_bundle_call_by_json(&runtime_name, &fn_path, &args_json).await
}

#[frb]
pub async fn qjs_fetch_image_bytes_wait(runtime_name: String, task_id: u64) -> Result<Vec<u8>> {
    let payload = wait_call_payload(&runtime_name, task_id).await?;
    native_bytes_from_payload(payload)
}

#[frb]
pub async fn qjs_fetch_image_bytes_cancel(runtime_name: String, task_id: u64) -> Result<bool> {
    qjs_call_cancel(runtime_name, task_id).await
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
