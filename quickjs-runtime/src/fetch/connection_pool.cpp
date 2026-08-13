// fetchcore —— ConnectionPool 实现（docs/fetch_connection_pool_design.md §3.4-3.6）
#include <fetch/connection_pool.hpp>

#include <boost/asio/steady_timer.hpp>

#include <algorithm>
#include <cassert>
#include <chrono>
#include <utility>

#ifndef _WIN32
#include <cerrno>
#include <sys/socket.h>
#include <sys/types.h>
#endif

namespace fetch {
namespace {

// 关闭连接（尽力而为）：TLS 不费心做 async_shutdown，直接 lowest-layer close
//（设计文档 §3.4；服务端 close_notify 不必等待，重试兜底）。
void close_stream(AnyStream& s)
{
    std::visit([](auto& st) {
        boost::system::error_code ec;
        st.lowest_layer().shutdown(boost::asio::ip::tcp::socket::shutdown_both, ec);
        st.lowest_layer().close(ec);
    }, s);
}

bool stream_open(const AnyStream& s)
{
    return std::visit([](const auto& st) { return st.lowest_layer().is_open(); }, s);
}

#ifndef _WIN32
// plain TCP 一次性 MSG_PEEK 探测（设计文档 §3.4）：只清掉"TCP 层已可见的死连接"。
// Windows（Winsock 无 MSG_DONTWAIT 语义）首版不探测，靠复用重试兜底（§7-1）。
bool probe_plain(const PlainStream& sock)
{
    char c;
    const ssize_t r = ::recv(sock.native_handle(), &c, 1, MSG_PEEK | MSG_DONTWAIT);
    if (r == 0)
        return false; // 对端 FIN：连接已死
    if (r > 0)
        return false; // 空闲明文连接上出现字节几乎必然是异常（对端乱发/代理
                      // 污染），复用后会被当响应头解析出错 → 判死丢弃
    const int e = errno;
    if (e == ECONNRESET)
        return false;
    // EAGAIN/EWOULDBLOCK（无数据）等 → 视为存活（探测只是 hint，正确性靠重试）
    return true;
}
#endif

} // namespace

void PooledConnection::put_back()
{
    if (!entry_)
        return;
    if (!discard_) {
        if (auto pool = pool_.lock())
            pool->put(std::move(key_), std::move(*entry_));
    }
    entry_.reset(); // 池销毁/discard：连接随 IdleEntry 析构关闭
}

ConnectionPool::ConnectionPool(boost::asio::io_context& io, PoolOptions opts)
    : io_(io), opts_(std::move(opts))
{
}

ConnectionPool::~ConnectionPool()
{
    // 线程契约（§3.11）：io 仍在运行期间，池的最后引用必须在 io 线程释放
    //（timer/idle socket 析构与 io_context 轮询并发即数据竞争）；io 已停止
    // 后任意线程释放均安全（无并发轮询），不做断言。
    if (!io_.stopped())
        assert_io_thread();
    if (sweeper_)
        sweeper_->cancel(); // handler 只弱捕获 timer，cancel 才能拦下挂起等待
    sweeper_.reset();
    idle_.clear(); // IdleEntry 析构关闭全部 idle 连接
}

void ConnectionPool::assert_io_thread() const
{
    // 线程契约（设计文档 §3.11）：池无锁，仅 io 线程访问；误用只会在 debug
    // 构建暴露（assert），release 构建零开销。io 线程身份取**首次访问线程**
    //（绑定层里 Client 构造线程 ≠ io 驱动线程，构造时无法确定 io 线程）。
    // 原子 CAS 记录：并发首次访问只有一个赢家，消除非原子读写的 UB。
    const auto tid = std::this_thread::get_id();
    std::thread::id expected{}; // 空 id = 未记录
    if (!io_thread_.compare_exchange_strong(expected, tid, std::memory_order_acq_rel))
        assert(expected == tid);
}

std::optional<PooledConnection> ConnectionPool::checkout(const PoolKey& key)
{
    assert_io_thread();
    auto it = idle_.find(key);
    if (it == idle_.end())
        return std::nullopt;
    auto& stack = it->second;
    const auto now = std::chrono::steady_clock::now();
    while (!stack.empty()) {
        // 过期检查：栈内条目按 idle_at 单调有序（追加时间递增），弹到一条过期
        // 即意味着剩下的（更早的）全过期 → 一次性清空（pool.rs:308-313 的 TODO）。
        if (opts_.idle_timeout &&
            (now - stack.back().idle_at) > *opts_.idle_timeout) {
            stack.clear();
            break;
        }
        IdleEntry entry = std::move(stack.back());
        stack.pop_back();
        // 活性检查（分层降级版 is_open()，池.rs:304-307 的惰性发现）
        if (!is_alive(entry.stream)) {
            close_stream(entry.stream); // 丢弃死连接
            continue;
        }
        if (stack.empty())
            idle_.erase(it);
        return PooledConnection(weak_from_this(), key, std::move(entry),
                                /*is_reused=*/true);
    }
    idle_.erase(it); // 栈空（或全过期）
    return std::nullopt;
}

void ConnectionPool::put(PoolKey key, IdleEntry entry)
{
    assert_io_thread();
    if (!stream_open(entry.stream))
        return; // 已死连接不回池（连接随 entry 析构关闭；对应 pool.rs:563-567）
    auto& stack = idle_[std::move(key)];
    if (stack.size() >= opts_.max_idle_per_host)
        return; // 超上限直接丢弃（对应 pool.rs:396-399；上限只在 put 执行）
    entry.idle_at = std::chrono::steady_clock::now();
    stack.push_back(std::move(entry));
    ensure_sweeper();
}

void ConnectionPool::close_all()
{
    assert_io_thread();
    if (sweeper_)
        sweeper_->cancel(); // 拦下挂起等待：否则旧 timer 到期会沿着 idle_ 非空再续一条清扫链
    sweeper_.reset();
    idle_.clear();
}

size_t ConnectionPool::idle_count() const
{
    assert_io_thread();
    size_t n = 0;
    for (const auto& [k, stack] : idle_)
        n += stack.size();
    return n;
}

bool ConnectionPool::is_alive(const AnyStream& s)
{
    if (!stream_open(s))
        return false;
    return std::visit([](const auto& st) -> bool {
        using T = std::decay_t<decltype(st)>;
        if constexpr (std::is_same_v<T, PlainStream>) {
#ifndef _WIN32
            return probe_plain(st);
#else
            return true; // Windows：不探测，靠复用重试兜底（§7-1；写失败与读头
                         // 零字节 EOF 均重试一次，见 pooled_flow）
#endif
        } else {
            // TLS 不做 MSG_PEEK：对端 close_notify 是 TLS 记录层数据，TCP 层
            // 看到的是密文有字节，会误判为存活。死活交给复用重试兜底（§3.4/§3.7；
            // 陈旧连接的"写成功读头 EOF"也重试，见 pooled_flow）。
            return true;
        }
    }, s);
}

void ConnectionPool::ensure_sweeper()
{
    if (sweeper_)
        return;
    auto timer = std::make_shared<boost::asio::steady_timer>(io_);
    sweeper_ = timer;
    schedule_sweep(timer);
}

void ConnectionPool::schedule_sweep(const std::shared_ptr<boost::asio::steady_timer>& timer)
{
    // 周期 = max(idle_timeout / 2, 90ms)（L2：刚清扫完就 idle 的连接原要等近
    // 2× timeout 才被淘汰，减半后回收延迟降到 ~1.5×；清扫本身只是遍历空闲
    // 链表，成本可忽略。90ms 下限照抄 hyper MIN_CHECK，pool.rs:443-448）；
    // idle_timeout == nullopt → 只扫死连接、周期固定 60s（防御性）。
    const auto period = opts_.idle_timeout
                            ? std::max(*opts_.idle_timeout / 2, std::chrono::milliseconds(90))
                            : std::chrono::seconds(60);
    timer->expires_after(period);
    // handler 只弱捕获 timer：强捕获会形成 timer→operation→handler→timer
    // 循环，sweeper_.reset() 无法取消挂起等待（close_all 后旧 timer 到期
    // 还会沿 idle_ 非空续出第二条清扫链）。lock 失败 = 池已放弃此 timer → 链终止。
    timer->async_wait([weak = weak_from_this(),
                       weak_timer = std::weak_ptr(timer)](const boost::system::error_code& ec) {
        if (ec)
            return; // 池销毁/close_all 时定时器被 cancel → 任务退出（对应 oneshot cancel-on-drop）
        auto self = weak.lock();
        if (!self)
            return; // 池已销毁：不 reschedule（Weak 不续命，pool.rs:798-801）
        auto timer = weak_timer.lock();
        if (!timer)
            return; // 池已放弃此定时器（close_all/池空自停）：链终止
        self->sweep();
        if (self->idle_.empty())
            self->sweeper_.reset(); // 池空自停，下次 put 再启动
        else
            self->schedule_sweep(timer);
    });
}

void ConnectionPool::sweep()
{
    assert_io_thread();
    const auto now = std::chrono::steady_clock::now();
    for (auto it = idle_.begin(); it != idle_.end();) {
        auto& stack = it->second;
        stack.erase(std::remove_if(stack.begin(), stack.end(), [&](IdleEntry& e) {
            if (!is_alive(e.stream))
                return true;
            if (opts_.idle_timeout && (now - e.idle_at) > *opts_.idle_timeout)
                return true;
            return false;
        }), stack.end());
        if (stack.empty())
            it = idle_.erase(it);
        else
            ++it;
    }
}

} // namespace fetch
