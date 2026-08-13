// dynamic_call_test.cpp —— 动态调用（docs/dynamic_call_design.md v1）验收测试
//
// 覆盖（设计文档 §8）：
//   - sync / async 基本调用（参数 JSON 序列化 + 返回值 JSON 解析）
//   - host 表优先于全局表（D1）
//   - 两个 Runtime 的 host 表互相隔离且共享全局表
//   - call 只服务异步 handler（未注册 async → reject not found）；callSync 命中
//     异步函数报错；同步/异步两表互不回落
//   - 未注册报错（sync throw / async reject，Error 同名）
//   - 不可序列化参数（循环引用 → TypeError，sync 抛 / async 同步抛）
//   - host_id 自动注入正确（handler 第一个参数）
//   - handler 返回非法 JSON → SyntaxError（sync throw / async reject）
//   - handler 抛 C++ 异常（sync throw / async reject）
//   - 注册/注销/remove_host 生命周期
//   - 同名 sync/async 双注册互不干扰
#include <chrono>
#include <memory>
#include <numeric>
#include <string>
#include <utility>
#include <vector>

#include <boost/asio/steady_timer.hpp>
#include <exec/asio/use_sender.hpp>
#include <glaze/glaze.hpp>
#include <gtest/gtest.h>
#include <qjsbind/dynamic_call.hpp>
#include <qjsbind/qjsbind.hpp>

using namespace qjs;

namespace {

// ---- 测试用 handler 素材 ----

// sync 加法：解析 [a,b,...] → 求和 → JSON 输出
std::string sync_add(std::string_view, std::string_view, std::string_view args)
{
    auto v = glz::read_json<std::vector<double>>(args);
    if (!v)
        throw std::runtime_error(glz::format_error(v.error(), args));
    auto out = glz::write_json(std::accumulate(v->begin(), v->end(), 0.0));
    return std::move(*out);
}

// 验证 host_id 注入 + name 透传：返回 "host_id|name|args_json"
std::string sync_echo(std::string_view host_id, std::string_view name, std::string_view args)
{
    auto v = glz::read_json<std::vector<std::string>>(args);
    if (!v)
        throw std::runtime_error("bad args");
    auto out = glz::write_json(
        std::string(host_id) + "|" + std::string(name) + "|" + std::string(args));
    return std::move(*out);
}

// 真异步加法：解析 → 求和 → 异步等 2ms → JSON 输出（覆盖 §6.3 线程模型）
std_exec::task<std::string> async_add(std::string, std::string, std::string args)
{
    auto v = glz::read_json<std::vector<double>>(args);
    if (!v)
        throw std::runtime_error(glz::format_error(v.error(), args));
    double s = std::accumulate(v->begin(), v->end(), 0.0);
    auto timer = std::make_shared<boost::asio::steady_timer>(
        qjs::current_io(), std::chrono::milliseconds(2));
    co_await timer->async_wait(exec::asio::use_sender);
    auto out = glz::write_json(s);
    co_return std::move(*out);
}

// 异步 handler 抛异常 → Promise reject（真协程：co_await 挂起后抛，被 task 捕获转 error）
std_exec::task<std::string> async_boom(std::string, std::string, std::string)
{
    auto timer = std::make_shared<boost::asio::steady_timer>(
        qjs::current_io(), std::chrono::milliseconds(1));
    co_await timer->async_wait(exec::asio::use_sender);
    throw std::runtime_error("async boom");
}

// ---- 单 Runtime fixture ----
struct DynFixture : ::testing::Test {
    Runtime rt;
    Context ctx = rt.main_context();

    void SetUp() override
    {
        dyn::install_dynamic_call(ctx);
    }

    // eval 后断言无异常
    Value eval_ok(const char* code)
    {
        Value r = ctx.eval(code);
        EXPECT_FALSE(r.is_exception());
        return r;
    }
};

// ================= 基本调用 =================

TEST_F(DynFixture, SyncBasic)
{
    dyn::register_global("add", sync_add);
    EXPECT_EQ(eval_ok("callSync('add', 1, 2, 3);").as<double>(), 6.0);
    EXPECT_EQ(eval_ok("callSync('add', 1.5, 2.25);").as<double>(), 3.75);
    // 无参数 → "[]"；对象/嵌套数组/字符串/布尔/null 均支持
    EXPECT_EQ(eval_ok("callSync('add');").as<double>(), 0.0);
}

TEST_F(DynFixture, SyncReturnNull)
{
    dyn::register_global("nothing", [](std::string_view, std::string_view,
                                       std::string_view) -> std::string {
        return "null"; // handler 返回 "null" 即 JS 的 null
    });
    Value r = eval_ok("callSync('nothing');");
    EXPECT_TRUE(r.is_null());
}

TEST_F(DynFixture, AsyncBasic)
{
    dyn::register_global_async("addAsync", async_add);
    ASSERT_FALSE(
        eval_ok("call('addAsync', 1, 2, 3).then(v => { globalThis.__r = v; }); 'ok';")
            .is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<double>(), 6.0);
}

TEST_F(DynFixture, AsyncReturnsObject)
{
    // async handler 返回对象 JSON
    dyn::register_global_async(
        "info", [](std::string, std::string, std::string) -> std_exec::task<std::string> {
            auto out = glz::write_json(std::vector<int>{1, 2, 3});
            co_return std::move(*out);
        });
    ASSERT_FALSE(
        eval_ok("call('info').then(v => { globalThis.__a = v; }); 'ok';").is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("JSON.stringify(__a)").as<std::string>(), "[1,2,3]");
}

// ================= D1：host 表优先于全局表 =================

TEST_F(DynFixture, HostOverridesGlobal)
{
    dyn::register_global("who", [](std::string_view, std::string_view,
                                   std::string_view) -> std::string { return "\"global\""; });
    dyn::register_host(rt.id(), "who", [](std::string_view, std::string_view,
                                          std::string_view) -> std::string { return "\"host\""; });
    // 本 host 命中自己的表
    EXPECT_EQ(eval_ok("callSync('who');").as<std::string>(), "host");
    // 其他 host 的覆盖不影响本 host（仍命中本 host 表）
    dyn::register_host("other-host", "who", [](std::string_view, std::string_view,
                                               std::string_view) -> std::string {
        return "\"other\"";
    });
    EXPECT_EQ(eval_ok("callSync('who');").as<std::string>(), "host");
    // 未覆盖的名字 → 回落全局表
    dyn::register_global("globalTag", [](std::string_view, std::string_view,
                                         std::string_view) -> std::string {
        return "\"global-tag\"";
    });
    EXPECT_EQ(eval_ok("callSync('globalTag');").as<std::string>(), "global-tag");
}

// ================= 两个 Runtime：host 表隔离 + 共享全局表 =================

TEST(DynTest, TwoRuntimesIsolation)
{
    Runtime rtA("host-A");
    Runtime rtB("host-B");
    Context ctxA = rtA.main_context();
    Context ctxB = rtB.main_context();
    dyn::install_dynamic_call(ctxA);
    dyn::install_dynamic_call(ctxB);
    // 全局表共享（含同名 "tag"：B 注销后回落它）
    dyn::register_global("shared", [](std::string_view, std::string_view,
                                      std::string_view) -> std::string { return "\"g\""; });
    dyn::register_global("tag", [](std::string_view, std::string_view,
                                   std::string_view) -> std::string { return "\"g-tag\""; });
    // 各自 host 表同名不同体
    dyn::register_host("host-A", "tag", [](std::string_view, std::string_view,
                                           std::string_view) -> std::string { return "\"A\""; });
    dyn::register_host("host-B", "tag", [](std::string_view, std::string_view,
                                           std::string_view) -> std::string { return "\"B\""; });

    EXPECT_EQ(ctxA.eval("callSync('tag');").as<std::string>(), "A");
    EXPECT_EQ(ctxB.eval("callSync('tag');").as<std::string>(), "B");
    EXPECT_EQ(ctxA.eval("callSync('shared');").as<std::string>(), "g");
    EXPECT_EQ(ctxB.eval("callSync('shared');").as<std::string>(), "g");

    // 注销 B 的 host 注册 → B 回落全局表同名注册
    dyn::unregister_host("host-B", "tag");
    EXPECT_EQ(ctxB.eval("callSync('tag');").as<std::string>(), "g-tag");

    // 析构时 remove_host：A 的表消失，但全局表仍可用
    // （rtA/rtB 在此析构；先验证 remove_host 前 A 正常）
    EXPECT_EQ(ctxA.eval("callSync('tag');").as<std::string>(), "A");
}

// remove_host 生命周期：整表移除后回落全局，不悬挂
TEST_F(DynFixture, RemoveHostLifecycle)
{
    dyn::register_global("who", [](std::string_view, std::string_view,
                                   std::string_view) -> std::string { return "\"global\""; });
    dyn::register_host(rt.id(), "who", [](std::string_view, std::string_view,
                                          std::string_view) -> std::string { return "\"host\""; });
    EXPECT_EQ(eval_ok("callSync('who');").as<std::string>(), "host");
    dyn::remove_host(rt.id());
    // host 表没了：回落全局表（thunk 不悬挂，仍可用）
    EXPECT_EQ(eval_ok("callSync('who');").as<std::string>(), "global");
}

// ================= call 只认异步；callSync 只认同步（互不回落）=================

// call 只服务异步 handler：未注册 async 版 → reject not found（不回落到 sync 表）
TEST_F(DynFixture, AsyncRejectsIfOnlySyncRegistered)
{
    dyn::register_global("add", sync_add); // 只注册 sync 版
    ASSERT_FALSE(
        eval_ok("call('add', 2, 3).then(v => { globalThis.__r = v; }, "
                "e => { globalThis.__r = 'REJECTED:' + e.message; }); 'ok';")
            .is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<std::string>().find("REJECTED:"), 0u);
    // callSync 照常同步使用（两表互不越界）
    EXPECT_EQ(eval_ok("callSync('add', 2, 3);").as<double>(), 5.0);
}

TEST_F(DynFixture, CallSyncOnAsyncThrows)
{
    dyn::register_global_async("onlyAsync", async_add);
    Value r = eval_ok("try { callSync('onlyAsync', 1); 'no-throw'; } catch (e) { e.message; }");
    EXPECT_NE(r.as<std::string>().find("not found"), std::string::npos);
}

// ================= 错误模型（设计文档 §7）=================

TEST_F(DynFixture, NotFoundSync)
{
    Value r = eval_ok("try { callSync('nope'); 'no-throw'; } catch (e) { e.name + ':' + e.message; }");
    EXPECT_EQ(r.as<std::string>(), "Error:dyn_call: 'nope' not found (host '" + rt.id() + "')");
}

TEST_F(DynFixture, NotFoundAsync)
{
    ASSERT_FALSE(
        eval_ok("call('nope').then(() => 'resolved', e => { globalThis.__err = e.name + ':' + e.message; }); 'ok';")
            .is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__err").as<std::string>(),
              "Error:dyn_call: 'nope' not found (host '" + rt.id() + "')");
}

TEST_F(DynFixture, UnserializableArgs)
{
    dyn::register_global("add", sync_add);
    // 循环引用 → stringify 失败 → TypeError（sync 抛）
    Value r = eval_ok("const a = {}; a.self = a; try { callSync('add', a); 'no-throw'; } "
                      "catch (e) { e.name; }");
    EXPECT_EQ(r.as<std::string>(), "TypeError");
    // async 版：thunk 入口即失败，同步抛（§7）
    Value r2 = eval_ok("const b = {}; b.self = b; try { call('add', b); 'no-throw'; } "
                       "catch (e) { e.name; }");
    EXPECT_EQ(r2.as<std::string>(), "TypeError");
    // 无异常残留：异常被正确消费后仍可正常调用
    EXPECT_EQ(eval_ok("callSync('add', 1, 2);").as<double>(), 3.0);
}

TEST_F(DynFixture, InvalidJsonReturn)
{
    dyn::register_global("bad", [](std::string_view, std::string_view,
                                   std::string_view) -> std::string { return "{not-json"; });
    // sync：SyntaxError
    Value r = eval_ok("try { callSync('bad'); 'no-throw'; } catch (e) { e.name; }");
    EXPECT_EQ(r.as<std::string>(), "SyntaxError");
    // async 只认异步 handler：注册 async 版返回非法 JSON → reject SyntaxError
    dyn::register_global_async(
        "badAsync", [](std::string, std::string, std::string) -> std_exec::task<std::string> {
            co_return "{not-json";
        });
    ASSERT_FALSE(
        eval_ok("call('badAsync').then(() => { globalThis.__bad = 'resolved'; }, "
                "e => { globalThis.__bad = e.name; }); 'ok';")
            .is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__bad").as<std::string>(), "SyntaxError");
}

TEST_F(DynFixture, HandlerException)
{
    dyn::register_global("boom", [](std::string_view, std::string_view,
                                    std::string_view) -> std::string {
        throw std::runtime_error("sync boom");
    });
    // sync：throw（qjsbind 出口统一捕获 → InternalError）
    Value r = eval_ok("try { callSync('boom'); 'no-throw'; } catch (e) { e.message; }");
    EXPECT_NE(r.as<std::string>().find("sync boom"), std::string::npos);

    // async（真异步 handler）：reject
    dyn::register_global_async("boomAsync", async_boom);
    ASSERT_FALSE(
        eval_ok("call('boomAsync').then(() => { globalThis.__b = 'resolved'; }, "
                "e => { globalThis.__b = e.message; }); 'ok';")
            .is_exception());
    rt.run_to_completion();
    EXPECT_NE(ctx.eval("__b").as<std::string>().find("async boom"), std::string::npos);
}

// ================= host_id 自动注入（设计文档 §0/§3.1）=================

TEST_F(DynFixture, HostIdInjected)
{
    dyn::register_global("echo", sync_echo);
    Value r = eval_ok("callSync('echo', 'x', 'y');");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<std::string>(), rt.id() + "|echo|[\"x\",\"y\"]");
    // async 路径同样注入
    dyn::register_global_async("echoAsync", [](std::string host_id, std::string name,
                                               std::string args) -> std_exec::task<std::string> {
        auto out = glz::write_json(host_id + "|" + name + "|" + args);
        co_return std::move(*out);
    });
    ASSERT_FALSE(
        eval_ok("call('echoAsync', 'y').then(v => { globalThis.__e = v; }); 'ok';")
            .is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__e").as<std::string>(), rt.id() + "|echoAsync|[\"y\"]");
}

// ================= 注册/注销 =================

TEST_F(DynFixture, Unregister)
{
    dyn::register_global("tmp", sync_add);
    EXPECT_EQ(eval_ok("callSync('tmp', 1);").as<double>(), 1.0);
    dyn::unregister_global("tmp");
    Value r = eval_ok("try { callSync('tmp', 1); 'no-throw'; } catch (e) { e.name; }");
    EXPECT_EQ(r.as<std::string>(), "Error");

    // host 表注销：仅删本 host 的，全局同名不受影响
    dyn::register_global("who", [](std::string_view, std::string_view,
                                   std::string_view) -> std::string { return "\"global\""; });
    dyn::register_host(rt.id(), "who", [](std::string_view, std::string_view,
                                          std::string_view) -> std::string { return "\"host\""; });
    dyn::unregister_host(rt.id(), "who");
    EXPECT_EQ(eval_ok("callSync('who');").as<std::string>(), "global");
}

// 重复注册同名：后注册生效（覆盖语义）
TEST_F(DynFixture, ReRegisterOverwrites)
{
    dyn::register_global("v", [](std::string_view, std::string_view,
                                 std::string_view) -> std::string { return "\"first\""; });
    dyn::register_global("v", [](std::string_view, std::string_view,
                                 std::string_view) -> std::string { return "\"second\""; });
    EXPECT_EQ(eval_ok("callSync('v');").as<std::string>(), "second");
}

// 同名 sync/async 双注册互不干扰（§4：同名不同体合法）
TEST_F(DynFixture, SameNameBothTables)
{
    dyn::register_global("f", [](std::string_view, std::string_view,
                                 std::string_view) -> std::string { return "\"sync\""; });
    dyn::register_global_async(
        "f", [](std::string, std::string, std::string) -> std_exec::task<std::string> {
            co_return "\"async\"";
        });
    EXPECT_EQ(eval_ok("callSync('f');").as<std::string>(), "sync");
    ASSERT_FALSE(
        eval_ok("call('f').then(v => { globalThis.__f = v; }); 'ok';").is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__f").as<std::string>(), "async");
    // 注销全局：sync/async 两张表都删（§3.2）→ 两个入口都报 not found
    dyn::unregister_global("f");
    Value r = eval_ok("try { callSync('f'); 'no-throw'; } catch (e) { e.name; }");
    EXPECT_EQ(r.as<std::string>(), "Error");
    ASSERT_FALSE(
        eval_ok("call('f').then(() => 'resolved', e => { globalThis.__f2 = e.name; }); 'ok';")
            .is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__f2").as<std::string>(), "Error");
}

// 重复 install 幂等（§6 生命周期）
TEST_F(DynFixture, ReinstallIdempotent)
{
    dyn::register_global("add", sync_add);
    dyn::register_global_async(
        "addAsync", [](std::string, std::string, std::string) -> std_exec::task<std::string> {
            auto out = glz::write_json(42.0);
            co_return std::move(*out);
        });
    dyn::install_dynamic_call(ctx); // 重复 install 不报错
    dyn::install_dynamic_call(ctx);
    EXPECT_EQ(eval_ok("callSync('add', 2, 3);").as<double>(), 5.0);
    ASSERT_FALSE(
        eval_ok("call('addAsync').then(v => { globalThis.__r = v; }); 'ok';").is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<double>(), 42.0);
}

// 异步 handler 内做真正的后台工作（continues_on 线程池语义由 handler 自理）：
// 这里验证 async 调用的 task 由调用方 Runtime spawn 且 run_to_completion 会等待
TEST_F(DynFixture, AsyncHandlerConcurrentCalls)
{
    dyn::register_global_async("addAsync", async_add);
    ASSERT_FALSE(
        eval_ok("Promise.all([call('addAsync', 1, 2), call('addAsync', 10, 20)])"
                ".then(([a, b]) => { globalThis.__sum = a + b; }); 'ok';")
            .is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__sum").as<double>(), 33.0);
}

} // namespace
