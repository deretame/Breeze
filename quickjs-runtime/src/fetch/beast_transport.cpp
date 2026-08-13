// fetchcore —— BeastTransport 实现（原 qjsbind_net http_client.cpp 演进）
//
// 设计注释见 include/fetch/beast_transport.hpp。本文件是 fetchcore 的实现侧：
// 只依赖 fetch 公共类型 + asio/beast/OpenSSL，无任何 quickjs/qjsbind 依赖。
//
// 连接池（docs/fetch_connection_pool_design.md）：本类参数化承载池能力。
//   - pool_ 非空：三个入口先 checkout 复用，未命中再走既有建连路径；body 读干
//     且 keep-alive → 归还；复用连接失败（响应头一字未达）→ 自动重试一次。
//   - pool_ 为空：行为与旧版完全一致（连接用完即关）。
//   - TLS 连接：IdleEntry 携带 ssl::context（shared_ptr，随连接存活）；池化时
//     ssl::context 走 LRU 缓存（tls_fingerprint → ctx，容量 32）。
#include "socks5.hpp"
#include "http_proxy.hpp"
#include "connect_util.hpp"
#include "cacert_embedded.hpp" // 脚本生成：fetch::embedded_cacert_pem

#include <fetch/beast_transport.hpp>
#include <fetch/body.hpp> // BodySource 完整定义（BeastBodySource 继承 + shared_ptr 转换）
#include <fetch/doh_resolver.hpp> // DohResolver（DnsOptions::doh 组装，§4.2）
#include <fetch/url_check.hpp> // origin_form_target（origin-form 请求行 target）

#include <boost/asio/ssl.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <boost/beast/ssl.hpp>
#include <exec/asio/use_sender.hpp>

#include <ada.h>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdint>
#include <functional>
#include <limits>
#include <list>
#include <memory>
#include <mutex>
#include <optional>
#include <stdexcept>
#include <tuple>
#include <type_traits>
#include <unordered_map>
#include <utility>

#include <cctype>
#include <cstring>

#include <openssl/bio.h>
#include <openssl/err.h>
#include <openssl/pem.h>
#include <openssl/ssl.h> // TLS1_2_VERSION 在 BoringSSL 定义于 ssl.h（tls1.h 不含）
#include <openssl/tls1.h>
#include <openssl/x509.h>

namespace fetch {
namespace {

using boost::asio::ip::tcp;
namespace beast = boost::beast;
namespace http = beast::http;
namespace ssl = boost::asio::ssl;
namespace asio = boost::asio;

struct ParsedUrl {
    std::string scheme; // "http" / "https"
    std::string host;   // 不含端口；IPv6 文字地址保留方括号（"[::1]"）
    std::string port;   // 端口字符串
    std::string target; // /path?query（空则 "/"）
};

// URL 解析：ada（WHATWG 标准解析器）；仅 http/https。
// scheme 大小写不敏感比较（HTTP:// 等大写形式与 WHATWG 语义一致——ada
// 解析后 scheme 已小写化，此处按规范语义比较）。
// 校验失败抛 std::invalid_argument。
ParsedUrl parse_url(const std::string& url) {
    auto r = ada::parse<ada::url_aggregator>(url);
    if (!r)
        throw std::invalid_argument("url: 无法解析");
    const auto& u = *r;
    auto scheme_eq = [&](const char* s) {
        const std::string_view sc = u.get_protocol(); // "http:"（带冒号）
        return sc.size() == std::strlen(s) + 1 &&
               std::equal(sc.begin(), sc.end() - 1, s,
                          [](char a, char b) { return (a | 32) == b; });
    };
    if (!scheme_eq("http") && !scheme_eq("https"))
        throw std::invalid_argument("url: 仅支持 http/https scheme");
    if (u.get_hostname().empty())
        throw std::invalid_argument("url: 缺少 host");
    // userinfo（http://user:pass@host/）显式拒绝（对齐 WHATWG fetch："URL
    // includes credentials"）——凭据应走 Authorization 头，URL 内嵌凭据易落日志。
    // 用 ada 解析后的 username/password 判定，天然区分 userinfo 的 '@' 与
    // IPv6 字面量（[::1]）及 path/query 中的 '@'。
    if (!u.get_username().empty() || !u.get_password().empty())
        throw std::invalid_argument(
            "url: 包含凭据（user:pass@）的 URL 不被支持，请改用 Authorization 头");
    // ada（WHATWG）host 解析已拒绝含控制字符的 host（forbidden host code
    // point，%0d/%0a 等 percent-decode 后即解析失败）——无需额外检查。
    ParsedUrl out;
    out.scheme = std::string(u.get_protocol());
    out.scheme.pop_back(); // 去冒号（"https:" → "https"）
    for (auto& c : out.scheme)
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    out.host = std::string(u.get_hostname()); // WHATWG 序列化：IPv6 带方括号
                                              //（"[::1]"），与 socks5/http_proxy
                                              // 的处理形态一致
    const std::string port_str(u.has_port() ? std::string(u.get_port()) : "");
    out.port = u.has_port() ? port_str : (out.scheme == "https" ? "443" : "80");
    if (u.has_port() && port_str.empty())
        throw std::invalid_argument("url: 端口非法"); // 空端口（"http://h:/x"）防御
    // target = path[?query]（origin_form_target 保留空 query 的 '?'：
    // HTTP origin-form 中 "/x?" 与 "/x" 语义不同）
    out.target = origin_form_target(u);
    if (out.target.empty())
        out.target = "/";
    return out;
}

// SNI 只对 reg-name 域名发送；IP 字面量按 RFC 6066 §3 不得作为 SNI（且部分
// 服务器会直接拒绝 IP SNI），故跳过。
bool is_ip_literal(const std::string& host) {
    boost::system::error_code ec;
    boost::asio::ip::make_address(host, ec);
    return !ec;
}

// 把 PEM 中的全部证书加载进 context 的 X509_STORE（内存加载，不落盘）。
void load_pem_into_store(ssl::context& ctx, std::string_view pem) {
    BIO* bio = BIO_new_mem_buf(pem.data(), static_cast<int>(pem.size()));
    if (!bio)
        throw std::runtime_error("TLS: BIO_new_mem_buf 失败");
    X509_STORE* store = SSL_CTX_get_cert_store(ctx.native_handle());
    X509* cert = nullptr;
    while ((cert = PEM_read_bio_X509(bio, nullptr, nullptr, nullptr)) != nullptr) {
        if (X509_STORE_add_cert(store, cert) != 1) {
            X509_free(cert);
            BIO_free(bio);
            throw std::runtime_error("TLS: X509_STORE_add_cert 失败");
        }
        X509_free(cert);
    }
    const unsigned long err = ERR_peek_last_error();
    BIO_free(bio);
    // 正常结束：读到文件尾（无错误，或最后一个错误是 NO_START_LINE）。
    // 其余 PEM 错误（如 base64 损坏）视为解析失败。
    if (err != 0 && (ERR_GET_LIB(err) != ERR_LIB_PEM || ERR_GET_REASON(err) != PEM_R_NO_START_LINE))
        throw std::runtime_error("TLS: PEM 解析失败");
    ERR_clear_error(); // 成功路径清理线程局部错误队列（NO_START_LINE 属正常 EOF 标记）
}

// 共享的嵌入 CA store（进程级缓存；up_ref 一次自持，各 context 再 up_ref 后 set）
X509_STORE* shared_ca_store() {
    static X509_STORE* store = [] {
        ssl::context tmp(ssl::context::tls_client);
        load_pem_into_store(tmp, embedded_cacert_pem);
        X509_STORE* s = SSL_CTX_get_cert_store(tmp.native_handle());
        X509_STORE_up_ref(s); // 自持一份（static 缓存，进程级存活）
        return s;
    }();
    return store;
}

// 构建 TLS context（boost 1.91 的 ssl::context 是 move-only，无法拷贝共享）
ssl::context make_ssl_context(const TlsOptions& tls) {
    ssl::context c(ssl::context::tls_client);
    // TLS 版本下限显式收紧到 1.2（上限默认即 1.3；拒绝已废弃的 TLS1.0/1.1）。
    // 失败仅当库不支持该常量（OpenSSL 1.1.0+/BoringSSL 均支持）——显式失败
    // 而非静默回退到库默认（避免安全下限失效时无信号）。
    if (SSL_CTX_set_min_proto_version(c.native_handle(), TLS1_2_VERSION) != 1)
        throw std::runtime_error("TLS: SSL_CTX_set_min_proto_version 失败");
    c.set_verify_mode(tls.verify ? ssl::verify_peer : ssl::verify_none);
    if (tls.verify) {
        X509_STORE* s = shared_ca_store();
        X509_STORE_up_ref(s); // ctx 接管一份
        SSL_CTX_set_cert_store(c.native_handle(), s);
    }
    for (const auto& pem : tls.extra_trust_pem)
        load_pem_into_store(c, pem);
    return c;
}

// ---- 池键辅助（docs/fetch_connection_pool_design.md §3.8/§3.9）----

// TLS 选项指纹：verify 开关 + 额外 CA PEM（FNV-1a，进程内稳定）。最低版本固定
// TLS1.2（代码硬编码），不进指纹。空字符串 = 明文（由调用方保证）。
std::string tls_fingerprint(const TlsOptions& tls) {
    uint64_t h = 1469598103934665603ull;
    auto mix = [&](std::string_view v) {
        for (unsigned char c : v) {
            h ^= c;
            h *= 1099511628211ull;
        }
    };
    mix(tls.verify ? "verify" : "noverify");
    for (const auto& pem : tls.extra_trust_pem)
        mix(pem);
    return std::to_string(h);
}

// 统一端口校验（M6）：池键与所有建连路径共用同一份校验，非法/越界即抛——
// 键里的端口与实际连接的端口由同一函数产生；非法端口在构造键时就抛。
uint16_t parse_port(const std::string& port)
{
    int p = 0;
    try {
        p = std::stoi(port);
    } catch (const std::exception&) {
        throw std::invalid_argument("非法端口 '" + port + "'");
    }
    if (p < 1 || p > 65535)
        throw std::invalid_argument("端口越界 '" + port + "'");
    return static_cast<uint16_t>(p);
}

uint16_t port_number(const ParsedUrl& url)
{
    return parse_port(url.port); // 非法端口在此抛（不再静默归 0）
}

// 直连/SOCKS5/CONNECT 隧道：键 = 目标 scheme+host+port + 代理维度 + TLS 指纹。
// http 正向代理（absolute-form 转发）的键由调用方单独构造（key = 代理本身）。
PoolKey make_pool_key(const ParsedUrl& url, std::string proxy_id, const TlsOptions& tls) {
    PoolKey k;
    k.scheme = url.scheme;
    k.host = url.host;
    k.port = port_number(url);
    k.proxy_id = std::move(proxy_id);
    k.tls_fingerprint = url.scheme == "https" ? tls_fingerprint(tls) : "";
    return k;
}

// proxy_id：含用户名不含密码（密码不进键避免落日志；同 host/port/用户名但
// 不同密码的配置共享连接，与 hyper 同层语义，§3.8）
std::string proxy_id_for(const std::string& scheme, const std::string& host, uint16_t port,
                         const std::optional<std::pair<std::string, std::string>>& auth)
{
    std::string s = scheme + "://";
    if (auth)
        s += auth->first + "@";
    s += host + ":" + std::to_string(port);
    return s;
}

// 响应是否允许连接复用（§3.5）：beast 的 parser.keep_alive() 已综合
// Connection: close / HTTP/1.0 / need_eof 判定；另需排除"有 body 但无
// content-length 且无 chunked"的 need_eof 响应——body 靠连接关闭终止，读干后
// 连接已死，不能回池。HEAD/204/205/304（no_body）无 body 可读，连接干净。
bool response_reusable(const http::response_parser<http::buffer_body>& parser, bool no_body)
{
    if (!parser.keep_alive())
        return false;
    if (no_body)
        return true;
    const auto& res = parser.get();
    if (res.chunked())
        return true;
    if (res.find(http::field::content_length) != res.end())
        return true;
    return false; // need_eof：body 靠 EOF 界定，连接不可复用
}

// 组装 beast 请求（不含 IO）。
// target 非空 → 用该值作请求行 target（HTTP 代理 absolute-form 转发用）；
// proxy 非空 → 追加 Proxy-Authorization: Basic（仅发往代理的连接；hop-by-hop
// 头不进入隧道内请求——https 隧道内复用 make_beast_request(req, url) 不带 proxy）。
// Body = http::string_body：整收 body（req.body）；Body = http::empty_body：
// head-only（流式上传用，body 数据由调用方循环 async_write）。
template <class Body>
http::request<Body> make_beast_request(const Request& req,
                                       const ParsedUrl& url,
                                       std::string_view target = {},
                                       const HttpProxy* proxy = nullptr) {
    http::request<Body> hreq;
    hreq.method_string(req.method);
    hreq.target(target.empty() ? url.target : target);
    hreq.version(11);
    for (const auto& h : req.headers) {
        // 头注入兜底：CR/LF/NUL 会破坏请求行/头结构（JS 绑定层已在
        // qjsbind/web/headers.hpp normalize_value 拦截，这里是 C++ 直通
        // 路径（如 fetch::easy）的防御纵深）
        auto has_ctrl = [](const std::string& s) {
            return s.find('\r') != std::string::npos || s.find('\n') != std::string::npos ||
                   s.find('\0') != std::string::npos;
        };
        if (has_ctrl(h.name) || has_ctrl(h.value))
            throw std::invalid_argument("header 名/值含 CR/LF/NUL");
        hreq.set(h.name, h.value);
    }
    hreq.set(http::field::host, url.host + (url.port == (url.scheme == "https" ? "443" : "80")
                                               ? ""
                                               : ":" + url.port));
    // 默认 UA 只在用户未设置时生效（与下方 Accept/Accept-Language 一致；
    // 用户经 req.headers 设置 User-Agent 时保留——easy 层 user_agent() 依赖此行为）
    if (hreq.find(http::field::user_agent) == hreq.end())
        hreq.set(http::field::user_agent, "qjs-runtime/0.1 (+wpt)");
    // 默认 Accept/Accept-Language 只在用户未设置时生效（wpt accept-header 测试）
    if (hreq.find(http::field::accept) == hreq.end())
        hreq.set(http::field::accept, "*/*");
    if (hreq.find(http::field::accept_language) == hreq.end())
        hreq.set(http::field::accept_language, "en-US,en;q=0.9");
    // 不设 Connection 头：wpt inspect-headers 测试要求 fetch 请求不含连接管理头；
    // keep-alive 由 beast 默认（HTTP/1.1），连接复用决策在池/BodySource 侧。
    if (proxy && proxy->auth) {
        const auto& [user, pass] = *proxy->auth;
        hreq.set(http::field::proxy_authorization,
                 "Basic " + base64_encode(user + ":" + pass));
    }
    if constexpr (!std::is_same_v<Body, http::empty_body>) {
        if (!req.body.empty()) {
            hreq.body() = req.body;
            hreq.prepare_payload();
        }
    }
    return hreq;
}

// 响应头（不含 body）
struct ResponseHead {
    int status = 0;
    std::string reason;
    Headers headers;
};

// 写请求（整收 body 或流式 body_stream）。成功返回 = 请求字节已全部交给内核。
// 失败抛错（可能部分字节上线；对 h1 服务端忽略不完整请求——与 hyper 的
// TrySendError 同语义，是"请求从未上线"重试判定的依据）。
template <class Stream>
std_exec::task<void> write_request(Stream& stream, const Request& req, const ParsedUrl& url,
                                   std::string_view target = {},
                                   const HttpProxy* proxy = nullptr) {
    // 流式请求体（body_stream）：head-only 写（Content-Length 已由
    // BodyLengthMiddleware 按 body_size 设置），再循环 read() 分块写。
    if (req.body_stream) {
        http::request<http::empty_body> hreq =
            make_beast_request<http::empty_body>(req, url, target, proxy);
        http::request_serializer<http::empty_body> ser(hreq);
        co_await http::async_write(stream, ser, exec::asio::use_sender);
        for (;;) {
            auto chunk = co_await req.body_stream->read();
            if (!chunk)
                break;
            if (chunk->empty())
                continue;
            co_await boost::asio::async_write(stream, boost::asio::buffer(*chunk),
                                              exec::asio::use_sender);
        }
    } else {
        http::request<http::string_body> hreq =
            make_beast_request<http::string_body>(req, url, target, proxy);
        co_await http::async_write(stream, hreq, exec::asio::use_sender);
    }
}

// 读响应头（不含 body）。parser 以 shared_ptr 传入：beast 的 response_parser
// 不可移动，且 body 阶段需要同一 parser 继续 async_read_some（BeastBodySource 持有）。
// buffer 为外部传入（池化路径用连接自带的 buffer——含 over-read 残留字节；
// 非池化路径由调用方提供局部 buffer）。
template <class Stream>
std_exec::task<ResponseHead>
read_header(Stream& stream, beast::flat_buffer& buffer,
            std::shared_ptr<http::response_parser<http::buffer_body>> parser) {
    co_await http::async_read_header(stream, buffer, *parser, exec::asio::use_sender);

    const auto& hres = parser->get();
    ResponseHead head;
    head.status = hres.result_int();
    head.reason = std::string(hres.reason());
    for (const auto& f : hres.base())
        head.headers.push_back({std::string(f.name_string()), std::string(f.value())});
    co_return head;
}

// ---- BeastBodySource：流式 body 源（fetch::BodySource 的 beast 实现）----
// 持有 PooledConnection（内部是 AnyStream variant；静态分派零堆分配）、
// flat_buffer（连接自带，含 over-read 残留）、response_parser<buffer_body> 与
// 64 KiB 读缓冲。
// read() = http::async_read_some → 返回本次消费的字节；parser.is_done() → nullopt。
// 读干（is_done）且 keep_alive → 连接立即回池（§3.5：连接空闲的时刻 = body
// 流完的时刻，即 hyper 的"延迟归位"）；未读干就析构 / cancel / I/O 错误 →
// 连接关闭不回池（h1 字节流上有未知残余数据，复用即错乱）。
// cancel() = lowest_layer().close()（同时唤醒挂起的 read，以 operation_aborted 完成）。
// 线程：read() 仅 io 线程；cancel() 可跨线程触发（stop_callback）。mu_ 保护
// "读干回池"与"cancel"对 conn_ 的并发访问。
class BeastBodySource : public BodySource,
                        public std::enable_shared_from_this<BeastBodySource> {
public:
    BeastBodySource(PooledConnection conn,
                    std::shared_ptr<http::response_parser<http::buffer_body>> parser)
        : conn_(std::move(conn)), parser_(std::move(parser))
    {
    }

    ~BeastBodySource() override
    {
        // 连接要么已在 read() 读干时回池（conn_ 已空），要么在此随 conn_ 析构关闭。
        // 成员析构序（逆序）：stop_cb_ 最先析构（注销回调、等并发回调完成），
        // 然后 mu_，最后 conn_——回调执行期间 mu_ 与 conn_ 均存活（见成员声明序）。
    }

    // 注册取消回调（weak 自持：回调执行期间 source 不会被析构）。
    // 注册时若已 stop_requested → 立即回调（cancel）。
    void arm_stop(std::stop_token st, std::weak_ptr<BeastBodySource> weak)
    {
        if (!st.stop_possible())
            return;
        stop_cb_.emplace(st, [weak] {
            if (auto self = weak.lock())
                self->cancel();
        });
    }

    std_exec::task<std::optional<std::string>> read() override
    {
        for (;;) {
            if (parser_->is_done()) {
                // 读干：连接干净（chunked/content-length 有明确终止）且 keep-alive
                // → 立即回池（io 线程；不在析构时回池，避免与跨线程 cancel 竞争）。
                std::lock_guard<std::mutex> lk(mu_);
                if (!cancelled_.load(std::memory_order_relaxed)) {
                    if (response_reusable(*parser_, /*no_body=*/false))
                        conn_.put_back();
                    // 否则（Connection: close / need_eof）→ 连接随析构关闭
                    conn_ = PooledConnection{};
                }
                co_return std::nullopt;
            }
            chunk_.resize(kChunkSize);
            parser_->get().body().data = chunk_.data();
            parser_->get().body().size = chunk_.size();
            // 按值传 use_sender（async_compose 要求 CompletionToken 为可移动的值类型）
            auto use_sender = exec::asio::use_sender;
            bool aborted = false;
            try {
                // 协程 lambda 统一 std::visit 各分支返回类型（async_read_some 的
                // sender 类型依赖具体 Stream，各分支协程化后统一为 task<void>）
                co_await std::visit(
                    [&](auto& s) -> std_exec::task<void> {
                        co_await http::async_read_some(s, conn_.buffer(), *parser_,
                                                       exec::asio::use_sender);
                    },
                    conn_.stream());
            } catch (const boost::system::system_error&) {
                // 中止（stop）已请求后的一切读取失败都算 abort：挂起中的读被
                // cancel() 唤醒后 asio 报 operation_aborted（use_sender 转 stopped，
                // 协程在此终止，不走这里）；但"先 close 后新发起读"会报
                // bad_descriptor 等错误 → 统一转 stopped → reject AbortError。
                // （catch 块内不能 co_await，用标志延后）
                if (cancelled_.load(std::memory_order_acquire))
                    aborted = true;
                else
                    throw;
            }
            if (aborted)
                co_await stdexec::just_stopped();
            const size_t used = chunk_.size() - parser_->get().body().size;
            chunk_.resize(used);
            if (used > 0)
                co_return std::move(chunk_);
            // used == 0 且未 done：只消费了控制字节（chunk 边界），继续读
        }
    }

    void cancel() override
    {
        std::lock_guard<std::mutex> lk(mu_);
        cancelled_.store(true, std::memory_order_relaxed);
        if (conn_.has_entry()) {
            std::visit([](auto& s) {
                boost::system::error_code ec;
                s.lowest_layer().close(ec);
            }, conn_.stream());
        }
    }

private:
    static constexpr size_t kChunkSize = 64 * 1024;
    // 成员声明序 = 析构逆序：stop_cb_ 必须最先析构（先注销回调），mu_ 必须比
    // stop_cb_ 晚析构（并发回调可能持 mu_），conn_ 必须比 mu_ 晚析构
    //（cancel 持 mu_ 访问 conn_）。
    PooledConnection conn_;
    std::shared_ptr<http::response_parser<http::buffer_body>> parser_;
    std::string chunk_;
    std::atomic<bool> cancelled_{false};
    std::mutex mu_; // 保护 conn_ 的 put_back/cancel 竞争（读干回池 vs 跨线程 cancel）
    std::optional<std::stop_callback<std::function<void()>>> stop_cb_;
};

// ---- 池化交换：写请求 + 读头 + 构造 body/回池（§3.5/§3.7）----
// write_done：请求字节已全部交给内核后置 true（重试条件判据；等价 hyper 的
// TrySendError 语义——写失败 = 请求"从未上线"）。失败路径：连接随 conn 析构
// 关闭（不回池）；连接已 move 进 BodySource 的由 BodySource 负责。
std_exec::task<Response> exchange_pooled(PooledConnection conn, const Request& req,
                                         const ParsedUrl& url, std::stop_token st,
                                         std::string_view target, const HttpProxy* proxy,
                                         bool& write_done) {
    auto parser = std::make_shared<http::response_parser<http::buffer_body>>();
    // beast 默认 body_limit 仅 1 MB，大文件下载（模型等）会被截杀；
    // body 是流式消费（buffer_body 不攒内存），上限放开，与 reqwest 语义对齐
    //（解压炸弹防护由 Options::max_decompressed_bytes 单独负责）。
    parser->body_limit(std::numeric_limits<std::uint64_t>::max());
    // 读头阶段的取消回调：绑连接底层（与 body 阶段 BeastBodySource 的回调交接）。
    // stream_ptr 指向 conn.stream()。竞态防护：回调（跨线程）与 io 线程的
    // 连接 move/回池 经 mu_ 互斥——回调先查 valid 再持锁 visit；io 线程在
    // move/回池前持锁置 valid=false。等锁期间 io 线程已置 false 的回调不再 visit。
    std::optional<std::stop_callback<std::function<void()>>> head_stop_cb;
    auto stream_ptr = &conn.stream();
    auto valid = std::make_shared<std::atomic<bool>>(true);
    auto mu = std::make_shared<std::mutex>();
    if (st.stop_possible()) {
        head_stop_cb.emplace(st, [valid, stream_ptr, mu] {
            if (!valid->load(std::memory_order_acquire))
                return;
            std::lock_guard<std::mutex> lk(*mu);
            if (!valid->load(std::memory_order_acquire)) // 等锁期间 io 可能已置 false
                return;
            std::visit([](auto& s) {
                boost::system::error_code ec;
                s.lowest_layer().cancel(ec);
            }, *stream_ptr);
        });
    }
    try {
        co_await std::visit(
            [&](auto& s) -> std_exec::task<void> {
                co_await write_request(s, req, url, target, proxy);
            },
            conn.stream());
    } catch (...) {
        std::lock_guard<std::mutex> lk(*mu);
        valid->store(false, std::memory_order_release);
        throw;
    }
    write_done = true; // 请求字节已交给内核：写失败（!write_done）与"读头零字节
                       // EOF"两个分支可重试（见 pooled_flow；后者是相对 hyper 的
                       // 额外放宽，hyper 只在请求从未开始写时重试，§2.8）
    ResponseHead head;
    try {
        head = co_await std::visit(
            [&](auto& s) -> std_exec::task<ResponseHead> {
                co_return co_await read_header(s, conn.buffer(), parser);
            },
            conn.stream());
    } catch (...) {
        std::lock_guard<std::mutex> lk(*mu);
        valid->store(false, std::memory_order_release);
        throw;
    }
    {
        std::lock_guard<std::mutex> lk(*mu);
        valid->store(false, std::memory_order_release);
    }

    // 407：代理拒绝（缺/错凭据）——与 CONNECT 握手同语义，抛可区分错误
    // （其余 4xx/5xx 是目标的正常响应，照常返回）
    if (proxy && head.status == 407)
        throw boost::system::system_error(
            boost::system::error_code(407, http_proxy_category()),
            "http_proxy: proxy authentication required");

    Response out;
    out.status = head.status;
    out.reason = std::move(head.reason);
    out.headers = std::move(head.headers);
    // 无 body 场景（HEAD / 204 / 205 / 304）：连接干净（请求已写、头已读）→ 立即回池
    const bool no_body = req.method == "HEAD" || head.status == 204 || head.status == 205 ||
                         head.status == 304;
    if (no_body) {
        if (response_reusable(*parser, /*no_body=*/true))
            conn.put_back();
        else
            conn.discard();
    } else {
        auto src = std::make_shared<BeastBodySource>(std::move(conn), std::move(parser));
        src->arm_stop(st, src);
        out.body = std::move(src);
    }
    co_return out;
}

// ---- 池化请求骨架（§3.7，对齐 hyper §2.8）----
// checkout 未命中 → connect() 建连（单线程顺序化 = hyper 的 lazy connect：
// checkout 不命中前一行网络代码都不会跑）；复用连接失败且请求可安全重放
//（写失败 = 从未上线；写成功但读头零字节 EOF = 陈旧 keep-alive）→ 只重试一次。
// 注：catch 块内不能 co_await（语言限制），重试路径落在 catch 之后的函数尾部。
template <class ConnectFn>
std_exec::task<Response> pooled_flow(ConnectionPool& pool, const PoolKey& key,
                                     const Request& req, const ParsedUrl& url,
                                     std::stop_token st, std::string_view target,
                                     const HttpProxy* proxy, ConnectFn&& connect) {
    auto conn = pool.checkout(key);
    const bool reused = conn.has_value();
    if (!conn)
        conn = co_await connect();
    bool write_done = false;
    try {
        co_return co_await exchange_pooled(std::move(*conn), req, url, st, target, proxy,
                                           write_done);
    } catch (const boost::system::system_error& e) {
        // 重试条件：只有复用连接触发的失败才重试（fresh 连接失败是真实故障，
        // 直接抛）；且请求必须可安全重放——两种形态：
        //   1. 写阶段失败（write_done == false）：请求从未上线。等价 hyper 的
        //      TrySendError（request 连同 body 原样带回 → Retryable）；
        //   2. 写成功但读响应头阶段零字节失败（end_of_stream/eof/stream_truncated，
        //      以及 reset/aborted——Windows 上对端 FIN 后再写会让读报 WSAECONNABORTED
        //      而非 EOF，同属"服务端已关、请求未被处理"形态）：陈旧 keep-alive
        //      连接被服务端关闭，写进内核缓冲即"成功"，请求大概率从未被服务端
        //      处理——这是生产环境最高频的半开形态。
        // 注：形态 2 是相对 hyper 的额外放宽——hyper 只在"请求从未开始写"的
        //   竞态下重试（retry_canceled_requests：入队前连接已死，message 原样
        //   带回），写成功后的读头 EOF 属在飞失败（message 不可带回），hyper
        //   不重试。我们靠"请求大概率未被服务端处理"的假设兜底（curl 风格）：
        //   服务端超时关闭空闲连接后，FIN/RST 会丢弃随后的请求字节，重试基本
        //   安全；仅当服务端恰已处理请求时才会重复（非幂等风险，见设计文档 §3.7）。
        // 流式上传不可重放（body_stream 单向拉流；hyper 因"未写即原样带回 body"
        // 可重放流式体，我们保守地全部排除）；用户取消（AbortSignal）不重试。
        const bool header_eof = e.code() == http::error::end_of_stream ||
                                e.code() == boost::asio::error::eof ||
                                e.code() == boost::asio::ssl::error::stream_truncated ||
                                e.code() == boost::asio::error::connection_reset ||
                                e.code() == boost::asio::error::connection_aborted;
        const bool can_retry = reused && pool.options().retry_on_reused_failure &&
                               !req.body_stream && (!write_done || header_eof) &&
                               e.code() != boost::asio::error::operation_aborted;
        if (!can_retry)
            throw;
        // 满足重试条件：连接已随 exchange_pooled 析构关闭（不回池），落到下方重试
    }
    auto conn2 = co_await connect();
    co_return co_await exchange_pooled(std::move(conn2), req, url, st, target, proxy,
                                       write_done);
}

} // namespace

// 建立到目标的 TCP 连接：直连（DnsResolver 解析 + connect_all）或经 SOCKS5 隧道。
// 返回共享 socket：调用方在其上挂取消回调（connect / socks5 握手 / TLS 握手 /
// 读头全程可取消；body 阶段由 BeastBodySource 接管）。
// resolve 阶段的取消由 DnsResolver 实现内化（H2，见 dns_resolver.hpp）；
// 这里只挂 connect 阶段的 socket cancel。
std_exec::task<std::shared_ptr<tcp::socket>>
connect_tcp(boost::asio::io_context& io, const std::string& host, const std::string& port,
            std::stop_token st, const std::optional<Socks5Proxy>& proxy,
            const std::shared_ptr<DnsResolver>& resolver)
{
    if (proxy) {
        // 与池键共用统一端口校验（M6）：非法/越界 → 抛（不静默默认 80）
        const uint16_t p = parse_port(port);
        co_return co_await socks5_connect(io, *proxy, host, p, st, resolver);
    }
    auto sock = std::make_shared<tcp::socket>(io);
    std::optional<std::stop_callback<std::function<void()>>> stop_cb;
    if (st.stop_possible()) {
        stop_cb.emplace(st, [sock] {
            boost::system::error_code ec;
            sock->cancel(ec); // connect 阶段生效：operation_aborted → set_stopped → AbortError
        });
    }
    const auto results = co_await resolver->resolve(host, port, st);
    // 依次尝试所有 endpoint（resolve 常返回 AAAA + A 多条），全失败抛最后一个错误；
    // 连上的地址回报缓存层做 last_good 排序（§3.3）
    const uint16_t p = parse_port(port);
    const auto addr = co_await detail::connect_all(*sock, results, p);
    resolver->report_success(host, port, addr);
    co_return sock;
}

// ---- TLS session 复用缓存（M5）----
// 与 TlsContextCacheImpl 并列：后者缓存的是 context，握手仍全是完整握手；
// 本缓存跨连接复用 session，省去 1-RTT/证书传输（idle 超时/上限丢弃后的重连受益）。
// 键 = host:port|tls_fingerprint（session 端到端绑定目标 host，与是否走隧道无关，
// proxy 不进键）；值 = SSL_SESSION*（up_ref/free 手动管理）+ 过期点
//（SSL_SESSION_get_timeout 秒 → steady_clock）。LRU 容量 128，仅 io 线程访问
//（沿用池的单线程契约，免锁）。仅池化路径启用。
struct BeastTransport::TlsSessionCacheImpl {
    static constexpr size_t kCapacity = 128;
    struct Entry {
        SSL_SESSION* sess; // 持有 1 份引用（erase/析构时 SSL_SESSION_free）
        std::chrono::steady_clock::time_point expires;
    };
    // 头 = 最久未用；命中即 splice 到尾部
    std::list<std::pair<std::string, Entry>> lru;
    std::unordered_map<std::string, std::list<std::pair<std::string, Entry>>::iterator>
        index;
    // 测试钩子：lookup 命中 / 入库 / 实际复用（SSL_session_reused）计数
    uint64_t hits = 0, stores = 0, resumed = 0;

    ~TlsSessionCacheImpl()
    {
        for (auto& [k, e] : lru)
            SSL_SESSION_free(e.sess);
    }

    // 命中且未过期 → 返回新引用（调用方负责 SSL_SESSION_free）；未命中/过期 → nullptr。
    // single-use（TLS 1.3 ticket，RFC 8446 C.4）取出即焚：服务端会发新票再存回。
    SSL_SESSION* lookup(const std::string& key)
    {
        auto it = index.find(key);
        if (it == index.end())
            return nullptr;
        if (std::chrono::steady_clock::now() >= it->second->second.expires) {
            erase(it);
            return nullptr;
        }
        ++hits;
        SSL_SESSION* s = it->second->second.sess;
        SSL_SESSION_up_ref(s);
        if (SSL_SESSION_should_be_single_use(s))
            erase(it); // 用后即焚
        else
            lru.splice(lru.end(), lru, it->second); // 移到最近使用
        return s;
    }

    // 入库：仅收 resumable 的完整 session（TLS 1.3 握手刚结束时的 session 无
    // ticket，is_resumable=false 被拒；ticket 由 new_cb 随后送达再入）。
    void store(const std::string& key, SSL_SESSION* sess)
    {
        if (!SSL_SESSION_is_resumable(sess))
            return;
        const auto expires =
            std::chrono::steady_clock::now() +
            std::chrono::seconds(SSL_SESSION_get_timeout(sess));
        ++stores;
        if (auto it = index.find(key); it != index.end())
            erase(it); // 同键新票替换旧票（1.3 单票语义下避免堆叠）
        SSL_SESSION_up_ref(sess);
        lru.emplace_back(key, Entry{sess, expires});
        index[key] = std::prev(lru.end());
        if (lru.size() > kCapacity) {
            SSL_SESSION_free(lru.front().second.sess);
            index.erase(lru.front().first);
            lru.pop_front();
        }
    }

private:
    void erase(std::unordered_map<
               std::string,
               std::list<std::pair<std::string, Entry>>::iterator>::iterator it)
    {
        SSL_SESSION_free(it->second->second.sess);
        lru.erase(it->second);
        index.erase(it);
    }
};

// 挂到 SSL* 上的链接块：make_tls_connection 握手前挂上，所有权随 ex_data 移交
// SSL（free_func 在 SSL 析构时 delete）——TLS 1.3 ticket 在握手完成后的任意
// 读操作中才可能到达，故链接块必须活得跟 SSL 一样久，不能握手结束就释放。
struct TlsSessionLink {
    BeastTransport::TlsSessionCacheImpl* cache;
    std::string key;
};

void tls_session_link_free(void* /*parent*/, void* ptr, CRYPTO_EX_DATA* /*ad*/,
                           int /*index*/, long /*argl*/, void* /*argp*/)
{
    delete static_cast<TlsSessionLink*>(ptr);
}

// SSL ex_data 索引（进程级一次性分配）：握手前往 SSL* 挂 TlsSessionLink，
// new_cb（TLS 1.3 ticket 握手完成后才送达）经它找回缓存与键。
int tls_session_ex_index()
{
    static const int idx =
        SSL_get_ex_new_index(0, nullptr, nullptr, nullptr, &tls_session_link_free);
    return idx;
}

// new_session 回调：新 session 建立（TLS 1.2 握手完成 / 1.3 NewSessionTicket
// 到达）时触发，须 ctx 开 SSL_SESS_CACHE_CLIENT。返回 0 = 不接管所有权，
// 缓存内部自行 up_ref。
int tls_session_on_new(SSL* ssl, SSL_SESSION* sess)
{
    void* p = SSL_get_ex_data(ssl, tls_session_ex_index());
    if (!p)
        return 0; // 未挂链接块（非池化 ctx / 明文）：忽略
    auto* link = static_cast<TlsSessionLink*>(p);
    link->cache->store(link->key, sess);
    return 0;
}

// TLS ctx 缓存（§3.9）：tls_fingerprint → shared_ptr<ssl::context>，容量上限 32，
// 满则 LRU 淘汰。只用于池化路径（无池时每请求新建，保持旧行为）。
struct BeastTransport::TlsContextCacheImpl {
    static constexpr size_t kCapacity = 32;
    // 头 = 最久未用；访问命中即 splice 到尾部
    std::list<std::pair<std::string, std::shared_ptr<ssl::context>>> lru;
    std::unordered_map<
        std::string, std::list<std::pair<std::string, std::shared_ptr<ssl::context>>>::iterator>
        index;

    std::shared_ptr<ssl::context> get(const TlsOptions& tls)
    {
        const std::string fp = tls_fingerprint(tls);
        if (auto it = index.find(fp); it != index.end()) {
            lru.splice(lru.end(), lru, it->second); // 移到最近使用
            return it->second->second;
        }
        auto ctx = std::make_shared<ssl::context>(make_ssl_context(tls));
        // M5：开客户端 session 缓存位并注册 new_cb（TLS 1.3 ticket 捕获入口；
        // 1.2 走握手后 SSL_get1_session）。仅池化 ctx 经此处，无池行为不变。
        SSL_CTX_set_session_cache_mode(
            ctx->native_handle(),
            SSL_CTX_get_session_cache_mode(ctx->native_handle()) | SSL_SESS_CACHE_CLIENT);
        SSL_CTX_sess_set_new_cb(ctx->native_handle(), &tls_session_on_new);
        lru.emplace_back(fp, ctx);
        index[fp] = std::prev(lru.end());
        if (lru.size() > kCapacity) {
            index.erase(lru.front().first);
            lru.pop_front();
        }
        return ctx;
    }
};

BeastTransport::BeastTransport(TlsOptions tls, std::shared_ptr<ConnectionPool> pool,
                               DnsOptions dns)
    : io_(fetch::thread_io()), tls_(std::move(tls)), pool_(std::move(pool))
{
    // DNS 组装（dns_resolver_design.md §5/§4.2）：custom_resolver
    //   > CachingResolver{DohResolver}（有 doh；负缓存/singleflight 免费获得）
    //   > CachingResolver{SystemResolver}（无 doh 且 cache_enabled）
    //   > DohResolver / SystemResolver（cache_enabled=false）
    // 三处建连路径（connect_tcp/socks5/http_proxy）统一走 resolver_。
    if (dns.custom_resolver) {
        resolver_ = std::move(dns.custom_resolver);
    } else if (dns.doh) {
        auto doh = std::make_shared<DohResolver>(*dns.doh, tls_);
        if (dns.cache_enabled)
            resolver_ =
                std::make_shared<CachingResolver>(io_, std::move(doh), std::move(dns.cache));
        else
            resolver_ = std::move(doh);
    } else if (dns.cache_enabled) {
        resolver_ = std::make_shared<CachingResolver>(
            io_, std::make_shared<SystemResolver>(io_), std::move(dns.cache));
    } else {
        resolver_ = std::make_shared<SystemResolver>(io_);
    }
}

BeastTransport::~BeastTransport() = default; // unique_ptr<TlsContextCacheImpl> 需要完整类型

std::shared_ptr<ssl::context> BeastTransport::tls_ctx_for(const TlsOptions& tls)
{
    if (!pool_)
        return std::make_shared<ssl::context>(make_ssl_context(tls)); // 无池：现状每请求新建
    if (!tls_cache_)
        tls_cache_ = std::make_unique<TlsContextCacheImpl>();
    if (!session_cache_)
        session_cache_ = std::make_unique<TlsSessionCacheImpl>(); // M5：随池启用
    return tls_cache_->get(tls);
}

// 测试钩子（M5）：无池 / 尚未建连时返回 0
size_t BeastTransport::tls_session_cache_size() const
{
    return session_cache_ ? session_cache_->lru.size() : 0;
}
uint64_t BeastTransport::tls_session_cache_hits() const
{
    return session_cache_ ? session_cache_->hits : 0;
}
uint64_t BeastTransport::tls_session_cache_stores() const
{
    return session_cache_ ? session_cache_->stores : 0;
}
uint64_t BeastTransport::tls_session_resumed_count() const
{
    return session_cache_ ? session_cache_->resumed : 0;
}

// ---- https-over-socket 段（直连 / SOCKS5 隧道 / HTTP 代理 CONNECT 隧道共用）----
// 输入：已建立的底层流（tcp::socket 或 TunnelStream）；输出：完成 TLS 握手的
// PooledConnection（fresh，is_reused=false；连接交给 exchange_pooled）。
// ctx 取自缓存/新建并以 shared_ptr 随连接存活（IdleEntry.tls_ctx；boost 契约：
// context 须比 stream 活得久）。
template <class NextLayer>
std_exec::task<PooledConnection>
BeastTransport::make_tls_connection(const PoolKey& key, std::shared_ptr<NextLayer> next,
                                    const std::string& host, std::stop_token st)
{
    auto ctx = tls_ctx_for(tls_);
    auto stream = std::make_shared<ssl::stream<NextLayer>>(std::move(*next), *ctx);
    stream->set_verify_callback(ssl::host_name_verification(host));
    // SNI（RFC 6066）：asio 不会自动从 URL 发送 SNI，按 SNI 分证书的虚拟主机站点
    // （大部分 CDN）需在握手前显式设置；IP 字面量跳过。失败仅当 host 超长
    // （>255 字节，SSL_set_tlsext_host_name 的限制）→ 有意忽略：SNI 缺失只影响
    // 虚拟主机分发，不应让整个请求失败。
    if (!is_ip_literal(host))
        (void)SSL_set_tlsext_host_name(stream->native_handle(), host.c_str());
    // M5 session 复用（仅池化路径，session_cache_ 随 tls_ctx_for 创建）：
    // 握手前查缓存挂上次的 session；并给 SSL* 挂链接块（所有权经 ex_data 移交
    // SSL，free_func 随 SSL 析构释放），供 new_cb（TLS 1.3 ticket 握手后才
    // 送达）找回缓存与键。
    TlsSessionLink* sess_link = nullptr;
    if (session_cache_) {
        sess_link = new TlsSessionLink{session_cache_.get(),
                                       host + ":" + std::to_string(key.port) + "|" +
                                           key.tls_fingerprint};
        if (SSL_SESSION* s = session_cache_->lookup(sess_link->key)) {
            // 复用失败（服务端拒票）OpenSSL/BoringSSL 自动回落完整握手，
            // 此处不假设 set_session 后一定 resumed
            (void)SSL_set_session(stream->native_handle(), s);
            SSL_SESSION_free(s);
        }
        SSL_set_ex_data(stream->native_handle(), tls_session_ex_index(), sess_link);
    }
    // 底层已 move 进 stream：取消回调改绑 stream 底层（否则 abort 失效）
    std::optional<std::stop_callback<std::function<void()>>> stop_cb;
    if (st.stop_possible()) {
        stop_cb.emplace(st, [stream] {
            boost::system::error_code ec;
            stream->next_layer().cancel(ec);
        });
    }
    co_await stream->async_handshake(ssl::stream_base::client, exec::asio::use_sender);
    if (sess_link) {
        if (SSL_session_reused(stream->native_handle())) {
            ++session_cache_->resumed;
        } else if (SSL_SESSION* s = SSL_get1_session(stream->native_handle())) {
            // TLS 1.2：握手成功（含证书校验通过，否则上面已抛）即得完整 session
            // 入库；1.3 此刻无 ticket 会被 store 的 is_resumable 拒掉，ticket
            // 由 new_cb 随后送达入库。
            session_cache_->store(sess_link->key, s);
            SSL_SESSION_free(s);
        }
    }
    // ssl::stream 移入 AnyStream（move 后原对象为空，shared_ptr 析构不关闭任何东西）。
    // 注：AnyStream 不可默认构造（variant 首成员 tcp::socket 需 executor），逐分支构造。
    IdleEntry entry = [&]() -> IdleEntry {
        if constexpr (std::is_same_v<NextLayer, tcp::socket>)
            return IdleEntry{std::move(ctx), TlsStream(std::move(*stream)), {}, {}};
        else
            return IdleEntry{std::move(ctx), TunnelTls(std::move(*stream)), {}, {}};
    }();
    co_return PooledConnection(pool_, key, std::move(entry), /*is_reused=*/false);
}

// 明文 TCP 连接段（直连 / SOCKS5 隧道 / http 正向代理转发共用）
std_exec::task<PooledConnection>
BeastTransport::make_plain_connection(const PoolKey& key, const std::string& host,
                                      const std::string& port, std::stop_token st,
                                      const std::optional<Socks5Proxy>& proxy)
{
    auto sock = co_await connect_tcp(io_, host, port, st, proxy, resolver_);
    IdleEntry entry{{}, PlainStream(std::move(*sock)), {}, {}};
    co_return PooledConnection(pool_, key, std::move(entry), /*is_reused=*/false);
}

std_exec::task<Response> BeastTransport::request(const Request& req, std::stop_token st) {
    const ParsedUrl url = parse_url(req.url);

    if (pool_) {
        // 池化路径：checkout 复用，未命中建连；连接用完回池（§3.7 骨架）
        const PoolKey key = make_pool_key(url, "", tls_);
        co_return co_await pooled_flow(*pool_, key, req, url, st, {}, nullptr,
            [&]() -> std_exec::task<PooledConnection> {
                if (url.scheme == "https") {
                    auto sock =
                        co_await connect_tcp(io_, url.host, url.port, st, std::nullopt, resolver_);
                    co_return co_await make_tls_connection(key, std::move(sock), url.host,
                                                           st);
                }
                co_return co_await make_plain_connection(key, url.host, url.port, st,
                                                         std::nullopt);
            });
    }

    // 无池模式（原行为：连接用完即关；连接上的 PooledConnection 持有空 weak 回指）
    bool write_done = false;
    if (url.scheme == "https") {
        auto sock = co_await connect_tcp(io_, url.host, url.port, st, std::nullopt, resolver_);
        auto conn = co_await make_tls_connection(PoolKey{}, std::move(sock), url.host, st);
        co_return co_await exchange_pooled(std::move(conn), req, url, st, {}, nullptr,
                                           write_done);
    }
    auto sock = co_await connect_tcp(io_, url.host, url.port, st, std::nullopt, resolver_);
    auto conn =
        co_await make_plain_connection(PoolKey{}, url.host, url.port, st, std::nullopt);
    co_return co_await exchange_pooled(std::move(conn), req, url, st, {}, nullptr,
                                       write_done);
}

std_exec::task<Response> BeastTransport::request_via_socks5(const Request& req,
                                                            const Socks5Proxy& proxy,
                                                            std::stop_token st) {
    const ParsedUrl url = parse_url(req.url);

    if (pool_) {
        // SOCKS5 隧道：端到端与目标绑定（key 含目标 + 代理维度；同目标同代理复用）
        const std::string pid =
            proxy_id_for("socks5", proxy.host, proxy.port, proxy.auth);
        const PoolKey key = make_pool_key(url, pid, tls_);
        co_return co_await pooled_flow(*pool_, key, req, url, st, {}, nullptr,
            [&]() -> std_exec::task<PooledConnection> {
                if (url.scheme == "https") {
                    auto sock =
                        co_await connect_tcp(io_, url.host, url.port, st, proxy, resolver_);
                    co_return co_await make_tls_connection(key, std::move(sock), url.host,
                                                           st);
                }
                co_return co_await make_plain_connection(key, url.host, url.port, st,
                                                         proxy);
            });
    }

    bool write_done = false;
    if (url.scheme == "https") {
        auto sock = co_await connect_tcp(io_, url.host, url.port, st, proxy, resolver_);
        auto conn = co_await make_tls_connection(PoolKey{}, std::move(sock), url.host, st);
        co_return co_await exchange_pooled(std::move(conn), req, url, st, {}, nullptr,
                                           write_done);
    }
    auto conn =
        co_await make_plain_connection(PoolKey{}, url.host, url.port, st, proxy);
    co_return co_await exchange_pooled(std::move(conn), req, url, st, {}, nullptr,
                                       write_done);
}

std_exec::task<Response> BeastTransport::request_via_http_proxy(const Request& req,
                                                                const HttpProxy& proxy,
                                                                std::stop_token st) {
    const ParsedUrl url = parse_url(req.url);

    if (pool_) {
        if (url.scheme == "https") {
            // CONNECT 隧道：端到端与目标绑定（同目标 × 同代理复用）
            const std::string pid =
                proxy_id_for("connect", proxy.host, proxy.port, proxy.auth);
            const PoolKey key = make_pool_key(url, pid, tls_);
            co_return co_await pooled_flow(*pool_, key, req, url, st, {}, nullptr,
                [&]() -> std_exec::task<PooledConnection> {
                    // 与池键共用统一端口校验（M6）：非法/越界 → 抛
                    const uint16_t p = parse_port(url.port);
                    auto conn = co_await http_proxy_connect(io_, proxy, url.host, p, st, resolver_);
                    // CONNECT 响应 over-read 的字节属隧道流：TunnelStream 先交付再读 socket
                    auto tunnel = std::make_shared<TunnelStream>(
                        std::move(conn.sock), std::move(conn.leftover));
                    co_return co_await make_tls_connection(key, std::move(tunnel),
                                                           url.host, st);
                });
        }
        // http 正向代理：absolute-form 转发允许同一条代理连接服务任意 http 目标
        // ——跨 origin 共享（key = 代理本身；白捡的复用红利，§3.8）
        const std::string pid = proxy_id_for("http", proxy.host, proxy.port, proxy.auth);
        PoolKey key;
        key.scheme = "http";
        key.host = proxy.host;
        key.port = proxy.port;
        key.proxy_id = pid;
        // absolute-form 永远带显式端口（含默认端口）：符合 RFC 9112
        // absolute-form，主流代理均接受，有意不省略（L3）。
        const std::string absolute =
            url.scheme + "://" + authority_form(url.host, url.port) + url.target;
        co_return co_await pooled_flow(*pool_, key, req, url, st, absolute, &proxy,
            [&]() -> std_exec::task<PooledConnection> {
                co_return co_await make_plain_connection(
                    key, proxy.host, std::to_string(proxy.port), st, std::nullopt);
            });
    }

    if (url.scheme == "https") {
        // 与池键共用统一端口校验（M6）：非法/越界 → 抛
        const uint16_t p = parse_port(url.port);
        auto conn = co_await http_proxy_connect(io_, proxy, url.host, p, st, resolver_);
        auto tunnel = std::make_shared<TunnelStream>(std::move(conn.sock),
                                                     std::move(conn.leftover));
        auto pc = co_await make_tls_connection(PoolKey{}, std::move(tunnel), url.host, st);
        bool write_done = false;
        co_return co_await exchange_pooled(std::move(pc), req, url, st, {}, nullptr,
                                           write_done);
    }
    auto conn = co_await make_plain_connection(PoolKey{}, proxy.host,
                                               std::to_string(proxy.port), st,
                                               std::nullopt);
    // absolute-form 永远带显式端口（含默认端口）：符合 RFC 9112 absolute-form，
    // 主流代理均接受，有意不省略（L3）。
    const std::string absolute =
        url.scheme + "://" + authority_form(url.host, url.port) + url.target;
    bool write_done = false;
    co_return co_await exchange_pooled(std::move(conn), req, url, st, absolute, &proxy,
                                       write_done);
}

} // namespace fetch
