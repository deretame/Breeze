// fetchcore —— 核心值类型与纯 C++ 工具（header-only）
//
// 本头是 fetchcore 的类型底座：Header/Headers/Request/Response/Options 均为
// 纯值类型，不含 JS guard/forbidden 检查与规范化逻辑（那些是 JS 规范语义，
// 留在绑定层）。同时收纳原 qjsbind::web 层的头操作、重定向判定、data: URL
// 与 SRI 摘要工具（纯 C++，随策略下沉迁入）。
//
// 依赖方向：本头只依赖 fetch/task.hpp + 标准库 + OpenSSL EVP；禁止 include
// 任何 quickjs/qjsbind 头。
#pragma once

#include <fetch/task.hpp>
#include <fetch/error.hpp>
#include <fetch/dns_resolver.hpp> // DnsCacheOptions / DnsResolver（DnsOptions 用）

#include <openssl/base64.h>
#include <openssl/evp.h>

#include <algorithm>
#include <cctype>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <limits>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace fetch {

struct BodySource; // 前向声明（body.hpp 定义；shared_ptr 允许不完整类型）

struct Header {
    std::string name;
    std::string value;
};

// 保序、允许重复名；大小写不敏感查找工具随库提供（has_header 等）。
using Headers = std::vector<Header>;

// TLS 选项（原 src/net TlsOptions 迁入）
struct TlsOptions {
    bool verify = true;                       // 默认校验证书（嵌入的 Mozilla CA bundle）
    std::vector<std::string> extra_trust_pem; // 追加信任的 PEM（测试/自签用）
};

// ---- 统一代理配置（配置层值类型；传输层参数仍用 HttpProxy/Socks5Proxy）----
// 三级优先级（高 → 低）：
//   1. 请求级：Request::proxy（每次请求配置）
//   2. 实例级：Options::proxy（Client 创建时配置）
//   3. 进程级：fetch::effective_process_proxy()（手动配置 > 系统自动读取，
//      见 process_proxy.hpp；系统自动仅产生 http 代理）
// parse() 接受的格式：
//   "http://[user:pass@]host:port" / "socks5://[user:pass@]host:port"
//   "host:port"（无 scheme 时默认 http）
//   IPv6 用 "[::1]:8080" 形式；无端口时用 scheme 默认（http=8080, socks5=1080）。
struct Proxy {
    enum class Kind { Http, Socks5 };
    Kind kind = Kind::Http;
    std::string host;
    uint16_t port = 0; // 0 = 未指定（parse 后恒为实际端口）
    std::optional<std::pair<std::string, std::string>> auth; // http: Basic；socks5: RFC 1929

    bool operator==(const Proxy&) const = default;

    // 解析代理 URL 字符串；非法格式 → nullopt
    static std::optional<Proxy> parse(std::string_view spec);

    // 直接构造工厂（测试/配置便捷用）
    static Proxy http(std::string host, uint16_t port = 8080,
                      std::optional<std::pair<std::string, std::string>> auth = std::nullopt)
    {
        Proxy p;
        p.kind = Kind::Http;
        p.host = std::move(host);
        p.port = port;
        p.auth = std::move(auth);
        return p;
    }
    static Proxy socks5(std::string host, uint16_t port = 1080,
                        std::optional<std::pair<std::string, std::string>> auth = std::nullopt)
    {
        Proxy p;
        p.kind = Kind::Socks5;
        p.host = std::move(host);
        p.port = port;
        p.auth = std::move(auth);
        return p;
    }
};

inline std::optional<Proxy> Proxy::parse(std::string_view s)
{
    // 去首尾空白
    while (!s.empty() && (s.front() == ' ' || s.front() == '\t'))
        s.remove_prefix(1);
    while (!s.empty() && (s.back() == ' ' || s.back() == '\t'))
        s.remove_suffix(1);
    if (s.empty())
        return std::nullopt;

    Proxy p;
    const size_t scheme_end = s.find("://");
    if (scheme_end != std::string_view::npos) {
        std::string_view sch = s.substr(0, scheme_end);
        // scheme 大小写不敏感（WHATWG URL scheme 语义）
        auto eq_ci = [](std::string_view a, std::string_view b) {
            if (a.size() != b.size())
                return false;
            for (size_t i = 0; i < a.size(); ++i)
                if ((a[i] | 32) != (b[i] | 32))
                    return false;
            return true;
        };
        const bool is_socks = eq_ci(sch, "socks5") || eq_ci(sch, "socks");
        const bool is_http = eq_ci(sch, "http");
        if (!is_socks && !is_http)
            return std::nullopt; // https://（HTTPS 代理，代理连接 TLS）不支持
        p.kind = is_socks ? Proxy::Kind::Socks5 : Proxy::Kind::Http;
        s.remove_prefix(scheme_end + 3);
    }

    // userinfo（最后一个 '@' 之前；user 可无 pass）
    const size_t at = s.rfind('@');
    if (at != std::string_view::npos) {
        std::string_view ui = s.substr(0, at);
        const size_t pc = ui.find(':');
        if (pc != std::string_view::npos)
            p.auth = std::make_pair(std::string(ui.substr(0, pc)),
                                    std::string(ui.substr(pc + 1)));
        else
            p.auth = std::make_pair(std::string(ui), std::string());
        s.remove_prefix(at + 1);
    }
    if (s.empty())
        return std::nullopt;

    const uint16_t def_port = p.kind == Proxy::Kind::Socks5 ? 1080 : 8080;
    // 端口解析（纯数字；1-65535；0 非法）
    auto take_port = [&](std::string_view ps) -> bool {
        if (ps.empty())
            return false;
        unsigned long v = 0;
        for (char c : ps) {
            if (c < '0' || c > '9')
                return false;
            v = v * 10 + static_cast<unsigned long>(c - '0');
            if (v > 65535)
                return false;
        }
        if (v == 0)
            return false;
        p.port = static_cast<uint16_t>(v);
        return true;
    };

    if (s.front() == '[') { // IPv6 字面量
        const size_t close = s.find(']');
        if (close == std::string_view::npos)
            return std::nullopt;
        p.host = std::string(s.substr(1, close - 1));
        if (p.host.empty())
            return std::nullopt;
        s.remove_prefix(close + 1);
        if (s.empty()) {
            p.port = def_port;
            return p;
        }
        if (s.front() != ':' || !take_port(s.substr(1)))
            return std::nullopt;
        return p;
    }

    const size_t pc = s.rfind(':');
    if (pc == std::string_view::npos) {
        p.host = std::string(s);
        p.port = def_port;
    } else {
        p.host = std::string(s.substr(0, pc));
        if (p.host.find(':') != std::string_view::npos)
            return std::nullopt; // 非 IPv6 形式不允许 host 内含冒号
        if (!take_port(s.substr(pc + 1)))
            return std::nullopt;
    }
    if (p.host.empty())
        return std::nullopt;
    return p;
}

// ---- 按 URL 匹配的代理路由（实例级配置，声明式）----
// 命中规则即生效（优先于 Options::proxy 与进程级配置），含"直连规则"
// （proxy == nullopt → 直连，不再回落进程级）。
// match 形态：
//   "*"                → 匹配全部 URL
//   "example.com"      → host 后缀匹配（example.com 与 *.example.com，大小写不敏感）
//   "/path"            → URL 路径前缀匹配（以 '/' 开头即路径模式，大小写敏感）
struct ProxyRoute {
    std::string match;
    std::optional<Proxy> proxy; // nullopt = 直连（no_proxy 语义）
};

// 提取 URL 的 host（不含端口/userinfo；IPv6 去方括号；解析失败 → 空串）
inline std::string_view url_host(std::string_view url)
{
    const size_t p = url.find("://");
    if (p == std::string_view::npos)
        return {};
    size_t h = p + 3;
    // userinfo：仅当 '@' 出现在第一个 /?# 之前（路径/query 里的 @ 不算）
    const size_t auth_end = url.find_first_of("/?#", h);
    const size_t at = url.find('@', h);
    if (at != std::string_view::npos &&
        (auth_end == std::string_view::npos || at < auth_end))
        h = at + 1;
    const size_t e = url.find_first_of("/?#", h);
    const std::string_view auth =
        url.substr(h, e == std::string_view::npos ? std::string_view::npos : e - h);
    if (auth.empty())
        return {};
    if (auth.front() == '[') { // IPv6 字面量
        const size_t close = auth.find(']');
        return close == std::string_view::npos ? auth : auth.substr(1, close - 1);
    }
    const size_t colon = auth.rfind(':');
    return colon == std::string_view::npos ? auth : auth.substr(0, colon);
}

// 提取 URL 的路径（含前导 '/'；不含 query/fragment；无路径 → "/"）
inline std::string_view url_path(std::string_view url)
{
    const size_t p = url.find("://");
    const size_t start = p == std::string_view::npos ? 0 : p + 3;
    const size_t slash = url.find('/', start);
    if (slash == std::string_view::npos)
        return "/";
    const size_t e = url.find_first_of("?#", slash);
    return url.substr(slash, e == std::string_view::npos ? std::string_view::npos : e - slash);
}

// host 后缀匹配（大小写不敏感）："example.com" 匹配 example.com / a.example.com；
// "*" 匹配全部
inline bool host_matches_suffix(std::string_view host, std::string_view suffix)
{
    if (suffix == "*")
        return true;
    if (suffix.empty())
        return false; // 空后缀永不匹配（子域分支空循环恒 true 的洞）
    auto eq_ci = [](std::string_view a, std::string_view b) {
        if (a.size() != b.size())
            return false;
        for (size_t i = 0; i < a.size(); ++i)
            // tolower 而非 |32：|32 会让非字母字符错误相等（如 '@'|32 == '`'）
            if (std::tolower(static_cast<unsigned char>(a[i])) !=
                std::tolower(static_cast<unsigned char>(b[i])))
                return false;
        return true;
    };
    if (eq_ci(host, suffix))
        return true;
    // 子域：host 以 ".suffix" 结尾（分隔点两侧均大小写不敏感比较）
    if (host.size() > suffix.size() + 1) {
        const size_t off = host.size() - suffix.size();
        if (host[off - 1] == '.') {
            bool eq = true;
            for (size_t i = 0; i < suffix.size(); ++i)
                if (std::tolower(static_cast<unsigned char>(host[off + i])) !=
                    std::tolower(static_cast<unsigned char>(suffix[i]))) {
                    eq = false;
                    break;
                }
            if (eq)
                return true;
        }
    }
    return false;
}

// ProxyRoute 匹配：路径模式（以 '/' 开头，大小写敏感）或 host 后缀模式
inline bool url_matches_route(std::string_view url, std::string_view match)
{
    if (match.empty())
        return false; // 空规则永不命中（避免空后缀匹配"以点结尾的 FQDN"）
    if (match == "*")
        return true;
    if (!match.empty() && match.front() == '/') {
        const std::string_view path = url_path(url);
        return path.size() >= match.size() && path.substr(0, match.size()) == match;
    }
    return host_matches_suffix(url_host(url), match);
}

struct Request {
    std::string method = "GET";
    std::string url;            // 绝对 http/https/data URL（相对 URL 解析是绑定层职责）
    Headers headers;
    std::string body;           // 整收（现有语义）；body_stream 非空时忽略
    std::shared_ptr<BodySource> body_stream; // 流式请求体（nullptr = 无；优先于 body）
    size_t body_size = 0;       // 流式体已知总长（Content-Length 用；body_stream 时必须
                                // >0，否则 BodyLengthMiddleware 抛 fetch::Error）
    std::string integrity;      // SRI 表达式，空 = 不校验
    enum class Redirect { follow, error, manual } redirect = Redirect::follow;
    std::optional<Proxy> proxy; // 请求级代理（最高优先级；nullopt = 未配置，
                                // 回落实例级/进程级）；重定向各跳沿用
};

struct Response {
    int status = 0;
    std::string reason;
    Headers headers;
    std::string url;            // 最终 URL（重定向后）
    bool redirected = false;
    std::shared_ptr<BodySource> body; // null = 无 body（HEAD/204/205/304）；拉模型，64 KiB 块
};

// ---- 连接池键与配置（docs/fetch_connection_pool_design.md §3.3/§3.8/§3.9）----
// 键 = hyper 的 (Scheme, Authority) 扩展版：代理选路在中间件层（逐请求可变），
// TLS 选项产生的连接不能混用，故 proxy_id 与 tls_fingerprint 必须进键。
struct PoolKey {
    std::string scheme;          // "http" | "https"
    std::string host;            // 小写规范化后的目标 host（或代理 host，见 §3.8）
    uint16_t port = 0;           // 显式化后的端口（http=80, https=443）
    std::string proxy_id;        // 空 = 直连；否则 "socks5://u@h:p" / "connect://u@h:p" / "http://u@h:p"
    std::string tls_fingerprint; // 空 = 明文；否则 TLS 选项指纹（verify/额外 CA），见 §3.9
    bool operator==(const PoolKey&) const = default;
};

struct PoolKeyHash {
    size_t operator()(const PoolKey& k) const noexcept
    {
        // FNV-1a（确定性、无 std::hash 抖动）
        size_t h = 1469598103934665603ull;
        auto mix = [&](std::string_view v) {
            for (unsigned char c : v) {
                h ^= c;
                h *= 1099511628211ull;
            }
        };
        mix(k.scheme);
        mix(k.host);
        mix(k.proxy_id);
        mix(k.tls_fingerprint);
        h ^= k.port;
        h *= 1099511628211ull;
        return h;
    }
};

// 池配置（对齐 reqwest 暴露面；默认值照抄 hyper/reqwest）：
//   idle_timeout = 90s（nullopt = 永不过期）；max_idle_per_host = 无上限；
//   retry_on_reused_failure = true（陈旧连接失败自动重试一次）。
// 注意默认 90s 与常见服务端 keep-alive 超时（如 nginx 75s）倒挂：靠
// retry_on_reused_failure 吸收；若目标服务端超时更短，调小 idle_timeout
// 可减少首包重试。
struct PoolOptions {
    std::optional<std::chrono::milliseconds> idle_timeout = std::chrono::seconds{90};
    size_t max_idle_per_host = std::numeric_limits<size_t>::max();
        // 0 = 禁用池（对应 hyper Config::is_enabled() == false / reqwest pool_max_idle_per_host(0)）
    bool retry_on_reused_failure = true;
        // 对应 hyper retry_canceled_requests（默认 true）
};

// DoH（DNS over HTTPS，RFC 8484）配置（docs/dns_resolver_design.md §4.2）
struct DohOptions {
    std::string endpoint; // 如 https://1.1.1.1/dns-query；必须 https。
                          // 建议 host 用字面 IP；非字面 IP 时经 SystemResolver 解析
                          // DoH 服务器域名（绝不递归进 DohResolver 自身，见 §4.2 循环依赖）
    bool fallback_to_system = true;              // DoH 失败回落系统解析（对齐 Firefox 语义）
    std::chrono::milliseconds timeout{5000};     // 单次 DoH 查询超时（超时走 fallback）
};

// DNS 配置（docs/dns_resolver_design.md §5）
struct DnsOptions {
    bool cache_enabled = true;       // 默认开缓存（行为改进，无 API 变化）
    DnsCacheOptions cache{};
    std::shared_ptr<DnsResolver> custom_resolver; // 非空则完全接管（测试/高级用户）
    std::optional<DohOptions> doh;   // 非空 → CachingResolver{DohResolver}（§4.2，
                                     // 负缓存/singleflight 由缓存层免费获得）
};

struct Options {
    TlsOptions tls{};            // 默认 BeastTransport 的 TLS 配置（注入自定义 Transport 时忽略）
    bool auto_decompress = true; // 内建 Accept-Encoding 中间件开关（固定最外层）
    int max_redirects = 20;
    // 自动解压的总字节上限（gzip bomb 防护；security review MEDIUM）。
    // 0 = 无限制；默认 256 MiB——单块上限 1 MiB 控峰值，此值控总量。
    size_t max_decompressed_bytes = 256 * 1024 * 1024;
    PoolOptions pool{};          // 连接池配置（默认开启 keep-alive 复用；见上）
    DnsOptions dns{};            // DNS 解析器/缓存配置（BeastTransport 构造时组装，§5）
    std::optional<Proxy> proxy;  // 实例级代理（Client 创建时配置；中等优先级，
                                 // 低于 Request::proxy，高于进程级）
    std::vector<ProxyRoute> proxy_routes; // 实例级按 URL 分流规则（声明式；
                                          // 命中即用，优先于 proxy 与进程级）
};

// ---- 头操作工具（原 interceptor.hpp 迁入）----

// 大小写不敏感比较
inline bool header_name_eq(std::string_view a, std::string_view b)
{
    return a.size() == b.size() &&
           std::equal(a.begin(), a.end(), b.begin(),
                      [](char x, char y) { return (x | 32) == (y | 32); });
}

inline bool has_header(const Headers& headers, std::string_view name)
{
    for (const auto& h : headers)
        if (header_name_eq(h.name, name))
            return true;
    return false;
}

inline void strip_headers(Headers& headers, std::initializer_list<const char*> names)
{
    headers.erase(std::remove_if(headers.begin(), headers.end(), [&](const Header& h) {
                      for (const char* n : names)
                          if (header_name_eq(h.name, n))
                              return true;
                      return false;
                  }),
                  headers.end());
}

// 取单一 content-encoding（逗号多个 → nullopt；identity/无 → nullopt）
inline std::optional<std::string> single_content_encoding(const Headers& headers)
{
    for (const auto& h : headers) {
        if (header_name_eq(h.name, "content-encoding")) {
            const std::string& v = h.value;
            if (v.find(',') != std::string::npos)
                return std::nullopt; // 多编码：不处理透传（避免歧义）
            std::string enc = v;
            enc.erase(std::remove_if(enc.begin(), enc.end(), [](char c) { return c == ' '; }),
                      enc.end());
            std::transform(enc.begin(), enc.end(), enc.begin(),
                           [](char c) { return static_cast<char>(c | 32); });
            if (enc.empty() || enc == "identity")
                return std::nullopt;
            return enc;
        }
    }
    return std::nullopt;
}

// ---- 重定向判定工具（原 fetch_detail 迁入）----

inline bool is_redirect_status(int status)
{
    return status == 301 || status == 302 || status == 303 || status == 307 || status == 308;
}

inline bool status_requires_get(int status, const std::string& method)
{
    // 303：仅非 GET/HEAD 转 GET；301/302：仅 POST 转 GET
    if (status == 303)
        return method != "GET" && method != "HEAD";
    if ((status == 301 || status == 302) && method == "POST")
        return true;
    return false;
}

// 从响应头取 Location（大小写不敏感；无 → 空串）
inline std::string location_of(const Headers& headers)
{
    for (const auto& h : headers)
        if (header_name_eq(h.name, "location"))
            return h.value;
    return {};
}

inline Headers without_body_headers(const Headers& headers)
{
    Headers out;
    for (const auto& h : headers) {
        // 重定向转 GET/HEAD 后剥离全部 body 相关头（fetch 规范；wpt redirect-method）
        if (!header_name_eq(h.name, "content-length") &&
            !header_name_eq(h.name, "content-type") &&
            !header_name_eq(h.name, "content-encoding") &&
            !header_name_eq(h.name, "content-language") &&
            !header_name_eq(h.name, "content-location"))
            out.push_back(h);
    }
    return out;
}

// ---- data: URL（WHATWG data URL processor，fetch 规范 §data URL）----

inline std::string percent_decode(const std::string& in)
{
    std::string out;
    auto hex = [](char c) -> int {
        if (c >= '0' && c <= '9') return c - '0';
        if (c >= 'a' && c <= 'f') return c - 'a' + 10;
        if (c >= 'A' && c <= 'F') return c - 'A' + 10;
        return -1;
    };
    for (size_t i = 0; i < in.size(); ++i) {
        if (in[i] == '%' && i + 2 < in.size()) {
            const int h = hex(in[i + 1]), l = hex(in[i + 2]);
            if (h >= 0 && l >= 0) {
                out.push_back(static_cast<char>((h << 4) | l));
                i += 2;
                continue;
            }
        }
        out.push_back(in[i]);
    }
    return out;
}

// 标准 base64 解码；失败（非法字符/长度）返回空 optional
// 直接调用 BoringSSL EVP_DecodeBase64（<openssl/base64.h>）。
// 与 WHATWG data URL 语义对齐：非法字符/非法 padding → 失败。
// 未补齐 padding 的输入（长度非 4 倍数）补 '=' 后解码（保持原有宽松行为；
// 但单个余字符不可能是合法 base64 → 失败）。
inline std::optional<std::string> base64_decode(const std::string& in)
{
    if (in.empty())
        return std::string();
    std::string padded = in;
    const size_t rem = padded.size() % 4;
    if (rem != 0) {
        if (rem == 1)
            return std::nullopt;
        padded.append(4 - rem, '=');
    }
    size_t max_out = 0;
    if (!EVP_DecodedLength(&max_out, padded.size()))
        return std::nullopt;
    std::string out(max_out, '\0');
    size_t out_len = 0;
    if (!EVP_DecodeBase64(reinterpret_cast<uint8_t*>(out.data()), &out_len, max_out,
                          reinterpret_cast<const uint8_t*>(padded.data()), padded.size()))
        return std::nullopt;
    out.resize(out_len);
    return out;
}

// 解析 data URL（入参为 URL 层已编码的字符串）。成功返回 true 并填充
// mime（Content-Type 头）与 body（解码后的原始字节）。
inline bool parse_data_url(const std::string& url, std::string& mime_out,
                           std::string& body_out)
{
    const size_t comma = url.find(',');
    if (comma == std::string::npos)
        return false; // 无逗号 → 解析失败
    std::string meta = url.substr(5, comma - 5); // "data:" 之后、逗号之前
    std::string data = url.substr(comma + 1);
    bool is_base64 = false;
    const size_t semi = meta.rfind(';');
    if (semi != std::string::npos) {
        std::string last = meta.substr(semi + 1);
        for (auto& c : last)
            c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
        if (last == "base64") {
            is_base64 = true;
            meta = meta.substr(0, semi);
        }
    }
    // MIME 规范化：无 type/subtype → 默认；type/subtype 与参数名小写，参数值保留
    if (meta.find('/') == std::string::npos) {
        mime_out = "text/plain;charset=US-ASCII";
    } else {
        std::string out;
        bool in_param_value = false;
        for (size_t i = 0; i < meta.size(); ++i) {
            const char c = meta[i];
            if (c == ';') {
                in_param_value = false;
                out.push_back(c);
            } else if (c == '=') {
                in_param_value = true;
                out.push_back(c);
            } else if (!in_param_value && (c == ' ' || c == '\t')) {
                continue; // 参数名/类型段去空白
            } else if (!in_param_value) {
                out.push_back(static_cast<char>(std::tolower(static_cast<unsigned char>(c))));
            } else {
                out.push_back(c);
            }
        }
        mime_out = out;
    }
    if (is_base64) {
        auto decoded = base64_decode(data);
        if (!decoded)
            return false; // base64 非法 → 解析失败
        body_out = std::move(*decoded);
    } else {
        body_out = percent_decode(data);
    }
    return true;
}

// ---- SRI（Subresource Integrity）----
inline std::string sha_digest(const std::string& algo, const std::string& data)
{
    const EVP_MD* md = nullptr;
    if (algo == "sha256")
        md = EVP_sha256();
    else if (algo == "sha384")
        md = EVP_sha384();
    else if (algo == "sha512")
        md = EVP_sha512();
    if (!md)
        return {};
    unsigned char buf[EVP_MAX_MD_SIZE];
    unsigned int len = 0;
    EVP_Digest(data.data(), data.size(), buf, &len, md, nullptr);
    return std::string(reinterpret_cast<char*>(buf), len);
}

inline std::string base64_encode(const std::string& in)
{
    // BoringSSL EVP_EncodeBlock：标准 base64（带 padding，无换行）
    size_t cap = 0;
    if (!EVP_EncodedLength(&cap, in.size()))
        return {};
    std::string out(cap, '\0'); // cap = 编码长度 + 1（EVP_EncodeBlock 写 NUL 位）
    const size_t n = EVP_EncodeBlock(reinterpret_cast<uint8_t*>(out.data()),
                                     reinterpret_cast<const uint8_t*>(in.data()),
                                     in.size());
    out.resize(n);
    return out;
}

// 比对：url-safe 变体归一化（-/_ → +//）+ 去 padding
inline bool digest_matches(const std::string& expected, const std::string& actual)
{
    auto norm = [](std::string s) {
        for (auto& c : s) {
            if (c == '-')
                c = '+';
            else if (c == '_')
                c = '/';
        }
        while (!s.empty() && s.back() == '=')
            s.pop_back();
        return s;
    };
    return norm(expected) == norm(actual);
}

// 校验响应体摘要（SRI）。不匹配/无法校验 → fetch::Error。
// 注：body 为空串调用仅用于"null body"立即校验（status/method 判定）。
inline void check_integrity(const std::string& integrity, int status,
                            const std::string& method, const std::string& body)
{
    if (integrity.empty())
        return;
    // 规范：null body（null body status 或 HEAD）无法校验 → 网络错误
    const bool null_body = status == 204 || status == 205 || status == 304 || method == "HEAD";
    if (null_body)
        throw Error("fetch: integrity 无法校验 null body 响应");
    std::string cur;
    auto verify_item = [&](const std::string& item) {
        const size_t dash = item.find('-');
        if (dash == std::string::npos)
            return false;
        const std::string actual = base64_encode(sha_digest(item.substr(0, dash), body));
        return digest_matches(item.substr(dash + 1), actual);
    };
    bool matched = false;
    for (const char c : integrity + " ") {
        if (c == ' ') {
            if (!cur.empty() && verify_item(cur))
                matched = true;
            cur.clear();
        } else {
            cur.push_back(c);
        }
    }
    if (!matched)
        throw Error("fetch: integrity 校验失败");
}

} // namespace fetch
