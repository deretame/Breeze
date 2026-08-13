// HTTP forward proxy：CONNECT 隧道建立（docs/proxy_test_plan.md §4）
#pragma once

#include <fetch/task.hpp>
#include <fetch/transport.hpp>
#include <fetch/tunnel_stream.hpp>
#include <fetch/dns_resolver.hpp>

#include <boost/asio/ip/tcp.hpp>
#include <boost/beast/core/flat_buffer.hpp>
#include <stdexec/execution.hpp>

#include <openssl/base64.h>

#include <cstdint>
#include <memory>
#include <string_view>
#include <utility>

namespace fetch {

// http_proxy 错误 category（错误码 = 代理返回的 HTTP 状态码；407 可区分）。
// CONNECT 握手（http_proxy.cpp）与 http 转发响应（beast_transport.cpp）共用。
struct HttpProxyCategory : boost::system::error_category {
    const char* name() const noexcept override { return "http_proxy"; }
    std::string message(int ev) const override
    {
        if (ev == 407)
            return "proxy authentication required";
        if (ev >= 100 && ev <= 599)
            return "proxy rejected request with HTTP status " + std::to_string(ev);
        return "unknown http_proxy error";
    }
};
inline const HttpProxyCategory& http_proxy_category()
{
    static const HttpProxyCategory c;
    return c;
}

// Basic 认证用 base64（RFC 7617；http_proxy.cpp 与 beast_transport.cpp 共用）
inline std::string base64_encode(std::string_view in)
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

// authority-form（CONNECT target / absolute-form 用）：IPv6 字面量补方括号
//（RFC 3986 §3.2.2）。注意两点：ada（WHATWG）get_hostname() 对 IPv6 已返回
// 带方括号形式（"[::1]"），而 boost::asio::make_address_v6 也接受带括号输入
// ——先剥已带括号的情况，避免双重方括号（"[[::1]]" 是非法 host）。
inline std::string authority_form(std::string_view host, std::string_view port)
{
    if (host.size() >= 2 && host.front() == '[' && host.back() == ']')
        return std::string(host) + ":" + std::string(port);
    boost::system::error_code ec;
    (void)boost::asio::ip::make_address_v6(host, ec);
    if (!ec)
        return "[" + std::string(host) + "]:" + std::string(port);
    return std::string(host) + ":" + std::string(port);
}

// 隧道结果：socket + CONNECT 响应解析后剩余字节（属于隧道流，移交 TLS 层）
struct HttpProxyConnectResult {
    std::shared_ptr<boost::asio::ip::tcp::socket> sock;
    boost::beast::flat_buffer leftover;
};

// 建立经 HTTP forward proxy 到目标的 CONNECT 隧道：向代理发
// `CONNECT host:port HTTP/1.1`（+ Host、可选 Proxy-Authorization: Basic），
// 读到 200 后隧道即建立；非 200（407/403/502…）→ 抛 boost::system::system_error
// （category=http_proxy，错误码 = HTTP 状态码，407 可区分）。
// 注意：仅"解析代理地址"一步走 resolver（CONNECT 目标仍携带原始域名，§1.3）。
// 取消：stop_token → socket cancel()（connect/握手阶段可取消 → stopped；
// resolve 阶段的取消由 DnsResolver 实现内化，见 dns_resolver.hpp）。
// 超时：TCP 连接建立后的 CONNECT 握手 30s 上限，超时抛 errc::timed_out。
// 注：返回 shared_ptr——与 BeastBodySource / stop_callback 的 shared_ptr
//    生命周期模型一致（隧道 socket 移交 body 阶段继续用）。
std_exec::task<HttpProxyConnectResult>
http_proxy_connect(boost::asio::io_context& io, const HttpProxy& proxy,
                   std::string_view target_host, uint16_t target_port, std::stop_token st,
                   const std::shared_ptr<DnsResolver>& resolver);

// TunnelStream（CONNECT 隧道流）定义见 <fetch/tunnel_stream.hpp>：CONNECT 响应
// over-read 的字节先于 socket 交付（beast 经典坑的解法：解析器剩余 buffer 里的
// 字节属于隧道流，ssl::stream 的 NextLayer 需先消费它们，耗尽后再读底层 socket）。

} // namespace fetch
