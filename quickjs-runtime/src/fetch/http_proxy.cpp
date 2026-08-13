// HTTP forward proxy 实现：CONNECT 隧道（docs/proxy_test_plan.md §4）
#include "http_proxy.hpp"
#include "connect_util.hpp"
#include <fetch/task.hpp>

#include <boost/asio.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>
#include <exec/asio/use_sender.hpp>

#include <functional>
#include <stdexcept>

namespace fetch {

std_exec::task<HttpProxyConnectResult>
http_proxy_connect(boost::asio::io_context& io, const HttpProxy& proxy,
                   std::string_view target_host, uint16_t target_port, std::stop_token st,
                   const std::shared_ptr<DnsResolver>& resolver)
{
    namespace net = boost::asio;
    namespace http = boost::beast::http;
    using tcp = net::ip::tcp;

    // 1. 连接代理：解析走 DnsResolver（resolve 阶段的取消由其内化，H2）；
    // connect 依次尝试所有 endpoint，全部失败抛最后一个错误；连上的地址回报
    // 给缓存层做 last_good 排序（§3.3）。CONNECT 目标仍携带原始域名（§1.3）。
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
    // 用户取消走 stop_token 路径 → stopped，两者可区分）。
    auto deadline = std::make_shared<detail::HandshakeDeadline>(io);
    deadline->timer.expires_after(std::chrono::seconds(30));
    deadline->timer.async_wait([deadline, sock](const boost::system::error_code& ec) {
        if (ec)
            return; // 握手完成/失败：timer 已 cancel
        deadline->fired.store(true, std::memory_order_release);
        boost::system::error_code ec2;
        sock->close(ec2); // 唤醒挂起操作 → await_op 抛超时
    });

    // 2. CONNECT 报文（authority-form；Basic 凭据只出现在发往代理的连接上）
    const std::string target = authority_form(target_host, std::to_string(target_port));
    http::request<http::empty_body> creq{http::verb::connect, target, 11};
    creq.set(http::field::host, target);
    if (proxy.auth) {
        const auto& [user, pass] = *proxy.auth;
        creq.set(http::field::proxy_authorization,
                 "Basic " + base64_encode(user + ":" + pass));
    }
    co_await detail::await_op([&](auto tok) { return http::async_write(*sock, creq, tok); },
                              deadline, "http_proxy: CONNECT handshake timeout", st);

    // 3. 读响应头（200 CONNECT 无 body，头读完即完成——成功路径绝不读 body：
    //    隧道里后续字节是目标流量，绝不能消费；async_read 已 over-read 的
    //    字节留在 buffer 移交）
    boost::beast::flat_buffer buffer;
    http::response_parser<http::string_body> parser;
    co_await detail::await_op(
        [&](auto tok) { return http::async_read_header(*sock, buffer, parser, tok); },
        deadline, "http_proxy: CONNECT handshake timeout", st);
    const int status = parser.get().result_int();
    if (status != 200) {
        // 失败响应（如 407）：读 body 前 4 KiB 摘要附进错误信息，便于诊断（L5）。
        // 仅当有明确帧界（content-length/chunked）时读——EOF 界定的 body 不读
        // （代理可能 keep-alive 不关连接，会挂到超时）。超限/读错按已收到部分
        // 截断使用（best-effort，不掩盖原始状态码）。
        if (parser.get().has_content_length() || parser.chunked()) {
            parser.body_limit(4096);
            try {
                co_await detail::await_op(
                    [&](auto tok) { return http::async_read(*sock, buffer, parser, tok); },
                    deadline, "http_proxy: CONNECT handshake timeout", st);
            } catch (const boost::system::system_error&) {
                // 忽略：body 摘要是 best-effort
            }
        }
        std::string msg = "http_proxy: CONNECT rejected";
        if (!parser.get().body().empty())
            msg += ": " + parser.get().body();
        throw boost::system::system_error(
            boost::system::error_code(status, http_proxy_category()), msg);
    }
    deadline->timer.cancel(); // 握手完成：解除超时（handler 以 operation_aborted 退出）
    co_return HttpProxyConnectResult{std::move(sock), std::move(buffer)};
}

} // namespace fetch
