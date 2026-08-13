// context.hpp —— Context / Runtime 封装 + per-runtime class 注册表
//
// Runtime 拥有 JSRuntime + 主 JSContext + 事件循环资产（M3 启用）+ 实例 id。
// 不可移动/复制（设计文档 §2）：多 Runtime 场景用 unique_ptr 或栈上持有。
#pragma once

#include <atomic>
#include <cstddef>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <string_view>
#include <typeindex>
#include <typeinfo>
#include <unordered_map>
#include <vector>

#include <boost/asio/io_context.hpp>
#include <boost/uuid/uuid.hpp>
#include <boost/uuid/uuid_generators.hpp>
#include <boost/uuid/uuid_io.hpp>

#include <exec/asio/use_sender.hpp>
#include <stdexec/execution.hpp>

#include <fetch/scheduler.hpp>

#include <quickjs.h>

#include <qjsbind/error.hpp>
#include <qjsbind/value.hpp>

namespace qjs {

namespace dyn {
    // dynamic_call（docs/dynamic_call_design.md）：host 表生命周期钩子。
    // 声明在前（Runtime 析构使用），inline 定义在 qjsbind/dynamic_call.hpp
    // （qjsbind.hpp 末尾包含）。凡构造 Runtime 的 TU 必须可见该定义。
    void remove_host(std::string_view host_id);
    // blob_store（docs/blob_store_design.md）：host 桶生命周期钩子。
    // 声明在前（Runtime 析构使用），inline 定义在 qjsbind/blob_store.hpp
    // （qjsbind.hpp 末尾包含）。凡构造 Runtime 的 TU 必须可见该定义。
    void remove_blob_host(std::string_view host_id);
}

class Runtime; // 前向声明（class_registry::finalizer 反查用）

// ---- 当前 JS 线程绑定的 Runtime（TLS；多运行时：每线程各绑一个）----
// Runtime 构造时绑定（构造线程即 JS 线程）；run()/run_to_completion() 进入时
// 再绑定一次（幂等）并恢复。协程异步函数可用 current_io() 拿事件循环（§11）。
inline thread_local Runtime* tls_current_runtime = nullptr;

// ---- io_context_scheduler：复用 fetchcore 的 fetch::io_scheduler ----
// （fetch_cpp_decoupling.md §7-8 风险 8：核心库自带一份，绑定层不重复实现，
// 避免两份实现漂移；schedule() = post(ioc, exec::asio::use_sender)）
using io_context_scheduler = fetch::io_scheduler;

// ---- 实例 id：自定义或自动 UUID v4（boost::uuids）----
inline std::string make_uuid_v4()
{
    static boost::uuids::random_generator gen; // 线程安全（内部 mutex，多 Runtime 各自线程可并发构造）
    return boost::uuids::to_string(gen());
}

// ---- per-runtime class 注册表（设计文档 §6.1）----
// 挂在 runtime opaque 上（JS_SetRuntimeOpaque），生命周期由 Runtime 成员保证：
// JS_FreeRuntime 在 Runtime 析构体内执行，此时注册表仍存活。
class class_registry {
public:
    // 注册（幂等）：每 C++ 类型一个 per-runtime class id；首次注册设定 class name
    template <class T>
    JSClassID ensure(JSContext* ctx, const char* name = "qjs_class")
    {
        auto it = ids_.find(typeid(T));
        if (it != ids_.end())
            return it->second;

        JSClassID id = 0;
        JS_NewClassID(JS_GetRuntime(ctx), &id);
        // class_name 指针由 JS_NewClass 保存（不拷贝）→ 存入稳定容器
        // （std::map 节点地址稳定，重哈希不影响）
        names_.emplace(typeid(T), name);
        // JS_NewClass 同样保存 class_def 指针（实测：传局部 def 会在 FreeRuntime 时悬垂崩溃）
        // → def 也存入 registry（map 节点稳定），生命周期 = registry 生命周期
        JSClassDef def{names_.at(typeid(T)).c_str(), &class_finalizer<T>, &class_mark<T>,
                       nullptr, nullptr};
        defs_.emplace(typeid(T), def);
        JS_NewClass(JS_GetRuntime(ctx), id, &defs_.at(typeid(T)));
        ids_.emplace(typeid(T), id);
        return id;
    }

    template <class T>
    bool is_registered() const
    {
        return ids_.count(typeid(T)) != 0;
    }

    template <class T>
    JSClassID id_of(JSContext* ctx) const
    {
        auto it = ids_.find(typeid(T));
        if (it == ids_.end())
            throw_type_error(ctx, "class not registered; call qjs::class_<T>(ctx, name) first");
        return it->second;
    }

    // 取 this/参数的原生指针（类型不符抛 type_error）
    template <class T>
    T* opaque(JSContext* ctx, JSValueConst this_val) const
    {
        auto it = ids_.find(typeid(T));
        if (it == ids_.end())
            throw_type_error(ctx, "class not registered");
        void* p = JS_GetOpaque2(ctx, this_val, it->second);
        if (!p)
            throw_type_error(ctx, "this is not an instance of the registered class");
        return static_cast<T*>(p);
    }

    // finalizer：定义在 Runtime 完整之后（context.hpp 底部，见下）
    template <class T>
    static void class_finalizer(JSRuntime* rt, JSValueConst obj);
    // gc_mark：定义在 Runtime 完整之后（context.hpp 底部，见下）。
    // 扩展点：T 可定义 void qjs_mark(JSRuntime*, JS_MarkFunc*) 标记 opaque 内的 JSValue
    // 引用（如监听器/缓存对象），否则 GC 会把它们误判为不可达而提前回收。
    template <class T>
    static void class_mark(JSRuntime* rt, JSValueConst val, JS_MarkFunc* mark_func);

    std::map<std::type_index, JSClassID> ids_;     // 节点稳定（class id 查找）
    std::map<std::type_index, std::string> names_; // class_name 生命周期 = registry 生命周期
    std::map<std::type_index, JSClassDef> defs_;   // JS_NewClass 保存 def 指针，须长期存活
};

class Context {
public:
    explicit Context(JSContext* ctx) : ctx_(ctx) {}

    JSContext* raw() const noexcept { return ctx_; }

    Value eval(std::string_view code, std::string_view filename = "<input>",
               int flags = JS_EVAL_TYPE_GLOBAL)
    {
        // 跨线程：QuickJS 栈检查基于 stack_top（构造线程记录），若本线程与
        // 构造线程不同（如 M4 的 ta 线程 eval 先于 run()），先更新栈基准，
        // 否则深调用会误判 "Maximum call stack size exceeded"（见 loop.hpp run()）。
        JS_UpdateStackTop(JS_GetRuntime(ctx_));
        return Value(ctx_, JS_Eval(ctx_, code.data(), code.size(), filename.data(), flags));
    }
    Object globals() { return Object(Value(ctx_, JS_GetGlobalObject(ctx_))); }

    // ---- JS 值工具（RAII 包装；声明在此，定义见 binary.hpp——与 Object::set
    // 声明在 value.hpp、定义在 function.hpp 同款模式，避免头循环依赖）----
    // 字符串取用：值语义拷贝（嵌入 '\0' 保留）；失败（如 Symbol → TypeError，
    // 引擎异常已挂起）→ nullopt。v 均为借用，不转移所有权。
    std::optional<std::string> js_string(JSValueConst v) const;
    // UTF-16 → UTF-8（TextEncoder 语义：正确组合代理对，孤立代理 → U+FFFD）
    std::optional<std::string> js_utf8(JSValueConst v) const;
    // 二进制提取：ArrayBuffer/TypedArray/DataView → 值拷贝；
    // 其他类型 → TypeError；detached/resize 守卫。
    std::vector<std::byte> js_bytes(JSValueConst v) const;
    // 字节 → JS（拷贝，JS 侧独立拥有）
    Value new_uint8_array(const std::byte* data, std::size_t len) const;
    Value new_array_buffer(const std::byte* data, std::size_t len) const;

    // ---- 类型转换（js_convert<T> 门面；定义见 convert.hpp）----
    // v 借用，不转移所有权；失败抛 type_error（引擎异常已挂起则抛 js_error）。
    template <class T>
    Value to_js(const T& v) const;
    template <class T>
    T from_js(JSValueConst v) const;

    // ---- JS 值操作（定义见 binary.hpp）----
    // 属性读取：返回 RAII Value（内部 JS_GetPropertyStr，析构自动 free）
    Value get_property(JSValueConst obj, std::string_view name) const;
    // 属性写入：转移 v 的所有权（内部 JS_SetPropertyStr 语义）
    void set_property(JSValueConst obj, std::string_view name, Value v) const;
    // 取走挂起异常（内部 JS_GetException，RAII 持有；无异常返回 undefined）
    Value get_exception() const;
    // 全局对象（RAII，内部 JS_GetGlobalObject）
    Value global_object() const;
    // 新建空对象（RAII，内部 JS_NewObject）
    Value new_object() const;
    // 新建空数组（RAII，内部 JS_NewArray）
    Value new_array() const;

    // 取 per-runtime 注册表（定义在文件底部：opaque 是 Runtime*，需 runtime_of）
    class_registry& registry() const;

private:
    JSContext* ctx_;
};

class Runtime {
public:
    explicit Runtime(std::string id = {}) : id_(id.empty() ? make_uuid_v4() : std::move(id))
    {
        rt_ = JS_NewRuntime();
        ctx_ = JS_NewContext(rt_);
        // opaque = Runtime*：finalizer（无 ctx）与转换层经 runtime_of(ctx) 反查
        JS_SetRuntimeOpaque(rt_, this);
        // TLS 绑定：构造线程即 JS 线程（多运行时：每 runtime 各自线程构造+run）。
        // 协程异步函数在 spawn（eval）时即同步执行到第一个挂起点，可能用到 current_io()
        tls_current_runtime = this;
        // fetch 核心从当前线程 thread_local 取 io_context（Client/BeastTransport/easy
        // 构造、multipart 切回等）；与 tls_current_runtime 同一线程绑定语义
        fetch::set_thread_io(io_);
    }
    ~Runtime()
    {
        // dynamic_call：host 表生命周期（docs/dynamic_call_design.md §6）——
        // 整表移除，防止悬挂 host_id 残留（全局表不进 remove_host，进程级存活）
        dyn::remove_host(id_);
        // blob_store：整桶立即回收（docs/blob_store_design.md §5）——不依赖
        // TTL，销毁即释放，防止孤儿桶白占 15 分钟内存
        dyn::remove_blob_host(id_);
        // 兜底关闭（幂等）：取消在飞任务并驱动到空、清理挂起定时器
        // （pending_==0 时也执行清理；正常流程经 stop() → run() 已 shutdown）
        shutdown();
        // 显式 GC：opaque 的 finalizer 在 ctx 存活期执行（opaque 内的
        // RtValue/JSValue 成员可安全释放；否则惰性 GC 会让它们泄漏到
        // JS_FreeRuntime 的 debug assert）。仍可达对象在 FreeContext 后
        // 引用归零释放，FreeRuntime 时 gc 列表为空。
        JS_RunGC(rt_);
        JS_FreeContext(ctx_);
        JS_FreeRuntime(rt_); // 类 finalizer 在此运行；registry_ 成员仍存活
        if (tls_current_runtime == this)
            tls_current_runtime = nullptr;
        // fetch thread_local io 指向本 Runtime 时清掉（防止同线程后续 fetch 用悬空 io）
        if (fetch::has_thread_io() && &fetch::thread_io() == &io_)
            fetch::clear_thread_io();
    }
    Runtime(const Runtime&) = delete;
    Runtime& operator=(const Runtime&) = delete;
    Runtime(Runtime&&) = delete;
    Runtime& operator=(Runtime&&) = delete;

    const std::string& id() const noexcept { return id_; }

    Context main_context() { return Context(ctx_); }
    JSRuntime* raw() const noexcept { return rt_; }

    class_registry& registry() { return registry_; }
    const class_registry& registry() const { return registry_; }

    boost::asio::io_context& io() noexcept { return io_; }
    io_context_scheduler io_scheduler() noexcept { return io_context_scheduler{io_}; }

    // ---- 统一 spawn 入口（设计文档 §8.1 不变量 1；实现见 loop.hpp）----
    // 三路收尾消化 error/stopped + pending_ 计数；env 注入 get_start_scheduler
    template <stdexec::sender S>
    void spawn(S&& sndr);

    // ---- 事件循环（设计文档 §8.2/§8.3；实现见 loop.hpp）----
    void run();               // 模式 A：服务模式（默认主模式），常驻直到 stop()
    void run_to_completion(); // 模式 B：脚本模式，pending_ == 0 即退出
    void stop();              // 任意线程可调：asio::post 置 done_ 标志
    void shutdown();          // request_stop + 驱动到 pending_ == 0 + 收尾
    void pump_js_jobs();      // 排干 JS job 队列（JS_ExecutePendingJob）

    // 剩余任务计数（诊断/测试用）
    std::ptrdiff_t pending() const noexcept { return pending_.load(std::memory_order_acquire); }
    // stop 标志（诊断/测试用）
    bool stop_requested_flag() const noexcept { return done_.load(std::memory_order_acquire); }

private:
    void complete() noexcept { pending_.fetch_sub(1, std::memory_order_acq_rel); }
    void finish_scope(); // 见 loop.hpp：join + 重建 scope_
    void loop_body();

    std::string id_;
    JSRuntime* rt_ = nullptr;
    JSContext* ctx_ = nullptr;
    boost::asio::io_context io_; // 见设计文档 §5/§8（成员声明顺序保证销毁次序）
    // scope_ 在 shutdown() 后重建（request_stop 单向，见 loop.hpp）
    std::unique_ptr<stdexec::counting_scope> scope_ = std::make_unique<stdexec::counting_scope>();
    std::atomic<std::ptrdiff_t> pending_{0};
    std::atomic<bool> done_{false};
    std::atomic<bool> shutdown_done_{false};
    std::optional<boost::asio::executor_work_guard<boost::asio::io_context::executor_type>> guard_;
    class_registry registry_; // 最后声明：JS_FreeRuntime 在析构体内执行时仍存活
};

// runtime 访问辅助（finalizer / thunk / convert_arg / promise 结算共用）
inline Runtime& runtime_of(JSContext* ctx)
{
    return *static_cast<Runtime*>(JS_GetRuntimeOpaque(JS_GetRuntime(ctx)));
}

// ---- 当前 JS 线程绑定的 Runtime（TLS 访问器）----
inline Runtime& current_runtime()
{
    if (!tls_current_runtime)
        throw std::runtime_error("qjs: no runtime bound to this thread (call Runtime::run() first)");
    return *tls_current_runtime;
}

inline boost::asio::io_context& current_io()
{
    return current_runtime().io();
}

// registry 访问辅助（兼容别名）
inline class_registry& registry_of(JSContext* ctx)
{
    return runtime_of(ctx).registry();
}

// Context::registry 定义（opaque 是 Runtime*，经 runtime_of 反查）
inline class_registry& Context::registry() const
{
    return runtime_of(ctx_).registry();
}

// ---- class_finalizer / class_mark 定义（Runtime 已完整）----
// finalizer 无 ctx（quickjs.h:654），从 runtime opaque（Runtime*）反查注册表拿 class id
template <class T>
void class_registry::class_finalizer(JSRuntime* rt, JSValueConst obj)
{
    auto* runtime = static_cast<Runtime*>(JS_GetRuntimeOpaque(rt));
    if (!runtime)
        return;
    auto& reg = runtime->registry();
    auto it = reg.ids_.find(typeid(T));
    if (it == reg.ids_.end())
        return;
    T* p = static_cast<T*>(JS_GetOpaque(obj, it->second));
    delete p;
}

// gc_mark：若 T 定义 qjs_mark(JSRuntime*, JS_MarkFunc*)，标记 opaque 内的 JSValue 引用
template <class T>
void class_registry::class_mark(JSRuntime* rt, JSValueConst val, JS_MarkFunc* mark_func)
{
    auto* runtime = static_cast<Runtime*>(JS_GetRuntimeOpaque(rt));
    if (!runtime)
        return;
    auto& reg = runtime->registry();
    auto it = reg.ids_.find(typeid(T));
    if (it == reg.ids_.end())
        return;
    T* p = static_cast<T*>(JS_GetOpaque(val, it->second));
    if constexpr (requires(T& t) { t.qjs_mark(rt, mark_func); })
        p->qjs_mark(rt, mark_func);
}

} // namespace qjs
