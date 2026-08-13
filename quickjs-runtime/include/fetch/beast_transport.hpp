// fetchcore —— BeastTransport 声明（boost::beast + OpenSSL 的 HTTP/HTTPS 传输）
//
// 设计：单次请求（不含重定向），协程化（std_exec::task）。v2 流式：
//   - request() 读出头即返回；body 由 BeastBodySource（fetch::BodySource）流式交出，
//     读取路径：read() → http::async_read_some（64 KiB 块），EOF 由
//     response_parser<buffer_body> 的 is_done() 判定（chunked / content-length /
//     need_eof 连接关闭终止统一由 beast 处理）。
//   - 取消语义：
//     * 头前阶段：stop_token 触发 → socket.cancel() → asio 异步操作以
//       operation_aborted 完成 → exec::asio::use_sender 转为 set_stopped
//       → 整个 task 以 stopped 完成 → 绑定层 reject AbortError
//     * 读 body 阶段：stop_callback 挂在 BeastBodySource 上（构造时注册、
//       析构时注销），触发 cancel() → lowest_layer().close() → 挂起的 read()
//       以 stopped 完成 → 流读取 reject AbortError
//   - 网络/协议/TLS 错误（头前）→ 协程抛出 boost::system::system_error；
//     读 body 中途失败 → read() 抛异常（fetch 已 resolve）
//
// 连接池（docs/fetch_connection_pool_design.md）：BeastTransport 参数化承载
// 池能力——构造时传入非空 ConnectionPool 即启用 HTTP/1.1 keep-alive 复用
//（checkout/归还/重试/TLS ctx 缓存全部在此类内）；pool == nullptr 时行为
// 与旧版完全一致（连接用完即关）。三个 Transport 入口（request /
// request_via_socks5 / request_via_http_proxy）签名不变，池对上层透明。
//
// 证书：默认信任嵌入的 Mozilla CA bundle（cacert_embedded.hpp，脚本生成）；
//       可通过 TlsOptions::extra_trust_pem 追加信任的 PEM（本地自签测试用）。
#pragma once

#include <fetch/task.hpp>
#include <fetch/transport.hpp>
#include <fetch/types.hpp>
#include <fetch/scheduler.hpp>
#include <fetch/connection_pool.hpp>

#include <boost/asio/io_context.hpp>

#include <memory>
#include <cstdint>

namespace fetch {

class BeastTransport : public Transport {
public:
    // io_context 从当前线程的 thread_local 获取（须已 fetch::set_thread_io()）。
    // pool 非空 → 启用连接池（同 host keep-alive 复用）；nullptr → 无池模式。
    // dns 组装 DnsResolver（§5/§4.2）：custom_resolver > CachingResolver{DohResolver}
    //（有 doh）> CachingResolver{SystemResolver} > SystemResolver；
    // connect_tcp/socks5/http_proxy 三处解析统一走它。
    // 构造/析构定义在 beast_transport.cpp（unique_ptr<PIMPL> 需完整类型）。
    explicit BeastTransport(TlsOptions tls = {}, std::shared_ptr<ConnectionPool> pool = nullptr,
                            DnsOptions dns = {});
    ~BeastTransport() override;

    std_exec::task<Response> request(const Request& req, std::stop_token st) override;

    // 经 SOCKS5 隧道交换（https 在隧道上照常 TLS handshake）
    std_exec::task<Response> request_via_socks5(const Request& req, const Socks5Proxy& proxy,
                                                std::stop_token st) override;

    // 经 HTTP forward proxy 交换：http 目标 → absolute-form 转发；
    // https 目标 → CONNECT 隧道（http_proxy_connect + TunnelStream 移交 over-read 字节）
    std_exec::task<Response> request_via_http_proxy(const Request& req, const HttpProxy& proxy,
                                                    std::stop_token st) override;

    // 测试钩子（M5，TLS session 复用缓存统计；无池/未启用时全为 0）：
    // 缓存条目数 / lookup 命中次数 / SSL_session_reused 为真的握手次数。
    size_t tls_session_cache_size() const;
    uint64_t tls_session_cache_hits() const;
    uint64_t tls_session_cache_stores() const;
    uint64_t tls_session_resumed_count() const;

    // PIMPL 前置声明（public 仅为让 cpp 内的自由 new_cb 回调能命名该类型；
    // 对外仍是不完整类型）。定义见 beast_transport.cpp（M5）。
    struct TlsSessionCacheImpl;

private:
    // TLS context 缓存实现（PIMPL，见 beast_transport.cpp §3.9）
    struct TlsContextCacheImpl;

    // 按 tls 选项取（或构建）ssl::context；池化时走 LRU 缓存（容量 32）。
    std::shared_ptr<boost::asio::ssl::context> tls_ctx_for(const TlsOptions& tls);

    // 池化建连（§3.7）：返回 fresh 连接（is_reused=false；服务完当前请求由
    // BodySource/exchange 决定归还）。make_tls_connection 完成 TLS 握手后把
    // ssl::stream 移入 AnyStream；make_plain_connection 走 connect_tcp。
    template <class NextLayer>
    std_exec::task<PooledConnection> make_tls_connection(const PoolKey& key,
                                                         std::shared_ptr<NextLayer> next,
                                                         const std::string& host,
                                                         std::stop_token st);
    std_exec::task<PooledConnection> make_plain_connection(const PoolKey& key,
                                                           const std::string& host,
                                                           const std::string& port,
                                                           std::stop_token st,
                                                           const std::optional<Socks5Proxy>& proxy);

    boost::asio::io_context& io_;
    TlsOptions tls_;
    std::shared_ptr<ConnectionPool> pool_; // nullptr = 无池模式
    std::shared_ptr<DnsResolver> resolver_; // 三处建连路径的统一 DNS 接缝（§5）
    std::unique_ptr<TlsContextCacheImpl> tls_cache_; // 池化时启用；惰性创建
    std::unique_ptr<TlsSessionCacheImpl> session_cache_; // M5：随池惰性创建
};

} // namespace fetch
