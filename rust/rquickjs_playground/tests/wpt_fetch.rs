use rquickjs_playground::host_runtime::AsyncHostRuntime;
use rquickjs_playground::web_runtime::{configure_http_client, current_http_client_config};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Debug, Clone, Serialize, Deserialize)]
struct WptResult {
    status: i32,
    name: String,
    message: Option<String>,
    stack: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct WptHarnessStatus {
    status: i32,
    message: Option<String>,
    stack: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct WptRunResult {
    harness: WptHarnessStatus,
    tests: Vec<WptResult>,
}

fn wpt_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("wpt")
}

fn ensure_wpt_checkout() {
    let root = wpt_root();
    if !root.join("resources/testharness.js").is_file() {
        panic!(
            "WPT checkout not found at {}. \
             Run: git clone --depth 1 https://github.com/web-platform-tests/wpt.git {}",
            root.display(),
            root.display()
        );
    }
}

fn read_wpt_file(relative: &str) -> String {
    fs::read_to_string(wpt_root().join(relative))
        .unwrap_or_else(|e| panic!("failed to read {}: {}", relative, e))
}

fn resolve_meta_script(test_dir: &Path, line: &str) -> Option<String> {
    let line = line.trim();
    if !line.starts_with("// META: script=") {
        return None;
    }
    let script = line.strip_prefix("// META: script=")?.trim();
    let content = if script.starts_with('/') {
        read_wpt_file(&script[1..])
    } else {
        fs::read_to_string(test_dir.join(script))
            .unwrap_or_else(|e| panic!("failed to read relative script {}: {}", script, e))
    };
    Some(content)
}

fn inject_implicit_loop_vars(test_source: &str) -> String {
    // QuickJS/rquickjs evaluates scripts in strict mode, so implicit globals
    // used as loop variables in `for (x of y)` / `for (x in y)` need to be
    // declared. This injects `var` declarations for such variables.
    let re = regex::Regex::new(r"for\s*\(\s*([A-Za-z_$][A-Za-z0-9_$]*)\s+(of|in)\s+").unwrap();
    let vars: std::collections::HashSet<&str> = re
        .captures_iter(test_source)
        .filter_map(|caps| caps.get(1).map(|m| m.as_str()))
        .collect();
    if vars.is_empty() {
        return test_source.to_string();
    }
    let mut declarations: Vec<&str> = vars.into_iter().collect();
    declarations.sort();
    format!("var {};\n{}", declarations.join(", "), test_source)
}

fn build_test_payload(test_relative: &str) -> String {
    let test_path = wpt_root().join(test_relative);
    let test_dir = test_path.parent().expect("test path has no parent");
    let test_source = fs::read_to_string(&test_path)
        .unwrap_or_else(|e| panic!("failed to read test {}: {}", test_relative, e));
    let test_source = inject_implicit_loop_vars(&test_source);

    let mut parts: Vec<String> = Vec::new();

    // Ensure self is defined and no DOM globals exist so testharness picks ShellTestEnvironment.
    parts.push(
        r#"
        if (typeof self === "undefined") { globalThis.self = globalThis; }
        if ("document" in globalThis) { delete globalThis.document; }
        if ("window" in globalThis) { delete globalThis.window; }
        if ("location" in globalThis) { delete globalThis.location; }
        if (!globalThis.GLOBAL) {
          globalThis.GLOBAL = {
            isWindow: function() { return false; },
            isWorker: function() { return false; },
            isShadowRealm: function() { return false; }
          };
        }
        "#
        .to_string(),
    );

    // Load testharness.js
    parts.push(read_wpt_file("resources/testharness.js"));

    // Provide a minimal location object for tests that only need to construct
    // URLs (e.g. bad-port checks). This is injected after testharness has picked
    // the shell environment so it is not mistaken for a Window.
    parts.push(
        r#"
        if (typeof globalThis.location === "undefined") {
          globalThis.location = {
            protocol: "http:",
            hostname: "example.com",
            host: "example.com",
            port: "",
            href: "http://example.com/",
            origin: "http://example.com"
          };
        }
        "#
        .to_string(),
    );

    // Custom reporter stores results into a Promise stored at __wpt_results__.
    parts.push(
        r#"
        (function() {
          const results = [];
          let resolvePromise = null;
          globalThis.__wpt_results__ = new Promise(function(resolve) {
            resolvePromise = resolve;
          });
          function sanitize(s) {
            if (s == null) return null;
            return String(s).replace(/[\uD800-\uDFFF]/g, function(c) {
              return "\\u" + ("0000" + c.charCodeAt(0).toString(16)).slice(-4);
            });
          }
          add_result_callback(function(test) {
            results.push({
              status: test.status,
              name: sanitize(test.name),
              message: sanitize(test.message),
              stack: sanitize(test.stack)
            });
          });
          add_completion_callback(function(tests, harness_status) {
            resolvePromise({
              harness: {
                status: harness_status.status,
                message: sanitize(harness_status.message),
                stack: sanitize(harness_status.stack)
              },
              tests: results
            });
          });
        })();
        "#
        .to_string(),
    );

    // Inline META scripts and the test source.
    for line in test_source.lines() {
        if let Some(script_content) = resolve_meta_script(test_dir, line) {
            parts.push(script_content);
        }
    }
    parts.push(test_source);

    // Return a promise that resolves once tests complete.
    parts.push(
        r#"
        globalThis.__wpt_results__.then(function(data) {
          return JSON.stringify(data);
        }).catch(function(err) {
          return JSON.stringify({ harness: { status: 2, message: String(err.message || err), stack: String(err.stack || "") }, tests: [] });
        })
        "#
        .to_string(),
    );

    parts.join("\n")
}

fn run_wpt_test(test_relative: &str) -> WptRunResult {
    ensure_wpt_checkout();
    let previous = current_http_client_config();
    let mut config = previous.clone();
    config.allow_private_network = true;
    configure_http_client(config).expect("failed to configure http client");

    rquickjs_playground::host_runtime::configure_js_error_stack(true);
    let runtime =
        AsyncHostRuntime::new("wpt-fetch-test").expect("failed to create async host runtime");

    let payload = build_test_payload(test_relative);
    let handle = runtime
        .spawn(payload)
        .expect("failed to spawn WPT test task");
    let raw = handle.wait().expect("failed to wait for WPT test task");

    configure_http_client(previous).expect("failed to restore http client config");

    // Runtime-level eval errors are reported as {"ok":false,"error":...}
    if let Ok(runtime_err) = serde_json::from_str::<serde_json::Value>(&raw) {
        if runtime_err.get("ok").and_then(|v| v.as_bool()) == Some(false) {
            let message = runtime_err
                .get("error")
                .and_then(|v| v.as_str())
                .unwrap_or("runtime error")
                .to_string();
            return WptRunResult {
                harness: WptHarnessStatus {
                    status: 2,
                    message: Some(message),
                    stack: None,
                },
                tests: Vec::new(),
            };
        }
    }

    serde_json::from_str(&raw).unwrap_or_else(|e| {
        panic!(
            "failed to parse WPT result JSON: {}\nraw result ({} bytes): {}",
            e,
            raw.len(),
            &raw[..raw.len().min(2000)]
        )
    })
}

#[derive(Debug, Default)]
struct Summary {
    total: usize,
    passed: usize,
    failed: usize,
    harness_errors: usize,
    by_file: HashMap<String, (usize, usize, bool)>,
}

fn run_test_files(files: &[&str]) -> Summary {
    let mut summary = Summary::default();

    for file in files {
        println!("\n=== Running WPT fetch test: {} ===", file);
        let result = run_wpt_test(file);
        let harness_ok = result.harness.status == 0;
        if !harness_ok {
            summary.harness_errors += 1;
            println!(
                "HARNESS ERROR: status={} message={:?}",
                result.harness.status, result.harness.message
            );
        }

        let mut file_passed = 0usize;
        let mut file_failed = 0usize;
        for test in &result.tests {
            summary.total += 1;
            if test.status == 0 {
                summary.passed += 1;
                file_passed += 1;
            } else {
                summary.failed += 1;
                file_failed += 1;
                println!(
                    "FAIL [{}] {}: {}",
                    file,
                    test.name,
                    test.message.as_deref().unwrap_or("no message")
                );
            }
        }
        summary
            .by_file
            .insert(file.to_string(), (file_passed, file_failed, harness_ok));
        println!(
            "Result: passed={} failed={} harness_ok={}",
            file_passed, file_failed, harness_ok
        );
    }

    summary
}

fn print_summary(summary: &Summary) {
    println!("\n========== WPT fetch summary ==========");
    println!("Total test assertions: {}", summary.total);
    println!("Passed: {}", summary.passed);
    println!("Failed: {}", summary.failed);
    println!("Harness errors: {}", summary.harness_errors);
    if summary.total > 0 {
        println!(
            "Pass rate: {:.1}%",
            (summary.passed as f64 / summary.total as f64) * 100.0
        );
    }
    println!("\nPer file:");
    for (file, (passed, failed, harness_ok)) in &summary.by_file {
        println!(
            "  {}: passed={} failed={} harness_ok={}",
            file, passed, failed, harness_ok
        );
    }
    println!("=======================================\n");
}

// Client-side-only fetch tests that do not require a remote server.
const CLIENT_SIDE_TESTS: &[&str] = &[
    "fetch/api/headers/headers-basic.any.js",
    "fetch/api/headers/headers-casing.any.js",
    "fetch/api/headers/headers-combine.any.js",
    "fetch/api/headers/headers-errors.any.js",
    "fetch/api/headers/headers-forbidden-override.any.js",
    "fetch/api/headers/headers-no-cors.any.js",
    "fetch/api/headers/headers-normalize.any.js",
    "fetch/api/headers/headers-record.any.js",
    "fetch/api/headers/headers-structure.any.js",
    "fetch/api/headers/header-setcookie.any.js",
    "fetch/api/headers/header-values-normalize.any.js",
    "fetch/api/request/request-structure.any.js",
    "fetch/api/request/request-bad-port.any.js",
    "fetch/api/request/forbidden-method.any.js",
    "fetch/api/request/request-init-002.any.js",
    "fetch/api/request/request-init-contenttype.any.js",
    "fetch/api/request/request-init-priority.any.js",
    "fetch/api/request/request-headers.any.js",
    "fetch/api/request/request-consume-empty.any.js",
    "fetch/api/response/response-error.any.js",
    "fetch/api/response/response-consume-empty.any.js",
    "fetch/api/response/response-init-001.any.js",
    "fetch/api/response/response-init-contenttype.any.js",
    "fetch/api/response/response-static-error.any.js",
    "fetch/api/response/response-static-json.any.js",
    "fetch/api/response/response-static-redirect.any.js",
    "fetch/api/request/request-constructor-init-body-override.any.js",
    "fetch/api/body/formdata.any.js",
    "fetch/api/body/mime-type.any.js",
    "fetch/api/basic/response-null-body.any.js",
    "fetch/api/basic/header-value-combining.any.js",
    "fetch/api/basic/header-value-null-byte.any.js",
    "fetch/api/basic/historical.any.js",
    "fetch/api/basic/request-head.any.js",
    "fetch/api/basic/request-headers-nonascii.any.js",
    "fetch/api/basic/request-headers-case.any.js",
    "fetch/api/abort/request.any.js",
];

#[test]
fn wpt_fetch_client_side_tests() {
    let summary = run_test_files(CLIENT_SIDE_TESTS);
    print_summary(&summary);
}
