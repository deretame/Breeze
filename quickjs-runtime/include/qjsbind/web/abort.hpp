// qjsbind::web —— AbortController / AbortSignal
//
// 取消链路：AbortSignalImpl 持有 std::stop_source；
//   abort() → stop.request_stop() → 网络层 stop_callback → socket.cancel()
//   → asio operation_aborted → use_sender set_stopped → Promise reject AbortError。
// 生命周期：AbortSignalImpl 由 signal JS 对象 opaque 持有；AbortControllerImpl
//   缓存 signal 的 JSValue（RtValue，JSRuntime 释放——见 rt_value.hpp）。
#pragma once

#include <qjsbind/class.hpp>
#include <qjsbind/context.hpp>
#include <qjsbind/rt_value.hpp>
#include <qjsbind/web/dom_exception.hpp>
#include <qjsbind/web/events.hpp>
#include <qjsbind/web/timers.hpp> // AbortSignal.timeout 定时器（timers_detail::schedule）

#include <stop_token>

namespace qjsbind::web {

// 创建 DOMException(message, name) 实例（AbortError 等）
inline qjs::Value make_dom_exception(JSContext* ctx, const char* message, const char* name) {
    JSClassID id = qjs::registry_of(ctx).id_of<DomException>(ctx);
    JSValue proto = JS_GetClassProto(ctx, id);
    JSValue obj = JS_NewObjectProtoClass(ctx, proto, id);
    JS_FreeValue(ctx, proto);
    if (JS_IsException(obj))
        throw qjs::js_error(ctx, JS_GetException(ctx));
    JS_SetOpaque(obj, new DomException(message, name));
    return qjs::Value(ctx, obj);
}

inline qjs::Value make_abort_error(JSContext* ctx) {
    return make_dom_exception(ctx, "The operation was aborted", "AbortError");
}

struct AbortSignalImpl : EventTargetImpl {
    std::stop_source stop; // 桥接 C++ 网络层取消
    bool aborted = false;
    int reason_kind = 0;   // 0=AbortError，1=TimeoutError（AbortSignal.timeout 用）

    void abort(JSContext* ctx) {
        if (aborted)
            return;
        aborted = true;
        stop.request_stop();
        dispatch_type(ctx, "abort");
    }

    void throw_if_aborted(JSContext* ctx) const {
        if (aborted)
            throw qjs::js_error(ctx, make_abort_error(ctx).take());
    }
};

// 创建 signal JS 对象（opaque = 传入的 impl，所有权转移给 JS）
inline qjs::Value make_signal_object(JSContext* ctx, AbortSignalImpl* impl) {
    JSClassID id = qjs::registry_of(ctx).id_of<AbortSignalImpl>(ctx);
    JSValue proto = JS_GetClassProto(ctx, id);
    JSValue obj = JS_NewObjectProtoClass(ctx, proto, id);
    JS_FreeValue(ctx, proto);
    if (JS_IsException(obj))
        throw qjs::js_error(ctx, JS_GetException(ctx));
    JS_SetOpaque(obj, impl);
    return qjs::Value(ctx, obj);
}

struct AbortControllerImpl {
    AbortSignalImpl* signal = nullptr; // 借用（由 signal JS 对象 opaque 持有）
    qjs::RtValue signal_js;            // 缓存（首次访问创建；RtValue 释放安全）

    void qjs_init(JSContext* ctx) {
        signal = new AbortSignalImpl();
        signal_js = qjs::RtValue(JS_GetRuntime(ctx), make_signal_object(ctx, signal).take());
    }

    // GC 标记：缓存 signal 对象
    void qjs_mark(JSRuntime* rt, JS_MarkFunc* mark_func) { signal_js.mark(rt, mark_func); }
};

inline void install_abort(qjs::Context& ctx) {
    // ---- AbortSignal ----
    auto sig = qjs::class_<AbortSignalImpl>(ctx, "AbortSignal").constructor<>();
    install_event_target_methods<decltype(sig), AbortSignalImpl>(sig);
    sig.getter("aborted", [](qjs::This<AbortSignalImpl> self) { return self->aborted; })
        .getter("reason", [](qjs::Ctx ctx, qjs::This<AbortSignalImpl> self) -> qjs::Value {
            // v1：abort 后按来源返回 TimeoutError/AbortError DOMException；否则 undefined
            if (!self->aborted)
                return qjs::Value(ctx.ctx, JS_UNDEFINED);
            return self->reason_kind == 1
                       ? make_dom_exception(ctx.ctx, "signal timed out", "TimeoutError")
                       : make_abort_error(ctx.ctx);
        })
        .method("throwIfAborted", [](qjs::Ctx ctx, qjs::This<AbortSignalImpl> self) {
            self->throw_if_aborted(ctx.ctx);
        })
        .static_method("abort", [](qjs::Ctx ctx) -> qjs::Value {
            auto* impl = new AbortSignalImpl();
            impl->aborted = true;
            impl->stop.request_stop();
            return make_signal_object(ctx.ctx, impl);
        })
        .static_method("timeout", [](qjs::Ctx ctx, double ms) -> qjs::Value {
            // 规范：ms 毫秒后 abort（reason = TimeoutError DOMException）。
            // 定时器走 timers 注册表（挂在 io_ 上）：fetch 等异步在飞时由
            // run_one 自然驱动触发；独立 timeout 不保持 run_to_completion
            // （与 Node 一致：`node -e "AbortSignal.timeout(1e5)"` 立即退出）；
            // shutdown 清理注册表 → 无残留。
            auto* impl = new AbortSignalImpl();
            impl->reason_kind = 1;
            qjs::Value obj = make_signal_object(ctx.ctx, impl);
            auto cb = [](qjs::Ctx c, qjs::Value sig) {
                auto* s = qjs::registry_of(c.ctx).opaque<AbortSignalImpl>(c.ctx, sig.raw());
                if (s && !s->aborted)
                    s->abort(c.ctx);
            };
            std::vector<qjs::RtValue> args;
            args.emplace_back(JS_GetRuntime(ctx.ctx), JS_DupValue(ctx.ctx, obj.raw()));
            timers_detail::schedule(ctx.ctx, qjs::func(ctx.ctx, cb), ms, std::move(args), false);
            return obj;
        });
    ctx.globals().set("AbortSignal", sig.constructor_function());
    // AbortSignal.any：任一输入 signal abort → 输出 abort（v1：reason 不传播，
    // 恒 AbortError；输入已 abort → 立即 abort）
    ctx.eval(
        "AbortSignal.any = function (signals) {"
        "  var list = Array.from(signals);"
        "  var ctl = new AbortController();"
        "  if (list.some(function (s) { return s.aborted; })) {"
        "    ctl.abort(); return ctl.signal;"
        "  }"
        "  list.forEach(function (s) {"
        "    s.addEventListener('abort', function () { ctl.abort(); });"
        "  });"
        "  return ctl.signal;"
        "};");

    // ---- AbortController ----
    auto ctl = qjs::class_<AbortControllerImpl>(ctx, "AbortController")
                   .constructor<>()
                   .getter("signal", [](qjs::Ctx ctx, qjs::This<AbortControllerImpl> self) -> qjs::Value {
                       // 首次访问已由 qjs_init 创建；返回 dup
                       return qjs::Value(ctx.ctx, self->signal_js.dup(ctx.ctx));
                   })
                   .method("abort", [](qjs::Ctx ctx, qjs::This<AbortControllerImpl> self) {
                       self->signal->abort(ctx.ctx);
                   });
    ctx.globals().set("AbortController", ctl.constructor_function());
}

} // namespace qjsbind::web
