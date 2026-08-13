// M3 异步绑定验收测试：sender → Promise + 事件循环
//
// 验收（设计文档 §12 M3）：
//   - 协程函数 JS 侧 await 成功（std_exec::task 自动识别为 Promise）
//   - asio timer 联通（use_sender）
//   - C++ 异常 → reject
//   - 取消（stop）→ AbortError reject
//   - run_to_completion 退出判据（pending_ == 0）
#include <atomic>
#include <qjsbind/std_exec.hpp>
#include <chrono>
#include <thread>
#include <exception>
#include <string>

#include <boost/asio/steady_timer.hpp>
#include <exec/asio/use_sender.hpp>
#include <stdexec/execution.hpp>
#include <gtest/gtest.h>
#include <qjsbind/qjsbind.hpp>

using namespace qjs;

namespace {

// ---- 异步被测函数（自由函数，MSVC 协程限制，设计文档 §10.1）----
std_exec::task<int> add_async(int a, int b)
{
    co_return a + b; // 同步完成的 task：无 suspend 点
}

std_exec::task<double> wait_and_value(Ctx c, double v, int ms)
{
    // Ctx 注入 → 拿 runtime 的 io_context；timer 生命周期由协程帧保证
    auto timer = std::make_shared<boost::asio::steady_timer>(
        runtime_of(c.ctx).io(), boost::asio::chrono::milliseconds(ms));
    co_await timer->async_wait(exec::asio::use_sender);
    co_return v;
}

std_exec::task<std::string> fail_async()
{
    throw std::runtime_error("async-boom");
    co_return "";
}

// 协作式取消：任务轮询 stop token，被取消则提前完成（resolve 带标记）
// started 是确定性同步点：协程真正开始轮询后置位（避免 stop 时序竞态）
std_exec::task<std::string> cancellable_poll(Ctx c, std::shared_ptr<std::atomic<bool>> started,
    std::string msg)
{
    auto stop = co_await stdexec::get_stop_token();
    started->store(true);
    // 短步长（1ms）轮询 stop；asio timer 不响应 stdexec stop，但任务主动检查
    for (int i = 0; i < 20000 && !stop.stop_requested(); ++i) {
        auto timer = std::make_shared<boost::asio::steady_timer>(runtime_of(c.ctx).io(),
            boost::asio::chrono::milliseconds(1));
        co_await timer->async_wait(exec::asio::use_sender);
    }
    co_return msg + (stop.stop_requested() ? ":cancelled" : ":timeout");
}

// 立即 set_stopped 的 sender（验证 set_stopped → AbortError reject 管道）
std_exec::task<void> stop_now()
{
    co_await stdexec::just_stopped();
    co_return;
}

struct M3Fixture : ::testing::Test {
    Runtime rt;
    Context ctx = rt.main_context();
    Object globals = ctx.globals();
};

// ---- 协程函数 → Promise，run_to_completion 驱动 ----
TEST_F(M3Fixture, CoroutineAwait)
{
    globals.set("addAsync", add_async);
    // JS 侧 .then 存结果（顶层 await 走 §8.5 变体，M3 用 then 模式）
    Value r = ctx.eval("addAsync(2, 3).then(v => { globalThis.__r = v; }); 'ok'");
    ASSERT_FALSE(r.is_exception());
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<double>(), 5.0);
}

// ---- 同步完成的 task 也是 sender：同路径 ----
TEST_F(M3Fixture, SyncTaskIsPromise)
{
    globals.set("addAsync", add_async);
    ctx.eval("addAsync(10, 32).then(v => { globalThis.__r = v; });");
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<double>(), 42.0);
}

// ---- asio timer 联通（use_sender）----
TEST_F(M3Fixture, AsioTimer)
{
    globals.set("waitAndValue", wait_and_value);
    ctx.eval("waitAndValue(3.14, 5).then(v => { globalThis.__r = v; });");
    rt.run_to_completion(); // timer 触发 → 结算 → 排干
    EXPECT_EQ(ctx.eval("__r").as<double>(), 3.14);
}

// ---- C++ 异常 → reject ----
TEST_F(M3Fixture, ExceptionRejects)
{
    globals.set("failAsync", fail_async);
    ctx.eval("failAsync().then(() => {}, e => { globalThis.__err = e.message; });");
    rt.run_to_completion();
    std::string msg = ctx.eval("__err").as<std::string>();
    EXPECT_NE(msg.find("async-boom"), std::string::npos);
}

// ---- stop() 传播到任务（std_exec::task 取消语义：stop → 任务 set_stopped → AbortError reject）----
TEST_F(M3Fixture, StopPropagatesToTask)
{
    auto started = std::make_shared<std::atomic<bool>>(false);
    globals.set("cancellablePoll", [started](Ctx c, std::string msg) {
        return cancellable_poll(c, started, std::move(msg));
    });
    // 任务挂起在 timer await 时收到 stop：std_exec::task 走 set_stopped（协程体不再继续），
    // 结算为 AbortError reject（设计文档 §5.5/§8.3）
    ctx.eval(
        "cancellablePoll('t').then(v => { globalThis.__r = v; }, e => { globalThis.__err = e.name; });");
    // 线程模型（设计文档 §1）：JS 操作全部在 JS 线程（本测试线程）；
    // run() 在 JS 线程，stop() 从别的线程（任意线程可调，只碰 io_）
    std::thread stopper([&] {
        for (int i = 0; i < 500 && !started->load(); ++i)
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        ASSERT_TRUE(started->load()) << "task did not start";
        rt.stop();
    });
    rt.run(); // JS 线程服务模式：stop() 后 shutdown 收尾（取消 → AbortError → 排干）
    stopper.join();
    EXPECT_EQ(ctx.eval("__err").as<std::string>(), "AbortError");
    EXPECT_TRUE(ctx.eval("typeof __r === 'undefined'").as<bool>()); // resolve 未发生
}

// ---- set_stopped → AbortError reject（取消结算管道）----
TEST_F(M3Fixture, StoppedRejectsAbortError)
{
    globals.set("stopNow", stop_now);
    ctx.eval("stopNow().then(v => { globalThis.__r = v; }, e => { globalThis.__err = e.name; });");
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__err").as<std::string>(), "AbortError");
    EXPECT_TRUE(ctx.eval("typeof __r === 'undefined'").as<bool>()); // __r 从未赋值（resolve 未发生）
}

// ---- pending_ 计数：run_to_completion 在无在飞任务时退出 ----
TEST_F(M3Fixture, RunToCompletionExitsWhenIdle)
{
    globals.set("addAsync", add_async);
    // 同步函数（无异步任务）：pending_ 恒 0，run_to_completion 立即退出
    globals.set("add", [](double a, double b) { return a + b; });
    ctx.eval("add(1, 2);");
    rt.run_to_completion();
    EXPECT_EQ(rt.pending(), 0);
}

// ---- 手动 promise_from_sender（sender 对象 → Promise）----
TEST_F(M3Fixture, PromiseFromSenderManual)
{
    globals.set("makePromise", [](Ctx c, double v) {
        auto sndr = stdexec::just(v);
        return Value(c.ctx, promise_from_sender(c.ctx, std::move(sndr)));
    });
    ctx.eval("makePromise(7).then(v => { globalThis.__r = v; });");
    rt.run_to_completion();
    EXPECT_EQ(ctx.eval("__r").as<double>(), 7.0);
}

} // namespace
