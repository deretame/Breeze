// 建连/握手阶段通用工具（src/fetch 内部头）：
//   - connect_all：依次尝试 DnsResult 的所有 endpoint（H1）；
//   - await_op：redirect_error 等待 + 取消/超时统一分流（M1 握手超时用）；
//   - HandshakeDeadline：steady_timer + fired 标志（超时 close socket）。
#pragma once

#include <fetch/task.hpp>
#include <fetch/dns_resolver.hpp>

#include <boost/asio.hpp>
#include <exec/asio/use_sender.hpp>

#include <atomic>
#include <chrono>
#include <cstdint>
#include <memory>
#include <stop_token>

namespace fetch::detail {

namespace net = boost::asio;

// 代理握手超时状态：timer 触发置 fired 后 close socket（挂起操作以
// operation_aborted 完成 → 由 await_op 映射为超时错误）。
struct HandshakeDeadline {
    explicit HandshakeDeadline(net::io_context& io) : timer(io) {}
    net::steady_timer timer;
    std::atomic<bool> fired{false};
};

// 通用网络等待：op 经 redirect_error 完成（错误不直接转 stopped/set_error，
// 协程恢复后统一分流）：
//   超时（deadline 触发 close，且非用户取消）→ 抛 errc::timed_out；
//   用户取消（stop_token 触发的 operation_aborted）→ 传播 stopped（AbortError）；
//   其余错误 → 抛 system_error。
// init 形如 [&](auto token) { return net::async_write(sock, buf, token); }。
template <class Init>
std_exec::task<void> await_op(Init&& init, const std::shared_ptr<HandshakeDeadline>& dl,
                              const char* what, std::stop_token st)
{
    boost::system::error_code ec;
    co_await init(net::redirect_error(exec::asio::use_sender, ec));
    if (!ec)
        co_return;
    if (dl && dl->fired.load(std::memory_order_acquire) && !st.stop_requested())
        throw boost::system::system_error(
            boost::system::errc::make_error_code(boost::system::errc::timed_out), what);
    if (ec == net::error::operation_aborted)
        co_await stdexec::just_stopped(); // 用户取消 → stopped（绑定层 reject AbortError）
    throw boost::system::system_error(ec);
}

// 依次尝试 resolve 结果（DnsResult，见 docs/dns_resolver_design.md §2.4）的所有
// endpoint（对齐 happy-eyeballs 的退化版：串行）：第一个成功即返回其地址（供
// 连接层回报 last_good）；全部失败抛最后一个错误；用户取消 → stopped。
// 每次重试前 close：connect 失败后的 socket 处于未指定状态，重新打开再连。
// port 为单次 resolve 的服务端口（DnsEntry 不带端口，整个结果集同属一个 service）。
inline std_exec::task<net::ip::address>
connect_all(net::ip::tcp::socket& sock, const fetch::DnsResult& results, uint16_t port)
{
    boost::system::error_code ec;
    for (const auto& e : results) {
        if (sock.is_open())
            sock.close(ec);
        ec.clear();
        co_await sock.async_connect(net::ip::tcp::endpoint(e.addr, port),
                                    net::redirect_error(exec::asio::use_sender, ec));
        if (!ec)
            co_return e.addr;
        if (ec == net::error::operation_aborted)
            co_await stdexec::just_stopped(); // 用户取消 → stopped
    }
    throw boost::system::system_error(ec);
}

} // namespace fetch::detail
