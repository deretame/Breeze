// fetch::easy 请求层测试（docs/fetch_easy_design.md §9 测试计划）
//
// 驱动方式与 fetchcore_test.cpp 一致：spawn 上 io 调度器，counting_scope
// close + join 后 poll 循环驱动（ScopeJoiner）。
#include <gtest/gtest.h>
#include <log.hpp>
#include <fetch/easy.hpp>
#include <fetch/scheduler.hpp>
#include "wpt_server.hpp"

#include <stdexec/execution.hpp>

#include <chrono>
#include <cstddef>
#include <cstdio>
#include <exception>
#include <fstream>
#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <thread>
#include <vector>

// ---- 测试数据（glaze 反射要求 external linkage：不能在匿名命名空间）----
struct User {
    std::string name;
    int age = 0;
    bool operator==(const User&) const = default;
};

namespace {

namespace wpt = qjsbind::net::wpt;
namespace easy = fetch::easy;

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
        if (!joined)
            QLOG_WARNING("[fetch_easy] warning: scope join 超时（20000 轮 poll）");
        return joined;
    }
};

// ---- 驱动辅助：协程任务 spawn 上 io 调度器，结果存成员 ----
struct EasyProbe {
    boost::asio::io_context io;
    easy::Client client;
    bool done = false;
    bool stopped = false;
    std::exception_ptr error;

    // cfg：可选，构造前定制 ClientBuilder（如 user_agent/timeout 默认值）
    explicit EasyProbe(std::function<void(easy::ClientBuilder&)> cfg = {})
        : client([&] {
              fetch::set_thread_io(io); // 本测试线程的 fetch io 来源
              easy::ClientBuilder b = easy::Client::builder();
              if (cfg)
                  cfg(b);
              return b.build();
          }())
    {
    }

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

    // 变体：外部 inplace_stop_source 可取消（取消 → set_stopped 传播）。
    // spawn 的 token 参数必须是 scope_token（生命周期管理），外部取消 token
    // 经 env 的 get_stop_token 覆盖传入（when_any/task 均透传 env，§8.5/8.7）
    void run_stoppable(std_exec::task<void> work, stdexec::inplace_stop_source& src)
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
            stdexec::env{stdexec::prop{stdexec::get_start_scheduler, fetch::io_scheduler{io}},
                         stdexec::prop{stdexec::get_stop_token, src.get_token()}});
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

    // 若异常是本层 easy::Error，返回其 kind
    std::optional<easy::error_kind> error_kind_of() const
    {
        if (!error)
            return std::nullopt;
        try {
            std::rethrow_exception(error);
        } catch (const easy::Error& e) {
            return e.kind();
        } catch (...) {
            return std::nullopt;
        }
    }
}; // struct EasyProbe

} // namespace

// ===================== 基础 GET / body 消费 =====================

TEST(Easy, GetText)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/status.py?code=200&content=hello")
                         .send();
        EXPECT_EQ(resp.status(), 200);
        EXPECT_TRUE(resp.ok());
        EXPECT_EQ(co_await resp.text(), "hello");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, GetStatus404)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/status.py?code=404").send();
        EXPECT_EQ(resp.status(), 404);
        EXPECT_FALSE(resp.ok());
        EXPECT_EQ(co_await resp.text(), "");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, HeadNoBody)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.head(server.base_url() + "/status.py?code=200&content=x")
                         .send();
        EXPECT_EQ(resp.status(), 200);
        EXPECT_EQ(co_await resp.text(), ""); // HEAD 响应无 body
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, Bytes)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/status.py?code=200&content=abc")
                         .send();
        auto b = co_await resp.bytes();
        EXPECT_EQ(b.size(), 3u);
        if (b.size() != 3u)
            co_return;
        EXPECT_EQ(static_cast<char>(b[0]), 'a');
        EXPECT_EQ(static_cast<char>(b[2]), 'c');
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, RawEscapeHatch)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/status.py?code=200&content=raw")
                         .send();
        EXPECT_EQ(resp.raw().status, 200); // 底层 fetch::Response
        // 流式读（BodySource）与 text() 结果一致
        auto raw_text = co_await fetch::read_all(resp.raw());
        EXPECT_EQ(raw_text, "raw");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, BodyConsumedTwice)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/status.py?code=200&content=x")
                         .send();
        EXPECT_EQ(co_await resp.text(), "x");
        // 第二次消费 → policy 错误
        bool threw = false;
        try {
            (void)co_await resp.text();
        } catch (const easy::Error& e) {
            threw = true;
            EXPECT_EQ(e.kind(), easy::error_kind::policy);
        }
        EXPECT_TRUE(threw);
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

// ===================== 手动 body / header（逃生舱） =====================

TEST(Easy, ManualBodyHeader)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.post(server.base_url() + "/echo-content.py")
                         .header("Content-Type", "text/plain")
                         .body("hello-easy")
                         .send();
        EXPECT_EQ(resp.status(), 200);
        EXPECT_EQ(co_await resp.text(), "hello-easy");
        // 手动设置的 Content-Type 原样发送（echo 回显）
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Content-Type");
        });
        EXPECT_NE(it, h.end());
        if (it == h.end())
            co_return;
        EXPECT_EQ(it->value, "text/plain");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, UserAgentTransportDefault)
{
    // 未配置 user_agent：transport 层缺省填默认 UA（beast_transport.cpp:
    // "qjs-runtime/0.1 (+wpt)"，仅在用户未设置时生效）
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/inspect-headers.py?headers=User-Agent")
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "x-request-User-Agent");
        });
        EXPECT_NE(it, h.end());
        if (it != h.end())
            EXPECT_EQ(it->value, "qjs-runtime/0.1 (+wpt)");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, UserAgentConfigEffective)
{
    // easy 的 user_agent() 生效：请求携带配置的 UA（transport 默认值不覆盖）
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p([](easy::ClientBuilder& b) { b.user_agent("easy-test/1.0"); });
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/inspect-headers.py?headers=User-Agent")
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "x-request-User-Agent");
        });
        EXPECT_NE(it, h.end());
        if (it != h.end())
            EXPECT_EQ(it->value, "easy-test/1.0");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, UserAgentPerRequestOverride)
{
    // 逐请求 header("User-Agent") 优先于 Client 默认
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p([](easy::ClientBuilder& b) { b.user_agent("easy-test/1.0"); });
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/inspect-headers.py?headers=User-Agent")
                         .header("User-Agent", "per-request/2.0")
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "x-request-User-Agent");
        });
        EXPECT_NE(it, h.end());
        if (it != h.end())
            EXPECT_EQ(it->value, "per-request/2.0");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, UserAgentPerRequestSugar)
{
    // .user_agent() 语法糖：等价 .header("User-Agent", v)，覆盖 Client 默认
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p([](easy::ClientBuilder& b) { b.user_agent("easy-test/1.0"); });
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/inspect-headers.py?headers=User-Agent")
                         .user_agent("per-request/2.0")
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "x-request-User-Agent");
        });
        EXPECT_NE(it, h.end());
        if (it != h.end())
            EXPECT_EQ(it->value, "per-request/2.0");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, UserAgentSugarReplacesDuplicate)
{
    // 重复调用 .user_agent() 只留最后一个（替换，不残留重复头）
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/inspect-headers.py?headers=User-Agent")
                         .user_agent("first/1.0")
                         .user_agent("second/2.0")
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "x-request-User-Agent");
        });
        EXPECT_NE(it, h.end());
        if (it != h.end())
            EXPECT_EQ(it->value, "second/2.0");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, HeaderValueInjectionRejected)
{
    // 头注入兜底：CR/LF 值在发送前被拒绝（beast_transport 校验；JS 层
    // normalize_value 已拦，这里是 C++ 直通路径的防御纵深）。校验发生在
    // 连接建立之后、写入之前 → 本地哑 server 确保连接成功到达校验点。
    // transport 抛 std::invalid_argument（std::exception 子类）→ easy
    // catch 链兜底归 decode。
    boost::asio::io_context sio;
    boost::asio::ip::tcp::acceptor acc(sio, {boost::asio::ip::tcp::v4(), 0});
    acc.listen();
    const uint16_t port = acc.local_endpoint().port();
    std::thread dumb([&] {
        boost::system::error_code ec;
        auto sock = acc.accept(ec);
        std::this_thread::sleep_for(std::chrono::milliseconds(500));
        sock.close(ec);
    });

    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("http://127.0.0.1:" + std::to_string(port) + "/")
                         .header("X-Evil", "a\r\nX-Injected: 1")
                         .send();
        (void)resp;
    }());
    dumb.join();
    EXPECT_TRUE(p.done);
    ASSERT_TRUE(p.error_kind_of().has_value());
    EXPECT_EQ(*p.error_kind_of(), easy::error_kind::decode);
    EXPECT_NE(p.error_message().find("CR/LF/NUL"), std::string::npos);
}

// ===================== JSON（glaze） =====================

TEST(Easy, GetJson)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client
                         .get(server.base_url() +
                              "/status.py?code=200&content=%7B%22name%22%3A%22tom%22%2C%22age%22%3A7%7D")
                         .send();
        User u = co_await resp.json<User>();
        EXPECT_EQ(u.name, "tom");
        EXPECT_EQ(u.age, 7);
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, PostJsonEcho)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.post(server.base_url() + "/echo-content.py")
                         .json(User{.name = "tom", .age = 7})
                         .send();
        // 自动 Content-Type（缺省才填）
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Content-Type");
        });
        EXPECT_NE(it, h.end());
        if (it == h.end())
            co_return;
        EXPECT_EQ(it->value, "application/json");
        // 序列化正确（echo 回显 body）
        EXPECT_EQ(co_await resp.text(), R"({"name":"tom","age":7})");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, ManualContentTypeWinsOverAuto)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        // 手动 header + json 同用：显式 Content-Type 优先，body 是 json 序列化结果
        auto resp = co_await p.client.post(server.base_url() + "/echo-content.py")
                         .header("Content-Type", "application/vnd.test+json")
                         .json(User{.name = "x", .age = 1})
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Content-Type");
        });
        EXPECT_NE(it, h.end());
        if (it == h.end())
            co_return;
        EXPECT_EQ(it->value, "application/vnd.test+json");
        EXPECT_EQ(co_await resp.text(), R"({"name":"x","age":1})");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

// ===================== multipart / FormData =====================

TEST(Easy, MultipartPostRoundTrip)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        easy::Form form;
        form.text("username", "sean");
        form.part("files",
                  easy::Part::bytes("hello").file_name("greeting.txt").mime("text/plain"));
        auto resp = co_await p.client.post(server.base_url() + "/echo-content.py")
                         .multipart(std::move(form))
                         .send();
        // 自动 Content-Type（缺省才填；reqwest .multipart() 语义）
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Content-Type");
        });
        EXPECT_NE(it, h.end());
        if (it == h.end())
            co_return;
        const std::string ct = it->value;
        EXPECT_TRUE(ct.rfind("multipart/form-data; boundary=", 0) == 0);
        // echo 回显 body 按 boundary 解析回 FormData（端到端 round-trip）
        const std::string boundary = fetch::extract_boundary(ct);
        EXPECT_FALSE(boundary.empty());
        if (boundary.empty())
            co_return;
        auto fd = fetch::parse_multipart(co_await resp.text(), boundary);
        EXPECT_TRUE(fd.has_value());
        if (!fd)
            co_return;
        EXPECT_EQ(fd->list.size(), 2u);
        if (fd->list.size() != 2u)
            co_return;
        EXPECT_EQ(fd->list[0].name, "username");
        EXPECT_FALSE(fd->list[0].is_blob);
        EXPECT_EQ(fd->list[0].bytes, "sean");
        EXPECT_EQ(fd->list[1].name, "files");
        EXPECT_TRUE(fd->list[1].is_blob);
        EXPECT_EQ(fd->list[1].filename, "greeting.txt");
        EXPECT_EQ(fd->list[1].type, "text/plain");
        EXPECT_EQ(fd->list[1].bytes, "hello");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, MultipartManualContentTypeWins)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        easy::Form form;
        form.text("k", "v");
        // 显式 Content-Type 优先（§7 同 json：缺省才自动填）
        auto resp = co_await p.client.post(server.base_url() + "/echo-content.py")
                         .header("Content-Type", "multipart/form-data; boundary=manual")
                         .multipart(std::move(form))
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Content-Type");
        });
        EXPECT_NE(it, h.end());
        if (it == h.end())
            co_return;
        EXPECT_EQ(it->value, "multipart/form-data; boundary=manual");
        // body 用声明 boundary 编码（声明与实体一致）→ 可解析回读
        auto fd = fetch::parse_multipart(co_await resp.text(), "manual");
        EXPECT_TRUE(fd.has_value());
        if (!fd)
            co_return;
        EXPECT_EQ(fd->list.size(), 1u);
        if (fd->list.size() != 1u)
            co_return;
        EXPECT_EQ(fd->list[0].name, "k");
        EXPECT_EQ(fd->list[0].bytes, "v");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, MultipartFileMissing)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        easy::Form form;
        form.text("k", "v");
        form.file("f", "no_such_file_does_not_exist.txt");
        auto resp = co_await p.client.post(server.base_url() + "/echo-content.py")
                         .multipart(std::move(form))
                         .send();
        // 不应到达：Form::file 读取失败延迟到 send 抛 Error(decode)
        (void)resp;
        EXPECT_TRUE(false) << "send() 应抛 Error";
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_TRUE(p.error);
    EXPECT_EQ(p.error_kind_of(), easy::error_kind::decode);
}

TEST(Easy, FormGuessMime)
{
    // 扩展名 → MIME 猜测（reqwest mime_guess 轻量等价物；大小写不敏感）
    EXPECT_EQ(easy::Form::guess_mime("a.png"), "image/png");
    EXPECT_EQ(easy::Form::guess_mime("dir/a.PNG"), "image/png");
    EXPECT_EQ(easy::Form::guess_mime("a.json"), "application/json");
    EXPECT_EQ(easy::Form::guess_mime("a.txt"), "text/plain");
    EXPECT_EQ(easy::Form::guess_mime("a.docx"),
              "application/vnd.openxmlformats-officedocument.wordprocessingml.document");
    // 未知扩展名 / 无扩展名 → application/octet-stream
    EXPECT_EQ(easy::Form::guess_mime("a.unknown_ext"), "application/octet-stream");
    EXPECT_EQ(easy::Form::guess_mime("noext"), "application/octet-stream");
}

TEST(Easy, MultipartFileUpload)
{
    // 临时上传探针文件（测试结束删除）
    const std::string path = "form_mime_probe.png";
    {
        std::ofstream f(path, std::ios::binary);
        ASSERT_TRUE(f.good());
        f << "PNGDATA";
    }
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        easy::Form form;
        form.file("avatar", path);                           // 缺省 → guess_mime
        form.file("manual", path, "application/x-custom");   // 手动覆盖
        auto resp = co_await p.client.post(server.base_url() + "/echo-content.py")
                         .multipart(std::move(form))
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Content-Type");
        });
        EXPECT_NE(it, h.end());
        if (it == h.end())
            co_return;
        // 解析回读：filename = 路径 basename，type = 猜测/手动各归其位
        auto fd = fetch::parse_multipart(co_await resp.text(), fetch::extract_boundary(it->value));
        EXPECT_TRUE(fd.has_value());
        if (!fd)
            co_return;
        EXPECT_EQ(fd->list.size(), 2u);
        if (fd->list.size() != 2u)
            co_return;
        EXPECT_EQ(fd->list[0].name, "avatar");
        EXPECT_TRUE(fd->list[0].is_blob);
        EXPECT_EQ(fd->list[0].filename, "form_mime_probe.png");
        EXPECT_EQ(fd->list[0].type, "image/png");   // 扩展名猜测
        EXPECT_EQ(fd->list[0].bytes, "PNGDATA");
        EXPECT_EQ(fd->list[1].name, "manual");
        EXPECT_TRUE(fd->list[1].is_blob);
        EXPECT_EQ(fd->list[1].filename, "form_mime_probe.png");
        EXPECT_EQ(fd->list[1].type, "application/x-custom"); // 手动覆盖
        EXPECT_EQ(fd->list[1].bytes, "PNGDATA");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
    std::remove(path.c_str());
}

// ===================== form-urlencoded / octet-stream =====================

TEST(Easy, FormUrlencodedPost)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.post(server.base_url() + "/echo-content.py")
                         .form_urlencoded({{"k", "v"}, {"a", "b c"}, {"q", "x&y"}})
                         .send();
        // 自动 Content-Type（缺省才填）
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Content-Type");
        });
        EXPECT_NE(it, h.end());
        if (it == h.end())
            co_return;
        EXPECT_EQ(it->value, "application/x-www-form-urlencoded");
        // 编码：空格 → '+'，& 等非 unreserved → %XX（与 UrlSearchParams 序列化一致）
        EXPECT_EQ(co_await resp.text(), "k=v&a=b+c&q=x%26y");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, UrlencodedManualContentTypeWins)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        // 显式 Content-Type 优先（§7 同 json/multipart）
        auto resp = co_await p.client.post(server.base_url() + "/echo-content.py")
                         .header("Content-Type", "application/x-www-form-urlencoded;charset=UTF-8")
                         .form_urlencoded({{"k", "v"}})
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Content-Type");
        });
        EXPECT_NE(it, h.end());
        if (it == h.end())
            co_return;
        EXPECT_EQ(it->value, "application/x-www-form-urlencoded;charset=UTF-8");
        EXPECT_EQ(co_await resp.text(), "k=v");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, OctetStreamPost)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    // 含 NUL/非 UTF-8 字节（MSVC 的 vector<byte> 范围构造不能从 char 直接 emplacing，
    // 显式逐字节转）
    const std::string raw = "raw\x00bytes\xff";
    const std::vector<std::byte> expected = [&] {
        std::vector<std::byte> v;
        v.reserve(raw.size());
        for (char c : raw)
            v.push_back(std::byte(static_cast<unsigned char>(c)));
        return v;
    }();
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.post(server.base_url() + "/echo-content.py")
                         .octet_stream(raw)
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Content-Type");
        });
        EXPECT_NE(it, h.end());
        if (it == h.end())
            co_return;
        EXPECT_EQ(it->value, "application/octet-stream");
        // 原始字节原样回显
        EXPECT_EQ(co_await resp.bytes(), expected);
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

// ===================== query / auth =====================

TEST(Easy, Query)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/echo-content.py")
                         .query({{"k", "v"}, {"q", "a b&c"}})
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Target");
        });
        EXPECT_NE(it, h.end());
        if (it == h.end())
            co_return;
        EXPECT_EQ(it->value, "/echo-content.py?k=v&q=a%20b%26c");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, QueryWithFragment)
{
    // append_query 把 query 插到 fragment(#) 之前（review nit 专项）
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/echo-content.py#frag")
                         .query({{"k", "v"}})
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Target");
        });
        EXPECT_NE(it, h.end());
        if (it != h.end())
            // fragment 不上行（HTTP 规范）；断言 query 拼在正确位置而非被 # 截断
            EXPECT_EQ(it->value, "/echo-content.py?k=v");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, BasicAuth)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/echo-content.py")
                         .basic_auth("user", "pass")
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Authorization");
        });
        EXPECT_NE(it, h.end());
        if (it == h.end())
            co_return;
        EXPECT_EQ(it->value, "Basic " + fetch::base64_encode("user:pass"));
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, BearerAuth)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/echo-content.py")
                         .bearer_auth("tok123")
                         .send();
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Authorization");
        });
        EXPECT_NE(it, h.end());
        if (it == h.end())
            co_return;
        EXPECT_EQ(it->value, "Bearer tok123");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

// ===================== error_for_status =====================

TEST(Easy, ErrorForStatus)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/status.py?code=404").send();
        bool threw = false;
        try {
            resp.error_for_status();
        } catch (const easy::Error& e) {
            threw = true;
            EXPECT_EQ(e.kind(), easy::error_kind::http_status);
            EXPECT_TRUE(e.status().has_value());
            if (!e.status())
                co_return;
            EXPECT_EQ(*e.status(), 404);
        }
        EXPECT_TRUE(threw);
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, ErrorForStatusPassThrough)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get(server.base_url() + "/status.py?code=200&content=ok")
                         .send();
        EXPECT_EQ(resp.error_for_status().status(), 200); // 链式可用
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

// ===================== 错误映射 =====================

TEST(Easy, UrlInvalid)
{
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("not a url").send();
        (void)resp;
    }());
    EXPECT_TRUE(p.done);
    ASSERT_TRUE(p.error_kind_of().has_value());
    EXPECT_EQ(*p.error_kind_of(), easy::error_kind::url);
}

TEST(Easy, UnsupportedScheme)
{
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("ftp://example.com/x").send();
        (void)resp;
    }());
    EXPECT_TRUE(p.done);
    ASSERT_TRUE(p.error_kind_of().has_value());
    EXPECT_EQ(*p.error_kind_of(), easy::error_kind::url);
}

TEST(Easy, UrlUserinfoRejected)
{
    // URL 内嵌凭据（user:pass@）显式拒绝（L4；对齐 WHATWG fetch "URL includes
    // credentials"），错误信息提示改用 Authorization 头。
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("http://user:pass@127.0.0.1:8080/").send();
        (void)resp;
    }());
    EXPECT_TRUE(p.done);
    ASSERT_TRUE(p.error_kind_of().has_value());
    EXPECT_EQ(*p.error_kind_of(), easy::error_kind::url);
    EXPECT_NE(p.error_message().find("credentials"), std::string::npos)
        << p.error_message();
    EXPECT_NE(p.error_message().find("Authorization"), std::string::npos)
        << p.error_message();
}

TEST(Easy, GetWithBodyRejected)
{
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("http://127.0.0.1:1/").body("x").send();
        (void)resp;
    }());
    EXPECT_TRUE(p.done);
    ASSERT_TRUE(p.error_kind_of().has_value());
    EXPECT_EQ(*p.error_kind_of(), easy::error_kind::policy);
}

TEST(Easy, NetworkError)
{
    // 找一个空闲端口（bind :0 后关闭；blocked-port 列表外的未监听端口）
    boost::asio::io_context tmp_io;
    boost::asio::ip::tcp::acceptor acc(tmp_io, {boost::asio::ip::tcp::v4(), 0});
    const uint16_t port = acc.local_endpoint().port();
    acc.close();

    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("http://127.0.0.1:" + std::to_string(port) + "/").send();
        (void)resp;
    }());
    EXPECT_TRUE(p.done);
    ASSERT_TRUE(p.error_kind_of().has_value());
    EXPECT_EQ(*p.error_kind_of(), easy::error_kind::network);
}

// ===================== 重定向 / data: / 一次性用法 =====================

TEST(Easy, RedirectFollow)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        // 注意：wpt 的 url_encode 不编码 &，location 带 query 会被 parse_query
        // 分割，故 final 目标用无 & 的 URL
        const std::string final_url = server.base_url() + "/status.py?code=200";
        auto resp = co_await p.client
                         .get(server.base_url() +
                              "/redirect.py?location=" + wpt::url_encode(final_url) + "&simple=1")
                         .send();
        EXPECT_EQ(resp.status(), 200);
        EXPECT_TRUE(resp.redirected());
        EXPECT_EQ(resp.url(), final_url);
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, DataUrl)
{
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("data:text/plain,hi-easy").send();
        EXPECT_EQ(resp.status(), 200);
        EXPECT_EQ(co_await resp.text(), "hi-easy");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, OneShotGet)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        // 一次性用法：easy::get(url)
        auto resp = co_await easy::get(server.base_url() + "/status.py?code=200&content=once")
                         .send();
        EXPECT_EQ(co_await resp.text(), "once");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

// ===================== 超时（E3，§6.2） =====================

TEST(Easy, TimeoutFires)
{
    // 哑 server：接受连接但 1s 内不响应任何字节 → fetch 卡在等响应头，
    // 200ms 超时必先触发（wpt 的 slow-response 头立即到达，测不到请求阶段）
    boost::asio::io_context sio;
    boost::asio::ip::tcp::acceptor acc(sio, {boost::asio::ip::tcp::v4(), 0});
    acc.listen();
    const uint16_t port = acc.local_endpoint().port();
    std::thread dumb([&] {
        boost::system::error_code ec;
        auto sock = acc.accept(ec);
        std::this_thread::sleep_for(std::chrono::seconds(1)); // 挂起不响应
        sock.close(ec);
    });

    EasyProbe p;
    auto t0 = std::chrono::steady_clock::now();
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("http://127.0.0.1:" + std::to_string(port) + "/")
                         .timeout(std::chrono::milliseconds(200))
                         .send();
        (void)resp;
    }());
    const auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
                             std::chrono::steady_clock::now() - t0)
                             .count();
    dumb.join();
    EXPECT_TRUE(p.done);
    ASSERT_TRUE(p.error_kind_of().has_value());
    EXPECT_EQ(*p.error_kind_of(), easy::error_kind::timeout);
    EXPECT_LT(elapsed, 900) << "超时应 ≈200ms 触发，而非等哑 server 1s";
}

TEST(Easy, NoTimeoutPassThrough)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        // 无超时（默认）：慢端点也要完整等到 body
        auto resp = co_await p.client
                         .get(server.base_url() + "/slow-response.py?delay=100&content=slow")
                         .send();
        EXPECT_EQ(resp.status(), 200);
        EXPECT_EQ(co_await resp.text(), "slow");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, DeadlineCoversBody)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        // 全程语义（§6.2-5）：头立即到 → send() 返回；body 延迟 3000ms 超过
        // 剩余 deadline → text() 抛 timeout
        auto resp = co_await p.client
                         .get(server.base_url() + "/slow-response.py?delay=3000&content=late")
                         .timeout(std::chrono::milliseconds(500))
                         .send();
        EXPECT_EQ(resp.status(), 200); // 头已到
        bool threw = false;
        try {
            (void)co_await resp.text();
        } catch (const easy::Error& e) {
            threw = true;
            EXPECT_EQ(e.kind(), easy::error_kind::timeout);
        }
        EXPECT_TRUE(threw) << "body 消费应受 deadline 约束";
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, TimeoutThenServerAlive)
{
    // 超时路径拆掉底层连接（§6.2-5）：服务器侧无残留挂起连接，
    // 同一 server 后续请求正常
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        try {
            auto resp = co_await p.client
                             .get(server.base_url() + "/slow-response.py?delay=5000&content=x")
                             .timeout(std::chrono::milliseconds(150))
                             .send();
            (void)resp;
        } catch (const easy::Error& e) {
            EXPECT_EQ(e.kind(), easy::error_kind::timeout);
        }
        // 超时后服务器仍可服务
        auto resp2 = co_await p.client.get(server.base_url() + "/status.py?code=200&content=alive")
                          .send();
        EXPECT_EQ(resp2.status(), 200);
        EXPECT_EQ(co_await resp2.text(), "alive");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

// ===================== 重试（E4，§6.3） =====================

// 构造 retry_policy 的便捷函数（字段是成员而非方法）
inline easy::retry_policy retries(int n, bool non_idempotent = false)
{
    easy::retry_policy p;
    p.max_retries = n;
    p.retry_non_idempotent = non_idempotent;
    return p;
}

// 计数 HTTP 服务器：前 fail_times 次返回 fail_status（可带 Retry-After），
// 之后返回 ok_status + ok_body；hits 记录总请求数（每请求新连接，无连接池）
struct CountingServer {
    boost::asio::io_context io;
    boost::asio::ip::tcp::acceptor acc{io, {boost::asio::ip::tcp::v4(), 0}};
    std::thread th;
    std::atomic<int> hits{0};
    const int fail_times;
    const int fail_status;
    const int ok_status;
    const std::string ok_body;
    const std::optional<int> retry_after;

    CountingServer(int fail_times_, int fail_status_, int ok_status_ = 200,
                   std::string ok_body_ = "ok", std::optional<int> retry_after_ = {})
        : fail_times(fail_times_), fail_status(fail_status_), ok_status(ok_status_),
          ok_body(std::move(ok_body_)), retry_after(retry_after_)
    {
        acc.listen();
        th = std::thread([this] {
            for (;;) {
                boost::system::error_code ec;
                auto sock = acc.accept(ec);
                if (ec)
                    break;
                char buf[4096];
                sock.read_some(boost::asio::buffer(buf), ec);
                const int n = ++hits;
                std::string resp;
                if (n <= fail_times) {
                    resp = "HTTP/1.1 " + std::to_string(fail_status) + " Fail\r\n";
                    if (retry_after)
                        resp += "Retry-After: " + std::to_string(*retry_after) + "\r\n";
                    resp += "Content-Length: 0\r\nConnection: close\r\n\r\n";
                } else {
                    resp = "HTTP/1.1 " + std::to_string(ok_status) + " OK\r\n"
                           "Content-Length: " +
                           std::to_string(ok_body.size()) + "\r\n"
                           "Connection: close\r\n\r\n" +
                           ok_body;
                }
                boost::asio::write(sock, boost::asio::buffer(resp), ec);
                sock.close(ec);
            }
        });
    }

    ~CountingServer()
    {
        boost::system::error_code ec;
        acc.close(ec);
        if (th.joinable())
            th.join();
    }

    uint16_t port() const { return acc.local_endpoint().port(); }
};

TEST(Easy, RetryOn5xx)
{
    CountingServer srv(2, 503); // 前 2 次 503，之后 200
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("http://127.0.0.1:" + std::to_string(srv.port()) + "/")
                         .retry(retries(2))
                         .send();
        EXPECT_EQ(resp.status(), 200);
        EXPECT_EQ(co_await resp.text(), "ok");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
    EXPECT_EQ(srv.hits.load(), 3) << "前 2 次 503 + 第 3 次成功";
}

TEST(Easy, RetryExhausted)
{
    CountingServer srv(100, 503); // 永远 503
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("http://127.0.0.1:" + std::to_string(srv.port()) + "/")
                         .retry(retries(2))
                         .send();
        EXPECT_EQ(resp.status(), 503); // 返回最后一次的 Response，不抛
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
    EXPECT_EQ(srv.hits.load(), 3) << "首发 + 2 次重试";
}

TEST(Easy, RetryNeverOnDecode)
{
    // decode 错误发生在 body 消费阶段（send 之外）——天然不重试
    CountingServer srv(0, 200, 200, "not-a-json");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("http://127.0.0.1:" + std::to_string(srv.port()) + "/")
                         .retry(retries(3))
                         .send();
        bool threw = false;
        try {
            (void)co_await resp.json<User>();
        } catch (const easy::Error& e) {
            threw = true;
            EXPECT_EQ(e.kind(), easy::error_kind::decode);
        }
        EXPECT_TRUE(threw);
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
    EXPECT_EQ(srv.hits.load(), 1) << "decode 错误不重试";
}

TEST(Easy, RetryNonIdempotentDefault)
{
    CountingServer srv(1, 503);
    EasyProbe p;
    // POST 默认不重试（非幂等）
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.post("http://127.0.0.1:" + std::to_string(srv.port()) + "/")
                         .body("x")
                         .retry(retries(2))
                         .send();
        EXPECT_EQ(resp.status(), 503);
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
    EXPECT_EQ(srv.hits.load(), 1) << "POST 默认不重试";

    // 打开 retry_non_idempotent 后重试
    CountingServer srv2(1, 503);
    EasyProbe p2;
    p2.run([&]() -> std_exec::task<void> {
        auto resp = co_await p2.client.post("http://127.0.0.1:" + std::to_string(srv2.port()) + "/")
                          .body("x")
                          .retry(retries(2, true))
                          .send();
        EXPECT_EQ(resp.status(), 200);
    }());
    EXPECT_TRUE(p2.done) << p2.error_message();
    EXPECT_FALSE(p2.error);
    EXPECT_EQ(srv2.hits.load(), 2) << "开关打开后 POST 重试";
}

TEST(Easy, RetryAfterHonored)
{
    CountingServer srv(1, 429, 200, "ok", 1); // 429 + Retry-After: 1
    EasyProbe p;
    auto t0 = std::chrono::steady_clock::now();
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("http://127.0.0.1:" + std::to_string(srv.port()) + "/")
                         .retry(retries(1))
                         .send();
        EXPECT_EQ(resp.status(), 200);
    }());
    const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::steady_clock::now() - t0)
                        .count();
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
    EXPECT_EQ(srv.hits.load(), 2);
    EXPECT_GE(ms, 900) << "Retry-After: 1 → 退避 ≥1s（实测 " << ms << "ms）";
}

// ===================== Builder 默认值（§4.2） =====================

TEST(Easy, BuilderDefaultTimeout)
{
    // ClientBuilder::timeout 是逐请求默认值：请求阶段超时生效
    boost::asio::io_context sio;
    boost::asio::ip::tcp::acceptor acc(sio, {boost::asio::ip::tcp::v4(), 0});
    acc.listen();
    const uint16_t port = acc.local_endpoint().port();
    std::thread dumb([&] {
        boost::system::error_code ec;
        auto sock = acc.accept(ec);
        std::this_thread::sleep_for(std::chrono::seconds(1)); // 挂起不响应
        sock.close(ec);
    });

    EasyProbe p([](easy::ClientBuilder& b) {
        b.timeout(std::chrono::milliseconds(150));
    });
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("http://127.0.0.1:" + std::to_string(port) + "/").send();
        (void)resp;
    }());
    dumb.join();
    EXPECT_TRUE(p.done);
    ASSERT_TRUE(p.error_kind_of().has_value());
    EXPECT_EQ(*p.error_kind_of(), easy::error_kind::timeout);
}

TEST(Easy, BuilderDefaultRetry)
{
    // ClientBuilder::retry 是逐请求默认策略：503 自动重试
    CountingServer srv(1, 503);
    EasyProbe p([](easy::ClientBuilder& b) { b.retry(retries(2)); });
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("http://127.0.0.1:" + std::to_string(srv.port()) + "/")
                         .send();
        EXPECT_EQ(resp.status(), 200);
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
    EXPECT_EQ(srv.hits.load(), 2) << "Client 默认重试策略生效";
}

TEST(Easy, DelMethod)
{
    wpt::WptTestServer server("third_party/wpt");
    EasyProbe p;
    p.run([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.del(server.base_url() + "/echo-content.py").send();
        EXPECT_EQ(resp.status(), 200);
        const auto& h = resp.headers();
        auto it = std::find_if(h.begin(), h.end(), [](const fetch::Header& x) {
            return fetch::header_name_eq(x.name, "X-Request-Method");
        });
        EXPECT_NE(it, h.end());
        if (it != h.end())
            EXPECT_EQ(it->value, "DELETE");
    }());
    EXPECT_TRUE(p.done) << p.error_message();
    EXPECT_FALSE(p.error);
}

TEST(Easy, CancelPropagatesStopped)
{
    // 外层取消 → set_stopped 原样传播（非 Error），重试永不拦截 stopped
    boost::asio::io_context sio;
    boost::asio::ip::tcp::acceptor acc(sio, {boost::asio::ip::tcp::v4(), 0});
    acc.listen();
    const uint16_t port = acc.local_endpoint().port();
    std::atomic<int> accepts{0};
    std::thread dumb([&] {
        boost::system::error_code ec;
        auto sock = acc.accept(ec);
        ++accepts;
        std::this_thread::sleep_for(std::chrono::seconds(1)); // 挂起不响应
        sock.close(ec);
    });

    EasyProbe p;
    stdexec::inplace_stop_source src;
    std::thread canceler([&] {
        std::this_thread::sleep_for(std::chrono::milliseconds(150));
        src.request_stop(); // 请求挂起中取消
    });
    p.run_stoppable([&]() -> std_exec::task<void> {
        auto resp = co_await p.client.get("http://127.0.0.1:" + std::to_string(port) + "/")
                         .retry(retries(3)) // 取消不得触发重试
                         .send();
        (void)resp;
    }(), src);
    canceler.join();
    dumb.join();
    EXPECT_TRUE(p.done);
    EXPECT_TRUE(p.stopped) << "取消 → set_stopped 传播";
    EXPECT_FALSE(p.error) << p.error_message();
    EXPECT_EQ(accepts.load(), 1) << "取消后不重试";
}
