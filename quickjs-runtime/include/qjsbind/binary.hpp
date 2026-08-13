// binary.hpp —— quickjs 原生 API 的 RAII 包装层（字符串 / 二进制）
//
// 动机：quickjs 原生 API 裸指针太多且生命周期全靠手管（JS_ToCStringLen 要
// 配 JS_FreeCString、JS_GetArrayBuffer 返回裸指针、detached buffer 会返回
// NULL 或越界）。本头把这些收口成安全、好用的 C++ 设施：
//
//   - qjs::js_string      ：JS 字符串 → std::string（UTF-8 值语义拷贝，嵌入
//                            '\0' 保留；失败 → nullopt，引擎异常已挂起）
//   - qjs::js_utf8        ：JS 字符串 → std::string（UTF-16 → UTF-8，TextEncoder
//                            语义：正确组合代理对，孤立代理 → U+FFFD）
//   - qjs::js_bytes       ：ArrayBuffer/TypedArray/DataView → vector<byte>（拷贝，
//                           带 detached/resize 守卫，其他类型 → TypeError）
//   - qjs::new_uint8_array：字节 → Uint8Array（JS_NewUint8ArrayCopy 包装，拷贝）
//   - qjs::new_array_buffer：字节 → ArrayBuffer（JS_NewArrayBufferCopy 包装，拷贝）
//
// 原则：一律值语义（std::string / vector / Value），无裸指针外露、无 ctx 生命周期
// 依赖；确实需要零拷贝借用且无法包装的场景才直接使用原生 API。
//
// 错误约定（与 convert.hpp 一致）：from 类操作失败抛 qjs::type_error；
// 引擎挂起异常则抛 qjs::js_error（消费掉，不残留污染后续 JS 操作）；
// 字符串提取失败（如 Symbol → TypeError）返回 nullopt 并保留引擎挂起异常，
// 由调用方决定是否消费。
#pragma once

#include <cstddef>
#include <cstring>
#include <optional>
#include <string>
#include <utility> // std::unreachable
#include <vector>

#include <quickjs.h>

#include <qjsbind/context.hpp>
#include <qjsbind/error.hpp>
#include <qjsbind/value.hpp>
#include <qjsbind/web/utf8.hpp> // utf16_to_utf8（TextEncoder 语义）

namespace qjs {

// ================= js_string：JS 字符串 → UTF-8 值语义提取 =================
// JS_ToCStringLen2 → std::string(s, len) 按长度拷贝（嵌入 '\0' 保留）→
// 立即 JS_FreeCString。失败（如 Symbol → TypeError，引擎异常已挂起）→ nullopt。
inline std::optional<std::string> js_string(JSContext* ctx, JSValueConst v)
{
    size_t len = 0;
    const char* s = JS_ToCStringLen2(ctx, &len, v, false);
    if (!s)
        return std::nullopt; // 异常已设置
    std::string out(s, len);
    JS_FreeCString(ctx, s);
    return out;
}

// ================= js_utf8：JS 字符串 → UTF-8（UTF-16 正确代理处理） =================
// JS_ToCStringLenUTF16 取 UTF-16 单元 → utf16_to_utf8 → 立即 JS_FreeCStringUTF16。
// 与 TextEncoder 规范一致（孤立代理 → U+FFFD）；失败 → nullopt（异常已挂起）。
inline std::optional<std::string> js_utf8(JSContext* ctx, JSValueConst v)
{
    size_t len = 0;
    const uint16_t* units = JS_ToCStringLenUTF16(ctx, &len, v);
    if (!units)
        return std::nullopt; // 异常已设置
    std::string out = qjsbind::web::utf16_to_utf8(units, len);
    JS_FreeCStringUTF16(ctx, units);
    return out;
}

// ================= is_binary：是否为二进制类型 =================
// ArrayBuffer / 任意 TypedArray（含 BigInt 变体）/ DataView → true。
inline bool is_binary(JSValueConst v)
{
    return JS_GetTypedArrayType(v) >= 0 || JS_IsArrayBuffer(v) || JS_IsDataView(v);
}

// ================= js_bytes：JS 二进制 → 字节拷贝 =================
// ArrayBuffer / 任意 TypedArray（含 BigInt 变体）/ DataView → 值拷贝；
// 其他类型 → TypeError。
// 安全：detached / 被 resize 缩小的 buffer 会让 JS_GetArrayBuffer 返回 NULL
// 或让视图范围越界——统一守卫，异常路径消费引擎挂起的异常（否则残留会
// 污染后续 JS 操作）。
inline std::vector<std::byte> js_bytes(JSContext* ctx, JSValueConst v)
{
    // data == nullptr 或范围越界 → 抛 js_error（消费挂起异常；没有则构造 InternalError）
    auto guard = [&](const uint8_t* data, size_t size, size_t offset, size_t len) {
        if (data && offset + len <= size)
            return;
        JSValue exc = JS_HasException(ctx)
            ? JS_GetException(ctx)
            : JS_NewInternalError(ctx, "qjs: invalid buffer (detached or resized)");
        throw js_error(ctx, exc);
    };
    if (!is_binary(v))
        throw_type_error(ctx, "qjs: expected ArrayBuffer / TypedArray / DataView");

    if (JS_GetTypedArrayType(v) >= 0) { // 任意 TypedArray（含 BigInt 变体）
        size_t byte_offset = 0, byte_length = 0, bytes_per_element = 0;
        Value buf(ctx, JS_GetTypedArrayBuffer(ctx, v, &byte_offset, &byte_length,
                                              &bytes_per_element)); // RAII 自动 free
        if (buf.is_exception())
            throw js_error(ctx, JS_GetException(ctx));
        size_t size = 0;
        uint8_t* data = JS_GetArrayBuffer(ctx, &size, buf.raw());
        guard(data, size, byte_offset, byte_length); // detached → data 为 NULL
        std::vector<std::byte> out(byte_length);
        std::memcpy(out.data(), data + byte_offset, byte_length);
        return out;
    }
    if (JS_IsArrayBuffer(v)) {
        size_t size = 0;
        uint8_t* data = JS_GetArrayBuffer(ctx, &size, v);
        guard(data, size, 0, size); // detached → data 为 NULL
        std::vector<std::byte> out(size);
        std::memcpy(out.data(), data, size);
        return out;
    }
    if (JS_IsDataView(v)) {
        // DataView：quickjs 无公开底层 API，经 buffer/byteOffset/byteLength 属性读取
        Value buf(ctx, JS_GetPropertyStr(ctx, v, "buffer"));
        Value off(ctx, JS_GetPropertyStr(ctx, v, "byteOffset"));
        Value len(ctx, JS_GetPropertyStr(ctx, v, "byteLength"));
        if (buf.is_exception())
            throw js_error(ctx, JS_GetException(ctx));
        size_t size = 0;
        uint8_t* data = JS_GetArrayBuffer(ctx, &size, buf.raw());
        const size_t offset = off.as<std::size_t>();
        const size_t length = len.as<std::size_t>();
        guard(data, size, offset, length);
        std::vector<std::byte> out(length);
        std::memcpy(out.data(), data + offset, length);
        return out;
    }
    // 开头 is_binary 已保证类型，各分支必有一个 return，此处不可达
    std::unreachable();
}

// ================= new_uint8_array：字节 → Uint8Array（拷贝） =================
// JS_NewUint8ArrayCopy 的包装：JS 侧拿到独立拥有的 Uint8Array，
// 之后源字节被修改/释放都不受影响。
inline Value new_uint8_array(JSContext* ctx, const std::byte* data, std::size_t len)
{
    return Value(ctx, JS_NewUint8ArrayCopy(
                          ctx, reinterpret_cast<const uint8_t*>(data), len));
}

// ================= new_array_buffer：字节 → ArrayBuffer（拷贝） =================
// JS_NewArrayBufferCopy 的包装：JS 侧独立拥有，之后源字节被修改/释放不受影响。
inline Value new_array_buffer(JSContext* ctx, const std::byte* data, std::size_t len)
{
    return Value(ctx, JS_NewArrayBufferCopy(
                          ctx, reinterpret_cast<const uint8_t*>(data), len));
}

// ================= Context 成员方法（声明见 context.hpp） =================
// 业务代码不再传裸 JSContext*：拿到 Context 后直接 ctx.js_string(v) 等。
// thunk 内部收到 quickjs 强制的 JSContext* 时，先包一层 Context 再用成员方法。
inline std::optional<std::string> Context::js_string(JSValueConst v) const
{
    return qjs::js_string(ctx_, v);
}
inline std::optional<std::string> Context::js_utf8(JSValueConst v) const
{
    return qjs::js_utf8(ctx_, v);
}
inline std::vector<std::byte> Context::js_bytes(JSValueConst v) const
{
    return qjs::js_bytes(ctx_, v);
}
inline Value Context::new_uint8_array(const std::byte* data, std::size_t len) const
{
    return qjs::new_uint8_array(ctx_, data, len);
}
inline Value Context::new_array_buffer(const std::byte* data, std::size_t len) const
{
    return qjs::new_array_buffer(ctx_, data, len);
}

// ================= Context::get_property / set_property / get_exception / global_object =================
// JS 值操作的 RAII 门面：业务代码不再手写 JS_GetPropertyStr + JS_FreeValue 配对。
inline Value Context::get_property(JSValueConst obj, std::string_view name) const
{
    return Value(ctx_, JS_GetPropertyStr(ctx_, obj, std::string(name).c_str()));
}
inline void Context::set_property(JSValueConst obj, std::string_view name, Value v) const
{
    JS_SetPropertyStr(ctx_, obj, std::string(name).c_str(), v.take()); // 转移所有权
}
inline Value Context::get_exception() const
{
    return Value(ctx_, JS_GetException(ctx_));
}
inline Value Context::global_object() const
{
    return Value(ctx_, JS_GetGlobalObject(ctx_));
}
inline Value Context::new_object() const
{
    return Value(ctx_, JS_NewObject(ctx_));
}
inline Value Context::new_array() const
{
    return Value(ctx_, JS_NewArray(ctx_));
}

} // namespace qjs
