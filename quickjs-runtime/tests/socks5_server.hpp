// tests/socks5_server.hpp —— mini SOCKS5 测试服务器（M4 对打测试用）
//
// 支持：无认证 / user-pass（RFC 1929）方法协商；CONNECT（ATYP 域名/IPv4/IPv6）；
// 可配置：强制 REP 错误码、延迟 greeting 响应（握手中止测试）、记录目标地址
// （选路断言）。隧道建立后双向转发字节（relay）。
//
// 实现：独立线程 + 同步 accept，每连接一个处理线程（测试负载小，够用且简单）。
#pragma once

#include <boost/asio.hpp>

#include <log.hpp>

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cstdio>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <thread>
#include <vector>

namespace qjsbind::net::wpt {

namespace asio = boost::asio;
using tcp = asio::ip::tcp;

class Socks5TestServer {
public:
    struct Options {
        bool require_auth = false;      // 需要 user-pass（RFC 1929）
        std::string username, password; // 期望的凭据（require_auth 时校验）
        int fail_rep = 0;               // 非 0：CONNECT 一律回该 REP（0x01..0x08）
        int greet_delay_ms = 0;         // 延迟响应 greeting（握手中止测试）
        bool record_targets = false;    // 记录 CONNECT 目标（选路断言）
    };

    // 无参构造在类外定义（类内 mem-initializer 中使用聚合默认成员初始化器
    // 会被 clang 拒绝——'outside of member functions'；MSVC 宽松接受）
    Socks5TestServer();
    explicit Socks5TestServer(Options opt) : opt_(std::move(opt)) {}
    ~Socks5TestServer() { stop(); }

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
        if (thread_.joinable())
            thread_.join();
    }

    std::string host() const { return "127.0.0.1"; }
    uint16_t port() const { return port_; }

    // CONNECT 目标记录（record_targets 时）：{host, port} 列表
    std::vector<std::pair<std::string, uint16_t>> targets()
    {
        std::lock_guard<std::mutex> lk(mu_);
        return targets_;
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
            std::thread(&Socks5TestServer::handle, this, std::move(client)).detach();
        }
    }

    // ---- 单连接处理：握手 → 连目标 → relay ----
    void handle(tcp::socket client)
    {
        try {
            // greeting: [05, nmethods, methods...]
            unsigned char hdr[2];
            read_exact(client, hdr, 2);
            if (hdr[0] != 0x05)
                return;
            std::vector<unsigned char> methods(hdr[1]);
            read_exact(client, methods.data(), methods.size());

            if (opt_.greet_delay_ms > 0)
                std::this_thread::sleep_for(std::chrono::milliseconds(opt_.greet_delay_ms));

            const bool has_userpass =
                std::find(methods.begin(), methods.end(), 0x02) != methods.end();
            if (opt_.require_auth) {
                if (!has_userpass) {
                    const unsigned char no[] = {0x05, 0xFF};
                    asio::write(client, asio::buffer(no, 2));
                    return;
                }
                const unsigned char ok[] = {0x05, 0x02};
                asio::write(client, asio::buffer(ok, 2));
                // RFC 1929: [01, ulen, user, plen, pass]
                unsigned char uh[2];
                read_exact(client, uh, 2);
                if (uh[0] != 0x01)
                    return;
                std::string user(uh[1], '\0');
                read_exact(client, reinterpret_cast<unsigned char*>(user.data()), user.size());
                unsigned char plen = 0;
                read_exact(client, &plen, 1);
                std::string pass(plen, '\0');
                read_exact(client, reinterpret_cast<unsigned char*>(pass.data()), pass.size());
                const bool auth_ok = user == opt_.username && pass == opt_.password;
                const unsigned char st[] = {0x01, static_cast<unsigned char>(auth_ok ? 0 : 1)};
                asio::write(client, asio::buffer(st, 2));
                if (!auth_ok)
                    return;
            } else {
                const unsigned char ok[] = {0x05, 0x00};
                asio::write(client, asio::buffer(ok, 2));
            }

            // CONNECT: [05, 01, 00, atyp, addr, port]
            unsigned char ch[4];
            read_exact(client, ch, 4);
            if (ch[0] != 0x05 || ch[1] != 0x01 || ch[3] == 0x00)
                return;
            std::string target_host;
            switch (ch[3]) {
            case 0x01: {
                unsigned char a[4];
                read_exact(client, a, 4);
                target_host = std::to_string(a[0]) + "." + std::to_string(a[1]) + "." +
                              std::to_string(a[2]) + "." + std::to_string(a[3]);
                break;
            }
            case 0x03: {
                unsigned char l = 0;
                read_exact(client, &l, 1);
                target_host.resize(l);
                read_exact(client, reinterpret_cast<unsigned char*>(target_host.data()), l);
                break;
            }
            case 0x04: {
                unsigned char a[16];
                read_exact(client, a, 16);
                char buf[64];
                std::snprintf(buf, sizeof(buf), "%02x%02x:%02x%02x:%02x%02x:%02x%02x:"
                                              "%02x%02x:%02x%02x:%02x%02x:%02x%02x",
                              a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7], a[8], a[9],
                              a[10], a[11], a[12], a[13], a[14], a[15]);
                target_host = buf;
                break;
            }
            default:
                return;
            }
            unsigned char pbuf[2];
            read_exact(client, pbuf, 2);
            const uint16_t target_port =
                static_cast<uint16_t>((pbuf[0] << 8) | pbuf[1]);

            if (opt_.record_targets) {
                std::lock_guard<std::mutex> lk(mu_);
                targets_.emplace_back(target_host, target_port);
            }

            if (opt_.fail_rep != 0) {
                const unsigned char rep[] = {0x05, static_cast<unsigned char>(opt_.fail_rep),
                                             0x00, 0x01, 0, 0, 0, 0, 0, 0};
                asio::write(client, asio::buffer(rep, sizeof(rep)));
                return;
            }

            // 连目标（域名经 resolver——测试里是 localhost/127.0.0.1）
            tcp::resolver resolver(io_);
            boost::system::error_code ec;
            auto results = resolver.resolve(target_host, std::to_string(target_port), ec);
            if (ec || results.empty()) {
                const unsigned char rep[] = {0x05, 0x04, 0x00, 0x01, 0, 0, 0, 0, 0, 0};
                asio::write(client, asio::buffer(rep, sizeof(rep)));
                return;
            }
            tcp::socket target(io_);
            // 遍历解析结果（localhost 可能先解析到 ::1，而目标只监听 IPv4）；
            // connect 失败后 socket 需重新 open 才能再连（boost 语义）
            for (auto it = results.begin(); it != results.end(); ++it) {
                boost::system::error_code e2;
                target.close(e2);
                target.open(it->endpoint().protocol(), e2);
                target.connect(*it, ec);
                if (!ec)
                    break;
            }
            if (ec) {
                const unsigned char rep[] = {0x05, 0x05, 0x00, 0x01, 0, 0, 0, 0, 0, 0};
                asio::write(client, asio::buffer(rep, sizeof(rep)));
                return;
            }
            const unsigned char ok[] = {0x05, 0x00, 0x00, 0x01, 0, 0, 0, 0, 0, 0};
            asio::write(client, asio::buffer(ok, sizeof(ok)));

            // relay：双向转发（各一个循环，读到 EOF/错误即停）
            pump(std::move(client), std::move(target));
        } catch (const std::exception& e) {
            QLOG_ERROR("[socks5] handle error: {}", e.what());
        } catch (...) {
            QLOG_ERROR("[socks5] handle unknown error");
        }
    }

    // 双向转发（两个方向各一个线程；shared_ptr 保证 detach 期间 socket 存活）
    void pump(tcp::socket a, tcp::socket b)
    {
        auto pa = std::make_shared<tcp::socket>(std::move(a));
        auto pb = std::make_shared<tcp::socket>(std::move(b));
        std::thread([pa, pb] { pump_one(*pa, *pb); }).detach();
        std::thread([pa, pb] { pump_one(*pb, *pa); }).detach();
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

    static void read_exact(tcp::socket& s, void* data, size_t n)
    {
        size_t got = 0;
        while (got < n) {
            const size_t k = s.read_some(
                asio::buffer(static_cast<char*>(data) + got, n - got));
            if (k == 0)
                throw std::runtime_error("socks5 test server: unexpected EOF");
            got += k;
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
    std::vector<std::pair<std::string, uint16_t>> targets_;
};

// 类外定义：类内 mem-initializer 使用聚合默认成员初始化器会被 clang 拒绝
inline Socks5TestServer::Socks5TestServer() : Socks5TestServer(Options{}) {}

} // namespace qjsbind::net::wpt
