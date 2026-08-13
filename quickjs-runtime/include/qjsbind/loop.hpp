// loop.hpp —— 事件循环：Runtime::spawn / run / stop / shutdown / pump_js_jobs
//
// 设计文档 §8：
//   - 退出判据 = pending_ 计数（Runtime::spawn +1、三路收尾 -1），不用 on_empty
//   - 检查总在 pump_js_jobs() 之后（pump 排干结算 job 才可能 spawn 新任务）
//   - stop() 任意线程可调（asio::post 置 done_），shutdown 单向（request_stop 不可逆）
#pragma once

#include <atomic>
#include <cstdio>

#include <quickjs.h>
#include <stdexec/execution.hpp>

#include <log.hpp>
#include <qjsbind/binary.hpp> // qjs::js_string（值语义字符串提取）
#include <qjsbind/context.hpp>
#include <qjsbind/error.hpp>
#include <qjsbind/web/timers.hpp> // shutdown 清理挂起定时器注册表

namespace qjs {

// ---- 统一 spawn 入口（设计文档 §8.1 不变量 1）----
// 三路收尾消化 error/stopped（noexcept，否则 stdexec::spawn 会 static_assert），
// 并维护 pending_ 计数；env 注入 get_start_scheduler（stdexec::task 要求）。
//
// scope 生命周期语义（stdexec::counting_scope，__counting_scopes.hpp）：
//   - request_stop() 只是 stop_source_.request_stop()，不会让后续 spawn 失败：
//     token 把 sender 包装成 __stop_when(sndr, stop_token)——scope 已停止时新
//     spawn 仍正常 start 并立即以 stopped 结算，上面 upon_stopped → complete()
//     照常执行，pending_ 不泄漏。因此 shutdown 期间（request_stop 后、JS 线程
//     仍在驱动时）JS job 里再发异步调用（promise_from_sender / dyn::call）是
//     安全的：新 Promise 会以 AbortError 结算，不会永久挂起。
//   - try_associate() 失败（stdexec::spawn 丢弃 sender、complete() 不执行）
//     只发生在 scope close() 之后（join 时）或关联数满。本项目时序下不可达：
//     shutdown() 先 request_stop 并驱动 pending_ 到 0（JS 线程活跃，关联恒成功），
//     最后才 finish_scope()（join → close）；单 JS 线程模型下不存在 join 进行中
//     另一线程并发 spawn 的路径。
template <stdexec::sender S>
void Runtime::spawn(S&& sndr)
{
    pending_.fetch_add(1, std::memory_order_relaxed);
    stdexec::spawn(
        std::forward<S>(sndr)
            | stdexec::then([this](auto&&...) noexcept { complete(); })
            | stdexec::upon_error([this](auto&&) noexcept { complete(); })
            | stdexec::upon_stopped([this]() noexcept { complete(); }),
        scope_->get_token(),
        stdexec::prop{stdexec::get_start_scheduler, io_scheduler()});
}

// ---- JS job 泵：一次排干（与浏览器微任务语义一致）----
inline void Runtime::pump_js_jobs()
{
    JSContext* c;
    int r;
    while ((r = JS_ExecutePendingJob(rt_, &c)) == 1) {
    }
    if (r < 0) {
        // job 执行抛了未捕获异常：取走并打印（类似 js_std_dump_error）
        JSValue exc = JS_GetException(c ? c : ctx_);
        // Context 成员：js_string（值语义提取，内部 FreeCString）；失败 → "(null)"
        std::string msg = Context(c ? c : ctx_).js_string(exc).value_or("(null)");
        QLOG_ERROR("[qjs] unhandled job exception: {}", msg);
        JS_FreeValue(c ? c : ctx_, exc);
    }
}

inline void Runtime::loop_body()
{
    pump_js_jobs();
    io_.run_one(); // 无 ready handler 时阻塞等未来工作（guard_ 保活）
}

// ---- 模式 A：服务模式（默认主模式，设计文档 §8.2）----
inline void Runtime::run()
{
    // 绑定当前 JS 线程（TLS）：协程异步函数经 current_io() 拿事件循环
    Runtime* prev = tls_current_runtime;
    tls_current_runtime = this;
    // QuickJS 的栈溢出检查基于 stack_top（JS_NewRuntime 时构造线程的栈指针，
    // 默认 1MB 窗口）。Runtime 可能在别的线程构造（如共享实例在主线程构造、
    // JS 执行在独立线程），必须把 stack_top 更新到本执行线程，否则跨线程时
    // 栈地址低于 stack_limit 会误判 "Maximum call stack size exceeded"。
    JS_UpdateStackTop(rt_);
    guard_.emplace(boost::asio::make_work_guard(io_));
    while (!done_.load(std::memory_order_acquire))
        loop_body();
    shutdown();
    tls_current_runtime = prev;
}

// ---- 模式 B：脚本模式：排干后无在飞异步即退出（设计文档 §8.2）----
inline void Runtime::run_to_completion()
{
    Runtime* prev = tls_current_runtime;
    tls_current_runtime = this;
    JS_UpdateStackTop(rt_); // 同上：栈检查基于本执行线程
    guard_.emplace(boost::asio::make_work_guard(io_));
    for (;;) {
        pump_js_jobs();
        if (done_.load(std::memory_order_acquire) ||
            pending_.load(std::memory_order_acquire) == 0)
            break;
        io_.run_one();
    }
    shutdown();
    tls_current_runtime = prev;
}

// ---- stop()：任意线程可调，只碰 io_（线程安全）、不碰 JS ----
inline void Runtime::stop()
{
    boost::asio::post(io_, [this] { done_.store(true, std::memory_order_release); });
}

// ---- shutdown()：单向关闭（设计文档 §8.3）----
inline void Runtime::shutdown()
{
    if (shutdown_done_.load(std::memory_order_acquire)) {
        // 多轮 eval+run 的脚本模式：request_stop 只发一次，但每轮
        // run_to_completion 结束都要把当轮 scope_ 的关联收干净并重建
        //（counting_scope 析构要求无在飞关联，见下）。
        finish_scope();
        return;
    }
    shutdown_done_.store(true, std::memory_order_release);

    if (pending_.load(std::memory_order_acquire) != 0) {
        scope_->request_stop(); // 1. 仅在确有在飞任务时通知协作式取消
        while (pending_.load(std::memory_order_acquire) != 0) { // 2. 驱动到全部结算
            pump_js_jobs();
            io_.run_one(); // guard_ 仍在：取消结算必然 post 回 io_
        }
        pump_js_jobs(); // 3. 收尾 job（AbortError 的 then/catch 链）
    }
    // 挂起定时器（setTimeout/AbortSignal.timeout）：Node 语义不保持进程，
    // 随本轮结束丢弃。逐个 cancel（async_wait handler 同步以 operation_aborted
    // 结束，释放 entry 的 RtValue 引用），再清表（map.clear() 本身不 cancel）。
    {
        auto& tm = qjsbind::web::timers_detail::timer_map();
        for (const auto& [id, e] : tm)
            e->timer->cancel();
        tm.clear();
        while (io_.poll_one() > 0) {
        } // 消化可能延迟的 cancel handler（asio 允许延迟调用）
    }
    guard_.reset(); // 4. 解除保活

    finish_scope(); // 5. 见下
}

// join + 重建 scope_：request_stop 单向，但 counting_scope 析构要求无在飞
// 关联（spawn 的 op 已完成但 association 未释放时析构会 terminate）。
// basic_task 的完成/帧销毁可能 post 回 start scheduler（调度亲和），先排干
// io 再 join，避免 join 在残余 post 未执行时提前完成。
inline void Runtime::finish_scope()
{
    while (io_.poll_one() > 0) {
    }
    stdexec::sync_wait(scope_->join());
    scope_ = std::make_unique<stdexec::counting_scope>();
}

} // namespace qjs
