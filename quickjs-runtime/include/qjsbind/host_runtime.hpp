// host_runtime.hpp —— 命名 bundle 实例的管理与初始化（设计文档
// docs/runtime_management_design.md）
//
// 模型：每个 bundle id 一个实例（线程 + Runtime + TaskRunner）。实例内普通
// call 为 **IO 并发**：事件循环常转，任务 begin 后不等待、立即取下一条命令，
// 多任务在同一 Runtime 的 io 上交替推进（fetch/定时器场景几百个在飞也没问题）。
// 屏障命令（debug call / reload / run_gc）需等在飞任务全部结算后才执行；
// debug 任务执行期间普通 call 排队（debug 强制串行：一个个跑，便于轮询与取消）。
// 五消息生命周期：
//   init(id, source)                    建实例（编译验证 + 加载失败即报错）
//   call(id, fn_path, args[, bundle])   返回 task_handle；带 bundle = 先热重载
//                                       再执行（debug 模式，屏障 + 串行）
//   reload(id, source)                  原子替换：先编译验证、先建后拆；
//                                       一次性结算（reload_receipt），不可取消
//   cancel(id, task_id)                 队列中摘除 / 运行中断（TaskRunner 三路取消）
//   stop(id)                            排干命令后回收实例（在飞任务：io 排空后
//                                       以 runtime_stopped 强制结算，回收有界）
//
// 返回协议（§2/§3）：统一 std::string。顶层二进制经 native buffer 池
// （BlobStore）传输，settle 负载 "\x00buf:"+id，wait() 取件（消费）交付原始字节；
// 其余为 JSON 文本（嵌套二进制 base64）。入参方向：put_buffer + {"$buf":id} 占位。
//
// 内建 fetch（Options.enable_fetch）：每实例自动装配全套 Web API；Client 在
// 实例线程构造/析构、先于实例 Runtime 销毁、reload 随旧 Runtime 回收重建，
// 调用方零管理（手工挂 Client 的三连约束见设计文档 §四）。
//
// 线程约定：init/call/reload/cancel/stop 任意线程可调；Runtime/TaskRunner 恒在
// 实例线程构造与析构（TLS 亲和）。锁序：host 锁 → runner 锁（与 TaskPool 一致）。
// 唤醒纪律：命令入队/退出标志/stats 之外的共享状态变更都在 host 锁内完成，
// 并随即将 noop post 到当前 rt->io()（reload 的 rt 替换也在同一把锁内 +
// 向新 io 补 post），实例循环阻塞在 run_one 时不会丢唤醒。
// 注意：task_handle::wait() 的协程在实例线程上恢复（结算发生在此），恢复后
// 不得直接调用 stop/shutdown 等会 join 实例线程的操作（自我 join = UB），
// 需要时请 post 到其他线程执行。
#pragma once

#include <qjsbind/qjsbind.hpp> // Runtime 析构钩子（dyn::remove_host 等）符号需要
#include <qjsbind/polyfill/bundle_dispatcher.hpp>
#include <qjsbind/polyfill/crypto.hpp> // Breeze 风格 crypto API（BoringSSL EVP，stdexec 异步）
#include <qjsbind/polyfill/runtime_api.hpp> // Breeze 风格运行时 API（base64/native/runtime/opencc/Buffer）
#include <qjsbind/task.hpp>
#include <qjsbind/web/web.hpp> // enable_fetch：install_web_apis + fetch::Client

#include <glaze/glaze.hpp> // 错误载荷 JSON（err_wire）
#include <stdexec/execution.hpp>

#include <atomic>
#include <cstdint>
#include <cstring>
#include <deque>
#include <expected>
#include <future>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>

namespace qjs {

// ---- 错误通道（设计文档 §6.2）----
enum class runtime_errc {
    bundle_not_found,   // call/reload/stop 了未 init 的 id
    bundle_exists,      // init 了重复的 id
    compile_failed,     // bundle 编译失败（reload/debug 重载时旧代码保留）
    function_not_found, // fn_path 解析不到导出函数
    invalid_args,       // 参数非法（不是合法 JSON / buffer id 失效等）
    task_cancelled,     // wait 时任务已被 cancel
    runtime_stopped,    // stop 之后通道关闭 / 排干结算
    js_exception,       // 脚本执行抛异常（message 带格式化栈）
};

struct runtime_error {
    runtime_errc code;
    std::string message; // 人类可读；js_exception/compile_failed 时带 JS 栈
};

using runtime_result = std::expected<std::string, runtime_error>;

namespace detail {

// 顶层二进制传输前缀（含前导 NUL，与 JSON 文本不可能撞车）：
// settle 负载为 "\x00buf:" + BlobStore 条目 id（native buffer 池，消费语义）
inline constexpr std::string_view kBufPrefix{"\0buf:", 5};
// 结构化错误载荷前缀："@@errj:" + JSON(err_wire)（dispatcher JS 侧与本层产出）
inline constexpr std::string_view kErrPrefix = "@@errj:";

// 错误线协议：c=程序码（映射 runtime_errc） n=错误名（TypeError 等）
//             m=消息 s=栈（已 remap） g=调用上下文（bundle/fn/args/source）
// 字段名与 dispatcher JS 的 errorPayload 一致（glaze 按成员名反射）
struct err_wire {
    std::string c, n, m, s, g;
};

// FNV-1a-64（与 TaskPool 快照同款）：content hash 跳过重载用
inline uint64_t fnv1a64(std::string_view s)
{
    uint64_t h = 1469598103934665603ull;
    for (unsigned char c : s) {
        h ^= c;
        h *= 1099511628211ull;
    }
    return h;
}

inline runtime_errc errc_from_code(std::string_view code)
{
    if (code == "function_not_found") return runtime_errc::function_not_found;
    if (code == "invalid_args") return runtime_errc::invalid_args;
    if (code == "compile_failed") return runtime_errc::compile_failed;
    if (code == "bundle_not_found") return runtime_errc::bundle_not_found;
    if (code == "runtime_stopped") return runtime_errc::runtime_stopped;
    if (code == "task_cancelled") return runtime_errc::task_cancelled;
    return runtime_errc::js_exception;
}

// Node 风格拼装：首行 "Name: message"；scope 以 "[scope] " 前缀；
// stack 首行已含消息则直接用 stack（Node 惯例），否则 message\nstack。
// include_stack=false：只给消息首行（面向终端用户的简洁错误）。
inline std::string format_node_style(const err_wire& w, bool include_stack)
{
    std::string first = (w.n.empty() ? "Error" : w.n) + ": " + w.m;
    std::string scoped = w.g.empty() ? first : "[" + w.g + "] " + first;
    if (!include_stack) {
        if (const auto nl = scoped.find('\n'); nl != std::string::npos)
            scoped.resize(nl);
        return scoped;
    }
    if (w.s.empty())
        return scoped;
    if (w.s.starts_with(first))
        return w.g.empty() ? w.s : "[" + w.g + "] " + w.s;
    return scoped + "\n" + w.s;
}

// 把 TaskResult 的错误文本映射为 runtime_error（结构化载荷 → errc + Node 风格文本）
inline runtime_error decode_error(std::string msg, bool include_stack = true)
{
    if (msg == "cancelled")
        return {runtime_errc::task_cancelled, std::move(msg)};
    if (msg.starts_with(kErrPrefix)) {
        err_wire w{};
        const auto json = std::string_view(msg).substr(kErrPrefix.size());
        if (glz::read_json(w, json))
            return {runtime_errc::js_exception, std::move(msg)}; // 载荷损坏：原样透传
        return {errc_from_code(w.c), format_node_style(w, include_stack)};
    }
    return {runtime_errc::js_exception, std::move(msg)};
}

inline std::string sentinel(std::string_view code, std::string_view msg)
{
    err_wire w{std::string(code), "Error", std::string(msg), {}, {}};
    return std::string(kErrPrefix) + glz::write_json(w).value_or("{}");
}

// 产出 sentinel 用的码名（仅本层会产生的码）
inline std::string_view errc_name(runtime_errc c)
{
    switch (c) {
    case runtime_errc::compile_failed: return "compile_failed";
    case runtime_errc::js_exception: return "js_exception";
    case runtime_errc::runtime_stopped: return "runtime_stopped";
    default: return "js_exception";
    }
}

} // namespace detail

// ---- 调用句柄：wait() 为唯一结算方式（异步，co_await 获取结果）----
struct task_handle {
    std::string instance; // cancel 定位用
    uint64_t id = 0;
    co::oneshot::Receiver<TaskResult> rx; // 原始编码通道（高级用法）
    bool include_stack = true;            // 错误文本是否带栈（HostRuntime 选项）
    std::string buf_bucket;               // 本实例的 BlobStore 桶（顶层二进制取件用）

    // 异步等待一次性结算（stdexec::task，co_await 获取结果，不阻塞调用线程）：
    // ok → std::string（顶层二进制经 buffer 池取原始字节交付）。
    // 注意：结算发生在实例线程，协程在该线程上恢复解码后即返回；
    // 调用方若在事件循环/协程中等待，不会卡住任何线程。
    stdexec::task<runtime_result> wait()
    {
        auto res = co_await std::move(rx); // optional<TaskResult>；close → nullopt
        if (!res)
            co_return std::unexpected(runtime_error{
                runtime_errc::runtime_stopped, "instance stopped (channel closed)"});
        TaskResult r = std::move(*res);
        if (!r.ok)
            co_return std::unexpected(detail::decode_error(std::move(r.json), include_stack));
        if (r.json.starts_with(detail::kBufPrefix)) {
            const auto bid = r.json.substr(detail::kBufPrefix.size());
            auto& store = dyn::BlobStore::instance();
            auto data = store.get(buf_bucket, bid);
            if (!data)
                co_return std::unexpected(runtime_error{
                    runtime_errc::js_exception,
                    "internal error: native buffer missing or expired"});
            store.remove(buf_bucket, bid); // 消费
            co_return std::string(reinterpret_cast<const char*>(data->data()), data->size());
        }
        co_return r.json;
    }
};

// ---- reload 回执：一次性结算，无 start/cancel（设计文档 §5）----
// reload / run_gc 共用（同为一次性结算的管理操作）
struct op_receipt {
    co::oneshot::Receiver<TaskResult> rx;
    bool include_stack = true; // 错误文本是否带栈（HostRuntime 选项）

    // 异步等待一次性结算（同 task_handle::wait 的协程语义）
    stdexec::task<std::expected<void, runtime_error>> wait()
    {
        auto res = co_await std::move(rx); // optional<TaskResult>；close → nullopt
        if (!res)
            co_return std::unexpected(runtime_error{
                runtime_errc::runtime_stopped, "instance stopped (channel closed)"});
        TaskResult r = std::move(*res);
        if (!r.ok)
            co_return std::unexpected(detail::decode_error(std::move(r.json), include_stack));
        co_return std::expected<void, runtime_error>{};
    }
};
using reload_receipt = op_receipt; // 兼容命名

// ---- 诊断计数（stats()）：每实例一份，累计值随实例生命周期 ----
struct instance_stats {
    std::string id;
    uint64_t queued = 0;         // 当前队列深度（call + reload 命令）
    bool busy = false;           // 是否有任务在执行
    uint64_t submitted = 0;      // 累计入队 call 数
    uint64_t completed = 0;      // 累计成功结算
    uint64_t failed = 0;         // 累计失败结算（含 stop 排干、debug 重载失败）
    uint64_t cancelled = 0;      // 累计取消（队列摘除 + Running 取消）
    uint64_t reloads_ok = 0;      // 累计热重载成功（reload + debug call 携带）
    uint64_t reloads_failed = 0;  // 累计热重载失败（旧代码保留）
    uint64_t reloads_skipped = 0; // 累计 content hash 未变跳过的重载
};

struct host_stats {
    std::vector<instance_stats> instances;
};

class HostRuntime {
public:
    // 宿主可重放的 native 绑定注册入口（每实例 / 每次 reload 走同一函数）
    using RegisterAllFn = std::function<void(Context&)>;

    struct Options {
        RegisterAllFn register_all;    // 宿主 native 绑定（在内建 Web API 之后执行）
        bool include_stack = true;     // 错误文本是否带栈（Node 风格）
        // 每实例内建 Web API（fetch/URL/Headers/timers/blob/stream…）：
        // Client 在实例线程构造、实例线程析构、先于实例 Runtime 销毁，
        // reload 随旧 Runtime 一并回收重建——调用方无需管理其生命周期
        bool enable_fetch = false;
        fetch::Options fetch_opts{};   // enable_fetch 时生效（TLS/连接池/DNS/代理等）
    };

    explicit HostRuntime(Options opt)
        : register_all_(std::move(opt.register_all)), include_stack_(opt.include_stack),
          enable_fetch_(opt.enable_fetch), fetch_opts_(std::move(opt.fetch_opts))
    {
    }
    // include_stack：错误文本是否带栈（Node 风格；false = 只给消息首行）
    explicit HostRuntime(RegisterAllFn register_all = {}, bool include_stack = true)
        : HostRuntime(Options{std::move(register_all), include_stack})
    {
    }
    ~HostRuntime() { shutdown(); }

    HostRuntime(const HostRuntime&) = delete;
    HostRuntime& operator=(const HostRuntime&) = delete;

    // ---- init：建实例（实例线程就绪握手，失败即报错且不留实例）----
    std::expected<void, runtime_error> init(std::string id, std::string source)
    {
        auto w = std::make_unique<instance>();
        w->id = id;
        std::promise<std::expected<void, runtime_error>> ready;
        auto fut = ready.get_future();
        {
            std::lock_guard lock(mu_);
            if (instances_.count(id))
                return std::unexpected(
                    runtime_error{runtime_errc::bundle_exists, "bundle already initialized: " + id});
            instance* wp = w.get();
            w->thread = std::thread(&HostRuntime::instance_main, this, wp,
                                    std::move(source), std::move(ready));
            instances_.emplace(id, std::move(w));
        }
        auto r = fut.get(); // 等实例线程完成 Runtime 构造 + bundle 加载
        if (!r) {
            // 加载失败：实例线程已退出，摘表并 join
            std::unique_ptr<instance> doomed;
            {
                std::lock_guard lock(mu_);
                auto it = instances_.find(id);
                doomed = std::move(it->second);
                instances_.erase(it);
            }
            if (doomed->thread.joinable())
                doomed->thread.join();
            return std::unexpected(std::move(r.error()));
        }
        return {};
    }

    // ---- call：入队即返句柄；带 bundle = debug（先热重载再执行）----
    // args_json 约定：JSON 文本整体 parse 后作为唯一参数传给目标函数
    // （命名参数风格 {"a":1,"b":2} → fn({a:1,b:2})）；二进制经 put_buffer 得 id
    // 后嵌 {"$buf":id} 占位；signal（AbortSignal）由运行时追加为第二参数
    std::expected<task_handle, runtime_error> call(std::string_view id,
                                                   std::string fn_path,
                                                   std::string args_json,
                                                   std::optional<std::string> bundle = std::nullopt)
    {
        auto [tx, rx] = co::oneshot::channel<TaskResult>();
        const uint64_t task_id = next_id_.fetch_add(1);
        std::lock_guard lock(mu_);
        auto it = instances_.find(std::string(id));
        if (it == instances_.end())
            return std::unexpected(runtime_error{runtime_errc::bundle_not_found,
                                                 "bundle not initialized: " + std::string(id)});
        instance& w = *it->second;
        w.stats.submitted++;
        w.queue.push_back(command{cmd_kind::call, task_id, std::move(fn_path),
                                  std::move(args_json), std::move(bundle), std::move(tx)});
        wakeup(w); // 锁内 post：与 rt 替换同锁，杜绝丢失唤醒
        return task_handle{std::string(id), task_id, std::move(rx), include_stack_,
                           buf_bucket_of(id)};
    }

    // ---- put_buffer：host→JS 二进制入参。返回 id，args JSON 任意深度嵌
    // {"$buf": "<id>"} 占位，调用前由 dispatcher 物化为 Uint8Array（消费语义）----
    std::expected<std::string, runtime_error> put_buffer(std::string_view id,
                                                         std::string bytes)
    {
        {
            std::lock_guard lock(mu_);
            if (!instances_.count(std::string(id)))
                return std::unexpected(runtime_error{
                    runtime_errc::bundle_not_found,
                    "bundle not initialized: " + std::string(id)});
        }
        std::vector<std::byte> v(bytes.size());
        if (!bytes.empty())
            std::memcpy(v.data(), bytes.data(), bytes.size());
        return dyn::BlobStore::instance().put(buf_bucket_of(id), std::move(v));
    }

    // ---- reload：原子替换，一次性结算（不可取消）----
    std::expected<reload_receipt, runtime_error> reload(std::string_view id, std::string source)
    {
        auto [tx, rx] = co::oneshot::channel<TaskResult>();
        std::lock_guard lock(mu_);
        auto it = instances_.find(std::string(id));
        if (it == instances_.end())
            return std::unexpected(runtime_error{runtime_errc::bundle_not_found,
                                                 "bundle not initialized: " + std::string(id)});
        instance& w = *it->second;
        w.queue.push_back(command{cmd_kind::reload, 0, {}, {}, std::move(source), std::move(tx)});
        wakeup(w);
        return reload_receipt{std::move(rx), include_stack_};
    }

    // ---- run_gc：在实例任务间隙执行一次 JS_RunGC（一次性结算，不可取消）----
    std::expected<op_receipt, runtime_error> run_gc(std::string_view id)
    {
        auto [tx, rx] = co::oneshot::channel<TaskResult>();
        std::lock_guard lock(mu_);
        auto it = instances_.find(std::string(id));
        if (it == instances_.end())
            return std::unexpected(runtime_error{runtime_errc::bundle_not_found,
                                                 "bundle not initialized: " + std::string(id)});
        instance& w = *it->second;
        w.queue.push_back(command{cmd_kind::run_gc, 0, {}, {}, std::nullopt, std::move(tx)});
        wakeup(w);
        return op_receipt{std::move(rx), include_stack_};
    }

    // ---- cancel：队列中摘除 / 运行中走 TaskRunner 三路取消；幂等 ----
    bool cancel(std::string_view id, uint64_t task_id)
    {
        std::lock_guard lock(mu_);
        auto it = instances_.find(std::string(id));
        if (it == instances_.end())
            return false;
        instance& w = *it->second;
        for (auto q = w.queue.begin(); q != w.queue.end(); ++q) {
            if (q->kind == cmd_kind::call && q->task_id == task_id) {
                auto tx = std::move(q->tx);
                w.queue.erase(q);
                w.stats.cancelled++;
                tx.send(TaskResult{false, "cancelled"}); // 锁内 send 仅置结果，安全
                return true;
            }
        }
        if (!w.in_flight.count(task_id))
            return false; // 不存在或已结算
        // ★ 锁序 host→runner（与 TaskPool::cancel 一致）。在飞任务经
        // register_running 登记（无 Queued 窗口），cancel 恒走
        // "post 闭包 + interrupt"，不会在调用线程上内联结算
        return w.runner->cancel(task_id);
    }
    bool cancel(const task_handle& h) { return cancel(h.instance, h.id); }

    // ---- stop：排干命令后回收实例（在飞任务：io 排空后以 runtime_stopped
    // 强制结算，回收时间有界——永不结算的任务不会卡住 stop）----
    std::expected<void, runtime_error> stop(std::string_view id)
    {
        std::unique_ptr<instance> doomed;
        {
            std::lock_guard lock(mu_);
            auto it = instances_.find(std::string(id));
            if (it == instances_.end())
                return std::unexpected(runtime_error{
                    runtime_errc::bundle_not_found, "bundle not initialized: " + std::string(id)});
            doomed = std::move(it->second);
            instances_.erase(it);
            doomed->exit = true; // 实例循环排干队列后退出（在飞任务见上）
            wakeup(*doomed);     // 锁内 post：唤醒阻塞在 run_one 的实例循环
        }
        if (doomed->thread.joinable())
            doomed->thread.join(); // Runtime/TaskRunner 已在实例线程析构
        dyn::BlobStore::instance().remove_host(buf_bucket_of(id)); // buffer 桶回收
        return {};
    }

    std::vector<std::string> list() const
    {
        std::lock_guard lock(mu_);
        std::vector<std::string> out;
        out.reserve(instances_.size());
        for (auto& [id, _] : instances_)
            out.push_back(id);
        return out;
    }

    // 诊断快照：计数器为实例生命周期的累计值（reload 不清零）
    host_stats stats() const
    {
        std::lock_guard lock(mu_);
        host_stats out;
        out.instances.reserve(instances_.size());
        for (auto& [id, w] : instances_) {
            instance_stats s = w->stats;
            s.id = id;
            s.queued = w->queue.size();
            s.busy = !w->in_flight.empty();
            out.instances.push_back(std::move(s));
        }
        return out;
    }

    void shutdown()
    {
        for (;;) {
            std::string id;
            {
                std::lock_guard lock(mu_);
                if (instances_.empty())
                    return;
                id = instances_.begin()->first;
            }
            (void)stop(id);
        }
    }

private:
    enum class cmd_kind { call, reload, run_gc };
    struct command {
        cmd_kind kind;
        uint64_t task_id = 0;                // call 专用
        std::string fn_path;                 // call 专用
        std::string args_json;               // call 专用
        std::optional<std::string> bundle;   // call(debug)/reload 的新源码
        co::oneshot::Sender<TaskResult> tx;
    };
    struct instance {
        std::string id;
        std::thread thread;
        // 以下恒在实例线程构造/析构（TLS 亲和）
        std::unique_ptr<Runtime> rt;
        std::unique_ptr<TaskRunner> runner;
        // 仅实例线程访问（init/reload/teardown）：后于 rt 构造（io 取自实例
        // 线程 thread_local）、先于 rt 析构（连接池/DNS 绑定实例 io，且有
        // io 线程断言）
        std::shared_ptr<fetch::Client> client;
        std::string source;            // 当前 bundle 源码（诊断）
        uint64_t source_hash = 0;      // 当前 bundle 的 FNV-1a（content hash 跳过重载）
        // 事件循环保活：实例线程 run_one 阻塞等唤醒的根基；reload 换 rt 时随迁
        std::optional<boost::asio::executor_work_guard<boost::asio::io_context::executor_type>>
            guard;
        // ---- 以下受 host 锁保护（锁序 host→runner）----
        std::deque<command> queue;
        bool exit = false;
        std::unordered_set<uint64_t> in_flight; // 已开始未结算的 call（IO 并发）
        bool debug_active = false;              // debug 任务执行中：普通 call 排队（串行）
        uint64_t debug_id = 0;                  // 当前 debug 任务 id
        instance_stats stats; // 计数器（host 锁内维护；id/queued/busy 字段不用）
    };

    static std::string buf_bucket_of(std::string_view id)
    {
        return "hbuf:" + std::string(id);
    }
    // 唤醒实例循环（可能正阻塞在 io.run_one）。必须在 host 锁内调用：
    // 与 reload 的 rt 替换同锁，noop 必达当前 rt，杜绝丢失唤醒
    static void wakeup(instance& w) { boost::asio::post(w.rt->io(), [] {}); }
    // TaskRunner 结算钩子：统计 + 清在飞/屏障标记（恒在实例线程触发）
    void install_settle_hook(instance& w, TaskRunner& runner);
    // 实例线程上安装 API：先内建 Web API（enable_fetch，Client 就地建仓到
    // client_slot），再宿主 register_all_；抛异常由调用方映射错误
    void setup_apis(Runtime& rt, std::shared_ptr<fetch::Client>& client_slot) const;
    // 委托给共用加载器（bundle_dispatcher.hpp 的 load_bundle_source），映射 errc
    std::optional<runtime_error> load_bundle(Context ctx, const std::string& source,
                                             const std::string& name);
    // 实例线程上的原子替换（先建后拆）；成功返回 nullopt，失败保留旧实例
    std::optional<runtime_error> reload_instance(instance& w, const std::string& source);
    void instance_main(instance* w, std::string source,
                       std::promise<std::expected<void, runtime_error>> ready);
    // 从队列取一条可启动的命令并执行（启动 call / 屏障命令），无则返回 false
    bool try_dispatch(instance& w);
    void exec_call(instance& w, command cmd);   // 普通 call：登记即并发启动
    void exec_reload(instance& w, command cmd); // reload：屏障内原子替换

    RegisterAllFn register_all_;
    bool include_stack_ = true; // 错误文本是否带栈（写入每个句柄/回执）
    bool enable_fetch_ = false; // 每实例内建 Web API + Client（见 Options）
    fetch::Options fetch_opts_{};
    std::atomic<uint64_t> next_id_{1};
    mutable std::mutex mu_; // instances_ + 各 instance 的 queue/exit/current_task
    std::unordered_map<std::string, std::unique_ptr<instance>> instances_;
};

// ================= 实现 =================

// 委托给共用加载器（与 TaskPool 同一路径）；compile_phase → compile_failed
inline std::optional<runtime_error> HostRuntime::load_bundle(Context ctx,
                                                             const std::string& source,
                                                             const std::string& name)
{
    if (auto err = load_bundle_source(ctx, source, name))
        return runtime_error{err->compile_phase ? runtime_errc::compile_failed
                                                : runtime_errc::js_exception,
                             std::move(err->message)};
    return std::nullopt;
}

inline std::optional<runtime_error> HostRuntime::reload_instance(instance& w,
                                                                 const std::string& source)
{
    Runtime* prev_tls = tls_current_runtime; // 失败时恢复（构造会把 TLS 绑到新实例）
    auto new_rt = std::make_unique<Runtime>("host:" + w.id);
    // 声明在 new_rt 之后：任何失败路径下局部逆序析构，client 恒先于 rt 销毁
    std::shared_ptr<fetch::Client> new_client;
    auto fail = [&](runtime_error err) -> std::optional<runtime_error> {
        tls_current_runtime = prev_tls; // new_rt 在本线程析构（TLS == this 保护）
        return err;
    };
    try {
        setup_apis(*new_rt, new_client); // 内建 Web API（可选）+ 宿主 register_all
    } catch (const std::exception& e) {
        return fail({runtime_errc::js_exception,
                     std::string("API install failed: ") + e.what()});
    }
    auto new_runner = std::make_unique<TaskRunner>(*new_rt);
    install_settle_hook(w, *new_runner); // 结算钩子随迁（统计/在飞/屏障标记）
    try {
        Context c = new_rt->main_context();
        install_bundle_dispatcher(c, buf_bucket_of(w.id));
    } catch (const std::exception& e) {
        return fail({runtime_errc::js_exception,
                     std::string("dispatcher install failed: ") + e.what()});
    }
    if (auto err = load_bundle(new_rt->main_context(), source, w.id))
        return fail(std::move(*err));

    // 先建后拆：替换段持 host 锁（cancel 在锁内读 w.runner，二者互斥）。
    // 屏障保证此刻无在飞任务（in_flight 空），旧 runner 的注册表已空。
    w.rt->io().poll(); // 排空旧 io 残余 handler
    w.guard.reset();   // 旧 io 的保活随旧 rt 析构前解除
    std::unique_ptr<TaskRunner> old_runner;
    std::shared_ptr<fetch::Client> old_client;
    std::unique_ptr<Runtime> old_rt;
    {
        std::lock_guard lock(mu_);
        old_runner = std::move(w.runner);
        old_client = std::move(w.client);
        old_rt = std::move(w.rt);
        w.runner = std::move(new_runner);
        w.client = std::move(new_client);
        w.rt = std::move(new_rt);
        w.source = source;
        w.source_hash = detail::fnv1a64(source);
        w.guard.emplace(w.rt->io().get_executor()); // 新 io 保活
        wakeup(w);                   // 向新 io 补 noop：换 rt 前的入队不丢唤醒
    }
    // 锁外析构：runner 必须先于 rt（其析构访问 rt_.raw() 卸 interrupt handler）；
    // client 必须先于 rt（连接池/DNS 绑定旧 io，且有 io 线程断言）
    old_runner.reset();
    old_client.reset();
    old_rt.reset();
    return std::nullopt;
}

inline void HostRuntime::setup_apis(Runtime& rt,
                                    std::shared_ptr<fetch::Client>& client_slot) const
{
    Context c = rt.main_context();
    if (enable_fetch_) {
        // 本函数恒在实例线程调用：Client 的 io 取自当前线程 thread_local
        // （Runtime 构造时已绑定实例 io）
        client_slot = std::make_shared<fetch::Client>(fetch_opts_);
        qjsbind::web::install_web_apis(c, *client_slot);
    }
    // Breeze 风格运行时 API（内建，不依赖 enable_fetch_）：base64/native/
    // runtime/opencc/Buffer。native_put/native_get/__native_b64encode 等既有
    // 能力若未安装，polyfill 侧自动降级（见 runtime_api.js 头部注释）。
    install_runtime_api(c);
    // Breeze 风格 crypto API（内建，BoringSSL EVP；crypto/hostCrypto/
    // nodeCryptoCompat 全局；Promise 方法走 fetch::file_pool 后台线程池）
    install_crypto(c);
    if (register_all_)
        register_all_(c);
}

inline void HostRuntime::install_settle_hook(instance& w, TaskRunner& runner)
{
    // 恒在实例线程触发（全部任务经 register_running 登记，无 Queued 内联结算
    // 路径）；host 锁内更新统计与调度标记。无需额外 wakeup：结算本身发生在
    // io handler / pump 内，循环每轮都会重新 try_dispatch
    runner.on_settle = [this, &w](uint64_t id, bool ok, bool cancelled) {
        std::lock_guard lock(mu_);
        w.in_flight.erase(id);
        if (ok)
            w.stats.completed++;
        else if (cancelled)
            w.stats.cancelled++;
        else
            w.stats.failed++;
        if (w.debug_active && w.debug_id == id) { // debug 任务结束：解除串行屏障
            w.debug_active = false;
            w.debug_id = 0;
        }
    };
}

inline void HostRuntime::exec_reload(instance& w, command cmd)
{
    // content hash 未变：跳过重载（不重建实例，模块状态保留）
    if (detail::fnv1a64(*cmd.bundle) == w.source_hash && *cmd.bundle == w.source) {
        {
            std::lock_guard lock(mu_);
            w.stats.reloads_skipped++;
        }
        cmd.tx.send(TaskResult{true, {}});
    } else if (auto err = reload_instance(w, *cmd.bundle)) {
        {
            std::lock_guard lock(mu_);
            w.stats.reloads_failed++;
        }
        cmd.tx.send(TaskResult{false, detail::sentinel(detail::errc_name(err->code),
                                                       err->message)});
    } else {
        {
            std::lock_guard lock(mu_);
            w.stats.reloads_ok++;
        }
        cmd.tx.send(TaskResult{true, {}});
    }
}

inline void HostRuntime::exec_call(instance& w, command cmd)
{
    if (cmd.bundle) { // debug：屏障已保证在飞为空；先热重载（失败保留旧代码）
        // content hash 未变：跳过重载，直接执行（模块状态保留）
        if (detail::fnv1a64(*cmd.bundle) == w.source_hash && *cmd.bundle == w.source) {
            std::lock_guard lock(mu_);
            w.stats.reloads_skipped++;
        } else if (auto err = reload_instance(w, *cmd.bundle)) {
            {
                std::lock_guard lock(mu_);
                w.stats.reloads_failed++;
                w.stats.failed++;
            }
            cmd.tx.send(TaskResult{false, detail::sentinel(detail::errc_name(err->code),
                                                           err->message)});
            return;
        } else {
            std::lock_guard lock(mu_);
            w.stats.reloads_ok++;
        }
    }
    {
        // 锁内登记 + 标记（锁序 host→runner）。登记即 Running（无 Queued 窗口），
        // cancel 恒走 post 闭包路径，on_settle 恒在实例线程触发。
        // debug 标记必须先于 begin_task 设置：begin 的同步异常兜底 settle 会
        // 触发 on_settle 清理标记，顺序反了会残留 debug_active 卡死队列
        std::lock_guard lock(mu_);
        w.runner->register_running(cmd.task_id,
                                   InvokeRequest{cmd.fn_path, cmd.args_json, false},
                                   std::move(cmd.tx));
        w.in_flight.insert(cmd.task_id);
        if (cmd.bundle) {
            w.debug_active = true;
            w.debug_id = cmd.task_id;
        }
    }
    // 本线程即 JS 线程：begin_task 内联（不等待结算——IO 并发，结果经
    // on_settle 钩子回收；调用方经 task_handle::wait 异步取结果）
    w.runner->begin_task(cmd.task_id);
}

// 从队列取一条可启动的命令并执行；无命令或遇屏障返回 false
inline bool HostRuntime::try_dispatch(instance& w)
{
    command cmd;
    {
        std::lock_guard lock(mu_);
        if (w.queue.empty())
            return false;
        const command& f = w.queue.front();
        const bool barrier = f.kind != cmd_kind::call || f.bundle.has_value();
        if (barrier) {
            // 屏障命令（debug call / reload / run_gc）：等在飞任务全部结算
            if (!w.in_flight.empty())
                return false;
        } else if (w.debug_active) {
            return false; // debug 执行期间：普通 call 排队（debug 串行）
        }
        cmd = std::move(w.queue.front());
        w.queue.pop_front();
    }
    switch (cmd.kind) {
    case cmd_kind::run_gc:
        JS_RunGC(w.rt->raw()); // 屏障内执行：无在飞任务
        cmd.tx.send(TaskResult{true, {}});
        break;
    case cmd_kind::reload:
        exec_reload(w, std::move(cmd));
        break;
    default:
        exec_call(w, std::move(cmd));
        break;
    }
    return true;
}

inline void HostRuntime::instance_main(instance* w, std::string source,
                                       std::promise<std::expected<void, runtime_error>> ready)
{
    // Runtime 在实例线程上构造与析构（TLS / 线程亲和）
    w->rt = std::make_unique<Runtime>("host:" + w->id);
    auto fail_early = [&](runtime_error err) {
        ready.set_value(std::unexpected(std::move(err)));
        w->client.reset(); // 先于 rt 析构（连接池/DNS 绑定实例 io）
        w->runner.reset();
        w->rt.reset();
    };
    try {
        setup_apis(*w->rt, w->client); // 内建 Web API（可选）+ 宿主 register_all
    } catch (const std::exception& e) {
        return fail_early({runtime_errc::js_exception,
                           std::string("API install failed: ") + e.what()});
    }
    w->runner = std::make_unique<TaskRunner>(*w->rt);
    install_settle_hook(*w, *w->runner);
    try {
        Context c = w->rt->main_context();
        install_bundle_dispatcher(c, buf_bucket_of(w->id));
    } catch (const std::exception& e) {
        return fail_early({runtime_errc::js_exception,
                           std::string("dispatcher install failed: ") + e.what()});
    }
    if (auto err = load_bundle(w->rt->main_context(), source, w->id))
        return fail_early(std::move(*err));
    w->source_hash = detail::fnv1a64(source);
    w->source = std::move(source);
    w->guard.emplace(w->rt->io().get_executor()); // 事件循环保活：run_one 阻塞等唤醒的根基
    ready.set_value(std::expected<void, runtime_error>{});

    // 主循环：pump JS job → 启动一切可启动的命令（IO 并发）→ 阻塞等事件。
    // 唤醒来源：任务 io handler / 结算回调 / 命令入队的 noop post。
    for (;;) {
        w->rt->pump_js_jobs();
        if (try_dispatch(*w))
            continue; // 有命令被启动/执行：立刻回到 pump（新 job 可能已排队）
        std::vector<uint64_t> stuck; // stop 时待强制结算的在飞任务
        bool done = false;
        {
            std::lock_guard lock(mu_);
            if (w->exit && w->queue.empty()) {
                if (w->in_flight.empty()) {
                    done = true;
                } else {
                    // stop 回收：在飞任务不再无限等（永不结算的任务会卡死
                    // join）——io 排空后以 runtime_stopped 强制结算
                    stuck.assign(w->in_flight.begin(), w->in_flight.end());
                }
            }
        }
        if (done)
            break;
        if (!stuck.empty()) {
            while (w->rt->io().poll_one() > 0) {
            } // 排空现成 handler（给在飞任务最后的结算机会）
            w->rt->pump_js_jobs();
            for (uint64_t id : stuck)
                w->runner->force_settle(
                    id, false,
                    std::string(detail::sentinel("runtime_stopped", "instance stopped")));
            continue; // on_settle 同步清空 in_flight，下一轮即 break
        }
        w->rt->io().run_one(); // guard 保活：阻塞至任意 handler（命令 noop 必唤醒）
    }
    // 排干剩余队列（stop 后竞态推入的命令以 runtime_stopped 结算）
    for (;;) {
        command cmd;
        {
            std::lock_guard lock(mu_);
            if (w->queue.empty())
                break;
            cmd = std::move(w->queue.front());
            w->queue.pop_front();
            if (cmd.kind == cmd_kind::call)
                w->stats.failed++;
        }
        cmd.tx.send(TaskResult{false, detail::sentinel("runtime_stopped",
                                                       "instance stopped before execution")});
    }
    w->guard.reset();
    // runner 先于 rt 析构（其析构访问 rt_.raw() 卸 interrupt handler）；
    // client 先于 rt 析构（连接池/DNS 绑定实例 io，且有 io 线程断言）
    w->runner.reset();
    w->client.reset();
    w->rt.reset();
}

} // namespace qjs
