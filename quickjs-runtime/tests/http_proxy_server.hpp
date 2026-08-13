// tests/http_proxy_server.hpp —— mini HTTP forward proxy 测试服务器（M-P1/P2 对打测试用）
//
// 支持：absolute-form 转发（http 目标，转发前重写为 origin-form 并剥离
// hop-by-hop 头）、CONNECT 中继（https 隧道）、Basic 认证校验 / 强制 407、
// 记录目标（选路与 absolute-form 断言）、CONNECT 响应延迟（中止测试）、
// 强制非 200（CONNECT 拒绝映射测试）。隧道建立后双向转发字节（relay）。
//
// 实现：独立线程 + 同步 accept，每连接一个处理线程（测试负载小，够用且简单）。
#pragma once

#include <boost/asio.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>

#include <openssl/base64.h>

#include <ada.h>

#include <log.hpp>

#include <fetch/url_check.hpp> // origin_form_target（origin-form 请求行 target）

#include <algorithm>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdio>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <utility>
#include <vector>

namespace qjsbind::net::wpt {

namespace asio = boost::asio;
namespace beast = boost::beast;
namespace http = beast::http;
using tcp = asio::ip::tcp;

class HttpProxyTestServer {
public:
    struct Options {
        std::optional<std::pair<std::string, std::string>> require_auth; // 期望的 Basic 凭据
        bool force_407 = false;        // 一律回 407（缺凭据语义测试）
        bool fail_connect = false;     // CONNECT 一律回 502（非 200 映射测试）
        int connect_delay_ms = 0;      // 延迟 CONNECT 200 响应（中止测试）
        bool record_targets = false;   // 记录转发/CONNECT 目标（选路断言）
    };

    struct Record {
        std::string host;            // 目标 host（absolute-form / CONNECT）
        uint16_t port = 0;           // 目标端口
        std::string target_line;     // 客户端请求行 target（absolute-form 断言）
        bool is_connect = false;     // CONNECT 隧道
        bool fwd_has_proxy_auth = false; // 转发前原请求带 Proxy-Authorization（客户端发了凭据）
    };

    // 无参构造在类外定义（类内 mem-initializer 中使用聚合默认成员初始化器
    // 会被 clang 拒绝——'outside of member functions'；MSVC 宽松接受）
    HttpProxyTestServer();
    explicit HttpProxyTestServer(Options opt) : opt_(std::move(opt)) {}
    ~HttpProxyTestServer() { stop(); }

    void start()
    {
        if (running_)
            return;
        running_ = true;
        thread_ = std::thread([this] { run(); });
        while (!ready_.load(std::memory_order_acquire) && running_)
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }

    void stop()
    {
        if (!running_)
            return;
        running_ = false;
        boost::system::error_code ec;
        if (acceptor_)
            acceptor_->close(ec);
        // 关闭所有活动连接：唤醒阻塞在 I/O 上的 handle/pump 线程
        std::vector<std::shared_ptr<tcp::socket>> conns;
        {
            std::lock_guard<std::mutex> lk(mu_);
            conns = conns_;
        }
        for (auto& s : conns)
            s->close(ec);
        // 确定性等待所有工作线程退出（析构后不再有线程访问成员）；
        // 超时兜底：异常路径（漏登记的线程）不挂死测试进程
        std::unique_lock<std::mutex> lk(cv_mu_);
        if (!cv_.wait_for(lk, std::chrono::seconds(5),
                          [this] { return active_.load(std::memory_order_acquire) == 0; }))
            QLOG_WARNING(
                "[http_proxy] stop(): 5s 内 {} 个工作线程未退出（漏登记？）",
                active_.load(std::memory_order_acquire));
        if (thread_.joinable())
            thread_.join();
    }

    std::string host() const { return "127.0.0.1"; }
    uint16_t port() const { return port_; }

    // 目标记录（record_targets 时）：{host, port, target_line, is_connect, ...}
    std::vector<Record> targets()
    {
        std::lock_guard<std::mutex> lk(mu_);
        return records_;
    }

private:
    void run()
    {
        acceptor_ = std::make_unique<tcp::acceptor>(
            io_, tcp::endpoint(asio::ip::address_v4::loopback(), 0));
        port_ = acceptor_->local_endpoint().port();
        ready_.store(true, std::memory_order_release);
        while (running_) {
            boost::system::error_code ec;
            tcp::socket client = acceptor_->accept(ec);
            if (ec)
                break;
            handle(std::move(client));
        }
    }

    // ---- 单连接处理（工作线程）：读请求 → 认证 → CONNECT 隧道 / absolute-form 转发 ----
    // 线程登记：active_ 计数 + conns_ 登记（stop() 据此 close + 等待退出）
    void handle(tcp::socket client)
    {
        auto conn = std::make_shared<tcp::socket>(std::move(client));
        std::thread([this, conn] {
            enter(conn);
            struct Exit {
                HttpProxyTestServer* self;
                ~Exit() { self->exit_thread(); }
            } guard{this};
            handle_inner(*conn);
        }).detach();
    }

    void handle_inner(tcp::socket& client)
    {
        try {
            beast::flat_buffer buf;
            http::request_parser<http::string_body> parser;
            boost::system::error_code ec;
            http::read(client, buf, parser, ec);
            if (ec)
                return;
            auto req = parser.release(); // 独立拷贝：转发前改写

            // 认证：缺失/错误凭据（或 force_407）→ 407 + Proxy-Authenticate
            if (opt_.force_407 || !check_auth(req)) {
                http::response<http::string_body> res(
                    http::status::proxy_authentication_required, req.version());
                res.set(http::field::proxy_authenticate, "Basic realm=\"test\"");
                res.set(http::field::content_type, "text/plain");
                res.body() = "proxy auth required";
                res.prepare_payload();
                http::write(client, res, ec);
                return;
            }

            if (req.method() == http::verb::connect) {
                // CONNECT host:port → 建隧道
                const std::string target(req.target());
                const size_t colon = target.rfind(':');
                if (colon == std::string::npos) {
                    bad_request(client, req.version(), "bad CONNECT target");
                    return;
                }
                const std::string thost = target.substr(0, colon);
                const int tport = std::stoi(target.substr(colon + 1));
                if (opt_.record_targets)
                    record(thost, tport, target, true, false);
                if (opt_.connect_delay_ms > 0)
                    std::this_thread::sleep_for(
                        std::chrono::milliseconds(opt_.connect_delay_ms));
                if (opt_.fail_connect) {
                    http::response<http::string_body> res(
                        http::status::bad_gateway, req.version());
                    res.set(http::field::content_type, "text/plain");
                    res.body() = "connect refused by policy";
                    res.prepare_payload();
                    http::write(client, res, ec);
                    return;
                }
                tcp::socket target_sock(io_);
                tcp::resolver resolver(io_);
                auto results = resolver.resolve(thost, std::to_string(tport), ec);
                if (ec || results.empty()) {
                    http::response<http::string_body> res(
                        http::status::bad_gateway, req.version());
                    res.body() = "resolve failed";
                    res.prepare_payload();
                    http::write(client, res, ec);
                    return;
                }
                ec.clear();
                for (auto it = results.begin(); it != results.end(); ++it) {
                    target_sock.close(ec);
                    target_sock.open(it->endpoint().protocol(), ec);
                    target_sock.connect(*it, ec);
                    if (!ec)
                        break;
                }
                if (ec) {
                    http::response<http::string_body> res(
                        http::status::bad_gateway, req.version());
                    res.body() = "connect failed";
                    res.prepare_payload();
                    http::write(client, res, ec);
                    return;
                }
                http::response<http::empty_body> ok(http::status::ok, req.version());
                http::write(client, ok, ec);
                // 隧道：双向转发（目标侧可能立刻开始 TLS 握手字节）
                pump(std::move(client), std::move(target_sock));
                return;
            }

            // ---- absolute-form 转发（http 目标）----
            const std::string target(req.target());
            if (target.rfind("http://", 0) != 0) {
                bad_request(client, req.version(), "non-absolute-form request");
                return;
            }
            auto parsed = ada::parse<ada::url_aggregator>(target);
            if (!parsed || parsed->get_hostname().empty()) {
                bad_request(client, req.version(), "bad absolute-form target");
                return;
            }
            const auto& u = *parsed;
            const std::string thost = std::string(u.get_hostname());
            const std::string tport = u.has_port() ? std::string(u.get_port()) : "80";
            if (opt_.record_targets)
                record(thost, static_cast<uint16_t>(std::stoi(tport)), target, false,
                       req.find(http::field::proxy_authorization) != req.end());
            // hop-by-hop 头剥离（凭据只发给代理，绝不转发给目标）
            req.erase(http::field::proxy_authorization);
            req.erase(http::field::proxy_connection);
            req.erase(http::field::connection);
            // origin-form：path[?query]（origin_form_target 保留空 query 的 '?'）
            std::string origin = fetch::origin_form_target(u);
            if (origin.empty())
                origin = "/";
            req.target(origin); // 转发给目标用 origin-form
            req.set(http::field::host, thost + (tport == "80" ? "" : ":" + tport));

            tcp::socket target_sock(io_);
            tcp::resolver resolver(io_);
            auto results = resolver.resolve(thost, tport, ec);
            if (ec || results.empty()) {
                bad_request(client, req.version(), "target resolve failed");
                return;
            }
            ec.clear();
            for (auto it = results.begin(); it != results.end(); ++it) {
                target_sock.close(ec);
                target_sock.open(it->endpoint().protocol(), ec);
                target_sock.connect(*it, ec);
                if (!ec)
                    break;
            }
            if (ec) {
                bad_request(client, req.version(), "target connect failed");
                return;
            }
            http::write(target_sock, req, ec);
            if (ec)
                return;
            beast::flat_buffer rbuf;
            http::response<http::string_body> res;
            http::read(target_sock, rbuf, res, ec);
            if (ec)
                return;
            http::write(client, res, ec);
        } catch (const std::exception& e) {
            QLOG_ERROR("[http_proxy] handle error: {}", e.what());
        } catch (...) {
            QLOG_ERROR("[http_proxy] handle unknown error");
        }
    }

    bool check_auth(const http::request<http::string_body>& req)
    {
        if (!opt_.require_auth)
            return true;
        const auto it = req.find(http::field::proxy_authorization);
        if (it == req.end())
            return false;
        const auto& [user, pass] = *opt_.require_auth;
        const std::string expect = "Basic " + basic64(user + ":" + pass);
        return it->value() == expect;
    }

    void record(std::string host, uint16_t port, std::string target_line, bool is_connect,
                bool fwd_has_proxy_auth)
    {
        std::lock_guard<std::mutex> lk(mu_);
        records_.push_back(
            {std::move(host), port, std::move(target_line), is_connect, fwd_has_proxy_auth});
    }

    void bad_request(tcp::socket& client, unsigned version, const char* why)
    {
        http::response<http::string_body> res(http::status::bad_request, version);
        res.set(http::field::content_type, "text/plain");
        res.body() = why;
        res.prepare_payload();
        boost::system::error_code ec;
        http::write(client, res, ec);
    }

    static std::string basic64(std::string_view in)
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

    // 双向转发（两个方向各一个工作线程；shared_ptr 保证线程期间 socket 存活；
    // 线程登记进 active_/conns_，stop() 关闭 socket 后确定性等待退出）
    void pump(tcp::socket a, tcp::socket b)
    {
        auto pa = std::make_shared<tcp::socket>(std::move(a));
        auto pb = std::make_shared<tcp::socket>(std::move(b));
        auto spawn = [this](std::shared_ptr<tcp::socket> from,
                            std::shared_ptr<tcp::socket> to) {
            std::thread([this, from, to] {
                enter(to); // 两个方向都登记（stop() 需关闭两侧 socket 唤醒对方线程）
                struct Exit {
                    HttpProxyTestServer* self;
                    ~Exit() { self->exit_thread(); }
                } guard{this};
                pump_one(*from, *to);
            }).detach();
        };
        spawn(pa, pb);
        spawn(pb, pa);
    }

    static void pump_one(tcp::socket& from, tcp::socket& to)
    {
        char buf[8192];
        for (;;) {
            boost::system::error_code ec;
            const size_t n = from.read_some(asio::buffer(buf), ec);
            if (ec || n == 0)
                break;
            asio::write(to, asio::buffer(buf, n), ec);
            if (ec)
                break;
        }
        boost::system::error_code ec;
        to.shutdown(tcp::socket::shutdown_send, ec);
    }

    // ---- 工作线程登记 / 退出 ----
    void enter(const std::shared_ptr<tcp::socket>& conn)
    {
        active_.fetch_add(1, std::memory_order_acq_rel);
        std::lock_guard<std::mutex> lk(mu_);
        conns_.push_back(conn);
        // 竞态窗口（accept 返回后、登记前 stop() 已执行）：登记后发现
        // running_ 已停 → 自关连接，避免线程阻塞在 I/O 上永不退出
        if (!running_.load(std::memory_order_acquire)) {
            boost::system::error_code ec;
            conn->close(ec);
        }
    }

    void exit_thread()
    {
        if (active_.fetch_sub(1, std::memory_order_acq_rel) == 1) {
            std::lock_guard<std::mutex> lk(cv_mu_);
            cv_.notify_all();
        }
    }

    Options opt_;
    asio::io_context io_; // 长期存活（acceptor 与隧道目标 socket 关联；析构在最后）
    std::atomic<bool> running_{false};
    std::atomic<bool> ready_{false};
    std::unique_ptr<tcp::acceptor> acceptor_;
    uint16_t port_ = 0;
    std::thread thread_;
    std::mutex mu_;
    std::vector<Record> records_;
    // ---- 工作线程管理（stop() 确定性清理）----
    std::mutex cv_mu_;
    std::condition_variable cv_;
    std::atomic<int> active_{0};                 // 未退出工作线程数
    std::vector<std::shared_ptr<tcp::socket>> conns_; // 活动连接（受 mu_ 保护）
};

// 类外定义：类内 mem-initializer 使用聚合默认成员初始化器会被 clang 拒绝
inline HttpProxyTestServer::HttpProxyTestServer() : HttpProxyTestServer(Options{}) {}

} // namespace qjsbind::net::wpt
