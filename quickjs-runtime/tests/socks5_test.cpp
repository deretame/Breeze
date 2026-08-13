// M4 SOCKS5 代理验收测试（设计文档 §3.4 / §5.7）
//
// 覆盖：无认证握手 / user-pass（RFC 1929）/ ATYP 域名与 IPv4 / REP 错误码 /
//   选路（命中走隧道、未命中直连）/ 握手中止（AbortError）/ https over tunnel。
#include <gtest/gtest.h>
#include <qjsbind/qjsbind.hpp>
#include <qjsbind/web/web.hpp>
#include <fetch/client.hpp>
#include <fetch/beast_transport.hpp>
#include "socks5_server.hpp"
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

struct Socks5Fixture : ::testing::Test {
    Runtime rt;
    std::unique_ptr<fetch::Client> client; // 先于 ctx 声明：析构逆序（ctx 先），
                                           // fetch 全局持有的 Client& 在 ctx 生命周期内有效
    Context ctx = rt.main_context();
    qjsbind::net::wpt::WptTestServer wpt{std::string("third_party/wpt")}; // 隧道目标（http）
    std::string base;

    // route_all：true = 实例级代理（全走代理）；false = 不配代理（全直连）
    void init(const qjsbind::net::wpt::Socks5TestServer::Options& opt = {},
              std::optional<std::pair<std::string, std::string>> proxy_auth = std::nullopt,
              bool route_all = true, uint16_t proxy_port = 0)
    {
        auto transport = std::make_shared<fetch::BeastTransport>();
        base = wpt.base_url();
        proxy_ = std::make_shared<qjsbind::net::wpt::Socks5TestServer>(opt);
        proxy_->start();
        const uint16_t port = proxy_port ? proxy_port : proxy_->port();
        fetch::Options opts;
        if (route_all)
            opts.proxy = fetch::Proxy::socks5(proxy_->host(), port, proxy_auth);
        client = std::make_unique<fetch::Client>(transport, std::move(opts));
        qjsbind::web::install_web_apis(ctx, *client);
    }

    std::shared_ptr<qjsbind::net::wpt::Socks5TestServer> proxy_;
};

// 无认证：fetch 经 SOCKS5 隧道 → 目标服务器内容
TEST_F(Socks5Fixture, NoAuth)
{
    init();
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py', {method: 'POST', body: 'via socks5'})"
        ".then(x => { globalThis.__r = x.status + '|' + x.headers.get('X-Request-Method');"
        " return x.text(); })"
        ".then(t => { globalThis.__r += '|' + t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<std::string>(), "200|POST|via socks5");
}

// user-pass：正确凭据通过；错误凭据 → fetch reject TypeError
TEST_F(Socks5Fixture, UserPass)
{
    qjsbind::net::wpt::Socks5TestServer::Options opt;
    opt.require_auth = true;
    opt.username = "alice";
    opt.password = "s3cret";
    init(opt, std::make_pair(std::string("alice"), std::string("s3cret")));
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py', {method: 'POST', body: 'authed'})"
        ".then(x => x.text()).then(t => { globalThis.__ok = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__ok").as<std::string>(), "authed");

    // 错误凭据（另一个代理服务器实例）
    qjsbind::net::wpt::Socks5TestServer::Options bad_opt = opt;
    auto bad = std::make_shared<qjsbind::net::wpt::Socks5TestServer>(bad_opt);
    bad->start();
    fetch::Socks5Proxy badp{bad->host(), bad->port(),
                            std::make_pair(std::string("alice"), std::string("wrong"))};
    auto bad_transport = std::make_shared<fetch::BeastTransport>();
    fetch::Client bad_client{bad_transport,
                              fetch::Options{.proxy = fetch::Proxy::socks5(badp.host, badp.port, badp.auth)}};
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

// ATYP：域名（localhost）→ 0x03；IPv4 字面量（127.0.0.1）→ 0x01
TEST_F(Socks5Fixture, Atyp)
{
    qjsbind::net::wpt::Socks5TestServer::Options opt;
    opt.record_targets = true;
    init(opt);
    // 域名路径：URL host = localhost（代理解析）
    std::string host = "localhost";
    // 从 base 提取端口
    const std::string port = base.substr(base.rfind(':') + 1);
    Value r = ctx.eval(
        "fetch('http://localhost:" + port + "/echo-content.py',"
        "{method: 'POST', body: 'dom'}).then(x => x.text())"
        ".then(t => { globalThis.__res0 = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__res0").as<std::string>(), "dom");
    // IPv4 字面量
    r = ctx.eval(
        "fetch('" + base + "/echo-content.py', {method: 'POST', body: 'v4'})"
        ".then(x => x.text()).then(t => { globalThis.__t = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__t").as<std::string>(), "v4");
    // 服务器记录的目标：域名 / IPv4
    const auto targets = proxy_->targets();
    ASSERT_EQ(targets.size(), 2u);
    EXPECT_EQ(targets[0].first, "localhost");
    EXPECT_EQ(targets[1].first, "127.0.0.1");
    EXPECT_EQ(targets[0].second, static_cast<uint16_t>(std::stoi(port)));
}

// REP 错误码：代理拒绝 → fetch reject TypeError
TEST_F(Socks5Fixture, RepError)
{
    qjsbind::net::wpt::Socks5TestServer::Options opt;
    opt.fail_rep = 0x05; // connection refused
    init(opt);
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py')"
        ".then(() => { globalThis.__r = 'no'; })"
        ".catch(e => { globalThis.__r = e.name; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<std::string>(), "TypeError");
}

// 选路：命中策略走隧道（代理记录目标）；未命中直连（代理无记录）
TEST_F(Socks5Fixture, Routing)
{
    qjsbind::net::wpt::Socks5TestServer::Options opt;
    opt.record_targets = true;
    auto transport = std::make_shared<fetch::BeastTransport>();
    client = std::make_unique<fetch::Client>(transport);
    base = wpt.base_url();
    proxy_ = std::make_shared<qjsbind::net::wpt::Socks5TestServer>(opt);
    proxy_->start();
    const fetch::Socks5Proxy p{proxy_->host(), proxy_->port(), std::nullopt};
    // 策略：仅 /via-proxy 路径走代理（实例级 URL 分流配置）
    fetch::Options opts;
    opts.proxy_routes = {{"/via-proxy", fetch::Proxy::socks5(p.host, p.port)}};
    client = std::make_unique<fetch::Client>(transport, std::move(opts));
    qjsbind::web::install_web_apis(ctx, *client);
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py')" // 未命中 → 直连
        ".then(x => x.text()).then(t => { globalThis.__direct = t; });"
        "fetch('" + base + "/via-proxy')" // 命中 → 隧道
        ".then(x => x.text()).then(t => { globalThis.__tunnel = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__direct").as<std::string>(), ""); // echo-content.py GET 回显空 body
    EXPECT_EQ(ctx.eval("__tunnel").as<std::string>(), "404 not found: /via-proxy");
    // 只有走隧道的请求到达代理
    const auto targets = proxy_->targets();
    ASSERT_EQ(targets.size(), 1u);
    EXPECT_EQ(targets[0].first, "127.0.0.1");
}

// 握手中止：服务器延迟响应 greeting，abort → AbortError
TEST_F(Socks5Fixture, AbortDuringHandshake)
{
    qjsbind::net::wpt::Socks5TestServer::Options opt;
    opt.greet_delay_ms = 800;
    init(opt);
    Value r = ctx.eval(
        "var ac = new AbortController();"
        "var p = fetch('" + base + "/echo-content.py', {signal: ac.signal})"
        ".then(() => { globalThis.__a = 'no'; })"
        ".catch(e => { globalThis.__a = e.name; });"
        "setTimeout(() => ac.abort(), 50); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__a").as<std::string>(), "AbortError");
}

// 超长凭据：user/pass >255 字节 → 抛 invalid_argument（不静默截断，M2）
// → fetch reject TypeError
TEST_F(Socks5Fixture, OversizedCredentialsRejected)
{
    init({}, std::make_pair(std::string(300, 'u'), std::string("p")));
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py')"
        ".then(() => { globalThis.__r = 'no'; })"
        ".catch(e => { globalThis.__r = e.name; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<std::string>(), "TypeError");
}

// https over SOCKS5 隧道：TLS handshake 在隧道上完成；证书校验按目标 host
//（自签证书 + extra_trust_pem 注入信任，SAN 含 IP:127.0.0.1）
TEST_F(Socks5Fixture, HttpsOverTunnel)
{
    // ctest 的 WORKING_DIRECTORY 是 build 目录；手动跑时是仓库根 → 多路径尝试
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
    base = wpt.base_url();
    proxy_ = std::make_shared<qjsbind::net::wpt::Socks5TestServer>();
    proxy_->start();
    const fetch::Socks5Proxy p{proxy_->host(), proxy_->port(), std::nullopt};
    client = std::make_unique<fetch::Client>(
        transport, fetch::Options{.proxy = fetch::Proxy::socks5(p.host, p.port)});
    qjsbind::web::install_web_apis(ctx, *client);
    Value r = ctx.eval(
        "fetch('" + tls.base_url() + "/echo', {method: 'POST', body: 'tls over socks5'})"
        ".then(x => { globalThis.__h = x.status + '|' + x.headers.get('content-type');"
        " return x.text(); })"
        ".then(t => { globalThis.__h += '|' + t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__h").as<std::string>(),
              "200|text/plain|tls over socks5");
}

} // namespace
