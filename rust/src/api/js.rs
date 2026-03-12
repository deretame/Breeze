use anyhow::{Context, Result, anyhow};
use flutter_rust_bridge::frb;
use rquickjs_playground::{AsyncHostRuntime, RuntimeTaskHandle};
use serde_json::Value;
use std::collections::HashMap;
use std::sync::{Arc, OnceLock};
use tokio::sync::RwLock;

type QjsRuntimeMap = HashMap<String, Arc<AsyncHostRuntime>>;
type QjsCallTaskMap = HashMap<String, HashMap<u64, RuntimeTaskHandle>>;

static QJS_RUNTIMES: OnceLock<RwLock<QjsRuntimeMap>> = OnceLock::new();
static QJS_CALL_TASKS: OnceLock<RwLock<QjsCallTaskMap>> = OnceLock::new();

const JM_RUNTIME_NAME: &str = "jm";
const JM_HTTP_BUNDLE: &str = include_str!("../js/jm_http.bundle.cjs");

fn qjs_runtime_map() -> &'static RwLock<QjsRuntimeMap> {
    QJS_RUNTIMES.get_or_init(|| RwLock::new(HashMap::new()))
}

fn qjs_call_task_map() -> &'static RwLock<QjsCallTaskMap> {
    QJS_CALL_TASKS.get_or_init(|| RwLock::new(HashMap::new()))
}

async fn create_qjs_runtime(runtime_name: &str) -> Result<AsyncHostRuntime> {
    let runtime = AsyncHostRuntime::new(false, runtime_name).map_err(|err| anyhow!(err))?;
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
    if !args.is_array() {
        return Err(anyhow!("调用参数必须是 JSON 数组"));
    }
    Ok(args)
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
        .map_err(|err| anyhow!("执行已加载 bundle 函数失败: {err}"))
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
        .map_err(|err| anyhow!("执行一次性 bundle 调用失败: {err}"))
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

async fn ensure_jm_http_loaded(runtime: &AsyncHostRuntime) -> Result<()> {
    let names = runtime
        .bundle_list()
        .await
        .map_err(|err| anyhow!("读取 bundle 列表失败: {err}"))?;
    if names.iter().any(|name| name == "jm_http") {
        return Ok(());
    }
    replace_bundle_inner(runtime, "jm_http", JM_HTTP_BUNDLE).await
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
    let runtime = qjs_runtime(&runtime_name).await?;
    let args = parse_args_array(&args_json)?;
    let data = call_current_bundle_inner(&runtime, &fn_path, &args).await?;
    serde_json::to_string(&data).context("序列化调用结果失败")
}

#[frb]
pub async fn qjs_call_start(
    runtime_name: String,
    fn_path: String,
    args_json: String,
) -> Result<u64> {
    let runtime = qjs_runtime(&runtime_name).await?;
    let args = parse_args_array(&args_json)?;
    qjs_call_start_inner(&runtime_name, &runtime, &fn_path, &args).await
}

#[frb]
pub async fn qjs_call_wait(runtime_name: String, task_id: u64) -> Result<String> {
    let handle = take_qjs_call_task(&runtime_name, task_id)
        .await
        .ok_or_else(|| anyhow!("调用任务不存在或已完成: {task_id}"))?;

    let raw = handle
        .wait_async()
        .await
        .map_err(|err| anyhow!("等待 QJS 调用结果失败: {err}"))?;
    let data = parse_ok_json_payload(&raw)?;
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
    let runtime = qjs_runtime(&runtime_name).await?;
    let args = parse_args_array(&args_json)?;
    let data = call_bundle_once_inner(&runtime, &bundle_js, &fn_path, &args).await?;
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
pub async fn jm_request(payload_json: String) -> Result<String> {
    let runtime = qjs_runtime(JM_RUNTIME_NAME).await?;
    let payload: Value = serde_json::from_str(&payload_json).context("请求参数不是合法 JSON")?;
    ensure_jm_http_loaded(&runtime).await?;
    let args = Value::Array(vec![payload]);
    let data = call_current_bundle_inner(&runtime, "request", &args).await?;
    serde_json::to_string(&data).context("序列化 JM 响应失败")
}

#[frb]
pub async fn test_hello_world() -> Result<String> {
    let runtime = qjs_runtime(JM_RUNTIME_NAME).await?;

    let result = runtime
        .spawn("console.log('hello world from JM runtime'); 'hello world';")
        .map_err(|err| anyhow!("执行 JS 代码失败: {err}"))?
        .wait_async()
        .await
        .map_err(|err| anyhow!("等待 JS 结果失败: {err}"))?;

    Ok(result)
}
