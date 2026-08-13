// fetchcore —— HTTP/1.1 keep-alive 连接池（docs/fetch_connection_pool_design.md §3.3）
//
// 对照 hyper-util pool.rs 的逐条映射见设计文档；要点：
//   - 无锁：池只允许在 io 线程访问（线程契约见 fetch_cpp_decoupling.md §4.2）。
//   - LIFO 复用（vector 当栈）；max_idle_per_host 只在 put 时执行（超限丢弃）。
//   - 活性检查分层降级：socket is_open() → plain TCP 一次性 MSG_PEEK 探测 →
//     统一靠复用重试兜底（写失败 = 请求从未上线；写成功但读头零字节 EOF =
//     陈旧 keep-alive，请求大概率未被处理——两者均重试一次，见 pooled_flow）。
//   - 归还全靠 RAII：PooledConnection 析构/put_back；连接与池互不续命
//     （weak_ptr 回指，对应 hyper 全链 Weak 设计）。
//   - 清扫定时器：steady_timer 挂 io_context；池空自停；池销毁即取消。
#pragma once

#include <fetch/types.hpp>
#include <fetch/tunnel_stream.hpp> // TunnelTls = ssl::stream<TunnelStream>

#include <boost/asio/io_context.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <boost/asio/ssl.hpp>
#include <boost/beast/core/flat_buffer.hpp>

#include <atomic>
#include <chrono>
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <thread>
#include <unordered_map>
#include <utility>
#include <variant>
#include <vector>

namespace fetch {

// ---- 连接实体：现有三种 stream 的 variant（静态分派零堆分配）----
// PlainStream = 明文直连/明文代理转发；TlsStream = https 直连或 SOCKS5 隧道上的
// TLS；TunnelTls = HTTP CONNECT 隧道上的 TLS。ssl::context 由 IdleEntry.tls_ctx
// 以 shared_ptr 持有（boost 契约：context 须比 stream 活得久）。
using PlainStream = boost::asio::ip::tcp::socket;
using TlsStream = boost::asio::ssl::stream<boost::asio::ip::tcp::socket>;
using TunnelTls = boost::asio::ssl::stream<TunnelStream>;
using AnyStream = std::variant<PlainStream, TlsStream, TunnelTls>;

struct IdleEntry {
    // 声明序 = 析构逆序：tls_ctx 必须**最后**析构——boost 契约要求
    // ssl::context 活得比 ssl::stream 久（SSL_free 触碰 ctx），故声明在最前。
    std::shared_ptr<boost::asio::ssl::context> tls_ctx; // TLS 连接的 ctx 必须随连接存活
    AnyStream stream;
    boost::beast::flat_buffer buffer; // 连接上残留的 over-read 字节，属于连接不属于请求
    std::chrono::steady_clock::time_point idle_at;
};

class ConnectionPool;

// RAII 句柄：hyper Pooled 的对应物（h1 Unique 语义，move-only）。
// 生命周期：持有 IdleEntry 直到 put_back()（回池）或析构（关闭）。
// 池可能先于句柄销毁：weak_ptr 回指，upgrade 失败即退化为直接关闭（§3.11）。
class PooledConnection {
public:
    PooledConnection() = default;
    PooledConnection(std::weak_ptr<ConnectionPool> pool, PoolKey key, IdleEntry entry,
                     bool is_reused)
        : pool_(std::move(pool)), key_(std::move(key)), entry_(std::move(entry)),
          is_reused_(is_reused)
    {
    }
    PooledConnection(PooledConnection&&) noexcept = default;
    PooledConnection& operator=(PooledConnection&&) noexcept = default;
    PooledConnection(const PooledConnection&) = delete;
    PooledConnection& operator=(const PooledConnection&) = delete;
    ~PooledConnection() = default; // entry_ 析构即关闭连接（未归还的终点）

    AnyStream& stream() { return entry_->stream; }
    boost::beast::flat_buffer& buffer() { return entry_->buffer; }
    std::shared_ptr<boost::asio::ssl::context>& tls_ctx() { return entry_->tls_ctx; }
    bool is_reused() const { return is_reused_; } // 对应 Pooled::is_reused（驱动重试/统计）
    bool has_entry() const { return entry_.has_value(); }

    // = hyper 的 Connected::poison()：标记"永不复用"，析构/put_back 时关闭。
    void discard() { discard_ = true; }

    // 归还池（仅 io 线程）。池已销毁 → 直接关闭。discard 标记 → 关闭。
    // 实现在 connection_pool.cpp（需要 ConnectionPool 完整定义）。
    void put_back();

private:
    std::weak_ptr<ConnectionPool> pool_;
    PoolKey key_;
    std::optional<IdleEntry> entry_;
    bool is_reused_ = false;
    bool discard_ = false;
};

// 池本体：纯数据结构 + 一把"线程契约"（无锁，仅 io 线程）+ 可选清扫定时器。
// checkout/put 全部同步；建连（DNS/TCP/TLS/握手）完全在池外。
// 线程契约（§3.11）：除 checkout/put/close_all 外，**io 运行期间池的最后引用
// 也必须在 io 线程释放**（析构销毁 timer/idle socket，与 io_context 轮询并发
// 即数据竞争；debug 构建由 ~ConnectionPool 的 assert_io_thread 守约；io 停止
// 后的释放无并发，任意线程均可）。
class ConnectionPool : public std::enable_shared_from_this<ConnectionPool> {
public:
    ConnectionPool(boost::asio::io_context& io, PoolOptions opts);
    ~ConnectionPool(); // 取消清扫定时器，map 内所有 idle 连接随 IdleEntry 析构关闭

    // 取连接（仅 io 线程；同步）：LIFO pop + 过期检查 + 活性检查；未命中 → nullopt
    //（调用方走既有建连路径——单线程版的 "lazy connect"，一行网络代码都没跑）。
    std::optional<PooledConnection> checkout(const PoolKey& key);

    // 归还连接（仅 io 线程；同步）：上限（max_idle_per_host）只在 put 执行；插栈顶。
    void put(PoolKey key, IdleEntry entry);

    // 显式排空（Runtime::shutdown / Client 析构时调用）：取消定时器、关闭全部 idle。
    void close_all();

    size_t idle_count() const; // 测试/观测用（仅 io 线程）
    const PoolOptions& options() const noexcept { return opts_; }

private:
    void ensure_sweeper(); // 首次 put 插入后启动（懒创建、至多一个）
    void schedule_sweep(const std::shared_ptr<boost::asio::steady_timer>& timer);
    void sweep();          // 淘汰死连接/过期连接；map 全空 → 停表（sweeper_.reset()）
    static bool is_alive(const AnyStream& s);
    // 线程契约（§3.11）：池无锁，只允许 io 线程访问；debug 构建用 assert 守约。
    // 注意：构造线程 ≠ io 线程（绑定层 Client 可在主线程构造、io 由 JS 线程
    // 驱动），故以**首次访问线程**作为 io 线程身份记录（原子 CAS，并发首次
    // 访问安全）。
    void assert_io_thread() const;

    boost::asio::io_context& io_;
    PoolOptions opts_;
    std::unordered_map<PoolKey, std::vector<IdleEntry>, PoolKeyHash> idle_; // vector 当栈 = LIFO
    std::shared_ptr<boost::asio::steady_timer> sweeper_; // 存在即在跑
    mutable std::atomic<std::thread::id> io_thread_{}; // 首次访问线程（= io 线程）；空 id = 未记录
};

} // namespace fetch
