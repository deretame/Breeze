use anyhow::{Result, anyhow};
use flutter_rust_bridge::frb;
use rquickjs_playground::AsyncHostRuntime;
use tokio::sync::OnceCell;

static QJS_RUNTIME: OnceCell<AsyncHostRuntime> = OnceCell::const_new();

async fn qjs_runtime() -> Result<&'static AsyncHostRuntime> {
    QJS_RUNTIME
        .get_or_try_init(|| async {
            let runtime = AsyncHostRuntime::new("jm").map_err(|err| anyhow!(err))?;
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
