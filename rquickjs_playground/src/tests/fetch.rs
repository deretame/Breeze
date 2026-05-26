use crate::tests::{run_async_script, spawn_test_server};
use crate::web_runtime::{configure_http_client, current_http_client_config};
use serde_json::Value;

#[test]
fn fetch_get_json() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const res = await fetch("{}/hello?from=test");
            const data = await res.json();
            return JSON.stringify({{
              status: res.status,
              method: data.method,
              path: data.path
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["status"], 200);
    assert_eq!(parsed["method"], "GET");
    assert_eq!(parsed["path"], "/hello?from=test");

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_post_json_body() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const res = await fetch("{}/echo", {{
              method: "POST",
              headers: {{ "x-from": "fetch-test" }},
              body: {{ name: "quickjs" }}
            }});
            const data = await res.json();
            return JSON.stringify({{
              method: data.method,
              body: data.body,
              header: data.headers["x-from"]
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["method"], "POST");
    assert_eq!(parsed["body"], "{\"name\":\"quickjs\"}");
    assert_eq!(parsed["header"], "fetch-test");

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_post_formdata_body() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const fd = new FormData();
            fd.append("name", "quickjs");
            fd.append("lang", "rust");
            const res = await fetch("{}/echo", {{
              method: "POST",
              body: fd
            }});
            const data = await res.json();
            return JSON.stringify({{
              method: data.method,
              body: data.body,
              contentType: data.headers["content-type"] || ""
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["method"], "POST");
    assert!(
        parsed["contentType"]
            .as_str()
            .unwrap_or("")
            .contains("multipart/form-data; boundary=")
    );
    assert!(
        parsed["body"]
            .as_str()
            .unwrap_or("")
            .contains("name=\"name\"")
    );
    assert!(parsed["body"].as_str().unwrap_or("").contains("quickjs"));
    assert!(
        parsed["body"]
            .as_str()
            .unwrap_or("")
            .contains("name=\"lang\"")
    );
    assert!(parsed["body"].as_str().unwrap_or("").contains("rust"));

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_post_formdata_file_fields() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const fd = new FormData();
            const file = new File(["hello-file"], "greeting.txt", {{ type: "text/plain" }});
            const blob = new Blob(["hello-blob"], {{ type: "application/custom" }});
            fd.append("upload", file);
            fd.append("raw", blob, "raw.bin");
            const res = await fetch("{}/echo", {{
              method: "POST",
              body: fd
            }});
            const data = await res.json();
            return JSON.stringify({{
              method: data.method,
              body: data.body,
              contentType: data.headers["content-type"] || ""
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["method"], "POST");
    assert!(
        parsed["contentType"]
            .as_str()
            .unwrap_or("")
            .contains("multipart/form-data; boundary=")
    );

    let body = parsed["body"].as_str().unwrap_or("");
    assert!(body.contains("name=\"upload\"; filename=\"greeting.txt\""));
    assert!(body.contains("name=\"raw\"; filename=\"raw.bin\""));
    assert!(body.contains("Content-Type: text/plain"));
    assert!(body.contains("Content-Type: application/custom"));
    assert!(body.contains("hello-file"));
    assert!(body.contains("hello-blob"));

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_post_urlsearchparams_body() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const params = new URLSearchParams();
            params.append("name", "quickjs");
            params.append("lang", "rust");
            const res = await fetch("{}/echo", {{
              method: "POST",
              body: params
            }});
            const data = await res.json();
            return JSON.stringify({{
              method: data.method,
              body: data.body,
              contentType: data.headers["content-type"] || ""
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["method"], "POST");
    assert_eq!(parsed["body"], "name=quickjs&lang=rust");
    assert_eq!(
        parsed["contentType"],
        "application/x-www-form-urlencoded;charset=UTF-8"
    );

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_headers() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const res = await fetch("{}/headers");
            const hasContentType = res.headers.has("content-type");
            const contentType = res.headers.get("content-type");
            return JSON.stringify({{
              status: res.status,
              hasContentType,
              contentType: contentType
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["status"], 200);
    assert_eq!(parsed["hasContentType"], true);
    assert!(
        parsed["contentType"]
            .as_str()
            .unwrap_or("")
            .contains("application/json")
    );

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_put_request() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const res = await fetch("{}/fetch-put", {{
              method: "PUT",
              body: JSON.stringify({{ name: "test" }})
            }});
            const data = await res.json();
            return JSON.stringify({{
              status: res.status,
              method: data.method,
              body: data.body
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["status"], 200);
    assert_eq!(parsed["method"], "PUT");
    assert_eq!(parsed["body"], "{\"name\":\"test\"}");

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_delete_request() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const res = await fetch("{}/fetch-delete/123", {{
              method: "DELETE"
            }});
            const data = await res.json();
            return JSON.stringify({{
              status: res.status,
              method: data.method,
              path: data.path
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["status"], 200);
    assert_eq!(parsed["method"], "DELETE");
    assert_eq!(parsed["path"], "/fetch-delete/123");

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_patch_request() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const res = await fetch("{}/fetch-patch", {{
              method: "PATCH",
              body: JSON.stringify({{ name: "updated" }})
            }});
            const data = await res.json();
            return JSON.stringify({{
              status: res.status,
              method: data.method,
              body: data.body
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["status"], 200);
    assert_eq!(parsed["method"], "PATCH");

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_text_response() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const res = await fetch("{}/text");
            const text = await res.text();
            return JSON.stringify({{
              status: res.status,
              isObject: text.includes("method")
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["status"], 200);
    assert_eq!(parsed["isObject"], true);

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_abort_controller() {
    let script = r#"
      (async () => {
        const controller = new AbortController();
        controller.abort("cancelled");
        try {
          await fetch("http://127.0.0.1:9/unreachable", { signal: controller.signal });
          return "unexpected";
        } catch (err) {
          return `${err.name}:${String(err.message || "")}`;
        }
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    assert!(result.starts_with("AbortError:"));
}

#[test]
fn fetch_abort_concurrent_requests_do_not_leave_pending_http_tasks() {
    let (base_url, tx, handle) = spawn_test_server(64);
    let script = format!(
        r#"
      (async () => {{
        const total = 20;
        const tasks = [];
        for (let i = 0; i < total; i += 1) {{
          const controller = new AbortController();
          const p = fetch("{}/slow?i=" + i, {{ signal: controller.signal }})
            .then(() => "resolved")
            .catch((err) => Error.isError(err) ? (err.name || String(err)) : String(err));
          tasks.push(p);
          setTimeout(() => controller.abort("cancel"), 0);
        }}
        const settled = await Promise.all(tasks);
        await new Promise((resolve) => setTimeout(resolve, 300));
        const stats = JSON.parse(__runtime_stats());
        const aborts = settled.filter((x) => x === "AbortError").length;
        return JSON.stringify({{
          total,
          aborts,
          httpPending: stats && stats.pending ? Number(stats.pending.http || 0) : -1,
          eventCanceled: stats && stats.httpEvented ? Number(stats.httpEvented.canceled || 0) : -1
        }});
      }})()
    "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["total"], 20);
    assert!(parsed["aborts"].as_i64().unwrap_or(0) >= 1);
    assert_eq!(parsed["httpPending"], 0);
    assert!(parsed["eventCanceled"].as_i64().unwrap_or(0) >= 1);

    let _ = tx.send(());
    let _ = handle.join();
}

// 说明：
// 这些用例会显式修改全局 HTTP client 配置（allow_private_network）。
// 在并发全量测试下可能与其它 fetch 用例竞争同一全局状态，导致偶发失败。
// 若出现抖动，优先单独执行本用例，或使用 --test-threads=1 串行执行 fetch 测试集。
#[test]
fn fetch_block_private_network_by_default() {
    let previous = current_http_client_config();
    let mut config = current_http_client_config();
    config.allow_private_network = false;
    configure_http_client(config).expect("更新 HTTP 配置失败");

    let runtime = crate::host_runtime::AsyncHostRuntime::new("test-web-runtime-private-block")
        .expect("创建 runtime 失败");
    configure_http_client(previous).expect("恢复 HTTP 配置失败");

    let task = runtime
        .spawn(
            r#"
          (async () => {
            try {
              await fetch("http://127.0.0.1:9/blocked");
              return "unexpected";
            } catch (err) {
              return String(err.message || err);
            }
          })()
        "#,
        )
        .expect("执行脚本失败");
    let result = task.wait().expect("等待脚本结果失败");
    assert!(result.contains("已拦截内网请求"));
}

// 说明：
// 这些用例会显式修改全局 HTTP client 配置（allow_private_network）。
// 在并发全量测试下可能与其它 fetch 用例竞争同一全局状态，导致偶发失败。
// 若出现抖动，优先单独执行本用例，或使用 --test-threads=1 串行执行 fetch 测试集。
#[test]
fn fetch_allow_private_network_when_config_enabled() {
    let previous = current_http_client_config();
    let mut config = current_http_client_config();
    config.allow_private_network = true;
    configure_http_client(config).expect("更新 HTTP 配置失败");

    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const res = await fetch("{}/hello?from=private-enabled");
            const data = await res.json();
            return JSON.stringify({{
              status: res.status,
              method: data.method,
              path: data.path
            }});
          }})()
        "#,
        base_url
    );

    let runtime = crate::host_runtime::AsyncHostRuntime::new("test-web-runtime-private-allowed")
        .expect("创建 runtime 失败");
    let task = runtime.spawn(&script).expect("执行脚本失败");
    let result = task.wait().expect("等待脚本结果失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["status"], 200);
    assert_eq!(parsed["method"], "GET");
    assert_eq!(parsed["path"], "/hello?from=private-enabled");
    assert!(!result.contains("已拦截内网请求"));

    configure_http_client(previous).expect("恢复 HTTP 配置失败");
    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_multiple_headers() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const res = await fetch("{}/multi-headers", {{
              headers: {{
                "X-Header-1": "value1",
                "X-Header-2": "value2",
                "X-Header-3": "value3"
              }}
            }});
            const data = await res.json();
            return JSON.stringify({{
              status: res.status,
              h1: data.headers["x-header-1"],
              h2: data.headers["x-header-2"],
              h3: data.headers["x-header-3"]
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["status"], 200);
    assert_eq!(parsed["h1"], "value1");
    assert_eq!(parsed["h2"], "value2");
    assert_eq!(parsed["h3"], "value3");

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_offload_binary_to_native_buffer() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const res = await fetch("{}/hello?img=1", {{
              headers: {{
                "x-rquickjs-host-offload-binary-v1": "true"
              }}
            }});

            const emptyText = res._bodyText || "";
            const bytes = await res.takeOffloadedBody();
            const decoded = new TextDecoder().decode(bytes);

            return JSON.stringify({{
              status: res.status,
              offloaded: res.offloaded === true,
              offloadedBytes: res.offloadedBytes,
              emptyText,
              hasPayload: decoded.includes("\"method\":\"GET\"")
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["status"], 200);
    assert_eq!(parsed["offloaded"], true);
    assert_eq!(parsed["emptyText"], "");
    assert!(parsed["offloadedBytes"].as_u64().unwrap_or(0) > 0);
    assert_eq!(parsed["hasPayload"], true);

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_offloaded_body_cannot_be_reconsumed_even_if_bodyused_is_tampered() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const res = await fetch("{}/hello?img=1", {{
              headers: {{
                "x-rquickjs-host-offload-binary-v1": "true"
              }}
            }});

            const first = await res.takeOffloadedBody();
            res.bodyUsed = false;

            let secondError = "";
            try {{
              await res.takeOffloadedBody();
            }} catch (err) {{
              secondError = Error.isError(err) ? err.message : String(err);
            }}

            return JSON.stringify({{
              firstLen: first.length,
              secondError
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert!(parsed["firstLen"].as_u64().unwrap_or(0) > 0);
    assert!(
        parsed["secondError"]
            .as_str()
            .unwrap_or("")
            .contains("Body 已被读取")
    );

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_offload_arraybuffer_works_without_custom_api() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const res = await fetch("{}/hello?img=arraybuffer", {{
              headers: {{
                "x-rquickjs-host-offload-binary-v1": "true"
              }}
            }});
            const ab = await res.arrayBuffer();
            const bytes = new Uint8Array(ab);
            const text = new TextDecoder().decode(bytes);
            return JSON.stringify({{
              status: res.status,
              offloaded: res.offloaded === true,
              len: bytes.length,
              hasPayload: text.includes("\"method\":\"GET\"")
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["status"], 200);
    assert_eq!(parsed["offloaded"], true);
    assert!(parsed["len"].as_u64().unwrap_or(0) > 0);
    assert_eq!(parsed["hasPayload"], true);

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_auto_offload_octet_stream_arraybuffer() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const res = await fetch("{}/axios-binary");
            const ab = await res.arrayBuffer();
            const bytes = new Uint8Array(ab);
            return JSON.stringify({{
              status: res.status,
              offloaded: res.offloaded === true,
              len: bytes.length,
              first: bytes[0],
              last: bytes[bytes.length - 1]
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["status"], 200);
    assert_eq!(parsed["offloaded"], true);
    assert_eq!(parsed["len"], 10);
    assert_eq!(parsed["first"], 0);
    assert_eq!(parsed["last"], 255);

    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn fetch_post_binary_body_via_native_buffer_channel() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const bytes = new Uint8Array(2048);
            for (let i = 0; i < bytes.length; i += 1) {{
              bytes[i] = 65 + (i % 26);
            }}
            const res = await fetch("{}/echo", {{
              method: "POST",
              headers: {{ "content-type": "application/octet-stream" }},
              body: bytes
            }});
            const data = await res.json();
            return JSON.stringify({{
              method: data.method,
              contentType: data.headers["content-type"] || "",
              bodyLen: (data.body || "").length
            }});
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["method"], "POST");
    assert_eq!(parsed["contentType"], "application/octet-stream");
    assert_eq!(parsed["bodyLen"], 2048);

    let _ = tx.send(());
    let _ = handle.join();
}
