// 任务系统验收测试：基础层 TaskRunner（可取消调用）+ 扩展层 TaskPool（debug 池）
//
// 覆盖（docs/debug_pool_design.md）：
//   - TaskRunner：同步/异步任务、三路取消（Queued 摘除 / Running 闭包+signal /
//     interrupt 同步卡死）、fetch signal 取消链路
//   - TaskPool：懒创建并发、热重载（含语法错误保留旧实例）、运行中取消、
//     shutdown（队列置 cancelled）、"settle 未调用"兜底、池内 fetch 取消
#include <gtest/gtest.h>
#include <qjsbind/qjsbind.hpp>
#include <qjsbind/task.hpp>
#include <qjsbind/task_pool.hpp>
#include <qjsbind/web/web.hpp>
#include <dart_cpp_bridge/channel.hpp>
#include <stdexec/execution.hpp>
#include "wpt_server.hpp"

#include <boost/asio/io_context.hpp>
#include <boost/asio/steady_timer.hpp>
#include <exec/asio/use_sender.hpp>

#include <atomic>
#include <chrono>
#include <filesystem>
#include <fstream>
#include <thread>

#ifdef _WIN32
#include <windows.h>
#endif

using namespace qjs;

namespace {

// ================= 临时脚本文件辅助 =================
// 临时脚本放测试进程 cwd 下的固定子目录（ctest 的测试进程 cwd = build 目录，
// 保证可写）。不要依赖 temp_directory_path()：在部分环境（如 MSYS bash 启动
// 的 make 丢失 TMP/LOCALAPPDATA 后）GetTempPath 会回退到不可写的
// C:\Windows\Temp，导致脚本创建失败、池 worker 读不到源码。
std::filesystem::path make_script(const std::string& content)
{
    static std::atomic<uint64_t> n{0};
    auto dir = std::filesystem::current_path() / "pool_test_tmp";
    std::error_code ec;
    std::filesystem::create_directories(dir, ec);
    auto p = dir / ("quickjs_pool_test_" +
#ifdef _WIN32
                    std::to_string(::GetCurrentProcessId()) +
#else
                    "x" +
#endif
                    "_" + std::to_string(n.fetch_add(1)) + ".js");
    std::ofstream f(p, std::ios::binary | std::ios::trunc);
    f << content;
    f.close();
    return p;
}

void write_script(const std::filesystem::path& p, const std::string& content)
{
    std::ofstream f(p, std::ios::binary | std::ios::trunc);
    f << content;
    f.close();
}

// sync_wait 解包（completion 是 tuple<optional<T>>）
std::optional<TaskResult> wait_result(co::oneshot::Receiver<TaskResult>&& rx)
{
    auto v = stdexec::sync_wait(std::move(rx));
    if (!v)
        return std::nullopt;
    return std::get<0>(*v);
}

// 池 worker 注册：native 异步 sleep（真 spawn，计入 pending_；setTimeout 不计——
// 设计文档 §6 已知限制，池异步测试统一走 sleepMs）
void register_sleep_binding(qjs::Context& c)
{
    c.globals().set(
        "sleepMs",
        qjs::func(c.raw(),
                  [](double ms, double v) -> std_exec::task<double> {
                      auto timer = std::make_shared<boost::asio::steady_timer>(
                          qjs::current_io(),
                          boost::asio::chrono::milliseconds(
                              static_cast<long long>(ms)));
                      co_await timer->async_wait(exec::asio::use_sender);
                      co_return v;
                  },
                  "sleepMs"));
}

// ================= 基础层：TaskRunner（共享实例 + 服务模式）=================
struct RunnerFixture : ::testing::Test {
    Runtime rt;
    fetch::Client client{}; // 先于 ctx 声明（析构逆序）
    Context ctx = rt.main_context();
    TaskRunner runner{rt}; // 构造（主线程，rt 空闲）：装 trampoline + interrupt handler

    RunnerFixture()
    {
        qjsbind::web::install_web_apis(ctx, client); // setTimeout/fetch/AbortSignal 等
    }
};

TEST_F(RunnerFixture, SubmitSyncTask)
{
    ctx.eval("globalThis.addOne = ({x}) => x + 1;");
    std::thread js_thread([&] { rt.run(); }); // 服务模式（§8.2 模式 A）
    auto h = runner.submit({"addOne", "{\"x\":41}"});
    auto res = wait_result(std::move(h.result_rx));
    rt.stop();
    js_thread.join();
    ASSERT_TRUE(res.has_value());
    ASSERT_TRUE(res->ok) << res->json;
    EXPECT_EQ(res->json, "42");
}

TEST_F(RunnerFixture, SubmitAsyncTask)
{
    ctx.eval("globalThis.asyncAdd = async ({x, ms}) => {"
             "  await new Promise(r => setTimeout(r, ms)); return x + 1; };");
    std::thread js_thread([&] { rt.run(); });
    auto h = runner.submit({"asyncAdd", "{\"x\":41,\"ms\":30}"});
    auto res = wait_result(std::move(h.result_rx));
    rt.stop();
    js_thread.join();
    ASSERT_TRUE(res.has_value());
    ASSERT_TRUE(res->ok) << res->json;
    EXPECT_EQ(res->json, "42");
}

TEST_F(RunnerFixture, CancelQueuedTask)
{
    // 立即取消：begin_task 可能尚未执行（Queued 摘除）或已执行（Running 闭包），
    // 两条路径结果一致（"cancelled"）
    ctx.eval("globalThis.addOne = ({x}) => x + 1;");
    std::thread js_thread([&] { rt.run(); });
    auto h = runner.submit({"addOne", "{\"x\":41}"});
    EXPECT_TRUE(runner.cancel(h.id));
    auto res = wait_result(std::move(h.result_rx));
    rt.stop();
    js_thread.join();
    ASSERT_TRUE(res.has_value());
    EXPECT_FALSE(res->ok);
    EXPECT_EQ(res->json, "cancelled");
}

TEST_F(RunnerFixture, CancelAsyncTask)
{
    // Running + 异步挂起：post 取消闭包 → abort + 立即 settle "cancelled"
    ctx.eval("globalThis.asyncAdd = async ({x, ms}) => {"
             "  await new Promise(r => setTimeout(r, ms)); return x + 1; };");
    std::thread js_thread([&] { rt.run(); });
    auto h = runner.submit({"asyncAdd", "{\"x\":41,\"ms\":10000}"});
    std::this_thread::sleep_for(std::chrono::milliseconds(100)); // 确保已开始
    EXPECT_TRUE(runner.cancel(h.id));
    auto res = wait_result(std::move(h.result_rx));
    // 幂等：结算后条目已擦除 → cancel false。注意 settle_task 先 send 后擦除，
    // 等待者可能早于擦除返回，故轮询（至多 50ms）
    bool still_cancellable = true;
    for (int i = 0; i < 50 && still_cancellable; ++i) {
        still_cancellable = runner.cancel(h.id);
        if (still_cancellable)
            std::this_thread::sleep_for(std::chrono::milliseconds(1));
    }
    EXPECT_FALSE(still_cancellable);
    rt.stop();
    js_thread.join();
    ASSERT_TRUE(res.has_value());
    EXPECT_FALSE(res->ok);
    EXPECT_EQ(res->json, "cancelled");
}

TEST_F(RunnerFixture, CancelBusyLoopTask)
{
    // Running + 同步卡死：interrupt 原子标志 → 引擎在字节码边界抛错 →
    // trampoline reject 分支收尾
    ctx.eval("globalThis.busy = () => { for (;;) {} };");
    std::thread js_thread([&] { rt.run(); });
    auto h = runner.submit({"busy", "{}"});
    std::this_thread::sleep_for(std::chrono::milliseconds(100)); // 进入死循环
    EXPECT_TRUE(runner.cancel(h.id));
    auto res = wait_result(std::move(h.result_rx));
    rt.stop();
    js_thread.join();
    ASSERT_TRUE(res.has_value());
    EXPECT_FALSE(res->ok); // json 为中断异常文本
}

TEST_F(RunnerFixture, CancelFetchTask)
{
    // 真实 signal → 网络取消链路：abort → stop.request_stop() → socket.cancel()
    // → operation_aborted；调用端在取消瞬间拿到 "cancelled"，底层收尸在后台
    qjsbind::net::wpt::WptTestServer server("third_party/wpt");
    const std::string base = server.base_url();
    ctx.eval("globalThis.__base = '" + base + "';");
    ctx.eval(R"(
        globalThis.slowFetch = async ({url}, signal) => {
          signal.addEventListener('abort', () => { globalThis.__abortFired = true; });
          const r = await fetch(url, {signal});
          return await r.text(); // body 延迟 5s → 挂起读
        };
    )");
    std::thread js_thread([&] { rt.run(); });
    auto h = runner.submit(
        {"slowFetch", "{\"url\":\"" + base + "/slow-response.py?delay=5000&content=x\"}"});
    std::this_thread::sleep_for(std::chrono::milliseconds(200)); // fetch 已在飞
    EXPECT_TRUE(runner.cancel(h.id));
    auto res = wait_result(std::move(h.result_rx));
    // 等 JS 线程执行完取消闭包的 abort 事件 dispatch
    auto [tx2, rx2] = co::oneshot::channel<bool>();
    boost::asio::post(rt.io(), [&] {
        tx2.send(ctx.eval("__abortFired === true").as<bool>());
    });
    auto fired = stdexec::sync_wait(std::move(rx2));
    rt.stop();
    js_thread.join();
    ASSERT_TRUE(res.has_value());
    EXPECT_FALSE(res->ok);
    EXPECT_EQ(res->json, "cancelled");
    ASSERT_TRUE(fired.has_value());
    EXPECT_TRUE(std::get<0>(*fired)) << "signal 的 abort 事件应已 dispatch";
}

// ================= 扩展层：TaskPool（debug 池）=================
TEST(TaskPoolTest, BasicSync)
{
    auto script = make_script("module.exports = { addOne: ({x}) => x + 1 };");
    TaskPool pool(script.string(), 4);
    auto r1 = wait_result(pool.submit({"addOne", "{\"x\":1}"}).result_rx);
    auto r2 = wait_result(pool.submit({"addOne", "{\"x\":2}"}).result_rx);
    ASSERT_TRUE(r1.has_value() && r1->ok) << (r1 ? r1->json : "no result");
    EXPECT_EQ(r1->json, "2");
    ASSERT_TRUE(r2.has_value() && r2->ok) << (r2 ? r2->json : "no result");
    EXPECT_EQ(r2->json, "3");
    pool.shutdown();
}

TEST(TaskPoolTest, ConcurrentSleeps)
{
    // 8 × 300ms 并发（懒创建 4 worker，两轮）→ 总时长 < 1500ms（串行需 2400ms）
    auto script = make_script("module.exports = { sleepTask: ({ms, v}) => sleepMs(ms, v) };");
    TaskPool pool(script.string(), 4, [](qjs::Context& c) { register_sleep_binding(c); });
    auto t0 = std::chrono::steady_clock::now();
    co::oneshot::Receiver<TaskResult> rxs[8];
    for (int i = 0; i < 8; ++i)
        rxs[i] = pool.submit({"sleepTask", "{\"ms\":300,\"v\":" + std::to_string(i) + "}"}).result_rx;
    for (auto& rx : rxs) {
        auto r = wait_result(std::move(rx));
        ASSERT_TRUE(r.has_value() && r->ok) << (r ? r->json : "no result");
    }
    const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::steady_clock::now() - t0)
                        .count();
    EXPECT_LT(ms, 1500) << "8 个 300ms 任务应并发执行（串行需 2400ms）";
    EXPECT_EQ(pool.worker_count(), 4u) << "懒创建应达上限 4 worker";
    pool.shutdown();
}

TEST(TaskPoolTest, Reload)
{
    // 热重载：改文件（内容变 → hash 变 → version++）→ 新任务跑新代码
    auto script = make_script("module.exports = { answer: () => 1 };");
    TaskPool pool(script.string(), 1);
    auto r0 = wait_result(pool.submit({"answer", "{}"}).result_rx);
    ASSERT_TRUE(r0.has_value() && r0->ok) << (r0 ? r0->json : "no result");
    EXPECT_EQ(r0->json, "1");
    std::this_thread::sleep_for(std::chrono::milliseconds(20)); // mtime 分辨率保险
    write_script(script, "module.exports = { answer: () => 2 };");
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
    auto r1 = wait_result(pool.submit({"answer", "{}"}).result_rx);
    ASSERT_TRUE(r1.has_value() && r1->ok) << (r1 ? r1->json : "no result");
    EXPECT_EQ(r1->json, "2");
    pool.shutdown();
}

TEST(TaskPoolTest, ReloadSyntaxErrorKeepsOld)
{
    // 保存到一半的语法错误文件：reload 编译验证失败 → 保留旧实例、本任务继续
    // 旧代码；修复后下个任务自动重试成功
    auto script = make_script("module.exports = { answer: () => 1 };");
    TaskPool pool(script.string(), 1);
    auto r0 = wait_result(pool.submit({"answer", "{}"}).result_rx);
    ASSERT_TRUE(r0.has_value() && r0->ok);
    EXPECT_EQ(r0->json, "1");
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
    write_script(script, "module.exports = {"); // 语法错误
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
    auto r1 = wait_result(pool.submit({"answer", "{}"}).result_rx);
    ASSERT_TRUE(r1.has_value() && r1->ok) << "坏文件不应炸掉实例";
    EXPECT_EQ(r1->json, "1"); // 旧代码继续跑
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
    write_script(script, "module.exports = { answer: () => 3 };"); // 修复
    std::this_thread::sleep_for(std::chrono::milliseconds(20));
    auto r2 = wait_result(pool.submit({"answer", "{}"}).result_rx);
    ASSERT_TRUE(r2.has_value() && r2->ok);
    EXPECT_EQ(r2->json, "3");
    pool.shutdown();
}

TEST(TaskPoolTest, CancelRunning)
{
    // 运行中取消：owner_ 定位 worker → runner->cancel（post 取消闭包 + interrupt）
    auto script = make_script("module.exports = { sleepTask: ({ms, v}) => sleepMs(ms, v) };");
    TaskPool pool(script.string(), 1, [](qjs::Context& c) { register_sleep_binding(c); });
    auto h = pool.submit({"sleepTask", "{\"ms\":300,\"v\":1}"});
    std::this_thread::sleep_for(std::chrono::milliseconds(100)); // 已在跑
    EXPECT_TRUE(pool.cancel(h.id));
    auto r = wait_result(std::move(h.result_rx));
    ASSERT_TRUE(r.has_value());
    EXPECT_FALSE(r->ok);
    EXPECT_EQ(r->json, "cancelled");
    pool.shutdown();
}

TEST(TaskPoolTest, ShutdownCancelsQueued)
{
    // 关闭协议（§7）：拒新任务；队列任务置 cancelled；在飞任务跑完才 join
    auto script = make_script("module.exports = { sleepTask: ({ms, v}) => sleepMs(ms, v) };");
    TaskPool pool(script.string(), 1, [](qjs::Context& c) { register_sleep_binding(c); });
    auto h1 = pool.submit({"sleepTask", "{\"ms\":80,\"v\":1}"}); // 占住唯一 worker
    auto h2 = pool.submit({"sleepTask", "{\"ms\":80,\"v\":2}"}); // 排队
    auto h3 = pool.submit({"sleepTask", "{\"ms\":80,\"v\":3}"}); // 排队
    std::this_thread::sleep_for(std::chrono::milliseconds(30)); // h1 在飞
    pool.shutdown();
    auto r1 = wait_result(std::move(h1.result_rx));
    auto r2 = wait_result(std::move(h2.result_rx));
    auto r3 = wait_result(std::move(h3.result_rx));
    ASSERT_TRUE(r1.has_value() && r1->ok) << (r1 ? r1->json : "no result");
    EXPECT_EQ(r1->json, "1"); // 在飞任务正常完成
    ASSERT_TRUE(r2.has_value() && !r2->ok);
    EXPECT_EQ(r2->json, "cancelled");
    ASSERT_TRUE(r3.has_value() && !r3->ok);
    EXPECT_EQ(r3->json, "cancelled");
}

TEST(TaskPoolTest, NeverResolvingPromiseFallsBackToError)
{
    // §6：永不结算且无在飞异步（new Promise(()=>{})）→ "settle 未调用"补发 error
    auto script = make_script("module.exports = { forever: () => new Promise(() => {}) };");
    TaskPool pool(script.string(), 1);
    auto r = wait_result(pool.submit({"forever", "{}"}).result_rx);
    ASSERT_TRUE(r.has_value());
    EXPECT_FALSE(r->ok);
    EXPECT_NE(r->json.find("did not settle"), std::string::npos) << r->json;
    pool.shutdown();
}

TEST(TaskPoolTest, FetchAndCancelInPool)
{
    // 池内真实 fetch + 取消：signal abort → 网络层 socket 取消 → 调用端拿
    // "cancelled"；底层收尸（AbortError reject 链）后 worker 回到空闲
    qjsbind::net::wpt::WptTestServer server("third_party/wpt");
    boost::asio::io_context client_io; // client 传输 io 独立于 worker（传输无共享状态）
    fetch::set_thread_io(client_io); // 本线程构造 Client 的 io 来源
    fetch::Client client{};
    // work_guard 保活：无在飞工作时 run() 立即返回，io_thread 必须活到收尸结束
    auto client_guard = boost::asio::make_work_guard(client_io);
    std::thread io_thread([&] { client_io.run(); });

    auto script = make_script(R"(
        module.exports = { fetchTask: async ({url}, signal) => {
          signal.addEventListener('abort', () => { globalThis.__aborted = true; });
          const r = await fetch(url, {signal});
          return await r.text(); // body 延迟 5s → 挂起读
        } };
    )");
    TaskPool pool(script.string(), 2, [&client](qjs::Context& c) {
        qjsbind::web::install_web_apis(c, client);
    });
    auto h = pool.submit({"fetchTask",
                          "{\"url\":\"" + server.base_url() +
                              "/slow-response.py?delay=5000&content=x\"}"});
    std::this_thread::sleep_for(std::chrono::milliseconds(200)); // fetch 已在飞
    EXPECT_TRUE(pool.cancel(h.id));
    auto r = wait_result(std::move(h.result_rx));
    ASSERT_TRUE(r.has_value());
    EXPECT_FALSE(r->ok);
    EXPECT_EQ(r->json, "cancelled");
    pool.shutdown(); // join worker：取消后 fetch 收尸由 io_thread 驱动
    client_guard.reset(); // 所有请求已结束 → run() 可返回
    io_thread.join();
}

} // namespace
