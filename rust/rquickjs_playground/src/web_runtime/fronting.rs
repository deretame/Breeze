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
//!
//! # 启用方式
//!
//! Flutter 构建默认编译进产物（`hook/build.dart` 固定传 `--features host-fronting`），
//! 需要关闭时设置环境变量 `BREEZE_HOST_FRONTING=0` 后重新构建。
//! 直接跑 cargo 时用 `cargo build --features host-fronting`。
//! 未启用时三个全局函数不注册，插件探测到缺失会静默降级。
//!
//! 注意：默认开启只是让宿主「具备能力」；插件不调用 `__http_set_front_hosts`
//! 时前置表为空，所有请求仍走原链路。
//!
//! # 信任模型
//!
//! 前置表是**进程级全局状态**，任意插件都能写入 / 清空；宿主只校验 IP 是公网
//! 地址，不校验 host 白名单（白名单由插件维护）。因此该能力默认关闭，只应在
//! 可信插件组合下启用。

use std::collections::HashMap;
use std::net::IpAddr;
use std::str::FromStr;
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};

use anyhow::{Context as _, Result as AnyResult, anyhow};
use reqwest::Client;
use reqwest::redirect::Policy;
use reqwest_middleware::ClientWithMiddleware;
use serde_json::{Value, json};

use super::http::{HttpClientConfig, apply_proxy_config, wrap_http_client};

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
/// - 非 IP 字面量与保留地址段（环回 / 内网 / 链路本地等）在写入时就被拒绝，
///   计入 `rejected`，避免它们在每次请求时再被判断。
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
                    if !is_valid_front_ip(&ip) || is_rejectable_front_ip(&ip) {
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

    // 从游标位置起按全表顺序找第一个健康 IP；全都不健康时退化为游标位置，
    // 宁可用坏 IP 反复重试，也不要直接失败。游标始终按全表长度推进，
    // 这样过滤掉部分 IP 后仍能均匀轮询。
    let start = cursor % ips.len();
    let pick = (0..ips.len())
        .map(|offset| (start + offset) % ips.len())
        .find(|idx| !unhealthy_ips.contains(&ips[*idx]))
        .unwrap_or(start);
    let ip = ips[pick].clone();

    if is_rejectable_front_ip(&ip) {
        tracing::warn!("fronting: refusing to use reserved address {}", ip);
        return Ok(None);
    }

    // 推进游标：从本次选中的 IP 之后继续，保证健康 IP 之间均匀轮询。
    if let Ok(mut state) = front_host_state().lock() {
        let next = (pick + 1) % ips.len();
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

    // 与普通客户端共用代理逻辑（HTTP 优先、可回落 SOCKS5）。
    builder = apply_proxy_config(builder, config)?;

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
            assert!(
                resolve_front_target("https://e-hentai.org/")
                    .unwrap()
                    .is_none()
            );
        });
    }

    /// 只映射一个域名时，其他域名必须完全不受影响。
    #[test]
    fn only_mapped_hosts_are_fronted() {
        with_serialized_state(|| {
            set_front_hosts(
                json!({
                    "e-hentai.org": ["172.66.132.196"],
                    "exhentai.org": ["178.175.128.251"],
                })
                .to_string(),
            );

            let eh = resolve_front_target("https://e-hentai.org/g/1/")
                .unwrap()
                .unwrap();
            assert_eq!(eh.host, "e-hentai.org");
            assert_eq!(eh.ip, "172.66.132.196");

            let ex = resolve_front_target("https://exhentai.org/")
                .unwrap()
                .unwrap();
            assert_eq!(ex.host, "exhentai.org");
            assert_eq!(ex.ip, "178.175.128.251");

            // 子域名跟随父域的映射。
            let cdn = resolve_front_target("https://s.exhentai.org/x")
                .unwrap()
                .unwrap();
            assert_eq!(cdn.ip, "178.175.128.251");

            // 未映射的域名、相似后缀、非子域字符串后缀一律不前置。
            for url in [
                "https://example.com/",
                "https://evil-e-hentai.org/",
                "https://e-hentai.org.evil.com/",
                "https://e-hentai.org.cn/",
                "https://notexhentai.org/",
            ] {
                assert!(
                    resolve_front_target(url).unwrap().is_none(),
                    "{url} should not be fronted"
                );
            }

            clear_front_hosts();
        });
    }

    #[test]
    fn reserved_ips_are_rejected_at_set_time() {
        with_serialized_state(|| {
            let result = set_front_hosts(
                json!({ "e-hentai.org": ["127.0.0.1", "10.0.0.1", "172.66.132.196"] }).to_string(),
            );
            let parsed: Value = serde_json::from_str(&result).unwrap();
            assert_eq!(parsed["ok"], json!(true));
            assert_eq!(parsed["hosts"], json!(1));
            assert_eq!(parsed["ips"], json!(1));
            assert_eq!(parsed["rejected"], json!(2));
            clear_front_hosts();
        });
    }

    #[test]
    fn rotation_alternates_between_healthy_ips() {
        with_serialized_state(|| {
            set_front_hosts(
                json!({
                    "e-hentai.org": ["172.66.132.196", "172.66.140.62", "178.175.128.251"],
                })
                .to_string(),
            );
            mark_front_host_unhealthy("172.66.140.62");

            let picks: Vec<String> = (0..4)
                .map(|_| {
                    resolve_front_target("https://e-hentai.org/")
                        .unwrap()
                        .unwrap()
                        .ip
                })
                .collect();
            // 中间那个 IP 在冷却，剩下两个应严格交替，而不是一直命中同一个。
            assert_eq!(picks[0], "172.66.132.196");
            assert_eq!(picks[1], "178.175.128.251");
            assert_eq!(picks[2], "172.66.132.196");
            assert_eq!(picks[3], "178.175.128.251");

            clear_front_hosts();
        });
    }

    /// feature 打开时必须注册三个全局函数，否则插件会误判「宿主不支持」。
    #[cfg(feature = "host-fronting")]
    #[test]
    fn globals_are_registered_with_feature_enabled() {
        let script = r#"
            JSON.stringify({
              set: typeof __http_set_front_hosts,
              get: typeof __http_get_front_hosts,
              clear: typeof __http_clear_front_hosts,
            })
        "#;
        let result = crate::tests::run_async_script(script).expect("script should run");
        let parsed: Value = serde_json::from_str(&result).expect("result should be JSON");
        assert_eq!(parsed["set"], json!("function"));
        assert_eq!(parsed["get"], json!("function"));
        assert_eq!(parsed["clear"], json!("function"));
    }

    /// 默认构建（feature 关闭）不得暴露这三个函数，保证零行为变化。
    #[cfg(not(feature = "host-fronting"))]
    #[test]
    fn globals_are_absent_without_feature() {
        let script = r#"
            JSON.stringify({
              set: typeof __http_set_front_hosts,
              get: typeof __http_get_front_hosts,
              clear: typeof __http_clear_front_hosts,
            })
        "#;
        let result = crate::tests::run_async_script(script).expect("script should run");
        let parsed: Value = serde_json::from_str(&result).expect("result should be JSON");
        assert_eq!(parsed["set"], json!("undefined"));
        assert_eq!(parsed["get"], json!("undefined"));
        assert_eq!(parsed["clear"], json!("undefined"));
    }
}
