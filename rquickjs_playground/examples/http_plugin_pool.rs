use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use std::sync::Arc;
use std::sync::mpsc;
use std::thread;

use axum::Json;
use axum::Router;
use axum::extract::State;
use axum::routing::post;
use rquickjs_playground::AsyncHostRuntime;
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use tokio::sync::oneshot;
use tokio::time::{Duration, sleep};

#[derive(Debug)]
struct WorkerJob {
    name: String,
    function: String,
    args: Value,
    reply_tx: oneshot::Sender<Result<Value, String>>,
}

#[derive(Clone)]
struct PluginManager {
    workers: Arc<Vec<mpsc::Sender<WorkerJob>>>,
}

impl PluginManager {
    fn new(worker_count: usize) -> Self {
        let mut workers = Vec::with_capacity(worker_count);

        for worker_id in 0..worker_count {
            let (tx, rx) = mpsc::channel::<WorkerJob>();
            workers.push(tx);

            thread::spawn(move || {
                let host = AsyncHostRuntime::new(format!("example-http-plugin-worker-{worker_id}"))
                    .expect("创建 HostRuntime 失败");
                host.spawn(plugin_bootstrap_script())
                    .expect("初始化插件脚本失败")
                    .wait()
                    .expect("初始化插件脚本失败");

                let info = get_plugin_info(&host, "test1", &json!({ "tag": "http-worker-init" }))
                    .expect("读取插件 getInfo 失败");
                println!("http worker test1 getInfo: {info}");

                while let Ok(job) = rx.recv() {
                    let _ =
                        job.reply_tx
                            .send(invoke_one(&host, &job.name, &job.function, &job.args));
                }
            });
        }

        Self {
            workers: Arc::new(workers),
        }
    }

    async fn invoke(&self, name: String, function: String, args: Value) -> Result<Value, String> {
        let idx = self.pick_worker(&name);
        let (reply_tx, reply_rx) = oneshot::channel();
        self.workers[idx]
            .send(WorkerJob {
                name,
                function,
                args,
                reply_tx,
            })
            .map_err(|e| format!("投递任务失败: {e}"))?;

        reply_rx
            .await
            .map_err(|e| format!("worker 结果接收失败: {e}"))?
    }

    fn pick_worker(&self, plugin_name: &str) -> usize {
        let mut hasher = DefaultHasher::new();
        plugin_name.hash(&mut hasher);
        (hasher.finish() as usize) % self.workers.len()
    }
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
struct InvokeHttpRequest {
    item_id: u64,
    name: String,
    function: String,
    args: Value,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct InvokeHttpResponse {
    item_id: u64,
    ok: bool,
    data: Option<Value>,
    error: Option<String>,
}

async fn invoke_handler(
    State(manager): State<PluginManager>,
    Json(payload): Json<InvokeHttpRequest>,
) -> Json<InvokeHttpResponse> {
    if payload.name == "test1" && payload.function == "1" {
        sleep(Duration::from_millis(80)).await;
    }
    if payload.name == "test2" {
        sleep(Duration::from_millis(20)).await;
    }

    match manager
        .invoke(payload.name, payload.function, payload.args)
        .await
    {
        Ok(data) => Json(InvokeHttpResponse {
            item_id: payload.item_id,
            ok: true,
            data: Some(data),
            error: None,
        }),
        Err(error) => Json(InvokeHttpResponse {
            item_id: payload.item_id,
            ok: false,
            data: None,
            error: Some(error),
        }),
    }
}

fn invoke_one(
    host: &AsyncHostRuntime,
    name: &str,
    function: &str,
    args: &Value,
) -> Result<Value, String> {
    let name_json = serde_json::to_string(name).map_err(|e| e.to_string())?;
    let function_json = serde_json::to_string(function).map_err(|e| e.to_string())?;
    let args_json = serde_json::to_string(args).map_err(|e| e.to_string())?;

    let script = format!(
        r#"
        (async () => {{
          try {{
            const data = await globalThis.__plugin_invoke({name_json}, {function_json}, {args_json});
            return JSON.stringify({{ ok: true, data }});
          }} catch (err) {{
            return JSON.stringify({{ ok: false, error: String(err && err.message ? err.message : err) }});
          }}
        }})()
        "#
    );

    let raw = host
        .spawn(&script)
        .map_err(|e| e.to_string())?
        .wait()
        .map_err(|e| e.to_string())?;
    let payload: Value = serde_json::from_str(&raw).map_err(|e| e.to_string())?;
    if payload.get("ok").and_then(Value::as_bool) == Some(true) {
        Ok(payload.get("data").cloned().unwrap_or(Value::Null))
    } else {
        Err(payload
            .get("error")
            .and_then(Value::as_str)
            .unwrap_or("调用失败")
            .to_string())
    }
}

fn get_plugin_info(
    host: &AsyncHostRuntime,
    plugin_name: &str,
    query: &Value,
) -> Result<Value, String> {
    let name_json = serde_json::to_string(plugin_name).map_err(|e| e.to_string())?;
    let query_json = serde_json::to_string(query).map_err(|e| e.to_string())?;
    let script = format!(
        r#"
        (async () => {{
          try {{
            const data = await globalThis.__plugin_get_info({name_json}, {query_json});
            return JSON.stringify({{ ok: true, data }});
          }} catch (err) {{
            return JSON.stringify({{ ok: false, error: String(err && err.message ? err.message : err) }});
          }}
        }})()
        "#
    );

    let raw = host
        .spawn(&script)
        .map_err(|e| e.to_string())?
        .wait()
        .map_err(|e| e.to_string())?;
    let payload: Value = serde_json::from_str(&raw).map_err(|e| e.to_string())?;
    if payload.get("ok").and_then(Value::as_bool) == Some(true) {
        Ok(payload.get("data").cloned().unwrap_or(Value::Null))
    } else {
        Err(payload
            .get("error")
            .and_then(Value::as_str)
            .unwrap_or("调用失败")
            .to_string())
    }
}

fn plugin_bootstrap_script() -> &'static str {
    r#"
    (async () => {
      const plugins = {
        test1: {
          getInfo: (query) => ({
            name: "test1",
            version: "1.0.0",
            description: "基础字符串与数字处理插件",
            apiVersion: 1,
            author: "demo-team",
            capabilities: ["transform"],
            requestTag: query && query.tag ? String(query.tag) : "default"
          }),
          handlers: {
            "1": async (arg) => ({ doubled: Number(arg) * 2 }),
            "2": async (arg) => ({ upper: String(arg).toUpperCase() }),
          }
        },
        test2: {
          getInfo: () => ({
            name: "test2",
            version: "1.0.0",
            description: "计算输入 JSON 长度",
            apiVersion: 1,
            capabilities: ["analyze"]
          }),
          handlers: {
            "1": async (arg) => ({ len: JSON.stringify(arg).length }),
          }
        }
      };

      const normalizeInfo = (raw) => {
        if (!raw || typeof raw !== "object") {
          throw new TypeError("getInfo 必须返回对象");
        }
        const info = {
          name: String(raw.name || "").trim(),
          version: String(raw.version || "").trim(),
          description: String(raw.description || "").trim(),
          apiVersion: raw.apiVersion === undefined ? 1 : Number(raw.apiVersion),
          author: raw.author == null ? undefined : String(raw.author),
          homepage: raw.homepage == null ? undefined : String(raw.homepage),
          capabilities: Array.isArray(raw.capabilities) ? raw.capabilities.map((x) => String(x)) : undefined,
          minHostVersion: raw.minHostVersion == null ? undefined : String(raw.minHostVersion),
        };
        if (!info.name) throw new TypeError("getInfo.name 不能为空");
        if (!info.version) throw new TypeError("getInfo.version 不能为空");
        if (!info.description) throw new TypeError("getInfo.description 不能为空");
        if (!Number.isInteger(info.apiVersion) || info.apiVersion <= 0) {
          throw new TypeError("getInfo.apiVersion 必须是正整数");
        }
        return info;
      };

      globalThis.__plugin_invoke = async (name, fnId, args) => {
        const key = String(name || "").trim();
        const pluginImpl = plugins[key];
        if (!pluginImpl) throw new Error(`插件不存在: ${name}`);
        const fn = pluginImpl.handlers && pluginImpl.handlers[String(fnId)];
        if (typeof fn !== "function") {
          throw new Error(`插件 ${name} 不支持函数 ${fnId}`);
        }
        return fn(args);
      };

      globalThis.__plugin_get_info = (name, query) => {
        const key = String(name || "").trim();
        if (!key) return null;
        const pluginImpl = plugins[key];
        if (!pluginImpl || typeof pluginImpl.getInfo !== "function") {
          throw new Error(`插件 ${key} 必须导出 getInfo()`);
        }
        return normalizeInfo(pluginImpl.getInfo(query));
      };

      return "ok";
    })()
    "#
}

#[tokio::main(flavor = "multi_thread", worker_threads = 2)]
async fn main() {
    let manager = PluginManager::new(2);
    let app = Router::new()
        .route("/invoke", post(invoke_handler))
        .with_state(manager);

    let listener = tokio::net::TcpListener::bind("127.0.0.1:0")
        .await
        .expect("绑定端口失败");
    let addr = listener.local_addr().expect("读取本地地址失败");
    let (shutdown_tx, shutdown_rx) = oneshot::channel::<()>();

    let server_task = tokio::spawn(async move {
        let server = axum::serve(listener, app);
        let graceful = server.with_graceful_shutdown(async {
            let _ = shutdown_rx.await;
        });
        if let Err(err) = graceful.await {
            eprintln!("HTTP 服务异常: {err}");
        }
    });

    let url_json =
        serde_json::to_string(&format!("http://{addr}/invoke")).expect("序列化 URL 失败");

    let script = format!(
        r#"
        (async () => {{
          const endpoint = {url_json};
          const items = [
            {{ itemId: 1, name: "test1", function: "1", args: 123 }},
            {{ itemId: 2, name: "test1", function: "2", args: "hello" }},
            {{ itemId: 3, name: "test2", function: "1", args: {{ k: "v", n: 42 }} }},
          ];

          const pending = items.map((item) =>
            fetch(endpoint, {{
              method: "POST",
              headers: {{ "Content-Type": "application/json" }},
              body: JSON.stringify(item),
            }})
              .then((res) => res.json())
          );

          const completed = [];
          while (pending.length > 0) {{
            const wrapped = pending.map((promise, idx) =>
              promise.then((value) => ({{ idx, value }}))
            );
            const winner = await Promise.race(wrapped);
            pending.splice(winner.idx, 1);
            completed.push(winner.value);
          }}

          return JSON.stringify(completed);
        }})()
        "#
    );

    let result = tokio::task::spawn_blocking(move || {
        let host =
            AsyncHostRuntime::new("example-http-plugin-main").expect("创建 HostRuntime 失败");
        host.spawn(&script)
            .expect("执行 JS 请求失败")
            .wait()
            .expect("执行 JS 请求失败")
    })
    .await
    .expect("等待 JS 任务失败");
    println!("JS 收到的完成顺序结果: {result}");

    let _ = shutdown_tx.send(());
    let _ = server_task.await;

    let parsed: Value = serde_json::from_str(&result).expect("解析 JS 结果失败");
    let arr = parsed.as_array().expect("结果必须是数组");
    assert_eq!(arr.len(), 3);
    assert!(arr.iter().all(|x| x["ok"] == json!(true)));
    let mut ids = arr
        .iter()
        .filter_map(|x| x["itemId"].as_u64())
        .collect::<Vec<_>>();
    ids.sort_unstable();
    assert_eq!(ids, vec![1, 2, 3]);
}
