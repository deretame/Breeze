//! 域名前置（domain fronting / IP 直连）。
//!
//! # 背景
//!
//! e-hentai.org / exhentai.org 在墙内走「系统 DNS + TLS SNI」时会被 RST，
//! 但「直连站点真实 IP + TLS 不发 SNI + 带 `Host` 头」可以穿透。
//! 这正是 JHenTai（`lib/src/setting/network_setting.dart` 的 `host2IPs`
//! + `lib/src/network/eh_ip_provider.dart` 的 `RoundRobinIpProvider`
//! + Dio 拦截器改写 host）所使用的方案。
//!
//! # 为什么必须由宿主实现
//!
//! Breeze 插件的 JS 请求最终走 `reqwest`，默认会协商 HTTP/2。
//! 而 HTTP/2 没有 `Host` 头，只有 `:authority` 伪头；hyper 的 `:authority`
//! **只从 URI 取**，于是 IP 形式的 URL 会让 `:authority = <IP>`，
//! Cloudflare / Apache 对「IP authority + Host 头」一律回 **400 Bad Request**。
//!
//! JS 侧没有任何手段强制 reqwest 只发 HTTP/1.1（`http1_only()` 是 Rust 侧
//! `ClientBuilder` 的配置），所以这段逻辑只能落在宿主。
//!
//! # 职责划分
//!
//! - **插件**（`src/network/ip-direct.ts`）：维护 host -> IP 表（内置表 + 用户覆盖），
//!   探测宿主能力，把表通过 `__http_set_front_hosts` 下发过来。
//! - **宿主**（本模块）：把命中的请求改写为 IP URL、注入 `Host` 头、
//!   强制 HTTP/1.1、不自动跟随重定向、跳过证书校验、轮询选 IP、
//!   连接失败时把 IP 标记为不健康（5 分钟）。
//!
//! 表为空时全部请求走原链路，对既有行为零影响。

use std::collections::HashMap;
use std::net::IpAddr;
use std::str::FromStr;
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};

use anyhow::{Context as _, Result as AnyResult, anyhow};
use reqwest::redirect::Policy;
use reqwest::Client;
use reqwest_middleware::ClientWithMiddleware;
use serde_json::{Value, json};

use super::http::{HttpClientConfig, wrap_http_client};

/// 不健康 IP 的冷却时长：5 分钟（与 JHenTai `RoundRobinIpProvider` 的
/// `inMinutes < 5` 判定一致）。
pub const FRONT_UNHEALTHY_TTL: Duration = Duration::from_secs(300);

/// 前置客户端的超时时间。
const FRONT_CLIENT_TIMEOUT: Duration = Duration::from_secs(30);

/// 一条前置目标：域名 + 选中的 IP。
#[derive(Debug, Clone)]
pub(crate) struct FrontTarget {
    /// 原始域名（小写），用于 `Host` 头。
    pub host: String,
    /// 实际连接的 IP。
    pub ip: String,
}

/// 进程级前置状态。
///
/// - `hosts`：host（小写）-> IP 列表
/// - `unhealthy`：IP -> 不健康截止时刻
/// - `cursor`：host -> 轮询游标
#[derive(Debug, Default)]
struct FrontHostState {
    hosts: HashMap<String, Vec<String>>,
    unhealthy: HashMap<String, Instant>,
    cursor: HashMap<String, usize>,
}

fn front_host_state() -> &'static Mutex<FrontHostState> {
    static FRONT_HOST_STATE: OnceLock<Mutex<FrontHostState>> = OnceLock::new();
    FRONT_HOST_STATE.get_or_init(|| Mutex::new(FrontHostState::default()))
}

/// 判断字符串是否为合法 IPv4 字面量。
///
/// 刻意**只**接受 IPv4：前置表里的 IP 会被直接写进 URL 的 host 部分，
/// IPv6 字面量需要方括号包裹，格式处理容易出错，且本项目用到的目标站
/// 目前都是 IPv4。
fn is_valid_front_ip(value: &str) -> bool {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        return false;
    }
    let mut parts = trimmed.split('.');
    for _ in 0..4 {
        let part = match parts.next() {
            Some(p) => p,
            None => return false,
        };
        if part.is_empty() || part.len() > 3 {
            return false;
        }
        if !part.bytes().all(|b| b.is_ascii_digit()) {
            return false;
        }
        if part.len() > 1 && part.starts_with('0') {
            return false;
        }
        if part.parse::<u8>().is_err() {
            return false;
        }
    }
    parts.next().is_none()
}

/// 判断 IP 是否属于「不应被前置」的保留地址段。
///
/// 前置表由插件下发，理论上可能来自不可信来源。如果表里混入内网 / 环回 /
/// 链路本地地址并被前置，等于凭空开出一条访问内网的通道（SSRF）。
/// 宿主原有的 `ensure_http_target_allowed` 也会拦这类地址，但那条检查在
/// **域名解析之后**才生效；前置时我们根本不解析域名，所以要在这里直接拒绝。
fn is_rejectable_front_ip(ip: &str) -> bool {
    let parsed = match IpAddr::from_str(ip.trim()) {
        Ok(v) => v,
        Err(_) => return true,
    };
    match parsed {
        IpAddr::V4(v4) => {
            let octets = v4.octets();
            v4.is_loopback()
                || v4.is_private()
                || v4.is_link_local()
                || v4.is_unspecified()
                || v4.is_broadcast()
                || v4.is_documentation()
                // 100.64.0.0/10：运营商级 NAT（RFC 6598）
                || (octets[0] == 100 && (64..=127).contains(&octets[1]))
        }
        IpAddr::V6(v6) => {
            v6.is_loopback()
                || v6.is_unspecified()
                || v6.is_unique_local()
                || v6.is_unicast_link_local()
                || v6.is_multicast()
        }
    }
}

/// 下发前置表。`payload` 是 JSON 字符串：`{ "e-hentai.org": ["1.2.3.4"] }`。
///
/// - 非 IP 字面量的条目静默忽略（不报错，避免一个脏值让整张表失效）。
/// - 传空对象等于关闭前置。
/// - 幂等：表内容没变就不动状态（保留不健康记录与轮询游标）。
pub fn set_front_hosts(payload: String) -> String {
    let parsed: Value = match serde_json::from_str(&payload) {
        Ok(v) => v,
        Err(e) => {
            return json!({
                "ok": false,
                "error": crate::tr!("failed-to-parse-front-hosts-json", e = e.to_string()),
            })
            .to_string();
        }
    };

    let mut table: HashMap<String, Vec<String>> = HashMap::new();
    let mut rejected = 0usize;
    if let Value::Object(obj) = parsed {
        for (raw_host, raw_ips) in obj {
            let host = raw_host
                .trim()
                .trim_start_matches("https://")
                .trim_start_matches("http://")
                .trim_end_matches('/')
                .to_ascii_lowercase();
            if host.is_empty() {
                continue;
            }
            let mut ips: Vec<String> = Vec::new();
            if let Value::Array(items) = raw_ips {
                for item in items {
                    let ip = match item.as_str() {
                        Some(s) => s.trim().to_string(),
                        None => continue,
                    };
                    if !is_valid_front_ip(&ip) {
                        rejected += 1;
                        continue;
                    }
                    if !ips.contains(&ip) {
                        ips.push(ip);
                    }
                }
            }
            if !ips.is_empty() {
                table.insert(host, ips);
            }
        }
    }

    let host_count = table.len();
    let ip_count: usize = table.values().map(|v| v.len()).sum();

    let mut state = match front_host_state().lock() {
        Ok(s) => s,
        Err(_) => {
            return json!({ "ok": false, "error": crate::tr!("front-host-state-lock-is-poisoned") })
                .to_string();
        }
    };

    if state.hosts != table {
        state.hosts = table;
        // 表变了就重置游标，但保留不健康记录（新表里没有的 IP 记录会被忽略）。
        state.cursor.clear();
    }

    json!({ "ok": true, "hosts": host_count, "ips": ip_count, "rejected": rejected }).to_string()
}

/// 读回当前前置表 + 每个 IP 的健康状态。
pub fn get_front_hosts() -> String {
    let state = match front_host_state().lock() {
        Ok(s) => s,
        Err(_) => {
            return json!({ "ok": false, "error": crate::tr!("front-host-state-lock-is-poisoned") })
                .to_string();
        }
    };

    let now = Instant::now();
    let mut hosts_map = serde_json::Map::new();
    for (host, ips) in &state.hosts {
        let mut entries = Vec::new();
        for ip in ips {
            let healthy = match state.unhealthy.get(ip) {
                Some(deadline) => *deadline <= now,
                None => true,
            };
            entries.push(json!({ "ip": ip, "healthy": healthy }));
        }
        hosts_map.insert(host.clone(), Value::Array(entries));
    }

    json!({ "ok": true, "hosts": Value::Object(hosts_map) }).to_string()
}

/// 清空前置表（关闭前置）。
pub fn clear_front_hosts() -> String {
    if let Ok(mut state) = front_host_state().lock() {
        state.hosts.clear();
        state.cursor.clear();
        state.unhealthy.clear();
    }
    json!({ "ok": true }).to_string()
}

/// 最长后缀匹配：优先命中更具体的键。
///
/// 例如表里有 `exhentai.org` 和 `s.exhentai.org` 时，`s.exhentai.org` 命中前者自己的键；
/// 只有表里没有 `s.exhentai.org` 时才回落到 `exhentai.org`。
fn match_front_host<'a>(
    table: &'a HashMap<String, Vec<String>>,
    host: &str,
) -> Option<&'a Vec<String>> {
    let mut best: Option<(usize, &Vec<String>)> = None;
    for (key, ips) in table {
        if host == key || host.ends_with(&format!(".{key}")) {
            let len = key.len();
            if best.is_none() || len > best.unwrap().0 {
                best = Some((len, ips));
            }
        }
    }
    best.map(|(_, ips)| ips)
}

/// 解析出本次请求要用的前置目标。
///
/// 流程：最长后缀匹配 -> 过滤不健康 IP -> 轮询选取 -> 拒绝保留地址段。
pub(crate) fn resolve_front_target(url: &str) -> AnyResult<Option<FrontTarget>> {
    let parsed = match reqwest::Url::parse(url) {
        Ok(v) => v,
        Err(e) => {
            return Err(anyhow::Error::new(e).context(crate::tr!("failed-to-parse-url", url = url)));
        }
    };
    let host = match parsed.host_str() {
        Some(h) => h.trim().to_ascii_lowercase(),
        None => return Ok(None),
    };
    if host.is_empty() {
        return Ok(None);
    }

    let (ips, cursor, unhealthy_ips) = {
        let state = match front_host_state().lock() {
            Ok(s) => s,
            Err(_) => return Ok(None),
        };
        let ips = match match_front_host(&state.hosts, &host) {
            Some(v) => v.clone(),
            None => return Ok(None),
        };
        if ips.is_empty() {
            return Ok(None);
        }
        let cursor = *state.cursor.get(&host).unwrap_or(&0);
        let unhealthy_ips: Vec<String> = state
            .unhealthy
            .iter()
            .filter(|(_, deadline)| **deadline > Instant::now())
            .map(|(ip, _)| ip.clone())
            .collect();
        (ips, cursor, unhealthy_ips)
    };

    // 过滤掉仍在冷却期的 IP。
    let healthy: Vec<usize> = ips
        .iter()
        .enumerate()
        .filter(|(_, ip)| !unhealthy_ips.contains(ip))
        .map(|(idx, _)| idx)
        .collect();

    // 全都不健康时退化为使用全表：宁可用一个坏 IP 反复重试，也不要直接失败。
    let candidates: Vec<usize> = if healthy.is_empty() {
        (0..ips.len()).collect()
    } else {
        healthy
    };
    if candidates.is_empty() {
        return Ok(None);
    }

    let pick = candidates[cursor % candidates.len()];
    let ip = ips[pick].clone();

    if is_rejectable_front_ip(&ip) {
        tracing::warn!("fronting: refusing to use reserved address {}", ip);
        return Ok(None);
    }

    // 推进游标（按 IP 列表长度取模，保证与表长度一致）。
    if let Ok(mut state) = front_host_state().lock() {
        let next = (cursor + 1) % ips.len();
        state.cursor.insert(host.clone(), next);
    }

    Ok(Some(FrontTarget { host, ip }))
}

/// 把 URL 的主机部分替换成 IP，路径与查询串原样保留。
pub(crate) fn front_url_with_ip(url: &str, ip: &str) -> AnyResult<String> {
    let mut parsed =
        reqwest::Url::parse(url).with_context(|| crate::tr!("failed-to-parse-url", url = url))?;
    parsed
        .set_host(Some(ip))
        .map_err(|e| anyhow!("failed-to-set-url-host: {e}"))?;
    Ok(parsed.to_string())
}

/// 标记 IP 为不健康，冷却 `FRONT_UNHEALTHY_TTL`。
pub(crate) fn mark_front_host_unhealthy(ip: &str) {
    if let Ok(mut state) = front_host_state().lock() {
        state
            .unhealthy
            .insert(ip.to_string(), Instant::now() + FRONT_UNHEALTHY_TTL);
    }
    tracing::warn!("fronting: marked ip {} unhealthy", ip);
}

/// 创建用于前置请求的客户端。
///
/// 与普通客户端的差别：
/// - `http1_only()`：**关键**。HTTP/2 下 `:authority` 取自 URI（会是 IP），
///   Cloudflare / Apache 一律回 400。
/// - `Policy::none()`：不自动跟随重定向。里站大量使用 302（例如跳到
///   `forums.e-hentai.org/remoteapi.php`），跳转目标在墙内同样解析不到，
///   必须把 3xx 交回插件逐跳手动跟随。
/// - `danger_accept_invalid_certs(true)`：证书签给域名，用 IP 直连必然不匹配。
///   （宿主已在 `lib/main.dart` 全局关闭 TLS 校验，这里与既有用法保持一致。）
fn front_http_client(config: &HttpClientConfig) -> AnyResult<ClientWithMiddleware> {
    let mut builder = Client::builder()
        .timeout(FRONT_CLIENT_TIMEOUT)
        .http1_only()
        .redirect(Policy::none())
        .danger_accept_invalid_certs(true);

    if config.use_http_proxy {
        if let Some(proxy_raw) = config.http_proxy.as_deref() {
            let proxy_url = if proxy_raw.contains("://") {
                proxy_raw.to_string()
            } else {
                format!("http://{proxy_raw}")
            };
            let proxy = reqwest::Proxy::all(&proxy_url).with_context(|| {
                crate::tr!("failed-to-parse-http-proxy-address", proxy_url = proxy_url)
            })?;
            builder = builder.proxy(proxy);
        }
    }

    let client = builder
        .build()
        .context(crate::tr!("failed-to-create-http-client"))?;
    Ok(wrap_http_client(client))
}

/// 为前置请求挑选客户端（按当前 worker 配置缓存）。
///
/// 缓存键包含代理配置：用户在宿主设置里改代理后缓存自然换键并重建。
pub(crate) fn cached_front_client(config: &HttpClientConfig) -> AnyResult<ClientWithMiddleware> {
    let key = format!(
        "{}|{}|{}|{}",
        config.use_http_proxy,
        config.use_socks5_proxy,
        config.http_proxy.as_deref().unwrap_or(""),
        config.socks5_proxy.as_deref().unwrap_or("")
    );
    static FRONT_CLIENT_CACHE: OnceLock<Mutex<HashMap<String, ClientWithMiddleware>>> =
        OnceLock::new();
    let cache = FRONT_CLIENT_CACHE.get_or_init(|| Mutex::new(HashMap::new()));

    let mut guard = match cache.lock() {
        Ok(g) => g,
        Err(_) => return front_http_client(config),
    };
    if let Some(client) = guard.get(&key) {
        return Ok(client.clone());
    }
    let client = front_http_client(config)?;
    guard.insert(key, client.clone());
    Ok(client)
}

#[cfg(test)]
mod tests {
    use super::*;

    /// 前置表是进程级全局状态，测试之间会互相干扰，必须串行化。
    static TEST_LOCK: Mutex<()> = Mutex::new(());

    fn with_serialized_state<T>(f: impl FnOnce() -> T) -> T {
        let _guard = TEST_LOCK.lock().unwrap_or_else(|e| e.into_inner());
        f()
    }

    #[test]
    fn rejects_non_ip_entries() {
        with_serialized_state(|| {
            let result = set_front_hosts(
                json!({
                    "e-hentai.org": ["172.66.132.196", "not-an-ip", "999.1.1.1"],
                    "exhentai.org": [],
                })
                .to_string(),
            );
            let parsed: Value = serde_json::from_str(&result).unwrap();
            assert_eq!(parsed["ok"], json!(true));
            assert_eq!(parsed["hosts"], json!(1));
            assert_eq!(parsed["ips"], json!(1));
            assert_eq!(parsed["rejected"], json!(2));

            let readback: Value = serde_json::from_str(&get_front_hosts()).unwrap();
            let hosts = readback["hosts"].as_object().unwrap();
            assert_eq!(hosts.len(), 1);
            assert!(hosts.contains_key("e-hentai.org"));

            clear_front_hosts();
        });
    }

    #[test]
    fn rejects_invalid_json() {
        with_serialized_state(|| {
            let result = set_front_hosts("{not json".to_string());
            let parsed: Value = serde_json::from_str(&result).unwrap();
            assert_eq!(parsed["ok"], json!(false));
            assert!(parsed["error"].as_str().unwrap().contains("JSON"));
        });
    }

    #[test]
    fn longest_suffix_match_wins() {
        with_serialized_state(|| {
            set_front_hosts(
                json!({
                    "exhentai.org": ["1.1.1.1"],
                    "s.exhentai.org": ["2.2.2.2"],
                })
                .to_string(),
            );
            let state = front_host_state().lock().unwrap();
            assert_eq!(
                match_front_host(&state.hosts, "s.exhentai.org"),
                Some(&vec!["2.2.2.2".to_string()])
            );
            assert_eq!(
                match_front_host(&state.hosts, "exhentai.org"),
                Some(&vec!["1.1.1.1".to_string()])
            );
            assert_eq!(
                match_front_host(&state.hosts, "cdn.exhentai.org"),
                Some(&vec!["1.1.1.1".to_string()])
            );
            assert!(match_front_host(&state.hosts, "e-hentai.org").is_none());
            drop(state);
            clear_front_hosts();
        });
    }

    #[test]
    fn rewrite_keeps_path_and_query() {
        let rewritten = front_url_with_ip("https://e-hentai.org/g/1/token/?p=2", "172.66.132.196")
            .expect("rewrite should succeed");
        assert_eq!(rewritten, "https://172.66.132.196/g/1/token/?p=2");
    }

    #[test]
    fn reserved_addresses_are_refused() {
        assert!(is_rejectable_front_ip("127.0.0.1"));
        assert!(is_rejectable_front_ip("10.0.0.1"));
        assert!(is_rejectable_front_ip("192.168.1.1"));
        assert!(is_rejectable_front_ip("169.254.1.1"));
        assert!(is_rejectable_front_ip("100.64.0.1"));
        assert!(!is_rejectable_front_ip("172.66.132.196"));
        assert!(!is_rejectable_front_ip("178.175.128.251"));
    }

    #[test]
    fn unhealthy_ip_is_skipped() {
        with_serialized_state(|| {
            set_front_hosts(
                json!({ "e-hentai.org": ["172.66.132.196", "172.66.140.62"] }).to_string(),
            );
            mark_front_host_unhealthy("172.66.132.196");

            let first = resolve_front_target("https://e-hentai.org/")
                .unwrap()
                .unwrap();
            let second = resolve_front_target("https://e-hentai.org/")
                .unwrap()
                .unwrap();
            // 不健康的 IP 不应被选中。
            assert_ne!(first.ip, "172.66.132.196");
            assert_ne!(second.ip, "172.66.132.196");

            clear_front_hosts();
        });
    }

    #[test]
    fn no_fronting_when_table_is_empty() {
        with_serialized_state(|| {
            clear_front_hosts();
            assert!(resolve_front_target("https://e-hentai.org/").unwrap().is_none());
        });
    }
}
