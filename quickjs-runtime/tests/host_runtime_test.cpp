// host_runtime_test.cpp —— qjs::HostRuntime（命名 bundle 实例管理）测试
//
// 设计文档：docs/runtime_management_design.md
// 覆盖：init/call/reload/cancel/stop 五消息生命周期、debug（call 带 bundle）、
// 序列化协议（顶层二进制 / 嵌套 base64 / JSON）、错误码映射。
#include <qjsbind/host_runtime.hpp>
#include <qjsbind/web/timers.hpp>
#include <qjsbind/web/web.hpp>

#include <fetch/client.hpp>

#include "wpt_server.hpp"

#include <gtest/gtest.h>

#include <chrono>
#include <string>
#include <thread>

namespace {

using qjs::HostRuntime;
using qjs::runtime_errc;

// 测试是同步上下文：对异步 wait()（stdexec::task）做一次 sync_wait 解包。
// 实参是 call/reload/run_gc 返回的 expected<task_handle/op_receipt>。
inline auto await_sync(auto&& e)
{
    auto res = stdexec::sync_wait(std::forward<decltype(e)>(e)->wait());
    using R = std::decay_t<decltype(std::get<0>(*res))>;
    // wait() 内部已把通道关闭转成 runtime_stopped 错误，此处 res 必有值
    if (!res)
        return R(std::unexpected(qjs::runtime_error{qjs::runtime_errc::runtime_stopped,
                                                    "test: wait channel closed"}));
    return R(std::move(std::get<0>(*res)));
}

// 标准测试 bundle：同步/异步/嵌套路径/异常/二进制/死循环 各一个出口
constexpr std::string_view kBundleV1 = R"js(
module.exports = {
  add: ({a, b}) => a + b,
  math: { inner: { mul: ({a, b}) => a * b } },
  version: () => 1,
  asyncEcho: async ({v}) => v,
  boom: () => { throw new Error("kaput"); },
  bytes: () => new Uint8Array([1, 2, 3, 255]),
  nested: () => ({ data: new Uint8Array([65, 66]), tag: "ab" }),
  echo: (x) => x,
  bufLen: (b) => (b == null ? -1 : b.byteLength),
  nestedBufLen: (o) => o.files[0].byteLength,
  loop: () => { for (;;) {} },
};
)js";

constexpr std::string_view kBundleV2 = R"js(
module.exports = {
  add: ({a, b}) => a + b,
  version: () => 2,
};
)js";

// 并发语义验证 bundle：sleep 走 setTimeout（需 install_timers）；
// waitGate/openGate 构成纯挂起闸门（无 io 工作），用于确定性并发证明
constexpr std::string_view kAsyncBundleV1 = R"js(
let resolveGate;
module.exports = {
  sleep: ({ms}) => new Promise((r) => setTimeout(() => r(ms), ms)),
  waitGate: () => new Promise((r) => { resolveGate = r; }).then(() => "released"),
  openGate: () => { if (resolveGate) resolveGate(); return "opened"; },
  version: () => 1,
};
)js";

constexpr std::string_view kAsyncBundleV2 = R"js(
module.exports = {
  version: () => 2,
};
)js";

TEST(HostRuntimeTest, InitAndCall)
{
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kBundleV1)).has_value());

    auto h = rt.call("t", "add", "{\"a\":1,\"b\":2}");
    ASSERT_TRUE(h.has_value());
    auto r = await_sync(h);
    ASSERT_TRUE(r.has_value()) << r.error().message;
    EXPECT_EQ(*r, "3");

    // 点路径解析到嵌套导出
    auto h2 = rt.call("t", "math.inner.mul", "{\"a\":3,\"b\":4}");
    ASSERT_TRUE(h2.has_value());
    auto r2 = await_sync(h2);
    ASSERT_TRUE(r2.has_value()) << r2.error().message;
    EXPECT_EQ(*r2, "12");

    // 异步函数（promise 链结算）
    auto h3 = rt.call("t", "asyncEcho", "{\"v\":42}");
    ASSERT_TRUE(h3.has_value());
    auto r3 = await_sync(h3);
    ASSERT_TRUE(r3.has_value()) << r3.error().message;
    EXPECT_EQ(*r3, "42");

    ASSERT_TRUE(rt.stop("t").has_value());
}

TEST(HostRuntimeTest, InitDuplicateAndUnknown)
{
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kBundleV1)).has_value());

    auto dup = rt.init("t", std::string(kBundleV1));
    ASSERT_FALSE(dup.has_value());
    EXPECT_EQ(dup.error().code, runtime_errc::bundle_exists);

    auto h = rt.call("nope", "add", "{\"a\":1,\"b\":2}");
    ASSERT_FALSE(h.has_value());
    EXPECT_EQ(h.error().code, runtime_errc::bundle_not_found);

    auto rl = rt.reload("nope", "module.exports = {};");
    ASSERT_FALSE(rl.has_value());
    EXPECT_EQ(rl.error().code, runtime_errc::bundle_not_found);

    auto st = rt.stop("nope");
    ASSERT_FALSE(st.has_value());
    EXPECT_EQ(st.error().code, runtime_errc::bundle_not_found);

    ASSERT_TRUE(rt.stop("t").has_value());
}

TEST(HostRuntimeTest, InitCompileFailed)
{
    HostRuntime rt;
    auto r = rt.init("bad", "module.exports = {");
    ASSERT_FALSE(r.has_value());
    EXPECT_EQ(r.error().code, runtime_errc::compile_failed);
    // 失败的 init 不留实例
    EXPECT_TRUE(rt.list().empty());
}

TEST(HostRuntimeTest, CallErrors)
{
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kBundleV1)).has_value());

    // fn_path 解析不到 → function_not_found，Node 风格详细诊断
    auto h = rt.call("t", "no.such.fn", "{}");
    ASSERT_TRUE(h.has_value());
    auto r = await_sync(h);
    ASSERT_FALSE(r.has_value());
    EXPECT_EQ(r.error().code, runtime_errc::function_not_found);
    EXPECT_NE(r.error().message.find("TypeError: function path not found: no.such.fn"),
              std::string::npos)
        << r.error().message;
    EXPECT_NE(r.error().message.find("missing segment=no"), std::string::npos)
        << r.error().message;
    EXPECT_NE(r.error().message.find("rootKeys="), std::string::npos) << r.error().message;

    // 参数不是 JSON → invalid_args
    auto h2 = rt.call("t", "add", "not json");
    ASSERT_TRUE(h2.has_value());
    auto r2 = await_sync(h2);
    ASSERT_FALSE(r2.has_value());
    EXPECT_EQ(r2.error().code, runtime_errc::invalid_args);

    // 用户代码抛异常 → js_exception，Node 风格：[scope] 前缀 + "Error: 消息" 首行 + 栈
    auto h4 = rt.call("t", "boom", "{}");
    ASSERT_TRUE(h4.has_value());
    auto r4 = await_sync(h4);
    ASSERT_FALSE(r4.has_value());
    EXPECT_EQ(r4.error().code, runtime_errc::js_exception);
    EXPECT_NE(r4.error().message.find(
                  "[bundle:t fn:boom args:{} source:t.bundle.cjs] Error: kaput"),
              std::string::npos)
        << r4.error().message;
    EXPECT_NE(r4.error().message.find("at boom (t.bundle.cjs:"), std::string::npos)
        << r4.error().message;

    ASSERT_TRUE(rt.stop("t").has_value());
}

TEST(HostRuntimeTest, ErrorNodeStyleDetails)
{
    HostRuntime rt;

    // default 导出 unwrap（Node 风格 CJS 互操作）
    ASSERT_TRUE(rt.init("d", "module.exports = { default: { add: ({a, b}) => a + b } };")
                    .has_value());
    EXPECT_EQ(await_sync(rt.call("d", "add", "{\"a\":2,\"b\":3}")).value_or(""), "5");

    // 导出非 object/function → init 失败（TypeError 文本）
    auto bad = rt.init("bad", "module.exports = 42;");
    ASSERT_FALSE(bad.has_value());
    EXPECT_EQ(bad.error().code, runtime_errc::js_exception);
    EXPECT_NE(bad.error().message.find("bundle must export object or function"),
              std::string::npos)
        << bad.error().message;

    // 安全键段拒绝 → invalid_args
    ASSERT_TRUE(rt.init("t", std::string(kBundleV1)).has_value());
    auto h = rt.call("t", "constructor", "{}");
    auto r = await_sync(h);
    ASSERT_FALSE(r.has_value());
    EXPECT_EQ(r.error().code, runtime_errc::invalid_args);
    EXPECT_NE(r.error().message.find("unsafe path segment: constructor"), std::string::npos)
        << r.error().message;

    // 非 Error 抛出值：包出栈 + "Error: <值>" 首行
    ASSERT_TRUE(rt.init("s", "module.exports = { fail: () => { throw 'plain string'; } };")
                    .has_value());
    auto r2 = await_sync(rt.call("s", "fail", "{}"));
    ASSERT_FALSE(r2.has_value());
    EXPECT_NE(r2.error().message.find("Error: plain string"), std::string::npos)
        << r2.error().message;

    ASSERT_TRUE(rt.stop("d").has_value());
    ASSERT_TRUE(rt.stop("t").has_value());
    ASSERT_TRUE(rt.stop("s").has_value());
}

TEST(HostRuntimeTest, ErrorStackDisabled)
{
    // include_stack=false：错误文本只给 [scope] + 消息首行，不带栈
    HostRuntime rt({}, false);
    ASSERT_TRUE(rt.init("t", std::string(kBundleV1)).has_value());

    auto r = await_sync(rt.call("t", "boom", "{\"a\":1}"));
    ASSERT_FALSE(r.has_value());
    EXPECT_EQ(r.error().message,
              "[bundle:t fn:boom args:{\"a\":1} source:t.bundle.cjs] Error: kaput")
        << r.error().message;

    ASSERT_TRUE(rt.stop("t").has_value());
}

TEST(HostRuntimeTest, BinaryTopLevel)
{
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kBundleV1)).has_value());

    // 顶层 TypedArray → wait() 交付原始字节
    auto h = rt.call("t", "bytes", "{}");
    ASSERT_TRUE(h.has_value());
    auto r = await_sync(h);
    ASSERT_TRUE(r.has_value()) << r.error().message;
    EXPECT_EQ(*r, std::string("\x01\x02\x03\xFF", 4));

    // 嵌套二进制 → JSON 内 base64 占位
    auto h2 = rt.call("t", "nested", "{}");
    ASSERT_TRUE(h2.has_value());
    auto r2 = await_sync(h2);
    ASSERT_TRUE(r2.has_value()) << r2.error().message;
    EXPECT_NE(r2->find("\"$type\":\"bytes\""), std::string::npos) << *r2;
    EXPECT_NE(r2->find("\"base64\":\"QUI=\""), std::string::npos) << *r2;
    EXPECT_NE(r2->find("\"tag\":\"ab\""), std::string::npos) << *r2;

    ASSERT_TRUE(rt.stop("t").has_value());
}

TEST(HostRuntimeTest, ReloadFlow)
{
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kBundleV1)).has_value());

    auto h = rt.call("t", "version", "{}");
    ASSERT_TRUE(h.has_value());
    EXPECT_EQ(await_sync(h).value_or(""), "1");

    // 原子替换成功：新代码生效
    auto rc = rt.reload("t", std::string(kBundleV2));
    ASSERT_TRUE(rc.has_value());
    ASSERT_TRUE(await_sync(rc).has_value());

    auto h2 = rt.call("t", "version", "{}");
    ASSERT_TRUE(h2.has_value());
    EXPECT_EQ(await_sync(h2).value_or(""), "2");

    // 编译失败：旧代码保留，返回 compile_failed
    auto rc2 = rt.reload("t", "module.exports = {");
    ASSERT_TRUE(rc2.has_value());
    auto rr = await_sync(rc2);
    ASSERT_FALSE(rr.has_value());
    EXPECT_EQ(rr.error().code, runtime_errc::compile_failed);

    auto h3 = rt.call("t", "version", "{}");
    ASSERT_TRUE(h3.has_value());
    EXPECT_EQ(await_sync(h3).value_or(""), "2");

    ASSERT_TRUE(rt.stop("t").has_value());
}

TEST(HostRuntimeTest, DebugCallWithBundle)
{
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kBundleV1)).has_value());

    // debug：call 携带新 bundle → 先热重载再执行，本次即跑新代码
    auto h = rt.call("t", "version", "{}", std::optional<std::string>(std::string(kBundleV2)));
    ASSERT_TRUE(h.has_value());
    EXPECT_EQ(await_sync(h).value_or(""), "2");

    // 重载是持久的：后续普通 call 也跑新代码（id 指向最近编译成功的代码）
    auto h2 = rt.call("t", "version", "{}");
    ASSERT_TRUE(h2.has_value());
    EXPECT_EQ(await_sync(h2).value_or(""), "2");

    // debug 携带坏 bundle：本次 call 结算 compile_failed，旧代码保留
    auto h3 = rt.call("t", "version", "[]",
                      std::optional<std::string>("module.exports = {"));
    ASSERT_TRUE(h3.has_value());
    auto r3 = await_sync(h3);
    ASSERT_FALSE(r3.has_value());
    EXPECT_EQ(r3.error().code, runtime_errc::compile_failed);

    auto h4 = rt.call("t", "version", "{}");
    ASSERT_TRUE(h4.has_value());
    EXPECT_EQ(await_sync(h4).value_or(""), "2");

    ASSERT_TRUE(rt.stop("t").has_value());
}

TEST(HostRuntimeTest, CancelQueuedAndRunning)
{
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kBundleV1)).has_value());

    // h1：同步死循环，独占实例
    auto h1 = rt.call("t", "loop", "{}");
    ASSERT_TRUE(h1.has_value());
    std::this_thread::sleep_for(std::chrono::milliseconds(200)); // 等 h1 跑起来

    // h2：排在实例队列里 → 队列摘除式取消，确定性地得 cancelled
    auto h2 = rt.call("t", "add", "{\"a\":1,\"b\":2}");
    ASSERT_TRUE(h2.has_value());
    EXPECT_TRUE(rt.cancel(*h2));
    auto r2 = await_sync(h2);
    ASSERT_FALSE(r2.has_value());
    EXPECT_EQ(r2.error().code, runtime_errc::task_cancelled);

    // h1：Running 取消（interrupt 打断同步死循环）。结算文本是 cancelled 还是
    // 引擎的 interrupted 取决于是取消闭包还是 trampoline 先结算（once 守卫），
    // 两种都算取消成功。
    EXPECT_TRUE(rt.cancel(*h1));
    auto r1 = await_sync(h1);
    ASSERT_FALSE(r1.has_value());
    EXPECT_TRUE(r1.error().code == runtime_errc::task_cancelled ||
                r1.error().code == runtime_errc::js_exception)
        << r1.error().message;

    // 取消后实例仍可用
    auto h3 = rt.call("t", "add", "{\"a\":5,\"b\":6}");
    ASSERT_TRUE(h3.has_value());
    EXPECT_EQ(await_sync(h3).value_or(""), "11");

    ASSERT_TRUE(rt.stop("t").has_value());
}

TEST(HostRuntimeTest, StatsCounters)
{
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kBundleV1)).has_value());

    // 2 成功 + 1 失败
    EXPECT_EQ(await_sync(rt.call("t", "add", "{\"a\":1,\"b\":2}")).value_or(""), "3");
    EXPECT_EQ(await_sync(rt.call("t", "add", "{\"a\":3,\"b\":4}")).value_or(""), "7");
    EXPECT_FALSE(await_sync(rt.call("t", "boom", "{}")).has_value());

    // 1 队列摘除式取消（h1 死循环独占实例，h2 排队时被取消）
    auto h1 = rt.call("t", "loop", "{}");
    std::this_thread::sleep_for(std::chrono::milliseconds(200));
    auto h2 = rt.call("t", "add", "{\"a\":9,\"b\":9}");
    EXPECT_TRUE(rt.cancel(*h2));
    EXPECT_EQ(await_sync(h2).error().code, runtime_errc::task_cancelled);
    EXPECT_TRUE(rt.cancel(*h1));
    EXPECT_FALSE(await_sync(h1).has_value()); // cancelled 或 interrupted（once 守卫竞态）

    // reload 1 成 1 败
    ASSERT_TRUE(await_sync(rt.reload("t", std::string(kBundleV2))).has_value());
    EXPECT_FALSE(await_sync(rt.reload("t", "module.exports = {")).has_value());

    auto snap = rt.stats();
    ASSERT_EQ(snap.instances.size(), 1u);
    const auto& s = snap.instances.front();
    EXPECT_EQ(s.id, "t");
    EXPECT_EQ(s.submitted, 5u);
    EXPECT_EQ(s.completed, 2u);
    EXPECT_EQ(s.cancelled + s.failed, 3u); // boom + 排队取消 + 死循环取消
    EXPECT_GE(s.cancelled, 1u);            // 排队取消确定计入
    EXPECT_GE(s.failed, 1u);               // boom 确定计入
    EXPECT_EQ(s.reloads_ok, 1u);
    EXPECT_EQ(s.reloads_failed, 1u);
    EXPECT_EQ(s.queued, 0u);
    EXPECT_FALSE(s.busy);

    ASSERT_TRUE(rt.stop("t").has_value());
    EXPECT_TRUE(rt.stats().instances.empty());
}

TEST(HostRuntimeTest, RunGc)
{
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kBundleV1)).has_value());
    EXPECT_EQ(await_sync(rt.call("t", "add", "{\"a\":1,\"b\":2}")).value_or(""), "3");

    auto rc = rt.run_gc("t");
    ASSERT_TRUE(rc.has_value());
    EXPECT_TRUE(await_sync(rc).has_value());

    auto bad = rt.run_gc("nope");
    ASSERT_FALSE(bad.has_value());
    EXPECT_EQ(bad.error().code, runtime_errc::bundle_not_found);

    // GC 后实例正常可用
    EXPECT_EQ(await_sync(rt.call("t", "add", "{\"a\":4,\"b\":5}")).value_or(""), "9");
    ASSERT_TRUE(rt.stop("t").has_value());
}

TEST(HostRuntimeTest, ReloadSkipUnchangedHash)
{
    // 带模块级状态的 bundle：跳过重载时状态保留（真重载会重置）
    constexpr std::string_view kCounter = R"js(
let n = 0;
module.exports = { hit: () => ++n };
)js";
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kCounter)).has_value());
    EXPECT_EQ(await_sync(rt.call("t", "hit", "{}")).value_or(""), "1");
    EXPECT_EQ(await_sync(rt.call("t", "hit", "{}")).value_or(""), "2");

    // 相同源码 reload：content hash 未变 → 跳过，模块状态保留
    ASSERT_TRUE(await_sync(rt.reload("t", std::string(kCounter))).has_value());
    EXPECT_EQ(await_sync(rt.call("t", "hit", "{}")).value_or(""), "3");

    // 变化源码 reload：真重载，状态重置
    ASSERT_TRUE(await_sync(rt.reload("t", std::string(kCounter) + "\n// v2")).has_value());
    EXPECT_EQ(await_sync(rt.call("t", "hit", "{}")).value_or(""), "1");

    // debug call 携带相同 bundle 同样跳过
    auto h = rt.call("t", "hit", "{}", std::optional<std::string>(std::string(kCounter) + "\n// v2"));
    EXPECT_EQ(await_sync(h).value_or(""), "2");

    auto snap = rt.stats();
    ASSERT_EQ(snap.instances.size(), 1u);
    EXPECT_EQ(snap.instances.front().reloads_skipped, 2u);
    EXPECT_EQ(snap.instances.front().reloads_ok, 1u);

    ASSERT_TRUE(rt.stop("t").has_value());
}

TEST(HostRuntimeTest, NativeBufferChannel)
{
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kBundleV1)).has_value());

    const std::string payload("\x00\x01\x02\xFF\x10", 5);
    auto bid = rt.put_buffer("t", payload);
    ASSERT_TRUE(bid.has_value());

    // host→JS：{"$buf": id} 占位在调用前物化为 Uint8Array
    auto h = rt.call("t", "bufLen", "{\"$buf\":\"" + *bid + "\"}");
    EXPECT_EQ(await_sync(h).value_or(""), "5");

    // 双向 roundtrip：echo 返回（JS→host 同样走池），wait() 交付原始字节
    auto bid2 = rt.put_buffer("t", payload);
    ASSERT_TRUE(bid2.has_value());
    auto r2 = await_sync(rt.call("t", "echo", "{\"$buf\":\"" + *bid2 + "\"}"));
    ASSERT_TRUE(r2.has_value()) << r2.error().message;
    EXPECT_EQ(*r2, payload);

    // 消费语义：同一 id 第二次 take → invalid_args
    auto r3 = await_sync(rt.call("t", "bufLen", "{\"$buf\":\"" + *bid2 + "\"}"));
    ASSERT_FALSE(r3.has_value());
    EXPECT_EQ(r3.error().code, runtime_errc::invalid_args);

    // 未知 id → invalid_args
    auto r4 = await_sync(rt.call("t", "bufLen", "{\"$buf\":\"no-such-id\"}"));
    ASSERT_FALSE(r4.has_value());
    EXPECT_EQ(r4.error().code, runtime_errc::invalid_args);

    // 任意深度嵌套占位
    auto bid3 = rt.put_buffer("t", payload);
    ASSERT_TRUE(bid3.has_value());
    auto r5 = await_sync(rt.call("t", "nestedBufLen", "{\"files\":[{\"$buf\":\"" + *bid3 + "\"}]}"));
    EXPECT_EQ(r5.value_or(""), "5");

    // put 到未 init 的实例 → bundle_not_found
    auto bad = rt.put_buffer("nope", "x");
    ASSERT_FALSE(bad.has_value());
    EXPECT_EQ(bad.error().code, runtime_errc::bundle_not_found);

    ASSERT_TRUE(rt.stop("t").has_value());
}

TEST(HostRuntimeTest, SourceMapRemap)
{
    // bundle 带行内 source map：boom 在 bundle 第 1 行（CJS 包装后第 2 行），
    // map 把 bundle 第 1 行映射到 src/original.ts 第 10 行第 4 列。
    constexpr std::string_view kMapped = R"js(function boom() { throw new Error("mapped!"); }
module.exports = { boom };
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbInNyYy9vcmlnaW5hbC50cyJdLCJuYW1lcyI6W10sIm1hcHBpbmdzIjoiQUFTSTsifQ==
)js";
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kMapped)).has_value());

    auto h = rt.call("t", "boom", "{}");
    ASSERT_TRUE(h.has_value());
    auto r = await_sync(h);
    ASSERT_FALSE(r.has_value());
    EXPECT_EQ(r.error().code, runtime_errc::js_exception);
    // 栈位置被 remap 回原始源码（不再是 t.bundle.cjs:2:...）
    EXPECT_NE(r.error().message.find("src/original.ts:10:4"), std::string::npos)
        << r.error().message;
    EXPECT_EQ(r.error().message.find("t.bundle.cjs:2"), std::string::npos)
        << r.error().message;
    EXPECT_NE(r.error().message.find("mapped!"), std::string::npos) << r.error().message;

    ASSERT_TRUE(rt.stop("t").has_value());
}

TEST(HostRuntimeTest, StopRecyclesInstance)
{
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kBundleV1)).has_value());
    ASSERT_TRUE(rt.init("u", std::string(kBundleV2)).has_value());
    EXPECT_EQ(rt.list().size(), 2u);

    ASSERT_TRUE(rt.stop("t").has_value());
    EXPECT_EQ(rt.list().size(), 1u);

    auto h = rt.call("t", "add", "{\"a\":1,\"b\":2}");
    ASSERT_FALSE(h.has_value());
    EXPECT_EQ(h.error().code, runtime_errc::bundle_not_found);

    // 其余实例不受影响
    auto h2 = rt.call("u", "version", "{}");
    ASSERT_TRUE(h2.has_value());
    EXPECT_EQ(await_sync(h2).value_or(""), "2");

    ASSERT_TRUE(rt.stop("u").has_value());
}

// IO 并发：同一实例上多任务在飞交替推进（不是串行，也不是多实例 CPU 并行）
TEST(HostRuntimeTest, ConcurrentInFlightIO)
{
    HostRuntime rt([](qjs::Context& c) { qjsbind::web::install_timers(c); });
    ASSERT_TRUE(rt.init("t", std::string(kAsyncBundleV1)).has_value());

    // 确定性证明：waitGate 纯挂起（无任何 io 工作）。串行模型下 openGate
    // 永远排不到队首，这里只能死锁；并发模型下 openGate 立即启动并放行闸门
    auto g = rt.call("t", "waitGate", "{}");
    auto o = rt.call("t", "openGate", "{}");
    EXPECT_EQ(await_sync(o).value_or(""), R"("opened")");
    EXPECT_EQ(await_sync(g).value_or(""), R"("released")");

    // 计时证明：两个 250ms 的 sleep 并发，总耗时显著小于串行的 500ms
    const auto t0 = std::chrono::steady_clock::now();
    auto h1 = rt.call("t", "sleep", "{\"ms\":250}");
    auto h2 = rt.call("t", "sleep", "{\"ms\":250}");
    EXPECT_EQ(await_sync(h1).value_or(""), "250");
    EXPECT_EQ(await_sync(h2).value_or(""), "250");
    const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                        std::chrono::steady_clock::now() - t0)
                        .count();
    EXPECT_LT(ms, 450);

    ASSERT_TRUE(rt.stop("t").has_value());
}
// debug 屏障：带 bundle 的 call 等在飞任务排空（热重载必须无在飞），
// 且 debug 执行期间普通 call 排队——debug 池强制串行
TEST(HostRuntimeTest, DebugBarrierSerial)
{
    HostRuntime rt;
    ASSERT_TRUE(rt.init("t", std::string(kAsyncBundleV1)).has_value());

    auto g = rt.call("t", "waitGate", "{}"); // 在飞挂起，堵住屏障
    auto d = rt.call("t", "version", "{}", std::string(kAsyncBundleV2)); // debug：等待
    // debug 拿不到执行权直到 g 离场；取消 g → 屏障解除 → 热重载并执行
    ASSERT_TRUE(rt.cancel(*g));
    EXPECT_EQ(await_sync(g).error().code, runtime_errc::task_cancelled);
    EXPECT_EQ(await_sync(d).value_or(""), "2"); // 跑的是热重载后的新 bundle

    // debug 完成后普通 call 恢复并发，且已是新代码
    EXPECT_EQ(await_sync(rt.call("t", "version", "{}")).value_or(""), "2");

    ASSERT_TRUE(rt.stop("t").has_value());
}

// 压测：100 个 fetch 并发在飞，等待全部结束。服务端每请求延迟 300ms 返回
// body——串行模型需 ~30s，IO 并发模型应在一秒内量级完成
TEST(HostRuntimeTest, ConcurrentFetchStress)
{
    qjsbind::net::wpt::WptTestServer server(""); // 只用 /slow-response.py，不需要 wpt 资产目录
    // 内建 fetch：Client 由 HostRuntime 按实例在实例线程构造/析构、随 reload
    // 回收重建，调用方零管理
    HostRuntime rt(HostRuntime::Options{.enable_fetch = true});
    ASSERT_TRUE(rt.init("t", R"js(
module.exports = {
  get: ({url}) => fetch(url).then((r) => r.text()).then((t) => t.length),
};
)js")
                       .has_value());

    constexpr int kN = 100;
    // 纯 JS 基线（无 IO）：隔离"调度 + 锁 + 通道"本身的开销
    ASSERT_TRUE(rt.init("e", std::string(kBundleV1)).has_value());
    {
        const auto t0 = std::chrono::steady_clock::now();
        std::vector<std::expected<qjs::task_handle, qjs::runtime_error>> hs;
        hs.reserve(kN);
        for (int i = 0; i < kN; ++i)
            hs.push_back(rt.call("e", "asyncEcho", "{\"v\":1}"));
        for (auto& h : hs)
            EXPECT_EQ(await_sync(h).value_or(""), "1");
        const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                            std::chrono::steady_clock::now() - t0)
                            .count();
        QLOG_INFO("[stress] {} 个纯 JS 任务（无 IO）总耗时 {} ms", kN, ms);
        ASSERT_TRUE(rt.stop("e").has_value());
    }
    // delay=0 对照组测纯管线开销；delay=300 组减去它就是延迟本身
    for (int delay : {0, 300}) {
        const std::string args = "{\"url\":\"" + server.base_url() +
                                 "/slow-response.py?delay=" + std::to_string(delay) +
                                 "&content=ok\"}";
        const auto t0 = std::chrono::steady_clock::now();
        std::vector<std::expected<qjs::task_handle, qjs::runtime_error>> handles;
        handles.reserve(kN);
        for (int i = 0; i < kN; ++i) {
            auto h = rt.call("t", "get", args);
            ASSERT_TRUE(h.has_value()) << h.error().message;
            handles.push_back(std::move(h));
        }
        for (auto& h : handles) {
            auto r = await_sync(h);
            ASSERT_TRUE(r.has_value()) << r.error().message;
            EXPECT_EQ(*r, "2"); // "ok".length
        }
        const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                            std::chrono::steady_clock::now() - t0)
                            .count();
        QLOG_INFO("[stress] {} 个并发 fetch（delay={}ms）总耗时 {} ms", kN, delay, ms);
        EXPECT_LT(ms, 10000); // 串行需 ~30s；并发给足抖动余量
    }

    // reload（enable_fetch 路径）：Client 随旧 Runtime 回收重建，新代码照常 fetch
    ASSERT_TRUE(await_sync(rt.reload("t", R"js(
module.exports = {
  get: ({url}) => fetch(url).then((r) => r.text()).then((t) => t.length + 1),
};
)js"))
                    .has_value());
    const std::string args2 =
        "{\"url\":\"" + server.base_url() + "/slow-response.py?delay=0&content=ok\"}";
    EXPECT_EQ(await_sync(rt.call("t", "get", args2)).value_or(""), "3");

    ASSERT_TRUE(rt.stop("t").has_value());
}

} // namespace
