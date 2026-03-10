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
            let runtime = AsyncHostRuntime::new(false).map_err(|err| anyhow!(err))?;
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

async fn eval_payload(runtime: &AsyncHostRuntime, script: String, context: &str) -> Result<Value> {
    let raw = runtime
        .spawn(script)
        .map_err(|err| anyhow!("{context}: {err}"))?
        .wait_async()
        .await
        .map_err(|err| anyhow!("{context}: {err}"))?;

    let payload: Value = serde_json::from_str(&raw).context("解析 JS 返回 JSON 失败")?;
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

#[frb]
pub async fn jm_request(payload_json: String) -> Result<String> {
    let runtime = qjs_runtime().await?;
    let payload: Value = serde_json::from_str(&payload_json).context("请求参数不是合法 JSON")?;
    let bundle_literal = serde_json::to_string(JM_HTTP_BUNDLE).context("序列化 JM bundle 失败")?;
    let payload_literal = serde_json::to_string(&payload).context("序列化请求参数失败")?;

    let script = format!(
        r#"
        (async () => {{
          try {{
            const source = {bundle_literal};
            const module = {{ exports: {{}} }};
            const exports = module.exports;
            const requireFn = typeof require === "function" ? require.bind(globalThis) : undefined;
            const runner = new Function("module", "exports", "require", source);
            runner(module, exports, requireFn);

            let api = module.exports;
            if (api && typeof api === "object" && api.default !== undefined) {{
              api = api.default;
            }}
            if (!api || typeof api.request !== "function") {{
              throw new TypeError("JM HTTP bundle 必须导出 request 函数");
            }}
            const req = {payload_literal};
            const data = await api.request(req);
            return JSON.stringify({{ ok: true, data }});
          }} catch (err) {{
            const message = String(err && (err.stack || err.message) ? (err.stack || err.message) : err);
            return JSON.stringify({{ ok: false, error: message }});
          }}
        }})()
        "#
    );

    let data = eval_payload(runtime, script, "执行 JM 请求失败").await?;
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
