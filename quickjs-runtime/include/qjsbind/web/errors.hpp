// qjsbind::web —— 统一异常抛出辅助
//
// 为什么不用 JS_NewTypeError / JS_ThrowTypeError：
//   - quickjs-ng 各版本对它们的实现/导出不一致（v0.15.1 由宏展开实现，
//     v0.16.1 头文件声明了但 quickjs.c 无定义），语义不可控；
//   - 历史代码里 `JS_Throw(...); throw qjs::js_error(...)` 两行组合在批量替换
//     时被改坏（throw 脱离 if 控制流 → 无条件抛出包装 JS_UNINITIALIZED 的伪异常）。
// 本函数是唯一出口：JS_NewError + 设置 name/message 属性 + JS_Throw，
// 完全可控，且每个调用点都是独立的一条语句，不会再被 if 控制流拆散。
//
// 参数约定：直接收 std::string 消息，不做 printf 格式化——拼接由调用方决定
// （项目已有 fmt 库，需要格式化时用 fmt::format 拼好再传）。
#pragma once

#include <qjsbind/context.hpp>
#include <qjsbind/convert.hpp> // Context::to_js

#include <string>

namespace qjsbind::web {

// 抛出 name="TypeError" 的错误（永不返回）
[[noreturn]] inline void throw_type_error(JSContext* ctx, const std::string& msg) {
    qjs::Context cx(ctx);
    JSValue err = JS_UNDEFINED;
    // 用全局 TypeError 构造器创建实例：保证 instanceof TypeError 与原型链正确
    // （JS_NewError 只是普通 Error，e.name 对但 instanceof 不对）。
    // g/ctor/m 均为 RAII Value，析构自动释放。
    qjs::Value g = cx.global_object();
    qjs::Value ctor = cx.get_property(g.raw(), "TypeError");
    if (!ctor.is_exception()) {
        qjs::Value m = cx.to_js(msg);
        JSValue m_raw = m.raw(); // 借用，m 生命周期覆盖调用
        err = JS_CallConstructor(ctx, ctor.raw(), 1, &m_raw);
    }
    if (JS_IsException(err) || JS_IsUndefined(err)) {
        // OOM 或异常回退：普通 Error + name/message 属性
        if (!JS_IsUndefined(err))
            JS_FreeValue(ctx, err);
        err = JS_NewError(ctx);
        if (!JS_IsException(err)) {
            cx.set_property(err, "name", cx.to_js(std::string("TypeError")));
            cx.set_property(err, "message", cx.to_js(msg));
        }
    }
    JS_Throw(ctx, err); // 覆盖 current_exception（即使构造期间有残留）
    throw qjs::js_error(ctx, JS_GetException(ctx));
}

// 同上，但 name="RangeError"（Response 状态码等场景，wpt 要求 instanceof RangeError）
[[noreturn]] inline void throw_range_error(JSContext* ctx, const std::string& msg) {
    qjs::Context cx(ctx);
    JSValue err = JS_UNDEFINED;
    qjs::Value g = cx.global_object();
    qjs::Value ctor = cx.get_property(g.raw(), "RangeError");
    if (!ctor.is_exception()) {
        qjs::Value m = cx.to_js(msg);
        JSValue m_raw = m.raw(); // 借用，m 生命周期覆盖调用
        err = JS_CallConstructor(ctx, ctor.raw(), 1, &m_raw);
    }
    if (JS_IsException(err) || JS_IsUndefined(err)) {
        if (!JS_IsUndefined(err))
            JS_FreeValue(ctx, err);
        err = JS_NewError(ctx);
        if (!JS_IsException(err)) {
            cx.set_property(err, "name", cx.to_js(std::string("RangeError")));
            cx.set_property(err, "message", cx.to_js(msg));
        }
    }
    JS_Throw(ctx, err);
    throw qjs::js_error(ctx, JS_GetException(ctx));
}

} // namespace qjsbind::web
