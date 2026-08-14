use crate::AsyncHostRuntime;
use crate::web_runtime::{configure_http_client, current_http_client_config};
use axum::{Json, Router, extract::State, routing::get};
use serde::Deserialize;
use serde_json::json;
use std::sync::Arc;
use std::sync::mpsc;
use std::thread;
use std::time::{Duration, Instant};
use tokio::sync::oneshot;

struct HttpPrivateNetworkGuard {
    previous: crate::web_runtime::HttpClientConfig,
}

impl HttpPrivateNetworkGuard {
    fn allow() -> Self {
        let previous = current_http_client_config();
        let mut config = previous.clone();
        config.allow_private_network = true;
        configure_http_client(config).expect(&crate::tr!("failed-to-update-http-config"));
        Self { previous }
    }
}

impl Drop for HttpPrivateNetworkGuard {
    fn drop(&mut self) {
        configure_http_client(self.previous.clone())
            .expect(&crate::tr!("failed-to-restore-http-config"));
    }
}

#[test]
fn async_runtime_spawn_is_non_blocking() {
    let runtime = AsyncHostRuntime::new("task-runtime-non-blocking")
        .expect(&crate::tr!("failed-to-create-asynchostruntime"));

    let script = r#"
      (async () => {
        await new Promise((resolve) => setTimeout(resolve, 40));
        return JSON.stringify({ ok: true });
      })()
    "#;

    let start = Instant::now();
    let handle = runtime
        .spawn(script)
        .expect(&crate::tr!("failed-to-submit-task"));
    let submit_cost = start.elapsed();

    assert!(submit_cost < Duration::from_millis(20));

    let result = handle.wait().expect(&crate::tr!("task-execution-failed"));
    assert!(result.contains("ok"));
}

#[test]
fn async_runtime_stats_and_drop() {
    let runtime = AsyncHostRuntime::new("task-runtime-stats-drop")
        .expect(&crate::tr!("failed-to-create-asynchostruntime"));

    let handle = runtime
        .spawn("(async () => { await new Promise(() => {}); return \"ok\"; })()")
        .expect(&crate::tr!("failed-to-submit-task"));

    let stats = runtime.stats();
    assert!(stats.pending + stats.running >= 1);

    assert!(runtime.cancel(handle.id()));

    let dropped = handle
        .wait()
        .expect_err(&crate::tr!("task-should-be-dropped"));
    assert!(dropped.contains("dropped"));
}

#[test]
fn async_runtime_runs_multiple_io_tasks_concurrently() {
    const TOTAL: usize = 20;
    const DELAY_MS: u64 = 40;

    let _http_guard = HttpPrivateNetworkGuard::allow();
    let (addr, shutdown_tx, handle) = spawn_delay_server(DELAY_MS);
    let runtime = AsyncHostRuntime::new("task-runtime-concurrent-io")
        .expect(&crate::tr!("failed-to-create-asynchostruntime"));

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
        handles.push(
            runtime
                .spawn(script.clone())
                .expect(&crate::tr!("failed-to-submit-task")),
        );
    }

    for task in handles {
        let result = task.wait().expect(&crate::tr!("task-execution-failed"));
        assert!(result.contains("ok"));
    }

    let elapsed = start.elapsed();

    let _ = shutdown_tx.send(());
    let _ = handle.join();

    assert!(
        elapsed < Duration::from_millis(10000),
        "{}",
        crate::tr!(
            "abnormal-multi-task-concurrent-elapsed-time-ms",
            arg0 = elapsed.as_millis()
        )
    );
}

#[test]
fn async_runtime_supports_many_independent_rust_async_waiters() {
    const TOTAL: usize = 24;
    const DELAY_MS: u64 = 35;

    let _http_guard = HttpPrivateNetworkGuard::allow();
    let (addr, shutdown_tx, handle) = spawn_delay_server(DELAY_MS);
    let runtime = Arc::new(
        AsyncHostRuntime::new("task-runtime-many-waiters")
            .expect(&crate::tr!("failed-to-create-asynchostruntime")),
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
        .expect(&crate::tr!("failed-to-create-tokio-runtime"));

    let start = Instant::now();
    rt.block_on(async {
        let mut join_set = tokio::task::JoinSet::new();
        for _ in 0..TOTAL {
            let runtime = Arc::clone(&runtime);
            let script = script.clone();
            join_set.spawn(async move {
                let task = runtime
                    .spawn(script)
                    .expect(&crate::tr!("failed-to-submit-task"));
                task.await
            });
        }

        let mut done = 0usize;
        while let Some(joined) = join_set.join_next().await {
            let result = joined.expect(&crate::tr!("async-wait-for-task-panicked"));
            assert!(
                result.is_ok(),
                "{}",
                crate::tr!("task-execution-failed-2", result = format!("{:?}", result))
            );
            done += 1;
        }
        assert_eq!(done, TOTAL);
    });

    let elapsed = start.elapsed();

    let _ = shutdown_tx.send(());
    let _ = handle.join();

    assert!(
        elapsed < Duration::from_millis(10000),
        "{}",
        crate::tr!(
            "abnormal-independent-async-waiter-concurrent",
            arg0 = elapsed.as_millis()
        )
    );
}

#[test]
fn async_runtime_wait_handle_avoids_polling() {
    const TOTAL: usize = 200;
    const DELAY_MS: u64 = 20;

    let _http_guard = HttpPrivateNetworkGuard::allow();
    let (addr, shutdown_tx, handle) = spawn_delay_server(DELAY_MS);
    let runtime = AsyncHostRuntime::new("task-runtime-wait-handle")
        .expect(&crate::tr!("failed-to-create-asynchostruntime"));

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
        handles.push(
            runtime
                .spawn(script.clone())
                .expect(&crate::tr!("failed-to-submit-task")),
        );
    }

    let start = Instant::now();
    for task in handles {
        let result = task.wait().expect(&crate::tr!("task-execution-failed"));
        assert!(result.contains("ok"));
    }
    let elapsed = start.elapsed();

    let _ = shutdown_tx.send(());
    let _ = handle.join();

    assert!(
        elapsed < Duration::from_millis(10000),
        "{}",
        crate::tr!(
            "abnormal-wait-handle-concurrent-elapsed-time-ms",
            arg0 = elapsed.as_millis()
        )
    );
}

#[derive(Debug, Deserialize)]
struct PingPayload {
    ok: bool,
}

#[test]
fn async_runtime_spawn_json_is_typed_and_awaitable() {
    let runtime = AsyncHostRuntime::new("task-runtime-json")
        .expect(&crate::tr!("failed-to-create-asynchostruntime"));
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .expect(&crate::tr!("failed-to-create-tokio-runtime"));

    rt.block_on(async {
        let task = runtime
            .spawn_json::<PingPayload>(
                r#"
              (async () => {
                return JSON.stringify({ ok: true });
              })()
            "#,
            )
            .expect(&crate::tr!("failed-to-submit-task"));

        let payload = task
            .await
            .expect(&crate::tr!("failed-to-parse-typed-result"));
        assert!(payload.ok);
    });
}

#[test]
fn async_runtime_handle_drop_cleans_pending_state() {
    let runtime = AsyncHostRuntime::new("task-runtime-handle-drop")
        .expect(&crate::tr!("failed-to-create-asynchostruntime"));
    let handle = runtime
        .spawn("(async () => { await new Promise(() => {}); return \"ok\"; })()")
        .expect(&crate::tr!("failed-to-submit-task"));

    drop(handle);
    thread::sleep(Duration::from_millis(10));

    let stats = runtime.stats();
    assert_eq!(
        stats.pending + stats.running + stats.done + stats.dropped,
        0
    );
}

#[test]
fn bundle_call_once_can_overlap_within_runtime() {
    let runtime = Arc::new(
        AsyncHostRuntime::new("task-runtime-bundle-call-once-overlap")
            .expect(&crate::tr!("failed-to-create-asynchostruntime")),
    );
    let rt = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(2)
        .enable_all()
        .build()
        .expect(&crate::tr!("failed-to-create-tokio-runtime"));

    let bundle_source = r#"
      module.exports = {
        async debugTask(name, delayMs) {
          await new Promise((resolve) => setTimeout(resolve, delayMs));
          return { ok: true, name, delayMs };
        }
      };
    "#;

    rt.block_on(async {
        let rt1 = Arc::clone(&runtime);
        let rt2 = Arc::clone(&runtime);
        let warm1 = tokio::spawn(async move {
            rt1.bundle_call_once(bundle_source, "debugTask", &json!(["warmup-a", 1]))
                .await
        });
        let warm2 = tokio::spawn(async move {
            rt2.bundle_call_once(bundle_source, "debugTask", &json!(["warmup-b", 1]))
                .await
        });
        warm1
            .await
            .expect(&crate::tr!("warmup-task1-join-failed"))
            .expect(&crate::tr!("warmup-task1-execution-failed"));
        warm2
            .await
            .expect(&crate::tr!("warmup-task2-join-failed"))
            .expect(&crate::tr!("warmup-task2-execution-failed"));
    });

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
            .expect(&crate::tr!("task1-join-failed"))
            .expect(&crate::tr!("task1-execution-failed"));
        let out2 = task2
            .await
            .expect(&crate::tr!("task2-join-failed"))
            .expect(&crate::tr!("task2-execution-failed"));

        assert_eq!(out1["ok"], true);
        assert_eq!(out2["ok"], true);

        t0.elapsed()
    });

    assert!(
        elapsed < Duration::from_millis(140),
        "{}",
        crate::tr!(
            "bundle_call_once-is-still-serialized-elapsed-ms",
            arg0 = elapsed.as_millis()
        )
    );
}

#[test]
fn bundle_call_once_error_contains_context_and_source_url() {
    let runtime = AsyncHostRuntime::new("task-runtime-bundle-call-once-error-context")
        .expect(&crate::tr!("failed-to-create-asynchostruntime"));
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .expect(&crate::tr!("failed-to-create-tokio-runtime"));

    let bundle_source = r#"
      module.exports = {
        boom() {
          throw new Error("boom");
        },
      };
    "#;

    let err = rt
        .block_on(async {
            runtime
                .bundle_call_once(bundle_source, "boom", &json!([]))
                .await
        })
        .expect_err(&crate::tr!("call-should-have-failed"));

    assert!(
        err.contains("[bundle:__once__ fn:boom args:[] source:__bundle_once__.cjs]"),
        "{}",
        crate::tr!("missing-call-context", err = err)
    );
    assert!(
        err.contains("source:__bundle_once__.cjs"),
        "{}",
        crate::tr!("missing-logic-source-name", err = err)
    );
}

#[test]
fn bundle_call_once_error_shows_export_shape() {
    let runtime = AsyncHostRuntime::new("task-runtime-bundle-call-once-export-shape")
        .expect(&crate::tr!("failed-to-create-asynchostruntime"));
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .expect(&crate::tr!("failed-to-create-tokio-runtime"));

    let bundle_source = r#"
      module.exports = {
        searchComic: "oops",
        okFn() { return 1; },
      };
    "#;

    let err = rt
        .block_on(async {
            runtime
                .bundle_call_once(bundle_source, "searchComic", &json!([{}]))
                .await
        })
        .expect_err(&crate::tr!("call-should-have-failed"));

    assert!(
        err.contains("targetType=string"),
        "{}",
        crate::tr!("missing-targettype", err = err)
    );
    assert!(
        err.contains("ownerKeys="),
        "{}",
        crate::tr!("missing-ownerkeys", err = err)
    );
    assert!(
        err.contains("rootKeys="),
        "{}",
        crate::tr!("missing-rootkeys", err = err)
    );
}

#[test]
fn async_runtime_drop_unblocks_pending_waiter() {
    let runtime = AsyncHostRuntime::new("task-runtime-drop-unblock")
        .expect(&crate::tr!("failed-to-create-asynchostruntime"));
    let handle = runtime
        .spawn(
            r#"
          (async () => {
            await new Promise((resolve) => setTimeout(resolve, 5000));
            return "ok";
          })()
        "#,
        )
        .expect(&crate::tr!("failed-to-submit-task"));

    drop(runtime);

    let (tx, rx) = mpsc::channel();
    thread::spawn(move || {
        let _ = tx.send(handle.wait());
    });

    let result = rx
        .recv_timeout(Duration::from_millis(800))
        .expect(&crate::tr!("wait-should-not-be-blocked-indefinitely-after"));
    let err = result.expect_err(&crate::tr!("tasks-should-return-an-error-after-runtime-is"));
    assert!(
        err.contains(&crate::tr!("runtime-is-closed")),
        "unexpected error: {err}"
    );
}

fn spawn_delay_server(delay_ms: u64) -> (String, oneshot::Sender<()>, thread::JoinHandle<()>) {
    let (addr_tx, addr_rx) = mpsc::channel::<String>();
    let (shutdown_tx, shutdown_rx) = oneshot::channel::<()>();

    let handle = thread::spawn(move || {
        let rt = tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .enable_all()
            .build()
            .expect(&crate::tr!("failed-to-create-tokio-runtime"));

        rt.block_on(async move {
            async fn ping(State(delay): State<u64>) -> Json<serde_json::Value> {
                tokio::time::sleep(Duration::from_millis(delay)).await;
                Json(json!({"ok": true}))
            }

            let app = Router::new().route("/ping", get(ping)).with_state(delay_ms);
            let listener = tokio::net::TcpListener::bind("127.0.0.1:0")
                .await
                .expect(&crate::tr!("failed-to-bind-test-port"));
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
fn sourcemap_inline_resolves_real_bundle_error() {
    use crate::host_runtime::AsyncHostRuntime;

    let bundle_src = include_str!("../../tests/fixtures/breeze-plugin-example.bundle.cjs");
    let runtime = AsyncHostRuntime::new("sourcemap-inline").expect("create runtime");
    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .unwrap();

    rt.block_on(async { runtime.bundle_load("test-bundle", &bundle_src).await })
        .expect("load bundle");

    let err = rt
        .block_on(async {
            runtime
                .bundle_call("test-bundle", "getComicDetail", &serde_json::json!([]))
                .await
        })
        .expect_err("should fail");

    println!("=== SOURCE MAPPED ERROR ===");
    println!("{err}");

    assert!(
        err.contains("webpack://breeze-plugin-example/./src/index.ts:143:12"),
        "{}",
        crate::tr!("sourcemap-should-resolve-to-src-index-ts-143-12", err = err)
    );
}
