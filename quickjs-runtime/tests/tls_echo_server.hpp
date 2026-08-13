// tests/tls_echo_server.hpp —— 自签 TLS 回显服务器（直连/SOCKS5 隧道测试共用）
//
// 证书：tests/certs/server.crt + server.key（SAN 含 IP:127.0.0.1）；
// 客户端需以 TlsOptions::extra_trust_pem 注入该证书信任。
// 响应带 X-Test-Sni 头（客户端 ClientHello 的 SNI，无则空）供 SNI 断言。
#pragma once

#include <boost/asio.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <boost/beast/ssl.hpp>

#include <atomic>
#include <fstream>
#include <memory>
#include <string>
#include <thread>

namespace wpt_test {

namespace asio = boost::asio;
namespace beast = boost::beast;
namespace http = beast::http;
using tcp = asio::ip::tcp;

class TlsEchoServer {
public:
    // cert_base：证书 basename（tests/certs/<cert_base>.crt/.key），默认 server
    explicit TlsEchoServer(const char* cert_base = "server")
    {
        // ctest 的 WORKING_DIRECTORY 是 build 目录 → 多路径尝试
        std::string cert, key;
        for (const char* p : {"tests/certs/", "../tests/certs/", "../../tests/certs/"}) {
            std::ifstream f(std::string(p) + cert_base + ".crt");
            if (f) {
                cert = std::string(p) + cert_base + ".crt";
                key = std::string(p) + cert_base + ".key";
                break;
            }
        }
        ctx_ = std::make_shared<asio::ssl::context>(asio::ssl::context::tls_server);
        ctx_->use_certificate_chain_file(cert);
        ctx_->use_private_key_file(key, asio::ssl::context::pem);
        acceptor_ = tcp::acceptor(io_, tcp::endpoint(asio::ip::address_v4::loopback(), 0));
        port_ = acceptor_.local_endpoint().port();
        thread_ = std::thread([this] { run(); });
    }
    ~TlsEchoServer()
    {
        boost::system::error_code ec;
        acceptor_.close(ec);
        if (thread_.joinable())
            thread_.join();
    }
    std::string base_url() const
    {
        return "https://127.0.0.1:" + std::to_string(port_);
    }
    uint16_t port() const { return port_; }

private:
    // accept 计数：连接辨识钩子（连接池 TLS 复用测试用；语义同 wpt_server.hpp）
    std::atomic<uint64_t> conn_seq_{0};

    void run()
    {
        for (;;) {
            boost::system::error_code ec;
            tcp::socket s = acceptor_.accept(ec);
            if (ec)
                break;
            std::thread([this, s = std::move(s)]() mutable { handle(std::move(s)); })
                .detach();
        }
    }
    void handle(tcp::socket s)
    {
        try {
            const uint64_t conn_id = ++conn_seq_; // 本连接的 accept 序号
            asio::ssl::stream<tcp::socket> stream(std::move(s), *ctx_);
            boost::system::error_code ec;
            stream.handshake(asio::ssl::stream_base::server, ec);
            if (ec)
                return;
            beast::flat_buffer buf;
            // keep-alive 循环：支持连接池复用测试（读干回池 → 下一请求同连接）
            for (;;) {
                http::request<http::string_body> req;
                http::read(stream, buf, req, ec);
                if (ec)
                    return;
                http::response<http::string_body> res(http::status::ok, req.version());
                res.set(http::field::content_type, "text/plain");
                // SNI 回显（无 SNI 为空）：供客户端断言 ClientHello 是否携带 SNI
                const char* sni = SSL_get_servername(stream.native_handle(),
                                                     TLSEXT_NAMETYPE_host_name);
                res.set("X-Test-Sni", sni ? sni : "");
                // 连接辨识钩子（语义同 wpt_server.hpp 的 X-Trace-Conn / X-Conn-Id）
                if (const auto it = req.find("X-Trace-Conn");
                    it != req.end() && it->value() == "1")
                    res.set("X-Conn-Id", std::to_string(conn_id));
                res.body() = req.body();
                res.prepare_payload();
                http::write(stream, res, ec);
                if (ec || req.keep_alive() == false)
                    return;
            }
        } catch (const std::exception&) {
        }
    }

    asio::io_context io_;
    std::shared_ptr<asio::ssl::context> ctx_;
    tcp::acceptor acceptor_{io_};
    uint16_t port_ = 0;
    std::thread thread_;
};

} // namespace wpt_test
