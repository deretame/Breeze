// runtime_api.hpp —— Breeze 风格运行时 API 安装入口（base64 / native / runtime / opencc / Buffer）
//
// 职责（docs/breeze_api_gap_analysis.md §8 实现记录）：
//   1. C++ 侧注册最小原生能力：
//        __native_b64encode(bytes) → string   （BoringSSL EVP，经 fetch::base64_encode）
//        __native_b64decode(str) → Uint8Array   （BoringSSL EVP，经 fetch::base64_decode）
//        __native_gc()                            （JS_RunGC）
//        uuidv4() → string                        （boost::uuids make_uuid_v4）
//        __opencc_convert(text, config) → string  （opencc::convert，纯 C++ 实现）
//   2. eval JS 资产：buffer_lib.js（npm buffer 打包）→ runtime_api.js（polyfill，
//      定义 bytesToBase64/bytesFromBase64/base64/native/runtime/opencc 并挂载 Buffer）。
//
// 其余原生能力由既有设施提供（install 顺序要求）：
//   - native_put / native_get / __native_buf_free：blob_store.hpp（install_blob_store）
//   - __native_task_cancelled：task.hpp（TaskRunner 构造时注册）
//
// ★ __native_b64encode 同时由 bundle_dispatcher.hpp 注册（同实现）：本入口重复
// 注册属幂等覆盖（HostRuntime 中 bundle_dispatcher 后装，覆盖成相同实现，
// 无行为差异）；独立使用方（测试等）装本入口即可自包含 base64 原生能力。
//
// 幂等：重复 install 覆盖注册 + 重新 eval，不报错。
// 由 HostRuntime::setup_apis 自动安装（web API 之后、宿主 register_all 之前）；
// 独立使用方（测试等）须先 install_blob_store / install_dynamic_call 等。
#pragma once

#include <quickjs.h>

#include <fetch/types.hpp> // fetch::base64_decode（BoringSSL EVP；fetchcore 公开纯函数）
#include <qjsbind/binary.hpp> // qjs::Context::new_uint8_array / js_bytes
#include <qjsbind/context.hpp>
#include <qjsbind/error.hpp>
#include <qjsbind/function.hpp> // qjs::func / Object::set（异常边界自动）
#include <qjsbind/value.hpp>

#include <opencc/opencc.hpp> // opencc::convert（纯 C++ 简繁转换）

#include <qjsbind/polyfill/runtime_api_embedded.hpp> // 生成物（configure 期生成，不入库）

#include <gzip/gzip.hpp> // gzip::compress / gzip::decompress（纯 C++ 二进制进出）

#include <cstddef>
#include <string>
#include <string_view>

namespace qjs {

// 安装 Breeze 风格运行时 API（幂等；见文件头注释的安装顺序要求）
inline void install_runtime_api(qjs::Context& ctx)
{
    Object global = ctx.globals();

    // __native_b64encode：标准 base64 编码（BoringSSL EVP_EncodeBlock，经
    // fetchcore 公开入口）。与 bundle_dispatcher.hpp 注册的版本同实现
    //（幂等覆盖，见文件头注释）；polyfill 的 bytesToBase64 优先调用。
    global.set("__native_b64encode", [](Ctx cx, Value v) -> std::string {
        const std::vector<std::byte> bytes = qjs::js_bytes(cx.ctx, v.raw());
        return fetch::base64_encode(
            std::string(reinterpret_cast<const char*>(bytes.data()), bytes.size()));
    });

    // __native_b64decode：标准 base64 解码（BoringSSL EVP_DecodeBase64，
    // 经 fetchcore 公开入口；失败抛 JS Error）。与 __native_b64encode 对称，
    // 供 polyfill 优先调用。
    global.set("__native_b64decode", [](Ctx cx, Value v) -> Value {
        qjs::Context c(cx.ctx);
        if (!v.is_string())
            throw_type_error(cx.ctx, "__native_b64decode: 需要字符串");
        const std::string s = c.from_js<std::string>(v.raw());
        const auto out = fetch::base64_decode(s);
        if (!out)
            throw std::runtime_error("__native_b64decode: 非法 base64 输入");
        return c.new_uint8_array(
            reinterpret_cast<const std::byte*>(out->data()), out->size());
    });

    // __native_gc：显式 GC（QuickJS JS_RunGC）
    global.set("__native_gc", [](Ctx cx) { JS_RunGC(JS_GetRuntime(cx.ctx)); });

    // uuidv4：全局 UUID v4 生成（boost::uuids random_generator，context.hpp 已有）
    global.set("uuidv4", [](Ctx cx) -> std::string {
        (void)cx;
        return make_uuid_v4();
    });

    // __opencc_convert：简繁转换（C++ 实现；未知配置 → std::invalid_argument →
    // 自动转 JS Error）
    global.set("__opencc_convert", [](Ctx cx, Value text, Value config) -> std::string {
        qjs::Context c(cx.ctx);
        const std::string t = c.from_js<std::string>(text.raw());
        const std::string cfg = c.from_js<std::string>(config.raw());
        return opencc::convert(t, cfg);
    });

    // __native_gzip_compress / __native_gzip_decompress：gzip 格式压缩/解压。
    // 只接受二进制进（js_bytes：ArrayBuffer/TypedArray/DataView，其它 → TypeError）、
    // 二进制出（Uint8Array）——多种输入格式收窄由 JS 侧 polyfill（toBytes）负责。
    // 非法输入（解压）→ zlib 错误 → std::runtime_error → 自动转 JS Error。
    global.set("__native_gzip_compress", [](Ctx cx, Value v) -> Value {
        qjs::Context c(cx.ctx);
        const std::vector<std::byte> bytes = c.js_bytes(v.raw());
        const std::vector<std::byte> out = gzip::compress(bytes);
        return c.new_uint8_array(out.data(), out.size());
    });
    global.set("__native_gzip_decompress", [](Ctx cx, Value v) -> Value {
        qjs::Context c(cx.ctx);
        const std::vector<std::byte> bytes = c.js_bytes(v.raw());
        const std::vector<std::byte> out = gzip::decompress(bytes);
        return c.new_uint8_array(out.data(), out.size());
    });

    // global 兜底：npm buffer 打包产物内部可能引用全局变量 `global`
    //（feross/buffer 的 browser 兼容写法），quickjs 无此变量，先补一个别名。
    {
        Value g = ctx.eval("if (typeof global === 'undefined') globalThis.global = globalThis;",
                           "<runtime_api_global>");
        if (g.is_exception())
            throw js_error(ctx.raw(), JS_GetException(ctx.raw()));
    }

    // JS 资产：buffer_lib（npm buffer IIFE，暴露 __buffer_lib）→ runtime_api polyfill
    Value lib = ctx.eval(polyfill::buffer_lib_js, "<buffer_lib>");
    if (lib.is_exception())
        throw js_error(ctx.raw(), JS_GetException(ctx.raw()));

    Value v = ctx.eval(polyfill::runtime_api_js, "<runtime_api>");
    if (v.is_exception())
        throw js_error(ctx.raw(), JS_GetException(ctx.raw()));
}

} // namespace qjs
