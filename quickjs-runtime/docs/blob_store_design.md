# 二进制暂存设计文档（v1）

> 状态：**已实现**（`include/qjsbind/blob_store.hpp` + `tests/blob_store_test.cpp`）。
> 目标：进程级全局二进制暂存区（blob store），线程安全，**按 host 分桶隔离**；JS 侧 `native_put(二进制) → id`、`native_get(id) → 二进制`；条目闲置 15 分钟自动回收。
> **实现差异**：隔离边界只约束 **JS 侧 thunk**（qjs 实例互相看不到对方）；**C++ 侧无此限制**——`put/get` 本就接受任意 `host_id`（可读写任何 host 的桶），并新增特权入口 `find_any(id)` 跨所有桶全局查找（不需要知道 id 属于哪个 host）。详见 §3。
> 相关文档：`docs/dynamic_call_design.md`（动态调用；JSON 之外的二进制传输可借本设施传 id）。
> 参考锚点：`include/qjsbind/context.hpp:47-51`（boost::uuids 生成 id 先例）、`docs/dynamic_call_design.md` §4 D3（拷出后解锁的并发先例）。

## 0. 目标与非目标

目标：

- 一个**进程级全局** store，内部**按 host_id 分桶**：每个 host 的数据互相隔离，JS 侧只能存取本 host 桶内的数据。
- JS 侧暴露两个同步函数：
  - `native_put(bytes)`：存入一份二进制（进本 host 的桶），返回 id 字符串。
  - `native_get(id)`：按 id 从本 host 的桶取回二进制；不存在或已过期返回 `null`。
- **不传 hostid**——与动态调用同款：thunk 自动使用安装时所在 Runtime 的 id。
- **C++ 侧无隔离限制（实现差异）**：C++ API 可访问**任何** host 的桶（`put/get` 接受任意 `host_id`），`find_any(id)` 更是不需要知道 id 属于哪个 host 即可跨桶全局取数——"cpp 可以随意获取到所有想要的东西"。
- 条目**闲置超过 15 分钟自动回收**（滑动过期：put 写入、get 读取都算"使用"，刷新计时）；host 销毁时其整桶立即回收。
- 纯头文件实现，一个 `install_blob_store(ctx)` 完成接入，风格对齐 `install_*` 系列。

非目标：

- 不做持久化（进程退出即清空）。
- **不做任何跨 host 访问入口**：别的 host 的 id 对你等同于不存在。这是硬性隔离边界，与动态调用设计 §0 同款。
- 不做流式/分片读写；一次性整块进出。
- 不做 JS 侧显式 `remove`（回收交给 TTL；需要显式删除见 §10）。

## 1. 总体架构

```
┌─ JS（某个 host 的 JS 线程）──────────────────────────────┐
│  const id = native_put(uint8ArrayOrBuffer)   → string     │
│  const b  = native_get(id)                   → Uint8Array|null  │
└──────────────┬───────────────────────────────────────────┘
               │ thunk（include/qjsbind/blob_store.hpp）
               │  0. host_id = 安装时捕获的本 Runtime id    （JS 不传）
               │  native_put: JS 字节 → 拷贝成 vector<byte> → 加锁入本 host 桶 → 生成 id
               │  native_get: 本 host 桶内加锁拷贝出字节 → 解锁 → 包成 Uint8Array
               ▼
┌─ dyn::BlobStore（进程级单例，shared_mutex 保护）──────────┐
│  buckets: unordered_map<string /*host_id*/,              │
│                         unordered_map<string /*id*/,     │
│                                       Entry>>            │
│    Entry { vector<byte> data; atomic<int64> last_used; } │
│  sweeper: jthread，每 60s 扫描，回收闲置 > 15min 的条目   │
└───────────────────────────────────────────────────────────┘
```

「host」= 一个 `qjs::Runtime`，host_id 复用 `Runtime::id()`，与动态调用设计完全同构：`install_blob_store(ctx)` 把本 Runtime 的 id 捕获进 thunk 闭包，JS 每次调用自动携带，因此不同 host 的二进制天然分桶——host A 存的 id，host B 的 JS 拿去 `native_get` 只会得到 `null`。

> **隔离边界只对 JS 生效（实现差异）**：上图的"分桶"是数据组织方式，不是 C++ 侧的权限边界。C++ 代码（含动态调用 handler）可以 `get(任意 host_id, id)` 读任何桶、`put(任意 host_id, ...)` 写任何桶，还可以用 `find_any(id)` 在不知道 host_id 的情况下全局搜到该 id——这正是"JS 实例之间互相隔离、C++ 随意获取"的语义。

## 2. JS API

```js
// 存入：接受 ArrayBuffer / 任意 TypedArray / DataView；返回 id 字符串
const id = native_put(new Uint8Array([1, 2, 3]));

// 取出：返回 Uint8Array；id 不存在、已过期、或不属于本 host → null（不抛异常）
const bytes = native_get(id);
if (bytes === null) { /* 已过期 / 从未存在 / 不是本 host 的数据 */ }
```

约定：

- `native_put` 的参数不是 ArrayBuffer/TypedArray/DataView → 抛 `TypeError`。
- `native_get` 的返回值是**拷贝**：JS 侧拿到的是独立拥有的 `Uint8Array`，之后条目被回收也不受影响。
- `native_put` 同理是**拷入**：入库后 JS 侧再改原数组不影响已存内容。
- id 是 UUID v4 字符串（复用 `context.hpp` 里 boost::uuids 的现成设施）。id 只在**存入它的那个 host** 内有效。

## 3. C++ API

全部声明集中在新头文件 `include/qjsbind/blob_store.hpp`，namespace `qjs::dyn`。

```cpp
class BlobStore {
public:
    static BlobStore& instance();                    // Meyers 单例，首次访问时构造

    // 拷入一份字节到 host_id 的桶，返回 id。put 即视为一次"使用"。
    // host_id 可以是任何 host 的——C++ 侧无隔离限制。
    std::string put(std::string_view host_id, std::vector<std::byte> data);

    // 从 host_id 的桶按 id 拷出字节；不存在/已过期返回 nullopt。命中即刷新 last_used。
    // host_id 可以是任何 host 的——C++ 侧无隔离限制。
    std::optional<std::vector<std::byte>> get(std::string_view host_id, std::string_view id);

    // ★ C++ 特权入口（实现差异）：跨所有 host 桶按 id 全局查找，不需要知道
    // id 属于哪个 host。命中返回 {host_id, data} 并刷新 last_used；
    // 不存在/已过期返回 nullopt。JS 侧没有任何等价入口。
    std::optional<std::pair<std::string, std::vector<std::byte>>> find_any(std::string_view id);

    // 建空 host 桶（幂等；install_blob_store 时调用）
    void ensure_host(std::string_view host_id);

    // 整桶删除（host 销毁时由 Runtime 析构钩子调用，§5）。
    void remove_host(std::string_view host_id);

    // 回收全部桶内闲置超过 TTL 的条目；sweeper 线程周期调用，测试可手动调。
    void sweep_now();

    // 默认 15min / 60s；测试可注入更小值（sweep_interval <= 0 禁用 sweeper
    // 线程，纯手动 sweep_now）。启动后改不生效（构造期配置）。
    struct Config { std::chrono::milliseconds ttl{15 * 60 * 1000}; std::chrono::milliseconds sweep_interval{60 * 1000}; };
};

void install_blob_store(qjs::Context& ctx);          // 幂等；建本 host 桶、注册 put/get、捕获 rt.id()
```

> 测试注入小配置用局部实例 `BlobStore store({ttl=..., sweep_interval=...})`；进程级单例 `instance()` 恒用默认配置（与 dynamic_call 的 Registry 同款单例模式）。

关键实现决策：

- **D1：两级 map 按 host 分桶，不拼 composite key。** 理由：`remove_host` 整桶 O(1) 定位删除；sweep 可分桶进行；结构与动态调用的 `hosts → HostTable` 同构，认知一致。若拼 `"host_id:id"` 单级 key，整桶删除就得全表扫描。
- **D2：滑动过期，时钟用 `steady_clock`。** `last_used` 存 `steady_clock::time_point` 的计数，单调递增，不受系统时间回拨影响；回收判定 = `now - last_used > ttl`。
- **D3：`last_used` 用 `std::atomic<int64_t>`。** get 是高频读路径，原子刷新让 get 只持**共享锁**（读锁），多线程并发 get 不互斥；只有 put/insert、sweep/erase、remove_host 持独占锁。
- **D4：锁内只做内存拷贝，绝不碰 JSValue。** put thunk 先在锁外把 JS 字节拷成 `vector<byte>` 再加锁入库；get thunk 在锁内拷出、解锁后再调 `JS_NewArrayBufferCopy`。与动态调用设计 §4 D3 同一原则：锁粒度内不出现可能重入的操作。
- **D5：拷进拷出语义。** store 与 JS 之间永远是值拷贝，不共享底层 buffer——回收线程何时 erase 都不会悬垂任何 JS 侧引用。
- **D6：sweeper 用 `std::jthread`。** 随单例构造启动、`stop_token` 周期性醒（默认 60s）逐桶扫一轮；单例析构时自动 `request_stop` + join。扫描间隔 60s 意味着实际回收时机落在闲置 15～16 分钟之间——对此语义"15 分钟后回收"足够精确，换来零定时器开销。
- **D7：get 对过期条目视作不存在。** 即使 sweeper 还没扫到，get 发现 `now - last_used > ttl` 直接返回 `nullopt`（顺手 erase）——TTL 语义在读路径上即时生效，不依赖 sweeper 的运气。
- **D8：桶不存在 = 空桶。** get/put 遇到未 install 过的 host_id：put 自动建桶（幂等，install 只是提前建 + 装 JS 函数），get 返回 `nullopt`。不为此报错，行为与"桶是空的"完全一致。

## 4. 回收机制语义

```
native_put(id): last_used = now
native_get(id): 若 now - last_used > ttl → 当作不存在（返回 null，顺手删）
              否则 last_used = now，返回数据
sweeper:      每 60s 醒来，逐桶 erase 所有 now - last_used > ttl 的条目；空桶顺手摘除
remove_host:  host 销毁 → 整桶立即删除，不等 TTL
```

- "使用"的定义 = 一次成功的 native_put 或 native_get。只 native_put 不 native_get 的条目在 15 分钟后被回收——符合"没有使用就回收"的字面语义。
- 过期时刻不保证精确到秒（sweeper 粒度 60s），但 get 路径（D7）保证**逻辑上**过期即不可得；sweeper 只负责释放内存。
- host 销毁是第三条回收路径：不依赖 TTL，立即释放。

## 5. 线程模型

1. store 是**纯 C++ 设施**：map 里只有字节和时间戳，没有任何 JSValue/JSContext——与动态调用设计 §6 不变量 1 同款。
2. thunk 只在所属 host 的 JS 线程上运行；多个 host 的 JS 线程可并发 put/get，由 `shared_mutex` + 原子 `last_used` 保证安全。分桶结构意味着不同 host 的操作在数据上不相交，锁只是保护 map 结构本身。
3. put/get 都是同步函数：一次 memcpy 级别的操作不值得开异步版。超大块（几十 MB）的拷贝会阻塞 JS 线程——见 §9。
4. **`Runtime` 析构需要钩子**：`context.hpp` 析构里加一行 `dyn::remove_blob_host(id())`，销毁即整桶回收，防止孤儿桶白占 15 分钟内存。与动态调用的 `dyn::remove_host(id())` 是同一个侵入点（两份设计都落地时析构加两行）；因两钩子同名不同义，blob 版独立命名 `remove_blob_host`（inline 定义在 `blob_store.hpp`，前向声明在 `context.hpp`，与 dynamic_call 同款模式）。

## 6. 与动态调用的配合

本设施补的是动态调用（`docs/dynamic_call_design.md`）"只走 JSON 文本"的短板，且两者的 host 分桶语义完全对齐：

- JS 想把二进制传给 C++ handler：`const id = native_put(bytes); await call("process", id);`——id 走 JSON 数组毫无压力。
- **handler 的第一个参数就是 host_id**（动态调用 thunk 自动注入的），直接拿来当 blob 命名空间用：`BlobStore::instance().get(host_id, id)`——同一份 host_id，同一条数据组织，不需要任何额外约定。
- **handler 是 C++ 代码，不受 JS 侧隔离限制（实现差异）**：可以 `get(任意 host_id, id)` 读任何 host 的桶（例如宿主进程替某个 host 管理数据），或者干脆用 `find_any(id)` 全局搜——不需要知道 id 属于谁。
- 反向同样成立：handler 产出二进制 → `put(host_id, ...)` 入库 → 把 id 写进返回的 JSON，JS 再 `native_get(id)`。
- 跨 host 传 id 对 JS 没有意义：id 离开本 host 就是无效字符串（别的 host 的 JS `native_get` 得到 `null`）。想跨 host 搬二进制请走 channel 传字节本身；但 **C++ 侧**拿到任何 id 都能 `find_any` 取到。

## 7. 错误与边界

| 场景 | 行为 |
|---|---|
| `native_put` 参数不是二进制类型 | throw `TypeError` |
| `native_get` 的 id 不存在 / 已过期 / 属于其他 host | 返回 `null`（不抛异常——三者对外不可区分，也**不该**可区分） |
| `native_get` 参数不是字符串 | throw `TypeError` |
| 空二进制（0 字节） | 合法，正常存取 |
| id 冲突 | UUID v4 空间内实际不可能；insert 失败时重新生成重试 |

## 8. 文件落点

- 新增 `include/qjsbind/blob_store.hpp`：BlobStore 单例 + sweeper + 两个 thunk + `install_blob_store`。header-only。**已实现**。
- 修改 `include/qjsbind/context.hpp`：析构加 `dyn::remove_blob_host(id())` 一行（与动态调用共用侵入点，独立命名）。**已实现**。
- 修改 `include/qjsbind/qjsbind.hpp`：末尾 include 新头文件。**已实现**。
- 新增 `tests/blob_store_test.cpp`：**已实现**。
  - put/get 往返（ArrayBuffer、Uint8Array、DataView 三种入参；拷入后改原数组不影响库存；get 返回独立拷贝）；
  - get 未注册/过期 id → `null`；
  - **隔离性：host A 存、host B 取 → `null`；两 host 各自 put 互不可见；但 C++ `find_any` 仍可跨桶取到（差异点验收）；**
  - **C++ 无隔离：`put/get` 用任意 host_id（含从未 install 过的 host）；`find_any` 不需要知道 host_id；**
  - **remove_host：host 销毁后桶被整桶回收（配合 Runtime 析构钩子 `remove_blob_host` 一起验证）；**
  - TTL：测试用小 TTL + 手动 `sweep_now()` 验证回收与滑动刷新（get 续命）；
  - 并发：多线程（两个 Runtime 的 JS 线程 + 裸线程）混合 put/get 不崩不丢；
  - 非二进制参数 → TypeError。

## 9. 已知限制

- **无容量上限**：15 分钟内 put 进的数据全在内存里，恶意/失控写入会涨爆内存。容量守卫见 §10。
- get/put 的整块 memcpy 在 JS 线程上，超大块会造成可感知卡顿。
- JS 侧函数名定为 `native_put`/`native_get`（避免与其他库的裸 `put`/`get` 冲突）；`install_blob_store` 留可选参数允许改名（如 `blobPut`/`blobGet`）。
- 过期时间精确度为分钟级（sweeper 间隔 60s），不适用于精确 TTL 场景。

## 10. 后续可选增强（本期不做）

- 容量守卫：`max_total_bytes`（或 per-host 配额）配置，超限时 put 抛错或 LRU 驱逐。
- JS 侧 `remove(id)` / `has(id)`（C++ 侧实现现成，只是两个额外 thunk）。
- 引用计数式句柄：get 改为"借用"，显式 release 后才参与 TTL 计时。
- 统计接口：每桶条目数、总字节数、命中率。
