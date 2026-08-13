// dynamic_call.hpp —— 动态调用：JS 侧 call(name, ...args) / callSync(name, ...args)
//
// 设计文档：docs/dynamic_call_design.md（v1）
//
// 概览：
//   - JS 侧两个全局函数：call（异步，返回 Promise）、callSync（同步）。
//   - 参数任意个，整体序列化为 JSON 数组字符串传给 C++ handler；返回值是
//     handler 返回的 JSON 字符串解析后的 JS 值。
//   - host_id 不由 JS 传：install_dynamic_call 时捕获本 Runtime 的 id 进 lambda
//     闭包（qjs::func()/Object::set 注册），每次调用自动携带；handler 可从
//     第一个参数得知调用来源。
//   - 进程级注册中心（Registry 单例）：全局表（同步/异步）+ 每 host 表
//     （同步/异步）；JS 调用只能命中自己 host 的表 + 全局表（硬性隔离边界）。
//   - 查找顺序：sync = host.sync → global.sync；async = host.async → global.async。
//     call 只服务异步 handler（返回 Promise 即真异步），callSync 只服务同步
//     handler——互不回落（同步结果不走 Promise，异步入口不内联同步执行）。
//
// 线程不变量（设计文档 §6）：
//   1. handler 是纯 C++ 函数：JSON 字符串进、JSON 字符串出，不得触碰任何
//      JSValue / JSContext。
//   2. sync handler 跑在调用方的 JS 线程上（内联调用）。重活不要注册 sync 版，
//      会阻塞该 host 的事件循环——想跑重活就注册 async 版，在 task 里自己
//      continues_on 到线程池。
//   3. async handler 的 task 由调用方 Runtime 的 counting_scope spawn
//      （Runtime::spawn，loop.hpp），run_to_completion() 会等它结算；结算点经
//      continues_on(rt.io_scheduler()) 回到调用方 JS 线程，parse JSON、resolve
//      Promise 都在 JS 线程，安全。
//   4. 同一个全局 handler 可能被多个 host 的 JS 线程并发调用；handler 若访问
//      共享状态，线程安全由注册方自理——注册中心只管查表时的锁（D3：查表持
//      读锁拷贝 handler，解锁后再调用，handler 内部可安全地注册/注销）。
//
// 依赖说明：context.hpp 在文件顶部前向声明了本文件的 dyn::remove_host（Runtime
// 析构钩子），定义在本文件。凡构造 Runtime 的 TU 必须可见本文件定义：用
// qjsbind.hpp（末尾包含本文件）或直接包含 <qjsbind/dynamic_call.hpp>。
#pragma once

#include <functional>
#include <memory>
#include <optional>
#include <shared_mutex>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>

#include <quickjs.h>
#include <stdexec/execution.hpp>

#include <qjsbind/context.hpp>
#include <qjsbind/error.hpp>
#include <qjsbind/binary.hpp> // qjs::Context::js_string（值语义字符串提取）
#include <qjsbind/function.hpp> // Object::set + func()（lambda 注册，异常边界自动）
#include <qjsbind/loop.hpp>
#include <qjsbind/promise.hpp>
#include <qjsbind/std_exec.hpp>

namespace qjs {
namespace dyn {

// ================= handler 签名（设计文档 §3.1）=================
// 同步 handler：JSON 进，JSON 出。在调用方 JS 线程上内联执行。
// 抛 C++ 异常 → JS 侧 throw。
using SyncHandler = std::function<std::string(
    std::string_view host_id, std::string_view name, std::string_view json_args)>;

// 异步 handler：惰性 task，由调用方 Runtime 的 scope spawn，
// Promise 经 continues_on 回到 JS 线程后 resolve。
// co_await 中抛异常 → Promise reject。
using AsyncHandler = std::function<std_exec::task<std::string>(
    std::string host_id, std::string name, std::string json_args)>;

// ================= 注册中心（设计文档 §1/§3.2）=================
class Registry {
public:
    static Registry& instance()
    {
        static Registry r; // 进程级单例（函数局部静态，惰性构造）
        return r;
    }

    Registry(const Registry&) = delete;
    Registry& operator=(const Registry&) = delete;

    // ---- 全局表（所有 host 可见）----
    void register_global(std::string name, SyncHandler fn)
    {
        std::unique_lock lock(mu_);
        global_sync_.insert_or_assign(std::move(name), std::move(fn));
    }
    void register_global_async(std::string name, AsyncHandler fn)
    {
        std::unique_lock lock(mu_);
        global_async_.insert_or_assign(std::move(name), std::move(fn));
    }
    // 两张全局表都尝试删（同名在 sync/async 表互不干扰，可分别存在）
    void unregister_global(std::string_view name)
    {
        std::unique_lock lock(mu_);
        global_sync_.erase(std::string(name));
        global_async_.erase(std::string(name));
    }

    // ---- host 表（只有该 host 自己的 JS 调用能命中；host 表优先于全局表）----
    void register_host(std::string_view host_id, std::string name, SyncHandler fn)
    {
        std::unique_lock lock(mu_);
        hosts_[std::string(host_id)].sync_map.insert_or_assign(std::move(name), std::move(fn));
    }
    void register_host_async(std::string_view host_id, std::string name, AsyncHandler fn)
    {
        std::unique_lock lock(mu_);
        hosts_[std::string(host_id)].async_map.insert_or_assign(std::move(name), std::move(fn));
    }
    void unregister_host(std::string_view host_id, std::string_view name)
    {
        std::unique_lock lock(mu_);
        auto it = hosts_.find(std::string(host_id));
        if (it == hosts_.end())
            return;
        it->second.sync_map.erase(std::string(name));
        it->second.async_map.erase(std::string(name));
    }
    // 整表删除（Runtime 析构时调用，防止悬挂 host_id 残留；全局表不受影响）
    void remove_host(std::string_view host_id)
    {
        std::unique_lock lock(mu_);
        hosts_.erase(std::string(host_id));
    }
    // 建空 host 表（幂等；install_dynamic_call 时调用）
    void ensure_host(std::string_view host_id)
    {
        std::unique_lock lock(mu_);
        hosts_.try_emplace(std::string(host_id));
    }

    // ---- 查找（D1：host 表优先于全局表；D3：读锁内拷贝 handler，解锁后调用）----
    std::optional<SyncHandler> find_sync(std::string_view host_id, std::string_view name) const
    {
        std::shared_lock lock(mu_);
        const std::string key(name); // unordered_map 非透明查找，构造 key
        auto it = hosts_.find(std::string(host_id));
        if (it != hosts_.end()) {
            auto h = it->second.sync_map.find(key);
            if (h != it->second.sync_map.end())
                return h->second; // 锁内拷贝 std::function（开销可忽略）
        }
        auto g = global_sync_.find(key);
        if (g != global_sync_.end())
            return g->second;
        return std::nullopt;
    }
    std::optional<AsyncHandler> find_async(std::string_view host_id, std::string_view name) const
    {
        std::shared_lock lock(mu_);
        const std::string key(name);
        auto it = hosts_.find(std::string(host_id));
        if (it != hosts_.end()) {
            auto h = it->second.async_map.find(key);
            if (h != it->second.async_map.end())
                return h->second;
        }
        auto g = global_async_.find(key);
        if (g != global_async_.end())
            return g->second;
        return std::nullopt;
    }

private:
    Registry() = default;

    struct HostTable {
        std::unordered_map<std::string, SyncHandler> sync_map;
        std::unordered_map<std::string, AsyncHandler> async_map;
    };

    mutable std::shared_mutex mu_; // 注册/注销/查表共用
    std::unordered_map<std::string, SyncHandler> global_sync_;
    std::unordered_map<std::string, AsyncHandler> global_async_;
    std::unordered_map<std::string, HostTable> hosts_;
};

// ---- 注册 / 注销顶层 API（设计文档 §3.2；全部转发到单例）----
inline void register_global(std::string name, SyncHandler fn)
{
    Registry::instance().register_global(std::move(name), std::move(fn));
}
inline void register_global_async(std::string name, AsyncHandler fn)
{
    Registry::instance().register_global_async(std::move(name), std::move(fn));
}
inline void unregister_global(std::string_view name)
{
    Registry::instance().unregister_global(name);
}
inline void register_host(std::string_view host_id, std::string name, SyncHandler fn)
{
    Registry::instance().register_host(host_id, std::move(name), std::move(fn));
}
inline void register_host_async(std::string_view host_id, std::string name, AsyncHandler fn)
{
    Registry::instance().register_host_async(host_id, std::move(name), std::move(fn));
}
inline void unregister_host(std::string_view host_id, std::string_view name)
{
    Registry::instance().unregister_host(host_id, name);
}
// host 表生命周期（设计文档 §6）：Runtime 析构时调用；context.hpp 有前向声明
inline void remove_host(std::string_view host_id)
{
    Registry::instance().remove_host(host_id);
}

// ================= 业务辅助 =================
namespace detail {

// 构造普通 Error 并设置 message（设计文档 §7：not found 抛 Error 而非 InternalError）
inline JSValue new_error(JSContext* ctx, const std::string& msg)
{
    JSValue err = JS_NewError(ctx);
    JSValue m = JS_NewStringLen(ctx, msg.data(), msg.size());
    JS_SetPropertyStr(ctx, err, "message", m); // 转移所有权
    return err;
}

// 把 Rest<Value> 参数序列化为 JSON 数组字符串（"[a,b,c]"）。
// 失败返回 false 且异常已设置（循环引用等 → TypeError，设计文档 §2/§7）。
// 注：数组内的 function/symbol 按 JSON.stringify 标准语义变 null 而非抛错；
// 「不可序列化」的真正报错路径是循环引用。
inline bool stringify_values(JSContext* ctx, const Rest<Value>& args, std::string& out)
{
    JSValue arr = JS_NewArray(ctx);
    if (JS_IsException(arr))
        return false;
    for (std::size_t i = 0; i < args.size(); ++i)
        JS_SetPropertyUint32(ctx, arr, static_cast<uint32_t>(i),
                             JS_DupValue(ctx, args[i].raw()));
    JSValue json = JS_JSONStringify(ctx, arr, JS_UNDEFINED, JS_UNDEFINED);
    JS_FreeValue(ctx, arr);
    if (JS_IsException(json))
        return false; // 异常已设置，直接透传
    auto s = Context(ctx).js_string(json); // 值语义提取
    JS_FreeValue(ctx, json);
    if (!s)
        return false; // 异常已设置
    out = std::move(*s);
    return true;
}

// ---- Promise 结算 hooks（async 专用：成功路径改为 JSON parse）----
// 所有权管理 / reject / reject_abort 全部继承 promise_hooks（promise.hpp），
// 只把 resolve(std::string) 重定义为 resolve_json（handler 返回的 JSON 字符串
// 解析成 JS 值；非法 JSON → reject SyntaxError）。
class async_json_hooks : public promise_hooks {
public:
    using promise_hooks::promise_hooks;

    void resolve(const std::string& json) const
    {
        resolve_json(json);
    }
};

// ---- async handler → Promise：task 由调用方 Runtime spawn（设计文档 §6.3）----
// 骨架复用 settle_from_sender（promise.hpp）：continues_on 拉回 JS 线程 →
// parse + resolve / reject / reject AbortError 三路收尾。
inline JSValue spawn_async(JSContext* ctx, std::string host_id, std::string name,
                           std::string json_args, AsyncHandler fn)
{
    // 先调 handler 拿 task（惰性：协程体在 spawn start 时于 JS 线程执行到首个
    // 挂起点）。注意必须在此处调用：若 handler 调用本身抛异常（如 std::function
    // 目标缺失、非协程函数直接 throw），异常传播给 thunk 出口捕获，此时尚未
    // 创建 promise，不会泄漏 resolving/promise 引用。
    std_exec::task<std::string> task =
        fn(std::move(host_id), std::move(name), std::move(json_args));
    return settle_from_sender<decltype(task), async_json_hooks>(ctx, std::move(task));
}

// ---- async 未注册：Promise reject Error（设计文档 §7）----
inline JSValue reject_not_found(JSContext* ctx, const std::string& host_id,
                                const std::string& name)
{
    JSValue resolving[2];
    JSValue promise = JS_NewPromiseCapability(ctx, resolving);
    if (JS_IsException(promise))
        return promise;
    JSValue err = new_error(ctx, "dyn_call: '" + name + "' not found (host '" + host_id + "')");
    JS_Call(ctx, resolving[1], JS_UNDEFINED, 1, &err);
    JS_FreeValue(ctx, err);
    JS_FreeValue(ctx, resolving[0]);
    JS_FreeValue(ctx, resolving[1]);
    return promise;
}

} // namespace detail

// ================= 接入入口（设计文档 §3.3）=================
// 给该 Runtime 的主 context 装上 call / callSync 两个全局函数，按 rt.id() 建好
// host 表。注册走 qjs::func()/Object::set：lambda 值捕获 host_id（closure_holder
// 持有，finalize 自动释放，无需手写 opaque）；参数转换（name 的 ToString 语义、
// Rest<Value> 收变长参数）、arity（name 必需）与异常边界（js_error/type_error/
// std::exception 全捕获）由 invoke_impl 提供。
// 幂等：重复 install 不报错（重新覆盖全局函数，host 表已存在则复用）。
inline void install_dynamic_call(qjs::Context& ctx)
{
    Runtime& rt = runtime_of(ctx.raw());
    Registry::instance().ensure_host(rt.id());
    const std::string host_id = rt.id(); // 捕获进 lambda，之后 JS 调用自动携带
    Object global = ctx.globals();

    // ---- sync（callSync）：内联执行，同步返回 ----
    global.set("callSync", [host_id](Ctx cx, std::string name, Rest<Value> args) -> Value {
        Context c(cx.ctx);
        std::string json;
        if (!detail::stringify_values(c.raw(), args, json))
            throw js_error(cx.ctx, JS_GetException(cx.ctx)); // 循环引用等 → TypeError
        // 查找：host.sync → global.sync（D1）
        auto h = Registry::instance().find_sync(host_id, name);
        if (!h)
            // invoke_impl 捕获 js_error → JS_Throw（设计文档 §7：Error 而非 InternalError）
            throw js_error(cx.ctx, detail::new_error(
                cx.ctx, "dyn_call: '" + name + "' not found (host '" + host_id + "')"));
        // sync handler 在调用方 JS 线程内联执行（§6.2）；抛异常 → invoke_impl 出口捕获
        std::string result = (*h)(host_id, name, json);
        JSValue v = JS_ParseJSON(cx.ctx, result.c_str(), result.size(), "<dyn_call>");
        if (JS_IsException(v))
            throw js_error(cx.ctx, JS_GetException(cx.ctx)); // 非法 JSON → SyntaxError
        return Value(cx.ctx, v);
    });

    // ---- async（call）：返回 Promise（设计文档 §2/§4/§6.3）----
    global.set("call", [host_id](Ctx cx, std::string name, Rest<Value> args) -> Value {
        Context c(cx.ctx);
        std::string json;
        if (!detail::stringify_values(c.raw(), args, json))
            throw js_error(cx.ctx, JS_GetException(cx.ctx)); // 入口即失败，同步抛（§7）
        // 查找顺序：host.async → global.async（纯异步：call 返回 Promise 即真异步）
        JSValue p;
        if (auto h = Registry::instance().find_async(host_id, name))
            p = detail::spawn_async(cx.ctx, host_id, name, std::move(json), std::move(*h));
        else
            p = detail::reject_not_found(cx.ctx, host_id, name);
        if (JS_IsException(p))
            throw js_error(cx.ctx, JS_GetException(cx.ctx)); // promise 创建失败（OOM）
        return Value(cx.ctx, p);
    });
}

} // namespace dyn
} // namespace qjs
