use crate::AsyncHostRuntime;
use axum::{Json, Router, extract::State, routing::get};
use serde::Deserialize;
use serde_json::json;
use std::sync::Arc;
use std::sync::mpsc;
use std::thread;
use std::time::{Duration, Instant};
use tokio::sync::oneshot;

#[test]
fn async_runtime_spawn_is_non_blocking() {
    let runtime =
        AsyncHostRuntime::new("task-runtime-non-blocking").expect("创建 AsyncHostRuntime 失败");

    let script = r#"
      (async () => {
        await new Promise((resolve) => setTimeout(resolve, 40));
        return JSON.stringify({ ok: true });
      })()
    "#;

    let start = Instant::now();
    let handle = runtime.spawn(script).expect("提交任务失败");
    let submit_cost = start.elapsed();

    assert!(submit_cost < Duration::from_millis(20));

    let result = handle.wait().expect("任务执行失败");
    assert!(result.contains("ok"));
}

#[test]
fn async_runtime_stats_and_drop() {
    let runtime =
        AsyncHostRuntime::new("task-runtime-stats-drop").expect("创建 AsyncHostRuntime 失败");

    let handle = runtime
        .spawn("(async () => { await new Promise(() => {}); return \"ok\"; })()")
        .expect("提交任务失败");

    let stats = runtime.stats();
    assert!(stats.pending + stats.running >= 1);

    assert!(runtime.cancel(handle.id()));

    let dropped = handle.wait().expect_err("任务应被 dropped");
    assert!(dropped.contains("dropped"));
}

#[test]
fn async_runtime_runs_multiple_io_tasks_concurrently() {
    const TOTAL: usize = 20;
    const DELAY_MS: u64 = 40;

    let (addr, shutdown_tx, handle) = spawn_delay_server(DELAY_MS);
    let runtime =
        AsyncHostRuntime::new("task-runtime-concurrent-io").expect("创建 AsyncHostRuntime 失败");

    let script = format!(
        r#"
      (async () => {{
        const res = await fetch({url:?});
        const body = await res.json();
        return JSON.stringify(body);
      }})()
    "#,
        url = format!("{}/ping", addr),
    );

    let start = Instant::now();
    let mut handles = Vec::with_capacity(TOTAL);
    for _ in 0..TOTAL {
        handles.push(runtime.spawn(script.clone()).expect("提交任务失败"));
    }

    for task in handles {
        let result = task.wait().expect("任务执行失败");
        assert!(result.contains("ok"));
    }

    let elapsed = start.elapsed();

    let _ = shutdown_tx.send(());
    let _ = handle.join();

    assert!(
        elapsed < Duration::from_millis(550),
        "多任务并发耗时异常: {}ms",
        elapsed.as_millis()
    );
}

#[test]
fn async_runtime_supports_many_independent_rust_async_waiters() {
    const TOTAL: usize = 24;
    const DELAY_MS: u64 = 35;

    let (addr, shutdown_tx, handle) = spawn_delay_server(DELAY_MS);
    let runtime = Arc::new(
        AsyncHostRuntime::new("task-runtime-many-waiters").expect("创建 AsyncHostRuntime 失败"),
    );

    let script = format!(
        r#"
      (async () => {{
        const res = await fetch({url:?});
        const body = await res.json();
        return JSON.stringify(body);
      }})()
    "#,
        url = format!("{}/ping", addr),
    );

    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(4)
        .enable_all()
        .build()
        .expect("创建 tokio runtime 失败");

    let start = Instant::now();
    rt.block_on(async {
        let mut join_set = tokio::task::JoinSet::new();
        for _ in 0..TOTAL {
            let runtime = Arc::clone(&runtime);
            let script = script.clone();
            join_set.spawn(async move {
                let task = runtime.spawn(script).expect("提交任务失败");
                task.await
            });
        }

        let mut done = 0usize;
        while let Some(joined) = join_set.join_next().await {
            let result = joined.expect("异步等待任务 panic");
            assert!(result.is_ok(), "任务执行失败: {result:?}");
            done += 1;
        }
        assert_eq!(done, TOTAL);
    });

    let elapsed = start.elapsed();

    let _ = shutdown_tx.send(());
    let _ = handle.join();

    assert!(
        elapsed < Duration::from_millis(700),
        "独立 async 等待者并发耗时异常: {}ms",
        elapsed.as_millis()
    );
}

#[test]
fn async_runtime_wait_handle_avoids_polling() {
    const TOTAL: usize = 200;
    const DELAY_MS: u64 = 20;

    let (addr, shutdown_tx, handle) = spawn_delay_server(DELAY_MS);
    let runtime =
        AsyncHostRuntime::new("task-runtime-wait-handle").expect("创建 AsyncHostRuntime 失败");

    let script = format!(
        r#"
      (async () => {{
        const res = await fetch({url:?});
        const body = await res.json();
        return JSON.stringify(body);
      }})()
    "#,
        url = format!("{}/ping", addr),
    );

    let mut handles = Vec::with_capacity(TOTAL);
    for _ in 0..TOTAL {
        handles.push(runtime.spawn(script.clone()).expect("提交任务失败"));
    }

    let start = Instant::now();
    for task in handles {
        let result = task.wait().expect("任务执行失败");
        assert!(result.contains("ok"));
    }
    let elapsed = start.elapsed();

    let _ = shutdown_tx.send(());
    let _ = handle.join();

    assert!(
        elapsed < Duration::from_millis(1200),
        "wait handle 并发耗时异常: {}ms",
        elapsed.as_millis()
    );
}

#[derive(Debug, Deserialize)]
struct PingPayload {
    ok: bool,
}

#[test]
fn async_runtime_spawn_json_is_typed_and_awaitable() {
    let runtime = AsyncHostRuntime::new("task-runtime-json").expect("创建 AsyncHostRuntime 失败");
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .expect("创建 tokio runtime 失败");

    rt.block_on(async {
        let task = runtime
            .spawn_json::<PingPayload>(
                r#"
              (async () => {
                return JSON.stringify({ ok: true });
              })()
            "#,
            )
            .expect("提交任务失败");

        let payload = task.await.expect("解析 typed 结果失败");
        assert!(payload.ok);
    });
}

#[test]
fn async_runtime_handle_drop_cleans_pending_state() {
    let runtime =
        AsyncHostRuntime::new("task-runtime-handle-drop").expect("创建 AsyncHostRuntime 失败");
    let handle = runtime
        .spawn("(async () => { await new Promise(() => {}); return \"ok\"; })()")
        .expect("提交任务失败");

    drop(handle);
    thread::sleep(Duration::from_millis(10));

    let stats = runtime.stats();
    assert_eq!(
        stats.pending + stats.running + stats.done + stats.dropped,
        0
    );
}

#[test]
fn bundle_call_once_is_serialized_per_runtime() {
    let runtime = Arc::new(
        AsyncHostRuntime::new("task-runtime-bundle-call-once-serialized")
            .expect("创建 AsyncHostRuntime 失败"),
    );
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(2)
        .enable_all()
        .build()
        .expect("创建 tokio runtime 失败");

    let bundle_source = r#"
      module.exports = {
        async debugTask(name, delayMs) {
          await new Promise((resolve) => setTimeout(resolve, delayMs));
          return { ok: true, name, delayMs };
        }
      };
    "#;

    let elapsed = rt.block_on(async {
        let t0 = Instant::now();
        let rt1 = Arc::clone(&runtime);
        let rt2 = Arc::clone(&runtime);

        let task1 = tokio::spawn(async move {
            rt1.bundle_call_once(bundle_source, "debugTask", &json!(["a", 80]))
                .await
        });
        let task2 = tokio::spawn(async move {
            rt2.bundle_call_once(bundle_source, "debugTask", &json!(["b", 80]))
                .await
        });

        let out1 = task1
            .await
            .expect("task1 join 失败")
            .expect("task1 执行失败");
        let out2 = task2
            .await
            .expect("task2 join 失败")
            .expect("task2 执行失败");

        assert_eq!(out1["ok"], true);
        assert_eq!(out2["ok"], true);

        t0.elapsed()
    });

    assert!(
        elapsed >= Duration::from_millis(140),
        "bundle_call_once 未被串行化，耗时={}ms",
        elapsed.as_millis()
    );
}

#[test]
fn async_runtime_drop_unblocks_pending_waiter() {
    let runtime =
        AsyncHostRuntime::new("task-runtime-drop-unblock").expect("创建 AsyncHostRuntime 失败");
    let handle = runtime
        .spawn(
            r#"
          (async () => {
            await new Promise((resolve) => setTimeout(resolve, 5000));
            return "ok";
          })()
        "#,
        )
        .expect("提交任务失败");

    drop(runtime);

    let (tx, rx) = mpsc::channel();
    thread::spawn(move || {
        let _ = tx.send(handle.wait());
    });

    let result = rx
        .recv_timeout(Duration::from_millis(800))
        .expect("runtime 销毁后 wait 不应被无限阻塞");
    let err = result.expect_err("runtime 销毁后任务应返回错误");
    assert!(err.contains("runtime 已关闭"), "unexpected error: {err}");
}

fn spawn_delay_server(delay_ms: u64) -> (String, oneshot::Sender<()>, thread::JoinHandle<()>) {
    let (addr_tx, addr_rx) = mpsc::channel::<String>();
    let (shutdown_tx, shutdown_rx) = oneshot::channel::<()>();

    let handle = thread::spawn(move || {
        let rt = tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .enable_all()
            .build()
            .expect("创建 tokio runtime 失败");

        rt.block_on(async move {
            async fn ping(State(delay): State<u64>) -> Json<serde_json::Value> {
                tokio::time::sleep(Duration::from_millis(delay)).await;
                Json(json!({"ok": true}))
            }

            let app = Router::new().route("/ping", get(ping)).with_state(delay_ms);
            let listener = tokio::net::TcpListener::bind("127.0.0.1:0")
                .await
                .expect("绑定测试端口失败");
            let addr = format!("http://{}", listener.local_addr().expect("读取地址失败"));
            addr_tx.send(addr).expect("发送测试地址失败");

            let server = axum::serve(listener, app).with_graceful_shutdown(async {
                let _ = shutdown_rx.await;
            });

            let _ = server.await;
        });
    });

    let addr = addr_rx.recv().expect("接收测试地址失败");
    (addr, shutdown_tx, handle)
}

#[test]
#[ignore = "手动性能对比：Promise.all(1000) vs 多 spawn + wait(handle)"]
fn benchmark_promise_all_vs_wait_handle_1000_fetch() {
    const TOTAL: usize = 1000;
    for delay_ms in [5_u64, 20_u64, 50_u64] {
        run_benchmark_case(TOTAL, delay_ms);
    }
}

fn run_benchmark_case(total: usize, delay_ms: u64) {
    let (addr, shutdown_tx, handle) = spawn_delay_server(delay_ms);

    let host = AsyncHostRuntime::new("task-runtime-bench-promise-all")
        .expect("创建 AsyncHostRuntime 失败");
    let promise_all_script = format!(
        r#"
      (async () => {{
        const base = {base:?};
        const t0 = Date.now();
        const tasks = [];
        for (let i = 0; i < {total}; i += 1) {{
          tasks.push(fetch(`${{base}}/ping?i=${{i}}`).then((r) => r.json()));
        }}
        const out = await Promise.all(tasks);
        return JSON.stringify({{ ms: Date.now() - t0, count: out.length }});
      }})()
    "#,
        base = addr,
        total = total,
    );

    let t0 = Instant::now();
    let raw = host
        .spawn(promise_all_script)
        .expect("Promise.all 脚本提交失败")
        .wait()
        .expect("Promise.all 脚本失败");
    let promise_all_elapsed = t0.elapsed();
    let promise_payload: serde_json::Value =
        serde_json::from_str(&raw).expect("解析 Promise.all 结果失败");

    assert_eq!(promise_payload["count"].as_u64(), Some(total as u64));

    let async_rt = AsyncHostRuntime::new("task-runtime-bench-wait-handle")
        .expect("创建 AsyncHostRuntime 失败");
    let one_fetch_script = format!(
        r#"
      (async () => {{
        const res = await fetch({url:?});
        const obj = await res.json();
        return JSON.stringify(obj);
      }})()
    "#,
        url = format!("{}/ping", addr),
    );

    let t1 = Instant::now();
    let mut handles = Vec::with_capacity(total);
    for _ in 0..total {
        handles.push(
            async_rt
                .spawn(one_fetch_script.clone())
                .expect("提交单任务失败"),
        );
    }
    for task in handles {
        task.wait().expect("单任务失败");
    }
    let wait_handle_elapsed = t1.elapsed();

    let _ = shutdown_tx.send(());
    let _ = handle.join();

    let ratio = wait_handle_elapsed.as_secs_f64() / promise_all_elapsed.as_secs_f64();
    let order_hint = if ratio >= 10.0 {
        "达到一个数量级差异(>=10x)"
    } else {
        "未达到一个数量级差异(<10x)"
    };

    println!(
        "[bench delay={}ms] Promise.all({}) rust_elapsed_ms={} js_elapsed_ms={} | wait(handle,{}) rust_elapsed_ms={} | ratio={:.2}x ({})",
        delay_ms,
        total,
        promise_all_elapsed.as_millis(),
        promise_payload["ms"].as_u64().unwrap_or(0),
        total,
        wait_handle_elapsed.as_millis(),
        ratio,
        order_hint
    );
}
