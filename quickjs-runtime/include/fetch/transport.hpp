// fetchcore —— 传输抽象（单次请求，不含重定向）
//
// 实现必须可跨线程安全调用（stop_token 可能在其他线程触发）。
// 依赖方向：传输层 →（asio/beast/OpenSSL）；本抽象不绑定任何具体实现。
#pragma once

#include <fetch/task.hpp>
#include <fetch/types.hpp>

#include <cstdint>
#include <optional>
#include <stdexcept>
#include <string>
#include <utility>

namespace fetch {

// SOCKS5 代理配置（纯值类型；握手/隧道实现在传输层）
struct Socks5Proxy {
    std::string host;                    // 代理地址（主机名或 IP）
    uint16_t port = 1080;                // 代理端口
    std::optional<std::pair<std::string, std::string>> auth; // RFC 1929 user-pass
};

// HTTP forward proxy 配置（纯值类型；absolute-form 转发 / CONNECT 隧道实现在传输层）。
// auth 为 Basic 认证凭据：仅出现在发往代理的连接上（http 转发请求 /
// CONNECT 报文），绝不进入隧道内发给目标的请求。
struct HttpProxy {
    std::string host;                    // 代理地址（主机名或 IP）
    uint16_t port = 8080;                // 代理端口
    std::optional<std::pair<std::string, std::string>> auth; // Basic user:pass
};

// 单次请求传输抽象（接口形状沿用 v1 FetchBackend）。
// 头前失败（DNS/连接/TLS/写请求/读头）抛 std::exception；
// 读出头即返回，body 尚未读完（由 resp.body 流提供）。
// req 为 const 引用：调用方（中间件链）需要保留本跳最终请求供后置相位读取。
struct Transport {
    virtual ~Transport() = default;

    virtual std_exec::task<Response> request(const Request& req, std::stop_token st) = 0;

    // 经 SOCKS5 隧道交换（可选能力：https 在隧道上照常 TLS handshake）。
    // 默认不支持（抛异常）；BeastTransport 提供实现。
    virtual std_exec::task<Response> request_via_socks5(const Request& req,
                                                        const Socks5Proxy& proxy,
                                                        std::stop_token st)
    {
        throw std::runtime_error("socks5: 该传输不支持代理隧道");
    }

    // 经 HTTP forward proxy 交换（可选能力）：http 目标 → absolute-form 转发；
    // https 目标 → 先 CONNECT 建隧道再在隧道上照常 TLS handshake。
    // 默认不支持（抛异常）；BeastTransport 提供实现。
    virtual std_exec::task<Response> request_via_http_proxy(const Request& req,
                                                            const HttpProxy& proxy,
                                                            std::stop_token st)
    {
        throw std::runtime_error("http_proxy: 该传输不支持代理");
    }
};

} // namespace fetch
