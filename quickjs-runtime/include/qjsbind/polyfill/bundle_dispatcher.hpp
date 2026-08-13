// bundle_dispatcher.hpp —— bundle 分发器 polyfill 安装入口
//
// 1. 注册 native base64 编码函数 __native_b64encode（BoringSSL EVP_EncodeBlock，
//    经 fetch::base64_encode；JS 侧不再自带 base64 实现）；
// 2. 把 polyfill/bundle_dispatcher.js（经 scripts/embed_js.py 嵌入为字符串）eval 进
//    context，提供 __bundle_set_exports / 覆盖 __invoke（见 JS 文件头注释）。
//
// 前置：TaskRunner 已构造（其默认 __invoke 会被本 polyfill 覆盖）。
// 由 qjs::HostRuntime 在实例初始化与 reload 时自动安装，宿主一般无需直接调用。
#pragma once

#include <quickjs.h>

#include <fetch/types.hpp> // fetch::base64_encode（BoringSSL EVP）
#include <qjsbind/binary.hpp>  // qjs::js_bytes（ArrayBuffer/TypedArray/DataView → 字节拷贝）
#include <qjsbind/blob_store.hpp> // dyn::BlobStore（native buffer 池）
#include <qjsbind/context.hpp>
#include <qjsbind/error.hpp>
#include <qjsbind/function.hpp> // qjs::func 自动绑定（Object::set 可调用重载）
#include <qjsbind/value.hpp>

#include <qjsbind/polyfill/bundle_dispatcher_embedded.hpp> // 生成物（configure 期生成，不入库）
#include <qjsbind/polyfill/source_map_lib_embedded.hpp>    // 生成物（同上；trace-mapping 打包产物）

#include <optional>
#include <string>
#include <string_view>

namespace qjs {

namespace detail {

// 提取挂起异常文本（Node 风格：消息行 + 栈；quickjs 的 stack 不含消息行，需拼接）
inline std::string bundle_exception_text(JSContext* ctx)
{
    JSValue exc = JS_GetException(ctx);
    std::string msg = Context(ctx).js_string(exc).value_or("(unknown error)");
    std::string stack;
    if (JS_IsObject(exc)) {
        JSValue sv = JS_GetPropertyStr(ctx, exc, "stack");
        if (JS_IsString(sv))
            stack = Context(ctx).js_string(sv).value_or("");
        JS_FreeValue(ctx, sv);
    }
    JS_FreeValue(ctx, exc);
    if (stack.empty() || stack.starts_with(msg))
        return stack.empty() ? msg : stack;
    return msg + "\n" + stack;
}

// 提取行内 source map： bundle 源码尾部的
//   //# sourceMappingURL=data:application/json;base64,<...>
// 解出 map JSON 文本（仅支持 base64 行内形式；无/非法 → nullopt）
inline std::optional<std::string> extract_inline_source_map(std::string_view source)
{
    constexpr std::string_view kMarker = "//# sourceMappingURL=data:";
    const auto pos = source.rfind(kMarker);
    if (pos == std::string_view::npos)
        return std::nullopt;
    auto rest = source.substr(pos + kMarker.size());
    if (const auto nl = rest.find('\n'); nl != std::string_view::npos)
        rest = rest.substr(0, nl);
    while (!rest.empty() && (rest.back() == '\r' || rest.back() == ' ' || rest.back() == '\t'))
        rest.remove_suffix(1);
    const auto comma = rest.find(',');
    if (comma == std::string_view::npos)
        return std::nullopt;
    if (rest.substr(0, comma).find(";base64") == std::string_view::npos)
        return std::nullopt; // 非 base64 行内形式不支持
    return fetch::base64_decode(std::string(rest.substr(comma + 1)));
}

} // namespace detail

struct bundle_load_error {
    bool compile_phase = false; // true = 编译验证失败；false = 求值/登记失败
    std::string message;
};

// 共用 bundle 加载（HostRuntime / TaskPool 同一路径）：
// CJS 包装（(function(module, exports){ ... })，filename = <name>.bundle.cjs，
// 错误栈可定位）→ 编译验证 → 求值 → factory(module, exports) →
// __bundle_set_exports(name, exports, mapJson) 登记（含 default unwrap /
// 导出类型检查 / source map 接入，见 dispatcher JS）。
// 前置：所在 context 已 install_bundle_dispatcher。
inline std::optional<bundle_load_error> load_bundle_source(qjs::Context ctx,
                                                           const std::string& source,
                                                           const std::string& name)
{
    JSContext* raw = ctx.raw();
    if (JS_HasException(raw)) { // 清上个任务可能挂起的异常
        JSValue e = JS_GetException(raw);
        JS_FreeValue(raw, e);
    }
    // 1. CJS 包装 + 编译验证（filename 即 bundle 名，错误栈可定位到插件源码）
    const std::string filename = name + ".bundle.cjs";
    const std::string wrapped = "(function(module, exports) {\n" + source + "\n})";
    JSValue compiled = JS_Eval(raw, wrapped.data(), wrapped.size(), filename.c_str(),
                               JS_EVAL_TYPE_GLOBAL | JS_EVAL_FLAG_COMPILE_ONLY);
    if (JS_IsException(compiled))
        return bundle_load_error{true, "bundle compile failed: " +
                                           detail::bundle_exception_text(raw)};
    JS_FreeValue(raw, compiled);

    // 2. 求值得工厂函数（语法已过验证，此处异常属求值期错误）
    JSValue factory = JS_Eval(raw, wrapped.data(), wrapped.size(), filename.c_str(),
                              JS_EVAL_TYPE_GLOBAL);
    if (JS_IsException(factory))
        return bundle_load_error{false, "bundle factory eval failed: " +
                                            detail::bundle_exception_text(raw)};

    // 3. CJS 语义：factory(module, exports)，导出表取 module.exports
    JSValue module_obj = JS_NewObject(raw);
    JSValue exports_obj = JS_NewObject(raw);
    JS_SetPropertyStr(raw, module_obj, "exports", JS_DupValue(raw, exports_obj));
    JSValue argv[2] = {module_obj, exports_obj};
    JSValue r = JS_Call(raw, factory, JS_UNDEFINED, 2, argv);
    const bool call_exc = JS_IsException(r);
    JS_FreeValue(raw, r);
    JS_FreeValue(raw, factory);
    if (call_exc) {
        JS_FreeValue(raw, module_obj);
        JS_FreeValue(raw, exports_obj);
        return bundle_load_error{false, "bundle load failed: " +
                                            detail::bundle_exception_text(raw)};
    }
    JSValue final_exports = JS_GetPropertyStr(raw, module_obj, "exports");
    JS_FreeValue(raw, module_obj);
    JS_FreeValue(raw, exports_obj);

    // 4. 登记导出表（dispatcher 侧保存，__invoke 按 fn_path 在其上解析）；
    //    行内 source map（有则）一并传入，错误栈自动 remap
    std::optional<std::string> map_json = detail::extract_inline_source_map(source);
    JSValue global = JS_GetGlobalObject(raw);
    JSValue set_exports = JS_GetPropertyStr(raw, global, "__bundle_set_exports");
    if (!JS_IsFunction(raw, set_exports)) {
        JS_FreeValue(raw, set_exports);
        JS_FreeValue(raw, global);
        JS_FreeValue(raw, final_exports);
        return bundle_load_error{false, "__bundle_set_exports is missing "
                                        "(bundle dispatcher not installed)"};
    }
    JSValue sargv[3] = {JS_NewStringLen(raw, name.data(), name.size()), final_exports,
                        map_json ? JS_NewStringLen(raw, map_json->data(), map_json->size())
                                 : JS_UNDEFINED};
    JSValue sr = JS_Call(raw, set_exports, JS_UNDEFINED, 3, sargv);
    const bool set_exc = JS_IsException(sr);
    JS_FreeValue(raw, sr);
    JS_FreeValue(raw, set_exports);
    JS_FreeValue(raw, global);
    for (auto& a : sargv)
        JS_FreeValue(raw, a);
    if (set_exc)
        return bundle_load_error{false, "bundle exports registration failed: " +
                                            detail::bundle_exception_text(raw)};
    return std::nullopt;
}

// buf_bucket：本实例在 BlobStore 的桶 id（HostRuntime 用 "hbuf:<instance>"；
// 刻意不用 Runtime id——reload 先建后拆时旧 Runtime 的析构钩子会整桶回收，
// 独立桶名使 buffer 跨 reload 存活；stop 时由 HostRuntime 回收）
inline void install_bundle_dispatcher(qjs::Context& ctx, const std::string& buf_bucket)
{
    // __native_b64encode(bytes)：base64 编码走 native（BoringSSL EVP_EncodeBlock，
    // 经 fetch::base64_encode）；JS 侧不再自带 base64 实现。入参非二进制时
    // js_bytes 抛 type_error，自动绑定层转成 JS TypeError。
    Object global = ctx.globals();
    global.set("__native_b64encode", [](Ctx cx, Value v) -> std::string {
        const std::vector<std::byte> bytes = qjs::js_bytes(cx.ctx, v.raw());
        return fetch::base64_encode(
            std::string(reinterpret_cast<const char*>(bytes.data()), bytes.size()));
    });

    // native buffer 通道（设计文档 §3）：host→JS 的 take（消费语义，miss → null）
    // 与 JS→host 的 put（返回桶内 id）
    global.set("__native_buf_take", [buf_bucket](Ctx cx, Value v) -> Value {
        qjs::Context c(cx.ctx);
        if (!v.is_string())
            throw_type_error(cx.ctx, "__native_buf_take: id 必须是字符串");
        const std::string id = c.from_js<std::string>(v.raw());
        auto& store = dyn::BlobStore::instance();
        std::optional<std::vector<std::byte>> data = store.get(buf_bucket, id);
        if (!data)
            return Value(cx.ctx, JS_NULL);
        store.remove(buf_bucket, id); // 消费：get 命中即删
        return c.new_uint8_array(data->data(), data->size());
    });
    global.set("__native_buf_put", [buf_bucket](Ctx cx, Value v) -> Value {
        qjs::Context c(cx.ctx);
        std::vector<std::byte> bytes = c.js_bytes(v.raw());
        return c.to_js(dyn::BlobStore::instance().put(buf_bucket, std::move(bytes)));
    });

    // source map 库（@jridgewell/trace-mapping 的 IIFE 打包，暴露 __sourcemap_lib）
    Value lib = ctx.eval(polyfill::source_map_lib_js, "<source_map_lib>");
    if (lib.is_exception())
        throw js_error(ctx.raw(), JS_GetException(ctx.raw()));

    Value v = ctx.eval(polyfill::bundle_dispatcher_js, "<bundle_dispatcher>");
    if (v.is_exception())
        throw js_error(ctx.raw(), JS_GetException(ctx.raw()));
}

} // namespace qjs
