use crate::tests::run_async_script;
#[cfg(feature = "wasi")]
use crate::tests::run_async_script_with_wasi;
use crate::{
    register_bridge_route_async_handler, register_bridge_route_blocking_handler,
    register_bridge_route_sync_handler, unregister_bridge_route_handler,
};
use serde_json::{Value, json};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::Duration;
#[cfg(feature = "wasi")]
use wat::parse_str;

static BRIDGE_ROUTE_SEQ: AtomicU64 = AtomicU64::new(1);

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
            ;; iov for stdin read: { ptr: 100, len: 256 }
            i32.const 0
            i32.const 100
            i32.store
            i32.const 4
            i32.const 256
            i32.store

            ;; fd_read(0, &iov, 1, &nread)
            i32.const 0
            i32.const 0
            i32.const 1
            i32.const 8
            call $fd_read
            drop

            ;; iov for stdout write: { ptr: 100, len: nread }
            i32.const 16
            i32.const 100
            i32.store
            i32.const 20
            i32.const 8
            i32.load
            i32.store

            ;; fd_write(1, &iov, 1, &nwritten)
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

#[cfg(feature = "wasi")]
fn wasi_increment_stdin_module_bytes() -> Vec<u8> {
    parse_str(
        r#"
        (module
          (import "wasi_snapshot_preview1" "fd_read"
            (func $fd_read (param i32 i32 i32 i32) (result i32)))
          (import "wasi_snapshot_preview1" "fd_write"
            (func $fd_write (param i32 i32 i32 i32) (result i32)))

          (memory (export "memory") 1)

          (func (export "_start")
            (local $i i32)
            (local $n i32)

            ;; iov for stdin read: { ptr: 100, len: 256 }
            i32.const 0
            i32.const 100
            i32.store
            i32.const 4
            i32.const 256
            i32.store

            ;; fd_read(0, &iov, 1, &nread)
            i32.const 0
            i32.const 0
            i32.const 1
            i32.const 8
            call $fd_read
            drop

            ;; n = nread
            i32.const 8
            i32.load
            local.set $n

            ;; for (i = 0; i < n; i++) mem[100 + i] += 1
            i32.const 0
            local.set $i
            block $done
              loop $next
                local.get $i
                local.get $n
                i32.ge_u
                br_if $done

                i32.const 100
                local.get $i
                i32.add
                i32.const 100
                local.get $i
                i32.add
                i32.load8_u
                i32.const 1
                i32.add
                i32.store8

                local.get $i
                i32.const 1
                i32.add
                local.set $i
                br $next
              end
            end

            ;; iov for stdout write: { ptr: 100, len: n }
            i32.const 16
            i32.const 100
            i32.store
            i32.const 20
            local.get $n
            i32.store

            ;; fd_write(1, &iov, 1, &nwritten)
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
    .expect("构建 wasi increment 模块失败")
}

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

#[cfg(feature = "wasi")]
#[test]
fn wasi_run_minimal_module() {
    let script = r#"
      (async () => {
        const wasm = new Uint8Array([
          0x00,0x61,0x73,0x6d,0x01,0x00,0x00,0x00,
          0x01,0x04,0x01,0x60,0x00,0x00,
          0x03,0x02,0x01,0x00,
          0x07,0x0a,0x01,0x06,0x5f,0x73,0x74,0x61,0x72,0x74,0x00,0x00,
          0x0a,0x04,0x01,0x02,0x00,0x0b
        ]);
        const result = await wasi.run(wasm);
        const stdout = await wasi.takeStdout(result);
        const stderr = await wasi.takeStderr(result);
        return JSON.stringify({
          exitCode: result.exitCode,
          stdoutLen: stdout.length,
          stderrLen: stderr.length
        });
      })()
    "#;

    let result = run_async_script_with_wasi(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["exitCode"], 0);
    assert_eq!(parsed["stdoutLen"], 0);
    assert_eq!(parsed["stderrLen"], 0);
}

#[cfg(feature = "wasi")]
#[test]
fn wasi_run_reuse_module_id() {
    let script = r#"
      (async () => {
        const wasm = new Uint8Array([
          0x00,0x61,0x73,0x6d,0x01,0x00,0x00,0x00,
          0x01,0x04,0x01,0x60,0x00,0x00,
          0x03,0x02,0x01,0x00,
          0x07,0x0a,0x01,0x06,0x5f,0x73,0x74,0x61,0x72,0x74,0x00,0x00,
          0x0a,0x04,0x01,0x02,0x00,0x0b
        ]);
        const id = await native.put(wasm);
        const r1 = await wasi.runById(id, { reuseModule: true });
        const r2 = await wasi.runById(id, { reuseModule: true });
        await wasi.takeStdout(r1);
        await wasi.takeStderr(r1);
        await wasi.takeStdout(r2);
        await wasi.takeStderr(r2);
        await native.free(id);
        return JSON.stringify({
          c1: r1.exitCode,
          c2: r2.exitCode
        });
      })()
    "#;

    let result = run_async_script_with_wasi(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["c1"], 0);
    assert_eq!(parsed["c2"], 0);
}

#[cfg(feature = "wasi")]
#[test]
fn wasi_run_processes_stdin_to_stdout() {
    let wasm = wasi_echo_stdin_module_bytes();
    let wasm_json = serde_json::to_string(&wasm).expect("序列化 wasm 失败");

    let script = format!(
        r#"
      (async () => {{
        const wasm = new Uint8Array({wasm_json});
        const input = new TextEncoder().encode("hello-wasi-io");
        const stdinId = await native.put(input);
        const result = await wasi.run(wasm, {{ stdinId }});
        const stdout = await wasi.takeStdout(result);
        const stderr = await wasi.takeStderr(result);
        const text = new TextDecoder().decode(stdout);

        return JSON.stringify({{
          exitCode: result.exitCode,
          text,
          stderrLen: stderr.length
        }});
      }})()
    "#
    );

    let result = run_async_script_with_wasi(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["exitCode"], 0);
    assert_eq!(parsed["text"], "hello-wasi-io");
    assert_eq!(parsed["stderrLen"], 0);
}

#[cfg(feature = "wasi")]
#[test]
fn wasi_run_transforms_stdin_bytes() {
    let wasm = wasi_increment_stdin_module_bytes();
    let wasm_json = serde_json::to_string(&wasm).expect("序列化 wasm 失败");

    let script = format!(
        r#"
      (async () => {{
        const wasm = new Uint8Array({wasm_json});
        const input = new Uint8Array([65, 66, 67, 120]); // A B C x
        const stdinId = await native.put(input);
        const result = await wasi.run(wasm, {{ stdinId }});
        const stdout = await wasi.takeStdout(result);
        return JSON.stringify({{
          exitCode: result.exitCode,
          out: Array.from(stdout)
        }});
      }})()
    "#
    );

    let result = run_async_script_with_wasi(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["exitCode"], 0);
    assert_eq!(parsed["out"][0], 66);
    assert_eq!(parsed["out"][1], 67);
    assert_eq!(parsed["out"][2], 68);
    assert_eq!(parsed["out"][3], 121);
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

#[cfg(feature = "wasi")]
#[test]
fn wasi_run_by_id_consumes_module_by_default() {
    let script = r#"
      (async () => {
        const wasm = new Uint8Array([
          0x00,0x61,0x73,0x6d,0x01,0x00,0x00,0x00,
          0x01,0x04,0x01,0x60,0x00,0x00,
          0x03,0x02,0x01,0x00,
          0x07,0x0a,0x01,0x06,0x5f,0x73,0x74,0x61,0x72,0x74,0x00,0x00,
          0x0a,0x04,0x01,0x02,0x00,0x0b
        ]);

        const id = await native.put(wasm);
        const ok = await wasi.runById(id);
        await wasi.takeStdout(ok);
        await wasi.takeStderr(ok);

        let secondError = "";
        try {
          await wasi.runById(id);
        } catch (err) {
          secondError = String(err.message || err);
        }

        return JSON.stringify({
          firstExit: ok.exitCode,
          secondErrorHasId: secondError.includes("module id")
        });
      })()
    "#;

    let result = run_async_script_with_wasi(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["firstExit"], 0);
    assert_eq!(parsed["secondErrorHasId"], true);
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
          out,
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
