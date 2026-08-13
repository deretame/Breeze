// blob_store.hpp —— 二进制暂存:JS 侧 put(二进制) → id / get(id) → 二进制
//
// 设计文档:docs/blob_store_design.md(v1)
//
// 概览:
//   - 进程级 BlobStore 单例,按 host_id 分桶;shared_mutex + 原子 last_used。
//   - JS 侧两个全局函数 native_put/native_get:lambda 捕获安装时所在 Runtime 的 id
//     （经 qjs::func()/Object::set 注册，异常边界自动），JS 只能存取本 host 桶
//     （硬性隔离边界——qjs 实例互相看不到对方）。
//   - ★ C++ 侧无隔离限制(与设计文档的差异点):native_put/native_get 本就接受任意
//     host_id(可读写任何 host 的桶);find_any(id) 更是不需要知道 id
//     属于哪个 host,跨所有桶全局查找。隔离只约束 JS 侧 thunk,C++ API
//     可以随意获取所有想要的数据。
//   - 条目闲置超过 TTL(默认 15min)自动回收:滑动过期(native_put/native_get 都刷新),
//     sweeper 线程(默认 60s 间隔)释放内存;get 读路径上过期即不可得。
//   - host 销毁(Runtime 析构)时整桶立即回收(context.hpp 钩子)。
//
// 线程不变量:
//   1. store 是纯 C++ 设施:map 里只有字节和时间戳,没有任何 JSValue/JSContext。
//   2. thunk 只在所属 host 的 JS 线程上运行;多 host 的 JS 线程 + 任意 C++
//      线程可并发 put/get 操作,shared_mutex + atomic last_used 保证安全。
//   3. get 只持共享锁:命中路径锁内拷贝 + 原子刷新,多线程并发 get 不互斥;
//      put/ensure_host/sweep/remove_host 持独占锁。
#pragma once

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstddef>
#include <cstring>
#include <mutex>
#include <optional>
#include <shared_mutex>
#include <stop_token>
#include <string>
#include <string_view>
#include <thread>
#include <unordered_map>
#include <utility>
#include <vector>

#include <quickjs.h>

#include <qjsbind/binary.hpp> // qjs::Context::js_string / js_utf8 / js_bytes / new_uint8_array
#include <qjsbind/context.hpp>
#include <qjsbind/convert.hpp> // qjs::Context::to_js / from_js
#include <qjsbind/error.hpp>
#include <qjsbind/function.hpp> // Object::set + func()（lambda 注册，异常边界自动）
#include <qjsbind/value.hpp>

namespace qjs {
namespace dyn {

// ================= BlobStore(设计文档 §3)=================
class BlobStore {
public:
    // 默认 15min / 60s;测试可注入更小值(sweep_interval <= 0 禁用 sweeper
    // 线程,纯手动 sweep_now)。配置在构造期固定,启动后改不生效。
    struct Config {
        std::chrono::milliseconds ttl{15 * 60 * 1000};
        std::chrono::milliseconds sweep_interval{60 * 1000};
    };

    // 局部实例(测试用小配置);进程级单例用 instance()(默认配置)
    BlobStore() : BlobStore(Config{}) {}
    explicit BlobStore(Config cfg) : cfg_(cfg)
    {
        if (cfg_.sweep_interval.count() > 0)
            sweeper_ = std::jthread([this](std::stop_token st) { sweeper_loop(st); });
    }
    ~BlobStore() = default; // sweeper_ 最后声明 → 最先析构:request_stop + join
    BlobStore(const BlobStore&) = delete;
    BlobStore& operator=(const BlobStore&) = delete;

    // 进程级单例(Meyers):首次访问时构造,sweeper 随单例生命周期
    static BlobStore& instance()
    {
        static BlobStore store;
        return store;
    }

    // ---- C++ API(无 host 隔离限制:host_id 可以是任何 host 的)----

    // 拷入一份字节到 host_id 的桶(桶不存在自动创建,设计 §8 D8),返回新 UUID id。
    // put 即视为一次"使用"。
    std::string put(std::string_view host_id, std::vector<std::byte> data);

    // 从 host_id 的桶按 id 拷出字节;不存在/已过期返回 nullopt。命中即刷新 last_used。
    std::optional<std::vector<std::byte>> get(std::string_view host_id, std::string_view id);

    // ★ C++ 特权入口(与设计文档的差异点):跨所有 host 桶按 id 全局查找,
    // 不需要知道 id 属于哪个 host。命中返回 {host_id, data} 并刷新 last_used;
    // 不存在/已过期返回 nullopt。JS 侧没有任何等价入口——隔离只约束 JS。
    std::optional<std::pair<std::string, std::vector<std::byte>>> find_any(std::string_view id);

    // 建空 host 桶(幂等;install_blob_store 时调用,不产生条目)
    void ensure_host(std::string_view host_id);

    // 整桶删除(host 销毁时由 Runtime 析构钩子调用)
    void remove_host(std::string_view host_id);

    // 删除单条（消费语义：take = get + remove）；不存在返回 false
    bool remove(std::string_view host_id, std::string_view id);

    // 回收全部桶内闲置超过 TTL 的条目;sweeper 线程周期调用,测试可手动调
    void sweep_now();

private:
    using clock = std::chrono::steady_clock; // D2:单调时钟,不受系统时间回拨影响
    using rep_t = clock::rep;

    struct Entry {
        Entry(std::vector<std::byte> d, rep_t now) : data(std::move(d)), last_used(now) {}
        std::vector<std::byte> data;
        std::atomic<rep_t> last_used; // D3:原子时间戳,get 读路径只需共享锁
    };
    using Bucket = std::unordered_map<std::string, Entry>;

    void sweeper_loop(std::stop_token st);
    rep_t now_rep() const { return clock::now().time_since_epoch().count(); }
    bool expired(rep_t last, rep_t now) const
    {
        return now - last > std::chrono::duration_cast<clock::duration>(cfg_.ttl).count();
    }
    // D7 顺手删:get 读路径发现过期条目后,升级独占锁删除(可能已被并发路径
    // 删除,幂等)。删除与"返回 nullopt"不冲突,语义上过期即不存在。
    void erase_if_expired(std::string_view host_id, std::string_view id, rep_t now);

    Config cfg_;
    mutable std::shared_mutex mu_;
    std::unordered_map<std::string, Bucket> buckets_; // D1:两级 map 按 host 分桶
    std::jthread sweeper_; // 最后声明:析构时最先 request_stop + join,其余成员仍存活
};

// ================= 实现 =================
inline std::string BlobStore::put(std::string_view host_id, std::vector<std::byte> data)
{
    const rep_t now = now_rep();
    std::unique_lock lock(mu_);
    Bucket& bucket = buckets_[std::string(host_id)]; // D8:桶不存在自动创建
    for (;;) {
        std::string id = make_uuid_v4();
        auto [it, inserted] = bucket.try_emplace(id, std::move(data), now);
        if (inserted)
            return id; // 冲突则重新生成重试(设计 §7;UUID v4 冲突实际不可能)
        // try_emplace 失败时不构造 value,data 未被移动,可安全重试
    }
}

inline std::optional<std::vector<std::byte>> BlobStore::get(std::string_view host_id,
                                                            std::string_view id)
{
    const rep_t now = now_rep();
    std::shared_lock lock(mu_); // D3:get 只持共享锁,并发 get 不互斥
    auto bit = buckets_.find(std::string(host_id));
    if (bit == buckets_.end())
        return std::nullopt; // D8:桶不存在 = 空桶
    auto it = bit->second.find(std::string(id));
    if (it == bit->second.end())
        return std::nullopt;
    Entry& e = it->second;
    const rep_t last = e.last_used.load(std::memory_order_relaxed);
    if (expired(last, now)) {
        lock.unlock(); // D7:过期即不可得;顺手删(锁升级,幂等)
        erase_if_expired(host_id, id, now);
        return std::nullopt;
    }
    e.last_used.store(now, std::memory_order_relaxed); // 滑动过期:get 算使用
    return e.data; // D5:锁内拷贝,返回独立副本
}

inline std::optional<std::pair<std::string, std::vector<std::byte>>>
BlobStore::find_any(std::string_view id)
{
    const rep_t now = now_rep();
    std::shared_lock lock(mu_); // 只读遍历 + 原子刷新,无独占锁
    for (auto& [host_id, bucket] : buckets_) {
        auto it = bucket.find(std::string(id));
        if (it == bucket.end())
            continue;
        Entry& e = it->second;
        if (expired(e.last_used.load(std::memory_order_relaxed), now))
            continue; // 过期对特权入口同样不可见(语义一致;sweeper 负责释放内存)
        e.last_used.store(now, std::memory_order_relaxed);
        return std::make_pair(host_id, e.data); // 锁内拷贝
    }
    return std::nullopt;
}

inline void BlobStore::ensure_host(std::string_view host_id)
{
    std::unique_lock lock(mu_);
    buckets_.try_emplace(std::string(host_id));
}

inline void BlobStore::remove_host(std::string_view host_id)
{
    std::unique_lock lock(mu_);
    buckets_.erase(std::string(host_id));
}

inline bool BlobStore::remove(std::string_view host_id, std::string_view id)
{
    std::unique_lock lock(mu_);
    auto bit = buckets_.find(std::string(host_id));
    if (bit == buckets_.end())
        return false;
    const bool erased = bit->second.erase(std::string(id)) > 0;
    if (bit->second.empty())
        buckets_.erase(bit); // 空桶顺手摘除
    return erased;
}

inline void BlobStore::erase_if_expired(std::string_view host_id, std::string_view id, rep_t now)
{
    std::unique_lock lock(mu_);
    auto bit = buckets_.find(std::string(host_id));
    if (bit == buckets_.end())
        return;
    auto it = bit->second.find(std::string(id));
    if (it == bit->second.end())
        return;
    if (expired(it->second.last_used.load(std::memory_order_relaxed), now)) {
        bit->second.erase(it);
        if (bit->second.empty())
            buckets_.erase(bit); // 空桶顺手摘除
    }
}

inline void BlobStore::sweep_now()
{
    const rep_t now = now_rep();
    std::unique_lock lock(mu_);
    for (auto bit = buckets_.begin(); bit != buckets_.end();) {
        for (auto it = bit->second.begin(); it != bit->second.end();) {
            if (expired(it->second.last_used.load(std::memory_order_relaxed), now))
                it = bit->second.erase(it);
            else
                ++it;
        }
        if (bit->second.empty())
            bit = buckets_.erase(bit); // 空桶顺手摘除
        else
            ++bit;
    }
}

inline void BlobStore::sweeper_loop(std::stop_token st)
{
    // D6:周期性醒(默认 60s)逐桶扫一轮。可中断等待:stop_callback 在
    // request_stop 时(无论回调注册前后)notify 唤醒,消除丢失唤醒——
    // join 不会被阻塞到下一个超时(MSVC STL 无 stop_token 版 wait_for,
    // 故用回调 + 普通超时等待)。
    std::mutex m;
    std::condition_variable cv;
    std::stop_callback wake(st, [&] { cv.notify_all(); });
    while (!st.stop_requested()) {
        std::unique_lock lock(m);
        cv.wait_for(lock, cfg_.sweep_interval); // 超时或被 stop 唤醒
        if (st.stop_requested())
            return;
        lock.unlock();
        sweep_now();
    }
}

// ---- host 桶生命周期钩子(Runtime 析构时调用;context.hpp 有前向声明)----
// 注意:与 dynamic_call 的 dyn::remove_host 同名不同义,故独立命名。
inline void remove_blob_host(std::string_view host_id)
{
    BlobStore::instance().remove_host(host_id);
}

// ================= 接入入口(设计文档 §3.3)=================
// 给该 Runtime 的主 context 装上 native_put/native_get/native_host_id 与
// __native_buf_free 四个全局函数,建好本 host 桶。native_host_id 供 polyfill 在
// 占位对象里标注来源 host（dyn_blob.js）。
// 注册走 qjs::func()/Object::set：lambda 值捕获 host_id（closure_holder 持有，
// finalize 自动释放，无需手写 opaque）；arity 推导与异常边界
// （js_error/type_error/std::exception 全捕获）由 invoke_impl 提供。
// 幂等:重复 install 不报错(重新覆盖全局函数,桶已存在则复用)。
inline void install_blob_store(qjs::Context& ctx)
{
    Runtime& rt = runtime_of(ctx.raw());
    BlobStore::instance().ensure_host(rt.id());
    const std::string host_id = rt.id(); // 捕获进 lambda，之后 JS 调用自动携带
    Object global = ctx.globals();
    global.set("native_host_id", [host_id](Ctx cx) -> Value {
        return qjs::Context(cx.ctx).to_js(host_id);
    });
    global.set("native_put", [host_id](Ctx cx, Value v) -> Value {
        qjs::Context c(cx.ctx);
        // js_bytes:RAII 字节提取（非二进制 → TypeError，detached/resize 守卫）。
        // D4:锁外完成,锁内只有纯内存拷贝。
        std::vector<std::byte> bytes = c.js_bytes(v.raw());
        std::string id = BlobStore::instance().put(host_id, std::move(bytes));
        return c.to_js(id); // JS_NewStringLen 包装
    });
    global.set("native_get", [host_id](Ctx cx, Value v) -> Value {
        qjs::Context c(cx.ctx);
        if (!v.is_string())
            throw_type_error(cx.ctx, "native_get: id 必须是字符串");
        std::string id = c.from_js<std::string>(v.raw()); // 值语义，嵌入 '\0' 保留
        std::optional<std::vector<std::byte>> data =
            BlobStore::instance().get(host_id, id);
        if (!data)
            return Value(cx.ctx, JS_NULL); // 不存在/已过期/属于其他 host:三者不可区分
        // D4:解锁后才碰 JSValue;new_uint8_array 再拷一份,JS 独立拥有
        return c.new_uint8_array(data->data(), data->size());
    });
    // __native_buf_free：按 id 删除本 host 桶内的条目（不存在返回 false）。
    // 供 runtime_api polyfill 的 native.free / native.take（消费语义）调用。
    global.set("__native_buf_free", [host_id](Ctx cx, Value v) -> Value {
        qjs::Context c(cx.ctx);
        if (!v.is_string())
            throw_type_error(cx.ctx, "__native_buf_free: id 必须是字符串");
        const std::string id = c.from_js<std::string>(v.raw());
        return c.to_js(BlobStore::instance().remove(host_id, id));
    });
}

} // namespace dyn
} // namespace qjs
