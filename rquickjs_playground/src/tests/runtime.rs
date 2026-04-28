#[cfg(feature = "wasi")]
use crate::tests::run_async_script_with_wasi;
use crate::tests::{run_async_script, run_async_script_without_wasi};
use crate::web_runtime::configure_log_http_endpoint;
use serde_json::Value;
#[cfg(feature = "wasi")]
use std::fs;
#[cfg(feature = "wasi")]
use std::path::PathBuf;
use std::sync::mpsc;
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

#[test]
fn runtime_timers_and_microtask() {
    let script = r#"
      (async () => {
        const events = [];

        const timeoutId = setTimeout(() => events.push("timeout-cancelled"), 1);
        clearTimeout(timeoutId);

        queueMicrotask(() => events.push("micro"));

        let count = 0;
        const intervalId = setInterval(() => {
          count += 1;
          events.push(`interval-${count}`);
          if (count >= 2) clearInterval(intervalId);
        }, 1);

        await new Promise((resolve) => setTimeout(resolve, 20));

        return JSON.stringify({ events });
      })()
    "#;

    let result = run_async_script_without_wasi(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    let events = parsed["events"].as_array().expect("events 必须是数组");

    assert!(events.iter().any(|v| v == "micro"));
    assert!(events.iter().any(|v| v == "interval-1"));
    assert!(events.iter().any(|v| v == "interval-2"));
    assert!(!events.iter().any(|v| v == "timeout-cancelled"));
}

#[test]
fn runtime_text_and_base64() {
    let script = r#"
      (async () => {
        const te = new TextEncoder();
        const td = new TextDecoder();
        const bytes = te.encode("A中B");
        const text = td.decode(bytes);

        const b64 = btoa("ABC");
        const raw = atob(b64);

        return JSON.stringify({
          text,
          b64,
          raw,
          byteLen: bytes.length
        });
      })()
    "#;

    let result = run_async_script_without_wasi(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["text"], "A中B");
    assert_eq!(parsed["b64"], "QUJD");
    assert_eq!(parsed["raw"], "ABC");
    assert!(parsed["byteLen"].as_u64().unwrap_or(0) >= 3);
}

#[test]
fn runtime_url_and_search_params() {
    let script = r#"
      (async () => {
        const url = new URL("/v1/items?q=1", "https://example.com/api/");
        url.searchParams.append("q", "2");
        url.searchParams.set("lang", "zh-CN");

        const sp = new URLSearchParams("a=1&a=2");
        const all = sp.getAll("a");
        sp.delete("a");
        sp.append("b", "3");

        return JSON.stringify({
          href: url.href,
          host: url.host,
          q2: url.searchParams.getAll("q").length,
          lang: url.searchParams.get("lang"),
          allLen: all.length,
          sp: sp.toString()
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["host"], "example.com");
    assert_eq!(parsed["q2"], 2);
    assert_eq!(parsed["lang"], "zh-CN");
    assert_eq!(parsed["allLen"], 2);
    assert_eq!(parsed["sp"], "b=3");
    assert!(parsed["href"].as_str().unwrap_or("").contains("lang=zh-CN"));
}

#[test]
fn runtime_process_and_immediate() {
    let script = r#"
      (async () => {
        const events = [];

        process.nextTick(() => events.push("nextTick"));
        const immediateId = setImmediate(() => events.push("immediate"));
        clearImmediate(immediateId);
        setImmediate(() => events.push("immediate-ok"));

        const t0 = process.hrtime();
        const dt = process.hrtime(t0);
        const ns = process.hrtime.bigint();

        await new Promise((resolve) => setTimeout(resolve, 10));

        return JSON.stringify({
          hasProcess: typeof process === "object",
          platform: process.platform,
          argvLen: process.argv.length,
          cwd: process.cwd(),
          hasNextTick: events.includes("nextTick"),
          hasImmediateOk: events.includes("immediate-ok"),
          hasImmediateCancelled: events.includes("immediate"),
          hrtimeOk: Array.isArray(dt) && dt.length === 2,
          bigintOk: typeof ns === "bigint"
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["hasProcess"], true);
    assert_eq!(parsed["platform"], "quickjs");
    assert_eq!(parsed["cwd"], "/");
    assert_eq!(parsed["hasNextTick"], true);
    assert_eq!(parsed["hasImmediateOk"], true);
    assert_eq!(parsed["hasImmediateCancelled"], false);
    assert_eq!(parsed["hrtimeOk"], true);
    assert_eq!(parsed["bigintOk"], true);
    assert!(parsed["argvLen"].as_u64().unwrap_or(0) >= 1);
}

#[test]
fn runtime_path_module_basic() {
    let script = r#"
      (async () => {
        const path = require("path");
        return JSON.stringify({
          join: path.join("/a", "b", "..", "c.txt"),
          resolve: path.resolve("a", "./b", "../c"),
          dirname: path.dirname("/a/b/c.txt"),
          basename: path.basename("/a/b/c.txt"),
          basenameNoExt: path.basename("/a/b/c.txt", ".txt"),
          ext: path.extname("/a/b/c.txt"),
          abs: path.isAbsolute("/a/b")
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["join"], "/a/c.txt");
    assert_eq!(parsed["resolve"], "/a/c");
    assert_eq!(parsed["dirname"], "/a/b");
    assert_eq!(parsed["basename"], "c.txt");
    assert_eq!(parsed["basenameNoExt"], "c");
    assert_eq!(parsed["ext"], ".txt");
    assert_eq!(parsed["abs"], true);
}

#[test]
fn runtime_buffer_basic() {
    let script = r#"
      (async () => {
        const { Buffer } = require("buffer");
        const a = Buffer.from("ab");
        const b = Buffer.from([99, 100]);
        const c = Buffer.concat([a, b]);
        const d = Buffer.alloc(4, 1);

        return JSON.stringify({
          isBuffer: Buffer.isBuffer(a),
          text: c.toString("utf8"),
          len: Buffer.byteLength("中", "utf8"),
          d: Array.from(d),
          globalOk: typeof globalThis.Buffer === "function"
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["isBuffer"], true);
    assert_eq!(parsed["text"], "abcd");
    assert_eq!(parsed["len"], 3);
    assert_eq!(parsed["d"][0], 1);
    assert_eq!(parsed["d"][1], 1);
    assert_eq!(parsed["d"][2], 1);
    assert_eq!(parsed["d"][3], 1);
    assert_eq!(parsed["globalOk"], true);
}

#[test]
fn runtime_uuidv4_basic() {
    let script = r#"
      (async () => {
        const mod = require("uuidv4");
        const fromGlobal = uuidv4();
        const fromModule = mod.uuidv4();
        const re = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

        const ids = [];
        for (let i = 0; i < 64; i += 1) ids.push(uuidv4());
        const unique = new Set(ids);

        return JSON.stringify({
          hasGlobal: typeof uuidv4 === "function",
          hasModuleFn: typeof mod.uuidv4 === "function",
          globalValid: re.test(fromGlobal),
          moduleValid: re.test(fromModule),
          allValid: ids.every((id) => re.test(id)),
          uniqueAll: unique.size === ids.length
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["hasGlobal"], true);
    assert_eq!(parsed["hasModuleFn"], true);
    assert_eq!(parsed["globalValid"], true);
    assert_eq!(parsed["moduleValid"], true);
    assert_eq!(parsed["allValid"], true);
    assert_eq!(parsed["uniqueAll"], true);
}

#[test]
fn runtime_crypto_hash_and_hmac_basic() {
    let script = r#"
      (async () => {
        const crypto = require("crypto");
        const text = "The quick brown fox jumps over the lazy dog";

        const shaHex = crypto.createHash("sha256").update(text).digest("hex");
        const hmacHex = crypto.createHmac("sha256", "key").update(text).digest("hex");
        const hmacBase64 = crypto.createHmac("sha256", "key").update(text).digest("base64");
        const random = crypto.randomBytes(16);

        return JSON.stringify({
          hasGlobal: typeof globalThis.crypto === "object",
          hasCreateHash: typeof crypto.createHash === "function",
          hasCreateHmac: typeof crypto.createHmac === "function",
          hasRandomBytes: typeof crypto.randomBytes === "function",
          shaHex,
          hmacHex,
          hmacBase64,
          randomLen: random.length,
          randomIsBuffer: Buffer.isBuffer(random)
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["hasGlobal"], true);
    assert_eq!(parsed["hasCreateHash"], true);
    assert_eq!(parsed["hasCreateHmac"], true);
    assert_eq!(parsed["hasRandomBytes"], true);
    assert_eq!(parsed["randomLen"], 16);
    assert_eq!(parsed["randomIsBuffer"], true);
    assert_eq!(
        parsed["shaHex"],
        "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592"
    );
    assert_eq!(
        parsed["hmacHex"],
        "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8"
    );
    assert_eq!(
        parsed["hmacBase64"],
        "97yD9DBThCSxMpjmqm+xQ+9NWaFJRhdZl0edvC0aPNg="
    );
}

#[test]
fn runtime_stats_exposed() {
    let script = r#"
      (async () => {
        const raw = globalThis.__runtime_stats();
        const s = JSON.parse(raw);
        return JSON.stringify({
          ok: s.ok === true,
          hasPending: typeof s.pending === "object",
          hasLimits: typeof s.limits === "object",
          hasPermits: typeof s.permits === "object",
          hasStale: typeof s.staleDrops === "object",
          hasWasi: typeof s.wasi === "object",
          hasCap: typeof s.wasi.cacheCapacity === "number"
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["ok"], true);
    assert_eq!(parsed["hasPending"], true);
    assert_eq!(parsed["hasLimits"], true);
    assert_eq!(parsed["hasPermits"], true);
    assert_eq!(parsed["hasStale"], true);
    assert_eq!(parsed["hasWasi"], true);
    assert_eq!(parsed["hasCap"], true);
}

#[test]
fn wasi_is_not_injected_by_default() {
    let script = r#"
      (async () => JSON.stringify({
        hasWasi: typeof globalThis.wasi !== "undefined"
      }))()
    "#;

    let result = run_async_script_without_wasi(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["hasWasi"], false);
}

#[test]
fn runtime_console_hook_emits_to_host_logger() {
    let script = r#"
      (async () => {
        const before = JSON.parse(globalThis.__runtime_stats()).logs || {};
        const beforeEnqueued = Number(before.enqueued || 0);

        console.log("hello", { a: 1 });
        console.warn("warn-msg");
        console.error("err-msg");

        await new Promise((r) => setTimeout(r, 0));
        await new Promise((r) => setTimeout(r, 0));

        const after = JSON.parse(globalThis.__runtime_stats()).logs || {};
        const deltaEnqueued = Number(after.enqueued || 0) - beforeEnqueued;

        return JSON.stringify({
          hasConsole: typeof console === "object" && typeof console.log === "function",
          deltaEnqueued,
          written: Number(after.written || 0),
          dropped: Number(after.dropped || 0)
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["hasConsole"], true);
    assert!(parsed["deltaEnqueued"].as_i64().unwrap_or(0) >= 3);
}

#[test]
fn runtime_console_all_levels_forwarded_to_http_endpoint() {
    use tiny_http::{Method, Response, Server};

    configure_log_http_endpoint(None);

    let server = Server::http("127.0.0.1:0").expect("启动测试服务失败");
    let endpoint = format!("http://{}/log", server.server_addr());
    let (tx, rx) = mpsc::channel::<Value>();

    let marker = format!(
        "debug-forward-{}",
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map(|d| d.as_nanos())
            .unwrap_or_default()
    );

    let marker_for_thread = marker.clone();
    let handle = thread::spawn(move || {
        let mut matched = 0usize;
        while matched < 3 {
            match server.recv_timeout(Duration::from_secs(3)) {
                Ok(Some(mut request)) => {
                    let mut body = String::new();
                    let _ = request.as_reader().read_to_string(&mut body);
                    if request.method() == &Method::Post
                        && request.url() == "/log"
                        && body.contains(&marker_for_thread)
                    {
                        if let Ok(value) = serde_json::from_str::<Value>(&body) {
                            let _ = tx.send(value);
                            matched += 1;
                        }
                    }
                    let _ = request.respond(Response::from_string("ok").with_status_code(200));
                }
                Ok(None) => {}
                Err(_) => break,
            }
        }
    });

    configure_log_http_endpoint(Some(endpoint));

    let script = format!(
        r#"
      (async () => {{
        console.debug("{marker}-debug");
        console.info("{marker}-info");
        console.warn("{marker}-warn");
        await new Promise((r) => setTimeout(r, 10));
        await new Promise((r) => setTimeout(r, 10));
        return JSON.stringify({{ ok: true }});
      }})()
    "#,
    );

    let _ = run_async_script(&script).expect("执行脚本失败");

    let first = rx
        .recv_timeout(Duration::from_secs(3))
        .expect("未收到第 1 条日志回调");
    let second = rx
        .recv_timeout(Duration::from_secs(3))
        .expect("未收到第 2 条日志回调");
    let third = rx
        .recv_timeout(Duration::from_secs(3))
        .expect("未收到第 3 条日志回调");

    configure_log_http_endpoint(None);
    let _ = handle.join();

    let mut levels = vec![
        first["level"].as_str().unwrap_or_default().to_string(),
        second["level"].as_str().unwrap_or_default().to_string(),
        third["level"].as_str().unwrap_or_default().to_string(),
    ];
    levels.sort();

    assert_eq!(
        levels,
        vec!["debug".to_string(), "info".to_string(), "warn".to_string()]
    );
    assert!(first["payload"]["tsMs"].is_number());
    assert!(second["payload"]["tsMs"].is_number());
    assert!(third["payload"]["tsMs"].is_number());
}

#[cfg(feature = "wasi")]
#[test]
fn runtime_runs_compiled_pnpm_bundle() {
    let mut bundle_path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    bundle_path.push("pnpm_demo");
    bundle_path.push("dist");
    bundle_path.push("bundle.cjs");

    let bundle =
        fs::read_to_string(&bundle_path).expect("读取编译产物失败，请先执行 pnpm_demo/pnpm build");
    let bundle_json = serde_json::to_string(&bundle).expect("序列化 bundle 失败");

    let script = format!(
        r#"
      (async () => {{
        const code = {bundle_json};
        const module = {{ exports: {{}} }};
        const exports = module.exports;
        const requireFn = typeof require === "function" ? require.bind(globalThis) : undefined;
        const runner = new Function("module", "exports", "require", code);
        runner(module, exports, requireFn);

        let entry = module.exports;
        if (entry && typeof entry === "object" && entry.default !== undefined) {{
          entry = entry.default;
        }}
        if (typeof entry !== "function") {{
          throw new Error("bundle 必须导出默认函数");
        }}

        const result = await entry();
        return JSON.stringify(result);
      }})()
    "#
    );

    let result = run_async_script_with_wasi(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["ok"], true);
    assert_eq!(parsed["joined"], "/demo/out.png");
    assert_eq!(parsed["out"][0], 1);
    assert_eq!(parsed["out"][1], 2);
    assert_eq!(parsed["out"][2], 3);
    assert_eq!(parsed["out"][3], 4);
    assert_eq!(parsed["wasi"]["exitCode"], 0);
}
