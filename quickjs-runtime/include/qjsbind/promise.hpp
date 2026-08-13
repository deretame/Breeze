// promise.hpp —— 异步绑定：sender → JS Promise
//
// 设计文档 §5.3：promise_from_sender 把任意 sender 包装成 Promise，
// 链尾 continues_on(js_sched) 强制结算回 JS 线程，then/upon_error/upon_stopped
// 三路收尾（resolve / reject / reject AbortError），再经 Runtime::spawn 统一入口。
#pragma once

#include <cstddef>
#include <exception>
#include <memory>
#include <string>
#include <utility>

#include <quickjs.h>
#include <stdexec/execution.hpp>

#include <qjsbind/context.hpp>
#include <qjsbind/convert.hpp>
#include <qjsbind/error.hpp>

namespace qjs {

// ---- C++ 异常 → JS Error ----
inline JSValue exception_to_js(JSContext* ctx, std::exception_ptr e)
{
    try {
        std::rethrow_exception(e);
    } catch (const js_error& je) {
        // 透传原本的 JS 异常值：release_value 已把所有权交给调用方（调用方 free）。
        // 不能 JS_DupValue——会多一份引用，异常对象析构时已 released_ 不再 free，
        // 导致 JSValue 引用计数泄漏（Runtime 析构断言 gc_obj_list 非空）。
        return je.release_value();
    } catch (const std::exception& ex) {
        return JS_NewInternalError(ctx, "%s", ex.what());
    } catch (...) {
        return JS_NewInternalError(ctx, "unknown C++ exception");
    }
}

// ---- promise 结算 hooks：持有 resolve/reject 两个 JSValue（接管所有权）----
// JS_NewPromiseCapability 返回的 resolving 是"调用方负责 free"的新引用——
// 由 hooks 接管（不 dup），析构时 JS_FreeValue；外部不再 free。
class promise_hooks {
public:
    promise_hooks(JSContext* ctx, JSValue resolve, JSValue reject)
        : ctx_(ctx), resolve_(resolve), reject_(reject)
    {
    }
    ~promise_hooks()
    {
        JS_FreeValue(ctx_, resolve_);
        JS_FreeValue(ctx_, reject_);
    }
    promise_hooks(const promise_hooks&) = delete;
    promise_hooks& operator=(const promise_hooks&) = delete;

    // set_value → resolve（仅在 JS 线程调用：链尾 continues_on(js_sched) 之后）
    // 0 值 → undefined；1 值 → 值；多值 → Array
    template <class... Vs>
    void resolve(Vs&&... vs) const
    {
        JSValue val = pack(ctx_, std::forward<Vs>(vs)...);
        JS_Call(ctx_, resolve_, JS_UNDEFINED, 1, &val);
        if (!JS_IsUndefined(val))
            JS_FreeValue(ctx_, val);
    }

    // JSON 字符串 → JS_ParseJSON 后 resolve（dyn::call 等 JSON 桥用）；
    // 非法 JSON → reject SyntaxError（parse 异常直接透传）
    void resolve_json(const std::string& json) const
    {
        JSValue v = JS_ParseJSON(ctx_, json.c_str(), json.size(), "<promise_json>");
        if (JS_IsException(v)) {
            JSValue exc = JS_GetException(ctx_);
            JS_Call(ctx_, reject_, JS_UNDEFINED, 1, &exc);
            JS_FreeValue(ctx_, exc);
        } else {
            JS_Call(ctx_, resolve_, JS_UNDEFINED, 1, &v);
            JS_FreeValue(ctx_, v);
        }
    }

    // set_error → reject（C++ 异常 → JS Error）
    void reject(std::exception_ptr e) const
    {
        JSValue err = exception_to_js(ctx_, e);
        JS_Call(ctx_, reject_, JS_UNDEFINED, 1, &err);
        JS_FreeValue(ctx_, err);
    }

    // set_stopped → reject AbortError（取消语义，设计文档 §5.5）
    void reject_abort() const
    {
        JSValue err = JS_NewError(ctx_);
        JSValue name = JS_NewString(ctx_, "AbortError");
        JS_SetPropertyStr(ctx_, err, "name", name); // 转移所有权
        JS_Call(ctx_, reject_, JS_UNDEFINED, 1, &err);
        JS_FreeValue(ctx_, err);
    }

private:
    template <class T>
    static JSValue pack_one(JSContext* ctx, const T& v)
    {
        return js_convert<std::decay_t<T>>::to_js(ctx, v);
    }
    static JSValue pack(JSContext*) { return JS_UNDEFINED; }
    static void pack_rest(JSContext*, JSValue) {}
    template <class V, class... Vs>
    static void pack_rest(JSContext* ctx, JSValue arr, std::uint32_t i, V&& v, Vs&&... vs)
    {
        JS_SetPropertyUint32(ctx, arr, i, pack_one(ctx, v));
        pack_rest(ctx, arr, i + 1, std::forward<Vs>(vs)...);
    }
    template <class V, class... Vs>
    static JSValue pack(JSContext* ctx, V&& v, Vs&&... vs)
    {
        if constexpr (sizeof...(Vs) == 0) {
            return pack_one(ctx, v);
        } else {
            JSValue arr = JS_NewArray(ctx);
            JS_SetPropertyUint32(ctx, arr, 0, pack_one(ctx, v));
            pack_rest(ctx, arr, 1, std::forward<Vs>(vs)...);
            return arr;
        }
    }

    JSContext* ctx_;
    JSValue resolve_;
    JSValue reject_;
};

// ---- sender → Promise 底层骨架（设计文档 §5.3）----
// Hooks 约定：构造函数 (JSContext*, JSValue resolve, JSValue reject) 接管
// resolving 所有权；提供 resolve(vs...) / reject(exception_ptr) / reject_abort()
// 三个结算方法（仅在 JS 线程调用）。promise_hooks 是通用实现；需要特殊成功
// 路径（如 JSON parse）的调用方派生/自定义 Hooks 后用本模板，骨架不复制。
template <stdexec::sender S, class Hooks>
JSValue settle_from_sender(JSContext* ctx, S&& sndr)
{
    Runtime& rt = runtime_of(ctx);
    JSValue resolving[2];
    JSValue promise = JS_NewPromiseCapability(ctx, resolving);
    if (JS_IsException(promise))
        return promise; // 失败：resolving 未初始化，直接返回异常值

    auto hooks = std::make_shared<Hooks>(ctx, resolving[0], resolving[1]);

    // 链尾三路收尾（noexcept）：消化 value/error/stopped，之后 sender 不再 set_error
    auto chained = std::move(sndr)
        | stdexec::continues_on(rt.io_scheduler()) // ★ 结算点拉回 JS 线程
        | stdexec::then([hooks](auto&&... vs) noexcept {
              hooks->resolve(std::forward<decltype(vs)>(vs)...);
          })
        | stdexec::upon_error([hooks](std::exception_ptr e) noexcept {
              hooks->reject(e);
          })
        | stdexec::upon_stopped([hooks]() noexcept {
              hooks->reject_abort();
          });

    rt.spawn(std::move(chained));
    return promise; // 立即同步返回 pending promise
}

// ---- sender → Promise（设计文档 §5.3）----
template <stdexec::sender S>
JSValue promise_from_sender(JSContext* ctx, S&& sndr)
{
    return settle_from_sender<S, promise_hooks>(ctx, std::forward<S>(sndr));
}

} // namespace qjs
