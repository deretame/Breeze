// qjsbind::web —— setTimeout / setInterval / clearTimeout / clearInterval
//
// 实现：asio::steady_timer + 全局注册表。回调在 io 线程执行（= JS 线程，
// Runtime::run 单线程驱动 io_context）。Runtime 析构时 io_context 销毁，
// 未完成定时器随之取消，回调不会在 ctx 死后执行。
// 回调函数经 qjs::RtValue 持有（JSRuntime 释放，见 rt_value.hpp）。
#pragma once

#include <qjsbind/class.hpp>
#include <qjsbind/binary.hpp> // qjs::Context::js_string（值语义字符串提取）
#include <qjsbind/context.hpp>
#include <qjsbind/function.hpp>
#include <qjsbind/rt_value.hpp>

#include <log.hpp>

#include <boost/asio/steady_timer.hpp>

#include <atomic>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <memory>
#include <unordered_map>
#include <vector>

namespace qjsbind::web {

namespace timers_detail {

struct timer_entry {
    std::shared_ptr<boost::asio::steady_timer> timer;
    JSContext* ctx = nullptr;
    qjs::RtValue fn;                 // 回调函数
    std::vector<qjs::RtValue> args;  // 附加参数
    bool repeat = false;
};

inline std::unordered_map<uint64_t, std::shared_ptr<timer_entry>>& timer_map() {
    static std::unordered_map<uint64_t, std::shared_ptr<timer_entry>> m;
    return m;
}
inline std::atomic<uint64_t> next_id{1};

inline void invoke_callback(JSContext* ctx, const timer_entry& e) {
    qjs::Context cx(ctx);
    // 清理引擎可能挂起的异常（不应有，防御性）：RAII 持有，析构即释放
    if (JS_HasException(ctx))
        cx.get_exception();
    std::vector<qjs::Value> argv; // RAII：dup 的引用随容器析构释放
    argv.reserve(e.args.size());
    for (const auto& a : e.args)
        argv.emplace_back(ctx, a.dup(ctx));
    std::vector<JSValue> raw;
    raw.reserve(argv.size());
    for (const auto& a : argv)
        raw.push_back(a.raw());
    qjs::Value r(ctx, JS_Call(ctx, e.fn.raw(), JS_UNDEFINED,
                              static_cast<int>(raw.size()), raw.data()));
    if (r.is_exception()) {
        qjs::Value exc = cx.get_exception();
        // Context 成员：js_string（值语义提取，内部 FreeCString）；失败 → "?"
        std::string str = cx.js_string(exc.raw()).value_or("?");
        QLOG_ERROR("[qjsbind::web] timer callback threw: {}", str);
    }
}

inline void run_timer(uint64_t id, std::shared_ptr<timer_entry> e) {
    if (e->repeat) {
        e->timer->async_wait([id, e](const boost::system::error_code& ec) {
            if (!ec)
                run_timer(id, e); // 先安排下一次，再回调（回调异常不影响周期）
        });
        invoke_callback(e->ctx, *e);
    } else {
        timer_map().erase(id); // 一次性：先摘除再回调（回调里 clearTimeout(id) 无副作用）
        invoke_callback(e->ctx, *e);
    }
}

inline uint64_t schedule(JSContext* ctx, qjs::Function fn, double ms,
                         std::vector<qjs::RtValue> args, bool repeat) {
    const uint64_t id = next_id.fetch_add(1);
    auto e = std::make_shared<timer_entry>();
    e->ctx = ctx;
    e->fn = qjs::RtValue(JS_GetRuntime(ctx), fn.take());
    e->args = std::move(args);
    e->repeat = repeat;
    e->timer = std::make_shared<boost::asio::steady_timer>(
        qjs::current_io(),
        std::chrono::milliseconds(ms > 0 ? static_cast<long long>(ms) : 0));
    timer_map()[id] = e;
    e->timer->async_wait([id, e](const boost::system::error_code& ec) {
        if (!ec)
            run_timer(id, e);
    });
    return id;
}

inline void clear(uint64_t id) {
    auto it = timer_map().find(id);
    if (it != timer_map().end()) {
        it->second->timer->cancel(); // 新版 asio：cancel() 无 error_code 重载
        timer_map().erase(it);
    }
}

} // namespace timers_detail

inline void install_timers(qjs::Context& ctx) {
    using namespace timers_detail;
    ctx.globals().set("setTimeout",
                      qjs::func(ctx.raw(),
                                [](qjs::Ctx c, qjs::Function fn, double ms,
                                   qjs::Rest<qjs::Value> args) -> double {
                                    std::vector<qjs::RtValue> rt_args;
                                    for (auto& a : args.items)
                                        rt_args.emplace_back(JS_GetRuntime(c.ctx), a.take());
                                    return static_cast<double>(
                                        schedule(c.ctx, std::move(fn), ms, std::move(rt_args),
                                                 false));
                                },
                                "setTimeout"));
    ctx.globals().set("setInterval",
                      qjs::func(ctx.raw(),
                                [](qjs::Ctx c, qjs::Function fn, double ms,
                                   qjs::Rest<qjs::Value> args) -> double {
                                    std::vector<qjs::RtValue> rt_args;
                                    for (auto& a : args.items)
                                        rt_args.emplace_back(JS_GetRuntime(c.ctx), a.take());
                                    return static_cast<double>(
                                        schedule(c.ctx, std::move(fn), ms, std::move(rt_args),
                                                 true));
                                },
                                "setInterval"));
    // id 以 JS number 传递（对齐浏览器；BigInt 会让 clearTimeout(setTimeout(...))
    // 在 JS_ToInt64 处抛 "expected uint64"）
    ctx.globals().set("clearTimeout",
                      qjs::func(ctx.raw(),
                                [](double id) {
                                    timers_detail::clear(static_cast<uint64_t>(id));
                                },
                                "clearTimeout"));
    ctx.globals().set("clearInterval",
                      qjs::func(ctx.raw(),
                                [](double id) {
                                    timers_detail::clear(static_cast<uint64_t>(id));
                                },
                                "clearInterval"));
}

} // namespace qjsbind::web
