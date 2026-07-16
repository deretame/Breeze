//! Test262 Temporal conformance runner.
//!
//! Requires a local checkout at `test262/` (gitignored):
//!   git clone --depth 1 --filter=blob:none --sparse https://github.com/tc39/test262.git test262
//!   cd test262 && git sparse-checkout set harness test/built-ins/Temporal test/intl402/Temporal
//!
//! Run:
//!   cargo test --test test262_temporal -- --nocapture
//!
//! Env filters:
//!   TEST262_FILTER=PlainDate        # path substring filter
//!   TEST262_LIMIT=200               # max files to run
//!   TEST262_INCLUDE_INTL402=1       # also run intl402 Temporal tests
//!   TEST262_CASE_TIMEOUT_MS=15000   # per-file timeout (default 15000)

use rquickjs_playground::host_runtime::AsyncHostRuntime;
use serde::{Deserialize, Serialize};
use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::OnceLock;
use std::sync::mpsc;
use std::thread;
use std::time::{Duration, Instant};

#[derive(Debug, Clone, Default)]
struct Frontmatter {
    includes: Vec<String>,
    features: Vec<String>,
    flags: Vec<String>,
    negative_type: Option<String>,
    negative_phase: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct FileResult {
    path: String,
    status: String,
    message: Option<String>,
}

fn test262_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("test262")
}

fn ensure_test262() {
    let root = test262_root();
    if !root.join("harness/assert.js").is_file() {
        panic!(
            "Test262 checkout not found at {}. \
             Run: git clone --depth 1 --filter=blob:none --sparse https://github.com/tc39/test262.git {} \
             && cd {} && git sparse-checkout set harness test/built-ins/Temporal test/intl402/Temporal",
            root.display(),
            root.display(),
            root.display()
        );
    }
}

fn read_harness(name: &str) -> String {
    fs::read_to_string(test262_root().join("harness").join(name))
        .unwrap_or_else(|e| panic!("failed to read harness/{name}: {e}"))
}

fn parse_frontmatter(source: &str) -> Frontmatter {
    let mut fm = Frontmatter::default();
    let start = match source.find("/*---") {
        Some(i) => i + 5,
        None => return fm,
    };
    let end = match source[start..].find("---*/") {
        Some(i) => start + i,
        None => return fm,
    };
    let body = &source[start..end];
    for line in body.lines() {
        let line = line.trim();
        if let Some(rest) = line.strip_prefix("includes:") {
            fm.includes = parse_yaml_list(rest);
        } else if let Some(rest) = line.strip_prefix("features:") {
            fm.features = parse_yaml_list(rest);
        } else if let Some(rest) = line.strip_prefix("flags:") {
            fm.flags = parse_yaml_list(rest);
        } else if line.starts_with("negative:") {
            // multi-line negative block handled below
        } else if let Some(rest) = line.strip_prefix("type:") {
            // only meaningful inside negative, but keep last
            fm.negative_type = Some(rest.trim().to_string());
        } else if let Some(rest) = line.strip_prefix("phase:") {
            fm.negative_phase = Some(rest.trim().to_string());
        }
    }
    // Better negative parse: if block contains negative:
    if body.contains("negative:") {
        for line in body.lines() {
            let t = line.trim();
            if let Some(rest) = t.strip_prefix("type:") {
                fm.negative_type = Some(rest.trim().to_string());
            } else if let Some(rest) = t.strip_prefix("phase:") {
                fm.negative_phase = Some(rest.trim().to_string());
            }
        }
        // If negative present but type missing, mark as generic negative
        if fm.negative_type.is_none() {
            fm.negative_type = Some("Error".to_string());
        }
    }
    fm
}

fn parse_yaml_list(raw: &str) -> Vec<String> {
    let s = raw.trim();
    let s = s
        .strip_prefix('[')
        .and_then(|x| x.strip_suffix(']'))
        .unwrap_or(s);
    s.split(',')
        .map(|p| p.trim().trim_matches('\'').trim_matches('"').to_string())
        .filter(|p| !p.is_empty())
        .collect()
}

fn collect_test_files(dir: &Path, out: &mut Vec<PathBuf>) {
    let entries = match fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return,
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.is_dir() {
            collect_test_files(&path, out);
        } else if path.extension().and_then(|e| e.to_str()) == Some("js") {
            out.push(path);
        }
    }
}

fn harness_cache() -> &'static std::collections::HashMap<String, String> {
    static CACHE: OnceLock<std::collections::HashMap<String, String>> = OnceLock::new();
    CACHE.get_or_init(|| {
        let mut m = std::collections::HashMap::new();
        for name in [
            "assert.js",
            "sta.js",
            "compareArray.js",
            "compareIterator.js",
            "propertyHelper.js",
            "temporalHelpers.js",
            "isConstructor.js",
            "deepEqual.js",
            "nans.js",
            "decimalToHexString.js",
            "nativeFunctionMatcher.js",
            "wellKnownIntrinsicObjects.js",
            "typeCoercion.js",
            "proxyTrapsHelper.js",
            "doneprintHandle.js",
            "fnGlobalObject.js",
            "testIntl.js",
        ] {
            let path = test262_root().join("harness").join(name);
            if path.is_file() {
                m.insert(name.to_string(), fs::read_to_string(path).unwrap());
            }
        }
        m
    })
}

fn build_payload(_test_path: &Path, source: &str, fm: &Frontmatter) -> String {
    let mut parts: Vec<String> = Vec::new();

    // Shell-like globals used by some harness helpers.
    parts.push(
        r#"
        if (typeof globalThis.$262 === "undefined") {
          globalThis.$262 = {
            createRealm() { throw new Error("$262.createRealm not supported"); },
            detachArrayBuffer() { throw new Error("$262.detachArrayBuffer not supported"); },
            evalScript(src) { return eval(src); },
            gc() {},
            global: globalThis,
            IsHTMLDDA: undefined,
            agent: undefined
          };
        }
        if (typeof globalThis.$DONOTEVALUATE === "undefined") {
          globalThis.$DONOTEVALUATE = function() {};
        }
        "#
        .to_string(),
    );

    let cache = harness_cache();
    // Required harness files.
    for req in ["assert.js", "sta.js"] {
        parts.push(cache.get(req).cloned().unwrap_or_else(|| read_harness(req)));
    }
    // Includes from frontmatter.
    let mut seen = HashSet::new();
    seen.insert("assert.js".to_string());
    seen.insert("sta.js".to_string());
    for inc in &fm.includes {
        if seen.insert(inc.clone()) {
            if let Some(src) = cache.get(inc) {
                parts.push(src.clone());
            } else {
                parts.push(read_harness(inc));
            }
        }
    }

    let is_module = fm.flags.iter().any(|f| f == "module");
    let is_async = fm.flags.iter().any(|f| f == "async");
    let only_strict = fm.flags.iter().any(|f| f == "onlyStrict");
    let negative = fm.negative_type.clone();
    let negative_phase = fm
        .negative_phase
        .clone()
        .unwrap_or_else(|| "runtime".into());

    // Result harness.
    parts.push(
        r#"
        globalThis.__test262_result__ = null;
        globalThis.__test262_done__ = false;
        function __test262_finish(status, message) {
          if (globalThis.__test262_done__) return;
          globalThis.__test262_done__ = true;
          globalThis.__test262_result__ = { status: status, message: message == null ? null : String(message) };
        }
        "#
        .to_string(),
    );

    if is_async {
        parts.push(
            r#"
            globalThis.$DONE = function(error) {
              if (error) {
                __test262_finish("fail", error && (error.stack || error.message || error));
              } else {
                __test262_finish("pass", null);
              }
            };
            "#
            .to_string(),
        );
    }

    let test_body = if only_strict {
        format!("\"use strict\";\n{source}")
    } else {
        source.to_string()
    };

    // Strip frontmatter so it is not executed.
    let test_body = strip_frontmatter(&test_body);

    if is_module {
        // QuickJS module support via rquickjs is limited here; skip modules as fail-skip.
        parts.push(
            r#"
            __test262_finish("skip", "module tests are not supported in this runner");
            "#
            .to_string(),
        );
    } else if let Some(neg_type) = negative {
        let phase = negative_phase;
        // Call with globalThis so tests using bare `this` (e.g. prop-desc) work
        // under QuickJS strict mode.
        parts.push(format!(
            r#"
            (function() {{
              var expectedType = {neg_type:?};
              var phase = {phase:?};
              try {{
                (function() {{
{test_body}
                }}).call(globalThis);
                if (phase === "parse") {{
                  __test262_finish("fail", "expected parse error but script parsed");
                }} else {{
                  __test262_finish("fail", "expected " + expectedType + " but no exception was thrown");
                }}
              }} catch (e) {{
                var name = e && e.name ? e.name : "";
                var ok = false;
                if (expectedType === "Error") ok = e instanceof Error;
                else ok = name === expectedType || (typeof e === "object" && e !== null && e.constructor && e.constructor.name === expectedType);
                if (ok) __test262_finish("pass", null);
                else __test262_finish("fail", "expected " + expectedType + " got " + name + ": " + (e && (e.message || e)));
              }}
            }})();
            "#
        ));
    } else {
        parts.push(format!(
            r#"
            (function() {{
              try {{
                (function() {{
{test_body}
                }}).call(globalThis);
                if (typeof $DONE === "function") {{
                  // async test will call $DONE
                }} else {{
                  __test262_finish("pass", null);
                }}
              }} catch (e) {{
                __test262_finish("fail", (e && (e.stack || e.message || String(e))) || String(e));
              }}
            }})();
            "#
        ));
    }

    // Return result promise for async host runtime.
    parts.push(
        r#"
        (async function() {
          if (typeof $DONE === "function" && !globalThis.__test262_done__) {
            // Wait briefly for async tests.
            for (var i = 0; i < 200 && !globalThis.__test262_done__; i++) {
              await new Promise(function(r){ setTimeout(r, 5); });
            }
            if (!globalThis.__test262_done__) {
              __test262_finish("fail", "async test timed out waiting for $DONE");
            }
          }
          return JSON.stringify(globalThis.__test262_result__ || { status: "fail", message: "no result" });
        })()
        "#
        .to_string(),
    );

    parts.join("\n")
}

fn strip_frontmatter(source: &str) -> String {
    if let Some(start) = source.find("/*---") {
        if let Some(rel_end) = source[start..].find("---*/") {
            let end = start + rel_end + 5;
            let mut out = String::new();
            out.push_str(&source[..start]);
            out.push_str(&source[end..]);
            return out;
        }
    }
    source.to_string()
}

fn case_timeout() -> Duration {
    let ms = std::env::var("TEST262_CASE_TIMEOUT_MS")
        .ok()
        .and_then(|s| s.parse::<u64>().ok())
        .unwrap_or(15_000);
    Duration::from_millis(ms.max(1_000))
}

fn run_one(test_path: &Path) -> FileResult {
    let rel = test_path
        .strip_prefix(test262_root())
        .unwrap_or(test_path)
        .to_string_lossy()
        .replace('\\', "/");
    let path = test_path.to_path_buf();
    let timeout = case_timeout();
    let (tx, rx) = mpsc::channel();
    thread::spawn(move || {
        let _ = tx.send(run_one_inner(&path));
    });
    match rx.recv_timeout(timeout) {
        Ok(result) => result,
        Err(mpsc::RecvTimeoutError::Timeout) => FileResult {
            path: rel,
            status: "fail".into(),
            message: Some(format!("case timed out after {}ms", timeout.as_millis())),
        },
        Err(mpsc::RecvTimeoutError::Disconnected) => FileResult {
            path: rel,
            status: "fail".into(),
            message: Some("case worker disconnected".into()),
        },
    }
}

fn run_one_inner(test_path: &Path) -> FileResult {
    let rel = test_path
        .strip_prefix(test262_root())
        .unwrap_or(test_path)
        .to_string_lossy()
        .replace('\\', "/");
    let source = match fs::read_to_string(test_path) {
        Ok(s) => s,
        Err(e) => {
            return FileResult {
                path: rel,
                status: "fail".into(),
                message: Some(format!("read error: {e}")),
            };
        }
    };
    let fm = parse_frontmatter(&source);

    // Skip features we know we cannot support.
    if fm.features.iter().any(|f| {
        matches!(
            f.as_str(),
            "Atomics" | "SharedArrayBuffer" | "Temporal-proposal" // keep Temporal
        )
    }) {
        // still allow Temporal
    }

    let payload = build_payload(test_path, &source, &fm);
    let runtime = match AsyncHostRuntime::new("test262-temporal") {
        Ok(rt) => rt,
        Err(e) => {
            return FileResult {
                path: rel,
                status: "fail".into(),
                message: Some(format!("runtime init: {e}")),
            };
        }
    };
    let handle = match runtime.spawn(payload) {
        Ok(h) => h,
        Err(e) => {
            return FileResult {
                path: rel,
                status: "fail".into(),
                message: Some(format!("spawn: {e}")),
            };
        }
    };
    let raw = match handle.wait() {
        Ok(r) => r,
        Err(e) => {
            return FileResult {
                path: rel,
                status: "fail".into(),
                message: Some(format!("wait: {e}")),
            };
        }
    };

    // Runtime error wrapper
    if let Ok(v) = serde_json::from_str::<serde_json::Value>(&raw) {
        if v.get("ok").and_then(|x| x.as_bool()) == Some(false) {
            return FileResult {
                path: rel,
                status: "fail".into(),
                message: Some(
                    v.get("error")
                        .and_then(|e| e.as_str())
                        .unwrap_or("runtime error")
                        .to_string(),
                ),
            };
        }
        if let Some(status) = v.get("status").and_then(|s| s.as_str()) {
            return FileResult {
                path: rel,
                status: status.to_string(),
                message: v
                    .get("message")
                    .and_then(|m| m.as_str())
                    .map(|s| s.to_string()),
            };
        }
    }

    FileResult {
        path: rel,
        status: "fail".into(),
        message: Some(format!(
            "unparseable result: {}",
            &raw[..raw.len().min(300)]
        )),
    }
}

fn env_filter() -> Option<String> {
    std::env::var("TEST262_FILTER")
        .ok()
        .filter(|s| !s.is_empty())
}

fn env_limit() -> Option<usize> {
    std::env::var("TEST262_LIMIT")
        .ok()
        .and_then(|s| s.parse().ok())
}

fn include_intl402() -> bool {
    matches!(
        std::env::var("TEST262_INCLUDE_INTL402").as_deref(),
        Ok("1") | Ok("true") | Ok("TRUE")
    )
}

fn expected_failures() -> HashSet<String> {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("tests/test262_temporal_expected_failures.txt");
    let mut set = HashSet::new();
    if let Ok(text) = fs::read_to_string(path) {
        for line in text.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            set.insert(line.replace('\\', "/"));
        }
    }
    set
}

fn normalize_test_rel(path: &Path) -> String {
    let rel = path
        .strip_prefix(test262_root().join("test"))
        .or_else(|_| path.strip_prefix(test262_root()))
        .unwrap_or(path)
        .to_string_lossy()
        .replace('\\', "/");
    rel.strip_prefix("test/").unwrap_or(&rel).to_string()
}

#[test]
fn test262_temporal_built_ins() {
    ensure_test262();
    rquickjs_playground::host_runtime::configure_js_error_stack(true);

    let mut files: Vec<PathBuf> = Vec::new();
    collect_test_files(&test262_root().join("test/built-ins/Temporal"), &mut files);
    if include_intl402() {
        collect_test_files(&test262_root().join("test/intl402/Temporal"), &mut files);
    }
    files.sort();

    if let Some(filter) = env_filter() {
        files.retain(|p| p.to_string_lossy().replace('\\', "/").contains(&filter));
    }
    if let Some(limit) = env_limit() {
        files.truncate(limit);
    }

    assert!(
        !files.is_empty(),
        "no Test262 Temporal files found (checkout incomplete?)"
    );

    let expected = expected_failures();
    let started = Instant::now();
    let mut passed = 0usize;
    let mut failed = 0usize;
    let mut skipped = 0usize;
    let mut expected_failed = 0usize;
    let mut unexpected_failures: Vec<FileResult> = Vec::new();
    let mut unexpected_passes: Vec<String> = Vec::new();

    let case_timeout_ms = case_timeout().as_millis();
    println!(
        "Running {} Test262 Temporal files... (case timeout {}ms)",
        files.len(),
        case_timeout_ms
    );

    for (i, path) in files.iter().enumerate() {
        let rel_full = path
            .strip_prefix(test262_root())
            .unwrap_or(path)
            .to_string_lossy()
            .replace('\\', "/");
        let rel_key = normalize_test_rel(path);
        let case_started = Instant::now();
        let result = run_one(path);
        let case_ms = case_started.elapsed().as_millis();
        let is_expected = expected.contains(&rel_key)
            || expected.contains(&rel_full)
            || expected.contains(&format!("test/{rel_key}"));
        match result.status.as_str() {
            "pass" => {
                passed += 1;
                if is_expected {
                    unexpected_passes.push(rel_key);
                }
            }
            "skip" => skipped += 1,
            _ => {
                if is_expected {
                    expected_failed += 1;
                } else {
                    failed += 1;
                    unexpected_failures.push(result.clone());
                    println!(
                        "FAIL {} :: {} ({}ms)",
                        rel_full,
                        result.message.as_deref().unwrap_or(""),
                        case_ms
                    );
                }
            }
        }
        if (i + 1) % 100 == 0 {
            println!(
                "... {}/{} passed={} unexpected_fail={} expected_fail={} skipped={} elapsed={:.1}s",
                i + 1,
                files.len(),
                passed,
                failed,
                expected_failed,
                skipped,
                started.elapsed().as_secs_f64()
            );
        }
    }

    let total = passed + failed + expected_failed + skipped;
    let rate = if passed + failed + expected_failed > 0 {
        (passed as f64 / (passed + failed + expected_failed) as f64) * 100.0
    } else {
        0.0
    };

    println!("\n========== Test262 Temporal summary ==========");
    println!("Files: {total}");
    println!("Passed: {passed}");
    println!("Unexpected failed: {failed}");
    println!("Expected failed: {expected_failed}");
    println!("Skipped: {skipped}");
    println!("Pass rate (incl. expected fails as non-pass): {rate:.1}%");
    println!("Elapsed: {:.1}s", started.elapsed().as_secs_f64());
    if !unexpected_failures.is_empty() {
        println!("\nUnexpected failures:");
        for f in unexpected_failures.iter().take(40) {
            println!("  {} :: {}", f.path, f.message.as_deref().unwrap_or(""));
        }
    }
    if !unexpected_passes.is_empty() {
        println!(
            "\nNote: {} expected-failure tests now pass (can remove from list)",
            unexpected_passes.len()
        );
    }
    println!("==============================================\n");

    let summary = serde_json::json!({
        "total": total,
        "passed": passed,
        "unexpected_failed": failed,
        "expected_failed": expected_failed,
        "skipped": skipped,
        "pass_rate": rate,
        "unexpected_failures": unexpected_failures,
        "unexpected_passes": unexpected_passes,
    });
    let out =
        PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("target/test262_temporal_results.json");
    let _ = fs::create_dir_all(out.parent().unwrap());
    let _ = fs::write(&out, serde_json::to_string_pretty(&summary).unwrap());

    assert!(
        failed == 0,
        "Unexpected Test262 Temporal failures: {failed}/{total} (see target/test262_temporal_results.json)"
    );
}
