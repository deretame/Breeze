// SOCKS5 握手实现（RFC 1928 + RFC 1929 子协商）
#include "socks5.hpp"
#include "connect_util.hpp"
#include <fetch/task.hpp>

#include <boost/asio.hpp>
#include <exec/asio/use_sender.hpp>

#include <functional>
#include <stdexcept>

namespace fetch {

namespace {

// REP → error_code（category=socks5，错误信息可读）
struct Socks5Category : boost::system::error_category {
    const char* name() const noexcept override { return "socks5"; }
    std::string message(int ev) const override
    {
        switch (ev) {
        case 0x00: return "succeeded";
        case 0x01: return "general failure";
        case 0x02: return "connection not allowed by ruleset";
        case 0x03: return "network unreachable";
        case 0x04: return "host unreachable";
        case 0x05: return "connection refused";
        case 0x06: return "TTL expired";
        case 0x07: return "command not supported";
        case 0x08: return "address type not supported";
        default: return "unknown SOCKS5 reply";
        }
    }
};
const Socks5Category& socks5_category()
{
    static const Socks5Category c;
    return c;
}

[[noreturn]] void throw_protocol(const char* what)
{
    throw boost::system::system_error(
        boost::system::error_code(boost::system::errc::protocol_error,
                                  boost::system::generic_category()),
        what);
}

// greeting：无认证 {05,01,00}；有 auth 只声明 0x02（不允许降级为无认证）
std::string build_greeting(const Socks5Proxy& p)
{
    return p.auth ? std::string("\x05\x01\x02", 3) : std::string("\x05\x01\x00", 3);
}

// RFC 1929：{01, ulen, user, plen, pass}（user/pass 各 ≤255 字节，超长抛错不截断：
// 静默截断只会表现为神秘的认证失败）
std::string build_userpass(const Socks5Proxy& p)
{
    const auto& [user, pass] = *p.auth;
    if (user.size() > 255)
        throw std::invalid_argument("socks5: 用户名超长（RFC 1929 限制 ≤255 字节）");
    if (pass.size() > 255)
        throw std::invalid_argument("socks5: 密码超长（RFC 1929 限制 ≤255 字节）");
    std::string s;
    s.push_back('\x01');
    s.push_back(static_cast<char>(user.size()));
    s += user;
    s.push_back(static_cast<char>(pass.size()));
    s += pass;
    return s;
}

// 目标地址 → {ATYP, ADDR}：IP 字面量按 0x01/0x04，其余按 0x03 域名（代理解析）
std::string build_target(std::string_view host)
{
    boost::system::error_code ec;
    if (auto v4 = boost::asio::ip::make_address_v4(host, ec); !ec) {
        auto b = v4.to_bytes();
        std::string s("\x01", 1);
        s.append(reinterpret_cast<const char*>(b.data()), b.size());
        return s;
    }
    if (auto v6 = boost::asio::ip::make_address_v6(host, ec); !ec) {
        auto b = v6.to_bytes();
        std::string s("\x04", 1);
        s.append(reinterpret_cast<const char*>(b.data()), b.size());
        return s;
    }
    // 域名（ATYP=0x03）≤255 字节，超长抛错不截断：截断会让代理去连一个
    // 被截断的错误主机名
    if (host.size() > 255)
        throw std::invalid_argument("socks5: 域名超长（RFC 1928 限制 ≤255 字节）");
    std::string s("\x03", 1);
    s.push_back(static_cast<char>(host.size()));
    s += host;
    return s;
}

} // namespace

std_exec::task<std::shared_ptr<boost::asio::ip::tcp::socket>>
socks5_connect(boost::asio::io_context& io, const Socks5Proxy& proxy,
               std::string_view target_host, uint16_t target_port, std::stop_token st,
               const std::shared_ptr<DnsResolver>& resolver)
{
    namespace net = boost::asio;
    using tcp = net::ip::tcp;

    // 1. 连接代理：解析走 DnsResolver（resolve 阶段的取消由其内化，H2）；
    // connect 依次尝试所有 endpoint，全部失败抛最后一个错误；连上的地址回报
    // 给缓存层做 last_good 排序（§3.3）。发给代理的目标仍携带原始域名（§1.3）。
    auto sock = std::make_shared<tcp::socket>(io);
    std::optional<std::stop_callback<std::function<void()>>> stop_cb;
    if (st.stop_possible())
        stop_cb.emplace(st, [sock] {
            boost::system::error_code ec;
            sock->cancel(ec); // connect/握手阶段生效：operation_aborted → stopped
        });
    const std::string service = std::to_string(proxy.port);
    const auto results = co_await resolver->resolve(proxy.host, service, st);
    const auto addr = co_await detail::connect_all(*sock, results, proxy.port);
    resolver->report_success(proxy.host, service, addr);

    // 握手超时（M1）：僵死代理可让挂起的 read 永不完成；30s 到期 close socket
    //（挂起操作以 operation_aborted 完成 → await_op 映射为 errc::timed_out；
    // 用户取消走 stop_token 路径 → stopped，两者可区分）。timer/handler 均以
    // shared_ptr 持活 sock/state，握手完成后 cancel timer。
    auto deadline = std::make_shared<detail::HandshakeDeadline>(io);
    deadline->timer.expires_after(std::chrono::seconds(30));
    deadline->timer.async_wait([deadline, sock](const boost::system::error_code& ec) {
        if (ec)
            return; // 握手完成/失败：timer 已 cancel
        deadline->fired.store(true, std::memory_order_release);
        boost::system::error_code ec2;
        sock->close(ec2); // 唤醒挂起操作 → await_op 抛超时
    });

    // 2. greeting：方法协商
    const std::string greeting = build_greeting(proxy);
    co_await detail::await_op([&](auto tok) { return net::async_write(*sock, net::buffer(greeting), tok); },
                              deadline, "socks5: handshake timeout", st);
    char gr[2];
    co_await detail::await_op([&](auto tok) { return net::async_read(*sock, net::buffer(gr, 2), tok); },
                              deadline, "socks5: handshake timeout", st);
    if (gr[0] != 0x05)
        throw_protocol("socks5: bad version from server");
    const uint8_t method = static_cast<uint8_t>(gr[1]);
    if (method == 0xFF)
        throw boost::system::system_error(
            boost::system::error_code(boost::system::errc::permission_denied,
                                      boost::system::generic_category()),
            "socks5: 代理拒绝了所有提供的认证方法（可能代理仅支持免认证，"
            "或不认可以提供的 user/pass）");
    if (proxy.auth) {
        if (method != 0x02)
            throw boost::system::system_error(
                boost::system::error_code(boost::system::errc::permission_denied,
                                          boost::system::generic_category()),
                "socks5: server rejected user-pass auth");
        // 3. RFC 1929 子协商
        const std::string up = build_userpass(proxy);
        co_await detail::await_op([&](auto tok) { return net::async_write(*sock, net::buffer(up), tok); },
                                  deadline, "socks5: handshake timeout", st);
        char ur[2];
        co_await detail::await_op([&](auto tok) { return net::async_read(*sock, net::buffer(ur, 2), tok); },
                                  deadline, "socks5: handshake timeout", st);
        if (ur[0] != 0x01 || ur[1] != 0x00)
            throw boost::system::system_error(
                boost::system::error_code(boost::system::errc::permission_denied,
                                          boost::system::generic_category()),
                "socks5: user-pass authentication failed");
    } else if (method != 0x00) {
        throw_protocol("socks5: server chose an undeclared method");
    }

    // 4. CONNECT（注意：不能用含 \x00 的 C 字符串字面量 += —— strlen 会截断）
    std::string conn;
    conn.reserve(7 + target_host.size());
    conn.push_back(0x05);
    conn.push_back(0x01);
    conn.push_back(0x00);
    conn += build_target(target_host);
    conn.push_back(static_cast<char>(target_port >> 8));
    conn.push_back(static_cast<char>(target_port & 0xFF));
    co_await detail::await_op([&](auto tok) { return net::async_write(*sock, net::buffer(conn), tok); },
                              deadline, "socks5: handshake timeout", st);
    char rh[4];
    co_await detail::await_op([&](auto tok) { return net::async_read(*sock, net::buffer(rh, 4), tok); },
                              deadline, "socks5: handshake timeout", st);
    if (rh[0] != 0x05 || rh[2] != 0x00)
        throw_protocol("socks5: malformed CONNECT reply");
    if (rh[1] != 0x00)
        throw boost::system::system_error(
            boost::system::error_code(rh[1], socks5_category()),
            "socks5: CONNECT rejected");
    // BND.ADDR（按 ATYP 读变长）
    size_t bnd_len = 0;
    switch (rh[3]) {
    case 0x01: bnd_len = 4; break;
    case 0x04: bnd_len = 16; break;
    case 0x03: {
        char len = 0;
        co_await detail::await_op([&](auto tok) { return net::async_read(*sock, net::buffer(&len, 1), tok); },
                                  deadline, "socks5: handshake timeout", st);
        bnd_len = static_cast<uint8_t>(len);
        break;
    }
    default:
        throw boost::system::system_error(
            boost::system::error_code(0x08, socks5_category()),
            "socks5: unsupported BND.ADDR type");
    }
    std::string bnd(bnd_len + 2, 0);
    co_await detail::await_op([&](auto tok) { return net::async_read(*sock, net::buffer(bnd.data(), bnd.size()), tok); },
                              deadline, "socks5: handshake timeout", st);

    deadline->timer.cancel(); // 握手完成：解除超时（handler 以 operation_aborted 退出）
    co_return sock;
}

} // namespace fetch
