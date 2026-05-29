use crate::tests::run_async_script;
use crate::{
    BridgeRuntimeConfig, configure_bridge_runtime, register_bridge_route_async_handler,
    register_bridge_route_blocking_handler, register_bridge_route_sync_handler,
    unregister_bridge_route_handler,
};
use serde_json::{Value, json};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;
static BRIDGE_ROUTE_SEQ: AtomicU64 = AtomicU64::new(1);

#[test]
fn native_run_invert_min_copy_api() {
    let script = r#"
      (async () => {
        const out = await native.run("invert", new Uint8Array([0, 10, 255]));
        return JSON.stringify({
          supportsBinaryBridge: native.supportsBinaryBridge,
          len: out.length,
          v0: out[0],
          v1: out[1],
          v2: out[2]
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["supportsBinaryBridge"], true);
    assert_eq!(parsed["len"], 3);
    assert_eq!(parsed["v0"], 255);
    assert_eq!(parsed["v1"], 245);
    assert_eq!(parsed["v2"], 0);
}

#[test]
fn native_gzip_decompress_api() {
    let script = r#"
      (async () => {
        const gz = new Uint8Array([
          31,139,8,0,0,0,0,0,2,255,203,72,205,201,201,87,
          72,175,202,44,0,0,25,106,210,223,10,0,0,0
        ]);
        const out = await native.gzipDecompress(gz);
        const text = new TextDecoder().decode(out);
        return JSON.stringify({ text, len: out.length });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["text"], "hello gzip");
    assert_eq!(parsed["len"], 10);
}

#[test]
fn native_gzip_compress_and_decompress_api() {
    let script = r#"
      (async () => {
        const input = new TextEncoder().encode("hello gzip");
        const gz = await native.gzipCompress(input);
        const out = await native.gzipDecompress(gz);
        const text = new TextDecoder().decode(out);
        return JSON.stringify({
          text,
          gzipMagic: gz.length >= 2 && gz[0] === 31 && gz[1] === 139
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["text"], "hello gzip");
    assert_eq!(parsed["gzipMagic"], true);
}

#[test]
fn native_handle_chain_grayscale() {
    let script = r#"
      (async () => {
        const rgba = new Uint8Array([
          255, 0, 0, 255,
          0, 255, 0, 255
        ]);
        const id = await native.put(rgba);
        const grayId = await native.exec("grayscale_rgba", id);
        const out = await native.take(grayId);
        await native.free(grayId);
        return JSON.stringify({
          len: out.length,
          a0: out[0],
          a1: out[1],
          a2: out[2],
          alpha0: out[3],
          b0: out[4],
          b1: out[5],
          b2: out[6],
          alpha1: out[7]
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["len"], 8);
    assert_eq!(parsed["a0"], parsed["a1"]);
    assert_eq!(parsed["a1"], parsed["a2"]);
    assert_eq!(parsed["b0"], parsed["b1"]);
    assert_eq!(parsed["b1"], parsed["b2"]);
    assert_eq!(parsed["alpha0"], 255);
    assert_eq!(parsed["alpha1"], 255);
}

#[test]
fn native_exec_with_extra_input() {
    let script = r#"
      (async () => {
        const left = await native.put(new Uint8Array([1, 2, 3]));
        const right = await native.put(new Uint8Array([3, 2, 1]));
        const outId = await native.exec("xor", left, null, right);
        const out = await native.take(outId);
        await native.free(outId);
        return JSON.stringify({
          v0: out[0],
          v1: out[1],
          v2: out[2]
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["v0"], 2);
    assert_eq!(parsed["v1"], 0);
    assert_eq!(parsed["v2"], 2);
}

#[test]
fn native_take_into_and_chain() {
    let script = r#"
      (async () => {
        const inputId = await native.put(new Uint8Array([1, 2, 3, 4]));
        const outId = await native.execChain(inputId, [
          { op: "invert" },
          { op: "invert" },
          { op: "noop" }
        ]);

        const target = new Uint8Array(8);
        const info = await native.takeInto(outId, target, 2);

        const chained = await native.chain(["invert", "invert"], new Uint8Array([9, 8]));

        return JSON.stringify({
          bytesWritten: info.bytesWritten,
          truncated: info.truncated,
          target: Array.from(target),
          chained: Array.from(chained)
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["bytesWritten"], 4);
    assert_eq!(parsed["truncated"], false);
    assert_eq!(parsed["target"][0], 0);
    assert_eq!(parsed["target"][1], 0);
    assert_eq!(parsed["target"][2], 1);
    assert_eq!(parsed["target"][3], 2);
    assert_eq!(parsed["target"][4], 3);
    assert_eq!(parsed["target"][5], 4);
    assert_eq!(parsed["chained"][0], 9);
    assert_eq!(parsed["chained"][1], 8);
}

#[test]
fn native_take_into_truncated_and_source_length() {
    let script = r#"
      (async () => {
        const id = await native.put(new Uint8Array([10, 11, 12, 13, 14]));
        const target = new Uint8Array(3);
        const info = await native.takeInto(id, target, 1);
        return JSON.stringify({
          bytesWritten: info.bytesWritten,
          sourceLength: info.sourceLength,
          truncated: info.truncated,
          target: Array.from(target)
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["bytesWritten"], 2);
    assert_eq!(parsed["sourceLength"], 5);
    assert_eq!(parsed["truncated"], true);
    assert_eq!(parsed["target"][0], 0);
    assert_eq!(parsed["target"][1], 10);
    assert_eq!(parsed["target"][2], 11);
}

#[test]
fn native_exec_chain_with_extra_input() {
    let script = r#"
      (async () => {
        const left = await native.put(new Uint8Array([1, 2, 3]));
        const right = await native.put(new Uint8Array([3, 2, 1]));
        const outId = await native.execChain(left, [
          { op: "xor", extraInputId: right },
          { op: "invert" }
        ]);
        const out = await native.take(outId);
        return JSON.stringify({ out: Array.from(out) });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["out"][0], 253);
    assert_eq!(parsed["out"][1], 255);
    assert_eq!(parsed["out"][2], 253);
}

#[test]
fn native_exec_chain_invalid_steps_errors() {
    let script = r#"
      (async () => {
        const inputId = await native.put(new Uint8Array([1, 2, 3]));

        let emptyErr = "";
        try {
          await native.execChain(inputId, []);
        } catch (err) {
          emptyErr = String(err.message || err);
        }

        const inputId2 = await native.put(new Uint8Array([4, 5, 6]));
        let badErr = "";
        try {
          await native.execChain(inputId2, [{}]);
        } catch (err) {
          badErr = String(err.message || err);
        }

        return JSON.stringify({
          emptyHasHint: emptyErr.includes("非空数组") || emptyErr.includes("不能为空"),
          badHasHint: badErr.includes("op")
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["emptyHasHint"], true);
    assert_eq!(parsed["badHasHint"], true);
}

#[test]
fn bridge_call_by_function_name_with_args() {
    let script = r#"
      (async () => {
        const inputId = await bridge.call("native.put", [1, 2, 3]);
        const outId = await bridge.call("native.exec", "invert", inputId, null, null);
        const out = await bridge.call("native.take", outId);
        const sum = await bridge.call("math.add", 1.5, 2);

        return JSON.stringify({
          out: Array.from(out),
          sum
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["out"][0], 254);
    assert_eq!(parsed["out"][1], 253);
    assert_eq!(parsed["out"][2], 252);
    assert_eq!(parsed["sum"], 3.5);
}

#[test]
fn bridge_call_accepts_typed_array_as_binary_arg() {
    let script = r#"
      (async () => {
        const inputId = await bridge.call("native.put", new Uint8Array([1, 2, 3]));
        const outId = await bridge.call("native.exec", "invert", inputId, null, null);
        const out = await bridge.call("native.take", outId);
        return JSON.stringify({ out: Array.from(out) });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["out"][0], 254);
    assert_eq!(parsed["out"][1], 253);
    assert_eq!(parsed["out"][2], 252);
}

#[test]
fn bridge_call_with_external_route_handler() {
    let route = format!(
        "test.custom.bridge.{}",
        BRIDGE_ROUTE_SEQ.fetch_add(1, Ordering::Relaxed)
    );

    register_bridge_route_async_handler(route.clone(), |runtime_name, args| async move {
        let first = args.first().cloned().unwrap_or(Value::Null);
        Ok(json!({
            "runtime": runtime_name,
            "first": first,
            "argc": args.len()
        }))
    })
    .expect("注册 bridge 自定义路由失败");

    let route_json = serde_json::to_string(&route).expect("序列化路由名失败");
    let script = format!(
        r#"
      (async () => {{
        const out = await bridge.call({route_json}, 42, "x");
        return JSON.stringify(out);
      }})()
    "#
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["first"], 42);
    assert_eq!(parsed["argc"], 2);
    assert!(parsed["runtime"].as_str().is_some());

    let removed = unregister_bridge_route_handler(&route).expect("卸载 bridge 自定义路由失败");
    assert!(removed);
}

#[test]
fn bridge_call_with_external_sync_route_handler() {
    let route = format!(
        "test.custom.bridge.sync.{}",
        BRIDGE_ROUTE_SEQ.fetch_add(1, Ordering::Relaxed)
    );

    register_bridge_route_sync_handler(route.clone(), |runtime_name, args| {
        let first = args.first().cloned().unwrap_or(Value::Null);
        Ok(json!({
            "runtime": runtime_name,
            "first": first,
            "argc": args.len(),
            "mode": "sync"
        }))
    })
    .expect("注册 bridge 同步自定义路由失败");

    let route_json = serde_json::to_string(&route).expect("序列化路由名失败");
    let script = format!(
        r#"
      (async () => {{
        const out = await bridge.call({route_json}, 100, "ok");
        return JSON.stringify(out);
      }})()
    "#
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["first"], 100);
    assert_eq!(parsed["argc"], 2);
    assert_eq!(parsed["mode"], "sync");
    assert!(parsed["runtime"].as_str().is_some());

    let removed = unregister_bridge_route_handler(&route).expect("卸载 bridge 同步自定义路由失败");
    assert!(removed);
}

#[test]
fn bridge_call_sync_route_should_not_create_bridge_pending() {
    let route = format!(
        "test.custom.bridge.sync.pending.{}",
        BRIDGE_ROUTE_SEQ.fetch_add(1, Ordering::Relaxed)
    );

    register_bridge_route_sync_handler(route.clone(), |_runtime_name, args| {
        let first = args.first().cloned().unwrap_or(Value::Null);
        Ok(json!({
            "first": first,
            "argc": args.len(),
            "mode": "sync"
        }))
    })
    .expect("注册 bridge 同步自定义路由失败");

    let route_json = serde_json::to_string(&route).expect("序列化路由名失败");
    let script = format!(
        r#"
      (async () => {{
        const before = JSON.parse(__runtime_stats()).pending.bridge;
        const out = await bridge.call({route_json}, "cache-like", 1);
        const after = JSON.parse(__runtime_stats()).pending.bridge;
        return JSON.stringify({{ before, after, out }});
      }})()
    "#
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(
        parsed["before"], parsed["after"],
        "sync route should not create bridge pending"
    );
    assert_eq!(parsed["out"]["first"], "cache-like");
    assert_eq!(parsed["out"]["argc"], 2);
    assert_eq!(parsed["out"]["mode"], "sync");

    let removed = unregister_bridge_route_handler(&route).expect("卸载 bridge 同步自定义路由失败");
    assert!(removed);
}

#[test]
fn bridge_call_with_external_async_route_handler() {
    let route = format!(
        "test.custom.bridge.async.{}",
        BRIDGE_ROUTE_SEQ.fetch_add(1, Ordering::Relaxed)
    );

    register_bridge_route_async_handler(route.clone(), |runtime_name, args| async move {
        tokio::time::sleep(Duration::from_millis(15)).await;
        let first = args.first().cloned().unwrap_or(Value::Null);
        Ok(json!({
            "runtime": runtime_name,
            "first": first,
            "argc": args.len(),
            "async": true
        }))
    })
    .expect("注册 bridge 异步自定义路由失败");

    let route_json = serde_json::to_string(&route).expect("序列化路由名失败");
    let script = format!(
        r#"
      (async () => {{
        const out = await bridge.call({route_json}, "hello", 7);
        return JSON.stringify(out);
      }})()
    "#
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["first"], "hello");
    assert_eq!(parsed["argc"], 2);
    assert_eq!(parsed["async"], true);
    assert!(parsed["runtime"].as_str().is_some());

    let removed = unregister_bridge_route_handler(&route).expect("卸载 bridge 自定义路由失败");
    assert!(removed);
}

#[test]
fn bridge_call_with_external_blocking_route_handler() {
    let route = format!(
        "test.custom.bridge.blocking.{}",
        BRIDGE_ROUTE_SEQ.fetch_add(1, Ordering::Relaxed)
    );

    register_bridge_route_blocking_handler(route.clone(), |runtime_name, args| {
        std::thread::sleep(Duration::from_millis(10));
        let first = args.first().cloned().unwrap_or(Value::Null);
        Ok(json!({
            "runtime": runtime_name,
            "first": first,
            "argc": args.len(),
            "mode": "blocking"
        }))
    })
    .expect("注册 bridge 阻塞自定义路由失败");

    let route_json = serde_json::to_string(&route).expect("序列化路由名失败");
    let script = format!(
        r#"
      (async () => {{
        const out = await bridge.call({route_json}, "slow", 1);
        return JSON.stringify(out);
      }})()
    "#
    );

    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["first"], "slow");
    assert_eq!(parsed["argc"], 2);
    assert_eq!(parsed["mode"], "blocking");
    assert!(parsed["runtime"].as_str().is_some());

    let removed = unregister_bridge_route_handler(&route).expect("卸载 bridge 阻塞自定义路由失败");
    assert!(removed);
}

#[test]
fn bridge_call_gzip_decompress() {
    let script = r#"
      (async () => {
        const gz = new Uint8Array([
          31,139,8,0,0,0,0,0,2,255,203,72,205,201,201,87,
          72,175,202,44,0,0,25,106,210,223,10,0,0,0
        ]);
        const bytes = await bridge.gzipDecompress(gz);
        const text = new TextDecoder().decode(bytes);
        return JSON.stringify({ text, len: bytes.length });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["text"], "hello gzip");
    assert_eq!(parsed["len"], 10);
}

#[test]
fn bridge_call_gzip_compress_and_decompress() {
    let script = r#"
      (async () => {
        const input = new TextEncoder().encode("hello gzip");
        const gz = await bridge.gzipCompress(input);
        const out = await bridge.gzipDecompress(gz);
        const text = new TextDecoder().decode(out);
        return JSON.stringify({
          text,
          gzipMagic: gz.length >= 2 && gz[0] === 31 && gz[1] === 139
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["text"], "hello gzip");
    assert_eq!(parsed["gzipMagic"], true);
}

#[test]
fn bridge_call_native_take_returns_uint8array() {
    let script = r#"
      (async () => {
        const inputId = await bridge.call("native.put", [1, 2, 3]);
        const outId = await bridge.call("native.exec", "invert", inputId, null, null);
        const out = await bridge.call("native.take", outId);
        return JSON.stringify({
          isUint8Array: out instanceof Uint8Array,
          out: Array.from(out),
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["isUint8Array"], true);
    assert_eq!(parsed["out"][0], 254);
    assert_eq!(parsed["out"][1], 253);
    assert_eq!(parsed["out"][2], 252);
}

#[test]
fn bridge_route_allowlist_denies_non_allowed_routes() {
    let _ = configure_bridge_runtime(BridgeRuntimeConfig {
        allowed_route_prefixes: vec![
            "native.".to_string(),
            "compression.".to_string(),
            "math.".to_string(),
            "crypto.".to_string(),
            "test.".to_string(),
            "bridge.".to_string(),
        ],
        max_args_json_bytes: 8 * 1024 * 1024,
        max_return_binary_bytes: 32 * 1024 * 1024,
    });

    let route_json = serde_json::to_string("forbidden.route").expect("序列化路由名失败");
    let script = format!(
        r#"
      (async () => {{
        let code = "";
        let message = "";
        try {{
          await bridge.call({route_json});
        }} catch (err) {{
          code = String(err.code || "");
          message = String(err.message || err);
        }}
        return JSON.stringify({{ code, message }});
      }})()
    "#
    );
    let result = run_async_script(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["code"], "BRIDGE_ROUTE_DENIED");
    assert!(
        parsed["message"]
            .as_str()
            .unwrap_or("")
            .contains("BRIDGE_ROUTE_DENIED")
    );

    let _ = configure_bridge_runtime(BridgeRuntimeConfig::default());
}

#[test]
fn bridge_args_size_limit_returns_structured_error() {
    let script = r#"
      (async () => {
        const big = "x".repeat(9 * 1024 * 1024);
        let code = "";
        let message = "";
        try {
          await bridge.call("math.add", big, 1);
        } catch (err) {
          code = String(err.code || "");
          message = String(err.message || err);
        }
        return JSON.stringify({ code, message });
      })()
    "#;
    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["code"], "BRIDGE_CALL_FAILED");
    assert!(
        parsed["message"]
            .as_str()
            .unwrap_or("")
            .contains("BRIDGE_CALL_FAILED")
    );
}
