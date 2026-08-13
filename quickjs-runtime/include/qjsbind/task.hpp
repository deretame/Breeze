// task.hpp —— 可取消的 JS 任务调用（基础层 TaskRunner）
//
// 设计文档：docs/debug_pool_design.md
//   - 分层：基础层（任何 Runtime 可用）在本文件；扩展层 TaskPool 在 task_pool.hpp。
//   - 取消协议（§5）：Queued → 锁内摘除立即结算；Running → asio::post 取消闭包
//     （abort signal + 立即 settle "cancelled"）+ interrupt 原子标志（同步卡死场景）。
//   - settle 是 native CClosure（opaque 持有 shared_ptr<TaskEntry>），once 守卫：
//     取消路径先结算，trampoline 迟到的结算被挡掉。
//   - trampoline（§3.4）：globalThis.__invoke，signal 作为最后一个参数追加。
//
// 线程约定：
//   - submit/cancel 任意线程可调；begin_task / settle 恒在 JS 线程执行
//     （事件循环内，或池 worker 的内联路径）。
//   - 生命周期：TaskRunner 必须比 Runtime 及其 io_context 活得久（取消闭包捕获
//     this），且 Runtime 事件循环停转后再析构（宿主按既有 stop/shutdown 协议）。
#pragma once

#include <dart_cpp_bridge/channel.hpp>

#include <log.hpp>
#include <qjsbind/binary.hpp> // qjs::js_string（值语义字符串提取）
#include <qjsbind/context.hpp>
#include <qjsbind/function.hpp> // Object::set / qjs::func（__native_task_cancelled 注册）
#include <qjsbind/rt_value.hpp>
#include <qjsbind/web/abort.hpp>

#include <boost/asio/post.hpp>

#include <atomic>
#include <cstdint>
#include <functional>
#include <memory>
#include <mutex>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <utility>

namespace qjs {

class TaskPool;     // 前向声明（friend：池 worker 复用注册/结算内部路径）
class HostRuntime;  // 前向声明（friend：实例线程同样走内联注册/结算路径）

// ---- 调用请求 / 结果（设计文档 §2）----
struct InvokeRequest {
    std::string function;  // JS 全局函数名
    std::string args_json; // JSON 文本（如何解释由 trampoline 决定；HostRuntime 为整体单参数）
    bool debug = false;    // 仅 facade 路由用；TaskRunner 本身不关心
};

struct TaskResult {
    bool ok = false; // false 时 json 为错误文本（含 "cancelled"）
    std::string json;
};

struct TaskHandle {
    uint64_t id = 0;
    co::oneshot::Receiver<TaskResult> result_rx; // 完成发生在任务所在线程
};

// ---- 基础层：可取消的非阻塞任务调用（绑定一个 Runtime&）----
class TaskRunner {
public:
    explicit TaskRunner(Runtime& rt); // 安装 trampoline + interrupt handler
    ~TaskRunner();

    TaskRunner(const TaskRunner&) = delete;
    TaskRunner& operator=(const TaskRunner&) = delete;

    // 任意线程；begin_task 经 asio::post 到 rt 的 io_context（宿主须驱动事件循环）
    TaskHandle submit(InvokeRequest req);
    // 幂等，任意线程（设计文档 §5 三路取消）
    bool cancel(uint64_t id);

    // ---- 内部路径（friend TaskPool；池 worker 本线程即 JS 线程，须内联）----
    // 调用线程必须是该 Runtime 的 JS 线程（否则 begin_task 不会被执行）
    TaskHandle submit_inline(InvokeRequest req);

    // 结算观察钩子（可选，HostRuntime 的并发调度用）：settle 完成后回调
    // (task_id, ok, cancelled)，在 runner 锁外触发。设于配置阶段（任务登记前），
    // 之后只读。只要全部条目经 register_running 登记，回调恒在 JS 线程发生
    // （无 Queued 内联结算路径）。
    std::function<void(uint64_t id, bool ok, bool cancelled)> on_settle;

    // 查询任务 id 是否被 cancel() 过（Breeze runtime.isTaskGroupCancelled 的
    // 语义：以现有 taskid 代替 taskGroupKey）。已取消任务在 settle 时记入
    // cancelled_ids_（任务完成/失败不会记入）。任意线程可调。
    bool is_cancelled(uint64_t id) const
    {
        std::lock_guard lock(mu_);
        return cancelled_ids_.count(id) > 0;
    }

private:
    friend class TaskPool;
    friend class HostRuntime;

    struct TaskEntry {
        enum class State { Queued, Running };
        uint64_t id = 0;
        State state = State::Queued;                 // 受 runner 的 mu_ 保护
        InvokeRequest req;                           // begin_task 消费
        co::oneshot::Sender<TaskResult> tx;
        // signal_impl 所有权归 signal JS 对象（finalizer delete）；本指针仅 JS
        // 线程读写（取消闭包 / settle / begin_task 全在 JS 线程），析构不 delete
        qjsbind::web::AbortSignalImpl* signal_impl = nullptr;
        qjs::RtValue signal_js; // 保活 signal 对象到 settle（否则 GC 释放 impl）
        std::atomic<bool> settled{false};            // once 守卫
        bool cancelled = false;                      // 受 runner 的 mu_ 保护（cancel 置位）
    };

    struct SettleOpaque {
        TaskRunner* runner;
        std::shared_ptr<TaskEntry> entry;
    };

    // 锁内登记条目（id 由调用方生成：submit / 池级 Task 共用同一 id 链）
    void register_task(uint64_t id, InvokeRequest req, co::oneshot::Sender<TaskResult> tx);
    // 内联路径专用：登记即 Running（调用方在同一临界区内随后立即 begin_task）。
    // 消除 Queued 窗口：cancel 只能看到 Running → 恒走"post 闭包 + interrupt"，
    // 不存在任意线程上的 Queued 内联结算——HostRuntime 依赖这一点保证
    // on_settle 恒在 JS 线程触发。
    void register_running(uint64_t id, InvokeRequest req, co::oneshot::Sender<TaskResult> tx);
    // 必须在 JS 线程调用；条目不存在（已取消/已结算）→ no-op
    void begin_task(uint64_t id);
    // 条目是否已结算（池 worker 驱动一轮后查兜底）
    bool is_settled(uint64_t id) const;
    // 兜底结算（"settle 未调用"补发 error；once 守卫）
    bool force_settle(uint64_t id, bool ok, std::string json);
    // 迁移未开始条目到新 runner（池 reload 用）：返回旧 runner 中全部 Queued 条目
    std::vector<std::pair<uint64_t, std::pair<InvokeRequest, co::oneshot::Sender<TaskResult>>>>
    drain_queued();

    void install_trampoline();
    void do_begin_task(const std::shared_ptr<TaskEntry>& entry);     // 异常兜底
    void do_begin_task_impl(const std::shared_ptr<TaskEntry>& entry, JSContext* ctx);

    // once 守卫的结算：send 结果 + 擦除注册表 + 释放 signal（任意线程可调）
    static void settle_task(TaskRunner* runner, const std::shared_ptr<TaskEntry>& entry,
                            bool ok, std::string json);
    static int interrupt_handler(JSRuntime* rt, void* opaque);
    static JSValue settle_closure(JSContext* ctx, JSValueConst this_val, int argc,
                                  JSValueConst* argv, int magic, void* opaque);
    static void settle_finalize(void* opaque);

    Runtime& rt_;
    JSContext* ctx_;
    std::atomic<uint64_t> next_id_{1};
    mutable std::mutex mu_;
    std::unordered_map<uint64_t, std::shared_ptr<TaskEntry>> tasks_;
    // 已取消任务 id 集合（is_cancelled 查询）：cancel 置位、settle 时记入；
    // 只增不减（id 单调递增，量 = 已取消任务数，可接受）
    std::unordered_set<uint64_t> cancelled_ids_;
    // interrupt 原子标志：cancel 对 Running 任务置位；interrupt handler 触发时
    // 自动复位（exchange(false)），避免打断取消后的收尸 job
    std::atomic<bool> interrupt_{false};
};

// ================= 实现 =================

inline TaskRunner::TaskRunner(Runtime& rt) : rt_(rt), ctx_(rt.main_context().raw())
{
    // per-task signal 需要 AbortSignalImpl class 注册（宿主未装 web API 也自包含）
    if (!rt_.registry().is_registered<qjsbind::web::AbortSignalImpl>())
        rt_.registry().ensure<qjsbind::web::AbortSignalImpl>(ctx_, "AbortSignal");
    JS_SetInterruptHandler(rt_.raw(), &TaskRunner::interrupt_handler, this);
    install_trampoline();

    // __native_task_cancelled(id)：Breeze runtime.isTaskGroupCancelled 的后端
    //（以现有 taskid 代替 taskGroupKey，查询该任务是否被 cancel() 过）。
    // 捕获 this：TaskRunner 必须比 Runtime/context 活得久（宿主协议，见文件头）。
    Object global = Context(ctx_).globals();
    global.set("__native_task_cancelled", [this](Ctx cx, Value v) -> bool {
        qjs::Context c(cx.ctx);
        if (!v.is_number())
            throw_type_error(cx.ctx, "__native_task_cancelled: id 必须是数字");
        const uint64_t id = c.from_js<uint64_t>(v.raw());
        return is_cancelled(id);
    });
}

inline TaskRunner::~TaskRunner()
{
    // 注册表兜底：条目 tx close（等待方收到 nullopt）。正常流程应先在
    // runtime 停转后析构（此时注册表为空）。
    std::vector<std::shared_ptr<TaskEntry>> doomed;
    {
        std::lock_guard lock(mu_);
        doomed.reserve(tasks_.size());
        for (auto& [id, e] : tasks_)
            doomed.push_back(std::move(e));
        tasks_.clear();
    }
    for (auto& e : doomed)
        e->tx.close();
    JS_SetInterruptHandler(rt_.raw(), nullptr, nullptr);
}

// ---- trampoline（设计文档 §3.4）：signal 作为最后一个参数追加 ----
// 参数约定（全项目统一）：argsJson 整体 JSON.parse 后作为第一参数传递
// （命名参数风格 {"a":1} → fn({a:1})），signal 为第二参数。
// 注意：HostRuntime / TaskPool 的实例会被 bundle dispatcher 的 __invoke
// 覆盖（点路径解析 + 物化 + Node 风格错误），本实现是未装 dispatcher 时的
// 基础版（全局函数名直查）。
inline void TaskRunner::install_trampoline()
{
    Value r = Context(ctx_).eval(R"js(
        globalThis.__invoke = (name, argsJson, settle, signal) => {
          Promise.resolve()
            .then(() => globalThis[name](JSON.parse(argsJson), signal))
            .then(
              (v) => settle(true, JSON.stringify(v) ?? "null"),
              (e) => settle(false, String((e && e.stack) || e)),
            );
        };
    )js");
    if (r.is_exception()) {
        JSValue exc = JS_GetException(ctx_);
        // Context 成员：js_string（值语义提取，内部 FreeCString）；失败 → "(null)"
        std::string s = Context(ctx_).js_string(exc).value_or("(null)");
        QLOG_ERROR("[qjs::TaskRunner] trampoline install failed: {}", s);
        JS_FreeValue(ctx_, exc);
    }
}

inline int TaskRunner::interrupt_handler(JSRuntime*, void* opaque)
{
    auto* self = static_cast<TaskRunner*>(opaque);
    // 触发一次即复位：引擎抛错中断当前执行，后续收尸 job 不再被打断
    return self->interrupt_.exchange(false, std::memory_order_acq_rel) ? 1 : 0;
}

inline void TaskRunner::register_task(uint64_t id, InvokeRequest req,
                                      co::oneshot::Sender<TaskResult> tx)
{
    auto entry = std::make_shared<TaskEntry>();
    entry->id = id;
    entry->req = std::move(req);
    entry->tx = std::move(tx);
    std::lock_guard lock(mu_);
    tasks_[id] = std::move(entry);
}

inline void TaskRunner::register_running(uint64_t id, InvokeRequest req,
                                         co::oneshot::Sender<TaskResult> tx)
{
    auto entry = std::make_shared<TaskEntry>();
    entry->id = id;
    entry->state = TaskEntry::State::Running; // 登记即 Running：无 Queued 窗口
    entry->req = std::move(req);
    entry->tx = std::move(tx);
    std::lock_guard lock(mu_);
    tasks_[id] = std::move(entry);
}

inline TaskHandle TaskRunner::submit(InvokeRequest req)
{
    auto [tx, rx] = co::oneshot::channel<TaskResult>();
    const uint64_t id = next_id_.fetch_add(1);
    register_task(id, std::move(req), std::move(tx));
    boost::asio::post(rt_.io(), [this, id] { begin_task(id); });
    return TaskHandle{id, std::move(rx)};
}

inline TaskHandle TaskRunner::submit_inline(InvokeRequest req)
{
    auto [tx, rx] = co::oneshot::channel<TaskResult>();
    const uint64_t id = next_id_.fetch_add(1);
    register_task(id, std::move(req), std::move(tx));
    begin_task(id);
    return TaskHandle{id, std::move(rx)};
}

inline void TaskRunner::begin_task(uint64_t id)
{
    std::shared_ptr<TaskEntry> entry;
    {
        std::lock_guard lock(mu_);
        auto it = tasks_.find(id);
        if (it == tasks_.end())
            return; // 已取消（Queued 摘除）/已结算：迟到闭包 no-op
        entry = it->second;
    }
    do_begin_task(entry);
}

inline void TaskRunner::do_begin_task(const std::shared_ptr<TaskEntry>& entry)
{
    // JS 线程（事件循环内 / 池 worker 内联）
    JSContext* ctx = ctx_;
    try {
        do_begin_task_impl(entry, ctx);
    } catch (const std::exception& e) {
        settle_task(this, entry, false, std::string("internal error: ") + e.what());
    } catch (...) {
        settle_task(this, entry, false, "internal error: unknown exception");
    }
}

inline void TaskRunner::do_begin_task_impl(const std::shared_ptr<TaskEntry>& entry,
                                           JSContext* ctx)
{
    interrupt_.store(false, std::memory_order_release); // 本任务开始：复位 interrupt

    // 创建 per-task signal，与"存在性检查 + 置 Running"同一临界区：Queued 取消
    // 路径（任意线程）的 settle_task 与这里的赋值经 runner 锁互斥，杜绝
    // signal_js 的并发读写（release vs 赋值 → double-free）。锁内做 JS 分配是
    // 安全的：JS 分配不取 runner 锁，无锁序交互。
    {
        std::lock_guard lock(mu_);
        if (tasks_.count(entry->id) == 0)
            return; // 已被取消（Queued 摘除）：不创建 signal，条目析构即可
        auto* impl = new qjsbind::web::AbortSignalImpl();
        qjs::Value sig = qjsbind::web::make_signal_object(ctx, impl);
        entry->signal_impl = impl; // 所有权随 signal JS 对象（finalizer delete）
        entry->signal_js = qjs::RtValue(JS_GetRuntime(ctx), sig.take());
        entry->state = TaskEntry::State::Running;
    }

    // settle CClosure：opaque 持有 shared_ptr（迟到调用不悬垂），once 守卫在
    // settle_task 内（取消路径可先结算，trampoline 迟到结算被挡）
    auto* opaque = new SettleOpaque{this, entry};
    JSValue settle_fn = JS_NewCClosure(ctx, &TaskRunner::settle_closure, "settle",
                                       &TaskRunner::settle_finalize, 2, 0, opaque);

    // __invoke(name, argsJson, settle, signal)
    JSValue argv[4] = {
        JS_NewString(ctx, entry->req.function.c_str()),
        JS_NewString(ctx, entry->req.args_json.c_str()),
        settle_fn,
        entry->signal_js.dup(ctx),
    };
    JSValue global = JS_GetGlobalObject(ctx);
    JSValue invoke = JS_GetPropertyStr(ctx, global, "__invoke");
    JSValue r = JS_IsFunction(ctx, invoke)
                    ? JS_Call(ctx, invoke, JS_UNDEFINED, 4, argv)
                    : JS_ThrowTypeError(ctx, "__invoke is missing (TaskRunner trampoline)");

    if (JS_IsException(r)) {
        // trampoline 同步抛异常（正常不会：promise 链消化用户异常）→ 兜底结算
        JSValue exc = JS_GetException(ctx);
        // Context 成员：js_string（值语义提取，内部 FreeCString）；失败 → "(unknown error)"
        std::string emsg = Context(ctx).js_string(exc).value_or("(unknown error)");
        JS_FreeValue(ctx, exc);
        settle_task(this, entry, false, std::move(emsg));
    }
    JS_FreeValue(ctx, r);
    JS_FreeValue(ctx, invoke);
    JS_FreeValue(ctx, global);
    for (auto& a : argv)
        JS_FreeValue(ctx, a);
}

inline bool TaskRunner::is_settled(uint64_t id) const
{
    std::lock_guard lock(mu_);
    return tasks_.count(id) == 0;
}

inline bool TaskRunner::force_settle(uint64_t id, bool ok, std::string json)
{
    std::shared_ptr<TaskEntry> entry;
    {
        std::lock_guard lock(mu_);
        auto it = tasks_.find(id);
        if (it == tasks_.end())
            return false;
        entry = it->second;
    }
    settle_task(this, entry, ok, std::move(json));
    return true;
}

inline std::vector<std::pair<uint64_t, std::pair<InvokeRequest, co::oneshot::Sender<TaskResult>>>>
TaskRunner::drain_queued()
{
    std::vector<std::pair<uint64_t, std::pair<InvokeRequest, co::oneshot::Sender<TaskResult>>>>
        out;
    std::lock_guard lock(mu_);
    for (auto it = tasks_.begin(); it != tasks_.end();) {
        auto& e = it->second;
        if (e->state == TaskEntry::State::Queued) {
            out.emplace_back(e->id,
                             std::make_pair(std::move(e->req), std::move(e->tx)));
            it = tasks_.erase(it);
        } else {
            ++it;
        }
    }
    return out;
}

// ---- 取消（设计文档 §5）----
inline bool TaskRunner::cancel(uint64_t id)
{
    std::shared_ptr<TaskEntry> entry;
    TaskEntry::State st;
    {
        std::lock_guard lock(mu_);
        auto it = tasks_.find(id);
        if (it == tasks_.end())
            return false; // 不存在或已结算
        entry = it->second;
        st = entry->state;
        entry->cancelled = true; // 记取消（settle 时入 cancelled_ids_ 供查询）
        if (st == TaskEntry::State::Queued)
            tasks_.erase(it); // 1. Queued：锁内摘除
    }
    if (st == TaskEntry::State::Queued) {
        // 立即结算 cancelled（任意线程）；迟到的 begin_task 发现条目不存在 → no-op
        settle_task(this, entry, false, "cancelled");
        return true;
    }
    // 2+3. Running：post 取消闭包（JS 线程：abort signal + 立即结算 cancelled；
    // 底层 IO 收尸在后台，trampoline 迟到结算被 once 挡）+ 置 interrupt 原子标志
    // （同步 JS 执行中场景：引擎在字节码边界抛错，trampoline reject 分支收尾）
    boost::asio::post(rt_.io(), [this, entry] {
        if (entry->signal_impl)
            entry->signal_impl->abort(ctx_);
        settle_task(this, entry, false, "cancelled");
    });
    interrupt_.store(true, std::memory_order_release);
    return true;
}

inline void TaskRunner::settle_task(TaskRunner* runner, const std::shared_ptr<TaskEntry>& entry,
                                    bool ok, std::string json)
{
    bool expected = false;
    if (!entry->settled.compare_exchange_strong(expected, true))
        return; // once 守卫：取消路径与 trampoline 结算只生效一次
    const bool cancelled = !ok && json == "cancelled";
    entry->tx.send(TaskResult{ok, std::move(json)});
    if (runner) {
        // release 与 do_begin_task_impl 的赋值同锁互斥（数据竞争防护）。实际
        // 释放恒发生在 JS 线程（settle_closure/force_settle/cancel 闭包均 JS
        // 线程；任意线程的 Queued 路径 release 的是空值，无 JS 调用），锁内
        // JS_FreeValueRT 安全（finalizer 仅 delete，不取 runner 锁）
        {
            std::lock_guard lock(runner->mu_);
            runner->tasks_.erase(entry->id);
            // 已取消的任务：记入 cancelled_ids_（is_cancelled / JS 侧
            // __native_task_cancelled 查询）；正常完成/失败不记。
            if (entry->cancelled)
                runner->cancelled_ids_.insert(entry->id);
            // signal JS 对象的所有权归 JS(finalizer delete impl)：只释放 JS 引用并清
            // 指针，绝不二次 delete（double free 防护）
            entry->signal_js.release();
            entry->signal_impl = nullptr;
        }
        // 观察钩子在 runner 锁外触发：回调（HostRuntime）会取 host 锁，
        // 锁序 host→runner，持 runner 锁回调会成环
        if (runner->on_settle)
            runner->on_settle(entry->id, ok, cancelled);
    }
}

inline JSValue TaskRunner::settle_closure(JSContext* ctx, JSValueConst, int argc,
                                          JSValueConst* argv, int, void* opaque)
{
    auto* o = static_cast<SettleOpaque*>(opaque);
    if (argc < 2) {
        settle_task(o->runner, o->entry, false, "internal error: settle arity");
        return JS_UNDEFINED;
    }
    const bool ok = JS_ToBool(ctx, argv[0]) != 0;
    std::string json;
    // Context 成员：js_string（值语义提取，内部 FreeCString）；失败 → 清异常 + 兜底文本
    if (auto s = Context(ctx).js_string(argv[1])) {
        json = std::move(*s);
    } else {
        if (JS_HasException(ctx)) { // 转换失败：清异常，兜底文本
            JSValue e = JS_GetException(ctx);
            JS_FreeValue(ctx, e);
        }
        json = "<stringify error>";
    }
    settle_task(o->runner, o->entry, ok, std::move(json));
    return JS_UNDEFINED;
}

inline void TaskRunner::settle_finalize(void* opaque)
{
    delete static_cast<SettleOpaque*>(opaque);
}

} // namespace qjs
