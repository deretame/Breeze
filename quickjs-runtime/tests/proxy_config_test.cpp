// 代理配置体系测试（三级优先级 + 进程级/系统自动 + 手动标记）
//
// 覆盖：
//   Proxy::parse 各种格式（http/socks5/user:pass/IPv6/默认端口/非法）
//   优先级：请求级 > 实例级 > 进程级(手动) > 系统自动 > 直连
//   手动标记：手动配置后系统自动更新被跳过；清除后恢复
//   系统自动仅 http（set_system_proxy 只接受 HttpProxy，走 http 传输）
//   重定向各跳沿用请求级代理
//   Windows ProxyServer 注册表值解析（仅 http 段，忽略 socks 段）
//
// 不联网：FakeTransport 记录选路（direct/http/socks5 + host/port）。
#include <gtest/gtest.h>
#include <log.hpp>
#include <fetch/client.hpp>
#include <fetch/middleware.hpp>
#include <fetch/process_proxy.hpp>
#include <fetch/scheduler.hpp>

#include <stdexec/execution.hpp>

#include <boost/asio/io_context.hpp>

#include <chrono>
#include <exception>
#include <memory>
#include <string>
#include <thread>

namespace {

// ---- 驱动辅助：counting_scope 的 join 驱动（同 fetchcore_test.cpp）----
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
        return joined;
    }
};

// ---- FakeTransport：记录选路，不真正联网 ----
struct FakeTransport : fetch::Transport {
    int direct_calls = 0;
    int http_calls = 0;
    int socks_calls = 0;
    std::string last_kind; // "direct" | "http" | "socks5"
    std::string last_host;
    uint16_t last_port = 0;
    bool redirect_once = false; // 首跳返回 302（重定向沿用测试用）

    std_exec::task<fetch::Response> request(const fetch::Request& req,
                                            std::stop_token) override
    {
        ++direct_calls;
        last_kind = "direct";
        fetch::Response r;
        r.status = 200;
        r.url = req.url;
        co_return r;
    }

    std_exec::task<fetch::Response> request_via_socks5(const fetch::Request& req,
                                                       const fetch::Socks5Proxy& p,
                                                       std::stop_token) override
    {
        ++socks_calls;
        last_kind = "socks5";
        last_host = p.host;
        last_port = p.port;
        fetch::Response r;
        r.status = 200;
        r.url = req.url;
        co_return r;
    }

    std_exec::task<fetch::Response> request_via_http_proxy(const fetch::Request& req,
                                                           const fetch::HttpProxy& p,
                                                           std::stop_token) override
    {
        ++http_calls;
        last_kind = "http";
        last_host = p.host;
        last_port = p.port;
        fetch::Response r;
        if (redirect_once) {
            redirect_once = false;
            r.status = 302;
            r.headers.push_back({"Location", "/next"});
        } else {
            r.status = 200;
        }
        r.url = req.url;
        co_return r;
    }
};

// ---- RecordingMiddleware：记录前置相位是否执行（placement 回归测试用）----
struct RecordingMiddleware : fetch::Middleware {
    int calls = 0;
    std_exec::task<fetch::Response> intercept(const fetch::Request& req,
                                              std::stop_token st,
                                              fetch::Handler next) override
    {
        ++calls;
        co_return co_await next(req, std::move(st));
    }
};

struct ProxyConfigTest : ::testing::Test {
    boost::asio::io_context io;
    std::shared_ptr<FakeTransport> transport;
    std::unique_ptr<fetch::Client> client;

    void SetUp() override
    {
        fetch::set_thread_io(io); // 本测试线程的 fetch io 来源（thread_local）
        transport = std::make_shared<FakeTransport>();
        client = std::make_unique<fetch::Client>(transport);
    }

    void TearDown() override
    {
        // 清理进程级全局状态，避免用例间污染
        fetch::clear_manual_proxy();
        fetch::set_system_proxy(std::nullopt);
    }

    // 重建 client（带实例级代理）
    void rebuild(fetch::Options opt = {}) { client = std::make_unique<fetch::Client>(transport, std::move(opt)); }

    // 同步驱动一次请求；返回是否成功（无异常）
    bool run(fetch::Request req)
    {
        stdexec::counting_scope scope;
        bool done = false;
        std::string err;
        auto work = [&]() -> std_exec::task<void> {
            try {
                (void)co_await client->fetch(std::move(req));
            } catch (const std::exception& e) {
                err = e.what();
            }
        }();
        stdexec::spawn(
            std::move(work)
                | stdexec::then([&]() noexcept { done = true; })
                | stdexec::upon_error([&](std::exception_ptr ep) noexcept {
                      try {
                          std::rethrow_exception(ep);
                      } catch (const std::exception& e) {
                          err = e.what();
                      }
                      done = true;
                  })
                | stdexec::upon_stopped([&]() noexcept { done = true; }),
            scope.get_token(),
            stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{io}});
        EXPECT_TRUE(ScopeJoiner::run(scope, io)) << "scope join 超时";
        if (!err.empty())
            QLOG_WARNING("fetch 失败: {}", err);
        return err.empty();
    }

    static fetch::Request req_to(const char* url)
    {
        fetch::Request r;
        r.url = url;
        return r;
    }
};

// ---- Proxy::parse ----

TEST(ProxyParse, HttpBasic)
{
    auto p = fetch::Proxy::parse("http://127.0.0.1:7890");
    ASSERT_TRUE(p);
    EXPECT_EQ(p->kind, fetch::Proxy::Kind::Http);
    EXPECT_EQ(p->host, "127.0.0.1");
    EXPECT_EQ(p->port, 7890);
    EXPECT_FALSE(p->auth);
}

TEST(ProxyParse, Socks5)
{
    auto p = fetch::Proxy::parse("socks5://proxy.example.com:1080");
    ASSERT_TRUE(p);
    EXPECT_EQ(p->kind, fetch::Proxy::Kind::Socks5);
    EXPECT_EQ(p->host, "proxy.example.com");
    EXPECT_EQ(p->port, 1080);
}

TEST(ProxyParse, Auth)
{
    auto p = fetch::Proxy::parse("http://alice:s3cret@127.0.0.1:8888");
    ASSERT_TRUE(p);
    ASSERT_TRUE(p->auth);
    EXPECT_EQ(p->auth->first, "alice");
    EXPECT_EQ(p->auth->second, "s3cret");

    // 无密码的 userinfo（user@host:port）
    auto q = fetch::Proxy::parse("socks5://bob@127.0.0.1:1080");
    ASSERT_TRUE(q);
    ASSERT_TRUE(q->auth);
    EXPECT_EQ(q->auth->first, "bob");
    EXPECT_TRUE(q->auth->second.empty());
}

TEST(ProxyParse, DefaultPort)
{
    auto p = fetch::Proxy::parse("http://127.0.0.1"); // http 默认 8080
    ASSERT_TRUE(p);
    EXPECT_EQ(p->port, 8080);
    auto s = fetch::Proxy::parse("socks5://127.0.0.1"); // socks5 默认 1080
    ASSERT_TRUE(s);
    EXPECT_EQ(s->port, 1080);
}

TEST(ProxyParse, BareHostPort)
{
    auto p = fetch::Proxy::parse("127.0.0.1:7890"); // 无 scheme → http
    ASSERT_TRUE(p);
    EXPECT_EQ(p->kind, fetch::Proxy::Kind::Http);
    EXPECT_EQ(p->host, "127.0.0.1");
    EXPECT_EQ(p->port, 7890);
}

TEST(ProxyParse, Ipv6)
{
    auto p = fetch::Proxy::parse("http://[::1]:8080");
    ASSERT_TRUE(p);
    EXPECT_EQ(p->host, "::1");
    EXPECT_EQ(p->port, 8080);
    auto q = fetch::Proxy::parse("http://[::1]"); // 无端口
    ASSERT_TRUE(q);
    EXPECT_EQ(q->host, "::1");
    EXPECT_EQ(q->port, 8080);
    EXPECT_FALSE(fetch::Proxy::parse("http://[]"));     // 空 IPv6 host
    EXPECT_FALSE(fetch::Proxy::parse("http://[]:8080"));
}

TEST(ProxyParse, SchemeCaseInsensitive)
{
    auto p = fetch::Proxy::parse("HTTP://127.0.0.1:7890");
    ASSERT_TRUE(p);
    EXPECT_EQ(p->kind, fetch::Proxy::Kind::Http);
    EXPECT_EQ(p->host, "127.0.0.1");
    auto s = fetch::Proxy::parse("SOCKS5://h:1080");
    ASSERT_TRUE(s);
    EXPECT_EQ(s->kind, fetch::Proxy::Kind::Socks5);
}

TEST(ProxyParse, Invalid)
{
    EXPECT_FALSE(fetch::Proxy::parse(""));
    EXPECT_FALSE(fetch::Proxy::parse("   "));
    EXPECT_FALSE(fetch::Proxy::parse("https://127.0.0.1:443")); // HTTPS 代理不支持
    EXPECT_FALSE(fetch::Proxy::parse("ftp://127.0.0.1:21"));
    EXPECT_FALSE(fetch::Proxy::parse("http://:8080"));          // 空 host
    EXPECT_FALSE(fetch::Proxy::parse("http://h:0"));            // 端口 0
    EXPECT_FALSE(fetch::Proxy::parse("http://h:65536"));        // 端口越界
    EXPECT_FALSE(fetch::Proxy::parse("http://h:abc"));          // 非数字端口
    EXPECT_FALSE(fetch::Proxy::parse("http://h:80:90"));        // 多余冒号（非 IPv6）
    EXPECT_FALSE(fetch::Proxy::parse("http://[::1"));           // IPv6 缺 ]
}

// ---- 优先级 ----

// 请求级 > 实例级
TEST_F(ProxyConfigTest, RequestOverridesInstance)
{
    fetch::Options opt;
    opt.proxy = fetch::Proxy::parse("http://inst:8080");
    rebuild(std::move(opt));

    auto req = req_to("http://example.com/");
    req.proxy = fetch::Proxy::parse("http://req:9090");
    ASSERT_TRUE(run(std::move(req)));

    EXPECT_EQ(transport->last_kind, "http");
    EXPECT_EQ(transport->last_host, "req");
    EXPECT_EQ(transport->last_port, 9090);
    EXPECT_EQ(transport->direct_calls, 0);
}

// 实例级 > 进程级（手动）
TEST_F(ProxyConfigTest, InstanceOverridesProcess)
{
    fetch::set_process_proxy(fetch::Proxy::parse("http://proc:7070"));
    fetch::Options opt;
    opt.proxy = fetch::Proxy::parse("http://inst:8080");
    rebuild(std::move(opt));

    ASSERT_TRUE(run(req_to("http://example.com/")));
    EXPECT_EQ(transport->last_kind, "http");
    EXPECT_EQ(transport->last_host, "inst");
    EXPECT_EQ(transport->last_port, 8080);
}

// 进程级（手动）> 系统自动
TEST_F(ProxyConfigTest, ProcessOverridesSystem)
{
    fetch::set_system_proxy(fetch::HttpProxy{"sys", 6060});
    fetch::set_process_proxy(fetch::Proxy::parse("http://proc:7070"));

    ASSERT_TRUE(run(req_to("http://example.com/")));
    EXPECT_EQ(transport->last_kind, "http");
    EXPECT_EQ(transport->last_host, "proc");
    EXPECT_EQ(transport->last_port, 7070);
}

// 仅系统自动（未手动配置）→ 走系统代理（http 传输）
TEST_F(ProxyConfigTest, SystemOnlyWhenNoManual)
{
    fetch::set_system_proxy(fetch::HttpProxy{"sys", 6060});

    ASSERT_TRUE(run(req_to("http://example.com/")));
    EXPECT_EQ(transport->last_kind, "http");
    EXPECT_EQ(transport->last_host, "sys");
    EXPECT_EQ(transport->last_port, 6060);
    EXPECT_EQ(transport->direct_calls, 0);
}

// 手动标记：手动配置后，系统自动更新被跳过；清除标记后恢复跟随系统
TEST_F(ProxyConfigTest, ManualFlagSkipsSystemUpdate)
{
    fetch::set_process_proxy(fetch::Proxy::parse("http://proc:7070")); // manual = true
    fetch::set_system_proxy(fetch::HttpProxy{"sys", 6060});            // 被跳过
    EXPECT_FALSE(fetch::system_proxy());                               // 系统槽仍空
    EXPECT_TRUE(fetch::has_manual_proxy());

    // 手动配置期间请求走手动代理
    ASSERT_TRUE(run(req_to("http://example.com/")));
    EXPECT_EQ(transport->last_host, "proc");

    // 清除手动标记 → 系统自动恢复生效
    fetch::clear_manual_proxy();
    EXPECT_FALSE(fetch::has_manual_proxy());
    fetch::set_system_proxy(fetch::HttpProxy{"sys2", 6161});
    ASSERT_TRUE(run(req_to("http://example.com/")));
    EXPECT_EQ(transport->last_host, "sys2");
    EXPECT_EQ(transport->last_port, 6161);
}

// 监听线程生命周期：start/stop 幂等、可反复启停（无崩溃/泄漏）
TEST_F(ProxyConfigTest, WatchLifecycleIdempotent)
{
    fetch::start_system_proxy_watch();
    fetch::start_system_proxy_watch(); // 重复 start 幂等
    fetch::stop_system_proxy_watch();
    fetch::stop_system_proxy_watch(); // 重复 stop 幂等
    fetch::start_system_proxy_watch();
    fetch::stop_system_proxy_watch();
}

// 手动清除代理（nullopt）也置位手动标记（保持"不跟随系统"）
TEST_F(ProxyConfigTest, ManualClearAlsoSetsFlag)
{
    fetch::set_process_proxy(std::nullopt); // 手动"不用代理"
    EXPECT_TRUE(fetch::has_manual_proxy());
    fetch::set_system_proxy(fetch::HttpProxy{"sys", 6060}); // 被跳过
    EXPECT_FALSE(fetch::system_proxy());

    ASSERT_TRUE(run(req_to("http://example.com/")));
    EXPECT_EQ(transport->last_kind, "direct"); // 手动无代理 → 直连
}

// 全部未配置 → 直连
TEST_F(ProxyConfigTest, DirectWhenNothingConfigured)
{
    ASSERT_TRUE(run(req_to("http://example.com/")));
    EXPECT_EQ(transport->last_kind, "direct");
    EXPECT_EQ(transport->http_calls, 0);
    EXPECT_EQ(transport->socks_calls, 0);
}

// 请求级 socks5 → 走 SOCKS5 隧道
TEST_F(ProxyConfigTest, RequestSocks5)
{
    auto req = req_to("http://example.com/");
    req.proxy = fetch::Proxy::parse("socks5://s5:1234");
    ASSERT_TRUE(run(std::move(req)));
    EXPECT_EQ(transport->last_kind, "socks5");
    EXPECT_EQ(transport->last_host, "s5");
    EXPECT_EQ(transport->last_port, 1234);
}

// 重定向各跳沿用请求级代理
TEST_F(ProxyConfigTest, RedirectCarriesRequestProxy)
{
    transport->redirect_once = true;
    auto req = req_to("http://example.com/start");
    req.proxy = fetch::Proxy::parse("http://req:9090");
    ASSERT_TRUE(run(std::move(req)));

    EXPECT_EQ(transport->http_calls, 2); // 首跳 302 + 第二跳 /next
    EXPECT_EQ(transport->last_host, "req");
    EXPECT_EQ(transport->last_port, 9090);
}

// 回归：用户 use() 的中间件必须在代理短路之前执行
// （ProxyMiddleware 固定最内层；代理命中时用户中间件前置相位不被跳过）
TEST_F(ProxyConfigTest, UserMiddlewareRunsBeforeProxyShortCircuit)
{
    auto rec = std::make_shared<RecordingMiddleware>();
    client->use(rec);

    auto req = req_to("http://example.com/");
    req.proxy = fetch::Proxy::parse("http://req:9090"); // 请求级代理 → 命中短路
    ASSERT_TRUE(run(std::move(req)));

    EXPECT_EQ(rec->calls, 1);                // 用户中间件执行了
    EXPECT_EQ(transport->last_kind, "http"); // 且代理确实命中
    EXPECT_EQ(transport->last_host, "req");
}

// ---- URL 分流（Options::proxy_routes）----

// host 后缀匹配：example.com 与子域走路由代理，其他回落实例级默认代理
TEST_F(ProxyConfigTest, RouteHostSuffixMatches)
{
    fetch::Options opt;
    opt.proxy = fetch::Proxy::http("default", 8080);
    opt.proxy_routes = {{"example.com", fetch::Proxy::http("route-a", 9090)}};
    rebuild(std::move(opt));

    ASSERT_TRUE(run(req_to("http://example.com/")));     // 精确匹配
    EXPECT_EQ(transport->last_host, "route-a");
    ASSERT_TRUE(run(req_to("http://api.example.com/x"))); // 子域后缀
    EXPECT_EQ(transport->last_host, "route-a");
    ASSERT_TRUE(run(req_to("http://other.org/")));        // 未命中 → 默认代理
    EXPECT_EQ(transport->last_host, "default");
}

// 路径前缀匹配（/via-proxy 走代理，其余直连——旧 HttpProxyMiddleware 行为）
TEST_F(ProxyConfigTest, RoutePathPrefixMatches)
{
    fetch::Options opt;
    opt.proxy_routes = {{"/via-proxy", fetch::Proxy::http("route-p", 9090)}};
    rebuild(std::move(opt));

    ASSERT_TRUE(run(req_to("http://example.com/via-proxy")));
    EXPECT_EQ(transport->last_host, "route-p");
    ASSERT_TRUE(run(req_to("http://example.com/via-proxy/sub"))); // 前缀命中
    EXPECT_EQ(transport->last_host, "route-p");
    ASSERT_TRUE(run(req_to("http://example.com/other")));         // 未命中 → 直连
    EXPECT_EQ(transport->last_kind, "direct");
}

// 通配路由：* 匹配全部
TEST_F(ProxyConfigTest, RouteWildcard)
{
    fetch::Options opt;
    opt.proxy_routes = {{"*", fetch::Proxy::socks5("route-all", 1080)}};
    rebuild(std::move(opt));

    ASSERT_TRUE(run(req_to("https://anything.example/path")));
    EXPECT_EQ(transport->last_kind, "socks5");
    EXPECT_EQ(transport->last_host, "route-all");
}

// 直连规则：命中 proxy==nullopt 的路由 → 直连，不回落进程级/系统级
TEST_F(ProxyConfigTest, RouteDirectRuleShortCircuits)
{
    fetch::set_process_proxy(fetch::Proxy::http("proc", 7070));
    fetch::Options opt;
    opt.proxy_routes = {{"internal.example", std::nullopt}, {"*", fetch::Proxy::http("fallback", 8080)}};
    rebuild(std::move(opt));

    ASSERT_TRUE(run(req_to("http://internal.example/x"))); // 直连规则 → 直连（不用进程级）
    EXPECT_EQ(transport->last_kind, "direct");
    ASSERT_TRUE(run(req_to("http://public.example/")));     // 未命中直连规则 → 通配路由
    EXPECT_EQ(transport->last_host, "fallback");
}

// 请求级 > 路由规则
TEST_F(ProxyConfigTest, RequestOverridesRoute)
{
    fetch::Options opt;
    opt.proxy_routes = {{"example.com", fetch::Proxy::http("route-a", 9090)}};
    rebuild(std::move(opt));

    auto req = req_to("http://example.com/");
    req.proxy = fetch::Proxy::http("req", 9091);
    ASSERT_TRUE(run(std::move(req)));
    EXPECT_EQ(transport->last_host, "req");
}

// 路由规则 > 实例级默认代理（默认代理是兜底）
TEST_F(ProxyConfigTest, RouteOverridesInstanceDefault)
{
    fetch::Options opt;
    opt.proxy = fetch::Proxy::http("default", 8080);
    opt.proxy_routes = {{"example.com", fetch::Proxy::socks5("route-s", 1080)}};
    rebuild(std::move(opt));

    ASSERT_TRUE(run(req_to("http://example.com/")));
    EXPECT_EQ(transport->last_kind, "socks5");
    EXPECT_EQ(transport->last_host, "route-s");
}

// ---- URL 工具 ----
TEST(UrlTools, HostExtraction)
{
    EXPECT_EQ(fetch::url_host("http://example.com/"), "example.com");
    EXPECT_EQ(fetch::url_host("http://example.com:8080/path?q=1"), "example.com");
    EXPECT_EQ(fetch::url_host("https://user:pass@api.example.com:443/x"), "api.example.com");
    EXPECT_EQ(fetch::url_host("http://[::1]:8080/"), "::1");
    EXPECT_EQ(fetch::url_host("no-scheme"), "");
    // 路径/query 里的 @ 不算 userinfo（回归：误判会把 host 提取成垃圾）
    EXPECT_EQ(fetch::url_host("http://example.com/x?email=a@b.com"), "example.com");
    EXPECT_EQ(fetch::url_host("http://example.com/a@b"), "example.com");
}

TEST(UrlTools, PathExtraction)
{
    EXPECT_EQ(fetch::url_path("http://example.com"), "/");
    EXPECT_EQ(fetch::url_path("http://example.com/"), "/");
    EXPECT_EQ(fetch::url_path("http://example.com/a/b?x=1"), "/a/b");
    EXPECT_EQ(fetch::url_path("http://example.com/a#frag"), "/a");
}

TEST(UrlTools, HostSuffixMatch)
{
    EXPECT_TRUE(fetch::host_matches_suffix("example.com", "example.com"));
    EXPECT_TRUE(fetch::host_matches_suffix("api.example.com", "example.com"));
    EXPECT_TRUE(fetch::host_matches_suffix("a.b.example.com", "example.com"));
    EXPECT_TRUE(fetch::host_matches_suffix("EXAMPLE.COM", "example.com")); // 大小写不敏感
    EXPECT_TRUE(fetch::host_matches_suffix("API.Example.com", "example.com")); // 子域也大小写不敏感
    EXPECT_FALSE(fetch::host_matches_suffix("notexample.com", "example.com"));
    EXPECT_FALSE(fetch::host_matches_suffix("example.com.evil.org", "example.com"));
    EXPECT_TRUE(fetch::host_matches_suffix("anything", "*"));
    // |32 碰撞回归：'@'(0x40)|32 == '`'(0x60)，tolower 比较不应误判相等
    EXPECT_FALSE(fetch::host_matches_suffix("a@b.com", "a`b.com"));
    // 空后缀：不匹配任何 host（包括以点结尾的 FQDN 也不会误命中）
    EXPECT_FALSE(fetch::host_matches_suffix("example.com.", ""));
    EXPECT_FALSE(fetch::host_matches_suffix("example.com", ""));
}

TEST(UrlTools, RouteMatch)
{
    EXPECT_TRUE(fetch::url_matches_route("http://example.com/", "example.com"));
    EXPECT_TRUE(fetch::url_matches_route("http://a.example.com/x", "example.com"));
    EXPECT_FALSE(fetch::url_matches_route("http://example.com/", "")); // 空规则永不命中
    EXPECT_FALSE(fetch::url_matches_route("http://example.com./", "")); // FQDN 带点也不命中
    EXPECT_TRUE(fetch::url_matches_route("http://example.com/", "*"));
    EXPECT_TRUE(fetch::url_matches_route("http://example.com/a/b", "/a"));
    EXPECT_FALSE(fetch::url_matches_route("http://example.com/ab", "/a/b"));
}

// ---- Windows ProxyServer 注册表值解析（仅 http 段）----
#ifdef _WIN32
TEST(WindowsProxyServer, Parse)
{
    // 单一值 → http 代理
    auto p = fetch::parse_windows_proxy_server(L"127.0.0.1:7890");
    ASSERT_TRUE(p);
    EXPECT_EQ(p->host, "127.0.0.1");
    EXPECT_EQ(p->port, 7890);

    // 多协议形式 → 取 http 段
    p = fetch::parse_windows_proxy_server(L"http=10.0.0.1:8080;https=10.0.0.1:8443");
    ASSERT_TRUE(p);
    EXPECT_EQ(p->host, "10.0.0.1");
    EXPECT_EQ(p->port, 8080);

    // 协议名大小写不敏感
    p = fetch::parse_windows_proxy_server(L"HTTP=1.2.3.4:3128");
    ASSERT_TRUE(p);
    EXPECT_EQ(p->host, "1.2.3.4");
    EXPECT_EQ(p->port, 3128);

    // 只有 socks 段 → 无 http → 不用代理
    EXPECT_FALSE(fetch::parse_windows_proxy_server(L"socks=127.0.0.1:1080"));

    // IPv6
    p = fetch::parse_windows_proxy_server(L"[::1]:8080");
    ASSERT_TRUE(p);
    EXPECT_EQ(p->host, "::1");
    EXPECT_EQ(p->port, 8080);

    // 无端口 → 默认 8080
    p = fetch::parse_windows_proxy_server(L"proxy.local");
    ASSERT_TRUE(p);
    EXPECT_EQ(p->port, 8080);

    // 非法
    EXPECT_FALSE(fetch::parse_windows_proxy_server(L""));
    EXPECT_FALSE(fetch::parse_windows_proxy_server(L"http=h:0"));
    EXPECT_FALSE(fetch::parse_windows_proxy_server(L"http=h:70000"));
    EXPECT_FALSE(fetch::parse_windows_proxy_server(L"http=h:abc"));
}
#endif

} // namespace
