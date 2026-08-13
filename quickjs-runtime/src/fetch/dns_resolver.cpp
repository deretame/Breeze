// fetchcore —— DNS 解析器实现（docs/dns_resolver_design.md §2.2/§2.3/§3）
//
//   - SystemResolver：现状三处裸调 async_resolve 的搬家 + H2 修复
//    （stop_callback 持 resolver 并 cancel）+ 字面 IP 短路。
//   - CachingResolver：LRU + TTL + 负缓存 + singleflight + last_good 排序；
//     仅 io 线程访问（与 ConnectionPool 同一契约），免锁，debug 构建 assert 守约。
#include <fetch/dns_resolver.hpp>

#include <boost/asio.hpp>
#include <exec/asio/use_sender.hpp>
#include <stdexec/execution.hpp>

#include <algorithm>
#include <atomic>
#include <cassert>
#include <cctype>
#include <functional>
#include <list>
#include <optional>
#include <stop_token>
#include <thread>
#include <unordered_map>
#include <utility>

namespace fetch {
namespace {

namespace net = boost::asio;

// IPv6 字面量经 URL 解析后带方括号（"[::1]"）；make_address 不认括号，先剥离
std::string_view strip_brackets(std::string_view host)
{
    if (host.size() >= 2 && host.front() == '[' && host.back() == ']')
        return host.substr(1, host.size() - 2);
    return host;
}

// host 键小写规范化（DNS 大小写不敏感）
std::string lower_host(std::string_view host)
{
    std::string out(strip_brackets(host));
    std::transform(out.begin(), out.end(), out.begin(),
                   [](unsigned char c) { return static_cast<char>(std::tolower(c)); });
    return out;
}

} // namespace

// ---- SystemResolver（§2.2）----

std_exec::task<DnsResult> SystemResolver::resolve(std::string host, std::string service,
                                                  std::stop_token st)
{
    // 字面 IP 短路（§3.1）：不发起任何网络查询
    boost::system::error_code ec;
    if (auto addr = net::ip::make_address(strip_brackets(host), ec); !ec)
        co_return DnsResult{{std::move(addr), std::nullopt}};
    // resolver 以 shared_ptr 持有：stop_callback 在 resolve 阶段也要能 cancel
    // resolver（否则 resolve 期间的 stop 阻塞至 DNS 超时，review H2）。
    // cancel → operation_aborted → use_sender 转 set_stopped → 绑定层 AbortError。
    auto resolver = std::make_shared<net::ip::tcp::resolver>(io_);
    std::optional<std::stop_callback<std::function<void()>>> stop_cb;
    if (st.stop_possible())
        stop_cb.emplace(st, [resolver] { resolver->cancel(); });
    const auto results = co_await resolver->async_resolve(host, service,
                                                          exec::asio::use_sender);
    DnsResult out;
    out.reserve(results.size());
    for (const auto& r : results)
        out.push_back({r.endpoint().address(), std::nullopt});
    co_return out;
}

// ---- CachingResolver（§2.3/§3）----

struct CachingResolver::Impl {
    enum class State { Ready, Pending, Negative };

    // singleflight 共享状态：等待者把自己的唤醒 timer 弱登记进来，首个完成的
    // 协程（leader）逐个 cancel 唤醒；等待者醒后重查缓存拿共享结果。
    struct PendingState {
        std::vector<std::weak_ptr<net::steady_timer>> waiters;
    };

    struct Entry {
        State state;
        DnsResult result;                                // Ready
        boost::system::error_code error;                 // Negative（缓存错误码
        std::string error_what;                          //   重放，不缓存异常对象）
        std::chrono::steady_clock::time_point expires;   // Ready/Negative
        std::optional<net::ip::address> last_good;       // Ready：上次连上的地址
        std::shared_ptr<PendingState> pending;           // Pending
    };

    net::io_context& io;
    std::shared_ptr<DnsResolver> upstream;
    DnsCacheOptions opt;

    Impl(net::io_context& io_, std::shared_ptr<DnsResolver> up, DnsCacheOptions o)
        : io(io_), upstream(std::move(up)), opt(std::move(o))
    {
    }

    // LRU：头 = 最久未用；命中 splice 到尾部（同 TlsSessionCacheImpl 形态）
    std::list<std::pair<std::string, Entry>> lru;
    std::unordered_map<std::string,
                       std::list<std::pair<std::string, Entry>>::iterator>
        index;

    // 线程契约（同 ConnectionPool::assert_io_thread）：缓存无锁，仅 io 线程
    // 访问；io 线程身份取首次访问线程（原子 CAS 记录，消除 UB）。
    std::atomic<std::thread::id> io_thread{};
    void assert_io_thread()
    {
        const auto tid = std::this_thread::get_id();
        std::thread::id expected{}; // 空 id = 未记录
        if (!io_thread.compare_exchange_strong(expected, tid, std::memory_order_acq_rel))
            assert(expected == tid);
    }

    static std::string key_of(std::string_view lhost, std::string_view service)
    {
        // service 进键（§2.3）：同一域名不同端口结果集相同，但保守进键不损失什么
        std::string key(lhost);
        key.push_back('\x1f');
        key += service;
        return key;
    }

    // last_good 排序（§3.3）：上次连接成功的地址仍在列表中 → 排最前
    static DnsResult ordered(const DnsResult& result,
                             const std::optional<net::ip::address>& last_good)
    {
        if (!last_good)
            return result;
        DnsResult out = result;
        std::stable_partition(out.begin(), out.end(),
                              [&](const DnsEntry& e) { return e.addr == *last_good; });
        return out;
    }

    void wake(const std::shared_ptr<PendingState>& state)
    {
        for (auto& w : state->waiters)
            if (auto t = w.lock())
                t->cancel();
        state->waiters.clear();
    }

    void erase(std::unordered_map<std::string,
                                  std::list<std::pair<std::string, Entry>>::iterator>::iterator it)
    {
        lru.erase(it->second);
        index.erase(it);
    }

    // 容量上限：从头淘汰最久未用；Pending 条目不淘汰（等待者还挂在上面，
    // 极端情况下宁可短暂超限）
    void evict_if_needed()
    {
        while (lru.size() > opt.capacity && lru.front().second.state != State::Pending) {
            index.erase(lru.front().first);
            lru.pop_front();
        }
    }
};

CachingResolver::CachingResolver(net::io_context& io,
                                 std::shared_ptr<DnsResolver> upstream,
                                 DnsCacheOptions opt)
    : impl_(std::make_unique<Impl>(io, std::move(upstream), std::move(opt)))
{
}

CachingResolver::~CachingResolver()
{
    // 与池同一契约：io 仍在运行期间最后引用须在 io 线程释放
    if (!impl_->io.stopped())
        impl_->assert_io_thread();
}

void CachingResolver::report_success(std::string_view host, std::string_view service,
                                     const net::ip::address& addr)
{
    impl_->assert_io_thread();
    const std::string key = Impl::key_of(lower_host(host), service);
    auto it = impl_->index.find(key);
    if (it != impl_->index.end() && it->second->second.state == Impl::State::Ready)
        it->second->second.last_good = addr;
}

std_exec::task<DnsResult> CachingResolver::resolve(std::string host,
                                                   std::string service,
                                                   std::stop_token st)
{
    auto& impl = *impl_; // 调用方持有 shared_ptr<DnsResolver>，生命周期随协程
    // 字面 IP 短路（§3.1）：不进缓存、不触上游（代理配置常写 IP，避免一次性
    // 条目污染缓存）
    boost::system::error_code ec;
    if (auto addr = net::ip::make_address(strip_brackets(host), ec); !ec)
        co_return DnsResult{{std::move(addr), std::nullopt}};

    impl.assert_io_thread();
    const std::string lhost = lower_host(host);
    const std::string key = Impl::key_of(lhost, service);

    for (;;) {
        const auto now = std::chrono::steady_clock::now();
        std::optional<net::ip::address> carry_good; // 过期 Ready 的 last_good 沿用
        if (auto it = impl.index.find(key); it != impl.index.end()) {
            Impl::Entry& entry = it->second->second;
            switch (entry.state) {
            case Impl::State::Ready:
                if (now < entry.expires) {
                    impl.lru.splice(impl.lru.end(), impl.lru, it->second);
                    co_return Impl::ordered(entry.result, entry.last_good);
                }
                carry_good = entry.last_good; // 陈旧也沿用 last_good（§3.3）
                impl.erase(it);
                break;
            case Impl::State::Negative:
                if (now < entry.expires) {
                    impl.lru.splice(impl.lru.end(), impl.lru, it->second);
                    throw boost::system::system_error(entry.error, entry.error_what);
                }
                impl.erase(it);
                break;
            case Impl::State::Pending: {
                // singleflight（§3.4）：解析进行中，挂起等待首个完成并共享结果。
                // 等待载体 = 一个永不过期的 steady_timer：leader 完成时 cancel 唤醒；
                // 自身取消经 stop_callback cancel 同一 timer（醒后按 stopped 传播）。
                auto state = entry.pending;
                auto timer = std::make_shared<net::steady_timer>(impl.io);
                timer->expires_at(net::steady_timer::time_point::max());
                state->waiters.push_back(timer);
                std::optional<std::stop_callback<std::function<void()>>> cb;
                if (st.stop_possible())
                    cb.emplace(st, [timer] { timer->cancel(); });
                boost::system::error_code wec;
                co_await timer->async_wait(net::redirect_error(exec::asio::use_sender, wec));
                if (st.stop_requested())
                    co_await stdexec::just_stopped(); // 用户取消 → stopped
                continue; // 醒来重查：Ready/Negative/leader 被取消后条目摘除
            }
            }
        }

        // 成为 leader：登记 Pending 后请求上游；stopped_as_optional 把 stopped
        // 收敛为 nullopt，使取消路径也能善后（摘除 Pending + 唤醒等待者）。
        auto state = std::make_shared<Impl::PendingState>();
        Impl::Entry pending;
        pending.state = Impl::State::Pending;
        pending.pending = state;
        impl.lru.emplace_back(key, std::move(pending));
        auto lit = std::prev(impl.lru.end());
        impl.index.emplace(key, lit);
        impl.evict_if_needed();

        std::optional<DnsResult> res;
        try {
            res = co_await stdexec::stopped_as_optional(
                impl.upstream->resolve(lhost, service, st));
        } catch (const boost::system::system_error& e) {
            // 负缓存（§3.2）：缓存错误码 + 描述重放，不缓存异常对象
            lit->second.state = Impl::State::Negative;
            lit->second.pending.reset();
            lit->second.error = e.code();
            lit->second.error_what = e.what();
            lit->second.expires = std::chrono::steady_clock::now() + impl.opt.negative_ttl;
            impl.wake(state);
            throw;
        } catch (const std::exception& e) {
            // 非 system_error 也进负缓存：包一层错误码（异常对象不跨协程复用）
            lit->second.state = Impl::State::Negative;
            lit->second.pending.reset();
            lit->second.error = boost::system::errc::make_error_code(
                boost::system::errc::io_error);
            lit->second.error_what = e.what();
            lit->second.expires = std::chrono::steady_clock::now() + impl.opt.negative_ttl;
            impl.wake(state);
            throw;
        }

        if (!res) {
            // leader 被取消：摘除 Pending（醒来的等待者重查不命中，其中之一成为
            // 新 leader），传播 stopped
            impl.index.erase(key);
            impl.lru.erase(lit);
            impl.wake(state);
            co_await stdexec::just_stopped();
        }

        // §3.2 TTL：条目有真 TTL（未来 DoH）→ min(ttl, max_ttl)；无 → max_ttl。
        // 整个结果集取最保守（最小）值。
        auto effective = impl.opt.max_ttl;
        for (const auto& e : *res)
            effective = std::min(effective, e.ttl.value_or(impl.opt.max_ttl));
        lit->second.state = Impl::State::Ready;
        lit->second.pending.reset();
        lit->second.result = *res;
        lit->second.last_good = carry_good;
        lit->second.expires = std::chrono::steady_clock::now() + effective;
        impl.wake(state);
        co_return Impl::ordered(*res, carry_good);
    }
}

} // namespace fetch
