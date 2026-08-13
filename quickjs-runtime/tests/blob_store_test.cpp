// blob_store_test.cpp —— 二进制暂存（docs/blob_store_design.md v1）验收测试
//
// 覆盖（设计文档 §8 + 差异点：C++ 侧无 host 隔离限制）：
//   - put/get 往返（ArrayBuffer、Uint8Array、DataView 三种入参；拷入拷出语义）
//   - 空二进制合法；get 未注册 id → null
//   - 非二进制参数 → TypeError；get 非字符串 → TypeError
//   - 隔离性：host A 存、host B 取 → null（JS 侧硬性隔离，qjs 实例互不可见）
//   - ★ C++ 特权：put/get 可访问任意 host 的桶；find_any 跨桶按 id 全局取数
//     （不需要知道 id 属于哪个 host——cpp 可以随意获取所有想要的数据）
//   - remove_host 生命周期 + Runtime 析构钩子整桶回收
//   - TTL：小 TTL + 手动 sweep_now 验证回收与滑动刷新（get 续命）
//   - 并发：多裸线程 + 两个 Runtime 的 JS 线程混合 put/get 不崩不丢
//   - install 幂等
#include <atomic>
#include <chrono>
#include <cstddef>
#include <mutex>
#include <string>
#include <thread>
#include <utility>
#include <vector>

#include <gtest/gtest.h>
#include <qjsbind/blob_store.hpp>
#include <qjsbind/qjsbind.hpp>

using namespace qjs;
using qjs::dyn::BlobStore;

namespace {

// ---- 单 Runtime fixture（JS thunk 走进程级单例）----
struct BlobFixture : ::testing::Test {
    Runtime rt;
    Context ctx = rt.main_context();

    void SetUp() override
    {
        dyn::install_blob_store(ctx);
    }

    // eval 后断言无异常（接受拼接字符串：id 需插进 JS 代码）
    Value eval_ok(const std::string& code)
    {
        Value r = ctx.eval(code);
        EXPECT_FALSE(r.is_exception());
        return r;
    }
};

// 局部 store：小 TTL + 禁 sweeper（sweep_now 手动控制回收时机）。
// ttl=500ms、sleep 300/700ms：余量 ≥200ms，避免 CI 时间抖动误判。
struct TinyStore {
    BlobStore store{BlobStore::Config{std::chrono::milliseconds(500), std::chrono::milliseconds(0)}};
};

// ================= put/get 基本往返 =================

TEST_F(BlobFixture, PutGetRoundtrip)
{
    // Uint8Array 入参
    std::string id = eval_ok("native_put(new Uint8Array([1,2,3]));").as<std::string>();
    EXPECT_EQ(id.size(), 36u); // UUID v4
    EXPECT_EQ(eval_ok("Array.from(native_get('" + id + "')).join('');").as<std::string>(),
              std::string("123"));

    // ArrayBuffer 入参
    std::string id2 = eval_ok(
        "const b = new ArrayBuffer(4);"
        "new Uint8Array(b).set([9,8,7,6]);"
        "native_put(b);").as<std::string>();
    EXPECT_EQ(eval_ok("Array.from(native_get('" + id2 + "')).join('');").as<std::string>(),
              std::string("9876"));

    // DataView 入参（byteOffset/byteLength 视野：只存视图内的字节）
    std::string id3 = eval_ok(
        "const dv = new DataView(new Uint8Array([5,6,7,8]).buffer, 1, 2);"
        "native_put(dv);").as<std::string>();
    EXPECT_EQ(eval_ok("Array.from(native_get('" + id3 + "')).join('');").as<std::string>(),
              std::string("67"));

    // 返回的是 Uint8Array
    EXPECT_TRUE(eval_ok("native_get('" + id + "') instanceof Uint8Array;").as<bool>());
}

// 拷入拷出语义（D5）：put 后改原数组、get 后改返回数组都不影响库存
TEST_F(BlobFixture, CopyInCopyOut)
{
    std::string id = eval_ok(
        "const a = new Uint8Array([1,2,3]);"
        "const id = native_put(a);"
        "a[0] = 99;" // 改原数组
        "id;").as<std::string>();
    EXPECT_TRUE(eval_ok("native_get('" + id + "')[0] === 1;").as<bool>());
    // 改 get 返回的数组
    EXPECT_TRUE(eval_ok("const b = native_get('" + id + "'); b[0] = 77; true;").as<bool>());
    EXPECT_TRUE(eval_ok("native_get('" + id + "')[0] === 1;").as<bool>());
}

TEST_F(BlobFixture, EmptyBlob)
{
    std::string id = eval_ok("native_put(new Uint8Array([]));").as<std::string>();
    EXPECT_EQ(eval_ok("native_get('" + id + "').length;").as<double>(), 0.0);
}

TEST_F(BlobFixture, GetMissing)
{
    EXPECT_TRUE(eval_ok("native_get('no-such-id') === null;").as<bool>());
}

// ================= 错误模型（设计文档 §7）=================

TEST_F(BlobFixture, PutTypeError)
{
    EXPECT_EQ(eval_ok("try { native_put('not binary'); 'no-throw'; } catch (e) { e.name; }")
                  .as<std::string>(), std::string("TypeError"));
    EXPECT_EQ(eval_ok("try { native_put(42); 'no-throw'; } catch (e) { e.name; }")
                  .as<std::string>(), std::string("TypeError"));
    EXPECT_EQ(eval_ok("try { native_put(); 'no-throw'; } catch (e) { e.name; }")
                  .as<std::string>(), std::string("TypeError"));
    EXPECT_EQ(eval_ok("try { native_put({}); 'no-throw'; } catch (e) { e.name; }")
                  .as<std::string>(), std::string("TypeError"));
}

// detached（transfer 后）的 ArrayBuffer：不得崩溃/越界读，抛异常
TEST_F(BlobFixture, PutDetachedBufferThrows)
{
    Value r = eval_ok(
        "try {"
        "  const b = new Uint8Array([1,2,3]).buffer;"
        "  b.transfer();" // detach 原 buffer（返回的新 buffer 忽略）
        "  native_put(b);"
        "  'no-throw';"
        "} catch (e) { e.name; }");
    EXPECT_NE(r.as<std::string>(), std::string("no-throw"));
    // 异常被正确消费：之后仍可正常使用
    std::string id = eval_ok("native_put(new Uint8Array([1]));").as<std::string>();
    EXPECT_TRUE(eval_ok("native_get('" + id + "')[0] === 1;").as<bool>());
}

TEST_F(BlobFixture, GetTypeError)
{
    EXPECT_EQ(eval_ok("try { native_get(42); 'no-throw'; } catch (e) { e.name; }")
                  .as<std::string>(), std::string("TypeError"));
    EXPECT_EQ(eval_ok("try { native_get(); 'no-throw'; } catch (e) { e.name; }")
                  .as<std::string>(), std::string("TypeError"));
    EXPECT_EQ(eval_ok("try { native_get(null); 'no-throw'; } catch (e) { e.name; }")
                  .as<std::string>(), std::string("TypeError"));
    // 异常被正确消费后仍可正常使用
    std::string id = eval_ok("native_put(new Uint8Array([1]));").as<std::string>();
    EXPECT_TRUE(eval_ok("native_get('" + id + "')[0] === 1;").as<bool>());
}

// ================= JS 侧隔离（qjs 实例互不可见）=================

TEST(BlobTest, JsIsolationAcrossHosts)
{
    Runtime rtA("blob-host-A");
    Runtime rtB("blob-host-B");
    Context ctxA = rtA.main_context();
    Context ctxB = rtB.main_context();
    dyn::install_blob_store(ctxA);
    dyn::install_blob_store(ctxB);

    std::string idA = ctxA.eval("native_put(new Uint8Array([1,2,3]));").as<std::string>();
    std::string idB = ctxB.eval("native_put(new Uint8Array([7,8]));").as<std::string>();

    // B 取 A 的 id → null；A 取 B 的 id → null（三者对外不可区分，都返回 null）
    EXPECT_TRUE(ctxB.eval("native_get('" + idA + "') === null;").as<bool>());
    EXPECT_TRUE(ctxA.eval("native_get('" + idB + "') === null;").as<bool>());
    // 各自取自己的 → 命中
    EXPECT_EQ(ctxA.eval("Array.from(native_get('" + idA + "')).join('');").as<std::string>(),
              std::string("123"));
    EXPECT_EQ(ctxB.eval("Array.from(native_get('" + idB + "')).join('');").as<std::string>(),
              std::string("78"));
    // 但 C++ 特权入口仍然能跨桶取到（隔离只约束 JS 侧 thunk）
    auto any = BlobStore::instance().find_any(idA);
    ASSERT_TRUE(any.has_value());
    EXPECT_EQ(any->first, "blob-host-A");
    EXPECT_EQ(any->second.size(), 3u);
}

// ================= ★ C++ 侧无隔离限制（差异点）=================

TEST(BlobTest, CppNoIsolation)
{
    BlobStore& store = BlobStore::instance();
    std::vector<std::byte> data{std::byte{1}, std::byte{2}, std::byte{3}};

    // C++ put 可写入任意 host 的桶（哪怕该 host 从未 install 过任何 Runtime）
    std::string id = store.put("ghost-host", data);
    EXPECT_TRUE(store.get("ghost-host", id).has_value());

    // C++ get 可读取任意 host 的桶
    auto got = store.get("ghost-host", id);
    ASSERT_TRUE(got.has_value());
    EXPECT_EQ(*got, data);

    // find_any：不需要知道 id 属于哪个 host，跨所有桶全局找到
    auto any = store.find_any(id);
    ASSERT_TRUE(any.has_value());
    EXPECT_EQ(any->first, "ghost-host");
    EXPECT_EQ(any->second, data);

    // 不存在的 id → nullopt
    EXPECT_FALSE(store.find_any("no-such-id").has_value());

    // 清理测试数据
    store.remove_host("ghost-host");
}

// ================= remove_host 生命周期 =================

TEST_F(BlobFixture, RemoveHostLifecycle)
{
    std::string id = eval_ok("native_put(new Uint8Array([1]));").as<std::string>();
    EXPECT_TRUE(BlobStore::instance().get(rt.id(), id).has_value());

    BlobStore::instance().remove_host(rt.id());
    // 整桶没了：get → null（thunk 不悬挂，仍可用）
    EXPECT_TRUE(eval_ok("native_get('" + id + "') === null;").as<bool>());
    EXPECT_FALSE(BlobStore::instance().find_any(id).has_value());

    // 之后再 put 自动重建桶（D8）
    std::string id2 = eval_ok("native_put(new Uint8Array([2]));").as<std::string>();
    EXPECT_TRUE(BlobStore::instance().get(rt.id(), id2).has_value());
}

// Runtime 析构钩子：整桶立即回收，不等 TTL
TEST(BlobTest, RuntimeDestructorRemovesBucket)
{
    std::string host_id;
    std::string blob_id;
    {
        Runtime rt("blob-dtor-host");
        Context ctx = rt.main_context();
        dyn::install_blob_store(ctx);
        host_id = rt.id();
        blob_id = ctx.eval("native_put(new Uint8Array([5,5]));").as<std::string>();
        EXPECT_TRUE(BlobStore::instance().get(host_id, blob_id).has_value());
    } // rt 析构 → dyn::remove_blob_host(id_)
    EXPECT_FALSE(BlobStore::instance().get(host_id, blob_id).has_value());
    EXPECT_FALSE(BlobStore::instance().find_any(blob_id).has_value());
}

// ================= TTL 回收与滑动刷新 =================

TEST(BlobTest, TtlExpiryAndSweep)
{
    TinyStore ts; // ttl=500ms，sweeper 禁用
    BlobStore& store = ts.store;

    // 1) 基本存取
    std::string id = store.put("h", {std::byte{1}});
    EXPECT_TRUE(store.get("h", id).has_value());

    // 2) 未到 TTL：sweep 不回收（此阶段不再 get，避免刷新 last_used）
    std::this_thread::sleep_for(std::chrono::milliseconds(300)); // < 500ms TTL
    store.sweep_now();
    EXPECT_TRUE(store.get("h", id).has_value());

    // 3) 超过 TTL：get 读路径即不可得（D7，不用等 sweeper）
    //    （新条目干净起点：期间不 get，last_used 不被刷新）
    std::string id2 = store.put("h", {std::byte{2}});
    std::this_thread::sleep_for(std::chrono::milliseconds(700)); // > 500ms TTL
    EXPECT_FALSE(store.get("h", id2).has_value());

    // 4) 滑动刷新：TTL 内 get 一次即续命
    std::string id3 = store.put("h", {std::byte{3}});
    std::this_thread::sleep_for(std::chrono::milliseconds(300));
    EXPECT_TRUE(store.get("h", id3).has_value()); // 命中并刷新 last_used
    std::this_thread::sleep_for(std::chrono::milliseconds(300)); // 距上次 300ms < 500ms
    EXPECT_TRUE(store.get("h", id3).has_value());
    std::this_thread::sleep_for(std::chrono::milliseconds(700)); // 距上次 700ms > 500ms
    EXPECT_FALSE(store.get("h", id3).has_value());

    // 5) sweep_now 释放内存：过期条目清掉，空桶摘除
    std::string id4 = store.put("h", {std::byte{4}});
    std::this_thread::sleep_for(std::chrono::milliseconds(700));
    store.sweep_now();
    EXPECT_FALSE(store.get("h", id4).has_value());
    EXPECT_FALSE(store.find_any(id4).has_value());
}

// ================= 并发 =================

// 多裸线程混合 put/get：不崩不丢
TEST(BlobTest, ConcurrentThreads)
{
    BlobStore store(BlobStore::Config{std::chrono::seconds(60), std::chrono::milliseconds(0)});
    constexpr int kThreads = 4;
    constexpr int kItems = 200;
    std::atomic<bool> ok{true};
    std::mutex ids_mu;
    std::vector<std::pair<std::string, std::string>> sample_ids; // (host, id)

    std::vector<std::thread> threads;
    for (int t = 0; t < kThreads; ++t) {
        threads.emplace_back([&, t] {
            const std::string host = "th-" + std::to_string(t);
            std::vector<std::string> ids;
            for (int i = 0; i < kItems; ++i) {
                std::vector<std::byte> data(kItems + i, static_cast<std::byte>(i));
                ids.push_back(store.put(host, data));
            }
            {
                std::lock_guard lock(ids_mu);
                sample_ids.emplace_back(host, ids[0]); // 本线程的 (host, id)
            }
            for (int i = 0; i < kItems; ++i) {
                auto got = store.get(host, ids[i]);
                if (!got || got->size() != kItems + i ||
                    (*got)[0] != static_cast<std::byte>(i) ||
                    (*got).back() != static_cast<std::byte>(i))
                    ok.store(false);
            }
        });
    }
    for (auto& th : threads)
        th.join();
    EXPECT_TRUE(ok.load());

    // find_any 并发后仍可全局找到其他线程写入的数据
    for (auto& [host, id] : sample_ids) {
        auto any = store.find_any(id);
        ASSERT_TRUE(any.has_value());
        EXPECT_EQ(any->first, host);
    }
}

// 两个 Runtime 各自 JS 线程并发 put/get + 隔离验证
TEST(BlobTest, TwoRuntimesConcurrentJs)
{
    std::string idA;
    std::atomic<bool> a_ready{false};
    std::atomic<bool> ok{true};
    std::mutex fail_mu;
    std::string fail_msg;

    auto record_fail = [&](const std::string& msg) {
        ok.store(false);
        std::lock_guard lock(fail_mu);
        if (fail_msg.empty())
            fail_msg = msg;
    };

    // JS 代码包 try/catch：失败时返回 'ERR:...'，便于定位
    auto workerA = [&] {
        Runtime rt("blob-js-A");
        Context ctx = rt.main_context();
        dyn::install_blob_store(ctx);
        Value r = ctx.eval("try { native_put(new Uint8Array([1,2,3])); } catch (e) { 'ERR:' + e.message; }");
        if (r.is_exception() || r.as<std::string>().rfind("ERR:", 0) == 0) {
            record_fail("A put: " + (r.is_exception() ? std::string("<exception>")
                                                      : r.as<std::string>()));
            return;
        }
        idA = r.as<std::string>();
        a_ready.store(true); // release：idA 写入先于 ready
        for (int i = 0; i < 100; ++i) {
            Value v = ctx.eval(
                "try { const id = native_put(new Uint8Array([4,5,6])); const b = native_get(id);"
                "  b[0] === 4 && b[1] === 5 && b[2] === 6 ? 'ok' : 'BAD'; }"
                "catch (e) { 'ERR:' + e.message; }");
            if (v.is_exception() || v.as<std::string>() != "ok") {
                record_fail("A loop#" + std::to_string(i) + ": " +
                            (v.is_exception() ? std::string("<exception>")
                                              : v.as<std::string>()));
                return;
            }
        }
        // C++ 特权（rt 仍存活）：并发中全局取到本 host 数据
        auto any = BlobStore::instance().find_any(idA);
        if (!any || any->first != "blob-js-A" || any->second.size() != 3u)
            record_fail("A find_any failed");
    };
    auto workerB = [&] {
        Runtime rt("blob-js-B");
        Context ctx = rt.main_context();
        dyn::install_blob_store(ctx);
        while (!a_ready.load()) // acquire：读 idA 前确保其已写入
            std::this_thread::yield();
        // 隔离：B 的 JS 取 A 的 id → null
        Value v = ctx.eval("try { native_get('" + idA + "') === null ? 'ok' : 'VISIBLE'; }"
                           "catch (e) { 'ERR:' + e.message; }");
        if (v.is_exception() || v.as<std::string>() != "ok") {
            record_fail("B isolation: " + (v.is_exception() ? std::string("<exception>")
                                                            : v.as<std::string>()));
            return;
        }
        for (int i = 0; i < 100; ++i) {
            Value v2 = ctx.eval(
                "try { const id = native_put(new Uint8Array([7,8])); const b = native_get(id);"
                "  b[0] === 7 && b[1] === 8 ? 'ok' : 'BAD'; }"
                "catch (e) { 'ERR:' + e.message; }");
            if (v2.is_exception() || v2.as<std::string>() != "ok") {
                record_fail("B loop#" + std::to_string(i) + ": " +
                            (v2.is_exception() ? std::string("<exception>")
                                               : v2.as<std::string>()));
                return;
            }
        }
    };
    std::thread tA(workerA), tB(workerB);
    tA.join();
    tB.join();
    EXPECT_TRUE(ok.load()) << fail_msg;
}

// ================= install 幂等 =================

TEST_F(BlobFixture, ReinstallIdempotent)
{
    dyn::install_blob_store(ctx);
    dyn::install_blob_store(ctx);
    std::string id = eval_ok("native_put(new Uint8Array([1]));").as<std::string>();
    EXPECT_TRUE(eval_ok("native_get('" + id + "')[0] === 1;").as<bool>());
}

} // namespace
