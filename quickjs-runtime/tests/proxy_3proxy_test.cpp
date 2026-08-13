// 3proxy 对打验收测试（docs/proxy_test_plan.md §3）
//
// 与 tests/socks5_test.cpp / http_proxy_test.cpp 的用例一一对应，但代理换成
// 真实 3proxy 进程（第三方对打，消除「mini 服务器是自家人写的」盲区）：
//   11080 SOCKS5 无认证 / 11081 SOCKS5 user-pass / 13128 HTTP 代理（含 CONNECT）
//   / 13129 HTTP 代理 Basic 认证。
// 3proxy 生命周期由测试驱动脚本管理（scripts/test.py --with-3proxy 拉起，
// 跨平台启停逻辑都在 Python 侧）；本文件只认环境变量 QJS_3PROXY_UP=1
// （表示 3proxy 已在运行），未设置 → GTEST_SKIP。
// 基准对照：P1/C7 用 _popen("curl … -s") 抓同一 URL 的 curl 输出做字节对照；
// curl 不可用时退化为与直连 fetch 结果对照。
#include <gtest/gtest.h>
#include <log.hpp>
#include <qjsbind/qjsbind.hpp>
#include <qjsbind/web/web.hpp>
#include <fetch/client.hpp>
#include <fetch/beast_transport.hpp>
#include "tls_echo_server.hpp"
#include "wpt_server.hpp"

#include <boost/asio.hpp>
#include <boost/asio/ssl.hpp>

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iterator>
#include <string>
#include <thread>

using namespace qjs;

namespace {

// ---- 3proxy 对打 fixture（3proxy 进程由 scripts/test.py 拉起，此处只消费）----
class Proxy3proxyTest : public ::testing::Test {
protected:
    static void SetUpTestSuite()
    {
        const char* env = std::getenv("QJS_3PROXY_UP");
        if (!env || std::string(env) != "1") {
            GTEST_SKIP() << "QJS_3PROXY_UP=1 未设置，跳过 3proxy 对打测试"
                            "（由 scripts/test.py --with-3proxy 拉起）";
            return;
        }
        ASSERT_TRUE(wait_port(11080, std::chrono::seconds(5)))
            << "QJS_3PROXY_UP=1 但 SOCKS5 11080 不可连接（3proxy 未在运行？）";
    }

    // 轮询 TCP 端口直到可连接
    static bool wait_port(uint16_t port, std::chrono::seconds timeout)
    {
        const auto deadline = std::chrono::steady_clock::now() + timeout;
        while (std::chrono::steady_clock::now() < deadline) {
            boost::asio::io_context io;
            boost::asio::ip::tcp::socket s(io);
            boost::system::error_code ec;
            s.connect(boost::asio::ip::tcp::endpoint(
                          boost::asio::ip::address_v4::loopback(), port),
                      ec);
            if (!ec)
                return true;
            std::this_thread::sleep_for(std::chrono::milliseconds(50));
        }
        return false;
    }

    // 同步执行命令并抓 stdout（curl 基准用）
    static std::string run_cmd(const std::string& cmdline)
    {
        std::string out;
        FILE* f = _popen(cmdline.c_str(), "r");
        if (!f)
            return out;
        char buf[4096];
        size_t n;
        while ((n = fread(buf, 1, sizeof(buf), f)) > 0)
            out.append(buf, n);
        _pclose(f);
        return out;
    }

    // curl 是否可用（不可用 → 基准退化为直连对照）
    static bool curl_available()
    {
        static const bool ok = [] {
            FILE* f = _popen("curl --version >nul 2>nul", "r");
            if (!f)
                return false;
            const int rc = _pclose(f);
            return rc == 0;
        }();
        return ok;
    }

    // curl 基准：经给定代理参数抓同一 URL 的响应体
    static std::string curl_bench(const std::string& proxy_args, const std::string& url)
    {
        return run_cmd("curl -s --max-time 15 " + proxy_args + " \"" + url +
                       "\" -d x");
    }

    // 直连基准（curl 不可用时对照）：进程内直连 fetch 取 body
    static std::string direct_bench(const std::string& url)
    {
        Runtime rt;
        Context ctx = rt.main_context();
        auto transport = std::make_shared<fetch::BeastTransport>();
        fetch::Client client{transport};
        qjsbind::web::install_web_apis(ctx, client);
        Value r = ctx.eval(
            "fetch('" + url + "', {method:'POST', body:'x'}).then(x=>x.text())"
            ".then(t => { globalThis.__d = t; }); 'ok'");
        rt.run_to_completion();
        return ctx.eval("__d").as<std::string>();
    }

    // 读自签证书（同 socks5_test.cpp）
    static std::string read_cert()
    {
        for (const char* p : {"tests/certs/server.crt", "../tests/certs/server.crt",
                              "../../tests/certs/server.crt"}) {
            std::ifstream f(p);
            if (f)
                return std::string(std::istreambuf_iterator<char>(f),
                                   std::istreambuf_iterator<char>());
        }
        return {};
    }

    Runtime rt;
    Context ctx = rt.main_context();
    qjsbind::net::wpt::WptTestServer wpt{std::string("third_party/wpt")};
    std::string base = wpt.base_url();

    // 安装 web APIs（client 的代理经 Options::proxy 在构造时配置）
    void install_client(fetch::Client& client)
    {
        qjsbind::web::install_web_apis(ctx, client);
    }
};

// P1 (C1)：SOCKS5 无认证，http 目标 —— body 与 curl 基准字节一致
TEST_F(Proxy3proxyTest, SocksNoAuthHttp)
{
    auto transport = std::make_shared<fetch::BeastTransport>();
    fetch::Client client{transport, fetch::Options{.proxy = fetch::Proxy::socks5("127.0.0.1", 11080)}};
    install_client(client);
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py', {method:'POST', body:'x'})"
        ".then(x => { globalThis.__s = x.status; return x.text(); })"
        ".then(t => { globalThis.__t = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__s").as<int>(), 200);
    const std::string via = ctx.eval("__t").as<std::string>();
    ASSERT_EQ(via, "x"); // 回显 body
    // curl 基准（同一 URL 经 11080）；curl 不可用 → 直连对照
    std::string bench;
    if (curl_available())
        bench = curl_bench("--socks5 127.0.0.1:11080", base + "/echo-content.py");
    else
        bench = direct_bench(base + "/echo-content.py");
    EXPECT_EQ(via, bench) << "与 curl 基准体不一致（3proxy 行为差异？）";
}

// P2 (C2)：SOCKS5 user/pass 正确凭据
TEST_F(Proxy3proxyTest, SocksUserPass)
{
    auto transport = std::make_shared<fetch::BeastTransport>();
    fetch::Client client{transport,
                         fetch::Options{.proxy = fetch::Proxy::socks5(
                             "127.0.0.1", 11081,
                             std::make_pair(std::string("alice"), std::string("s3cret")))}};
    install_client(client);
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py', {method:'POST', body:'authed'})"
        ".then(x => x.text()).then(t => { globalThis.__ok = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__ok").as<std::string>(), "authed");
}

// P3 (C3)：SOCKS5 错误凭据 → fetch reject TypeError（curl exit≠0 同语义）
TEST_F(Proxy3proxyTest, SocksWrongCredentials)
{
    auto transport = std::make_shared<fetch::BeastTransport>();
    fetch::Client client{transport,
                         fetch::Options{.proxy = fetch::Proxy::socks5(
                             "127.0.0.1", 11081,
                             std::make_pair(std::string("alice"), std::string("wrong")))}};
    install_client(client);
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py')"
        ".then(() => { globalThis.__r = 'no'; })"
        ".catch(e => { globalThis.__r = e.name; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<std::string>(), "TypeError");
}

// P4 (C4)：URL host=localhost（域名）→ 3proxy 解析（ATYP=0x03，日志可见域名）
TEST_F(Proxy3proxyTest, SocksDomainHost)
{
    auto transport = std::make_shared<fetch::BeastTransport>();
    fetch::Client client{transport, fetch::Options{.proxy = fetch::Proxy::socks5("127.0.0.1", 11080)}};
    install_client(client);
    const std::string port = base.substr(base.rfind(':') + 1);
    Value r = ctx.eval(
        "fetch('http://localhost:" + port + "/echo-content.py',"
        "{method:'POST', body:'dom'}).then(x => x.text())"
        ".then(t => { globalThis.__ok = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__ok").as<std::string>(), "dom");
}

// P5 (C5)：URL host=127.0.0.1（IPv4 字面量）→ ATYP=0x01
TEST_F(Proxy3proxyTest, SocksIpv4Host)
{
    auto transport = std::make_shared<fetch::BeastTransport>();
    fetch::Client client{transport, fetch::Options{.proxy = fetch::Proxy::socks5("127.0.0.1", 11080)}};
    install_client(client);
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py', {method:'POST', body:'v4'})"
        ".then(x => x.text()).then(t => { globalThis.__ok = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__ok").as<std::string>(), "v4");
}

// P6 (C6)：https over SOCKS5 隧道（3proxy CONNECT + TLS handshake）
TEST_F(Proxy3proxyTest, HttpsOverSocks5)
{
    const std::string cert = read_cert();
    ASSERT_FALSE(cert.empty());
    wpt_test::TlsEchoServer tls;
    auto transport = std::make_shared<fetch::BeastTransport>(
        fetch::TlsOptions{true, {cert}});
    fetch::Client client{transport, fetch::Options{.proxy = fetch::Proxy::socks5("127.0.0.1", 11080)}};
    install_client(client);
    Value r = ctx.eval(
        "fetch('" + tls.base_url() + "/echo', {method:'POST', body:'tls via 3proxy'})"
        ".then(x => { globalThis.__h = x.status + '|' + x.headers.get('content-type');"
        " return x.text(); })"
        ".then(t => { globalThis.__h += '|' + t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__h").as<std::string>(),
              "200|text/plain|tls via 3proxy");
}

// P7 (C11)：不可达目标 → 3proxy 回 REP≠0 → fetch reject TypeError
//（10.255.255.1 会超时等待；用 127.0.0.1:9（本机未监听）→ 立即 REP 0x05）
TEST_F(Proxy3proxyTest, SocksUnreachable)
{
    auto transport = std::make_shared<fetch::BeastTransport>();
    fetch::Client client{transport, fetch::Options{.proxy = fetch::Proxy::socks5("127.0.0.1", 11080)}};
    install_client(client);
    Value r = ctx.eval(
        "fetch('http://127.0.0.1:9/x')"
        ".then(() => { globalThis.__r = 'no'; })"
        ".catch(e => { globalThis.__r = e.name; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<std::string>(), "TypeError");
}

// P8 (C12)：代理端口未监听 → fetch reject TypeError（连接拒绝）
TEST_F(Proxy3proxyTest, ProxyNotListening)
{
    auto transport = std::make_shared<fetch::BeastTransport>();
    fetch::Client client{transport, fetch::Options{.proxy = fetch::Proxy::socks5("127.0.0.1", 19999)}};
    install_client(client);
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py')"
        ".then(() => { globalThis.__r = 'no'; })"
        ".catch(e => { globalThis.__r = e.name; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<std::string>(), "TypeError");
}

// C7：HTTP 代理无认证，http 目标（absolute-form 转发）—— body 与 curl 基准一致
TEST_F(Proxy3proxyTest, HttpProxyHttpTarget)
{
    auto transport = std::make_shared<fetch::BeastTransport>();
    fetch::Client client{transport, fetch::Options{.proxy = fetch::Proxy::http("127.0.0.1", 13128)}};
    install_client(client);
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py', {method:'POST', body:'x'})"
        ".then(x => { globalThis.__s = x.status; return x.text(); })"
        ".then(t => { globalThis.__t = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__s").as<int>(), 200);
    const std::string via = ctx.eval("__t").as<std::string>();
    ASSERT_EQ(via, "x");
    std::string bench;
    if (curl_available())
        bench = curl_bench("-x http://127.0.0.1:13128", base + "/echo-content.py");
    else
        bench = direct_bench(base + "/echo-content.py");
    EXPECT_EQ(via, bench) << "与 curl 基准体不一致";
}

// C8：HTTP 代理无认证，https 目标（CONNECT 隧道）
TEST_F(Proxy3proxyTest, HttpProxyHttpsTarget)
{
    const std::string cert = read_cert();
    ASSERT_FALSE(cert.empty());
    wpt_test::TlsEchoServer tls;
    auto transport = std::make_shared<fetch::BeastTransport>(
        fetch::TlsOptions{true, {cert}});
    fetch::Client client{transport, fetch::Options{.proxy = fetch::Proxy::http("127.0.0.1", 13128)}};
    install_client(client);
    Value r = ctx.eval(
        "fetch('" + tls.base_url() + "/echo', {method:'POST', body:'tls via connect'})"
        ".then(x => { globalThis.__h = x.status + '|' + x.headers.get('content-type');"
        " return x.text(); })"
        ".then(t => { globalThis.__h += '|' + t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__h").as<std::string>(),
              "200|text/plain|tls via connect");
}

// C9：HTTP 代理 Basic 认证（bob:passw0rd）
TEST_F(Proxy3proxyTest, HttpProxyBasicAuth)
{
    auto transport = std::make_shared<fetch::BeastTransport>();
    fetch::Client client{transport,
                         fetch::Options{.proxy = fetch::Proxy::http(
                             "127.0.0.1", 13129,
                             std::make_pair(std::string("bob"), std::string("passw0rd")))}};
    install_client(client);
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py', {method:'POST', body:'authed'})"
        ".then(x => x.text()).then(t => { globalThis.__ok = t; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__ok").as<std::string>(), "authed");
}

// C10：HTTP 代理缺凭据 → 407 → fetch reject TypeError（curl 见 407 同语义）
TEST_F(Proxy3proxyTest, HttpProxyMissingCredentials)
{
    auto transport = std::make_shared<fetch::BeastTransport>();
    fetch::Client client{transport, fetch::Options{.proxy = fetch::Proxy::http("127.0.0.1", 13129)}};
    install_client(client);
    Value r = ctx.eval(
        "fetch('" + base + "/echo-content.py')"
        ".then(() => { globalThis.__r = 'no'; })"
        ".catch(e => { globalThis.__r = e.name; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<std::string>(), "TypeError");
}

} // namespace
