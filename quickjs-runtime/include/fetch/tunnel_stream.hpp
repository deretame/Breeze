// fetchcore —— TunnelStream：HTTP CONNECT 隧道流（http_proxy.hpp 抽出的公共类型）
//
// 隧道流：CONNECT 响应 over-read 的字节先于 socket 交付（beast 经典坑的解法：
// 解析器剩余 buffer 里的字节属于隧道流，ssl::stream 的 NextLayer 需先消费它们，
// 耗尽后再读底层 socket）。
// 满足 ssl::stream<NextLayer> 的接口要求：get_executor / lowest_layer / cancel /
// async_read_some（先 leftover 后 socket）/ async_write_some（直通）。
// 定义在 include/fetch/ 下：连接池（AnyStream::TunnelTls 的 NextLayer 类型，
// include/fetch/connection_pool.hpp）与本头互相可见，且公共 include 路径可达。
#pragma once

#include <boost/asio/ip/tcp.hpp>
#include <boost/beast/core/flat_buffer.hpp>

#include <memory>
#include <utility>

namespace fetch {

class TunnelStream {
public:
    using executor_type = boost::asio::ip::tcp::socket::executor_type;
    using lowest_layer_type = boost::asio::ip::tcp::socket;

    TunnelStream(std::shared_ptr<boost::asio::ip::tcp::socket> sock,
                 boost::beast::flat_buffer leftover)
        : sock_(std::move(sock)), leftover_(std::move(leftover)) {}

    executor_type get_executor() noexcept { return sock_->get_executor(); }
    lowest_layer_type& lowest_layer() noexcept { return *sock_; }
    const lowest_layer_type& lowest_layer() const noexcept { return *sock_; }

    void cancel(boost::system::error_code& ec) { sock_->cancel(ec); }

    template <class MutableBufferSequence, class CompletionToken>
    auto async_read_some(MutableBufferSequence buffers, CompletionToken&& token)
    {
        namespace asio = boost::asio;
        return asio::async_initiate<
            CompletionToken, void(boost::system::error_code, std::size_t)>(
            [this](auto handler, MutableBufferSequence bufs) {
                const std::size_t n = asio::buffer_copy(bufs, leftover_.data());
                if (n > 0) {
                    leftover_.consume(n);
                    // post 保证异步完成（不内联递归）
                    asio::post(sock_->get_executor(),
                               [h = std::move(handler), n]() mutable {
                                   h(boost::system::error_code{}, n);
                               });
                    return;
                }
                sock_->async_read_some(bufs, std::move(handler));
            },
            token, buffers);
    }

    template <class ConstBufferSequence, class CompletionToken>
    auto async_write_some(ConstBufferSequence buffers, CompletionToken&& token)
    {
        return sock_->async_write_some(buffers, std::forward<CompletionToken>(token));
    }

private:
    std::shared_ptr<boost::asio::ip::tcp::socket> sock_;
    boost::beast::flat_buffer leftover_;
};

} // namespace fetch
