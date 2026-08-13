// rt_value.hpp —— 用 JSRuntime 释放的 JSValue 持有者
//
// 背景（QuickJS 约束）：JSClassFinalizer 只有 JSRuntime* 没有 JSContext*；
// JS_FreeContext 不先跑 GC，opaque 的析构发生在 JS_FreeRuntime 的最终 GC
//（此时 ctx 内存已释放）。因此 class 的 opaque 内不能存依赖 ctx 的 qjs::Value
//（其析构调 JS_FreeValue(ctx, ...) 会悬垂访问 ctx）。
//
// RtValue 存 JSRuntime* + JSValue，析构用 JS_FreeValueRT（仅访问 rt，finalizer
// 期间 rt 存活）——opaque 成员安全。需要 ctx 的场景（如 dispatch 时调用函数）
// 用 to_value(ctx) 临时 dup 包装。
#pragma once

#include <quickjs.h>

#include <utility>

namespace qjs {

class RtValue {
public:
    RtValue() = default;
    RtValue(JSRuntime* rt, JSValue v) noexcept : rt_(rt), v_(v) {}
    RtValue(RtValue&& o) noexcept : rt_(o.rt_), v_(o.v_) { o.v_ = JS_UNDEFINED; }
    RtValue& operator=(RtValue&& o) noexcept
    {
        if (this != &o) {
            release();
            rt_ = o.rt_;
            v_ = o.v_;
            o.v_ = JS_UNDEFINED;
        }
        return *this;
    }
    RtValue(const RtValue&) = delete;
    RtValue& operator=(const RtValue&) = delete;
    ~RtValue() { release(); }

    void release() noexcept
    {
        if (!JS_IsUndefined(v_)) {
            JS_FreeValueRT(rt_, v_);
            v_ = JS_UNDEFINED;
        }
    }

    // 转移所有权（调用方负责释放）
    JSValue take() noexcept
    {
        JSValue v = v_;
        v_ = JS_UNDEFINED;
        return v;
    }

    JSValue raw() const noexcept { return v_; }
    bool empty() const noexcept { return JS_IsUndefined(v_); }
    explicit operator bool() const noexcept { return !empty(); }

    // 临时包装成 qjs::Value（dup，调用方负责释放返回的 Value）
    JSValue dup(JSContext* ctx) const { return JS_DupValue(ctx, v_); }

    // GC 标记：opaque 内的 JSValue 引用须经 JS_MarkValue 标记，否则被误回收
    void mark(JSRuntime* rt, JS_MarkFunc* mf) const
    {
        if (!empty())
            JS_MarkValue(rt, v_, mf);
    }

private:
    JSRuntime* rt_ = nullptr;
    JSValue v_ = JS_UNDEFINED;
};

} // namespace qjs
