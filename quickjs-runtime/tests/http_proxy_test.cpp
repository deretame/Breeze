// M-P1/M-P2 HTTP forward proxy 验收测试（docs/proxy_test_plan.md §4.3）
//
// 覆盖：absolute-form 转发（http 目标）/ CONNECT 隧道（https 目标）/
//   Basic 认证对错（407 → TypeError）/ 选路（命中走代理、未命中直连）/
//   CONNECT 非 200 映射 / 握手中止（AbortError）/ 凭据只在发往代理的连接上。
#include <gtest/gtest.h>
#include <qjsbind/qjsbind.hpp>
#include <qjsbind/web/web.hpp>
#include <fetch/client.hpp>
#include <fetch/beast_transport.hpp>
#include "http_proxy_server.hpp"
#include "tls_echo_server.hpp"
#include "wpt_server.hpp"

#include <boost/asio/ssl.hpp>
#include <boost/beast/core.hpp>
#include <boost/beast/http.hpp>

#include <chrono>
#include <fstream>
#include <iterator>
#include <thread>

using namespace qjs;

namespace {

struct HttpProxyFixture : ::testing::Test {
    Runtime rt;
    std::unique_ptr<fetch::Client> client; // 先于 ctx 声明：析构逆序（ctx 先），
                                           // fetch 全局持有的 Client& 在 ctx 生命周期内有效
    Context ctx = rt.main_context();
    qjsbind::net::wpt::WptTestServer wpt{std::string("third_party/wpt")}; // 转发目标（http）
    std::string base;

    // route_all：true = 实例级代理（全走代理）；false = 不配代理（全直连）
    void init(const qjsbind::net::wpt::HttpProxyTestServer::Options& opt = {},
              std::optional<std::pair<std::string, std::string>> proxy_auth = std::nullopt,
              bool route_all = true, uint16_t proxy_port = 0)
    {
        auto transport = std::make_shared<fetch::BeastTransport>();
        base = wpt.base_url();
        proxy_ = std::make_shared<qjsbind::net::wpt::HttpProxyTestServer>(opt);
        proxy_->start();
        const uint16_t port = proxy_port ? proxy_port : proxy_->port();
        fetch::Options opts;
        if (route_all)
            opts.proxy = fetch::Proxy::http(proxy_->host(), port, proxy_auth);
        client = std::make_unique<fetch::Client>(transport, std::move(opts));
        qjsbind::web::install_web_apis(ctx, *client);
    }

    std::shared_ptr<qjsbind::net::wpt::HttpProxyTestServer> proxy_;
};

// http 目标经代理（absolute-form 转发）：fetch 取回 body；代理记录 absolute-form
TEST_F(HttpProxyFixture, HttpViaProxy)
{
    qjsbind::net::wpt::HttpProxyTestServer::Options opt;
    opt.record_targets = true;
    init(opt);
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py', {method: 'POST', body: 'via http proxy'})"
        ".then(x => { globalThis.__r = x.status + '|' + x.headers.get('X-Request-Method');"
        " return x.text(); })"
        ".then(t => { globalThis.__r += '|' + t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<std::string>(), "200|POST|via http proxy");
    // 代理确实收到请求：目标 = wpt 服务器；请求行是 absolute-form
    const auto targets = proxy_->targets();
    ASSERT_EQ(targets.size(), 1u);
    EXPECT_FALSE(targets[0].is_connect);
    EXPECT_EQ(targets[0].host, "127.0.0.1");
    EXPECT_EQ(targets[0].port, static_cast<uint16_t>(std::stoi(base.substr(base.rfind(':') + 1))));
    EXPECT_EQ(targets[0].target_line.substr(0, 7), "http://");
}

// https 目标经代理（CONNECT 隧道）：TLS handshake 在隧道上完成；
// 证书校验按目标 host（自签证书 + extra_trust_pem 注入信任，SAN 含 IP:127.0.0.1）
TEST_F(HttpProxyFixture, HttpsOverConnect)
{
    std::string cert;
    for (const char* p : {"tests/certs/server.crt", "../tests/certs/server.crt",
                          "../../tests/certs/server.crt"}) {
        std::ifstream f(p);
        if (f) {
            cert.assign(std::istreambuf_iterator<char>(f), std::istreambuf_iterator<char>());
            break;
        }
    }
    ASSERT_FALSE(cert.empty());
    wpt_test::TlsEchoServer tls;
    auto transport = std::make_shared<fetch::BeastTransport>(
        fetch::TlsOptions{true, {cert}});
    qjsbind::net::wpt::HttpProxyTestServer::Options opt;
    opt.record_targets = true;
    proxy_ = std::make_shared<qjsbind::net::wpt::HttpProxyTestServer>(opt);
    proxy_->start();
    const fetch::HttpProxy p{proxy_->host(), proxy_->port(), std::nullopt};
    client = std::make_unique<fetch::Client>(transport, fetch::Options{.proxy = fetch::Proxy::http(p.host, p.port)});
    qjsbind::web::install_web_apis(ctx, *client);
    Value r = ctx.eval(
        "fetch('" + tls.base_url() + "/echo', {method: 'POST', body: 'tls over connect'})"
        ".then(x => { globalThis.__h = x.status + '|' + x.headers.get('content-type');"
        " return x.text(); })"
        ".then(t => { globalThis.__h += '|' + t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__h").as<std::string>(),
              "200|text/plain|tls over connect");
    // 代理记录 CONNECT 目标（TlsEchoServer 端口）
    const auto targets = proxy_->targets();
    ASSERT_EQ(targets.size(), 1u);
    EXPECT_TRUE(targets[0].is_connect);
    EXPECT_EQ(targets[0].host, "127.0.0.1");
    EXPECT_EQ(targets[0].port, tls.port());
}

// Basic 认证：正确凭据通过；错误凭据 → 代理 407 → fetch reject TypeError
TEST_F(HttpProxyFixture, BasicAuth)
{
    qjsbind::net::wpt::HttpProxyTestServer::Options opt;
    opt.require_auth = std::make_pair(std::string("bob"), std::string("passw0rd"));
    init(opt, std::make_pair(std::string("bob"), std::string("passw0rd")));
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py', {method: 'POST', body: 'authed'})"
        ".then(x => x.text()).then(t => { globalThis.__ok = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__ok").as<std::string>(), "authed");

    // 错误凭据（另一个代理服务器实例）
    auto bad = std::make_shared<qjsbind::net::wpt::HttpProxyTestServer>(opt);
    bad->start();
    fetch::HttpProxy badp{bad->host(), bad->port(),
                          std::make_pair(std::string("bob"), std::string("wrong"))};
    auto bad_transport = std::make_shared<fetch::BeastTransport>();
    fetch::Client bad_client{bad_transport,
                              fetch::Options{.proxy = fetch::Proxy::http(badp.host, badp.port, badp.auth)}};
    auto ctx2 = rt.main_context();
    qjsbind::web::install_web_apis(ctx2, bad_client);
    Value r2 = ctx2.eval(
        "fetch('" + base + "/echo-content.py', {method: 'POST', body: 'x'})"
        ".then(() => { globalThis.__bad = 'no'; })"
        ".catch(e => { globalThis.__bad = e.name; }); 'ok'");
    ASSERT_FALSE(r2.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx2.eval("__bad").as<std::string>(), "TypeError");
}

// 缺凭据：代理回 407 → fetch reject TypeError（与 curl 的失败语义一致）
TEST_F(HttpProxyFixture, MissingCredentials)
{
    qjsbind::net::wpt::HttpProxyTestServer::Options opt;
    opt.require_auth = std::make_pair(std::string("bob"), std::string("passw0rd"));
    init(opt); // 不带凭据
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py')"
        ".then(() => { globalThis.__r = 'no'; })"
        ".catch(e => { globalThis.__r = e.name; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<std::string>(), "TypeError");
}

// 选路：命中策略走代理（代理记录目标）；未命中直连（代理无记录）
TEST_F(HttpProxyFixture, Routing)
{
    qjsbind::net::wpt::HttpProxyTestServer::Options opt;
    opt.record_targets = true;
    auto transport = std::make_shared<fetch::BeastTransport>();
    client = std::make_unique<fetch::Client>(transport);
    base = wpt.base_url();
    proxy_ = std::make_shared<qjsbind::net::wpt::HttpProxyTestServer>(opt);
    proxy_->start();
    const fetch::HttpProxy p{proxy_->host(), proxy_->port(), std::nullopt};
    // 策略：仅 /via-proxy 路径走代理（实例级 URL 分流配置）
    fetch::Options opts;
    opts.proxy_routes = {{"/via-proxy", fetch::Proxy::http(p.host, p.port)}};
    client = std::make_unique<fetch::Client>(transport, std::move(opts));
    qjsbind::web::install_web_apis(ctx, *client);
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py')" // 未命中 → 直连
        ".then(x => x.text()).then(t => { globalThis.__direct = t; });"
        "fetch('" + base + "/via-proxy')" // 命中 → 代理
        ".then(x => x.text()).then(t => { globalThis.__tunnel = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__direct").as<std::string>(), ""); // echo-content.py GET 回显空 body
    EXPECT_EQ(ctx.eval("__tunnel").as<std::string>(), "404 not found: /via-proxy");
    // 只有走代理的请求到达代理
    const auto targets = proxy_->targets();
    ASSERT_EQ(targets.size(), 1u);
    EXPECT_EQ(targets[0].host, "127.0.0.1");
}

// CONNECT 非 200（502）：代理拒绝隧道 → fetch reject TypeError（与 SOCKS5 REP 同语义）；
// 错误信息含失败响应 body 摘要（L5，测试代理回 "connect refused by policy"）
TEST_F(HttpProxyFixture, ConnectRejected)
{
    // 必须走 https 目标才会 CONNECT（http 目标的 502 是普通响应，照常返回）
    wpt_test::TlsEchoServer tls;
    qjsbind::net::wpt::HttpProxyTestServer::Options opt;
    opt.fail_connect = true;
    init(opt);
    Value r = ctx.eval(
        "fetch('" + tls.base_url() + "/echo')"
        ".then(() => { globalThis.__r = 'no'; })"
        ".catch(e => { globalThis.__r = e.name + '|' + e.message; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    const std::string got = ctx.eval("__r").as<std::string>();
    EXPECT_TRUE(got.rfind("TypeError|", 0) == 0) << got;
    EXPECT_NE(got.find("connect refused by policy"), std::string::npos) << got;
}

// 握手中止：代理延迟 CONNECT 200 响应，abort → AbortError
TEST_F(HttpProxyFixture, AbortDuringConnect)
{
    wpt_test::TlsEchoServer tls;
    qjsbind::net::wpt::HttpProxyTestServer::Options opt;
    opt.connect_delay_ms = 800;
    init(opt);
    Value r = ctx.eval(
        "var ac = new AbortController();"
        "var p = fetch('" + tls.base_url() + "/echo', {signal: ac.signal})"
        ".then(() => { globalThis.__a = 'no'; })"
        ".catch(e => { globalThis.__a = e.name; });"
        "setTimeout(() => ac.abort(), 50); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__a").as<std::string>(), "AbortError");
}

// 凭据只出现在发往代理的连接上：代理校验通过（收到 Proxy-Authorization），
// 转发给目标的请求已剥离（hop-by-hop）
TEST_F(HttpProxyFixture, CredentialsNotForwarded)
{
    qjsbind::net::wpt::HttpProxyTestServer::Options opt;
    opt.require_auth = std::make_pair(std::string("bob"), std::string("passw0rd"));
    opt.record_targets = true;
    init(opt, std::make_pair(std::string("bob"), std::string("passw0rd")));
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py', {method: 'POST', body: 'sealed'})"
        ".then(x => x.text()).then(t => { globalThis.__ok = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__ok").as<std::string>(), "sealed");
    const auto targets = proxy_->targets();
    ASSERT_EQ(targets.size(), 1u);
    // 客户端确实把凭据发给了代理（Basic 校验通过才会转发）
    EXPECT_TRUE(targets[0].fwd_has_proxy_auth);
    // 转发给目标的请求不含 Proxy-Authorization（剥离发生在代理侧，见服务器实现）
}

// IPv6 字面量目标：absolute-form 请求行必须带方括号（RFC 3986 §3.2.2；
// ::1:61001 无目标服务 → 代理回 400 响应，但已记录请求行，断言格式）
TEST_F(HttpProxyFixture, IPv6AbsoluteForm)
{
    qjsbind::net::wpt::HttpProxyTestServer::Options opt;
    opt.record_targets = true;
    init(opt);
    Value r = ctx.eval(
        "fetch('http://[::1]:61001/x')"
        ".then(x => { globalThis.__s = x.status; return x.text(); })"
        ".then(t => { globalThis.__t = t; return 'ok'; })"
        ".catch(e => { globalThis.__t = 'rejected'; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__s").as<int>(), 400); // 目标不可达（代理转发的 4xx 照常返回）
    const auto targets = proxy_->targets();
    ASSERT_EQ(targets.size(), 1u);
    EXPECT_FALSE(targets[0].is_connect);
    EXPECT_EQ(targets[0].target_line, "http://[::1]:61001/x"); // 请求行带方括号
}

// IPv6 字面量目标：CONNECT target 必须带方括号（[::1]:61001 无目标服务 → 502 →
// TypeError；代理记录 CONNECT 行，断言格式）
TEST_F(HttpProxyFixture, IPv6ConnectTarget)
{
    qjsbind::net::wpt::HttpProxyTestServer::Options opt;
    opt.record_targets = true;
    init(opt);
    Value r = ctx.eval(
        "fetch('https://[::1]:61001/x')"
        ".then(() => { globalThis.__r = 'no'; })"
        ".catch(e => { globalThis.__r = e.name; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<std::string>(), "TypeError"); // CONNECT 被拒
    const auto targets = proxy_->targets();
    ASSERT_EQ(targets.size(), 1u);
    EXPECT_TRUE(targets[0].is_connect);
    EXPECT_EQ(targets[0].target_line, "[::1]:61001");
}

} // namespace
