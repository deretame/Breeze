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
fn runtime_url_library_complete() {
    let script = r#"
      (async () => {
        const sp = new URLSearchParams("a=1&b=hello+world&a=2");
        const beforeSize = sp.size;
        const hasA2 = sp.has("a", "2");
        sp.delete("a", "1");
        sp.append("c", "x y");
        sp.sort();

        const url = new URL("../v2/item?id=9#h", "https://u:p@example.com/api/v1/list?q=1");
        const beforeHref = url.href;
        url.username = "alice";
        url.password = "secret";
        url.searchParams.set("lang", "zh CN");
        url.pathname = "/a/./b/../c";

        const resolved = new URL("?page=2", url.href).href;

        return JSON.stringify({
          spBeforeSize: beforeSize,
          spAfterSize: sp.size,
          spHasA2: hasA2,
          spAllA: sp.getAll("a"),
          spText: sp.toString(),
          beforeHref,
          href: url.href,
          origin: url.origin,
          username: url.username,
          password: url.password,
          resolved
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["spBeforeSize"], 3);
    assert_eq!(parsed["spAfterSize"], 3);
    assert_eq!(parsed["spHasA2"], true);
    assert_eq!(parsed["spAllA"][0], "2");
    assert_eq!(parsed["spText"], "a=2&b=hello+world&c=x+y");

    assert_eq!(parsed["origin"], "https://example.com");
    assert_eq!(parsed["username"], "alice");
    assert_eq!(parsed["password"], "secret");
    assert!(
        parsed["beforeHref"]
            .as_str()
            .unwrap_or("")
            .starts_with("https://u:p@example.com/api/v2/item")
    );
    assert!(
        parsed["href"]
            .as_str()
            .unwrap_or("")
            .starts_with("https://alice:secret@example.com/a/c?")
    );
    assert_eq!(
        parsed["resolved"],
        "https://alice:secret@example.com/a/c?page=2"
    );
}

#[test]
fn runtime_url_web_global_api_surface() {
    let script = r#"
      (async () => {
        const parsed = URL.parse("/x?a=1", "https://example.com/base/");
        const invalid = URL.parse("::::");

        const json = JSON.stringify({
          u: new URL("/api?q=1", "https://example.com").toJSON()
        });

        const spTag = Object.prototype.toString.call(new URLSearchParams());
        const urlTag = Object.prototype.toString.call(new URL("https://example.com"));

        return JSON.stringify({
          can1: URL.canParse("/x", "https://example.com"),
          can2: URL.canParse("::::"),
          parsedHref: parsed ? parsed.href : null,
          invalidIsNull: invalid === null,
          json,
          spTag,
          urlTag
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["can1"], true);
    assert_eq!(parsed["can2"], false);
    assert_eq!(parsed["parsedHref"], "https://example.com/x?a=1");
    assert_eq!(parsed["invalidIsNull"], true);
    assert_eq!(parsed["json"], "{\"u\":\"https://example.com/api?q=1\"}");
    assert_eq!(parsed["spTag"], "[object URLSearchParams]");
    assert_eq!(parsed["urlTag"], "[object URL]");
}

#[test]
fn runtime_structured_clone() {
    let script = r#"
      (async () => {
        const now = new Date("2026-01-02T03:04:05.000Z");
        const map = new Map([["k", { n: 1 }]]);
        const set = new Set(["a", "b"]);
        const bytes = new Uint8Array([1, 2, 3]);
        const source = {
          nested: { ok: true },
          date: now,
          map,
          set,
          bytes,
        };
        source.self = source;

        const cloned = structuredClone(source);
        cloned.nested.ok = false;
        cloned.map.get("k").n = 99;
        cloned.set.add("c");
        cloned.bytes[0] = 9;

        return JSON.stringify({
          sameRef: cloned === source,
          cycleOk: cloned.self === cloned,
          nestedOriginal: source.nested.ok,
          nestedCloned: cloned.nested.ok,
          mapOriginal: source.map.get("k").n,
          mapCloned: cloned.map.get("k").n,
          setOriginalSize: source.set.size,
          setClonedSize: cloned.set.size,
          bytesOriginal0: source.bytes[0],
          bytesCloned0: cloned.bytes[0],
          dateIso: cloned.date.toISOString(),
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["sameRef"], false);
    assert_eq!(parsed["cycleOk"], true);
    assert_eq!(parsed["nestedOriginal"], true);
    assert_eq!(parsed["nestedCloned"], false);
    assert_eq!(parsed["mapOriginal"], 1);
    assert_eq!(parsed["mapCloned"], 99);
    assert_eq!(parsed["setOriginalSize"], 2);
    assert_eq!(parsed["setClonedSize"], 3);
    assert_eq!(parsed["bytesOriginal0"], 1);
    assert_eq!(parsed["bytesCloned0"], 9);
    assert_eq!(parsed["dateIso"], "2026-01-02T03:04:05.000Z");
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
fn runtime_abort_signal_static_methods() {
    let script = r#"
      (async () => {
        const c1 = new AbortController();
        const c2 = new AbortController();
        const any = AbortSignal.any([c1.signal, c2.signal]);
        c2.abort("boom");

        const aborted = AbortSignal.abort("x");
        const timed = AbortSignal.timeout(1);
        await new Promise((resolve) => setTimeout(resolve, 5));

        return JSON.stringify({
          hasAny: typeof AbortSignal.any === "function",
          hasAbort: typeof AbortSignal.abort === "function",
          hasTimeout: typeof AbortSignal.timeout === "function",
          anyAborted: any.aborted,
          anyReason: String(any.reason),
          abortedNow: aborted.aborted,
          abortedReason: String(aborted.reason),
          timedAborted: timed.aborted
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["hasAny"], true);
    assert_eq!(parsed["hasAbort"], true);
    assert_eq!(parsed["hasTimeout"], true);
    assert_eq!(parsed["anyAborted"], true);
    assert_eq!(parsed["anyReason"], "boom");
    assert_eq!(parsed["abortedNow"], true);
    assert_eq!(parsed["abortedReason"], "x");
    assert_eq!(parsed["timedAborted"], true);
}

#[test]
fn runtime_request_clone_available() {
    let script = r#"
      (async () => {
        const req = new Request("https://example.com/a", {
          method: "POST",
          headers: { "x-a": "1" },
          body: "hello"
        });
        const cloned = req.clone();
        return JSON.stringify({
          hasClone: typeof req.clone === "function",
          method: cloned.method,
          url: cloned.url,
          body: await cloned.text(),
          header: cloned.headers.get("x-a")
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["hasClone"], true);
    assert_eq!(parsed["method"], "POST");
    assert_eq!(parsed["url"], "https://example.com/a");
    assert_eq!(parsed["body"], "hello");
    assert_eq!(parsed["header"], "1");
}

#[test]
fn runtime_request_clone_get_without_body() {
    let script = r#"
      (async () => {
        const req = new Request("https://example.com/a?x=1", { method: "GET" });
        const cloned = req.clone();
        return JSON.stringify({
          method: cloned.method,
          url: cloned.url,
          bodyUsed: cloned.bodyUsed,
          text: await cloned.text()
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["method"], "GET");
    assert_eq!(parsed["url"], "https://example.com/a?x=1");
    assert_eq!(parsed["bodyUsed"], false);
    assert_eq!(parsed["text"], "");
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
fn runtime_crypto_common_extra_apis() {
    let script = r#"
      (async () => {
        const crypto = require("crypto");
        const a = Buffer.from([1, 2, 3]);
        const b = Buffer.from([1, 2, 3]);
        const c = Buffer.from([1, 2, 4]);
        const toHex = (buf) =>
          Array.from(buf)
            .map((x) => x.toString(16).padStart(2, "0"))
            .join("");

        const dk = crypto.pbkdf2Sync("password", "salt", 1000, 32, "sha256");
        const uuid = crypto.randomUUID();
        const re = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;

        const asyncHex = await new Promise((resolve, reject) => {
          crypto.pbkdf2("password", "salt", 1000, 32, "sha256", (err, key) => {
            if (err) return reject(err);
            resolve(toHex(key));
          });
        });

        return JSON.stringify({
          hasRandomUUID: typeof crypto.randomUUID === "function",
          hasTimingSafeEqual: typeof crypto.timingSafeEqual === "function",
          hasPbkdf2Sync: typeof crypto.pbkdf2Sync === "function",
          hasPbkdf2: typeof crypto.pbkdf2 === "function",
          eq1: crypto.timingSafeEqual(a, b),
          eq2: crypto.timingSafeEqual(a, c),
          dkHex: toHex(dk),
          asyncHex,
          uuidValid: re.test(uuid),
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["hasRandomUUID"], true);
    assert_eq!(parsed["hasTimingSafeEqual"], true);
    assert_eq!(parsed["hasPbkdf2Sync"], true);
    assert_eq!(parsed["hasPbkdf2"], true);
    assert_eq!(parsed["eq1"], true);
    assert_eq!(parsed["eq2"], false);
    assert_eq!(
        parsed["dkHex"],
        "632c2812e46d4604102ba7618e9d6d7d2f8128f6266b4a03264d2a0460b7dcb3"
    );
    assert_eq!(
        parsed["asyncHex"],
        "632c2812e46d4604102ba7618e9d6d7d2f8128f6266b4a03264d2a0460b7dcb3"
    );
    assert_eq!(parsed["uuidValid"], true);
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
