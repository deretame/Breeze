// DNS 解析器抽象与缓存测试（docs/dns_resolver_design.md §6.6 验收清单）
//
// 覆盖：
//   - 字面 IP 短路（SystemResolver / CachingResolver 均不触网不触上游）
//   - 缓存命中不触上游（fake 计数）+ host 键小写规范化
//   - TTL 过期重解析（max_ttl=0 / 条目真 ttl=0 两条路径）
//   - 负缓存重放（错误码一致、不触上游；negative_ttl=0 立即重解析）
//   - singleflight（并发同 key 只触一次上游，结果共享）
//   - last_good 排序（report_success 后命中条目把它排最前）
//   - H2 回归：resolve 期间 abort 立即返回（fake 挂起 + stop）
//   - H1 回归：首个 endpoint 不可达落到第二个（Client + custom_resolver +
//     本地不可达/可达双地址，走完整 connect_tcp → connect_all 链路）
//
// 驱动方式与 connection_pool_test 相同：counting_scope close+join + poll 循环。
#include <gtest/gtest.h>
#include <fetch/dns_resolver.hpp>
#include <fetch/client.hpp>
#include <fetch/body.hpp> // fetch::read_all
#include <fetch/scheduler.hpp>

#include <boost/asio.hpp>
#include <exec/asio/use_sender.hpp>
#include <stdexec/execution.hpp>

#include <atomic>
#include <chrono>
#include <exception>
#include <functional>
#include <memory>
#include <optional>
#include <stop_token>
#include <string>
#include <thread>
#include <utility>
#include <vector>

namespace {

namespace net = boost::asio;
using fetch::DnsEntry;
using fetch::DnsResult;

// ---- 可控 fake resolver：计数 / 可控挂起 / 可控失败 ----
class FakeResolver : public fetch::DnsResolver {
public:
    explicit FakeResolver(net::io_context& io) : io_(io) {}

    std::atomic<int> calls{0};
    DnsResult result;                            // 成功时返回的结果集
    std::optional<boost::system::error_code> fail; // 非空 → 抛 system_error
    bool hang = false;                           // 挂起直到 release() 或 stop
    std::vector<std::shared_ptr<net::steady_timer>> gates;
    std::atomic<bool> released{false};

    void release()
    {
        released.store(true);
        for (auto& t : gates)
            t->cancel();
        gates.clear();
    }

    std_exec::task<DnsResult> resolve(std::string /*host*/, std::string /*service*/,
                                      std::stop_token st) override
    {
        ++calls;
        if (fail)
            throw boost::system::system_error(*fail, "fake dns failure");
        if (hang && !released.load()) {
            auto timer = std::make_shared<net::steady_timer>(io_);
            timer->expires_at(net::steady_timer::time_point::max());
            gates.push_back(timer);
            std::optional<std::stop_callback<std::function<void()>>> cb;
            if (st.stop_possible())
                cb.emplace(st, [timer] { timer->cancel(); });
            boost::system::error_code ec;
            co_await timer->async_wait(net::redirect_error(exec::asio::use_sender, ec));
            if (st.stop_requested())
                co_await stdexec::just_stopped(); // 取消 → stopped
            // release() 唤醒 → 正常返回
        }
        co_return result;
    }

private:
    net::io_context& io_;
};

// ---- 驱动辅助（同 connection_pool_test 的 ScopeJoiner 模式）----
template <class T>
struct Outcome {
    bool done = false;
    bool stopped = false;
    std::optional<T> value;
    std::exception_ptr error;
};

struct Rig {
    net::io_context io;

    Rig() { fetch::set_thread_io(io); }
    ~Rig() { fetch::clear_thread_io(); }

    // spawn 一个 sender 链到 scope，并驱动 io 直到 scope join
    template <class Sndr>
    void spawn_and(stdexec::counting_scope& scope, Sndr&& sndr)
    {
        stdexec::spawn(static_cast<Sndr&&>(sndr), scope.get_token(),
                       stdexec::prop{stdexec::get_start_scheduler,
                                     fetch::io_scheduler{io}});
    }

    void join(stdexec::counting_scope& scope)
    {
        scope.close();
        bool joined = false;
        struct Rcvr {
            bool* joined;
            net::io_context* io;
            using receiver_concept = stdexec::receiver_t;
            void set_value() noexcept { *joined = true; }
            void set_error(std::exception_ptr) noexcept { *joined = true; }
            void set_stopped() noexcept { *joined = true; }
            auto get_env() const noexcept
            {
                return stdexec::prop{stdexec::get_start_scheduler,
                                     fetch::io_scheduler{*io}};
            }
        };
        auto op = stdexec::connect(scope.join(), Rcvr{&joined, &io});
        stdexec::start(op);
        for (int i = 0; !joined && i < 20000; ++i) {
            io.poll();
            if (!joined)
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        ASSERT_TRUE(joined) << "scope join 超时";
    }

    // 跑单个 task 并收集结果/异常/stopped
    template <class T>
    Outcome<T> run(std_exec::task<T> work)
    {
        auto out = std::make_shared<Outcome<T>>();
        stdexec::counting_scope scope;
        spawn_and(scope,
                  std::move(work)
                      | stdexec::then([out](T v) mutable noexcept {
                            out->value = std::move(v);
                            out->done = true;
                        })
                      | stdexec::upon_error([out](std::exception_ptr ep) mutable noexcept {
                            out->error = std::move(ep);
                            out->done = true;
                        })
                      | stdexec::upon_stopped([out]() mutable noexcept {
                            out->stopped = true;
                            out->done = true;
                        }));
        join(scope);
        return std::move(*out);
    }

    // 驱动 io 直到条件满足（或超轮次）
    bool pump_until(const std::function<bool()>& pred, int rounds = 20000)
    {
        for (int i = 0; i < rounds && !pred(); ++i) {
            io.poll();
            if (!pred())
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        return pred();
    }
};

DnsResult two_addrs()
{
    return DnsResult{{net::ip::make_address("10.0.0.1"), std::nullopt},
                     {net::ip::make_address("10.0.0.2"), std::nullopt}};
}

// ---- 字面 IP 短路 ----

TEST(DnsResolver, SystemResolverLiteralShortCircuit)
{
    Rig rig;
    fetch::SystemResolver r(rig.io);
    auto out = rig.run(r.resolve("127.0.0.1", "80", {}));
    ASSERT_TRUE(out.value.has_value());
    ASSERT_EQ(out.value->size(), 1u);
    EXPECT_EQ(out.value->front().addr, net::ip::make_address("127.0.0.1"));
    EXPECT_FALSE(out.value->front().ttl.has_value());

    // IPv6 字面量（含 URL 形态的方括号）同样短路
    auto out6 = rig.run(r.resolve("[::1]", "443", {}));
    ASSERT_TRUE(out6.value.has_value());
    ASSERT_EQ(out6.value->size(), 1u);
    EXPECT_EQ(out6.value->front().addr, net::ip::make_address("::1"));
}

TEST(DnsResolver, CachingLiteralSkipsUpstream)
{
    Rig rig;
    auto fake = std::make_shared<FakeResolver>(rig.io);
    fake->result = two_addrs();
    fetch::CachingResolver r(rig.io, fake);
    auto out = rig.run(r.resolve("8.8.8.8", "80", {}));
    ASSERT_TRUE(out.value.has_value());
    ASSERT_EQ(out.value->size(), 1u);
    EXPECT_EQ(out.value->front().addr, net::ip::make_address("8.8.8.8"));
    EXPECT_EQ(fake->calls.load(), 0); // 不触上游
}

// ---- 缓存命中 + host 小写规范化 ----

TEST(DnsResolver, CacheHitSkipsUpstream)
{
    Rig rig;
    auto fake = std::make_shared<FakeResolver>(rig.io);
    fake->result = two_addrs();
    fetch::CachingResolver r(rig.io, fake);

    auto out1 = rig.run(r.resolve("Example.TEST", "80", {}));
    ASSERT_TRUE(out1.value.has_value());
    EXPECT_EQ(out1.value->size(), 2u);
    EXPECT_EQ(fake->calls.load(), 1);

    // 大小写不同 = 同一缓存键；命中不触上游
    auto out2 = rig.run(r.resolve("example.test", "80", {}));
    ASSERT_TRUE(out2.value.has_value());
    EXPECT_EQ(*out2.value, *out1.value);
    EXPECT_EQ(fake->calls.load(), 1);
}

// ---- TTL 过期重解析 ----

TEST(DnsResolver, TtlExpiryReResolves)
{
    Rig rig;
    auto fake = std::make_shared<FakeResolver>(rig.io);
    fake->result = two_addrs();
    fetch::DnsCacheOptions opt;
    opt.max_ttl = std::chrono::seconds(0); // 立即过期
    fetch::CachingResolver r(rig.io, fake, opt);

    ASSERT_TRUE(rig.run(r.resolve("a.test", "80", {})).value.has_value());
    ASSERT_TRUE(rig.run(r.resolve("a.test", "80", {})).value.has_value());
    EXPECT_EQ(fake->calls.load(), 2);
}

TEST(DnsResolver, EntryRealTtlClampsExpiry)
{
    Rig rig;
    auto fake = std::make_shared<FakeResolver>(rig.io);
    // 条目带真 TTL=0（DoH 预留路径）：即使 max_ttl=60 也按 min(ttl, max_ttl) 立即过期
    fake->result = DnsResult{{net::ip::make_address("10.0.0.1"), std::chrono::seconds(0)}};
    fetch::CachingResolver r(rig.io, fake); // 默认 max_ttl=60

    ASSERT_TRUE(rig.run(r.resolve("a.test", "80", {})).value.has_value());
    ASSERT_TRUE(rig.run(r.resolve("a.test", "80", {})).value.has_value());
    EXPECT_EQ(fake->calls.load(), 2);
}

// ---- 负缓存 ----

TEST(DnsResolver, NegativeCacheReplaysError)
{
    Rig rig;
    auto fake = std::make_shared<FakeResolver>(rig.io);
    fake->fail = net::error::make_error_code(net::error::host_not_found);
    fetch::CachingResolver r(rig.io, fake);

    auto out1 = rig.run(r.resolve("gone.test", "80", {}));
    ASSERT_TRUE(out1.error != nullptr);
    auto out2 = rig.run(r.resolve("gone.test", "80", {}));
    ASSERT_TRUE(out2.error != nullptr);
    EXPECT_EQ(fake->calls.load(), 1); // 负缓存期间不触上游

    // 重放的是错误码而非异常对象：两次错误的 code 一致
    auto code_of = [](std::exception_ptr ep) {
        try {
            std::rethrow_exception(ep);
        } catch (const boost::system::system_error& e) {
            return e.code();
        }
        return boost::system::error_code{};
    };
    EXPECT_EQ(code_of(out1.error), net::error::make_error_code(net::error::host_not_found));
    EXPECT_EQ(code_of(out2.error), code_of(out1.error));
}

TEST(DnsResolver, NegativeCacheExpiryReResolves)
{
    Rig rig;
    auto fake = std::make_shared<FakeResolver>(rig.io);
    fake->fail = net::error::make_error_code(net::error::host_not_found);
    fetch::DnsCacheOptions opt;
    opt.negative_ttl = std::chrono::seconds(0); // 立即过期
    fetch::CachingResolver r(rig.io, fake, opt);

    EXPECT_TRUE(rig.run(r.resolve("gone.test", "80", {})).error != nullptr);
    EXPECT_TRUE(rig.run(r.resolve("gone.test", "80", {})).error != nullptr);
    EXPECT_EQ(fake->calls.load(), 2);
}

// ---- singleflight：并发同 key 只触一次上游 ----

TEST(DnsResolver, SingleflightSharesInFlightResolve)
{
    Rig rig;
    auto fake = std::make_shared<FakeResolver>(rig.io);
    fake->hang = true;
    fake->result = two_addrs();
    fetch::CachingResolver r(rig.io, fake);

    auto out1 = std::make_shared<Outcome<DnsResult>>();
    auto out2 = std::make_shared<Outcome<DnsResult>>();
    stdexec::counting_scope scope;
    auto arm = [&](std::shared_ptr<Outcome<DnsResult>> out) {
        rig.spawn_and(scope,
                      r.resolve("hot.test", "80", {})
                          | stdexec::then([out](DnsResult v) mutable noexcept {
                                out->value = std::move(v);
                                out->done = true;
                            })
                          | stdexec::upon_error([out](std::exception_ptr ep) mutable noexcept {
                                out->error = std::move(ep);
                                out->done = true;
                            })
                          | stdexec::upon_stopped([out]() mutable noexcept {
                                out->stopped = true;
                                out->done = true;
                            }));
    };
    arm(out1);
    arm(out2);
    // 等 leader 进入 fake（挂起）且 waiter 挂上
    ASSERT_TRUE(rig.pump_until([&] { return fake->calls.load() == 1; }));
    rig.io.poll();
    fake->release();
    rig.join(scope);

    EXPECT_EQ(fake->calls.load(), 1); // 只触一次上游
    ASSERT_TRUE(out1->value.has_value());
    ASSERT_TRUE(out2->value.has_value());
    EXPECT_EQ(*out1->value, *out2->value); // 共享同一份结果
}

// ---- last_good 排序（§3.3）----

TEST(DnsResolver, LastGoodSortsFirstOnHit)
{
    Rig rig;
    auto fake = std::make_shared<FakeResolver>(rig.io);
    fake->result = two_addrs();
    fetch::CachingResolver r(rig.io, fake);

    auto out1 = rig.run(r.resolve("lg.test", "80", {}));
    ASSERT_TRUE(out1.value.has_value());
    EXPECT_EQ(out1.value->front().addr, net::ip::make_address("10.0.0.1"));

    // 连接层回报"10.0.0.2 连上了" → 缓存命中时它排最前
    r.report_success("lg.test", "80", net::ip::make_address("10.0.0.2"));
    auto out2 = rig.run(r.resolve("lg.test", "80", {}));
    ASSERT_TRUE(out2.value.has_value());
    EXPECT_EQ(out2.value->front().addr, net::ip::make_address("10.0.0.2"));
    EXPECT_EQ(out2.value->size(), 2u);
    EXPECT_EQ(fake->calls.load(), 1); // 仍只是缓存命中
}

// ---- H2 回归：resolve 期间 abort 立即返回 ----

TEST(DnsResolver, AbortDuringResolveReturnsStopped)
{
    Rig rig;
    auto fake = std::make_shared<FakeResolver>(rig.io);
    fake->hang = true; // 永不自行完成（不 release）
    fetch::CachingResolver r(rig.io, fake);

    auto out = std::make_shared<Outcome<DnsResult>>();
    stdexec::counting_scope scope;
    std::stop_source src;
    rig.spawn_and(scope,
                  r.resolve("hang.test", "80", src.get_token())
                      | stdexec::then([out](DnsResult v) mutable noexcept {
                            out->value = std::move(v);
                            out->done = true;
                        })
                      | stdexec::upon_error([out](std::exception_ptr ep) mutable noexcept {
                            out->error = std::move(ep);
                            out->done = true;
                        })
                      | stdexec::upon_stopped([out]() mutable noexcept {
                            out->stopped = true;
                            out->done = true;
                        }));
    ASSERT_TRUE(rig.pump_until([&] { return fake->calls.load() == 1; }));
    src.request_stop(); // resolve 进行中取消
    rig.join(scope);    // 若取消空洞存在，这里会卡到 join 超时（ASSERT 在 join 内）
    EXPECT_TRUE(out->stopped);
    EXPECT_FALSE(out->value.has_value());
}

// ---- H1 回归：首个 endpoint 不可达 → 落到第二个（端到端走 Client）----

// 一次性 HTTP server：accept 后读请求头、回固定 200 响应即关
class OneShotServer {
public:
    explicit OneShotServer(net::io_context& io)
        : acceptor_(io, net::ip::tcp::endpoint(net::ip::make_address("127.0.0.1"), 0))
    {
        do_accept();
    }
    uint16_t port() const { return acceptor_.local_endpoint().port(); }

private:
    void do_accept()
    {
        acceptor_.async_accept([this](boost::system::error_code ec, net::ip::tcp::socket s) {
            if (ec)
                return;
            auto sock = std::make_shared<net::ip::tcp::socket>(std::move(s));
            auto buf = std::make_shared<net::streambuf>();
            net::async_read_until(*sock, *buf, "\r\n\r\n",
                                  [sock, buf](boost::system::error_code, size_t) {
                                      static const char kResp[] =
                                          "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n"
                                          "Connection: close\r\n\r\nok";
                                      net::async_write(*sock, net::buffer(kResp, sizeof(kResp) - 1),
                                                       [sock](boost::system::error_code, size_t) {});
                                  });
            do_accept(); // 继续接受（重试路径可能再连）
        });
    }
    net::ip::tcp::acceptor acceptor_;
};

TEST(DnsResolver, FirstEndpointUnreachableFallsThrough)
{
    Rig rig;
    OneShotServer server(rig.io);

    // custom_resolver：把 "h1.test" 解析为 [不可达, 127.0.0.1]，验证连接层
    // 循环尝试所有 endpoint（H1）+ Options::dns.custom_resolver 接线（§5）
    auto fake = std::make_shared<FakeResolver>(rig.io);
    fake->result = DnsResult{{net::ip::make_address("127.0.0.2"), std::nullopt},
                             {net::ip::make_address("127.0.0.1"), std::nullopt}};
    fetch::Options opt;
    opt.dns.custom_resolver = fake;

    fetch::Client client(std::move(opt)); // 在 Rig 的 io 线程上构造
    auto out = rig.run([&]() -> std_exec::task<int> {
        fetch::Request req;
        req.url = "http://h1.test:" + std::to_string(server.port()) + "/";
        auto resp = co_await client.fetch(std::move(req), {});
        if (resp.body) {
            const std::string drained = co_await fetch::read_all(resp);
            EXPECT_EQ(drained, "ok");
        }
        co_return resp.status;
    }());
    ASSERT_TRUE(out.value.has_value()) << [&] {
        if (!out.error)
            return std::string("stopped");
        try {
            std::rethrow_exception(out.error);
        } catch (const std::exception& e) {
            return std::string(e.what());
        }
    }();
    EXPECT_EQ(*out.value, 200);
    EXPECT_EQ(fake->calls.load(), 1);
}

} // namespace
