use anyhow::{Context, Result, anyhow};
use flutter_rust_bridge::frb;
use rquickjs_playground::AsyncHostRuntime;
use serde_json::Value;
use tokio::sync::OnceCell;

static QJS_RUNTIME: OnceCell<AsyncHostRuntime> = OnceCell::const_new();
const JM_HTTP_BUNDLE: &str = include_str!("../js/jm_http.bundle.cjs");

async fn qjs_runtime() -> Result<&'static AsyncHostRuntime> {
    QJS_RUNTIME
        .get_or_try_init(|| async {
            tracing::info!("新建了一个qjs实例");
            let runtime = AsyncHostRuntime::new(false, "jm").map_err(|err| anyhow!(err))?;
            let init_script = r#"(async () => {
                    return "ok";
            })()"#;
            let task = runtime
                .spawn(init_script)
                .map_err(|err| anyhow!("提交 JM bundle 初始化任务失败: {err}"))?;
            task.wait_async()
                .await
                .map_err(|err| anyhow!("加载 Bika QJS bundle 失败: {err}"))?;

            Ok(runtime)
        })
        .await
}

fn parse_args_array(args_json: &str) -> Result<Value> {
    let args: Value = serde_json::from_str(args_json).context("调用参数不是合法 JSON")?;
    if !args.is_array() {
        return Err(anyhow!("调用参数必须是 JSON 数组"));
    }
    Ok(args)
}

async fn load_bundle_inner(runtime: &AsyncHostRuntime, name: &str, bundle_js: &str) -> Result<()> {
    runtime
        .bundle_load(name, bundle_js)
        .await
        .map_err(|err| anyhow!("加载 JM bundle 失败: {err}"))
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
            "当前 runtime 未加载 bundle，请先调用 jm_replace_bundle"
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
pub async fn jm_replace_bundle(name: String, bundle_js: String) -> Result<()> {
    let runtime = qjs_runtime().await?;
    replace_bundle_inner(runtime, &name, &bundle_js).await
}

#[frb]
pub async fn jm_call(fn_path: String, args_json: String) -> Result<String> {
    let runtime = qjs_runtime().await?;
    let args = parse_args_array(&args_json)?;
    let data = call_current_bundle_inner(runtime, &fn_path, &args).await?;
    serde_json::to_string(&data).context("序列化调用结果失败")
}

#[frb]
pub async fn jm_call_once(bundle_js: String, fn_path: String, args_json: String) -> Result<String> {
    let runtime = qjs_runtime().await?;
    let args = parse_args_array(&args_json)?;
    let data = call_bundle_once_inner(runtime, &bundle_js, &fn_path, &args).await?;
    serde_json::to_string(&data).context("序列化一次性调用结果失败")
}

#[frb]
pub async fn jm_clear_bundle() -> Result<bool> {
    let runtime = qjs_runtime().await?;
    let Some(name) = current_bundle_name(runtime).await? else {
        return Ok(false);
    };
    runtime
        .bundle_unload(&name)
        .await
        .map_err(|err| anyhow!("清空当前 bundle 失败: {err}"))
}

#[frb]
pub async fn jm_current_bundle() -> Result<String> {
    let runtime = qjs_runtime().await?;
    let current = current_bundle_name(runtime).await?;
    serde_json::to_string(&current).context("序列化当前 bundle 信息失败")
}

#[frb]
pub async fn jm_request(payload_json: String) -> Result<String> {
    let runtime = qjs_runtime().await?;
    let payload: Value = serde_json::from_str(&payload_json).context("请求参数不是合法 JSON")?;
    ensure_jm_http_loaded(runtime).await?;
    let args = Value::Array(vec![payload]);
    let data = call_current_bundle_inner(runtime, "request", &args).await?;
    serde_json::to_string(&data).context("序列化 JM 响应失败")
}

#[frb]
pub async fn test_hello_world() -> Result<String> {
    let runtime = qjs_runtime().await?;

    let result = runtime
        .spawn("console.log('hello world from JM runtime'); 'hello world';")
        .map_err(|err| anyhow!("执行 JS 代码失败: {err}"))?
        .wait_async()
        .await
        .map_err(|err| anyhow!("等待 JS 结果失败: {err}"))?;

    Ok(result)
}
