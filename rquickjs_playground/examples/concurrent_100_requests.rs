use std::time::{Duration, Instant};

use axum::Json;
use axum::Router;
use axum::extract::Query;
use axum::routing::get;
use rquickjs_playground::AsyncHostRuntime;
use serde::Deserialize;
use serde_json::{Value, json};
use tokio::sync::oneshot;
use tokio::time::sleep;

#[derive(Debug, Deserialize)]
struct PingQuery {
    id: Option<u32>,
}

async fn ping_handler(Query(query): Query<PingQuery>) -> Json<Value> {
    sleep(Duration::from_millis(100)).await;
    Json(json!({
        "ok": true,
        "id": query.id.unwrap_or(0)
    }))
}

#[tokio::main(flavor = "multi_thread", worker_threads = 2)]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let app = Router::new().route("/ping", get(ping_handler));

    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await?;
    let addr = listener.local_addr()?;
    let base_url = format!("http://{addr}");
    let (shutdown_tx, shutdown_rx) = oneshot::channel::<()>();

    let server_task = tokio::spawn(async move {
        let server = axum::serve(listener, app);
        let graceful = server.with_graceful_shutdown(async {
            let _ = shutdown_rx.await;
        });
        let _ = graceful.await;
    });

    let base_url_json = serde_json::to_string(&base_url)?;
    let script = format!(
        r#"
        (async () => {{
          const baseUrl = {base_url_json};
          const total = 100;
          const start = Date.now();
          const pending = Array.from({{ length: total }}, (_, i) =>
            fetch(`${{baseUrl}}/ping?id=${{i}}`).then((res) => res.json())
          );
          const data = await Promise.all(pending);
          const elapsedMs = Date.now() - start;

          return JSON.stringify({{
            total,
            elapsedMs,
            firstId: data[0]?.id ?? null,
            lastId: data[data.length - 1]?.id ?? null
          }});
        }})()
        "#
    );

    let rust_start = Instant::now();
    let raw = tokio::task::spawn_blocking(move || {
        let host =
            AsyncHostRuntime::new("example-concurrent-requests").expect("创建 HostRuntime 失败");
        host.spawn(&script).expect("执行 JS 脚本失败").wait()
    })
    .await??;
    let rust_elapsed = rust_start.elapsed().as_millis();

    let parsed: Value = serde_json::from_str(&raw)?;
    let js_elapsed = parsed["elapsedMs"].as_u64().unwrap_or_default();
    let serial_baseline = 100_u64 * 100_u64;
    let concurrent_likely = js_elapsed < serial_baseline / 2;

    println!("result: {raw}");
    println!("serial_baseline_ms: {serial_baseline}");
    println!("rust_elapsed_ms: {rust_elapsed}");
    println!("concurrent_likely: {concurrent_likely}");

    let _ = shutdown_tx.send(());
    let _ = server_task.await;

    Ok(())
}
