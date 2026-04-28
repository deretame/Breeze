use rquickjs_playground::AsyncHostRuntime;
use serde_json::Value;
use std::path::PathBuf;
use std::time::{Instant, SystemTime, UNIX_EPOCH};

fn unique_temp_dir(prefix: &str) -> PathBuf {
    let ts = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("系统时间异常")
        .as_nanos();
    let dir = std::env::temp_dir().join(format!("rquickjs-{prefix}-{ts}"));
    std::fs::create_dir_all(&dir).expect("创建临时目录失败");
    dir
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let root = unique_temp_dir("fs-concurrent-example");
    let root_js = root.to_string_lossy().replace('\\', "/");

    let script = format!(
        r#"
        (async () => {{
          const base = {root_js:?};
          const total = 100;

          const now = () => Date.now();

          const t1 = now();
          for (let i = 0; i < total; i += 1) {{
            const p = `${{base}}/s-${{i}}.txt`;
            await fs.promises.writeFile(p, `value-${{i}}`, "utf8");
          }}
          const serialMs = now() - t1;

          const t2 = now();
          await Promise.all(Array.from({{ length: total }}, (_, i) => {{
            const p = `${{base}}/c-${{i}}.txt`;
            return fs.promises.writeFile(p, `value-${{i}}`, "utf8");
          }}));
          const concurrentMs = now() - t2;

          return JSON.stringify({{ total, serialMs, concurrentMs }});
        }})()
        "#
    );

    let host = AsyncHostRuntime::new("example-concurrent-file-ops")?;
    let start = Instant::now();
    let raw = host.spawn(&script)?.wait()?;
    let rust_elapsed = start.elapsed().as_millis();

    let parsed: Value = serde_json::from_str(&raw)?;
    println!("result: {raw}");
    println!("rust_elapsed_ms: {rust_elapsed}");
    println!(
        "concurrency_gain: {}",
        parsed["serialMs"].as_i64().unwrap_or_default()
            - parsed["concurrentMs"].as_i64().unwrap_or_default()
    );

    let _ = std::fs::remove_dir_all(root);
    Ok(())
}
