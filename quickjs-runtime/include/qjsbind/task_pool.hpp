// task_pool.hpp —— Debug 任务池（扩展层 TaskPool，设计文档 docs/debug_pool_design.md）
//
// 在基础层 TaskRunner 之上叠加"多实例 + 热重载"拓扑：
//   - 懒创建、上限 max_workers（默认 20）；queue + idle + 一把 mutex（§1/§3.2）
//   - source 快照 {mtime, hash, source, version}：submit 时更新；worker 领任务时
//     比对 loaded_version != current_version（§3.2/§4）
//   - reload：先建后拆（新 Runtime 构造会把 TLS 绑到自己，旧实例析构的 TLS 清理
//     有 == this 判断保护，不误清）；加载失败保留旧实例、下个任务自动重试
//   - worker = 线程 + Runtime + TaskRunner，一实例同时只跑一个任务；worker 永不
//     调 Runtime::stop()（done_ 置位不可逆）
//   - 关闭（§7）：拒新任务 → 队列任务置 cancelled → worker 置退出 + notify →
//     join → Runtime 在各自 worker 线程上析构
//
// ★ 脚本即 bundle（与 HostRuntime 同一约定）：脚本文件按 CJS bundle 加载
//   （(function(module, exports){ ... }) 包装，module.exports 为导出表，
//   fn_path 点路径解析），参数为对象风格（argsJson 整体 parse 后作为第一参数，
//   signal 第二参数）。worker 安装 bundle dispatcher（错误栈/source map/
//   buffer 通道与 HostRuntime 行为一致）；加载走共用的 load_bundle_source。
//
// 线程约定：
//   - submit / cancel 任意线程可调；worker 在自身线程构造/析构 Runtime（TLS 亲和）。
//   - native 绑定注册必须可重放：register_all 每个新实例走同一入口（§4）。
#pragma once

#include <qjsbind/task.hpp>
#include <qjsbind/binary.hpp> // qjs::js_string（值语义字符串提取）
#include <qjsbind/polyfill/bundle_dispatcher.hpp> // install_bundle_dispatcher / load_bundle_source

#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <deque>
#include <filesystem>
#include <fstream>
#include <functional>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <unordered_map>
#include <utility>
#include <vector>

namespace qjs {

class TaskPool {
public:
    // 宿主可重放的 native 绑定注册入口（每个 worker 新实例走同一函数）
    using RegisterAllFn = std::function<void(Context&)>;

    explicit TaskPool(std::string script_path, size_t max_workers = 20,
                      RegisterAllFn register_all = {});
    ~TaskPool() { shutdown(); }
    TaskPool(const TaskPool&) = delete;
    TaskPool& operator=(const TaskPool&) = delete;
    TaskPool(TaskPool&&) = delete;
    TaskPool& operator=(TaskPool&&) = delete;

    // 非阻塞，任意线程；debug 池语义（热重载 + 池化并发）
    TaskHandle submit(InvokeRequest req);
    bool cancel(uint64_t id); // 幂等，任意线程（设计文档 §5 三路取消）
    void shutdown();          // 拒新任务；队列任务置 cancelled；join 全部 worker

    // ---- 诊断 ----
    size_t worker_count() const;      // 已创建 worker 数（懒创建，可能 < max）
    uint64_t current_version() const; // 共享快照版本
    std::string last_error() const;   // 最近一次加载/编译/注册错误

private:
    struct SourceSnapshot {
        std::string source;
        int64_t mtime = -1; // 文件最后写时间（ns）
        uint64_t hash = 0;  // FNV-1a-64
        uint64_t version = 0;
    };
    struct Task {
        uint64_t id = 0;
        InvokeRequest req;
        co::oneshot::Sender<TaskResult> tx;
    };
    struct Worker {
        std::thread thread;
        std::unique_ptr<Runtime> rt;       // worker 线程构造/析构（TLS 亲和）
        std::unique_ptr<TaskRunner> runner;
        std::optional<Task> slot_;         // 交接槽（submit 直接交接）
        std::condition_variable cv;
        bool idle_marked = false;          // 池锁内使用
        bool exit = false;                 // 池锁内使用
        uint64_t loaded_version = 0;       // worker 侧仅本线程读写
        std::string bucket;                // 本 worker 的 BlobStore 桶（buffer 通道）
    };

    static uint64_t fnv1a64(std::string_view s);
    void refresh_source_locked();         // 池锁内：stat → 重读 → hash → version++
    std::shared_ptr<const SourceSnapshot> snapshot() const;
    std::optional<Task> take_task(Worker& w); // 池锁内取任务 + 注册到 runner + owner_
    void worker_main(Worker* w);
    bool reload_worker(Worker& w, const SourceSnapshot& snap); // 失败保留旧实例
    void finish_task(uint64_t id);        // 池锁内擦 owner_

    std::string script_path_;
    size_t max_workers_ = 20;
    RegisterAllFn register_all_;
    std::atomic<uint64_t> next_id_{1};
    std::atomic<bool> exit_{false};

    mutable std::mutex mu_; // 一把锁：queue_ + idle_ + slot_ + owner_ + workers_
    std::shared_ptr<const SourceSnapshot> source_;
    std::deque<Task> queue_;
    std::vector<std::unique_ptr<Worker>> workers_;
    std::vector<Worker*> idle_;
    std::unordered_map<uint64_t, Worker*> owner_;
    std::string last_error_; // 最近一次加载/编译/注册错误（诊断）
};

// ================= 实现 =================

inline uint64_t TaskPool::fnv1a64(std::string_view s)
{
    uint64_t h = 1469598103934665603ull;
    for (unsigned char c : s) {
        h ^= c;
        h *= 1099511628211ull;
    }
    return h;
}

inline TaskPool::TaskPool(std::string script_path, size_t max_workers,
                          RegisterAllFn register_all)
    : script_path_(std::move(script_path)),
      max_workers_(max_workers == 0 ? 1 : max_workers),
      register_all_(std::move(register_all))
{
    std::lock_guard lock(mu_);
    refresh_source_locked(); // 初始快照（worker 首轮加载用）
}

// ---- 快照更新（§3.2 第 2 步）：mtime 变了才重读 + hash；hash 变了 → version++ ----
inline void TaskPool::refresh_source_locked()
{
    std::error_code ec;
    const auto mtime = std::filesystem::last_write_time(script_path_, ec);
    if (ec)
        return; // 文件暂不可读：保持旧快照（后续 submit 重试）
    const int64_t mtime_ns =
        std::chrono::duration_cast<std::chrono::nanoseconds>(mtime.time_since_epoch())
            .count();
    if (source_ && source_->mtime == mtime_ns)
        return;
    std::ifstream f(script_path_, std::ios::binary);
    if (!f)
        return;
    std::string src((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
    const uint64_t h = fnv1a64(src);
    auto snap = std::make_shared<SourceSnapshot>();
    snap->source = std::move(src);
    snap->hash = h;
    snap->mtime = mtime_ns;
    // 内容没变（touch 等）→ 版本不变；变了 → version++
    snap->version = (source_ && source_->hash == h) ? source_->version
                                                    : (source_ ? source_->version + 1 : 1);
    source_ = std::move(snap);
}

inline std::shared_ptr<const TaskPool::SourceSnapshot> TaskPool::snapshot() const
{
    std::lock_guard lock(mu_);
    return source_;
}

inline TaskHandle TaskPool::submit(InvokeRequest req)
{
    if (exit_.load(std::memory_order_acquire))
        throw std::runtime_error("TaskPool::submit: pool is shut down");
    auto [tx, rx] = co::oneshot::channel<TaskResult>();
    Task t;
    t.id = next_id_.fetch_add(1);
    t.req = std::move(req);
    t.tx = std::move(tx);

    std::unique_lock lock(mu_);
    if (exit_.load(std::memory_order_acquire)) {
        lock.unlock();
        throw std::runtime_error("TaskPool::submit: pool is shut down");
    }
    refresh_source_locked(); // 每次 submit 检查文件（mtime 变了才重读）

    if (!idle_.empty()) {
        // 交接给队首 idle worker（写入其 slot_，cv 唤醒）
        Worker* w = idle_.front();
        idle_.erase(idle_.begin());
        w->idle_marked = false;
        w->slot_ = std::move(t);
        w->cv.notify_one();
    } else if (workers_.size() < max_workers_) {
        // 懒创建 worker（首任务经构造交接；线程起来后锁内取 slot_）
        auto w = std::make_unique<Worker>();
        Worker* wp = w.get();
        wp->slot_ = std::move(t);
        workers_.push_back(std::move(w));
        wp->thread = std::thread(&TaskPool::worker_main, this, wp);
    } else {
        queue_.push_back(std::move(t));
    }
    lock.unlock();
    return TaskHandle{t.id, std::move(rx)};
}

// ---- 取消（§5）：queue_ → slot_ → 已在 runner（owner_ 定位 worker）----
inline bool TaskPool::cancel(uint64_t id)
{
    std::unique_lock lock(mu_);
    for (auto it = queue_.begin(); it != queue_.end(); ++it) {
        if (it->id == id) {
            Task t = std::move(*it);
            queue_.erase(it);
            lock.unlock();
            t.tx.send(TaskResult{false, "cancelled"});
            return true;
        }
    }
    for (auto& w : workers_) {
        if (w->slot_ && w->slot_->id == id) {
            Task t = std::move(*w->slot_);
            w->slot_.reset();
            lock.unlock();
            t.tx.send(TaskResult{false, "cancelled"});
            return true;
        }
    }
    auto it = owner_.find(id);
    if (it == owner_.end())
        return false; // 不存在或已结算
    Worker* w = it->second;
    // ★ 锁内读 runner 并调用：与 reload 的替换段互斥（数据竞争防护）。锁序
    // 池锁→runner 锁，与 take_task 一致，无死锁环（runner->cancel 内部解锁后
    // 才调 settle_task，不反向取池锁）
    return w->runner->cancel(id);
}

// ---- worker 取任务（池锁内，双侧检查无丢唤醒；锁内注册避免取消竞态窗口）----
inline std::optional<TaskPool::Task> TaskPool::take_task(Worker& w)
{
    std::unique_lock lock(mu_);
    for (;;) {
        if (w.exit)
            return std::nullopt; // shutdown
        std::optional<Task> t;
        if (w.slot_) {
            t = std::move(*w.slot_);
            w.slot_.reset();
        } else if (!queue_.empty()) {
            t = std::move(queue_.front());
            queue_.pop_front();
        }
        if (t) {
            // 锁内注册（本线程即 JS 线程，begin_task 稍后内联）：
            // cancel 总能经 owner_ → runner 命中该 id，无"已取走未注册"窗口
            w.runner->register_task(t->id, std::move(t->req), std::move(t->tx));
            owner_[t->id] = &w;
            return t;
        }
        if (!w.idle_marked) {
            w.idle_marked = true;
            idle_.push_back(&w);
        }
        w.cv.wait(lock);
    }
}

// ---- reload（§4）：任务边界；失败保留旧实例，本任务继续旧代码 ----
// 加载走共用 load_bundle_source（自带编译验证 + CJS 包装）；失败即丢弃新实例
inline bool TaskPool::reload_worker(Worker& w, const SourceSnapshot& snap)
{
    // 先建后拆：新 Runtime + 全部 native 绑定 + dispatcher + bundle 加载
    Runtime* prev_tls = tls_current_runtime; // 失败时恢复（构造会把 TLS 绑到新实例）
    auto new_rt = std::make_unique<Runtime>("pool-worker");
    auto fail = [&](const std::string& msg) {
        tls_current_runtime = prev_tls; // 恢复旧实例的 TLS 绑定
        std::lock_guard lock(mu_);
        last_error_ = msg;
        return false; // new_rt 在本线程析构（TLS == this 判断保护，不误清）
    };
    try {
        if (register_all_) {
            Context c = new_rt->main_context();
            register_all_(c);
        }
    } catch (const std::exception& e) {
        return fail(std::string("reload register_all failed: ") + e.what());
    }
    auto new_runner = std::make_unique<TaskRunner>(*new_rt);
    try {
        Context c = new_rt->main_context();
        install_bundle_dispatcher(c, w.bucket);
    } catch (const std::exception& e) {
        return fail(std::string("reload dispatcher install failed: ") + e.what());
    }
    if (auto err = load_bundle_source(new_rt->main_context(), snap.source, script_path_))
        return fail(std::string("reload bundle load failed: ") + err->message);

    // 替换（旧实例在本线程析构；TLS 已绑到新实例）。★ 替换段持池锁：
    // cancel 在池锁内读 w->runner，二者互斥（数据竞争防护）；迁移条目也在锁内
    //（池锁→runner 锁，与 take_task 一致）
    w.rt->io().poll(); // 排空旧 io 残余 handler（如迟到的取消闭包）
    std::unique_ptr<TaskRunner> old_runner;
    std::unique_ptr<Runtime> old_rt;
    {
        std::lock_guard lock(mu_);
        old_runner = std::move(w.runner);
        old_rt = std::move(w.rt);
        w.runner = std::move(new_runner);
        w.rt = std::move(new_rt);
        // 迁移未开始条目（本任务）到新 runner
        for (auto& [id, kv] : old_runner->drain_queued())
            w.runner->register_task(id, std::move(kv.first), std::move(kv.second));
    }
    // 锁外析构：runner 必须先于 rt（TaskRunner 析构访问 rt_.raw() 卸 interrupt
    // handler；局部变量逆声明序会把 rt 排前 → 悬垂崩溃，故显式 reset）
    old_runner.reset();
    old_rt.reset();
    return true;
}

// ---- worker 主循环（§3.3）----
inline void TaskPool::worker_main(Worker* w)
{
    // Runtime 在 worker 线程上构造与析构（TLS / 线程亲和）
    w->rt = std::make_unique<Runtime>("pool-worker");
    w->runner = std::make_unique<TaskRunner>(*w->rt);
    w->bucket = "hbuf:pool:" + std::to_string(reinterpret_cast<uintptr_t>(w));
    try {
        if (register_all_) {
            Context c = w->rt->main_context();
            register_all_(c);
        }
    } catch (const std::exception& e) {
        std::lock_guard lock(mu_);
        last_error_ = std::string("register_all failed: ") + e.what();
    }
    try { // bundle dispatcher（trampoline 覆盖 / source map / buffer 通道）
        Context c = w->rt->main_context();
        install_bundle_dispatcher(c, w->bucket);
    } catch (const std::exception& e) {
        std::lock_guard lock(mu_);
        last_error_ = std::string("dispatcher install failed: ") + e.what();
    }
    // 初始 bundle 加载（失败不致命：任务调用不存在的函数会结算错误；文件修复后
    // version 变化 → reload 重试）
    {
        auto snap = snapshot();
        w->loaded_version = snap ? snap->version : 0;
        if (snap && !snap->source.empty()) {
            if (auto err = load_bundle_source(w->rt->main_context(), snap->source,
                                              script_path_)) {
                std::lock_guard lock(mu_);
                last_error_ = std::string("initial bundle load failed: ") + err->message;
            }
        }
    }

    for (;;) {
        auto task = take_task(*w); // 锁内取任务 + 注册到 runner
        if (!task)
            break; // shutdown
        const uint64_t id = task->id;

        // 版本检查（worker 不各自读文件；只比对快照版本）
        auto snap = snapshot();
        if (snap && snap->version != w->loaded_version) {
            if (reload_worker(*w, *snap))
                w->loaded_version = snap->version;
            // reload 失败：loaded_version 不变，下个任务自动重试（§4 第 2 步）
        }

        // begin_task 直接调（本线程即 JS 线程；post 进 io_ 的话 run_to_completion
        // 会在 pending_==0 判定时先退出，handler 还没跑——§3.3）
        w->runner->begin_task(id);
        w->rt->run_to_completion(); // 驱动到该任务 promise 链结算（pending_==0 退出）
        if (!w->runner->is_settled(id)) {
            // promise 永不结算且无在飞异步 → 补发 error 结果（§3.3/§6）
            w->runner->force_settle(id, false,
                                    "internal error: task did not settle "
                                    "(never-resolving promise?)");
        }
        w->rt->io().poll(); // 排空 io_ 残余 handler（如迟到的取消闭包，§5）
        finish_task(id);
    }

    // 退出前：runner 先于 rt 析构（本线程；取消闭包捕获 runner 指针）
    w->runner.reset();
    w->rt.reset();
}

inline void TaskPool::finish_task(uint64_t id)
{
    std::lock_guard lock(mu_);
    owner_.erase(id);
}

// ---- 关闭协议（§7）----
inline void TaskPool::shutdown()
{
    bool expected = false;
    if (!exit_.compare_exchange_strong(expected, true))
        return; // 幂等
    std::vector<Task> doomed;
    {
        std::lock_guard lock(mu_);
        while (!queue_.empty()) { // 队列任务全部置 cancelled
            doomed.push_back(std::move(queue_.front()));
            queue_.pop_front();
        }
        for (auto& w : workers_) { // 全部 worker 置退出标志 + notify
            if (w->slot_) {
                doomed.push_back(std::move(*w->slot_));
                w->slot_.reset();
            }
            w->exit = true;
            w->cv.notify_all();
        }
    }
    for (auto& t : doomed)
        t.tx.send(TaskResult{false, "cancelled"});
    for (auto& w : workers_)
        if (w->thread.joinable())
            w->thread.join(); // 在飞任务跑完才退出（绝不在任务进行中销毁实例）
    std::lock_guard lock(mu_);
    workers_.clear(); // Worker 的 rt/runner 已由 worker_main 在本线程析构
    idle_.clear();
}

// ---- 诊断 ----
inline size_t TaskPool::worker_count() const
{
    std::lock_guard lock(mu_);
    return workers_.size();
}

inline uint64_t TaskPool::current_version() const
{
    std::lock_guard lock(mu_);
    return source_ ? source_->version : 0;
}

inline std::string TaskPool::last_error() const
{
    std::lock_guard lock(mu_);
    return last_error_;
}

} // namespace qjs
