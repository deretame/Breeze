// dyn_blob_polyfill_test.cpp —— dyn blob polyfill（include/qjsbind/polyfill/dyn_blob.js）
//
// 覆盖：
//   - callSync + TypedArray/ArrayBuffer：二进制 → blob_store 占位对象，handler
//     按 $blob/$host 从 BlobStore 取回字节
//   - call（async）+ TypedArray：同链路走 Promise
//   - 非二进制参数原样透传（数字/字符串/对象不被 polyfill 触碰）
//   - native_host_id() 与 handler 收到的 host_id 一致
#include <cstddef>
#include <string>
#include <string_view>
#include <unordered_map>
#include <vector>

#include <glaze/glaze.hpp>
#include <gtest/gtest.h>
#include <qjsbind/blob_store.hpp>
#include <qjsbind/dynamic_call.hpp>
#include <qjsbind/polyfill/dyn_blob.hpp>
#include <qjsbind/qjsbind.hpp>

using namespace qjs;

namespace {

// 占位对象 {"$blob": id, "$host": host_id} → BlobStore 取字节 → 汇总返回
std::string blob_sum(std::string_view host_id, std::string_view, std::string_view args)
{
    auto v = glz::read_json<
        std::vector<std::unordered_map<std::string, std::string>>>(args);
    if (!v || v->empty())
        throw std::runtime_error("bad args");
    const auto& ref = v->front();
    std::optional<std::vector<std::byte>> data =
        dyn::BlobStore::instance().get(ref.at("$host"), ref.at("$blob"));
    if (!data)
        throw std::runtime_error("blob not found");
    unsigned sum = 0;
    for (std::byte b : *data)
        sum += static_cast<unsigned>(b);
    // host_match：占位对象里的 $host 必须等于 handler 注入的 host_id
    return "{\"sum\":" + std::to_string(sum) + ",\"len\":" +
           std::to_string(data->size()) + ",\"host_match\":" +
           (ref.at("$host") == host_id ? "1" : "0") + "}";
}

std_exec::task<std::string> blob_sum_async(std::string host_id, std::string name,
                                           std::string args)
{
    co_return blob_sum(host_id, name, args);
}

struct DynBlobFixture : ::testing::Test {
    Runtime rt;
    Context ctx = rt.main_context();

    void SetUp() override
    {
        dyn::install_blob_store(ctx);
        dyn::install_dynamic_call(ctx);
        dyn::install_dyn_blob_polyfill(ctx);
    }

    Value eval_ok(const char* code)
    {
        Value r = ctx.eval(code);
        EXPECT_FALSE(r.is_exception());
        return r;
    }
};

TEST_F(DynBlobFixture, SyncTypedArray)
{
    dyn::register_global("blob_sum", blob_sum);
    eval_ok("globalThis.__r = callSync('blob_sum', new Uint8Array([1,2,3,4]));");
    EXPECT_EQ(eval_ok("__r.sum").as<int>(), 10);
    EXPECT_EQ(eval_ok("__r.len").as<int>(), 4);
    EXPECT_EQ(eval_ok("__r.host_match").as<int>(), 1);
}

TEST_F(DynBlobFixture, SyncArrayBuffer)
{
    dyn::register_global("blob_sum", blob_sum);
    eval_ok("const b = new ArrayBuffer(3); new Uint8Array(b).set([5,6,7]);"
            "globalThis.__r = callSync('blob_sum', b);");
    EXPECT_EQ(eval_ok("__r.sum").as<int>(), 18);
    EXPECT_EQ(eval_ok("__r.len").as<int>(), 3);
}

TEST_F(DynBlobFixture, SyncMixedArgs)
{
    // 混合参数：二进制占位 + 普通参数透传，顺序保持
    dyn::register_global(
        "mixed", [](std::string_view, std::string_view, std::string_view args) {
            // args[0] 是占位对象，args[1]/[2] 原样透传
            return std::string(args);
        });
    eval_ok("globalThis.__r = callSync('mixed', new Uint8Array([9]), 42, 'x');");
    EXPECT_EQ(eval_ok("__r[1]").as<int>(), 42);
    EXPECT_EQ(eval_ok("__r[2]").as<std::string>(), "x");
    EXPECT_EQ(eval_ok("typeof __r[0].$blob").as<std::string>(), "string");
    EXPECT_EQ(eval_ok("typeof __r[0].$host").as<std::string>(), "string");
}

TEST_F(DynBlobFixture, AsyncTypedArray)
{
    dyn::register_global_async("blob_sum_async", blob_sum_async);
    eval_ok("call('blob_sum_async', new Uint8Array([10,20,30]))"
            ".then(v => { globalThis.__r = v; }); 'ok';");
    rt.run_to_completion();
    EXPECT_EQ(eval_ok("__r.sum").as<int>(), 60);
    EXPECT_EQ(eval_ok("__r.len").as<int>(), 3);
    EXPECT_EQ(eval_ok("__r.host_match").as<int>(), 1);
}

TEST_F(DynBlobFixture, PassthroughUntouched)
{
    // 纯普通参数：polyfill 不引入任何变化
    dyn::register_global("echo_args", [](std::string_view, std::string_view,
                                         std::string_view args) { return std::string(args); });
    eval_ok("globalThis.__r = callSync('echo_args', 1, 'a', {x: [1,2]}, null);");
    EXPECT_EQ(eval_ok("JSON.stringify(__r)").as<std::string>(), R"([1,"a",{"x":[1,2]},null])");
}

} // namespace
