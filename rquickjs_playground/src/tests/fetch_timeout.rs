//! 插件模式下载超时问题排查测试。
//!
//! 目标：对比「JS 运行时 fetch（插件模式走的路径）」与「直接 reqwest（Rust 直连路径）」
//! 在相同 timeout 下对慢速服务器的行为差异，验证以下疑点：
//!
//! 1. JS 侧 fetch 的 timeout 是「墙钟时间」（从 dispatch 开始计时），
//!    原生 reqwest 的 timeout 是「请求真正发出后开始计时」→ 双重超时竞态。
//! 2. 插件路径在请求发出前有额外开销（桥接、DNS 预检、信号量），会吃掉超时预算。
//! 3. 重定向（read-image → hath.network）的跟随与总超时口径。
//! 4. 大响应体走 native buffer offload 的开销。
//!
//! 均为本机 127.0.0.1 慢速服务器，不依赖外网。

use crate::tests::run_async_script;
use crate::web_runtime::{
    BuildHttpClientOptions, HttpClientConfig, build_http_client_ex,
};
use serde_json::Value;
use std::sync::mpsc;
use std::thread;
use std::time::{Duration, Instant};
use tiny_http::{Header, Response, Server};

// ---------- 测试用慢速服务器 ----------

fn parse_path_num(url: &str, prefix: &str) -> Option<u64> {
    url.strip_prefix(prefix)?.split('?').next()?.parse().ok()
}

/// 分块慢速发送的 reader：每读一次睡 delay 毫秒，发 chunk 字节。
/// 用来模拟真实网络上 body 分块慢慢到达的情况。
struct TrickleReader {
    remaining: usize,
    chunk: usize,
    delay: Duration,
}
impl std::io::Read for TrickleReader {
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize> {
        if self.remaining == 0 {
            return Ok(0);
        }
        thread::sleep(self.delay);
        let n = self.chunk.min(self.remaining).min(buf.len());
        buf[..n].fill(0xAB);
        self.remaining -= n;
        Ok(n)
    }
}

/// 端点：
/// - `/delay/{ms}`          延迟 ms 毫秒后返回小 JSON
/// - `/redirect/{ms}`       302 跳转到 `/delay/{ms}`
/// - `/large/{size}`        直接返回 size 字节的二进制（无延迟）
fn spawn_delay_server() -> (String, mpsc::Sender<()>, thread::JoinHandle<()>) {
    let server = Server::http("127.0.0.1:0").expect("start server");
    let addr = format!("http://{}", server.server_addr());
    let addr_inner = addr.clone();
    let addr_log = addr.clone();
    let (tx, rx) = mpsc::channel::<()>();
    eprintln!("[srv] START {addr}");
    let handle = thread::spawn(move || {
        let mut count: u32 = 0;
        loop {
            if rx.try_recv().is_ok() {
                eprintln!("[srv] STOP {addr_log}");
                break;
            }
            // 小轮询间隔，避免给请求带来最多 200ms 的额外延迟
            match server.recv_timeout(Duration::from_millis(5)) {
                Ok(Some(mut request)) => {
                    count += 1;
                    let url = request.url().to_string();
                    eprintln!("[srv] {addr_log} ACCEPT #{count} url={url}");
                    if let Some(ms) = parse_path_num(&url, "/delay/") {
                        thread::sleep(Duration::from_millis(ms));
                        let body = format!(r#"{{"ok":true,"ms":{}}}"#, ms);
                        let r = request.respond(Response::from_string(body).with_status_code(200));
                        eprintln!("[srv] {addr_log} RESP #{count} delay={ms}ms -> {:?}", r.is_ok());
                        continue;
                    }
                    if let Some(ms) = parse_path_num(&url, "/redirect/") {
                        let location = format!("{}/delay/{}", addr_inner, ms);
                        let resp = Response::empty(302).with_header(
                            Header::from_bytes(b"Location".as_slice(), location.as_bytes())
                                .expect("location header"),
                        );
                        let r = request.respond(resp);
                        eprintln!("[srv] {addr_log} RESP #{count} redirect->delay/{ms} -> {:?}", r.is_ok());
                        continue;
                    }
                    if let Some(size) = parse_path_num(&url, "/large/") {
                        let bytes = vec![0xABu8; size as usize];
                        let _ = request.respond(
                            Response::from_data(bytes)
                                .with_status_code(200)
                                .with_header(
                                    Header::from_bytes(
                                        b"Content-Type".as_slice(),
                                        b"application/octet-stream".as_slice(),
                                    )
                                    .expect("ct header"),
                                ),
                        );
                        eprintln!("[srv] {addr_log} RESP #{count} large/{size}");
                        continue;
                    }
                    // /trickle/{size}/{chunk}/{delay}：分块慢速发送
                    if let Some(rest) = url.strip_prefix("/trickle/") {
                        let parts: Vec<u64> = rest
                            .split('/')
                            .take(3)
                            .filter_map(|s| s.parse().ok())
                            .collect();
                        if parts.len() == 3 {
                            let (size, chunk, delay) = (parts[0], parts[1], parts[2]);
                            let reader = TrickleReader {
                                remaining: size as usize,
                                chunk: chunk.max(1) as usize,
                                delay: Duration::from_millis(delay),
                            };
                            let headers = vec![Header::from_bytes(
                                b"Content-Type".as_slice(),
                                b"application/octet-stream".as_slice(),
                            )
                            .expect("ct header")];
                            let resp = Response::new(
                                tiny_http::StatusCode(200),
                                headers,
                                Box::new(reader),
                                Some(size as usize),
                                None,
                            );
                            let _ = request.respond(resp);
                            eprintln!(
                                "[srv] {addr_log} RESP #{count} trickle size={size} chunk={chunk} delay={delay}ms"
                            );
                            continue;
                        }
                    }
                    let _ = request.respond(
                        Response::from_string(r#"{"ok":true}"#).with_status_code(200),
                    );
                }
                Ok(None) => {
                    // tiny_http 的 recv_timeout 超时返回 Ok(None) 表示「无新请求」，
                    // 并非服务器关闭，必须继续轮询；否则服务器线程会误退出。
                    // 继续循环等待。
                }
                Err(_) => {}
            }
        }
    });
    (addr, tx, handle)
}

// ---------- JS 侧：带/不带 timeout 的 fetch，返回耗时与结果 ----------

fn js_fetch(url: &str, timeout_ms: u64, pre_delay_ms: u64) -> Value {
    let script = format!(
        r#"
        (async () => {{
          const t0 = Date.now();
          if ({pre_delay_ms} > 0) {{
            await new Promise(r => setTimeout(r, {pre_delay_ms}));
          }}
          const t1 = Date.now();
          try {{
            const res = await fetch("{url}", {{ timeout: {timeout_ms} }});
            const t2 = Date.now();
            return JSON.stringify({{ ok: true, preMs: t1 - t0, fetchMs: t2 - t1, totalMs: t2 - t0, status: res.status }});
          }} catch (e) {{
            const t2 = Date.now();
            return JSON.stringify({{
              ok: false,
              preMs: t1 - t0,
              fetchMs: t2 - t1,
              totalMs: t2 - t0,
              name: String(e && e.name || e),
              message: String(e && e.message || "")
            }});
          }}
        }})()
        "#,
        url = url,
        timeout_ms = timeout_ms,
        pre_delay_ms = pre_delay_ms
    );
    let result = run_async_script(&script).expect("failed to execute script");
    serde_json::from_str(&result).expect("failed to parse result")
}

fn js_fetch_no_timeout(url: &str, pre_delay_ms: u64) -> Value {
    let script = format!(
        r#"
        (async () => {{
          const t0 = Date.now();
          if ({pre_delay_ms} > 0) {{
            await new Promise(r => setTimeout(r, {pre_delay_ms}));
          }}
          const t1 = Date.now();
          try {{
            const res = await fetch("{url}");
            const t2 = Date.now();
            return JSON.stringify({{ ok: true, preMs: t1 - t0, fetchMs: t2 - t1, totalMs: t2 - t0, status: res.status }});
          }} catch (e) {{
            const t2 = Date.now();
            return JSON.stringify({{ ok: false, preMs: t1 - t0, fetchMs: t2 - t1, totalMs: t2 - t0, name: String(e && e.name || e), message: String(e && e.message || "") }});
          }}
        }})()
        "#,
        url = url,
        pre_delay_ms = pre_delay_ms
    );
    let result = run_async_script(&script).expect("failed to execute script");
    serde_json::from_str(&result).expect("failed to parse result")
}

// ---------- 直连 reqwest（模拟 Rust HttpClient::fetch 的行为） ----------

fn direct_config() -> HttpClientConfig {
    HttpClientConfig {
        use_http_proxy: false,
        use_socks5_proxy: false,
        http_proxy: None,
        socks5_proxy: None,
        disable_tls_verify: false,
        allow_private_network: true,
    }
}

/// 与 rust/src/api/http.rs 的 create_reqwest_client 对齐：
/// timeout 从请求真正发出开始计时。
fn direct_get(url: &str, timeout_ms: u64) -> Result<Duration, String> {
    let rt = tokio::runtime::Runtime::new().map_err(|e| e.to_string())?;
    rt.block_on(async {
        let client = build_http_client_ex(
            &direct_config(),
            BuildHttpClientOptions {
                no_proxy: false,
                timeout: Some(Duration::from_millis(timeout_ms)),
                connect_timeout: Some(Duration::from_millis(15_000)),
                follow_redirects: None,
                user_agent: None,
            },
        )
        .map_err(|e| e.to_string())?;
        let start = Instant::now();
        let resp = client
            .get(url)
            .send()
            .await
            .map_err(|e| format!("send failed: {e}"))?;
        let elapsed = start.elapsed();
        resp.bytes()
            .await
            .map_err(|e| format!("body failed: {e}"))?;
        Ok(elapsed)
    })
}

fn shutdown(handle: thread::JoinHandle<()>, tx: mpsc::Sender<()>) {
    let _ = tx.send(());
    let _ = handle.join();
}

// ---------- 跨域重定向 + Host/Referer 头保留测试 ----------
// 插件（axios）给 read-image 请求设置了 `Host: e-hentai.org`，
// read-image 302 到 hath.network 后，如果 Host 头被保留发送给 CDN，
// CDN 收到错误的 Host 就会异常（挂起/拒绝），导致超时。
// 本测试：A 服务器 302 到 B，客户端带自定义 Host 头，看 B 收到什么。

fn spawn_echo_server() -> (String, mpsc::Sender<()>, thread::JoinHandle<()>) {
    let server = Server::http("127.0.0.1:0").expect("echo server");
    let addr = format!("http://{}", server.server_addr());
    let (tx, rx) = mpsc::channel::<()>();
    let handle = thread::spawn(move || {
        loop {
            if rx.try_recv().is_ok() {
                break;
            }
            match server.recv_timeout(Duration::from_millis(5)) {
                Ok(Some(request)) => {
                    let host = request
                        .headers()
                        .iter()
                        .find(|h| h.field.equiv("Host"))
                        .map(|h| h.value.as_str().to_string())
                        .unwrap_or_default();
                    let referer = request
                        .headers()
                        .iter()
                        .find(|h| h.field.equiv("Referer"))
                        .map(|h| h.value.as_str().to_string())
                        .unwrap_or_default();
                    let body = serde_json::json!({ "host": host, "referer": referer }).to_string();
                    let _ = request.respond(Response::from_string(body).with_status_code(200));
                }
                _ => {}
            }
        }
    });
    (addr, tx, handle)
}

fn spawn_redirect_server(target: String) -> (String, mpsc::Sender<()>, thread::JoinHandle<()>) {
    let server = Server::http("127.0.0.1:0").expect("redirect server");
    let addr = format!("http://{}", server.server_addr());
    let (tx, rx) = mpsc::channel::<()>();
    let handle = thread::spawn(move || {
        loop {
            if rx.try_recv().is_ok() {
                break;
            }
            match server.recv_timeout(Duration::from_millis(5)) {
                Ok(Some(request)) => {
                    let resp = Response::empty(302).with_header(
                        Header::from_bytes(b"Location".as_slice(), target.as_bytes())
                            .expect("location"),
                    );
                    let _ = request.respond(resp);
                }
                _ => {}
            }
        }
    });
    (addr, tx, handle)
}

#[test]
fn host_header_and_referer_on_cross_host_redirect() {
    let (echo, tx_e, h_e) = spawn_echo_server();
    let (redir, tx_r, h_r) = spawn_redirect_server(echo.clone());
    let url = format!("{}/r", redir);

    // JS 运行时 fetch：模拟插件设置 Host: spoofed.example + Referer
    let script = format!(
        r#"
        (async () => {{
          const res = await fetch("{url}", {{
            headers: {{ Host: "spoofed.example", Referer: "https://origin.example/" }}
          }});
          const data = await res.json();
          return JSON.stringify({{ status: res.status, host: data.host, referer: data.referer }});
        }})()
        "#,
        url = url
    );
    let result = run_async_script(&script).expect("js redirect script");
    println!("[js-host-redirect] {result}");
    let v: Value = serde_json::from_str(&result).expect("parse js redirect");
    println!(
        "[js-host-redirect] 重定向后 CDN 收到的 Host = {:?}, Referer = {:?}",
        v["host"], v["referer"]
    );

    // 直接 reqwest 对比
    let rt = tokio::runtime::Runtime::new().expect("rt");
    let direct = rt.block_on(async {
        let client = build_http_client_ex(
            &direct_config(),
            BuildHttpClientOptions {
                no_proxy: false,
                timeout: Some(Duration::from_millis(10_000)),
                connect_timeout: Some(Duration::from_millis(5_000)),
                follow_redirects: None,
                user_agent: None,
            },
        )
        .expect("client");
        client
            .get(&url)
            .header("Host", "spoofed.example")
            .header("Referer", "https://origin.example/")
            .send()
            .await
            .expect("send")
            .text()
            .await
            .unwrap_or_default()
    });
    println!("[direct-host-redirect] CDN 收到的内容: {direct}");

    shutdown(h_r, tx_r);
    shutdown(h_e, tx_e);
}

// ---------- 测试 1：JS fetch 对慢服务器确实会超时（机制验证） ----------

#[test]
fn js_fetch_timeout_fires_on_slow_server() {
    let (base, tx, handle) = spawn_delay_server();
    // 服务器延迟 800ms > timeout 500ms，应当超时
    let v = js_fetch(&format!("{}/delay/800", base), 500, 0);
    println!("js_fetch timeout 500 vs delay 800 -> {v}");
    assert_eq!(v["ok"], false, "应该超时，实际: {v}");
    let name = v["name"].as_str().unwrap_or("");
    let msg = v["message"].as_str().unwrap_or("");
    assert!(
        name.contains("TimeoutError") || name.contains("AbortError") || msg.contains("超时"),
        "错误类型不符: {v}"
    );
    // 耗时应该接近 500ms（墙钟），而不是等满 800ms
    let elapsed = v["totalMs"].as_u64().unwrap_or(0);
    assert!(
        (450..=900).contains(&elapsed),
        "超时触发时机异常: elapsed={elapsed}ms"
    );
    shutdown(handle, tx);
}

// ---------- 测试 2：JS fetch 在 timeout 内完成则成功 ----------

#[test]
fn js_fetch_succeeds_under_timeout() {
    let (base, tx, handle) = spawn_delay_server();
    let v = js_fetch(&format!("{}/delay/400", base), 3000, 0);
    println!("js_fetch timeout 3000 vs delay 400 -> {v}");
    assert_eq!(v["ok"], true, "应当成功: {v}");
    let elapsed = v["totalMs"].as_u64().unwrap_or(0);
    assert!(elapsed >= 400, "至少等服务器 400ms: elapsed={elapsed}");
    shutdown(handle, tx);
}

// ---------- 测试 3：JS 路径无「墙钟提前超时」竞态（实测结论） ----------
// 相同服务器、相同 timeout 值：
//   直连 reqwest（timeout 从请求开始算）→ 成功
//   JS fetch（timeout 从 dispatch 算，且请求前有 600ms 预延迟）→ 也应成功，
//   因为 fetch 的 timeout 计时起点是 fetch 派发那一刻，网络部分 1200ms + 开销
//   ~200ms 仍 < 1500ms 预算。实测 JS 路径不会提前触发墙钟超时。
#[test]
fn wallclock_timeout_race_direct_succeeds_js_succeeds_too() {
    let (base, tx, handle) = spawn_delay_server();
    let url = format!("{}/delay/1200", base); // 服务器响应 1200ms

    // 直连：timeout 1500ms，从请求开始计时 → 1200 < 1500，应当成功
    match direct_get(&url, 1500) {
        Ok(elapsed) => {
            println!("[direct] timeout=1500 delay=1200 -> OK in {:?}", elapsed);
            assert!(elapsed.as_millis() < 1500);
        }
        Err(e) => panic!("直连竟然超时了: {e}"),
    }

    // JS：请求派发前先 sleep 600ms，再 fetch timeout 1500ms。
    // 结论：fetch 计时从派发开始，网络部分 1200ms+~200ms 开销 < 1500ms → 应成功。
    let v = js_fetch(&url, 1500, 600);
    println!("[js]     timeout=1500 delay=1200 pre=600 -> {v}");
    assert_eq!(
        v["ok"], true,
        "JS fetch 应在自身 1500ms 预算内完成（1200+开销<1500），不存在墙钟提前超时: {v}"
    );
    let fetch_ms = v["fetchMs"].as_u64().unwrap_or(0);
    assert!(
        fetch_ms < 1500,
        "fetch 网络部分应 <1500ms: fetchMs={fetch_ms}"
    );

    shutdown(handle, tx);
}

// ---------- 测试 4：无 timeout 的 JS fetch 在 pre_delay + 慢服务器场景可成功 ----------
// 同样的 pre_delay=600 + delay=1200 = 1800ms，不带 JS timeout → 原生 30s 预算内完成。
// 说明该场景本身没有会让请求失败的因素，只是需要足够的时间预算。
#[test]
fn js_fetch_without_timeout_succeeds_in_race_scenario() {
    let (base, tx, handle) = spawn_delay_server();
    let url = format!("{}/delay/1200", base);

    // 同样的 pre_delay=600 + delay=1200 = 1800ms，但不带 JS timeout → 原生 30s 预算内完成
    let v = js_fetch_no_timeout(&url, 600);
    println!("[js no-timeout] delay=1200 pre=600 -> {v}");
    assert_eq!(v["ok"], true, "无 JS 墙钟定时器时应成功: {v}");
    let elapsed = v["totalMs"].as_u64().unwrap_or(0);
    assert!(elapsed >= 1800, "应等满 1800ms: elapsed={elapsed}");

    shutdown(handle, tx);
}

// ---------- 测试 5：量化 JS 路径相对直连的固定开销 ----------
#[test]
fn measure_js_fetch_overhead_vs_direct() {
    let (base, tx, handle) = spawn_delay_server();
    let url = format!("{}/delay/50", base);

    let direct = direct_get(&url, 10_000).expect("direct should succeed");
    let v = js_fetch_no_timeout(&url, 0);
    let js_ms = v["totalMs"].as_u64().unwrap_or(0);

    println!(
        "[overhead] direct={:?} js={}ms delta={}ms",
        direct,
        js_ms,
        js_ms as i128 - direct.as_millis() as i128
    );
    assert_eq!(v["ok"], true);
    // JS 路径至少不慢于服务器延迟（合理性检查）
    assert!(js_ms >= 50, "JS 路径耗时异常: {js_ms}ms");

    shutdown(handle, tx);
}

// ---------- 测试 6：重定向（read-image → 图片 CDN）跟随与总超时 ----------
#[test]
fn redirect_slow_target_timeout_accounting() {
    let (base, tx, handle) = spawn_delay_server();
    // /redirect/1200 -> 302 -> /delay/1200（模拟 read-image 302 到 hath.network）
    let url = format!("{}/redirect/1200", base);

    // 直连 timeout 1500：302 + 1200 < 1500 → 成功
    match direct_get(&url, 1500) {
        Ok(elapsed) => {
            println!("[direct redirect] timeout=1500 -> OK in {:?}", elapsed);
            assert!(elapsed.as_millis() < 1500);
        }
        Err(e) => panic!("直连跟随重定向失败: {e}"),
    }
    // 直连 timeout 1000：302 + 1200 > 1000 → 超时
    assert!(
        direct_get(&url, 1000).is_err(),
        "直连 timeout=1000 应超时（302+1200>1000）"
    );

    // JS 侧同样：timeout 1500 成功、1000 超时 → 重定向口径两边一致
    let v_ok = js_fetch(&url, 1500, 0);
    println!("[js redirect] timeout=1500 -> {v_ok}");
    assert_eq!(v_ok["ok"], true, "JS 跟随重定向 timeout=1500 应成功: {v_ok}");

    let v_timeout = js_fetch(&url, 1000, 0);
    println!("[js redirect] timeout=1000 -> {v_timeout}");
    assert_eq!(v_timeout["ok"], false, "JS 跟随重定向 timeout=1000 应超时: {v_timeout}");

    shutdown(handle, tx);
}

// ---------- 测试 7：大响应体 native buffer offload 的开销 ----------
#[test]
fn large_body_offload_overhead() {
    let (base, tx, handle) = spawn_delay_server();
    // 分别测 2MB / 10MB / 50MB，观察 JS 运行时读大 body 是否会卡
    for size in [2 * 1024 * 1024, 10 * 1024 * 1024, 50 * 1024 * 1024] {
        let url = format!("{}/large/{}", base, size);
        let direct = direct_get(&url, 30_000).expect("direct large should succeed");
        let v = js_fetch_no_timeout(&url, 0);
        println!(
            "[large {}MB] direct={:?} js={}ms ok={}",
            size / (1024 * 1024),
            direct,
            v["totalMs"],
            v["ok"]
        );
        assert_eq!(v["ok"], true, "JS 大 body 应成功: {v}");
    }
    shutdown(handle, tx);
}

// ---------- 测试 9：隔离 pre_delay 对 fetch 耗时的影响 ----------
// 服务器同样延迟 1200ms：
//   A) 无 pre_delay → fetchMs 应 ≈ 1200 + 开销
//   B) 有 600ms pre_delay → fetchMs 应同样 ≈ 1200 + 开销（墙钟总 1800+）
// 若 B 的 fetchMs 明显大于 A，说明 pre_delay 阻塞了 fetch 派发/运行时调度。
#[test]
fn pre_delay_effect_on_fetch_latency() {
    let (base, tx, handle) = spawn_delay_server();
    let url = format!("{}/delay/1200", base);

    let v_a = js_fetch_no_timeout(&url, 0);
    println!("[isolation A] delay=1200 pre=0    -> {v_a}");
    assert_eq!(v_a["ok"], true, "A 应成功: {v_a}");
    let fetch_a = v_a["fetchMs"].as_u64().unwrap_or(0);
    assert!(
        fetch_a < 3000 && fetch_a >= 1200,
        "A fetchMs 异常: {fetch_a}"
    );

    let v_b = js_fetch_no_timeout(&url, 600);
    println!("[isolation B] delay=1200 pre=600  -> {v_b}");
    let fetch_b = v_b["fetchMs"].as_u64().unwrap_or(0);
    if v_b["ok"] == false {
        eprintln!(
            "[isolation B] FAILED with {:?}: {:?}",
            v_b["name"], v_b["message"]
        );
    } else {
        println!(
            "[isolation] delta(fetchMs B - A) = {}ms",
            fetch_b as i128 - fetch_a as i128
        );
        // B 的 fetch 耗时不应比 A 明显更长
        assert!(
            fetch_b <= fetch_a + 400,
            "pre_delay 导致 fetch 耗时异常增加: A={fetch_a}ms B={fetch_b}ms"
        );
    }

    shutdown(handle, tx);
}


// ---------- 测试 10：DNS 预检分支（localhost 主机名 vs 127.0.0.1 IP 字面量） ----------
// `ensure_http_target_allowed` 对非 IP 字面量的主机名会执行 `lookup_host` DNS 解析，
// 对 IP 字面量直接跳过。对比两种 URL 的 JS fetch 耗时，量化 DNS 分支的开销。
#[test]
fn dns_prelookup_overhead_localhost_vs_ip() {
    let (base, tx, handle) = spawn_delay_server();
    // 从 base（http://127.0.0.1:PORT）派生 localhost 版本
    let localhost_url = base.replacen("127.0.0.1", "localhost", 1);
    let ip_url = format!("{}/delay/30", base);
    let host_url = format!("{}/delay/30", localhost_url);

    let v_ip = js_fetch_no_timeout(&ip_url, 0);
    let v_host = js_fetch_no_timeout(&host_url, 0);
    println!("[dns] ip      -> {v_ip}");
    println!("[dns] localhost-> {v_host}");

    assert_eq!(v_ip["ok"], true, "IP 直连应成功: {v_ip}");
    assert_eq!(v_host["ok"], true, "localhost 主机名应成功: {v_host}");
    let ip_ms = v_ip["fetchMs"].as_u64().unwrap_or(0);
    let host_ms = v_host["fetchMs"].as_u64().unwrap_or(0);
    println!(
        "[dns] delta(host - ip) = {}ms (localhost DNS 预检开销)",
        host_ms as i128 - ip_ms as i128
    );

    shutdown(handle, tx);
}

// ---------- 测试 11：真实 DNS 解析耗时（量化 lookup_host 的成本） ----------
// 对 hath.network 这类域名，每个唯一子域都要解析一次 DNS。测一下当前机器上
// 一次真实 lookup_host 要多久，判断 DNS 是否可能吃掉超时预算。
#[test]
fn real_dns_lookup_timing() {
    let rt = tokio::runtime::Runtime::new().expect("rt");
    let hosts = [
        ("example.com", 80u16),
        ("e-hentai.org", 443),
        ("sryrolt.zrzzqnxxkfhb.hath.network", 443),
        ("mxrvudxfzg.hath.network", 443),
    ];
    for (host, port) in hosts {
        let start = Instant::now();
        let result = rt.block_on(async move {
            tokio::net::lookup_host((host.to_owned(), port)).await
        });
        let elapsed = start.elapsed();
        match result {
            Ok(addrs) => {
                let first = addrs.into_iter().next();
                println!(
                    "[dns-lookup] {} -> {:?} in {:?}",
                    host,
                    first.map(|a| a.to_string()),
                    elapsed
                );
            }
            Err(e) => {
                println!("[dns-lookup] {} -> ERROR {e} in {:?}", host, elapsed);
            }
        }
    }
}


// 说明：tiny_http 服务器是单线程的，请求会按到达顺序串行处理，
// 因此这里用小延迟（50ms×20=1000ms < 2000ms 超时），验证 JS 运行时本身
// 不会把并发请求串行化或卡在 http_io_sem 信号量上。
#[test]
fn concurrent_requests_no_semaphore_timeout() {
    let (base, tx, handle) = spawn_delay_server();
    let url = format!("{}/delay/50", base);

    let script = format!(
        r#"
        (async () => {{
          const url = "{url}";
          const jobs = [];
          const t0 = Date.now();
          for (let i = 0; i < 20; i++) {{
            jobs.push(fetch(url, {{ timeout: 2000 }}).then(r => {{ const t1 = Date.now(); return {{ ok: true, elapsed: t1 - t0 }}; }}).catch(e => {{ const t1 = Date.now(); return {{ ok: false, elapsed: t1 - t0, name: String(e && e.name || e) }}; }}));
          }}
          const results = await Promise.all(jobs);
          const okCount = results.filter(r => r.ok).length;
          return JSON.stringify({{ okCount, total: results.length, maxElapsed: Math.max(...results.map(r => r.elapsed)) }});
        }})()
        "#,
        url = url
    );
    let result = run_async_script(&script).expect("concurrent script");
    println!("[concurrent 20 x delay50] {result}");
    let v: Value = serde_json::from_str(&result).expect("parse concurrent");
    assert_eq!(v["okCount"], 20, "并发请求不应因运行时串行化/信号量排队而超时: {v}");
    let max_elapsed = v["maxElapsed"].as_u64().unwrap_or(0);
    assert!(max_elapsed < 2000, "并发耗时异常: {v}");

    shutdown(handle, tx);
}

// ---------- 测试 14：慢速分块 body（模拟真实网络）JS vs 直连 ----------
// 5MB 按 64KB 分块、每块间隔 10ms 发送，服务器侧约 78×10=780ms。
// 若 JS 运行时与直连接近（都 ~1s），说明修复已消除逐块 50ms 延迟；
// 若 JS 明显慢（几十倍），说明仍有逐块轮询开销。
#[test]
fn trickle_body_js_vs_direct() {
    let (base, tx, handle) = spawn_delay_server();
    // /trickle/{size}/{chunk}/{delay}
    let url = format!("{}/trickle/5000000/65536/10", base);

    let direct = direct_get(&url, 30_000).expect("direct trickle should succeed");
    let v = js_fetch_no_timeout(&url, 0);
    println!(
        "[trickle 5MB/64KB/10ms] direct={:?} js={}ms ok={}",
        direct,
        v["totalMs"],
        v["ok"]
    );
    assert_eq!(v["ok"], true, "JS trickle body 应成功: {v}");

    // 服务器侧发送就要 ~780ms，JS 总耗时不应离谱（给足余量：<20s）
    // 注：修复前这里是"永不完成/超时"，修复后成功但仍有逐块轮询开销。
    let js_ms = v["totalMs"].as_u64().unwrap_or(0);
    assert!(
        js_ms < 20_000,
        "JS 逐块轮询异常慢: js={js_ms}ms direct={:?}",
        direct
    );

    shutdown(handle, tx);
}


// ---------- 测试 17：请求正常完成后 cancel sender 被清理 ----------
// 防止 http_promise_cancel_senders 无限增长（之前每次请求都留一个悬空 sender）。
#[test]
fn cancel_senders_are_cleaned_up_after_completion() {
    let before = crate::web_runtime::http_promise_cancel_senders_len();
    let (base, tx, handle) = spawn_delay_server();
    let url = format!("{}/delay/50", base);

    // 连续做几个请求，每个完成后 map 应该回到 before 大小
    for _ in 0..3 {
        let v = js_fetch_no_timeout(&url, 0);
        assert_eq!(v["ok"], true, "{v}");
    }
    let after = crate::web_runtime::http_promise_cancel_senders_len();
    println!(
        "[cancel-senders] before={before} after={after}（请求完成后不应增长）"
    );
    assert_eq!(
        after, before,
        "取消 sender 未在请求完成后清理: before={before} after={after}"
    );

    shutdown(handle, tx);
}


// 服务器延迟 2s，fetch 100ms 后 abort。验证：
// 1. JS promise 快速被取消（不会等满 2s）——即"不获取结果"的行为保住了。
// 2. 取消走的是 __http_request_cancel → cancel_rx → select 返回 canceled。
#[test]
fn cancel_aborts_fetch_promptly() {
    let (base, tx, handle) = spawn_delay_server();
    let url = format!("{}/delay/2000", base);
    let script = format!(
        r#"
        (async () => {{
          const controller = new AbortController();
          const t0 = Date.now();
          const p = fetch("{url}", {{ signal: controller.signal }});
          setTimeout(() => controller.abort(), 100);
          try {{
            await p;
            const t1 = Date.now();
            return JSON.stringify({{ ok: true, elapsed: t1 - t0 }});
          }} catch (e) {{
            const t1 = Date.now();
            return JSON.stringify({{
              ok: false,
              canceled: true,
              elapsed: t1 - t0,
              name: String(e && e.name || e),
              message: String(e && e.message || "")
            }});
          }}
        }})()
        "#,
        url = url
    );
    let result = run_async_script(&script).expect("cancel script");
    println!("[cancel] {result}");
    let v: Value = serde_json::from_str(&result).expect("parse cancel");
    let elapsed = v["elapsed"].as_u64().unwrap_or(0);
    // 取消后应快速返回（<1s），而不是等满服务器 2s 延迟
    assert!(
        elapsed < 1000,
        "取消后应快速返回，elapsed={elapsed}ms: {v}"
    );

    shutdown(handle, tx);
}


// 修复前：`__native_buffer_take_raw` 返回 Vec<u8> 经 rquickjs 慢转换，
// 5MB 实测 ~5s。修复后走 `__native_buffer_take_typed`（零拷贝 ArrayBuffer），
// 应该毫秒级。这个测试用来防止回归。
#[test]
fn native_take_large_buffer_is_fast() {
    let script = r#"
        (async () => {
          const size = 5 * 1024 * 1024;
          const bytes = new Uint8Array(size);
          const id = await globalThis.native.put(bytes);
          const t0 = Date.now();
          const taken = await globalThis.native.take(id);
          const t1 = Date.now();
          return JSON.stringify({
            ms: t1 - t0,
            isArray: Array.isArray(taken),
            isU8: typeof Uint8Array !== 'undefined' && taken instanceof Uint8Array,
            len: taken && taken.length,
            first: taken && taken[0]
          });
        })()
    "#;
    let result = run_async_script(script).expect("native take script");
    println!("[native-take 5MB] {result}");
    let v: Value = serde_json::from_str(&result).expect("parse native take");
    let ms = v["ms"].as_u64().unwrap_or(0);
    let is_array = v["isArray"].as_bool().unwrap_or(false);
    println!(
        "[native-take] ms={ms} isArray={is_array} isU8={} len={}",
        v["isU8"], v["len"]
    );
    // 如果 5MB 的 take 超过 1s，说明走了慢转换路径（回归）
    assert!(
        ms < 1000,
        "native.take 大 buffer 过慢: {ms}ms isArray={is_array}"
    );
}


// 直接请求用户提供的真实 hath.network 图片，关键变量：Referer 头。
// 怀疑：插件/重定向路径丢失了 Referer，hath.network 没 Referer 就挂起 → 超时。
const REAL_HATH_URL: &str = "https://sryrolt.zrzzqnxxkfhb.hath.network/h/52e8283bc7d7e918db571d087125f55ddbc4006c-6099922-832-1120-gif/keystamp=1786681200-694b0205c1;fileindex=244073022;xres=org/c3f64c2c0df2a72500h00m00s_00h00m05s.gif";
const REAL_REFERER: &str = "https://e-hentai.org/";

fn js_fetch_real(url: &str, referer: Option<&str>, timeout_ms: u64) -> Value {
    let headers_js = match referer {
        Some(r) => format!(r#"{{ Referer: "{}" }}"#, r),
        None => "{}".to_string(),
    };
    let script = format!(
        r#"
        (async () => {{
          const t0 = Date.now();
          try {{
            const res = await fetch("{url}", {{
              timeout: {timeout_ms},
              headers: {headers_js}
            }});
            const t1 = Date.now();
            const data = await res.arrayBuffer();
            const t2 = Date.now();
            return JSON.stringify({{
              ok: true,
              fetchMs: t1 - t0,
              bodyMs: t2 - t1,
              totalMs: t2 - t0,
              status: res.status,
              ct: res.headers.get("content-type") || "",
              len: data.byteLength
            }});
          }} catch (e) {{
            const t1 = Date.now();
            return JSON.stringify({{
              ok: false,
              fetchMs: t1 - t0,
              name: String(e && e.name || e),
              message: String(e && e.message || "")
            }});
          }}
        }})()
        "#,
        url = url,
        timeout_ms = timeout_ms,
        headers_js = headers_js
    );
    let result = run_async_script(&script).expect("failed to execute script");
    serde_json::from_str(&result).expect("failed to parse result")
}

fn direct_get_real(url: &str, referer: Option<&str>, timeout_ms: u64) -> Result<(Duration, u64, u16), String> {
    let rt = tokio::runtime::Runtime::new().map_err(|e| e.to_string())?;
    rt.block_on(async {
        let client = build_http_client_ex(
            &direct_config(),
            BuildHttpClientOptions {
                no_proxy: false,
                timeout: Some(Duration::from_millis(timeout_ms)),
                connect_timeout: Some(Duration::from_millis(15_000)),
                follow_redirects: None,
                user_agent: None,
            },
        )
        .map_err(|e| e.to_string())?;
        let mut req = client.get(url);
        if let Some(r) = referer {
            req = req.header("Referer", r);
        }
        let start = Instant::now();
        let resp = req.send().await.map_err(|e| format!("send failed: {e}"))?;
        let status = resp.status().as_u16();
        let bytes = resp.bytes().await.map_err(|e| format!("body failed: {e}"))?;
        let len = bytes.len() as u64;
        Ok((start.elapsed(), len, status))
    })
}

#[test]
fn real_hath_url_referer_on_off() {
    println!("[real] URL = {}", REAL_HATH_URL);

    // 打印 JS 运行时用的全局 HTTP 配置 + 用同款方式建 client 直测，定位差异层
    let global_cfg = crate::current_http_client_config();
    println!("[config] 全局 HttpClientConfig = {:?}", global_cfg);

    let rt = tokio::runtime::Runtime::new().expect("rt");
    let native = rt.block_on(async {
        let client = crate::build_http_client(&global_cfg).expect("build client");
        let start = Instant::now();
        let resp = client
            .get(REAL_HATH_URL)
            .header("Referer", REAL_REFERER)
            .send()
            .await;
        match resp {
            Ok(r) => {
                let status = r.status().as_u16();
                let bytes = r.bytes().await.map(|b| b.len()).unwrap_or(0);
                Some((status, bytes, start.elapsed()))
            }
            Err(e) => {
                println!("[native同款client] 发送失败: {e}");
                None
            }
        }
    });
    if let Some((status, len, elapsed)) = native {
        println!(
            "[native同款client] OK status={status} len={len} in {:?}",
            elapsed
        );
    }

    println!("--- JS 运行时（插件路径） ---");
    let v_js_ref = js_fetch_real(REAL_HATH_URL, Some(REAL_REFERER), 15_000);
    println!("[js 带Referer]  {v_js_ref}");
    let v_js_no = js_fetch_real(REAL_HATH_URL, None, 15_000);
    println!("[js 不带Referer] {v_js_no}");

    println!("--- 直接 reqwest ---");
    match direct_get_real(REAL_HATH_URL, Some(REAL_REFERER), 15_000) {
        Ok((elapsed, len, status)) => {
            println!("[direct 带Referer]  OK status={status} len={len} in {:?}", elapsed);
        }
        Err(e) => println!("[direct 带Referer]  ERR {e}"),
    }
    match direct_get_real(REAL_HATH_URL, None, 15_000) {
        Ok((elapsed, len, status)) => {
            println!("[direct 不带Referer] OK status={status} len={len} in {:?}", elapsed);
        }
        Err(e) => println!("[direct 不带Referer] ERR {e}"),
    }
}

// ---------- 测试 13：在 current_thread runtime（同 QJS worker）上复刻请求 ----------
// QJS 的 fetch 跑在 `Builder::new_current_thread().enable_all()` 的单线程 runtime 上，
// 而我的直连测试用多线程 runtime。这里在完全相同的 current_thread runtime 上，
// 分步执行 JS 运行时的逻辑（DNS 预检 → 建 client → 发请求），定位卡点。
#[test]
fn real_hath_url_current_thread_runtime() {
    let host = "bicywbk.wsbrbtsgkdto.hath.network";
    let port = 2333u16;

    let rt = tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .expect("current_thread rt");

    // 步骤 1：ensure_http_target_allowed 里的 lookup_host
    rt.block_on(async {
        let start = Instant::now();
        match tokio::net::lookup_host((host, port)).await {
            Ok(addrs) => {
                let ips: Vec<String> = addrs.into_iter().map(|a| a.to_string()).collect();
                println!("[ct] lookup_host OK in {:?} -> {:?}", start.elapsed(), ips);
            }
            Err(e) => println!("[ct] lookup_host ERR in {:?}: {e}", start.elapsed()),
        }
    });

    // 步骤 2：build_http_client（同 JS 运行时全局配置）
    rt.block_on(async {
        let start = Instant::now();
        let client = crate::build_http_client(&crate::current_http_client_config())
            .expect("build client");
        println!("[ct] build_http_client OK in {:?}", start.elapsed());

        // 步骤 3：发送请求
        let start2 = Instant::now();
        match client
            .get(REAL_HATH_URL)
            .header("Referer", REAL_REFERER)
            .send()
            .await
        {
            Ok(r) => {
                let status = r.status().as_u16();
                let start3 = Instant::now();
                match r.bytes().await {
                    Ok(b) => println!(
                        "[ct] send+headers OK in {:?} (status={status} len={}) body in {:?}",
                        start2.elapsed(),
                        b.len(),
                        start3.elapsed()
                    ),
                    Err(e) => println!("[ct] body ERR in {:?}: {e}", start2.elapsed()),
                }
            }
            Err(e) => println!("[ct] send ERR in {:?}: {e}", start2.elapsed()),
        }
    });

    // 对照：JS 运行时 fetch
    let v = js_fetch_real(REAL_HATH_URL, Some(REAL_REFERER), 10_000);
    println!("[ct-js] fetch -> {v}");
}
