// runtime_api_test.cpp —— Breeze 风格运行时 API 集成测试
//
// 覆盖（docs/breeze_api_gap_analysis.md §8）：
//   - base64：bytesToBase64/bytesFromBase64/base64 对象（native 优先路径 +
//     JS fallback 路径）、已知向量、类型错误
//   - native：put/take/free（take 消费语义、free 后不可得）
//   - uuidv4：格式与唯一性
//   - runtime.gc：可调用；runtime.isTaskGroupCancelled：对接 TaskRunner taskid
//   - Buffer：npm buffer 挂载（from/alloc/concat/readUInt/isBuffer）
//   - opencc：六种配置 JS 入口（C++ 行为细节见 opencc_test.cpp）
#include <cstdint>
#include <optional>
#include <string>
#include <thread>
#include <tuple>

#include <gtest/gtest.h>
#include <qjsbind/blob_store.hpp>
#include <qjsbind/polyfill/bundle_dispatcher.hpp>
#include <qjsbind/polyfill/runtime_api.hpp>
#include <qjsbind/qjsbind.hpp>
#include <qjsbind/task.hpp>

#include <dart_cpp_bridge/channel.hpp>
#include <stdexec/execution.hpp>

using namespace qjs;

namespace {

// sync_wait 解包（completion 是 tuple<optional<T>>）
std::optional<TaskResult> wait_result(co::oneshot::Receiver<TaskResult>&& rx)
{
    auto v = stdexec::sync_wait(std::move(rx));
    if (!v)
        return std::nullopt;
    return std::get<0>(*v);
}

// ---- 公共基类：Runtime + eval 辅助 ----
struct RuntimeApiBase : ::testing::Test {
    Runtime rt;
    Context ctx = rt.main_context();

    Value eval_ok(const std::string& code)
    {
        Value r = ctx.eval(code);
        if (r.is_exception()) {
            JSValue e = JS_GetException(ctx.raw());
            auto s = Context(ctx.raw()).js_string(e);
            QLOG_ERROR("[runtime_api_test] eval failed: {} | code: {}",
                       s ? *s : "(null)", code);
            JS_FreeValue(ctx.raw(), e);
        }
        EXPECT_FALSE(r.is_exception());
        return r;
    }
};

// ---- 主 fixture：全量安装（native base64 路径 + blob store + TaskRunner）----
// 不装 bundle_dispatcher：__invoke 保持 TaskRunner 基础版（全局函数直查），
// 任务测试（isTaskGroupCancelled）用全局函数；base64 native 能力由
// install_runtime_api 自包含注册（__native_b64encode/__native_b64decode）。
struct RuntimeApiFixture : RuntimeApiBase {
    TaskRunner runner{rt}; // 构造即注册 __native_task_cancelled

    RuntimeApiFixture()
    {
        dyn::install_blob_store(ctx); // native_put/native_get/__native_buf_free
        install_runtime_api(ctx);     // base64/uuid/gc/opencc + Buffer
    }
};

// ---- fallback fixture：删除 native base64 函数 ----
// 覆盖 polyfill 的纯 JS base64 降级路径（__native_b64encode 缺失时）
struct RuntimeApiFallbackFixture : RuntimeApiBase {
    RuntimeApiFallbackFixture()
    {
        dyn::install_blob_store(ctx);
        install_runtime_api(ctx);
        // 摘掉 native 能力，强制走 JS fallback（eval 先删再测）
        ctx.eval("delete globalThis.__native_b64encode;"
                 "delete globalThis.__native_b64decode;");
    }
};

// ================= base64 =================

TEST_F(RuntimeApiFixture, Base64Roundtrip)
{
    EXPECT_EQ(eval_ok("bytesToBase64(new Uint8Array([1,2,3]));").as<std::string>(),
              "AQID");
    EXPECT_EQ(eval_ok("Array.from(bytesFromBase64('AQID')).join(',');").as<std::string>(),
              "1,2,3");
    // base64 命名空间对象
    EXPECT_EQ(eval_ok("base64.encode(new Uint8Array([104,105]));").as<std::string>(),
              "aGk=");
    EXPECT_EQ(eval_ok("Array.from(base64.decode('aGk=')).join(',');").as<std::string>(),
              "104,105");
}

TEST_F(RuntimeApiFixture, Base64KnownVectors)
{
    // 与标准 base64 一致（BoringSSL / RFC 4648）
    EXPECT_EQ(eval_ok("bytesToBase64(new Uint8Array([]));").as<std::string>(), "");
    EXPECT_EQ(eval_ok("bytesToBase64(new Uint8Array([104,101,108,108,111]));").as<std::string>(),
              "aGVsbG8="); // "hello"
    EXPECT_EQ(eval_ok("bytesToBase64(new Uint8Array([113,117,105,99,107,106,115]));").as<std::string>(),
              "cXVpY2tqcw=="); // "quickjs"
    // number[] 入参（BinaryInput 兼容）
    EXPECT_EQ(eval_ok("bytesToBase64([1,2,3]);").as<std::string>(), "AQID");
    // 解码往返（无 TextDecoder 依赖：直接比较字节）
    EXPECT_EQ(eval_ok("Array.from(bytesFromBase64('aGVsbG8=')).join(',');").as<std::string>(),
              "104,101,108,108,111");
}

TEST_F(RuntimeApiFixture, Base64TypeErrors)
{
    EXPECT_TRUE(eval_ok(
        "(() => { try { bytesToBase64('str'); return false; } catch (e) { "
        "return e instanceof TypeError; } })();").as<bool>());
    EXPECT_TRUE(eval_ok(
        "(() => { try { bytesFromBase64(123); return false; } catch (e) { "
        "return e instanceof TypeError; } })();").as<bool>());
    // 非法 base64 → 抛异常（native 路径）
    EXPECT_TRUE(eval_ok(
        "(() => { try { bytesFromBase64('!!!'); return false; } catch (e) { "
        "return true; } })();").as<bool>());
}

TEST_F(RuntimeApiFallbackFixture, Base64JsFallback)
{
    // 无 __native_b64encode/__native_b64decode：纯 JS 实现结果一致
    EXPECT_EQ(eval_ok("bytesToBase64(new Uint8Array([1,2,3]));").as<std::string>(),
              "AQID");
    EXPECT_EQ(eval_ok("bytesToBase64(new Uint8Array([104,101,108,108,111]));").as<std::string>(),
              "aGVsbG8="); // "hello"
    EXPECT_EQ(eval_ok("Array.from(bytesFromBase64('aGVsbG8=')).join(',');").as<std::string>(),
              "104,101,108,108,111");
    EXPECT_EQ(eval_ok("Array.from(bytesFromBase64('aGk=')).join(',');").as<std::string>(),
              "104,105");
}

// ================= native（put/take/free）=================

TEST_F(RuntimeApiFixture, NativePutTakeFree)
{
    // put → id（string，UUID v4）
    std::string id = eval_ok("native.put(new Uint8Array([7,8,9]));").as<std::string>();
    EXPECT_EQ(id.size(), 36u);
    // get 不消费：可重复取
    EXPECT_EQ(eval_ok("Array.from(native_get('" + id + "')).join(',');").as<std::string>(),
              "7,8,9");
    // take 消费语义：取走即删
    EXPECT_EQ(eval_ok("Array.from(native.take('" + id + "')).join(',');").as<std::string>(),
              "7,8,9");
    EXPECT_TRUE(eval_ok("native_get('" + id + "') === null;").as<bool>());
    // 再 take → null；free 已删除 id → false
    EXPECT_TRUE(eval_ok("native.take('" + id + "') === null;").as<bool>());
    EXPECT_FALSE(eval_ok("native.free('" + id + "');").as<bool>());
}

TEST_F(RuntimeApiFixture, NativeFree)
{
    const std::string id = eval_ok("native.put(new Uint8Array([1]));").as<std::string>();
    EXPECT_TRUE(eval_ok("native.free('" + id + "');").as<bool>());
    EXPECT_TRUE(eval_ok("native_get('" + id + "') === null;").as<bool>());
    EXPECT_TRUE(eval_ok("native.free('" + id + "') === false;").as<bool>()); // 幂等
}

TEST_F(RuntimeApiFixture, NativePutTypeError)
{
    EXPECT_TRUE(eval_ok(
        "(() => { try { native.put('str'); return false; } catch (e) { "
        "return e instanceof TypeError; } })();").as<bool>());
}

// ================= uuidv4 =================

TEST_F(RuntimeApiFixture, UuidV4)
{
    const std::string a = eval_ok("uuidv4();").as<std::string>();
    const std::string b = eval_ok("uuidv4();").as<std::string>();
    // 8-4-4-4-12 十六进制格式
    EXPECT_EQ(a.size(), 36u);
    EXPECT_EQ(a[8], '-');
    EXPECT_EQ(a[13], '-');
    EXPECT_EQ(a[18], '-');
    EXPECT_EQ(a[23], '-');
    EXPECT_NE(a, b);
}

// ================= runtime =================

TEST_F(RuntimeApiFixture, RuntimeGc)
{
    // gc 可调用且不抛（显式 GC 后对象仍可用）
    EXPECT_EQ(eval_ok("runtime.gc(); typeof runtime.gc;").as<std::string>(), "function");
}

TEST_F(RuntimeApiFixture, IsTaskGroupCancelled)
{
    // 长任务：cancel 后查询 → true
    ctx.eval("globalThis.longTask = () => new Promise(r => setTimeout(r, 300));");
    std::thread js_thread([&] { rt.run(); });
    auto h = runner.submit({"longTask", "{}"});
    EXPECT_TRUE(runner.cancel(h.id));
    auto res = wait_result(std::move(h.result_rx));
    ASSERT_TRUE(res.has_value());
    EXPECT_FALSE(res->ok);
    EXPECT_EQ(res->json, "cancelled");
    rt.stop();
    js_thread.join();

    EXPECT_TRUE(eval_ok("runtime.isTaskGroupCancelled(" + std::to_string(h.id) + ");")
                    .as<bool>());
}

TEST_F(RuntimeApiFixture, IsTaskGroupCancelledFalse)
{
    // 正常完成的任务：查询 → false；未提交过的 id → false
    ctx.eval("globalThis.doneTask = () => 42;");
    std::thread js_thread([&] { rt.run(); });
    auto h = runner.submit({"doneTask", "{}"});
    auto res = wait_result(std::move(h.result_rx));
    ASSERT_TRUE(res.has_value());
    ASSERT_TRUE(res->ok) << res->json;
    rt.stop();
    js_thread.join();

    EXPECT_FALSE(eval_ok("runtime.isTaskGroupCancelled(" + std::to_string(h.id) + ");")
                     .as<bool>());
    EXPECT_FALSE(eval_ok("runtime.isTaskGroupCancelled(999999);").as<bool>());
}

// ================= Buffer =================

TEST_F(RuntimeApiFixture, BufferBasics)
{
    EXPECT_EQ(eval_ok("typeof Buffer;").as<std::string>(), "function");
    EXPECT_EQ(eval_ok("Buffer.from('abc').toString('hex');").as<std::string>(), "616263");
    EXPECT_EQ(eval_ok("Buffer.alloc(4).length;").as<int>(), 4);
    EXPECT_EQ(eval_ok("Buffer.from([1,2,3]).readUInt8(1);").as<int>(), 2);
    EXPECT_EQ(eval_ok("Buffer.concat([Buffer.from('a'), Buffer.from('b')]).toString();")
                  .as<std::string>(),
              "ab");
    EXPECT_TRUE(eval_ok("Buffer.isBuffer(Buffer.from('x'));").as<bool>());
    EXPECT_TRUE(eval_ok("Buffer.isBuffer(new Uint8Array(1)) === false;").as<bool>());
    // Buffer 是 Uint8Array 子类
    EXPECT_TRUE(eval_ok("Buffer.from('x') instanceof Uint8Array;").as<bool>());
}

TEST_F(RuntimeApiFixture, BufferWriteRead)
{
    // 注意：quickjs 的连续 eval 共享全局作用域，避免重复 const 声明
    EXPECT_EQ(eval_ok(
                  "const buf8 = Buffer.alloc(8);"
                  "buf8.writeUInt16BE(0x1234, 0);"
                  "buf8.readUInt16BE(0);").as<int>(),
              0x1234);
    EXPECT_EQ(eval_ok("Buffer.from('hello').toString('base64');").as<std::string>(),
              "aGVsbG8=");
}

// ================= gzip =================

TEST_F(RuntimeApiFixture, GzipJsRoundtrip)
{
    // Uint8Array 进 → 解回
    EXPECT_EQ(
        eval_ok(
            "Array.from(gzipDecompress(gzipCompress(new Uint8Array([1,2,3,4])))).join(',');")
            .as<std::string>(),
        "1,2,3,4");
    // 多种格式输入由 toBytes 收窄：ArrayBuffer / number[]
    EXPECT_EQ(eval_ok(
                  "const ab = new Uint8Array([104,105]).buffer;"
                  "Array.from(gzipDecompress(gzipCompress(ab))).join(',');").as<std::string>(),
              "104,105");
    EXPECT_EQ(
        eval_ok("Array.from(gzipDecompress(gzipCompress([1,2,3]))).join(',');").as<std::string>(),
        "1,2,3");
    // gzip 格式魔数（1f 8b）
    EXPECT_EQ(eval_ok("gzipCompress(new Uint8Array([104])).slice(0,2).join(',');")
                  .as<std::string>(),
              "31,139");
    // 空输入往返
    EXPECT_EQ(eval_ok("gzipDecompress(gzipCompress(new Uint8Array([]))).length;").as<int>(), 0);
}

TEST_F(RuntimeApiFixture, GzipNativeMounted)
{
    // native 对象挂载（对齐 kit 的 native.gzipCompress / native.gzipDecompress）
    EXPECT_EQ(eval_ok("typeof native.gzipCompress;").as<std::string>(), "function");
    EXPECT_EQ(eval_ok("typeof native.gzipDecompress;").as<std::string>(), "function");
    EXPECT_EQ(
        eval_ok(
            "Array.from(native.gzipDecompress(native.gzipCompress(new Uint8Array([7,8,9])))).join(',');")
            .as<std::string>(),
        "7,8,9");
}

TEST_F(RuntimeApiFixture, GzipJsTypeErrors)
{
    // 非二进制输入 → TypeError（toBytes 收窄拒绝）
    EXPECT_TRUE(eval_ok(
        "(() => { try { gzipCompress('str'); return false; } catch (e) { "
        "return e instanceof TypeError; } })();").as<bool>());
    // 非法 gzip 数据解压 → 抛异常（zlib 错误 → JS Error）
    EXPECT_TRUE(eval_ok(
        "(() => { try { gzipDecompress(new Uint8Array([1,2,3])); return false; } "
        "catch (e) { return true; } })();").as<bool>());
}

// ================= opencc（JS 入口）=================

TEST_F(RuntimeApiFixture, OpenccJs)
{
    EXPECT_EQ(eval_ok("opencc.convert('鼠标', 's2t.json');").as<std::string>(), "鼠標");
    EXPECT_EQ(eval_ok("opencc.convert('里面', 's2tw.json');").as<std::string>(), "裡面");
    EXPECT_EQ(eval_ok("opencc.convert('里面', 's2hk.json');").as<std::string>(), "裏面");
    EXPECT_EQ(eval_ok("opencc.convert('軟體', 't2s.json');").as<std::string>(), "软体");
    // 未知配置 → 抛异常（C++ std::invalid_argument → JS Error）
    EXPECT_TRUE(eval_ok(
        "(() => { try { opencc.convert('鼠标', 's2x.json'); return false; } "
        "catch (e) { return true; } })();").as<bool>());
}

} // namespace
