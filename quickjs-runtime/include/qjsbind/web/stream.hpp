// qjsbind::web —— ReadableStream 流机制（设计文档 §4，v2）
//
// 组成：
//   - ReadableStreamImpl：C++ 状态机（不直接暴露），拉模型驱动底层 BodySource
//   - MemorySource / TeeSource：内部字节源（支撑字节 body 统一流化、clone tee）
//   - ReadableStream / ReadableStreamDefaultReader：JS 绑定
//
// 并发与线程模型（设计文档 §4.1/§8.7）：
//   - 所有流状态操作在 io 线程（= JS 线程）；唯一跨线程入口是 stop_callback
//     （AbortController/Runtime::stop）→ 仅 post 回 io 线程再触碰状态
//   - cancel()/on_stop() 都在 io 线程执行，命令式、幂等
//   - 挂起的 read() 用 PendingRead（协程合成帧句柄双向链表，FIFO 结算）挂起；
//     协程被外层取消（shutdown）时 stdexec 销毁 awaitable → 析构自动摘除链表
//
// GC 回收路径：JS 对象（流/reader）被 GC → 绑定结构析构 → shared_ptr 释放 →
// ReadableStreamImpl 析构 → BodySource 释放 → socket 关闭（文档化行为：
// 不读完的 body 连接被丢弃）。挂起中的 read() 任务持 shared_ptr 副本，对象存活。
#pragma once

#include <fetch/body.hpp>
#include <qjsbind/std_exec.hpp>

#include <qjsbind/qjsbind.hpp>

#include <fmt/format.h> // fmt::format（错误消息拼接）

#include <boost/asio/io_context.hpp>
#include <deque>
#include <exception>
#include <functional>
#include <memory>
#include <optional>
#include <string>
#include <utility>

namespace qjsbind::web {

// 底层字节源 = fetchcore 核心类型（fetch_cpp_decoupling.md：绑定层不再持有
// 独立的 BodySource，BodySource/Header/Request/Response 均为 fetch 核心类型）
using BodySource = fetch::BodySource;

// ---- 挂起等待者（协程合成帧句柄双向链表，FIFO 结算）----
// 用法：read() 协程局部声明，co_await 挂起；head_slot/tail_slot 指向所属
// 链表（调用方在挂起前设置）。wake_all() 按序 resume。
// 析构自动摘除：协程帧销毁（外层 stopped）时不会留下悬挂指针。
struct PendingRead {
    std::coroutine_handle<> frame{}; // await_suspend 收到的合成帧（stdexec 包装）
    PendingRead* prev = nullptr;
    PendingRead* next = nullptr;
    PendingRead** head_slot = nullptr; // 指向链表头指针（调用方设置）
    PendingRead** tail_slot = nullptr; // 指向链表尾指针（调用方设置）
    bool linked = false;

    ~PendingRead()
    {
        if (linked)
            unlink();
    }
    bool await_ready() const noexcept { return false; }
    void await_suspend(std::coroutine_handle<> h) noexcept
    {
        frame = h;
        // 尾插：保持 FIFO
        prev = *tail_slot;
        next = nullptr;
        if (prev)
            prev->next = this;
        else
            *head_slot = this;
        *tail_slot = this;
        linked = true;
    }
    void await_resume() noexcept {}

    void unlink()
    {
        if (prev)
            prev->next = next;
        else
            *head_slot = next;
        if (next)
            next->prev = prev;
        else
            *tail_slot = prev;
        prev = next = nullptr;
        linked = false;
    }
};

// 唤醒链表全部挂起者（io 线程）；frame.resume() 恢复协程（stdexec 合成帧，
// 恢复后走 await_resume → set_value → 协程继续）。
template <class Head, class Tail>
inline void wake_all(Head& head, Tail& tail)
{
    PendingRead* w = head;
    head = nullptr;
    tail = nullptr;
    while (w) {
        PendingRead* n = w->next;
        w->prev = w->next = nullptr;
        w->linked = false; // 已摘除（析构不再动链表）
        w->frame.resume();
        w = n;
    }
}

// ---- 内存字节源：字节 body（new Response("x")、data: URL）统一为流 ----
class MemorySource : public BodySource {
public:
    explicit MemorySource(std::string bytes) : bytes_(std::move(bytes)) {}
    std_exec::task<std::optional<std::string>> read() override
    {
        if (done_)
            co_return std::nullopt;
        done_ = true;
        co_return std::move(bytes_);
    }
    void cancel() override
    {
        done_ = true;
        bytes_.clear();
    }

private:
    std::string bytes_;
    bool done_ = false;
};

// ---- tee：克隆/init 复制共享底层源（设计文档 §4.4）----
// 共享状态：{ source, bufA, bufB, closedA, closedB, done, error }
// 分支 read：本分支 buf 空 → pull source → 块推入两侧 buf（已关闭分支不推）→ 从本分支弹出
// 分支 cancel：标记关闭；两侧都关闭 → source.cancel()
// 内存说明：慢分支会积压缓冲；分支被 GC → 视为 cancel 释放缓冲（已知限制）
class TeeSource : public BodySource {
public:
    struct Shared {
        std::shared_ptr<BodySource> source;
        std::deque<std::string> bufA, bufB;
        bool closedA = false, closedB = false;
        bool done = false;
        bool errored = false;
        std::exception_ptr error;
        bool pumping = false;
        PendingRead* head = nullptr;
        PendingRead* tail = nullptr;
    };

    static std::pair<std::shared_ptr<TeeSource>, std::shared_ptr<TeeSource>>
    tee(std::shared_ptr<BodySource> src)
    {
        auto sh = std::make_shared<Shared>();
        sh->source = std::move(src);
        auto a = std::shared_ptr<TeeSource>(new TeeSource(sh, true));
        auto b = std::shared_ptr<TeeSource>(new TeeSource(sh, false));
        return {a, b};
    }

    std_exec::task<std::optional<std::string>> read() override
    {
        for (;;) {
            if (sh_->errored)
                std::rethrow_exception(sh_->error);
            auto& buf = is_a_ ? sh_->bufA : sh_->bufB;
            if (!buf.empty()) {
                auto v = std::move(buf.front());
                buf.pop_front();
                co_return v;
            }
            if (sh_->done)
                co_return std::nullopt;
            if (is_a_ ? sh_->closedA : sh_->closedB)
                co_return std::nullopt; // 本分支已 cancel
            if (sh_->pumping) {
                PendingRead w{};
                w.head_slot = &sh_->head;
                w.tail_slot = &sh_->tail;
                co_await w; // 等 pump 分支完成（FIFO）
                continue;
            }
            struct PumpGuard {
                bool& f;
                ~PumpGuard() { f = false; }
            } guard{sh_->pumping};
            std::optional<std::string> block;
            try {
                block = co_await sh_->source->read();
            } catch (...) {
                sh_->errored = true;
                sh_->error = std::current_exception();
                wake_all(sh_->head, sh_->tail);
                throw;
            }
            if (!block)
                sh_->done = true;
            else {
                if (!sh_->closedA)
                    sh_->bufA.push_back(*block);
                if (!sh_->closedB)
                    sh_->bufB.push_back(*block);
            }
            wake_all(sh_->head, sh_->tail);
        }
    }

    void cancel() override
    {
        if (is_a_)
            sh_->closedA = true;
        else
            sh_->closedB = true;
        if (sh_->closedA && sh_->closedB)
            sh_->source->cancel();
        wake_all(sh_->head, sh_->tail); // 挂起的分支 read 醒来 → 见 closed → nullopt
    }

    ~TeeSource() override
    {
        // 分支被 GC → 视为 cancel（文件头注释语义）：清缓冲停止积压；
        // 两分支都消亡 → cancel 底层源（否则 abort 后网络读残留）
        if (is_a_) {
            sh_->closedA = true;
            std::deque<std::string>().swap(sh_->bufA);
        } else {
            sh_->closedB = true;
            std::deque<std::string>().swap(sh_->bufB);
        }
        if (sh_->closedA && sh_->closedB && sh_->source)
            sh_->source->cancel();
    }

private:
    TeeSource(std::shared_ptr<Shared> sh, bool is_a) : sh_(std::move(sh)), is_a_(is_a) {}

    std::shared_ptr<Shared> sh_;
    bool is_a_;
};

// ---- ReadableStreamImpl：流状态机（设计文档 §4.1）----
// 经 make_stream() 创建（构造后再注册 stop_callback：weak_from_this 需 shared_ptr 已建）。
struct ReadableStreamDefaultReaderBinding; // 前向声明（唯一 reader 槽）
struct ReadableStreamImpl : public std::enable_shared_from_this<ReadableStreamImpl> {
    enum class State { Readable, Closed, Errored };
    State state = State::Readable;
    std::shared_ptr<BodySource> source; // 底层字节源（网络/解压/内存/tee）
    std::deque<std::string> queue;      // 已拉未读块（拉驱动下通常 ≤1）
    std::exception_ptr error;           // Errored 时的原因
    bool disturbed = false;             // 发生过实际 read → bodyUsed
    bool pumping = false;               // 是否有 pull 在飞（PumpGuard 管理）
    bool stop_requested = false;        // abort 已请求（io 线程置位）
    // 唯一 reader 槽：reader_lock 是 locked 标记（不随 reader JS 对象 GC 释放——
    // wpt：getReader 返回值丢弃后流仍锁定）；reader_binding 仅供活跃 reader
    // 使用（binding 析构置空；closed promise 结算走它）
    std::shared_ptr<void> reader_lock;
    ReadableStreamDefaultReaderBinding* reader_binding = nullptr;
    PendingRead* head = nullptr;
    PendingRead* tail = nullptr;
    boost::asio::io_context& io;
    std::stop_token st_; // 构造时传入（tee/复制时沿袭，abort 语义保持）
    std::optional<std::stop_callback<std::function<void()>>> stop_cb_;

    ReadableStreamImpl(boost::asio::io_context& io_, std::shared_ptr<BodySource> src,
                       std::stop_token st = {})
        : source(std::move(src)), io(io_), st_(std::move(st))
    {
    }

    // 注意：析构不 cancel source——丢弃未读完 body 的连接由 BodySource 析构链
    // 关闭（BeastBodySource 析构 close socket）；tee 分支流析构不得杀死共享
    // source（否则另一分支读 EOF）。abort 场景由 on_stop() 显式 cancel。

    bool locked() const noexcept { return reader_lock != nullptr; }

    // 注册取消回调（跨线程：仅 post 回 io 线程再触碰状态）。须在 make_shared 之后调用。
    void arm_stop(std::stop_token st)
    {
        if (!st.stop_possible())
            return;
        std::weak_ptr<ReadableStreamImpl> weak = weak_from_this();
        stop_cb_.emplace(st, [weak] {
            if (auto impl = weak.lock())
                boost::asio::post(impl->io, [impl] { impl->on_stop(); });
        });
    }

    // io 线程：abort 请求到达
    void on_stop()
    {
        stop_requested = true;
        if (state == State::Readable) {
            state = State::Closed;
            if (source)
                source->cancel();
        }
        wake_all(head, tail);
        notify_reader_later();
    }

    // io 线程：命令式取消（reader.cancel / 流 cancel）
    void cancel()
    {
        if (state != State::Readable)
            return;
        state = State::Closed;
        disturbed = true; // spec：cancel 是消费操作（wpt response-stream-disturbed-4）
        if (source)
            source->cancel();
        wake_all(head, tail);
        notify_reader_later();
    }

    // 状态变化 → 结算 reader 的 closed promise（定义见绑定部分）
    void notify_reader_later();

    // read()：queue 非空 → 立即返回 {value, done:false}；EOF → {nullopt, done:true}
    // 挂起：进 pending FIFO 并触发一次 source pull（pumping 串行化并发 pull）。
    // abort（stop_requested）→ 以 stopped 完成 → reject AbortError。
    // source 抛异常 → 状态 Errored，挂起及后续 read() 以该 error 结束。
    std_exec::task<std::optional<std::string>> read()
    {
        disturbed = true;
        for (;;) {
            if (stop_requested)
                co_await stdexec::just_stopped(); // AbortError
            if (state == State::Errored)
                std::rethrow_exception(error);
            if (!queue.empty()) {
                auto v = std::move(queue.front());
                queue.pop_front();
                co_return v;
            }
            if (state == State::Closed)
                co_return std::nullopt;
            if (pumping) {
                PendingRead w{};
                w.head_slot = &head;
                w.tail_slot = &tail;
                co_await w; // 等正在 pull 的 read 完成（FIFO 结算）
                continue;
            }
            struct PumpGuard {
                bool& f;
                ~PumpGuard() { f = false; }
            } guard{pumping};
            std::optional<std::string> block;
            try {
                block = co_await source->read();
            } catch (...) {
                state = State::Errored;
                error = std::current_exception();
                wake_all(head, tail);
                notify_reader_later();
                continue; // 重入循环 → 抛 error
            }
            if (!block) {
                state = State::Closed;
                notify_reader_later();
            } else if (!block->empty())
                queue.push_back(std::move(*block));
            wake_all(head, tail); // 挂起者醒来重查状态（取块 / done / error）
            // 自己继续循环取块
        }
    }
};

inline std::shared_ptr<ReadableStreamImpl>
make_stream(boost::asio::io_context& io, std::shared_ptr<BodySource> src,
            std::stop_token st = {})
{
    auto impl = std::make_shared<ReadableStreamImpl>(io, std::move(src), st);
    impl->arm_stop(st);
    return impl;
}

} // namespace qjsbind::web

// ======================== JS 绑定（设计文档 §4.2）=====================
// 绑定结构作为 class_ opaque（new/delete）；持 shared_ptr<ReadableStreamImpl>
// 保证挂起任务/GC 期间对象存活；RtValue 引用经 qjs_mark 标记。
namespace qjsbind::web {

// 状态变化 → 结算 reader 的 closed promise（定义见绑定结构之后）
struct ReadableStreamDefaultReaderBinding;

// 构造 name="TypeError" 的 JS 错误值（不抛；调用方负责 free）。
// 与 errors.hpp 的 throw_type_error 同源构造逻辑（保证 instanceof 正确）。
// g/ctor/m 均为 RAII Value，析构自动释放。
inline JSValue make_type_error_value(JSContext* ctx, const std::string& msg)
{
    qjs::Context cx(ctx);
    JSValue err = JS_UNDEFINED;
    qjs::Value g = cx.global_object();
    qjs::Value ctor = cx.get_property(g.raw(), "TypeError");
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
            cx.set_property(err, "name", cx.to_js(std::string_view("TypeError")));
            cx.set_property(err, "message", cx.to_js(msg));
        }
    }
    return err;
}

// std::exception_ptr → JS 错误值：js_error 原样；读 body 失败统一 TypeError
inline JSValue stream_error_value(JSContext* ctx, std::exception_ptr e)
{
    try {
        std::rethrow_exception(e);
    } catch (const qjs::js_error& je) {
        return je.release_value();
    } catch (const std::exception& ex) {
        return make_type_error_value(ctx, std::string("fetch failed: ") + ex.what());
    } catch (...) {
        return make_type_error_value(ctx, "fetch failed: unknown error");
    }
}

struct ReadableStreamBinding {
    std::shared_ptr<ReadableStreamImpl> impl;
    ReadableStreamBinding() = default;
    ReadableStreamBinding(const ReadableStreamBinding& o) : impl(o.impl) {}
    // 禁止 JS 直接构造（内部类：fetch/Response 注入 source）
    void qjs_init(JSContext* ctx)
    {
        throw_type_error(ctx, "ReadableStream: 不能直接构造");
    }
};

struct ReadableStreamDefaultReaderBinding {
    std::shared_ptr<ReadableStreamImpl> impl;
    JSContext* ctx = nullptr;
    qjs::RtValue closed_js;       // closed promise（SameObject 缓存）
    qjs::RtValue closed_resolve;  // 结算函数（懒创建于首次访问 closed）
    qjs::RtValue closed_reject;
    bool closed_settled = false;

    // 禁止 JS 直接构造（经 stream.getReader() 创建）
    void qjs_init(JSContext* ctx)
    {
        throw_type_error(ctx, "ReadableStreamDefaultReader: 不能直接构造");
    }

    std::shared_ptr<void> lock; // 与 impl->reader_lock 同对象（releaseLock 时比对）

    ~ReadableStreamDefaultReaderBinding()
    {
        // 活跃槽置空（不解除 locked——锁标记由 impl 独立持有，wpt 语义：
        // reader 被 GC 后流仍锁定，直到显式 releaseLock）
        if (impl && impl->reader_binding == this)
            impl->reader_binding = nullptr;
    }

    void qjs_mark(JSRuntime* rt, JS_MarkFunc* mf)
    {
        closed_js.mark(rt, mf);
        closed_resolve.mark(rt, mf);
        closed_reject.mark(rt, mf);
    }

    // 状态已定 → 结算缓存的 closed promise（io 线程调用）
    void settle_closed()
    {
        if (closed_settled || !ctx || closed_js.empty())
            return;
        if (impl->state == ReadableStreamImpl::State::Closed) {
            JSValue u = JS_UNDEFINED;
            JS_Call(ctx, closed_resolve.raw(), JS_UNDEFINED, 1, &u);
            closed_settled = true;
        } else if (impl->state == ReadableStreamImpl::State::Errored) {
            JSValue err = stream_error_value(ctx, impl->error);
            JS_Call(ctx, closed_reject.raw(), JS_UNDEFINED, 1, &err);
            JS_FreeValue(ctx, err);
            closed_settled = true;
        }
    }
};

// 手动创建绑定对象：new T 挂为 opaque（JS 对象持有；finalizer delete）
template <class T>
inline qjs::Value new_binding_object(JSContext* ctx, std::shared_ptr<ReadableStreamImpl> impl)
{
    JSClassID id = qjs::registry_of(ctx).id_of<T>(ctx);
    JSValue obj = JS_NewObjectClass(ctx, id);
    if (JS_IsException(obj))
        throw qjs::js_error(ctx, JS_GetException(ctx));
    auto* b = new T;
    b->impl = std::move(impl);
    JS_SetOpaque(obj, b);
    return qjs::Value(ctx, obj);
}

// 状态变化 → 结算 reader 的 closed promise（io 线程调用）
inline void ReadableStreamImpl::notify_reader_later()
{
    if (reader_binding)
        reader_binding->settle_closed();
}

// 状态变化通知 reader（closed promise 结算；io 线程调用）
inline void notify_reader(ReadableStreamImpl& impl)
{
    if (impl.reader_binding)
        impl.reader_binding->settle_closed();
}

// 已结算 promise（同步返回 Promise.resolve(undefined)；
// quickjs 无 JS_NewPromiseResolve，用 capability + 立即 resolve）
inline qjs::Value resolved_promise(JSContext* ctx)
{
    JSValue resolving[2];
    JSValue p = JS_NewPromiseCapability(ctx, resolving);
    if (JS_IsException(p)) {
        JS_FreeValue(ctx, resolving[0]);
        JS_FreeValue(ctx, resolving[1]);
        return qjs::Value(ctx, JS_GetException(ctx));
    }
    JSValue u = JS_UNDEFINED;
    JS_Call(ctx, resolving[0], JS_UNDEFINED, 1, &u);
    JS_FreeValue(ctx, resolving[0]);
    JS_FreeValue(ctx, resolving[1]);
    return qjs::Value(ctx, p);
}

inline void install_readable_stream(qjs::Context& ctx)
{
    using namespace qjs; // class_/js_convert 在 qjs
    auto cls = class_<ReadableStreamBinding>(ctx, "ReadableStream")
        .constructor<>() // 挂全局需要构造器；qjs_init 抛 TypeError 禁止 new
        .getter("locked", [](qjs::Ctx ctx, qjs::This<ReadableStreamBinding> self) -> bool {
            return self->impl->locked();
        })
        .method("getReader", [](qjs::Ctx ctx,
                                qjs::This<ReadableStreamBinding> self) -> qjs::Value {
            if (self->impl->locked())
                throw_type_error(ctx.ctx, "ReadableStream: 已被 reader 锁定");
            if (self->impl->disturbed)
                throw_type_error(ctx.ctx, "ReadableStream: body 已被消费"); // wpt disturbed-5
            qjs::Value v = new_binding_object<ReadableStreamDefaultReaderBinding>(ctx.ctx,
                                                                                  self->impl);
            auto* r = qjs::registry_of(ctx.ctx)
                          .opaque<ReadableStreamDefaultReaderBinding>(ctx.ctx, v.raw());
            r->ctx = ctx.ctx;
            r->lock = std::make_shared<int>(0);
            self->impl->reader_lock = r->lock; // locked 标记（不随 reader GC 释放）
            self->impl->reader_binding = r;
            return v;
        })
        .method("cancel", [](qjs::Ctx ctx, qjs::This<ReadableStreamBinding> self) -> qjs::Value {
            self->impl->cancel();
            notify_reader(*self->impl);
            return resolved_promise(ctx.ctx);
        });

    auto cls_reader = class_<ReadableStreamDefaultReaderBinding>(ctx, "ReadableStreamDefaultReader")
        .constructor<>() // 挂全局需要构造器；qjs_init 抛 TypeError 禁止 new
        .getter("closed", [](qjs::Ctx ctx,
                             qjs::This<ReadableStreamDefaultReaderBinding> self) -> qjs::Value {
            if (self->closed_js.empty()) {
                // 懒创建 capability（SameObject：同一 reader 恒同一 promise）
                JSValue resolving[2];
                JSValue p = JS_NewPromiseCapability(ctx.ctx, resolving);
                if (JS_IsException(p)) {
                    JS_FreeValue(ctx.ctx, resolving[0]);
                    JS_FreeValue(ctx.ctx, resolving[1]);
                    return qjs::Value(ctx.ctx, JS_GetException(ctx.ctx));
                }
                self->closed_js = qjs::RtValue(JS_GetRuntime(ctx.ctx), p);
                self->closed_resolve = qjs::RtValue(JS_GetRuntime(ctx.ctx), resolving[0]);
                self->closed_reject = qjs::RtValue(JS_GetRuntime(ctx.ctx), resolving[1]);
                self->settle_closed(); // 状态已定 → 立即结算
            }
            return qjs::Value(ctx.ctx, self->closed_js.dup(ctx.ctx));
        })
        .method("read", [](qjs::Ctx ctx,
                           qjs::This<ReadableStreamDefaultReaderBinding> self)
                    -> std_exec::task<qjs::Value> {
            // 副本：挂起期间 JS 对象可被 GC，impl 必须存活
            std::shared_ptr<ReadableStreamImpl> impl = self->impl;
            std::optional<std::string> block;
            try {
                block = co_await impl->read();
            } catch (const qjs::js_error&) {
                throw;
            } catch (const std::exception& e) {
                // 读 body 失败 → TypeError（设计文档 §3.3）
                throw_type_error(ctx.ctx, fmt::format("fetch failed: {}", e.what()));
            }
            JSValue obj = JS_NewObject(ctx.ctx);
            if (block) {
                JSValue val =
                    JS_NewUint8ArrayCopy(ctx.ctx, reinterpret_cast<const uint8_t*>(block->data()),
                                         static_cast<int>(block->size()));
                JS_SetPropertyStr(ctx.ctx, obj, "value", val);
                JS_SetPropertyStr(ctx.ctx, obj, "done", JS_NewBool(ctx.ctx, false));
            } else {
                JS_SetPropertyStr(ctx.ctx, obj, "value", JS_UNDEFINED);
                JS_SetPropertyStr(ctx.ctx, obj, "done", JS_NewBool(ctx.ctx, true));
            }
            co_return qjs::Value(ctx.ctx, obj);
        })
        .method("cancel", [](qjs::Ctx ctx,
                             qjs::This<ReadableStreamDefaultReaderBinding> self) -> qjs::Value {
            self->impl->cancel();
            notify_reader(*self->impl);
            if (self->lock && self->lock == self->impl->reader_lock) {
                self->impl->reader_lock.reset(); // spec：cancel 顺带 releaseLock
                if (self->impl->reader_binding == self.ptr)
                    self->impl->reader_binding = nullptr;
            }
            return resolved_promise(ctx.ctx);
        })
        .method("releaseLock", [](qjs::Ctx ctx,
                                  qjs::This<ReadableStreamDefaultReaderBinding> self) {
            if (!self->lock || self->lock != self->impl->reader_lock)
                return; // 已释放/非本 reader：无操作
            if (self->impl->head != nullptr)
                throw_type_error(ctx.ctx, "Reader: 有挂起的 read 时不能 releaseLock");
            self->impl->reader_lock.reset();
            if (self->impl->reader_binding == self.ptr)
                self->impl->reader_binding = nullptr;
        });

    // class_ 注册只建类，需显式挂全局（模块场景才 export）
    ctx.globals().set("ReadableStream", cls.constructor_function());
    ctx.globals().set("ReadableStreamDefaultReader", cls_reader.constructor_function());
}

} // namespace qjsbind::web
