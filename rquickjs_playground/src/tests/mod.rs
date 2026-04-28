pub mod compat;
pub mod fetch;
pub mod fs;
pub mod native;
pub mod runtime;
pub mod task_runtime;

pub use crate::web_runtime::{
    run_async_script, run_async_script_with_fs, run_async_script_with_wasi,
    run_async_script_with_wasi_and_fs, run_async_script_without_wasi,
};
use serde_json::{Map, Value, json};
use std::path::PathBuf;
use std::process::Command;
use std::sync::OnceLock;
use std::sync::mpsc;
use std::thread;
use std::time::Duration;
use tiny_http::{Method as TinyMethod, Response, Server};

static PNPM_CASES_BUILD: OnceLock<Result<(), String>> = OnceLock::new();

pub fn ensure_pnpm_cases_built() {
    let result = PNPM_CASES_BUILD.get_or_init(|| {
        let mut demo_dir = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        demo_dir.push("pnpm_demo");

        let output = if cfg!(windows) {
            Command::new("cmd")
                .args(["/C", "pnpm run test:cases:node"])
                .current_dir(&demo_dir)
                .output()
                .map_err(|e| format!("执行 pnpm test:cases:node 失败: {e}"))?
        } else {
            Command::new("pnpm")
                .args(["run", "test:cases:node"])
                .current_dir(&demo_dir)
                .output()
                .map_err(|e| format!("执行 pnpm test:cases:node 失败: {e}"))?
        };

        if output.status.success() {
            Ok(())
        } else {
            let stdout = String::from_utf8_lossy(&output.stdout);
            let stderr = String::from_utf8_lossy(&output.stderr);
            Err(format!(
                "pnpm test:cases:node 失败\nstdout:\n{stdout}\nstderr:\n{stderr}"
            ))
        }
    });

    if let Err(err) = result {
        panic!("{err}");
    }
}

pub fn spawn_test_server(limit: usize) -> (String, mpsc::Sender<()>, thread::JoinHandle<()>) {
    spawn_test_server_with_headers(limit, None)
}

pub fn spawn_test_server_with_headers(
    limit: usize,
    extra_headers: Option<Vec<(&'static str, &'static str)>>,
) -> (String, mpsc::Sender<()>, thread::JoinHandle<()>) {
    let server = Server::http("127.0.0.1:0").expect("启动测试服务失败");
    let addr = format!("http://{}", server.server_addr());
    let (tx, rx) = mpsc::channel::<()>();

    let handle = thread::spawn(move || {
        for _ in 0..limit {
            if rx.try_recv().is_ok() {
                break;
            }
            match server.recv_timeout(Duration::from_millis(100)) {
                Ok(Some(mut request)) => {
                    if request.url() == "/axios-binary" {
                        let resp =
                            Response::from_data(vec![0, 1, 2, 3, 250, 251, 252, 253, 254, 255])
                                .with_status_code(200)
                                .with_header(
                                    tiny_http::Header::from_bytes(
                                        b"Content-Type".as_slice(),
                                        b"application/octet-stream".as_slice(),
                                    )
                                    .expect("构造二进制响应头失败"),
                                );
                        let _ = request.respond(resp);
                        continue;
                    }

                    let method = match request.method() {
                        TinyMethod::Get => "GET",
                        TinyMethod::Post => "POST",
                        TinyMethod::Put => "PUT",
                        TinyMethod::Delete => "DELETE",
                        TinyMethod::Patch => "PATCH",
                        TinyMethod::Head => "HEAD",
                        TinyMethod::Options => "OPTIONS",
                        _ => "OTHER",
                    };

                    let mut body = String::new();
                    let _ = request.as_reader().read_to_string(&mut body);

                    let mut headers = Map::new();
                    for header in request.headers() {
                        headers.insert(
                            header.field.as_str().to_string().to_lowercase(),
                            Value::String(header.value.as_str().to_string()),
                        );
                    }

                    let payload = json!({
                        "method": method,
                        "path": request.url(),
                        "body": body,
                        "headers": headers,
                    });

                    let mut resp_builder =
                        Response::from_string(payload.to_string()).with_status_code(200);

                    resp_builder = resp_builder
                        .with_header(
                            tiny_http::Header::from_bytes(
                                b"Content-Type".as_slice(),
                                b"application/json".as_slice(),
                            )
                            .expect("构造响应头失败"),
                        )
                        .with_header(
                            tiny_http::Header::from_bytes(
                                b"X-Custom".as_slice(),
                                b"custom-value".as_slice(),
                            )
                            .expect("构造自定义响应头失败"),
                        );

                    if let Some(ref extra) = extra_headers {
                        for (key, value) in extra {
                            resp_builder = resp_builder.with_header(
                                tiny_http::Header::from_bytes(key.as_bytes(), value.as_bytes())
                                    .expect("构造额外响应头失败"),
                            );
                        }
                    }

                    let resp = resp_builder;
                    let _ = request.respond(resp);
                }
                Ok(None) => {}
                Err(_) => {}
            }
        }
    });

    (addr, tx, handle)
}
