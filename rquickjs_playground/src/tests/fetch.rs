use crate::tests::{run_async_script, spawn_test_server};
use serde_json::Value;
#[cfg(feature = "wasi")]
use wat::parse_str;

#[cfg(feature = "wasi")]
fn wasi_echo_stdin_module_bytes() -> Vec<u8> {
    parse_str(
        r#"
        (module
          (import "wasi_snapshot_preview1" "fd_read"
            (func $fd_read (param i32 i32 i32 i32) (result i32)))
          (import "wasi_snapshot_preview1" "fd_write"
            (func $fd_write (param i32 i32 i32 i32) (result i32)))

          (memory (export "memory") 1)

          (func (export "_start")
            i32.const 0
            i32.const 100
            i32.store
            i32.const 4
            i32.const 4096
            i32.store

            i32.const 0
            i32.const 0
            i32.const 1
            i32.const 8
            call $fd_read
            drop

            i32.const 16
            i32.const 100
            i32.store
            i32.const 20
            i32.const 8
            i32.load
            i32.store

            i32.const 1
            i32.const 16
            i32.const 1
            i32.const 24
            call $fd_write
            drop
          )
        )
        "#,
    )
    .expect("构建 wasi echo 模块失败")
}

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

#[cfg(feature = "wasi")]
#[test]
fn fetch_offload_with_wasi_transform_success() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let wasm = wasi_echo_stdin_module_bytes();
    let wasm_json = serde_json::to_string(&wasm).expect("序列化 wasm 失败");

    let script = format!(
        r#"
          (async () => {{
            const wasm = new Uint8Array({wasm_json});
            const moduleId = await native.put(wasm);
            const planJson = JSON.stringify({{
              moduleId,
              function: "echo",
              args: {{ mode: "passthrough" }},
              jsProcess: true,
              outputType: "binary"
            }});
            const planBytes = new TextEncoder().encode(planJson);
            let bin = "";
            for (let i = 0; i < planBytes.length; i += 1) bin += String.fromCharCode(planBytes[i]);
            const plan = btoa(bin);

            const res = await fetch("{}/hello?wasi=1", {{
              headers: {{
                "x-rquickjs-host-offload-binary-v1": "true",
                "x-rquickjs-host-wasi-transform-b64-v1": plan
              }}
            }});

            const bytes = await res.takeOffloadedBody();
            const decoded = new TextDecoder().decode(bytes);
            return JSON.stringify({{
              status: res.status,
              offloaded: res.offloaded,
              wasiApplied: res.wasiApplied,
              wasiNeedJsProcessing: res.wasiNeedJsProcessing,
              wasiFunction: res.wasiFunction,
              wasiOutputType: res.wasiOutputType,
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
    assert_eq!(parsed["wasiApplied"], true);
    assert_eq!(parsed["wasiNeedJsProcessing"], true);
    assert_eq!(parsed["wasiFunction"], "echo");
    assert_eq!(parsed["wasiOutputType"], "binary");
    assert_eq!(parsed["hasPayload"], true);

    let _ = tx.send(());
    let _ = handle.join();
}

#[cfg(feature = "wasi")]
#[test]
fn fetch_offload_with_wasi_transform_failure_fails_request() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let script = format!(
        r#"
          (async () => {{
            const planJson = JSON.stringify({{
              moduleId: 999999,
              function: "echo",
              args: {{ mode: "passthrough" }},
              jsProcess: false,
              outputType: "binary"
            }});
            const planBytes = new TextEncoder().encode(planJson);
            let bin = "";
            for (let i = 0; i < planBytes.length; i += 1) bin += String.fromCharCode(planBytes[i]);
            const plan = btoa(bin);

            try {{
              await fetch("{}/hello?wasi=fail", {{
                headers: {{
                  "x-rquickjs-host-offload-binary-v1": "true",
                  "x-rquickjs-host-wasi-transform-b64-v1": plan
                }}
              }});
              return JSON.stringify({{ ok: false }});
            }} catch (err) {{
              return JSON.stringify({{ ok: true, name: err.name }});
            }}
          }})()
        "#,
        base_url
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["ok"], true);
    assert_eq!(parsed["name"], "TypeError");

    let _ = tx.send(());
    let _ = handle.join();
}
