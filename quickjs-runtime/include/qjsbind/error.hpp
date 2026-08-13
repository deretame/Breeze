// error.hpp —— qjsbind 异常类型
//
// 铁律（设计文档 §4.3）：C++ 异常绝不允许穿过 QuickJS 的 C 帧，
// thunk 边界必须全捕获并转成 JS 异常。
#pragma once

#include <exception>
#include <stdexcept>
#include <string>

#include <quickjs.h>

namespace qjs {

// 携带 JS 异常值（JSValue，接管所有权）的 C++ 异常。
// thunk 边界 catch 后经 release_value() 把 JSValue 交给 JS_Throw。
class js_error : public std::exception {
public:
    js_error(JSContext* ctx, JSValue v) : ctx_(ctx), v_(v) {}
    ~js_error() override
    {
        if (!released_ && ctx_)
            JS_FreeValue(ctx_, v_);
    }
    js_error(const js_error& o) : ctx_(o.ctx_), v_(o.ctx_ ? JS_DupValue(o.ctx_, o.v_) : JS_UNDEFINED)
    {
    }
    js_error& operator=(const js_error&) = delete;
    js_error(js_error&& o) noexcept : ctx_(o.ctx_), v_(o.v_), released_(o.released_)
    {
        o.released_ = true;
    }

    const char* what() const noexcept override { return "qjs::js_error (JS exception)"; }

    JSContext* ctx() const noexcept { return ctx_; }
    // 转移 JSValue 所有权给调用方（调用方负责 free），此后析构不再 free
    JSValue release_value() const noexcept
    {
        released_ = true;
        return v_;
    }

private:
    JSContext* ctx_;
    JSValue v_;
    mutable bool released_ = false;
};

// 类型转换失败：thunk 边界转 JS TypeError
class type_error : public std::runtime_error {
public:
    using std::runtime_error::runtime_error;
};

// 转换失败公共入口：先清掉引擎可能已挂起的异常，再抛 type_error
[[noreturn]] inline void throw_type_error(JSContext* ctx, const std::string& msg)
{
    if (JS_HasException(ctx)) {
        JSValue exc = JS_GetException(ctx);
        JS_FreeValue(ctx, exc);
    }
    throw type_error(msg);
}

} // namespace qjs
