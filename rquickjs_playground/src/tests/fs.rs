use crate::tests::{run_async_script, run_async_script_with_fs};
use serde_json::Value;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

fn unique_temp_dir(prefix: &str) -> PathBuf {
    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("系统时间异常")
        .as_nanos();
    let dir = std::env::temp_dir().join(format!("rquickjs-{prefix}-{ts}"));
    std::fs::create_dir_all(&dir).expect("创建临时目录失败");
    dir
}

fn js_path(path: &Path) -> String {
    path.to_string_lossy().replace('\\', "/")
}

#[test]
fn fs_not_injected_by_default_runtime() {
    let script = r#"
      (async () => {
        let requireHasFs = false;
        if (typeof require === "function") {
          try {
            requireHasFs = typeof require("fs") === "object";
          } catch (_err) {
          }
        }
        return JSON.stringify({
          hasFs: typeof fs === "object",
          requireHasFs
        });
      })()
    "#;

    let result = run_async_script(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["hasFs"], false);
    assert_eq!(parsed["requireHasFs"], false);
}

#[test]
fn fs_only_async_apis_exposed() {
    let script = r#"
      (async () => {
        return JSON.stringify({
          hasFs: typeof fs === "object",
          hasPromisesReadFile: typeof fs.promises.readFile === "function",
          hasAsyncReadFile: typeof fs.readFile === "function",
          hasSyncReadFile: typeof fs.readFileSync === "function"
        });
      })()
    "#;

    let result = run_async_script_with_fs(script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["hasFs"], true);
    assert_eq!(parsed["hasPromisesReadFile"], true);
    assert_eq!(parsed["hasAsyncReadFile"], true);
    assert_eq!(parsed["hasSyncReadFile"], false);
}

#[test]
fn fs_read_write_append_utf8() {
    let root = unique_temp_dir("utf8");
    let file = js_path(&root.join("note.txt"));

    let script = format!(
        r#"
      (async () => {{
        await fs.promises.writeFile("{file}", "hello", "utf8");
        await fs.promises.appendFile("{file}", " world", "utf8");
        const text = await fs.promises.readFile("{file}", "utf8");
        return JSON.stringify({{ text }});
      }})()
    "#
    );

    let result = run_async_script_with_fs(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["text"], "hello world");

    let _ = std::fs::remove_dir_all(&root);
}

#[test]
fn fs_binary_read_write() {
    let root = unique_temp_dir("binary");
    let file = js_path(&root.join("bin.dat"));

    let script = format!(
        r#"
      (async () => {{
        await fs.promises.writeFile("{file}", new Uint8Array([1, 2, 3, 255]));
        const data = await fs.promises.readFile("{file}");
        return JSON.stringify({{
          isUint8Array: data instanceof Uint8Array,
          length: data.length,
          last: data[3]
        }});
      }})()
    "#
    );

    let result = run_async_script_with_fs(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["isUint8Array"], true);
    assert_eq!(parsed["length"], 4);
    assert_eq!(parsed["last"], 255);

    let _ = std::fs::remove_dir_all(&root);
}

#[test]
fn fs_concurrent_promises_read_write() {
    let root = unique_temp_dir("concurrent");
    let root_js = js_path(&root);

    let script = format!(
        r#"
      (async () => {{
        const base = "{root_js}";
        const total = 100;

        const writes = Array.from({{ length: total }}, (_, i) => {{
          const p = `${{base}}/f-${{i}}.txt`;
          return fs.promises.writeFile(p, `v-${{i}}`, "utf8");
        }});
        await Promise.all(writes);

        const reads = Array.from({{ length: total }}, (_, i) => {{
          const p = `${{base}}/f-${{i}}.txt`;
          return fs.promises.readFile(p, "utf8");
        }});
        const out = await Promise.all(reads);
        const ok = out.every((v, i) => v === `v-${{i}}`);
        return JSON.stringify({{ ok, count: out.length }});
      }})()
    "#
    );

    let result = run_async_script_with_fs(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["ok"], true);
    assert_eq!(parsed["count"], 100);

    let _ = std::fs::remove_dir_all(&root);
}

#[test]
fn fs_mkdir_readdir_stat() {
    let root = unique_temp_dir("tree");
    let root_js = js_path(&root);

    let script = format!(
        r#"
      (async () => {{
        const base = "{root_js}";
        await fs.promises.mkdir(base + "/a/b", {{ recursive: true }});
        await fs.promises.writeFile(base + "/a/one.txt", "1", "utf8");
        await fs.promises.writeFile(base + "/a/two.txt", "2", "utf8");

        const list = await fs.promises.readdir(base + "/a", {{ withFileTypes: true }});
        const names = list.map((x) => x.name).sort();
        const hasDir = list.some((x) => x.name === "b" && x.isDirectory());

        const st = await fs.promises.stat(base + "/a/one.txt");
        return JSON.stringify({{
          names,
          hasDir,
          fileIsFile: st.isFile(),
          fileSize: st.size
        }});
      }})()
    "#
    );

    let result = run_async_script_with_fs(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    let names = parsed["names"].as_array().expect("names 必须是数组");
    assert!(names.iter().any(|v| v == "b"));
    assert!(names.iter().any(|v| v == "one.txt"));
    assert!(names.iter().any(|v| v == "two.txt"));
    assert_eq!(parsed["hasDir"], true);
    assert_eq!(parsed["fileIsFile"], true);
    assert_eq!(parsed["fileSize"], 1);

    let _ = std::fs::remove_dir_all(&root);
}

#[test]
fn fs_require_promises_and_rm_flow() {
    let root = unique_temp_dir("flow");
    let root_js = js_path(&root);

    let script = format!(
        r#"
      (async () => {{
        const fsp = require("fs/promises");
        const base = "{root_js}";
        const src = base + "/src.txt";
        const copied = base + "/copied.txt";
        const renamed = base + "/renamed.txt";

        await fsp.writeFile(src, "abc", "utf8");
        await fsp.copyFile(src, copied);
        await fsp.rename(copied, renamed);
        await fsp.access(renamed);
        const real = await fsp.realpath(renamed);
        await fsp.unlink(src);
        await fsp.rm(renamed);
        await fsp.rm(base, {{ recursive: true, force: true }});

        let removedCode = "";
        try {{
          await fsp.access(renamed);
        }} catch (err) {{
          removedCode = err.code || "";
        }}

        return JSON.stringify({{
          hasRealpath: typeof real === "string" && real.length > 0,
          removedCode
        }});
      }})()
    "#
    );

    let result = run_async_script_with_fs(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    assert_eq!(parsed["hasRealpath"], true);
    assert_eq!(parsed["removedCode"], "ENOENT");
}

#[test]
fn fs_readdir_recursive_and_cp() {
    let root = unique_temp_dir("recursive");
    let root_js = js_path(&root);

    let script = format!(
        r#"
      (async () => {{
        const base = "{root_js}";
        const src = base + "/src";
        const dst = base + "/dst";
        await fs.promises.mkdir(src + "/deep/nested", {{ recursive: true }});
        await fs.promises.writeFile(src + "/a.txt", "A", "utf8");
        await fs.promises.writeFile(src + "/deep/b.txt", "B", "utf8");
        await fs.promises.writeFile(src + "/deep/nested/c.txt", "C", "utf8");

        const recursiveNames = await fs.promises.readdir(src, {{ recursive: true }});
        await fs.promises.cp(src, dst, {{ recursive: true }});
        const copied = await fs.promises.readFile(dst + "/deep/nested/c.txt", "utf8");

        return JSON.stringify({{
          hasA: recursiveNames.includes("a.txt"),
          hasB: recursiveNames.includes("deep/b.txt"),
          hasC: recursiveNames.includes("deep/nested/c.txt"),
          copied
        }});
      }})()
    "#
    );

    let result = run_async_script_with_fs(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["hasA"], true);
    assert_eq!(parsed["hasB"], true);
    assert_eq!(parsed["hasC"], true);
    assert_eq!(parsed["copied"], "C");

    let _ = std::fs::remove_dir_all(&root);
}

#[test]
fn fs_open_truncate_and_link() {
    let root = unique_temp_dir("open");
    let root_js = js_path(&root);

    let script = format!(
        r#"
      (async () => {{
        const base = "{root_js}";
        const file = base + "/data.txt";
        const hard = base + "/data-hard.txt";

        const handle = await fs.promises.open(file, "w+");
        await handle.writeFile("abcdef", "utf8");
        const readBuf = new Uint8Array(3);
        await handle.read(readBuf, 0, 3, 2);
        await handle.truncate(4);
        await handle.close();

        await fs.promises.link(file, hard);
        const lstat = await fs.promises.lstat(hard);
        const text = await fs.promises.readFile(file, "utf8");

        return JSON.stringify({{
          readChunk: String.fromCharCode(...readBuf),
          text,
          hardIsFile: lstat.isFile()
        }});
      }})()
    "#
    );

    let result = run_async_script_with_fs(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["readChunk"], "cde");
    assert_eq!(parsed["text"], "abcd");
    assert_eq!(parsed["hardIsFile"], true);

    let _ = std::fs::remove_dir_all(&root);
}

#[test]
fn fs_mkdtemp_and_utimes() {
    let root = unique_temp_dir("mkdtemp");
    let prefix = js_path(&root.join("tmp-"));

    let script = format!(
        r#"
      (async () => {{
        const dir = await fs.promises.mkdtemp("{prefix}");
        const file = dir + "/touch.txt";
        await fs.promises.writeFile(file, "ok", "utf8");
        await fs.promises.utimes(file, 1710000000, 1710000010);
        await fs.promises.chmod(file, 0o644);
        const st = await fs.promises.stat(file);
        return JSON.stringify({{
          dir,
          size: st.size,
          isFile: st.isFile()
        }});
      }})()
    "#
    );

    let result = run_async_script_with_fs(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert!(parsed["dir"].as_str().unwrap_or("").contains("tmp-"));
    assert_eq!(parsed["size"], 2);
    assert_eq!(parsed["isFile"], true);

    let _ = std::fs::remove_dir_all(&root);
}

#[test]
fn fs_create_read_stream() {
    let root = unique_temp_dir("stream-read");
    let root_js = js_path(&root);

    let script = format!(
        r#"
      (async () => {{
        const file = "{root_js}/read.txt";
        await fs.promises.writeFile(file, "hello-stream-reader", "utf8");
        const rs = fs.createReadStream(file, {{ encoding: "utf8", highWaterMark: 5 }});
        const chunks = [];
        await new Promise((resolve, reject) => {{
          rs.on("data", (chunk) => chunks.push(chunk));
          rs.on("end", resolve);
          rs.on("error", reject);
        }});
        return JSON.stringify({{
          chunkCount: chunks.length,
          text: chunks.join("")
        }});
      }})()
    "#
    );

    let result = run_async_script_with_fs(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["text"], "hello-stream-reader");
    assert!(parsed["chunkCount"].as_u64().unwrap_or(0) >= 3);

    let _ = std::fs::remove_dir_all(&root);
}

#[test]
fn fs_create_write_stream_and_pipe() {
    let root = unique_temp_dir("stream-write");
    let root_js = js_path(&root);

    let script = format!(
        r#"
      (async () => {{
        const src = "{root_js}/src.txt";
        const dst = "{root_js}/dst.txt";
        await fs.promises.writeFile(src, "pipe-source-content", "utf8");

        const ws = fs.createWriteStream(dst);
        await new Promise((resolve, reject) => {{
          ws.on("finish", resolve);
          ws.on("error", reject);
          ws.write("hello");
          ws.write("-");
          ws.end("world");
        }});

        const first = await fs.promises.readFile(dst, "utf8");

        const rs = fs.createReadStream(src);
        const ws2 = fs.createWriteStream(dst, {{ flags: "w" }});
        await new Promise((resolve, reject) => {{
          ws2.on("finish", resolve);
          ws2.on("error", reject);
          rs.on("error", reject);
          rs.pipe(ws2);
        }});

        const second = await fs.promises.readFile(dst, "utf8");
        return JSON.stringify({{ first, second }});
      }})()
    "#
    );

    let result = run_async_script_with_fs(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert_eq!(parsed["first"], "hello-world");
    assert_eq!(parsed["second"], "pipe-source-content");

    let _ = std::fs::remove_dir_all(&root);
}

#[test]
fn fs_opendir_async_iter() {
    let root = unique_temp_dir("opendir");
    let root_js = js_path(&root);

    let script = format!(
        r#"
      (async () => {{
        const base = "{root_js}";
        await fs.promises.writeFile(base + "/a.txt", "A", "utf8");
        await fs.promises.writeFile(base + "/b.txt", "B", "utf8");
        const dir = await fs.promises.opendir(base);
        const names = [];
        for await (const ent of dir) {{
          names.push(ent.name);
        }}
        await dir.close();
        names.sort();
        return JSON.stringify({{ names }});
      }})()
    "#
    );

    let result = run_async_script_with_fs(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");
    let names = parsed["names"].as_array().expect("names 必须是数组");

    assert!(names.iter().any(|v| v == "a.txt"));
    assert!(names.iter().any(|v| v == "b.txt"));

    let _ = std::fs::remove_dir_all(&root);
}

#[test]
fn fs_watch_detects_change() {
    let root = unique_temp_dir("watch");
    let root_js = js_path(&root);

    let script = format!(
        r#"
      (async () => {{
        const file = "{root_js}/watch.txt";
        await fs.promises.writeFile(file, "v1", "utf8");

        const events = [];
        const watcher = fs.watch(file, (eventType, filename) => {{
          events.push({{ eventType, filename }});
        }});

        await Promise.resolve();
        await Promise.resolve();
        await fs.promises.writeFile(file, "v2", "utf8");
        await Promise.resolve();
        await Promise.resolve();
        await Promise.resolve();
        watcher.close();

        return JSON.stringify({{
          count: events.length,
          firstType: events[0] ? events[0].eventType : "",
          firstName: events[0] ? events[0].filename : ""
        }});
      }})()
    "#
    );

    let result = run_async_script_with_fs(&script).expect("执行脚本失败");
    let parsed: Value = serde_json::from_str(&result).expect("解析结果失败");

    assert!(parsed["count"].as_u64().unwrap_or(0) >= 1);
    assert_eq!(parsed["firstType"], "change");
    assert_eq!(parsed["firstName"], "watch.txt");

    let _ = std::fs::remove_dir_all(&root);
}
