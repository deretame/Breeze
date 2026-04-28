use crate::tests::{
    ensure_pnpm_cases_built, run_async_script, run_async_script_with_fs,
    run_async_script_with_wasi, run_async_script_with_wasi_and_fs, spawn_test_server,
};
use serde_json::Value;
use std::fs;
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

fn case_bundle_path(name: &str) -> PathBuf {
    let mut p = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    p.push("pnpm_demo");
    p.push("dist");
    p.push("cases");
    p.push(format!("{name}.js"));
    p
}

fn run_case(name: &str, config: Value) -> Value {
    run_case_with_wasi(name, config, false, false)
}

fn run_case_with_wasi(name: &str, config: Value, wasi: bool, fs: bool) -> Value {
    ensure_pnpm_cases_built();
    let bundle = fs::read_to_string(case_bundle_path(name)).expect("读取 case bundle 失败");
    let bundle_json = serde_json::to_string(&bundle).expect("序列化 bundle 失败");
    let config_json = serde_json::to_string(&config).expect("序列化 config 失败");

    let script = format!(
        r#"
      (async () => {{
        try {{
          const code = {bundle_json};
          const cfg = {config_json};
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
            throw new Error("case bundle 必须导出默认函数");
          }}

          const out = await entry(cfg);
          return JSON.stringify(out);
        }} catch (err) {{
          return JSON.stringify({{
            ok: false,
            __error: String(err && (err.stack || err.message) ? (err.stack || err.message) : err)
          }});
        }}
      }})()
    "#
    );

    let result = if wasi && fs {
        run_async_script_with_wasi_and_fs(&script)
    } else if wasi {
        run_async_script_with_wasi(&script)
    } else if fs {
        run_async_script_with_fs(&script)
    } else {
        run_async_script(&script)
    }
    .expect("执行 bundle case 失败");

    serde_json::from_str(&result).expect("解析 case 结果失败")
}

fn assert_case_ok(out: &Value) {
    if out["ok"] != true {
        let raw = serde_json::to_string(out).unwrap_or_else(|_| "<serialize-failed>".to_string());
        panic!(
            "case 执行失败: {}\nraw={}",
            out["__error"].as_str().unwrap_or("未知错误"),
            raw
        );
    }
}

fn unique_temp_dir() -> PathBuf {
    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("系统时间异常")
        .as_nanos();
    let dir = std::env::temp_dir().join(format!("rquickjs-case-{ts}"));
    fs::create_dir_all(&dir).expect("创建临时目录失败");
    dir
}

#[test]
fn compiled_fetch_case_runs() {
    ensure_pnpm_cases_built();
    let (base_url, tx, handle) = spawn_test_server(4);
    let out = run_case("fetch", serde_json::json!({ "baseUrl": base_url }));
    assert_case_ok(&out);
    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn compiled_axios_case_runs() {
    ensure_pnpm_cases_built();
    let (base_url, tx, handle) = spawn_test_server(100);
    let out = run_case("axios", serde_json::json!({ "baseUrl": base_url }));
    assert_case_ok(&out);
    assert_eq!(out["checks"]["get"], true);
    assert_eq!(out["checks"]["post"], true);
    assert_eq!(out["checks"]["params"], true);
    assert_eq!(out["checks"]["interceptor"], true);
    assert_eq!(out["checks"]["responseInterceptor"], true);
    assert_eq!(out["checks"]["formData"], true);
    assert_eq!(out["checks"]["concurrent"], true);
    assert_eq!(out["checks"]["urlEncoded"], true);
    assert_eq!(out["checks"]["instanceRequest"], true);
    assert_eq!(out["checks"]["helpers"], true);
    assert_eq!(out["checks"]["errorShape"], true);
    assert_eq!(out["checks"]["arrayBuffer"], true);
    assert_eq!(out["details"]["getPath"], "/axios-get?x=1");
    assert_eq!(out["details"]["interceptorHeader"], "yes");
    assert_eq!(out["details"]["responseIntercepted"], true);
    assert!(
        out["details"]["formDataContentType"]
            .as_str()
            .unwrap_or_default()
            .contains("multipart/form-data")
    );
    assert!(out["details"]["formDataBodyLen"].as_u64().unwrap_or(0) > 0);
    let url_body = out["details"]["urlEncodedBody"]
        .as_str()
        .unwrap_or_default();
    assert!(url_body.contains("name=axios") || url_body.contains("\"name\",\"axios\""));
    assert_eq!(out["details"]["instanceRequestMethod"], "PUT");
    assert_eq!(
        out["details"]["helperSpreadOut"],
        "/axios-all-1|/axios-all-2"
    );
    assert_eq!(out["details"]["errorIsAxiosError"], true);
    assert!(out["details"]["arrayBufferLen"].as_u64().unwrap_or(0) > 0);
    assert!(out["details"]["arrayBufferFirst"].as_i64().unwrap_or(-1) >= 0);
    assert!(out["details"]["arrayBufferLast"].as_i64().unwrap_or(-1) >= 0);
    let _ = tx.send(());
    let _ = handle.join();
}

#[test]
fn compiled_fs_case_runs() {
    let dir = unique_temp_dir();
    let base_dir = dir.to_string_lossy().replace('\\', "/");
    let out = run_case_with_wasi(
        "fs",
        serde_json::json!({ "baseDir": base_dir }),
        false,
        true,
    );
    assert_case_ok(&out);
    let _ = fs::remove_dir_all(&dir);
}

#[test]
fn compiled_native_case_runs() {
    let out = run_case("native", serde_json::json!({}));
    assert_case_ok(&out);
}

#[test]
fn compiled_runtime_case_runs() {
    let out = run_case("runtime", serde_json::json!({}));
    assert_case_ok(&out);
}

#[cfg(feature = "wasi")]
#[test]
fn compiled_runtime_api_case_runs() {
    let (base_url, tx, handle) = spawn_test_server(2);
    let dir = unique_temp_dir();
    let base_dir = dir.to_string_lossy().replace('\\', "/");
    let out = run_case_with_wasi(
        "runtime_api",
        serde_json::json!({ "baseDir": base_dir, "baseUrl": base_url }),
        true,
        true,
    );
    assert_case_ok(&out);
    let _ = tx.send(());
    let _ = handle.join();
    let _ = fs::remove_dir_all(&dir);
}

#[cfg(feature = "wasi")]
#[test]
fn compiled_wasi_case_runs() {
    let out = run_case_with_wasi("wasi", serde_json::json!({}), true, false);
    assert_case_ok(&out);
}

#[test]
fn compiled_bridge_case_runs() {
    let out = run_case("bridge", serde_json::json!({}));
    assert_case_ok(&out);
}
