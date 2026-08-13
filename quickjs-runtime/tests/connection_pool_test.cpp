// 连接池测试（docs/fetch_connection_pool_design.md §6 验收标尺）
//
// 覆盖关键用例：
//   - 复用/新建辨识（X-Conn-Id：同 host 复用、异端口新建、body 读一半丢弃不回池、
//     HEAD 无 body 回池、Connection: close 不回池）
//   - 陈旧连接自动重试（close-after.py 服务端写完即断；复用失败 → 重试一次）
//   - 流式上传复用失败不重试；fresh 连接失败不重试（错误上抛）
//   - body 阶段取消 → 连接关闭不回池
//   - 池状态（直接注入 ConnectionPool 断言 idle_count）：回池计数、max_idle_per_host
//     上限、LIFO 顺序、idle_timeout 清扫、close_all 后仍可用
//   - TLS 连接复用（tls_echo_server keep-alive 循环 + 连接序号钩子）
//   - easy 层默认池化 / pool_max_idle_per_host(0) 禁用池
//
// 驱动方式与 fetchcore_test 相同：counting_scope close+join + poll 循环
//（ScopeJoiner），见 stdexec [exec.simple.counting]。
#include <gtest/gtest.h>
#include <log.hpp>
#include <fetch/client.hpp>
#include <fetch/body.hpp>
#include <fetch/connection_pool.hpp>
#include <fetch/beast_transport.hpp>
#include <fetch/scheduler.hpp>
#include <fetch/easy.hpp>
#include "wpt_server.hpp"
#include "tls_echo_server.hpp"

#include <stdexec/execution.hpp>
#include <exec/asio/use_sender.hpp>

#include <chrono>
#include <exception>
#include <fstream>
#include <functional>
#include <iterator>
#include <memory>
#include <string>
#include <utility>

#include <atomic>
#include <thread>

namespace {

namespace wpt = qjsbind::net::wpt;

// ---- 驱动辅助（同 fetchcore_test）：counting_scope 的 join 驱动 ----
struct ScopeJoiner {
    struct JoinRcvr {
        bool* joined;
        boost::asio::io_context* io;
        using receiver_concept = stdexec::receiver_t;
        void set_value() noexcept { *joined = true; }
        void set_error(std::exception_ptr) noexcept { *joined = true; }
        void set_stopped() noexcept { *joined = true; }
        auto get_env() const noexcept
        {
            return stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{*io}};
        }
    };

    static bool run(stdexec::counting_scope& scope, boost::asio::io_context& io)
    {
        scope.close();
        bool joined = false;
        auto join_op = stdexec::connect(scope.join(), JoinRcvr{&joined, &io});
        stdexec::start(join_op);
        for (int i = 0; !joined && i < 20000; ++i) {
            io.poll();
            if (!joined)
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
        }
        if (!joined)
            QLOG_WARNING("[connection_pool] warning: scope join 超时（20000 轮 poll）");
        return joined;
    }
};

// 标准 Probe：fetch::Client 默认构造（= PooledTransport，默认池配置）
struct Probe {
    boost::asio::io_context io;
    fetch::Client client;
    bool done = false;
    bool stopped = false;
    std::exception_ptr error;

    explicit Probe(fetch::Options opt = {}) : client(build(io, std::move(opt))) {}

private:
    // 成员初始化顺序：io 先于 client 构造；set_thread_io 必须在 client 构造前
    static fetch::Client build(boost::asio::io_context& ioc, fetch::Options opt)
    {
        fetch::set_thread_io(ioc); // 本测试线程的 fetch io 来源（thread_local）
        return fetch::Client(std::move(opt));
    }

public:
    void run(std_exec::task<void> work)
    {
        stdexec::counting_scope scope;
        stdexec::spawn(
            std::move(work)
                | stdexec::then([this]() noexcept { done = true; })
                | stdexec::upon_error([this](std::exception_ptr ep) noexcept {
                      error = std::move(ep);
                      done = true;
                  })
                | stdexec::upon_stopped([this]() noexcept {
                      stopped = true;
                      done = true;
                  }),
            scope.get_token(),
            stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{io}});
        (void)ScopeJoiner::run(scope, io);
    }

    std::string error_message() const
    {
        if (!error)
            return {};
        try {
            std::rethrow_exception(error);
        } catch (const std::exception& e) {
            return e.what();
        }
    }
};

// 池状态 Probe：直接注入 ConnectionPool + BeastTransport（可断言 idle_count）
struct PoolProbe {
    boost::asio::io_context io;
    std::shared_ptr<fetch::ConnectionPool> pool;
    fetch::Client client;
    bool done = false;
    std::exception_ptr error;

    explicit PoolProbe(fetch::PoolOptions popts)
        : pool(std::make_shared<fetch::ConnectionPool>(io, std::move(popts))),
          client(build(io, pool))
    {
    }

private:
    static fetch::Client build(boost::asio::io_context& ioc,
                               std::shared_ptr<fetch::ConnectionPool> p)
    {
        fetch::set_thread_io(ioc);
        auto transport = std::make_shared<fetch::BeastTransport>(fetch::TlsOptions{},
                                                                 std::move(p));
        return fetch::Client{std::move(transport)};
    }

public:
    void run(std_exec::task<void> work)
    {
        stdexec::counting_scope scope;
        stdexec::spawn(
            std::move(work)
                | stdexec::then([this]() noexcept { done = true; })
                | stdexec::upon_error([this](std::exception_ptr ep) noexcept {
                      error = std::move(ep);
                      done = true;
                  })
                | stdexec::upon_stopped([this]() noexcept { done = true; }),
            scope.get_token(),
            stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{io}});
        (void)ScopeJoiner::run(scope, io);
    }

    std::string error_message() const
    {
        if (!error)
            return {};
        try {
            std::rethrow_exception(error);
        } catch (const std::exception& e) {
            return e.what();
        }
    }
};

// easy 层 Probe（同 fetch_easy_test）
struct EasyProbe {
    boost::asio::io_context io;
    fetch::easy::Client client;
    bool done = false;
    std::exception_ptr error;

    explicit EasyProbe(std::function<void(fetch::easy::ClientBuilder&)> cfg = {})
        : client(build(io, std::move(cfg)))
    {
    }

private:
    static fetch::easy::Client build(
        boost::asio::io_context& ioc, std::function<void(fetch::easy::ClientBuilder&)> cfg)
    {
        fetch::set_thread_io(ioc);
        fetch::easy::ClientBuilder b = fetch::easy::Client::builder();
        if (cfg)
            cfg(b);
        return b.build();
    }

public:
    void run(std_exec::task<void> work)
    {
        stdexec::counting_scope scope;
        stdexec::spawn(
            std::move(work)
                | stdexec::then([this]() noexcept { done = true; })
                | stdexec::upon_error([this](std::exception_ptr ep) noexcept {
                      error = std::move(ep);
                      done = true;
                  })
                | stdexec::upon_stopped([this]() noexcept { done = true; }),
            scope.get_token(),
            stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{io}});
        (void)ScopeJoiner::run(scope, io);
    }

    std::string error_message() const
    {
        if (!error)
            return {};
        try {
            std::rethrow_exception(error);
        } catch (const std::exception& e) {
            return e.what();
        }
    }
};

std::string header_of(const fetch::Response& r, const std::string& name)
{
    for (const auto& [k, v] : r.headers)
        if (k == name)
            return v;
    return {};
}

// easy 层的 Response 暴露 fetch::Headers（无 .header() 便捷方法）
std::string easy_header_of(const fetch::easy::Response& r, const std::string& name)
{
    for (const auto& [k, v] : r.headers())
        if (k == name)
            return v;
    return {};
}

// 带连接辨识钩子的 GET（服务端回写 X-Conn-Id）
fetch::Request traced_get(const std::string& url)
{
    fetch::Request r;
    r.url = url;
    r.headers.push_back({"X-Trace-Conn", "1"});
    return r;
}

std::string read_cert_file(const char* name)
{
    for (const char* p : {"tests/certs/", "../tests/certs/", "../../tests/certs/"}) {
        std::ifstream f(std::string(p) + name + ".crt");
        if (f)
            return std::string(std::istreambuf_iterator<char>(f),
                               std::istreambuf_iterator<char>());
    }
    return {};
}

// ==================== 复用/新建辨识 ====================

// 用例 1：顺序请求同 host → 复用同一连接（X-Conn-Id 相同）
TEST(PoolReuse, SequentialSameHostReuses)
{
    wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        auto r1 = co_await p.client.fetch(traced_get(base + "/status.py?code=200&content=one"));
        EXPECT_EQ(r1.status, 200);
        const std::string c1 = header_of(r1, "X-Conn-Id");
        co_await fetch::read_all(r1);
        auto r2 = co_await p.client.fetch(traced_get(base + "/status.py?code=200&content=two"));
        const std::string c2 = header_of(r2, "X-Conn-Id");
        co_await fetch::read_all(r2);
        EXPECT_FALSE(c1.empty()) << "服务端应回写 X-Conn-Id";
        EXPECT_EQ(c1, c2) << "顺序同 host 请求应复用同一连接";
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// 用例 2：不同端口（不同池键）→ 不共享连接。两个服务器各自独立计数
//（X-Conn-Id 跨服务器不可比）：若池键漏了端口维度，请求 2 会复用请求 1
// 的连接（发到 s1 的 socket 上）→ s2 收不到请求 → conn_count 不增长。
TEST(PoolReuse, DifferentPortNewConnection)
{
    wpt::WptTestServer s1("third_party/wpt");
    wpt::WptTestServer s2("third_party/wpt");
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        auto r1 = co_await p.client.fetch(traced_get(s1.base_url() + "/status.py?code=200&content=a"));
        EXPECT_EQ(r1.status, 200);
        co_await fetch::read_all(r1);
        auto r2 = co_await p.client.fetch(traced_get(s2.base_url() + "/status.py?code=200&content=b"));
        EXPECT_EQ(r2.status, 200);
        const std::string c2 = header_of(r2, "X-Conn-Id");
        EXPECT_FALSE(c2.empty());
        co_await fetch::read_all(r2);
        EXPECT_EQ(s2.conn_count(), 1u) << "不同端口（不同池键）应新建连接";
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// 用例 3：body 读一半就丢弃 → 连接关闭不回池 → 下一请求新建连接
TEST(PoolReuse, PartialBodyDiscardNewConnection)
{
    wpt::WptTestServer server("third_party/wpt");
    const std::string big(200 * 1024, 'x'); // 注意：URL/头有 8KB 限制，body 走 POST
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        std::string c1, c2;
        {
            fetch::Request r1;
            r1.method = "POST";
            r1.url = server.base_url() + "/echo-content.py";
            r1.body = big; // 服务端回显 200KB
            r1.headers.push_back({"X-Trace-Conn", "1"});
            auto resp = co_await p.client.fetch(std::move(r1));
            EXPECT_EQ(resp.status, 200);
            c1 = header_of(resp, "X-Conn-Id");
            const auto block = co_await resp.body->read(); // 只读一块（< 总长）就丢弃
            EXPECT_TRUE(block.has_value());
        } // resp 析构 → body 未读干 → 连接关闭（不回池）
        auto r2 = co_await p.client.fetch(traced_get(server.base_url() + "/status.py?code=200&content=next"));
        c2 = header_of(r2, "X-Conn-Id");
        co_await fetch::read_all(r2);
        EXPECT_NE(c1, c2) << "body 未读干的连接不得回池复用";
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// 用例 4：HEAD（无 body）响应后连接干净 → 回池复用
TEST(PoolReuse, HeadReusesConnection)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        fetch::Request head;
        head.method = "HEAD";
        head.url = server.base_url() + "/status.py?code=200&content=head";
        head.headers.push_back({"X-Trace-Conn", "1"});
        auto r1 = co_await p.client.fetch(std::move(head));
        const std::string c1 = header_of(r1, "X-Conn-Id");
        co_await fetch::read_all(r1); // 无 body：空读
        auto r2 = co_await p.client.fetch(traced_get(server.base_url() + "/status.py?code=200&content=next"));
        const std::string c2 = header_of(r2, "X-Conn-Id");
        co_await fetch::read_all(r2);
        EXPECT_EQ(c1, c2) << "HEAD 请求后连接应回池复用";
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// 用例 5：Connection: close 响应 → 不回池 → 下一请求新建连接
TEST(PoolReuse, ConnectionCloseNotReused)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        // slow-response.py 的响应头带 Connection: close（写完即断）
        auto r1 = co_await p.client.fetch(
            traced_get(server.base_url() + "/slow-response.py?delay=10&content=bye"));
        const std::string c1 = header_of(r1, "X-Conn-Id");
        co_await fetch::read_all(r1);
        auto r2 = co_await p.client.fetch(traced_get(server.base_url() + "/status.py?code=200&content=next"));
        const std::string c2 = header_of(r2, "X-Conn-Id");
        co_await fetch::read_all(r2);
        EXPECT_NE(c1, c2) << "Connection: close 响应不得回池";
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// ==================== 陈旧连接重试 ====================

// 用例 8：服务端写完即断（close-after.py，RST）→ 客户端读干回池 → 下次复用
// 写失败（RST 已到达）→ 自动重试一次（新连接）→ 成功。X-Conn-Id 不同 = 走新连接。
TEST(PoolReuse, StaleConnectionRetried)
{
    wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        // 1) 请求 1：正常响应（keep-alive），服务端写完即断（RST）
        auto r1 = co_await p.client.fetch(traced_get(base + "/close-after.py?code=200&content=bye"));
        EXPECT_EQ(r1.status, 200);
        const std::string c1 = header_of(r1, "X-Conn-Id");
        EXPECT_EQ(co_await fetch::read_all(r1), "bye");
        // 连接已回池（客户端感知不到服务端已断）
        // 等服务端延迟 RST（服务端 100ms 后发，本地回环微秒级到达）被 Winsock
        // 处理：否则复用写可能赶在 RST 之前成功（写成功读 EOF 则走 H3 的
        // "读头零字节 EOF"重试分支，同样会重试——此处等 RST 是为了确定性覆盖
        // "写失败"分支）
        boost::asio::steady_timer t(p.io, std::chrono::milliseconds(250));
        co_await t.async_wait(exec::asio::use_sender);
        // 2) 请求 2：复用死连接 → 写失败（ECONNRESET）→ 自动重试 → 成功
        auto r2 = co_await p.client.fetch(traced_get(base + "/status.py?code=200&content=ok"));
        EXPECT_EQ(r2.status, 200);
        const std::string c2 = header_of(r2, "X-Conn-Id");
        EXPECT_EQ(co_await fetch::read_all(r2), "ok");
        EXPECT_NE(c1, c2) << "陈旧连接重试应走新连接";
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// 用例 8b：服务端优雅关闭（fin-after.py，FIN 而非 RST）→ 复用连接写成功、
// 读响应头零字节 EOF → 仍自动重试一次（H3：陈旧 keep-alive 的最高频形态；
// pooled_flow 的 header_eof 分支——本项目在 hyper 语义外的额外放宽）
TEST(PoolReuse, StaleConnectionFinRetried)
{
    wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        // 1) 请求 1：正常响应（keep-alive），服务端写完即优雅关闭（FIN）
        auto r1 = co_await p.client.fetch(traced_get(base + "/fin-after.py?code=200&content=bye"));
        EXPECT_EQ(r1.status, 200);
        const std::string c1 = header_of(r1, "X-Conn-Id");
        EXPECT_EQ(co_await fetch::read_all(r1), "bye");
        // 连接已回池（客户端感知不到服务端已断）；服务端已 close，无论如何
        // 都不会再响应这条连接——写失败（RST 竞态）或写成功读 EOF 均触发重试
        // 2) 请求 2：复用死连接 → 自动重试 → 成功
        auto r2 = co_await p.client.fetch(traced_get(base + "/status.py?code=200&content=ok"));
        EXPECT_EQ(r2.status, 200);
        const std::string c2 = header_of(r2, "X-Conn-Id");
        EXPECT_EQ(co_await fetch::read_all(r2), "ok");
        EXPECT_NE(c1, c2) << "读头零字节 EOF 的重试应走新连接";
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// 用例 10：流式上传（body_stream）在复用连接上失败 → 不重试 → 错误上抛
TEST(PoolReuse, StreamingUploadNoRetry)
{
    wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        // 1) 建连并回池（服务端写完即断）
        auto r1 = co_await p.client.fetch(traced_get(base + "/close-after.py?code=200&content=bye"));
        co_await fetch::read_all(r1);
        // 2) 复用死连接 + 流式上传 → 抛错（body_stream 不可重放）
        fetch::Request r2;
        r2.method = "POST";
        r2.url = base + "/echo-content.py";
        r2.body_size = 5;
        r2.body_stream = std::make_shared<fetch::BytesBodySource>("hello");
        auto resp = co_await p.client.fetch(std::move(r2)); // 应抛错，不应走到这里
        EXPECT_TRUE(false) << "流式上传复用失败应抛错（不重试）";
        co_await fetch::read_all(resp);
    }());
    ASSERT_TRUE(p.done);
    ASSERT_TRUE(p.error) << "流式上传复用死连接应失败";
}

// 用例 9：fresh 连接失败（建连即拒绝）→ 不重试 → 错误上抛
TEST(PoolReuse, RefusedPortPropagates)
{
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.fetch(traced_get("http://127.0.0.1:1/x"));
        EXPECT_TRUE(false) << "连接被拒绝应抛错";
        co_await fetch::read_all(resp);
    }());
    ASSERT_TRUE(p.done);
    ASSERT_TRUE(p.error) << "建连失败应上抛";
}

// 用例 14（简化）：body 阶段取消 → 连接关闭不回池 → 后续请求新建连接
TEST(PoolReuse, AbortDuringBodyClosesConnection)
{
    wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        std::stop_source ss;
        fetch::Request req;
        req.url = base + "/slow-response.py?delay=400&content=hello";
        fetch::Response resp = co_await p.client.fetch(std::move(req), ss.get_token());
        // fetch 已 resolve（头到）；30ms 后 abort 挂起的 body 读
        boost::asio::steady_timer t(p.io, std::chrono::milliseconds(30));
        t.async_wait([&](const boost::system::error_code&) { ss.request_stop(); });
        co_await resp.body->read(); // 以 stopped 中断（不走到这里）
        EXPECT_TRUE(false) << "读不应正常返回";
    }());
    ASSERT_TRUE(p.stopped) << "abort 应使挂起的读以 stopped 完成";
    // 取消的连接未回池：后续请求（同一 client/池）应从新连接开始
    const uint64_t conns_before = server.conn_count();
    p.run([&]() -> std_exec::task<void> {
        auto r1 = co_await p.client.fetch(traced_get(base + "/status.py?code=200&content=a"));
        co_await fetch::read_all(r1);
        auto r2 = co_await p.client.fetch(traced_get(base + "/status.py?code=200&content=b"));
        co_await fetch::read_all(r2);
    }());
    ASSERT_FALSE(p.error) << p.error_message();
    // abort 用了 1 条连接；后续 2 个请求若复用 abort 前的连接则不会再 accept。
    // 若 abort 连接被错误回池复用，会因已 close 触发重试 → 额外 accept。
    EXPECT_EQ(server.conn_count() - conns_before, 1u)
        << "abort 后连接不得回池（后续请求应复用同一新连接）";
}

// ==================== TLS 复用 ====================

// 用例 12（简化）：TLS 连接读干回池 → 下个 https 请求复用同一连接
TEST(PoolReuse, TlsReusesConnection)
{
    wpt_test::TlsEchoServer server("server");
    const std::string cert = read_cert_file("server");
    ASSERT_FALSE(cert.empty()) << "读取自签证书失败";
    fetch::Options opt;
    opt.tls.extra_trust_pem.push_back(cert);
    Probe p(std::move(opt));
    p.run([&]() -> std_exec::task<void> {
        auto r1 = co_await p.client.fetch(traced_get(server.base_url() + "/one"));
        EXPECT_EQ(r1.status, 200);
        const std::string c1 = header_of(r1, "X-Conn-Id");
        co_await fetch::read_all(r1);
        auto r2 = co_await p.client.fetch(traced_get(server.base_url() + "/two"));
        EXPECT_EQ(r2.status, 200);
        const std::string c2 = header_of(r2, "X-Conn-Id");
        co_await fetch::read_all(r2);
        EXPECT_EQ(c1, c2) << "TLS 连接应复用（握手只做一次）";
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// ==================== TLS session 复用（M5） ====================

// 用例 12b：连接不回池（max_idle_per_host=0 强制每次新建 TLS 连接）时，
// 同一 host 第二次建连应复用 TLS session（缓存命中 + SSL_session_reused 为真）。
TEST(PoolReuse, TlsSessionResumedAcrossConnections)
{
    wpt_test::TlsEchoServer server("server");
    const std::string cert = read_cert_file("server");
    ASSERT_FALSE(cert.empty()) << "读取自签证书失败";
    boost::asio::io_context io;
    fetch::set_thread_io(io);
    fetch::PoolOptions popts;
    popts.max_idle_per_host = 0; // 连接不回池 → 每个请求都新建 TCP+TLS
    auto pool = std::make_shared<fetch::ConnectionPool>(io, popts);
    fetch::TlsOptions tls;
    tls.extra_trust_pem.push_back(cert);
    auto transport = std::make_shared<fetch::BeastTransport>(std::move(tls), pool);
    fetch::Client client(transport);
    bool done = false;
    std::exception_ptr error;
    stdexec::counting_scope scope;
    stdexec::spawn(
        [&]() -> std_exec::task<void> {
            auto r1 = co_await client.fetch(traced_get(server.base_url() + "/one"));
            EXPECT_EQ(r1.status, 200);
            co_await fetch::read_all(r1); // 读干：让 TLS 1.3 ticket 被处理入库
            EXPECT_EQ(transport->tls_session_resumed_count(), 0u)
                << "首次建连应是完整握手";
            auto r2 = co_await client.fetch(traced_get(server.base_url() + "/two"));
            EXPECT_EQ(r2.status, 200);
            co_await fetch::read_all(r2);
        }()
            | stdexec::then([&]() noexcept { done = true; })
            | stdexec::upon_error([&](std::exception_ptr ep) noexcept {
                  error = std::move(ep);
                  done = true;
              }),
        scope.get_token(),
        stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{io}});
    (void)ScopeJoiner::run(scope, io);
    ASSERT_TRUE(done);
    ASSERT_FALSE(error) << [&] {
        try {
            std::rethrow_exception(error);
        } catch (const std::exception& e) {
            return std::string(e.what());
        }
        return std::string();
    }();
    EXPECT_GE(transport->tls_session_cache_hits(), 1u)
        << "第二次建连应命中 session 缓存（size="
        << transport->tls_session_cache_size()
        << " stores=" << transport->tls_session_cache_stores() << "）";
    EXPECT_GE(transport->tls_session_resumed_count(), 1u)
        << "第二次建连应复用 TLS session（精简握手）";
}

// ==================== easy 层配置暴露 ====================

// 用例 13：easy 默认即池化（连续请求复用同一连接）
TEST(PoolReuse, EasyDefaultPooled)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto r1 = co_await p.client.get(server.base_url() + "/status.py?code=200&content=a")
                      .header("X-Trace-Conn", "1")
                      .send();
        const std::string c1 = easy_header_of(r1, "X-Conn-Id");
        co_await r1.text();
        auto r2 = co_await p.client.get(server.base_url() + "/status.py?code=200&content=b")
                      .header("X-Trace-Conn", "1")
                      .send();
        const std::string c2 = easy_header_of(r2, "X-Conn-Id");
        co_await r2.text();
        EXPECT_EQ(c1, c2) << "easy 默认应启用连接池";
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// pool_max_idle_per_host(0) = 禁用池（每次新建连接）
TEST(PoolReuse, EasyPoolDisabledNoReuse)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p([](fetch::easy::ClientBuilder& b) { b.pool_max_idle_per_host(0); });
    p.run([&]() -> std_exec::task<void> {
        auto r1 = co_await p.client.get(server.base_url() + "/status.py?code=200&content=a")
                      .header("X-Trace-Conn", "1")
                      .send();
        const std::string c1 = easy_header_of(r1, "X-Conn-Id");
        co_await r1.text();
        auto r2 = co_await p.client.get(server.base_url() + "/status.py?code=200&content=b")
                      .header("X-Trace-Conn", "1")
                      .send();
        const std::string c2 = easy_header_of(r2, "X-Conn-Id");
        co_await r2.text();
        EXPECT_NE(c1, c2) << "pool_max_idle_per_host(0) 应禁用连接池";
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// ==================== 池状态（idle_count 断言） ====================

fetch::PoolOptions popts_default()
{
    fetch::PoolOptions o;
    o.idle_timeout = std::chrono::seconds(90);
    o.max_idle_per_host = std::numeric_limits<size_t>::max();
    return o;
}

TEST(PoolState, IdleCountAfterRequests)
{
    wpt::WptTestServer server("third_party/wpt");
    PoolProbe p(popts_default());
    p.run([&]() -> std_exec::task<void> {
        auto r1 = co_await p.client.fetch(traced_get(server.base_url() + "/status.py?code=200&content=a"));
        co_await fetch::read_all(r1);
    }());
    ASSERT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(p.pool->idle_count(), 1u) << "读干 + keep-alive 应回池";
    // 第二个请求复用 → idle 数不变
    p.run([&]() -> std_exec::task<void> {
        auto r2 = co_await p.client.fetch(traced_get(server.base_url() + "/status.py?code=200&content=b"));
        co_await fetch::read_all(r2);
    }());
    ASSERT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(p.pool->idle_count(), 1u) << "复用后池容量不变";
}

// put 上限：max_idle_per_host(1) 时第二条 idle 直接丢弃
TEST(PoolState, MaxIdlePerHostDropsExcess)
{
    wpt::WptTestServer server("third_party/wpt");
    boost::asio::io_context io;
    fetch::PoolOptions popts = popts_default();
    popts.max_idle_per_host = 1;
    // 注意：池必须以 shared_ptr 持有（PooledConnection 经 weak_ptr 回指，
    // enable_shared_from_this 对栈对象无效）
    auto pool = std::make_shared<fetch::ConnectionPool>(io, popts);
    const fetch::PoolKey key{"http", "127.0.0.1",
                             static_cast<uint16_t>(server.port()), "", ""};
    auto make_sock = [&]() {
        auto s = std::make_shared<boost::asio::ip::tcp::socket>(io);
        boost::system::error_code ec;
        s->connect(boost::asio::ip::tcp::endpoint(
                       boost::asio::ip::make_address("127.0.0.1"), server.port()),
                   ec);
        return s;
    };
    auto s1 = make_sock();
    auto s2 = make_sock();
    const auto h1 = s1->native_handle();
    const auto h2 = s2->native_handle();
    pool->put(key, fetch::IdleEntry{{}, fetch::PlainStream(std::move(*s1)), {}, {}});
    pool->put(key, fetch::IdleEntry{{}, fetch::PlainStream(std::move(*s2)), {}, {}});
    EXPECT_EQ(pool->idle_count(), 1u) << "超 max_idle_per_host 应丢弃（上限只在 put 执行）";
    // 栈里只剩第一条（第二条被丢弃）；checkout 弹栈顶 = s1
    auto c = pool->checkout(key);
    ASSERT_TRUE(c.has_value());
    EXPECT_EQ(std::get<fetch::PlainStream>(c->stream()).native_handle(), h1);
    c->put_back(); // 回池（weak_ptr 回指有效）
    EXPECT_EQ(pool->idle_count(), 1u);
    auto c2 = pool->checkout(key);
    ASSERT_TRUE(c2.has_value());
    EXPECT_EQ(std::get<fetch::PlainStream>(c2->stream()).native_handle(), h1);
}

// LIFO：max_idle_per_host(2) 时两条都进池，checkout 弹栈顶（最后放入的）
TEST(PoolState, LifoOrder)
{
    wpt::WptTestServer server("third_party/wpt");
    boost::asio::io_context io;
    fetch::PoolOptions popts = popts_default();
    popts.max_idle_per_host = 2;
    auto pool = std::make_shared<fetch::ConnectionPool>(io, popts);
    const fetch::PoolKey key{"http", "127.0.0.1",
                             static_cast<uint16_t>(server.port()), "", ""};
    auto make_sock = [&]() {
        auto s = std::make_shared<boost::asio::ip::tcp::socket>(io);
        boost::system::error_code ec;
        s->connect(boost::asio::ip::tcp::endpoint(
                       boost::asio::ip::make_address("127.0.0.1"), server.port()),
                   ec);
        return s;
    };
    auto s1 = make_sock();
    auto s2 = make_sock();
    const auto h1 = s1->native_handle();
    const auto h2 = s2->native_handle();
    pool->put(key, fetch::IdleEntry{{}, fetch::PlainStream(std::move(*s1)), {}, {}});
    pool->put(key, fetch::IdleEntry{{}, fetch::PlainStream(std::move(*s2)), {}, {}});
    EXPECT_EQ(pool->idle_count(), 2u);
    // LIFO：弹栈顶（最后放入的 s2）
    auto c = pool->checkout(key);
    ASSERT_TRUE(c.has_value());
    EXPECT_EQ(std::get<fetch::PlainStream>(c->stream()).native_handle(), h2)
        << "checkout 应 LIFO 弹栈顶";
    // 不归还，直接再取 → 栈里只剩 s1
    auto c2 = pool->checkout(key);
    ASSERT_TRUE(c2.has_value());
    EXPECT_EQ(std::get<fetch::PlainStream>(c2->stream()).native_handle(), h1)
        << "第二次 checkout 应取剩余连接";
    // 归还顺序无关（c/c2 各自析构关闭）
    EXPECT_EQ(pool->idle_count(), 0u);
}

// idle_timeout：清扫定时器按超时淘汰 idle 连接
TEST(PoolState, IdleTimeoutSweeps)
{
    wpt::WptTestServer server("third_party/wpt");
    fetch::PoolOptions popts = popts_default();
    popts.idle_timeout = std::chrono::milliseconds(100);
    PoolProbe p(std::move(popts));
    p.run([&]() -> std_exec::task<void> {
        auto r1 = co_await p.client.fetch(traced_get(server.base_url() + "/status.py?code=200&content=a"));
        co_await fetch::read_all(r1);
    }());
    ASSERT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(p.pool->idle_count(), 1u);
    // 驱动 io 直到清扫定时器（周期 = max(100ms, 90ms)）触发
    p.run([&]() -> std_exec::task<void> {
        boost::asio::steady_timer t(p.io, std::chrono::milliseconds(300));
        co_await t.async_wait(exec::asio::use_sender);
    }());
    ASSERT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(p.pool->idle_count(), 0u) << "idle_timeout 到期应被清扫";
}

// close_all：清空 idle 且池仍可用
TEST(PoolState, CloseAllThenStillUsable)
{
    wpt::WptTestServer server("third_party/wpt");
    PoolProbe p(popts_default());
    p.run([&]() -> std_exec::task<void> {
        auto r1 = co_await p.client.fetch(traced_get(server.base_url() + "/status.py?code=200&content=a"));
        co_await fetch::read_all(r1);
    }());
    ASSERT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(p.pool->idle_count(), 1u);
    p.pool->close_all();
    EXPECT_EQ(p.pool->idle_count(), 0u) << "close_all 应清空 idle 连接";
    // 池仍可用：请求正常，连接重新回池
    p.run([&]() -> std_exec::task<void> {
        auto r2 = co_await p.client.fetch(traced_get(server.base_url() + "/status.py?code=200&content=b"));
        EXPECT_EQ(r2.status, 200);
        co_await fetch::read_all(r2);
    }());
    ASSERT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(p.pool->idle_count(), 1u) << "close_all 后池应继续工作";
}

} // namespace
