// fetchcore 纯 C++ 直连测试（fetch_cpp_decoupling.md §9 验收标尺）
//
// 不建 JSRuntime：直接 io_context + fetch::Client 打 WptTestServer / 自签
// TLS 服务器 / SOCKS5 测试服务器，验证核心库独立可用性与行为等价：
//   GET/POST、流式读、重定向（follow/error/manual/超限）、解压、SRI、
//   data: URL、abort（stop_token）、用户中间件、多实例共用 io、SOCKS5、
//   HTTPS（extra_trust_pem）。
//
// 驱动方式（§4.2 方案 B）：spawn 上 io 调度器，counting_scope close+join 后
// 用 poll 循环驱动 io（ScopeJoiner；io.run() 会因残留在飞 work 挂起，
// join 语义保证 scope 析构安全，见 stdexec [exec.simple.counting]）。
#include <gtest/gtest.h>
#include <log.hpp>
#include <fetch/client.hpp>
#include <fetch/formdata.hpp>
#include <fetch/multipart.hpp>
#include <fetch/scheduler.hpp>
#include <zlib.h>
#include "wpt_server.hpp"
#include "socks5_server.hpp"
#include "http_proxy_server.hpp"
#include "tls_echo_server.hpp"

#include <stdexec/execution.hpp>

#include <chrono>
#include <cstdio>
#include <exception>
#include <fstream>
#include <iterator>
#include <memory>
#include <string>

#include <atomic>
#include <thread>

namespace {

namespace wpt = qjsbind::net::wpt;

// ---- 驱动辅助：counting_scope 的 join 驱动 ----------------
// counting_scope 析构要求 state 为 joined（stdexec [exec.simple.counting]：
// 仅 spawn 不 join 会 terminate）。close 后 connect 一个 join sender，
// 用 poll 循环驱动 io（不阻塞）直到 join 完成。
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
        if (!joined) // 轮询耗尽：join 未完成（慢机/死锁）——调用方据返回值判失败
            QLOG_WARNING("[fetchcore] warning: scope join 超时（20000 轮 poll）");
        return joined;
    }
};

// ---- 驱动辅助：把协程任务 spawn 上 io 调度器并跑 io.run() ----
// 结果（done/stopped/error）存成员，主线程断言。
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
        // counting_scope 析构要求 state 为 joined——必须 close + join
        // （见 stdexec [exec.simple.counting]；仅 spawn 不 join 会 terminate）。
        // 超时由 ScopeJoiner 告警 + 调用方 done 断言（协程未完成）覆盖。
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

// ---- 最小驱动自检：空协程经 spawn + io.run 应同步完成 ----
// ---- GET/POST 直连 ----
TEST(FetchcoreDirect, GetAndPost)
{
    wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        // GET：200 + reason + 无 body
        fetch::Request get;
        get.url = base + "/echo-content.py";
        fetch::Response r = co_await p.client.fetch(std::move(get));
        EXPECT_EQ(r.status, 200);
        EXPECT_EQ(r.reason, "OK");
        EXPECT_FALSE(r.redirected);
        EXPECT_EQ(r.url, base + "/echo-content.py");
        std::string got1 = co_await fetch::read_all(r); // 先读干再断言（co_await 不进断言宏）
        EXPECT_EQ(got1, "");
        // POST：body 回显
        fetch::Request post;
        post.method = "POST";
        post.url = base + "/echo-content.py";
        post.body = "hello from fetchcore";
        fetch::Response r2 = co_await p.client.fetch(std::move(post));
        EXPECT_EQ(r2.status, 200);
        std::string got2 = co_await fetch::read_all(r2);
        EXPECT_EQ(got2, "hello from fetchcore");
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// ---- 流式读：慢响应分块读 ----
TEST(FetchcoreDirect, StreamingRead)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    std::string body;
    p.run([&]() -> std_exec::task<void> {
        fetch::Request req;
        req.url = server.base_url() + "/slow-response.py?delay=150&content=streamed";
        fetch::Response resp = co_await p.client.fetch(std::move(req));
        EXPECT_EQ(resp.status, 200);
        // 手动分块读（拉模型：read 逐块）
        for (;;) {
            auto block = co_await resp.body->read();
            if (!block)
                break;
            body += *block;
        }
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(body, "streamed");
}

// ---- 重定向 follow / error / manual / 超限 ----
TEST(FetchcoreDirect, RedirectFollow)
{
    wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        // 302 → /status.py?code=200（simple：Location 原样，不附加 query）
        fetch::Request req;
        req.url = base + "/redirect.py?location=/status.py?code=200&redirect_status=302&simple=1";
        fetch::Response resp = co_await p.client.fetch(std::move(req));
        EXPECT_EQ(resp.status, 200);
        EXPECT_TRUE(resp.redirected);
        EXPECT_EQ(resp.url, base + "/status.py?code=200");
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// Location 带大写 scheme（HTTP://…）：WHATWG 解析器归一为小写后跟随
// （review should-fix 1——resolve_url 小写化 scheme，传输层大小写不敏感比较）
TEST(FetchcoreDirect, RedirectSchemeCase)
{
    wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    const std::string port = base.substr(base.rfind(':') + 1);
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        fetch::Request req;
        req.url = base + "/redirect.py?location=HTTP://127.0.0.1:" + port +
                  "/status.py?code=200&redirect_status=302&simple=1";
        fetch::Response resp = co_await p.client.fetch(std::move(req));
        EXPECT_EQ(resp.status, 200);
        EXPECT_EQ(resp.url, base + "/status.py?code=200");
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// resolve_url 归一单测（review sa_20260808_171142：encoded host 保留、
// 前导零端口剥离、非 http/https 不剥离、IPv6 不抛）
TEST(FetchcoreDirect, ResolveUrlNormalization)
{
    // ada（WHATWG）host 解析：pct-encoded 解码后规范化（%41 → 'a'，浏览器一致）
    EXPECT_EQ(fetch::resolve_url("http://%41.example/x", "http://base/"),
              "http://a.example/x");
    // 前导零默认端口剥离（080 == 80，WHATWG 数值语义）
    EXPECT_EQ(fetch::resolve_url("http://h:080/x", "http://base/"),
              "http://h/x");
    // 非默认端口保留；ws://h:80 是 ws 的默认端口（WHATWG 默认端口表）→ 剥离
    EXPECT_EQ(fetch::resolve_url("http://h:8080/x", "http://base/"),
              "http://h:8080/x");
    EXPECT_EQ(fetch::resolve_url("ws://h:80/x", "http://base/"),
              "ws://h/x");
    // IPv6 文字地址：host 跳过小写化、不抛异常
    EXPECT_EQ(fetch::resolve_url("http://[::1]:8080/x", "http://base/"),
              "http://[::1]:8080/x");
    // IPv6 + 默认端口剥离（[::1]:80 → 剥）
    EXPECT_EQ(fetch::resolve_url("http://[::1]:80/x", "http://base/"),
              "http://[::1]/x");
    // 非 ASCII host → IDNA punycode（WHATWG；%C3%A9 与原始 UTF-8 'é' 等价）
    EXPECT_EQ(fetch::resolve_url("http://%C3%A9.example/x", "http://base/"),
              "http://xn--9ca.example/x");
    // 无效 UTF-8 的 pct 序列（%AF 不能独立成字符）→ host 解析失败 → 抛 Error
    EXPECT_THROW(fetch::resolve_url("http://%AF.example/x", "http://base/"),
                 fetch::Error);
    // host 小写化（普通域名）
    EXPECT_EQ(fetch::resolve_url("http://ExAmPle.COM/x", "http://base/"),
              "http://example.com/x");
}

TEST(FetchcoreDirect, RedirectErrorMode)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        fetch::Request req;
        req.url = server.base_url() + "/redirect.py?location=/x&redirect_status=302&simple=1";
        req.redirect = fetch::Request::Redirect::error;
        fetch::Response resp = co_await p.client.fetch(std::move(req));
        (void)resp;
    }());
    ASSERT_TRUE(p.done);
    ASSERT_TRUE(p.error) << "redirect=error 应抛 fetch::Error";
    EXPECT_EQ(p.error_message(), "fetch: redirect mode 为 error");
}

TEST(FetchcoreDirect, RedirectManualMode)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        fetch::Request req;
        req.url = server.base_url() + "/redirect.py?location=/x&redirect_status=301&simple=1";
        req.redirect = fetch::Request::Redirect::manual;
        fetch::Response resp = co_await p.client.fetch(std::move(req));
        // opaqueredirect 哨兵：status==0 且 url 空（绑定层据此构造 opaqueredirect）
        EXPECT_EQ(resp.status, 0);
        EXPECT_TRUE(resp.url.empty());
        EXPECT_FALSE(resp.body);
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

TEST(FetchcoreDirect, RedirectLoopExceeded)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        // 无 simple → 服务器把 count 追加进 Location，无限重定向
        fetch::Request req;
        req.url = server.base_url() + "/redirect.py?location=/redirect.py&redirect_status=302";
        fetch::Response resp = co_await p.client.fetch(std::move(req));
        (void)resp;
    }());
    ASSERT_TRUE(p.done);
    ASSERT_TRUE(p.error);
    EXPECT_EQ(p.error_message(), "fetch: 重定向次数超过 20");
}

// ---- 解压（Accept-Encoding 内建中间件）----
TEST(FetchcoreDirect, Decompress)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    std::string out;
    p.run([&]() -> std_exec::task<void> {
        fetch::Request req;
        req.method = "POST";
        req.url = server.base_url() + "/compress.py?code=gzip";
        req.body = "hello world";
        fetch::Response resp = co_await p.client.fetch(std::move(req));
        out += "gzip:" + co_await fetch::read_all(resp) + ":";
        fetch::Request req2;
        req2.method = "POST";
        req2.url = server.base_url() + "/compress.py?code=br";
        req2.body = "hello brotli";
        fetch::Response resp2 = co_await p.client.fetch(std::move(req2));
        out += "br:" + co_await fetch::read_all(resp2);
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(out, "gzip:hello world:br:hello brotli");
}

// ---- 安全（security review sa_20260808_173002）----
// MEDIUM 1：blocked 端口检查下沉 fetchcore——初始 URL 与 redirect 每跳都执行
TEST(FetchcoreDirect, BlockedPortRejected)
{
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        // 端口 0 也在 #port-blocking 清单（security review LOW：p != -1 拦截）
        fetch::Request r0;
        r0.url = "http://127.0.0.1:0/x";
        bool threw0 = false;
        try {
            (void)co_await p.client.fetch(std::move(r0));
        } catch (const fetch::Error&) {
            threw0 = true;
        }
        EXPECT_TRUE(threw0);
        fetch::Request req;
        req.url = "http://127.0.0.1:22/x"; // SSH 端口在 fetch 规范 #port-blocking 清单
        bool threw = false;
        try {
            (void)co_await p.client.fetch(std::move(req));
        } catch (const fetch::Error& e) {
            threw = std::string(e.what()).find("端口") != std::string::npos;
        }
        EXPECT_TRUE(threw);
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// redirect 到 blocked 端口：恶意 Location → 拒绝（不跟随、不连接）
TEST(FetchcoreDirect, RedirectToBlockedPort)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        fetch::Request req;
        req.url = server.base_url() +
                  "/redirect.py?location=http://127.0.0.1:22/x&redirect_status=302&simple=1";
        bool threw = false;
        try {
            (void)co_await p.client.fetch(std::move(req));
        } catch (const fetch::Error&) {
            threw = true;
        }
        EXPECT_TRUE(threw);
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// MEDIUM 2：解压总量上限（total_limit）——超限抛异常；单块上限（kMaxChunk）
// 由 Decompress 测试（正常流完整读）与总量测试（限内路径）共同覆盖
TEST(FetchcoreDirect, DecompressTotalLimit)
{
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        // 读 BodySource 全文（read_all 只接受 Response，此处内联）
        auto read_all_src = [](fetch::BodySource& s) -> std_exec::task<std::string> {
            std::string out;
            for (;;) {
                auto block = co_await s.read();
                if (!block)
                    break;
                out += *block;
            }
            co_return out;
        };
        // zlib compress2 生成 64 KiB 高压缩 deflate 流（zlib 格式）
        const std::string raw(64 * 1024, 'A');
        uLongf bound = compressBound(static_cast<uLong>(raw.size()));
        std::string comp(bound, '\0');
        uLongf clen = bound;
        const int rc = compress2(reinterpret_cast<Bytef*>(comp.data()), &clen,
                                 reinterpret_cast<const Bytef*>(raw.data()),
                                 static_cast<uLong>(raw.size()), Z_BEST_COMPRESSION);
        EXPECT_EQ(rc, Z_OK);
        comp.resize(clen);
        std::string comp2 = comp; // dec2 需要独立副本（dec1 move 走 comp）
        auto dec = std::make_shared<fetch::DecompressSource>(
            std::make_shared<fetch::BytesBodySource>(std::move(comp)),
            fetch::DecompressSource::Kind::Deflate, 1024); // 总量上限 1 KiB
        bool threw = false;
        try {
            (void)co_await read_all_src(*dec);
        } catch (const std::runtime_error&) {
            threw = true;
        }
        EXPECT_TRUE(threw);
        // 不设上限：同数据完整读出（单块上限不影响总量）
        auto dec2 = std::make_shared<fetch::DecompressSource>(
            std::make_shared<fetch::BytesBodySource>(std::move(comp2)),
            fetch::DecompressSource::Kind::Deflate);
        std::string got = co_await read_all_src(*dec2); // 先读干再断言
        EXPECT_EQ(got, raw);
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// Options.max_decompressed_bytes → AcceptEncodingMiddleware 接线（review
// sa_20260808_175039 nit 2）：低上限 + 大 gzip 响应 → read 抛异常
TEST(FetchcoreDirect, DecompressOptionsLimit)
{
    wpt::WptTestServer server("third_party/wpt");
    fetch::Options opt;
    opt.max_decompressed_bytes = 1024; // 极小上限（默认 256 MiB）
    Probe p(opt);
    p.run([&]() -> std_exec::task<void> {
        fetch::Request req;
        req.method = "POST";
        req.url = server.base_url() + "/compress.py?code=gzip";
        req.body = std::string(64 * 1024, 'x'); // 解压后远超上限
        fetch::Response resp = co_await p.client.fetch(std::move(req));
        bool threw = false;
        try {
            (void)co_await fetch::read_all(resp);
        } catch (const std::runtime_error&) {
            threw = true;
        }
        EXPECT_TRUE(threw);
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
}

// ---- SRI：正确摘要通过；错误摘要 read 阶段抛异常 ----
TEST(FetchcoreDirect, Integrity)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    std::string out;
    p.run([&]() -> std_exec::task<void> {
        fetch::Request ok;
        ok.method = "POST";
        ok.url = server.base_url() + "/echo-content.py";
        ok.body = "hello world";
        // 'hello world' 的 sha384
        ok.integrity = "sha384-/b2OdaZ/KfcBpOBAOF4uI5hjA+oQI5IRr5B/y7g1eLPkF8txzmRu/QgZ3YwIjeG9";
        fetch::Response resp = co_await p.client.fetch(std::move(ok));
        out += co_await fetch::read_all(resp);
        // 错误摘要：fetch 正常返回，读干时抛异常（SRI 消费末端校验）
        fetch::Request bad;
        bad.method = "POST";
        bad.url = server.base_url() + "/echo-content.py";
        bad.body = "hello world";
        bad.integrity = "sha384-" + std::string(64, 'A');
        fetch::Response resp2 = co_await p.client.fetch(std::move(bad));
        out += "|" + co_await fetch::read_all(resp2); // 应抛
    }());
    ASSERT_TRUE(p.done);
    // 错误摘要的 read_all 抛 runtime_error（SRI 不匹配）——通过 error 通道捕获
    EXPECT_TRUE(p.error) << "错误摘要应抛异常";
    // 注意：`out += "|" + co_await read_all(resp2)` 中 co_await 先求值（抛出），
    // "|" 未拼接——out 停在第一个成功读取的 "hello world"
    EXPECT_EQ(out, "hello world");
    EXPECT_EQ(p.error_message(), "integrity: 摘要不匹配（SRI 校验失败）");
}

// 204 null body + integrity：fetch 阶段立即抛 fetch::Error（null body 无法校验）
// ——与错误摘要用例拆开（协程异常后后续不可达，review nit 1）
TEST(FetchcoreDirect, IntegrityNullBody)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        fetch::Request nullb;
        nullb.url = server.base_url() + "/status.py?code=204";
        nullb.integrity = "sha384-UT6f7WCFp32YJnp1is4l/ZYnOeQKpE8xjmdkLOwZ3nIP+tmT2aMRFQGJomjVf5cE";
        fetch::Response resp3 = co_await p.client.fetch(std::move(nullb));
        (void)resp3;
    }());
    ASSERT_TRUE(p.done);
    ASSERT_TRUE(p.error) << "204 + integrity 应抛 fetch::Error";
    EXPECT_EQ(p.error_message(), "fetch: integrity 无法校验 null body 响应");
}

// ---- base64（BoringSSL EVP_EncodeBlock / EVP_DecodeBase64 直接调用）----
TEST(FetchcoreDirect, Base64)
{
    // 编码：标准 base64（带 padding，无换行）
    EXPECT_EQ(fetch::base64_encode(""), "");
    EXPECT_EQ(fetch::base64_encode("f"), "Zg==");
    EXPECT_EQ(fetch::base64_encode("fo"), "Zm8=");
    EXPECT_EQ(fetch::base64_encode("foo"), "Zm9v");
    EXPECT_EQ(fetch::base64_encode("foob"), "Zm9vYg==");
    // 解码 round-trip（含二进制字节）
    const std::string bin = std::string("\x00\x01\xfe\xff", 4);
    EXPECT_EQ(fetch::base64_encode(bin), "AAH+/w==");
    auto back = fetch::base64_decode("AAH+/w==");
    ASSERT_TRUE(back.has_value());
    EXPECT_EQ(*back, bin);
    // 未补齐 padding 的输入（长度非 4 倍数）补 '=' 后解码（宽松保持）
    ASSERT_TRUE(fetch::base64_decode("Zg").has_value());
    EXPECT_EQ(*fetch::base64_decode("Zg"), "f");
    ASSERT_TRUE(fetch::base64_decode("Zm8").has_value());
    EXPECT_EQ(*fetch::base64_decode("Zm8"), "fo");
    // 非法输入 → nullopt：余 1 字符、padding 在中间、padding 后跟数据、
    // 非法字符（含空白）
    EXPECT_FALSE(fetch::base64_decode("A").has_value());
    EXPECT_FALSE(fetch::base64_decode("QQ=A").has_value());
    EXPECT_FALSE(fetch::base64_decode("QUJD=XYZ").has_value());
    EXPECT_FALSE(fetch::base64_decode("!!!").has_value());
    EXPECT_FALSE(fetch::base64_decode("QUJ ").has_value()); // 空白在 4 倍数输入中 → EVP 拒绝
    EXPECT_FALSE(fetch::base64_decode("QUJD==").has_value());
}

// ---- FormData：纯 C++ 条目操作 + multipart 编解码（fetchcore 内建，不建 JSRuntime）----
TEST(FetchcoreDirect, FormDataCore)
{
    // 条目操作：append / has / set（替换首个、删其余）/ erase
    fetch::FormData fd;
    fd.append_entry("a", "1", "", "", false);
    fd.append_entry("a", "2", "", "", false);
    fd.append_entry("b", "x", "", "", false);
    EXPECT_TRUE(fd.has_entry("a"));
    EXPECT_TRUE(fd.has_entry("b"));
    EXPECT_FALSE(fd.has_entry("c"));
    fd.set_entry("a", "9", "", "", false);
    ASSERT_EQ(fd.list.size(), 2u);
    EXPECT_EQ(fd.list[0].name, "a");
    EXPECT_EQ(fd.list[0].bytes, "9");
    EXPECT_EQ(fd.list[1].name, "b");
    fd.set_entry("c", "z", "", "", false); // 无同名 → append
    ASSERT_EQ(fd.list.size(), 3u);
    EXPECT_EQ(fd.list[2].bytes, "z");
    fd.erase_entry("a");
    ASSERT_EQ(fd.list.size(), 2u);
    EXPECT_FALSE(fd.has_entry("a"));

    // encode_multipart：string / blob（filename + Content-Type）/ 转义
    fetch::FormData enc;
    enc.append_entry("k1", "v1", "", "", false);
    enc.append_entry("k2", "bin", "text/plain", "f.txt", true);
    enc.append_entry("q\"uote", "v", "", "", false);
    const std::string body = fetch::encode_multipart(enc, "bnd");
    EXPECT_EQ(body,
              "--bnd\r\n"
              "Content-Disposition: form-data; name=\"k1\"\r\n"
              "\r\n"
              "v1\r\n"
              "--bnd\r\n"
              "Content-Disposition: form-data; name=\"k2\"; filename=\"f.txt\"\r\n"
              "Content-Type: text/plain\r\n"
              "\r\n"
              "bin\r\n"
              "--bnd\r\n"
              "Content-Disposition: form-data; name=\"q\\\"uote\"\r\n"
              "\r\n"
              "v\r\n"
              "--bnd--\r\n");
    // 空 FormData → 仅结束标记（HTML multipart 编码，wpt "Empty form data"）
    EXPECT_EQ(fetch::encode_multipart(fetch::FormData{}, "bnd"), "--bnd--\r\n");

    // extract_boundary：参数名大小写不敏感；引号值（含空格/分号/转义）与裸值
    //（中间空格保留、去尾随空白）均按 MIME Sniffing 参数解析；缺失 → 空
    EXPECT_EQ(fetch::extract_boundary("multipart/form-data; boundary=abc"), "abc");
    EXPECT_EQ(fetch::extract_boundary("multipart/form-data; BOUNDARY=\"abc\""), "abc");
    EXPECT_EQ(fetch::extract_boundary("multipart/form-data; boundary=\"a b\""), "a b");
    EXPECT_EQ(fetch::extract_boundary("multipart/form-data; boundary=a b"), "a b");
    EXPECT_EQ(fetch::extract_boundary("multipart/form-data; boundary=\"abc;def\""), "abc;def");
    EXPECT_EQ(fetch::extract_boundary("multipart/form-data; boundary=\"a\\\"b\""), "a\"b");
    EXPECT_EQ(fetch::extract_boundary("multipart/form-data; boundary=a\"b"), "a\"b"); // 裸值引号保留
    EXPECT_EQ(fetch::extract_boundary("multipart/form-data; boundary=abc "), "abc"); // 尾随空白
    // \ 后跟 CR/LF 视为异常终止（防御头值注入；不吞入换行）
    EXPECT_EQ(fetch::extract_boundary("multipart/form-data; boundary=\"a\\\r\nb\""), "a");
    EXPECT_EQ(fetch::extract_boundary("text/plain"), "");

    // 带空格 boundary 的 multipart body 也能解析（RFC 2046 允许 boundary 含空格）
    const std::string spaced =
        "--a b\r\n"
        "Content-Disposition: form-data; name=\"x\"\r\n"
        "\r\n"
        "v\r\n"
        "--a b--\r\n";
    auto spaced_back = fetch::parse_multipart(spaced, fetch::extract_boundary("boundary=\"a b\""));
    ASSERT_TRUE(spaced_back.has_value());
    ASSERT_EQ(spaced_back->list.size(), 1u);
    EXPECT_EQ(spaced_back->list[0].bytes, "v");

    // parse_multipart round-trip（string / blob / 中文 / 转义；头名大小写不敏感）
    auto back = fetch::parse_multipart(body, "bnd");
    ASSERT_TRUE(back.has_value());
    ASSERT_EQ(back->list.size(), 3u);
    EXPECT_EQ(back->list[0].name, "k1");
    EXPECT_FALSE(back->list[0].is_blob);
    EXPECT_EQ(back->list[0].bytes, "v1");
    EXPECT_TRUE(back->list[1].is_blob);
    EXPECT_EQ(back->list[1].filename, "f.txt");
    EXPECT_EQ(back->list[1].type, "text/plain");
    EXPECT_EQ(back->list[1].bytes, "bin");
    EXPECT_EQ(back->list[2].name, "q\"uote");
    // 中文 + BOM 剥离（string 条目按 UTF-8 decode）
    const std::string cn = "\xEF\xBB\xBF\xE4\xB8\xAD\xE6\x96\x87"; // BOM + "中文"
    fetch::FormData fd2;
    fd2.append_entry("n", cn, "", "", false);
    auto back2 = fetch::parse_multipart(fetch::encode_multipart(fd2, "b2"), "b2");
    ASSERT_TRUE(back2.has_value());
    ASSERT_EQ(back2->list.size(), 1u);
    EXPECT_EQ(back2->list[0].bytes, "\xE4\xB8\xAD\xE6\x96\x87");
    // 空 body → 空 FormData（wpt formdata.any.js：空 FormData 往返）
    auto empty = fetch::parse_multipart("", "bnd");
    ASSERT_TRUE(empty.has_value());
    EXPECT_TRUE(empty->list.empty());
    // 结构不合法 → nullopt（缺 boundary / 结束标记后有多余内容 / 垃圾字节）
    EXPECT_FALSE(fetch::parse_multipart(body, "").has_value());
    EXPECT_FALSE(fetch::parse_multipart(body + "garbage", "bnd").has_value());
    EXPECT_FALSE(fetch::parse_multipart("not a multipart body", "bnd").has_value());
    // 独立 \n（非 \r\n）分隔 → 拒绝（KI-056 后不再卡死，直接失败）
    EXPECT_FALSE(
        fetch::parse_multipart("--bnd\nContent-Disposition: form-data; name=\"x\"\n\nv\n--bnd--",
                               "bnd")
            .has_value());
}

// ---- 流式 multipart 编码器：产出序列与 total_size 自洽 + 与整收编码字节一致 ----
TEST(FetchcoreDirect, MultipartEncoderStream)
{
    // 临时文件（文件 part 用；测试结束删除）
    const std::string fpath = "fetchcore_multipart_probe.bin";
    {
        std::ofstream f(fpath, std::ios::binary);
        ASSERT_TRUE(f.good());
        f << "FILEDATA";
    }
    // 同一输入整收编码（参考输出）
    fetch::FormData fd;
    fd.append_entry("k", "v", "", "", false);
    fd.append_entry("mem", "bin", "text/plain", "x.txt", true);
    fd.append_entry("file", "FILEDATA", "application/octet-stream", "fetchcore_multipart_probe.bin",
                    true);
    fd.append_entry("q\"u", "esc", "text/plain", "a\\b.txt", true); // 转义字符（review should-fix）
    const std::string expected = fetch::encode_multipart(fd, "bnd");

    Probe p;
    // 测试局部线程池（覆盖注入路径；析构自动 join，不碰全局 file_pool）
    boost::asio::thread_pool pool(2);
    std::string out1, out2;
    size_t total = 0;
    p.run([&]() -> std_exec::task<void> {
        auto enc = fetch::MultipartEncoder::create(
            "bnd",
            {{"k", "", "", "v", "", 1},
             {"mem", "x.txt", "text/plain", "bin", "", 3},
             {"file", "fetchcore_multipart_probe.bin", "application/octet-stream", "", fpath, 0},
             {"q\"u", "a\\b.txt", "text/plain", "esc", "", 3}},
            &pool);
        EXPECT_TRUE(enc.has_value());
        if (!enc)
            co_return;
        total = enc->total_size();
        // 第一遍
        for (;;) {
            auto chunk = co_await enc->read();
            if (!chunk)
                break;
            out1 += *chunk;
        }        // reset 重放：第二遍与第一遍一致（重试/307 重发语义）
        enc->reset();
        for (;;) {
            auto chunk = co_await enc->read();
            if (!chunk)
                break;
            out2 += *chunk;
        }
    }());
    ASSERT_TRUE(p.done) << p.error_message();
    ASSERT_FALSE(p.error);
    // total_size 与实际产出严格一致（Content-Length 正确性——不一致会导致服务器挂起）
    EXPECT_EQ(total, out1.size());
    EXPECT_EQ(out1, expected); // 与整收 encode_multipart 字节一致（文件 part 分段读不改变字节）
    EXPECT_EQ(out2, out1);     // reset 重放一致
    std::remove(fpath.c_str());
}

// ---- 全局文件线程池：默认容量（4×用户线程数）+ 单例 + 并发容量 -------
TEST(FetchcoreDirect, FilePoolDefaults)
{
    // 默认线程数 = 4 × hardware_concurrency（hw 为 0 时按 1）
    const unsigned hw = std::thread::hardware_concurrency();
    EXPECT_EQ(fetch::default_file_pool_size(), 4u * (hw ? hw : 1u));
    // 全局单例：两次调用同一实例（惰性初始化）
    EXPECT_EQ(&fetch::file_pool(), &fetch::file_pool());
    // 并发容量（确定性验证）：N 个任务全部启动 = 线程容量达到 N。
    // 每个任务进入后自增 arrived 并等待其他任务到齐（线程数 < N 时无法到齐，
    // 等待窗口后标记容量不足继续退出——不卡死）。主线程等 done 归位。
    // 注：不 join 全局池（join 后不可复用；用计数归零等待完成）。
    const unsigned N = fetch::default_file_pool_size();
    auto& pool = fetch::file_pool();
    std::atomic<unsigned> arrived{0}, done{0};
    std::atomic<bool> capacity_ok{false};
    for (unsigned i = 0; i < N; ++i) {
        boost::asio::post(pool, [&]() {
            ++arrived;
            for (int k = 0; k < 500 && arrived.load() < N; ++k)
                std::this_thread::sleep_for(std::chrono::milliseconds(1));
            if (arrived.load() >= N)
                capacity_ok = true;
            ++done;
        });
    }
    for (int i = 0; i < 5000 && done.load() < N; ++i)
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
    EXPECT_EQ(done.load(), N) << "池任务应在超时内全部完成";
    EXPECT_TRUE(capacity_ok.load()) << "线程池并发容量应达到默认值 " << N;
}

TEST(FetchcoreDirect, EmptyQueryTargetPreserved)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    std::string tgt;
    p.run([&]() -> std_exec::task<void> {
        fetch::Request req;
        req.url = server.base_url() + "/echo-content.py?";
        fetch::Response resp = co_await p.client.fetch(std::move(req));
        EXPECT_EQ(resp.status, 200);
        for (const auto& h : resp.headers)
            if (fetch::header_name_eq(h.name, "x-request-target"))
                tgt = h.value;
        (void)co_await fetch::read_all(resp);
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(tgt, "/echo-content.py?");
}

// ---- data: URL 本地构造 ----
TEST(FetchcoreDirect, DataUrl)
{
    Probe p;
    std::string out;
    p.run([&]() -> std_exec::task<void> {
        fetch::Request text;
        text.url = "data:text/plain,hello%20data";
        fetch::Response r1 = co_await p.client.fetch(std::move(text));
        EXPECT_EQ(r1.status, 200);
        EXPECT_EQ(r1.url, "data:text/plain,hello%20data");
        EXPECT_FALSE(r1.redirected);
        std::string t1 = co_await fetch::read_all(r1); // 先读干再断言
        EXPECT_EQ(t1, "hello data");
        // base64
        fetch::Request b64;
        b64.url = "data:application/json;base64,eyJrIjogMX0=";
        fetch::Response r2 = co_await p.client.fetch(std::move(b64));
        out = co_await fetch::read_all(r2);
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(out, "{\"k\": 1}");
}

// ---- abort：fetch resolve 后挂起的 body 读被取消（stopped）----
// 对齐绑定层语义（fetch_test M1FetchAbortDuringBody）：慢响应头先到，
// fetch resolve；body 挂起期间 request_stop → socket.cancel → 读以 stopped 完成。
TEST(FetchcoreDirect, Abort)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    p.run([&]() -> std_exec::task<void> {
        std::stop_source ss;
        fetch::Request req;
        req.url = server.base_url() + "/slow-response.py?delay=400&content=hello";
        fetch::Response resp = co_await p.client.fetch(std::move(req), ss.get_token());
        // fetch 已 resolve（头到）；30ms 后 abort 挂起的 body 读
        boost::asio::steady_timer t(p.io, std::chrono::milliseconds(30));
        t.async_wait([&](const boost::system::error_code&) { ss.request_stop(); });
        co_await resp.body->read(); // 以 stopped 中断（不走这里）
        EXPECT_TRUE(false) << "读不应正常返回";
    }());
    ASSERT_TRUE(p.done);
    EXPECT_TRUE(p.stopped) << "abort 应使挂起的读以 stopped 完成";
    EXPECT_FALSE(p.error);
}

// ---- 用户中间件：鉴权头注入（C++ 插件定位示例）----
namespace {
struct AuthMiddleware : fetch::Middleware {
    std_exec::task<fetch::Response> intercept(const fetch::Request& req, std::stop_token st,
                                              fetch::Handler next) override
    {
        fetch::Request r = req; // req 只读：修改先拷贝
        r.headers.push_back({"Authorization", "Bearer token-123"});
        co_return co_await next(r, st);
    }
};

// 用户中间件把 body 翻倍（ContentLengthAfterMiddlewareBodyChange 用：
// 验证最内层 BodyLengthMiddleware 按最终 body 重算长度）
struct BodyTwiceMiddleware : fetch::Middleware {
    std_exec::task<fetch::Response> intercept(const fetch::Request& req, std::stop_token st,
                                              fetch::Handler next) override
    {
        fetch::Request r = req;
        r.body += r.body;
        co_return co_await next(r, st);
    }
};
}

TEST(FetchcoreDirect, UserMiddleware)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    std::string out;
    p.client.use(std::make_shared<AuthMiddleware>()); // 注入鉴权中间件
    p.run([&]() -> std_exec::task<void> {
        fetch::Request req;
        req.url = server.base_url() + "/echo-content.py";
        fetch::Response resp = co_await p.client.fetch(std::move(req));
        // 服务器把 X-Request-* 头回显在响应体外的响应头中
        for (const auto& h : resp.headers)
            if (fetch::header_name_eq(h.name, "X-Request-Authorization"))
                out = h.value;
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(out, "Bearer token-123");
}

// ---- BodyLengthMiddleware：Content-Length 运行时重写（发送前）----
// 用户手写 Content-Length 与实际 body 不符 → 发送前强制按 body.size() 重算
TEST(FetchcoreDirect, ContentLengthRewritten)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    std::string out;
    p.run([&]() -> std_exec::task<void> {
        // 1) body 非空 + 手写错误长度（多写）→ 重写为实际字节数
        fetch::Request r1;
        r1.method = "POST";
        r1.url = server.base_url() + "/echo-content.py";
        r1.body = "hello";
        r1.headers.push_back({"Content-Length", "999"});
        fetch::Response resp1 = co_await p.client.fetch(std::move(r1));
        for (const auto& h : resp1.headers)
            if (fetch::header_name_eq(h.name, "X-Request-Content-Length"))
                out += h.value;
        out += "|";
        // 2) body 空 + POST（手写 999）→ 重写为 0（无 body 的 POST 语义）
        fetch::Request r2;
        r2.method = "POST";
        r2.url = server.base_url() + "/echo-content.py";
        r2.headers.push_back({"Content-Length", "999"});
        fetch::Response resp2 = co_await p.client.fetch(std::move(r2));
        for (const auto& h : resp2.headers)
            if (fetch::header_name_eq(h.name, "X-Request-Content-Length"))
                out += h.value;
        out += "|";
        // 3) body 空 + GET（手写 999）→ 头被移除（GET 无 body 语义）
        fetch::Request r3;
        r3.url = server.base_url() + "/echo-content.py";
        r3.headers.push_back({"Content-Length", "999"});
        fetch::Response resp3 = co_await p.client.fetch(std::move(r3));
        for (const auto& h : resp3.headers)
            if (fetch::header_name_eq(h.name, "X-Request-Content-Length"))
                out += h.value;
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(out, "5|0|NO");
}

// 用户中间件修改 body 后，Content-Length 仍按最终 body 重算（最内层保证）
TEST(FetchcoreDirect, ContentLengthAfterMiddlewareBodyChange)
{
    wpt::WptTestServer server("third_party/wpt");
    Probe p;
    p.client.use(std::make_shared<BodyTwiceMiddleware>());
    std::string out;
    p.run([&]() -> std_exec::task<void> {
        fetch::Request req;
        req.method = "POST";
        req.url = server.base_url() + "/echo-content.py";
        req.body = "ab"; // 中间件翻倍 → "abab"（4 字节）
        req.headers.push_back({"Content-Length", "2"}); // 手写旧长度
        fetch::Response resp = co_await p.client.fetch(std::move(req));
        for (const auto& h : resp.headers)
            if (fetch::header_name_eq(h.name, "X-Request-Content-Length"))
                out = h.value;
    }());
    ASSERT_TRUE(p.done);
    ASSERT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(out, "4");
}

// ---- 多实例共用同一 io：各自独立配置互不干扰 ----
TEST(FetchcoreDirect, MultiInstanceSharedIo)
{
    wpt::WptTestServer server("third_party/wpt");
    boost::asio::io_context io;
    fetch::set_thread_io(io);
    fetch::Client c1{};
    fetch::Client c2{}; // 同一 io，独立实例
    std::string r1, r2;
    bool done1 = false, done2 = false;
    stdexec::counting_scope scope;
    auto work1 = [&]() -> std_exec::task<void> {
        fetch::Request req;
        req.method = "POST";
        req.url = server.base_url() + "/echo-content.py";
        req.body = "c1";
        fetch::Response resp = co_await c1.fetch(std::move(req));
        r1 = co_await fetch::read_all(resp);
    }();
    stdexec::spawn(
        std::move(work1)
            | stdexec::then([&]() noexcept { done1 = true; })
            | stdexec::upon_error([&](std::exception_ptr) noexcept { done1 = false; })
            | stdexec::upon_stopped([&]() noexcept { done1 = false; }),
        scope.get_token(),
        stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{io}});
    auto work2 = [&]() -> std_exec::task<void> {
        fetch::Request req;
        req.method = "POST";
        req.url = server.base_url() + "/echo-content.py";
        req.body = "c2";
        fetch::Response resp = co_await c2.fetch(std::move(req));
        r2 = co_await fetch::read_all(resp);
    }();
    stdexec::spawn(
        std::move(work2)
            | stdexec::then([&]() noexcept { done2 = true; })
            | stdexec::upon_error([&](std::exception_ptr) noexcept { done2 = false; })
            | stdexec::upon_stopped([&]() noexcept { done2 = false; }),
        scope.get_token(),
        stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{io}});
    EXPECT_TRUE(ScopeJoiner::run(scope, io)) << "scope join 超时";
    EXPECT_TRUE(done1);
    EXPECT_TRUE(done2);
    EXPECT_EQ(r1, "c1");
    EXPECT_EQ(r2, "c2");
}
// ---- SOCKS5：选路命中走隧道 ----
TEST(FetchcoreDirect, Socks5)
{
    wpt::WptTestServer wpt_server("third_party/wpt");
    wpt::Socks5TestServer proxy;
    proxy.start();
    boost::asio::io_context io;
    fetch::set_thread_io(io);
    auto transport = std::make_shared<fetch::BeastTransport>();
    const fetch::Socks5Proxy p{proxy.host(), proxy.port(), std::nullopt};
    fetch::Client client{transport, fetch::Options{.proxy = fetch::Proxy::socks5(p.host, p.port)}};
    bool ok = false;
    stdexec::counting_scope scope;
    auto work = [&]() -> std_exec::task<void> {
        fetch::Request req;
        req.method = "POST";
        req.url = wpt_server.base_url() + "/echo-content.py";
        req.body = "via socks5";
        fetch::Response resp = co_await client.fetch(std::move(req));
        ok = co_await fetch::read_all(resp) == "via socks5";
    }();
    stdexec::spawn(
        std::move(work)
            | stdexec::then([&]() noexcept { ok = ok && true; })
            | stdexec::upon_error([&](std::exception_ptr) noexcept { ok = false; })
            | stdexec::upon_stopped([&]() noexcept { ok = false; }),
        scope.get_token(),
        stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{io}});
    EXPECT_TRUE(ScopeJoiner::run(scope, io)) << "scope join 超时";
    EXPECT_TRUE(ok) << "经 SOCKS5 隧道请求失败";
}

// ---- HTTP forward proxy：absolute-form 转发（http 目标）----
TEST(FetchcoreDirect, HttpProxy)
{
    wpt::WptTestServer wpt_server("third_party/wpt");
    wpt::HttpProxyTestServer::Options opt;
    opt.record_targets = true;
    wpt::HttpProxyTestServer proxy(opt);
    proxy.start();
    boost::asio::io_context io;
    fetch::set_thread_io(io);
    auto transport = std::make_shared<fetch::BeastTransport>();
    const fetch::HttpProxy p{proxy.host(), proxy.port(), std::nullopt};
    fetch::Client client{transport, fetch::Options{.proxy = fetch::Proxy::http(p.host, p.port)}};
    bool ok = false;
    stdexec::counting_scope scope;
    auto work = [&]() -> std_exec::task<void> {
        fetch::Request req;
        req.method = "POST";
        req.url = wpt_server.base_url() + "/echo-content.py";
        req.body = "via http proxy";
        fetch::Response resp = co_await client.fetch(std::move(req));
        ok = co_await fetch::read_all(resp) == "via http proxy";
    }();
    stdexec::spawn(
        std::move(work)
            | stdexec::then([&]() noexcept { ok = ok && true; })
            | stdexec::upon_error([&](std::exception_ptr) noexcept { ok = false; })
            | stdexec::upon_stopped([&]() noexcept { ok = false; }),
        scope.get_token(),
        stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{io}});
    EXPECT_TRUE(ScopeJoiner::run(scope, io)) << "scope join 超时";
    EXPECT_TRUE(ok) << "经 HTTP 代理请求失败";
    // 代理确实收到 absolute-form 请求（选路证据）
    const auto targets = proxy.targets();
    ASSERT_EQ(targets.size(), 1u);
    EXPECT_EQ(targets[0].host, "127.0.0.1");
    EXPECT_EQ(targets[0].target_line.substr(0, 7), "http://");
}

// ---- HTTP forward proxy：CONNECT 隧道（https 目标，TLS 在隧道上）----
TEST(FetchcoreDirect, HttpsViaHttpProxy)
{
    const std::string cert = read_cert_file("server");
    ASSERT_FALSE(cert.empty());
    wpt_test::TlsEchoServer tls;
    wpt::HttpProxyTestServer::Options opt;
    opt.record_targets = true;
    wpt::HttpProxyTestServer proxy(opt);
    proxy.start();
    boost::asio::io_context io;
    fetch::set_thread_io(io);
    auto transport = std::make_shared<fetch::BeastTransport>(
        fetch::TlsOptions{true, {cert}});
    const fetch::HttpProxy p{proxy.host(), proxy.port(), std::nullopt};
    fetch::Client client{transport, fetch::Options{.proxy = fetch::Proxy::http(p.host, p.port)}};
    bool ok = false;
    stdexec::counting_scope scope;
    auto work = [&]() -> std_exec::task<void> {
        fetch::Request req;
        req.method = "POST";
        req.url = tls.base_url() + "/echo";
        req.body = "tls over connect";
        fetch::Response resp = co_await client.fetch(std::move(req));
        ok = resp.status == 200 &&
             co_await fetch::read_all(resp) == "tls over connect";
    }();
    stdexec::spawn(
        std::move(work)
            | stdexec::then([&]() noexcept { ok = ok && true; })
            | stdexec::upon_error([&](std::exception_ptr) noexcept { ok = false; })
            | stdexec::upon_stopped([&]() noexcept { ok = false; }),
        scope.get_token(),
        stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{io}});
    EXPECT_TRUE(ScopeJoiner::run(scope, io)) << "scope join 超时";
    EXPECT_TRUE(ok) << "经 CONNECT 隧道请求失败";
    // 代理记录 CONNECT 目标（选路证据）
    const auto targets = proxy.targets();
    ASSERT_EQ(targets.size(), 1u);
    EXPECT_TRUE(targets[0].is_connect);
    EXPECT_EQ(targets[0].port, tls.port());
}

// ---- HTTPS：自签证书 + extra_trust_pem ----
TEST(FetchcoreDirect, Https)
{
    const std::string cert = read_cert_file("server");
    ASSERT_FALSE(cert.empty());
    wpt_test::TlsEchoServer tls;
    boost::asio::io_context io;
    fetch::set_thread_io(io);
    auto transport = std::make_shared<fetch::BeastTransport>(
        fetch::TlsOptions{true, {cert}});
    fetch::Client client{transport};
    std::string out;
    std::string sni = "sent"; // 期望为空：IP 字面量不发 SNI（RFC 6066）
    bool ok = false;
    stdexec::counting_scope scope;
    auto work = [&]() -> std_exec::task<void> {
        fetch::Request req;
        req.method = "POST";
        req.url = tls.base_url() + "/echo";
        req.body = "tls direct";
        fetch::Response resp = co_await client.fetch(std::move(req));
        for (const auto& h : resp.headers)
            if (fetch::header_name_eq(h.name, "x-test-sni"))
                sni = h.value;
        out = co_await fetch::read_all(resp);
    }();
    stdexec::spawn(
        std::move(work)
            | stdexec::then([&]() noexcept { ok = true; })
            | stdexec::upon_error([&](std::exception_ptr) noexcept { ok = false; })
            | stdexec::upon_stopped([&]() noexcept { ok = false; }),
        scope.get_token(),
        stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{io}});
    EXPECT_TRUE(ScopeJoiner::run(scope, io)) << "scope join 超时";
    ASSERT_TRUE(ok);
    EXPECT_EQ(out, "tls direct");
    EXPECT_EQ(sni, ""); // IP 字面量：不发送 SNI
}

// ---- HTTPS + SNI：域名 host 必须携带 SNI（beast_ssl_backend.md §2）----
// URL host 用域名 localhost（经 SOCKS5 隧道解析到本地），TLS 服务器回显
// ClientHello 的 SNI 供断言；证书为 SAN 含 DNS:localhost 的自签证书。
TEST(FetchcoreDirect, HttpsSniViaSocks5)
{
    const std::string cert = read_cert_file("localhost");
    ASSERT_FALSE(cert.empty());
    wpt_test::TlsEchoServer tls("localhost");
    wpt::Socks5TestServer proxy;
    proxy.start();
    boost::asio::io_context io;
    fetch::set_thread_io(io);
    auto transport = std::make_shared<fetch::BeastTransport>(
        fetch::TlsOptions{true, {cert}});
    const fetch::Socks5Proxy p{proxy.host(), proxy.port(), std::nullopt};
    fetch::Client client{transport, fetch::Options{.proxy = fetch::Proxy::socks5(p.host, p.port)}};
    std::string out;
    std::string sni;
    bool ok = false;
    stdexec::counting_scope scope;
    auto work = [&]() -> std_exec::task<void> {
        fetch::Request req;
        req.method = "POST";
        req.url = "https://localhost:" + std::to_string(tls.port()) + "/echo";
        req.body = "sni check";
        fetch::Response resp = co_await client.fetch(std::move(req));
        for (const auto& h : resp.headers)
            if (fetch::header_name_eq(h.name, "x-test-sni"))
                sni = h.value;
        out = co_await fetch::read_all(resp);
    }();
    stdexec::spawn(
        std::move(work)
            | stdexec::then([&]() noexcept { ok = true; })
            | stdexec::upon_error([&](std::exception_ptr) noexcept { ok = false; })
            | stdexec::upon_stopped([&]() noexcept { ok = false; }),
        scope.get_token(),
        stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{io}});
    EXPECT_TRUE(ScopeJoiner::run(scope, io)) << "scope join 超时";
    ASSERT_TRUE(ok);
    EXPECT_EQ(out, "sni check");
    EXPECT_EQ(sni, "localhost"); // 域名：ClientHello 携带 SNI
}

} // namespace
