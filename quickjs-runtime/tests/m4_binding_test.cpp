// M4 打磨验收测试：qjs::Function 回调、Module 导出、异步方法糖、多 Runtime 并行、端到端
//
// 验收（设计文档 §12 M4）：
//   - 端到端示例（§11）跑通
//   - qjs::Function 回调：JS 函数作参数传入 C++ 并调用
//   - Module 导出：ESM import 原生模块（func + class）
//   - 异步方法糖：method 注册 This<Counter> + std_exec::task 自由函数
//   - 多 Runtime 并行：两个 Runtime 各一线程 + channel 互通 + 统一 stop/join
#include <atomic>
#include <qjsbind/std_exec.hpp>
#include <chrono>
#include <memory>
#include <string>
#include <thread>

#include <boost/asio/steady_timer.hpp>
#include <dart_cpp_bridge/channel.hpp>
#include <exec/asio/use_sender.hpp>
#include <stdexec/execution.hpp>
#include <gtest/gtest.h>
#include <qjsbind/qjsbind.hpp>

using namespace qjs;

namespace {

// ================= 端到端（§11）素材 =================
double add(double a, double b) { return a + b; }

// 异步自由函数：无 Ctx 参数，经 current_io() 拿事件循环（§11 示例）
std_exec::task<std::string> greet_after(std::string name, double ms)
{
    auto timer = std::make_shared<boost::asio::steady_timer>(
        current_io(), boost::asio::chrono::milliseconds(static_cast<long long>(ms)));
    co_await timer->async_wait(exec::asio::use_sender);
    co_return "hello, " + name;
}

struct Counter {
    int value = 0;
    int add(int d) { return value += d; }
};

// 模块导出用的类（有 int 构造）
struct Point {
    int value;
    explicit Point(int v) : value(v) {}
};

// 异步方法糖：This<Counter> + std_exec::task 自由函数，method() 注册
std_exec::task<int> counter_add_later(This<Counter> self, int d, double ms)
{
    auto timer = std::make_shared<boost::asio::steady_timer>(
        current_io(), boost::asio::chrono::milliseconds(static_cast<long long>(ms)));
    co_await timer->async_wait(exec::asio::use_sender);
    co_return self->add(d);
}

// ================= qjs::Function 回调素材 =================
// JS 函数作参数：回调 x+1，结果×2
double apply_twice(Function fn, double x)
{
    return fn.call(x).as<double>() * 2;
}
// 回调抛异常 → Function::call 抛 js_error → C++ 函数转成 JS 异常传播
double call_boom(Function fn)
{
    return fn.call(1).as<double>();
}

struct M4Fixture : ::testing::Test {
    Runtime rt;
    Context ctx = rt.main_context();
    Object globals = ctx.globals();
};

// ================= 端到端（§11 精简：自由函数 + 异步 + 类 + Promise.all）=================
TEST_F(M4Fixture, EndToEnd)
{
    globals.set("add", add);
    globals.set("greetAfter", greet_after);
    qjs::class_<Counter> cls(ctx, "Counter");
    cls.constructor<>().method("add", &Counter::add).method("addLater", counter_add_later)
        .field("value", &Counter::value);
    globals.set("Counter", cls.constructor_function());

    Value r = ctx.eval(R"(
        const c = new Counter();
        c.add(5);
        Promise.all([greetAfter("qjs", 5), c.addLater(2, 5)])
          .then(([g, total]) => { globalThis.__g = g; globalThis.__total = total; globalThis.__v = c.value; });
        'ok';
    )");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__g").as<std::string>(), "hello, qjs");
    EXPECT_EQ(ctx.eval("__total").as<double>(), 7.0); // addLater 返回 self->add(2) = value(5)+2
    EXPECT_EQ(ctx.eval("__v").as<double>(), 7.0);     // c.value = 5 + 2
}

// ================= qjs::Function 回调 =================
TEST_F(M4Fixture, FunctionCallback)
{
    globals.set("applyTwice", apply_twice);
    Value r = ctx.eval("applyTwice(v => v + 1, 10);");
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(r.as<double>(), 22.0); // (10+1)*2
}

TEST_F(M4Fixture, FunctionCallbackNonFunctionTypeError)
{
    globals.set("applyTwice", apply_twice);
    Value r = ctx.eval("applyTwice(42, 10);"); // 非函数 → from_js TypeError → JS 异常
    ASSERT_TRUE(r.is_exception());
}

TEST_F(M4Fixture, FunctionCallbackThrowsPropagates)
{
    globals.set("callBoom", call_boom);
    // 回调抛 JS 异常 → Function::call 抛 js_error → thunk 边界转回 JS 异常
    Value r = ctx.eval(
        "try { callBoom(() => { throw new Error('cb-boom'); }); 'no-throw'; }"
        "catch (e) { e.message; }");
    ASSERT_FALSE(r.is_exception());
    EXPECT_NE(r.as<std::string>().find("cb-boom"), std::string::npos);
}

// ================= Module 导出 =================
TEST_F(M4Fixture, ModuleExport)
{
    Module mod(ctx.raw(), "my:native");
    mod.function("add", [](double a, double b) { return a + b; });
    qjs::class_<Point> pc(ctx, "Point");
    pc.constructor<int>().field("value", &Point::value);
    mod.class_(std::move(pc));

    Value r = ctx.eval(
        "import { add as nadd, Point } from 'my:native';"
        "const p = new Point(3);"
        "globalThis.__mod = nadd(2, 3);"
        "globalThis.__px = p.value;",
        "<m4-module>", JS_EVAL_TYPE_MODULE);
    ASSERT_FALSE(r.is_exception());
    EXPECT_EQ(ctx.eval("__mod").as<double>(), 5.0);
    EXPECT_EQ(ctx.eval("__px").as<double>(), 3.0);
}

// ================= 异步方法糖（This + task）=================
TEST_F(M4Fixture, AsyncMethodSugar)
{
    qjs::class_<Counter> cls(ctx, "Counter");
    cls.constructor<>().method("addLater", counter_add_later).field("value", &Counter::value);
    globals.set("Counter", cls.constructor_function());
    Value r = ctx.eval(
        "const c = new Counter();"
        "c.addLater(2, 5).then(v => { globalThis.__later = v; globalThis.__lv = c.value; });"
        "'ok';");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__later").as<double>(), 2.0);
    EXPECT_EQ(ctx.eval("__lv").as<double>(), 2.0); // c.value 被异步方法更新
}

// ================= 多 Runtime 并行 + channel 互通 + 统一 stop/join =================
TEST_F(M4Fixture, MultiRuntimeChannelAndStop)
{
    Runtime rtA("runtime-A");
    Runtime rtB("runtime-B");
    EXPECT_NE(rtA.id(), rtB.id()); // 自定义 id 生效

    auto [tx, rx] = co::oneshot::channel<int>();

    int a_result = -1;
    std::thread ta([&] {
        // rtA 线程：JS 初始化 + 发值 + 服务模式 run
        Context ctxA = rtA.main_context();
        ctxA.globals().set("sendToB", [&tx](int v) { tx.send(v); }); // send 任意线程
        ctxA.eval("sendToB(41);");
        rtA.run();
        a_result = 0; // rtA 正常关闭
    });

    int b_result = -1;
    std::thread tb([&] {
        // rtB 线程：JS 初始化 + run（主线程 post 来的 handler 在 rtB 线程执行）
        Context ctxB = rtB.main_context();
        ctxB.globals().set("__fromA", 0);
        rtB.run();
        b_result = ctxB.eval("__fromA").as<int>(); // rtB 线程内断言读值
    });

    // 主线程：等 channel 值 → post 到 rtB 事件循环（跨线程、asio 线程安全）
    auto received = stdexec::sync_wait(std::move(rx));
    ASSERT_TRUE(received.has_value()) << "channel 未收到 rtA 的值";
    EXPECT_EQ(std::get<0>(*received), 41);
    boost::asio::post(rtB.io(), [&] {
        rtB.main_context().eval("__fromA = 41;"); // 在 rtB 线程（run 线程）执行 ✓
    });

    // 统一 stop（任意线程）+ join
    rtA.stop();
    rtB.stop();
    ta.join();
    tb.join();
    EXPECT_EQ(a_result, 0);
    EXPECT_EQ(b_result, 41);
}

} // namespace
