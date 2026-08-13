# JS 任务系统设计：可取消调用（基础层）+ Debug 任务池（扩展层）

> 状态：已定稿（2026-08-09 讨论结论），实现前读本文。
>
> 分层原则（用户决策）：**可取消是基础功能，不是 debug 特性**。正常使用（直接持有
> 当前实例跑任务）与 debug 池共用同一套任务/取消机制；debug 池只是在运行时之上
> 叠加"多实例 + 热重载"的扩展。
>
> 相关：
>
> - `qjs_cpp_binding_design.md` —— 线程模型 / 事件循环不变量（§8）
> - `include/dart_cpp_bridge/channel.hpp` —— `co::oneshot`（结果通道）
> - `include/qjsbind/loop.hpp` —— run / run_to_completion / stop / shutdown 协议
> - `include/qjsbind/context.hpp` —— Runtime 的 TLS 绑定与线程亲和
> - `include/qjsbind/web/abort.hpp` —— AbortSignal → std::stop_source 取消链
> - `include/qjsbind/web/fetch.hpp` —— signal token 传入 `Client::fetch`（:122）

## 0. 目标与非目标

目标：

1. **可取消的非阻塞调用是基础能力**：任意 Runtime 上 `submit` 立即返回句柄，
   `cancel(id)` 任意时刻、任意线程可调。
2. **开发期热重载**（debug 扩展）：替换单个 js 文件后，新任务自动跑新代码
   （单文件、无 Module 加载）。
3. **并发**（debug 扩展）：10~40 个并发 IO 型任务（漫画封面加载）不串行。

非目标：

- 二进制参数/结果（后续单独方案）。
- JS 跨调用状态保持（明确不需要；后续持久化走独立存储方案，与本系统正交）。
- JS 线程内共享堆的 Worker（同绑定层总设计，不做）。

## 1. 分层架构

```
基础层（任何 Runtime）：
  qjs::TaskRunner —— 绑定一个 Runtime&
    ├─ 任务注册表：id → TaskEntry{状态, result_tx, signal_impl, generation}
    ├─ submit(req) → Handle{id, result_rx}   （非阻塞，任意线程）
    └─ cancel(id)                            （幂等，任意线程）

扩展层（debug）：
  qjs::TaskPool —— 懒创建、上限 max_workers（默认 20）
    ├─ queue: deque<Task> + idle: vector<Worker*> + 一把 mutex
    ├─ source 快照：{mtime, hash, source, version}（submit 时更新）
    └─ Worker × N：各自 线程 + Runtime + TaskRunner
```

normal 路径与 debug 路径的关系：

```
                ┌─────────────────────────────┐
  submit ──────►│ JsHost（可选 facade，按      │
  (含 debug 标志)│ req.debug 路由）             │
                └──┬──────────────────┬───────┘
        debug=false│                  │debug=true
                   ▼                  ▼
        主 Runtime 的 TaskRunner    TaskPool（热重载 + 池化并发）
        （共享实例，任务并发跑在      Worker = 线程+Runtime+TaskRunner
         同一事件循环上）            （一实例同时只跑一个任务）
```

关键决策记录：

- **取消沉在 TaskRunner（基础层）**：per-task AbortSignal + settle-once + interrupt
  flag，normal / debug 两条路径同一份实现；池子只叠加拓扑（队列、池化、reload）。
- **独立 Runtime 池，不用共享 Runtime 的多 Context**：取消粒度 = 实例粒度；
  reload 销毁粒度 = 实例；与 m4 多 Runtime 各自线程的既有模式一致。
- **池化而非单实例 drain-and-swap**：长任务期间文件多次变更时，单实例换版方案
  会堆积多个 drain 中实例无上限；池方案实例上限恒为 `max_workers`。
- **无"已创建未启动"状态**：取消只需要 id 提前存在 + `cancel(id)` API，submit
  返回即满足；不引入两阶段 create/start。
- **取消的跨线程执行用 asio::post + 原子标志，不走 channel**：理由见 §5.4。

## 2. API

```cpp
namespace qjs {

struct InvokeRequest {
    std::string function;    // JS 函数名（池为 bundle 导出表上的 fn_path）
    std::string args_json;   // JSON 文本（整体 parse 后作为第一参数，见 §3.4）
    bool debug = false;      // 仅 facade 路由用；TaskRunner 本身不关心
};

struct TaskResult {
    bool ok;                 // false 时 json 为错误文本（含 "cancelled"）
    std::string json;
};

struct TaskHandle {
    uint64_t id;
    co::oneshot::Receiver<TaskResult> result_rx; // 注意：完成发生在任务所在线程
};

// ---- 基础层 ----
class TaskRunner {
public:
    explicit TaskRunner(Runtime& rt); // 安装 trampoline + interrupt handler
    TaskHandle submit(InvokeRequest req); // 任意线程；要求宿主在驱动 rt 的事件循环
    bool cancel(uint64_t id);             // 幂等，任意线程
};

// ---- 扩展层（debug）----
class TaskPool {
public:
    explicit TaskPool(std::string script_path, size_t max_workers = 20);
    TaskHandle submit(InvokeRequest req); // 非阻塞，任意线程
    bool cancel(uint64_t id);             // 幂等，任意线程
    void shutdown();  // 拒新任务；队列任务置 cancelled；join 全部 worker
};

} // namespace qjs
```

## 3. 任务生命周期

状态机：`Queued → Running → Settled / Cancelled / Failed`

### 3.1 基础层 submit 路径（TaskRunner，共享实例）

1. 原子发 id；建 `co::oneshot::channel<TaskResult>`（tx 入 TaskEntry，rx 入 Handle）。
2. 锁内登记 `TaskEntry{Queued}`；`asio::post` 一个 `begin_task` 闭包到
   rt 的 io_context，立即返回 Handle。
3. `begin_task`（JS 线程，事件循环内执行）：
   - 创建 per-task `AbortSignalImpl` + signal JS 对象（`web/abort.hpp` 的
     `make_signal_object`）；TaskEntry 持有 impl 指针 + signal 的 RtValue 引用
     （保活到 settle，否则 JS 函数丢弃 signal 后 GC 会释放 impl）；
   - `JS_Call` trampoline（见 §3.4），同步执行到第一个 await，异步工作经
     `promise_from_sender` 登记进 `pending_`；
   - 条目共 Queued → Running。
4. settle（trampoline 的 then/catch 或取消路径触发，once 守卫）：
   `result_tx.send(...)` + 释放 signal 引用 + 擦除条目。

前提：宿主线程在驱动该 Runtime 的事件循环（`run()` 服务模式，或嵌入模式的
周期 `poll_once()`）——否则 post 的闭包永远不执行。

### 3.2 扩展层 submit 路径（TaskPool，调用线程，全程无阻塞）

1. 同基础层 1-2（池级 task_map）。
2. stat 脚本文件；mtime 变了才重读 + FNV-1a-64 hash；hash 变了 → `version++`、
   更新共享 source 快照（`shared_ptr<const Source>`）。
3. 锁内：任务入 `queue`；若 `idle` 非空 → 队首任务交接给某 idle worker（写入其
   `slot_`，cv 唤醒）；若无 idle 且 worker 数 < 上限 → 懒创建 worker（起线程，
   首任务经构造交接）；都没有 → 任务留队。
4. 返回 Handle。

### 3.3 worker 路径（worker 线程）

```
loop:
    锁内取任务：slot_ → queue → 都没有则标 idle + cv.wait
               （双侧检查在同一把锁内，无丢唤醒）
    if loaded_version != current_version: reload()           // §4
    begin_task：worker 线程直接调（本线程即 JS 线程，不 post——
                post 进 io_ 的话 run_to_completion 会在 pending_==0
                判定时先退出，handler 还没跑）
    run_to_completion() 驱动到该任务 promise 链结算（pending_==0 退出）
    若退出后 settle 未被调用（promise 永不结算且无在飞异步）→ 补发 error 结果
    poll 排空 io_ 残余 handler（如迟到的取消闭包，见 §5）
```

要点：

- Runtime 在 worker 线程上构造与析构（TLS / 线程亲和，`context.hpp:151-153,167-168`）。
- `run_to_completion()` 可重入：每轮结束 `shutdown()` 走 `finish_scope()` 重建
  scope（`loop.hpp:101-104,137-143`）。
- **worker 永不调用 `Runtime::stop()`**——`done_` 置位不可逆（`loop.hpp:92-95`）。
- 每 worker 内嵌一个 TaskRunner 实例负责注册表/trampoline/取消，worker 只负责
  拓扑（取任务）与驱动（run_to_completion）；`begin_task` 与 `cancel` 与基础层
  是同一份代码。

### 3.4 JS trampoline（每个实例注入一次）

```js
globalThis.__invoke = (name, argsJson, settle, signal) => {
  Promise.resolve()
    .then(() => globalThis[name](JSON.parse(argsJson), signal))
    .then(
      (v) => settle(true, JSON.stringify(v) ?? "null"),
      (e) => settle(false, String((e && e.stack) || e)),
    );
};
```

约定（全项目统一）：**argsJson 整体 `JSON.parse` 后作为第一参数传递**
（命名参数风格 `{"a":1}` → `fn({a:1})`），**signal 作为第二参数追加**——函数
想支持取消就声明第二个形参接收（传给 fetch 等），不想支持完全不感知。

注意：这是**基础版** trampoline（全局函数名直查）。池 worker 与 HostRuntime
实例都会安装 bundle dispatcher（`qjsbind/polyfill/bundle_dispatcher.js`），
其 `__invoke` 覆盖本版：fn_path 点路径解析到 bundle 导出表、`$buf` 占位物化、
Node 风格结构化错误、source map remap。**池脚本即 bundle**：按
`(function(module, exports){ ... })` CJS 包装加载，`module.exports` 为导出表，
与 HostRuntime 完全同一约定（加载走共用的 `load_bundle_source`）。

`settle` 是 native CClosure（opaque 持有 `result_tx` 与条目指针），once 守卫：
取消路径会先于 trampoline 的结算主动调它，迟到的第二次调用被挡掉。

## 4. reload 协议（仅 debug 池）

版本检查只发生在两处：submit 时更新共享快照（§3.2 第 2 步）；worker 领到任务时
比对 `loaded_version != current_version`。worker 不各自读文件。

reload 流程（worker 线程、任务边界，**绝不在任务进行中销毁实例**）：

1. 从共享快照取 source；
2. 构造新 Runtime（注册全部 native 绑定 + 安装 bundle dispatcher），走共用
   `load_bundle_source` 加载 bundle（**自带编译验证**：COMPILE_ONLY 不过则不
   执行）——失败 → 丢弃新实例、保留旧实例、上报错误、本任务继续用旧代码跑
   （`loaded_version` 不变，下个任务自动重试）——开发中保存到一半的语法错误
   文件不会炸掉任何实例；
3. 加载成功后才析构旧 Runtime（**先建后拆**；新实例构造会把 TLS 绑到自己，
   旧实例析构的 TLS 清理有 `== this` 判断保护，不会误清）。

语义：

- 在飞任务永远跑它启动时的版本（其闭包/全局状态属于该版本，中途换代码不成立）；
  忙实例随任务完成逐步收敛到最新版。30s 长任务期间改 4 次文件：无实例堆积，
  语义正确。
- native 绑定注册必须可重放：抽出 `register_all(qjs::Context&)`，每个新实例走
  同一入口。

## 5. 取消协议（基础层）

`cancel(id)` 幂等、任意线程可调，按任务状态分三路：

1. **Queued**（共享实例：post 的闭包尚未执行；池：任务在 queue/slot\_）：
   锁内摘除，立即 `result_tx.send({false,"cancelled"})`，擦除条目。
   迟到的 begin_task 闭包发现条目不存在 → no-op。
2. **Running 且异步 IO 挂起**：`asio::post` 取消闭包到该 Runtime 的 io_context。
   闭包（JS 线程）内：
   - `entry->signal_impl->abort(ctx)`——`request_stop()` 经 stop_callback 取消
     底层 socket（`abort.hpp:37-48` 链路已存在），并 dispatch `abort` 事件；
   - 经 once 守卫立即 `settle(false,"cancelled")`——**调用端在取消瞬间拿到结果**；
     底层 IO 收尸在后台进行，trampoline 迟到的 settle 被 once 守卫挡掉。
3. **Running 且同步 JS 执行中**（CPU 密集/死循环）：置该 Runtime 的
   interrupt 原子标志（`JS_SetInterruptHandler`，quickjs.h:1180）；引擎在字节码
   边界抛错，trampoline 的 reject 分支收尾。

精度对照（机制相同，精度由拓扑决定）：

| 场景                                          | 共享实例（normal）                               | 池实例（debug，一实例一任务） |
| --------------------------------------------- | ------------------------------------------------ | ----------------------------- |
| 取消异步任务，循环健康                        | 精确（闭包 + signal）                            | 精确                          |
| 取消同步卡死任务                              | 精确——卡死任务即当前执行任务                     | 精确                          |
| 取消异步任务时循环正卡在**别的**任务的同步 JS | interrupt 误伤当前任务；目标随后仍被闭包精确取消 | 不存在（单任务）              |

### 5.4 为什么取消用 asio::post 而不是 channel（讨论结论）

- `co::oneshot` 的完成发生在 **send 所在线程**（`channel.hpp:26-29`）：接收端要
  在 JS 线程干活必须 `continues_on(js_sched)`，而 `continues_on` 的实现就是
  `post(ioc, exec::asio::use_sender)`——channel 不会替代 post，只会把 post 包在里面。
- channel 版取消需要每个任务额外 spawn 一个 watcher 协程（`co_await cancel_rx`），
  正常结束时还要回收它；每任务多一个 spawn + 一套 channel 对象，底层机制不变。
- 取消是朝事件循环的 fire-and-forget 控制信号，**没有值消费者**；channel 的价值
  在于有消费者在等值（结果通道 B 正是这种场景，保留）。
- `asio::post` 是本代码库既有跨线程机制：`Runtime::stop()` 即 `asio::post`
  （`loop.hpp:92-95`），设计文档 §8.1 不变量 2 同。io_context 是 asio 唯一
  线程安全对象；post 同时解决"唤醒阻塞在 IOCP/epoll 的 `run_one`"。闭包在
  `run_one` 内执行 = 在 JS 线程执行，不违反线程亲和。
- 观感问题用封装解决：取消入口就是 `TaskRunner::cancel(id)`，调用方不见 asio。

## 6. 已知限制 / 实现时验证点

- `setTimeout` 等 web 定时器是否计入 `pending_` 未验证：若不计入，池 worker 的
  `run_to_completion` 对"await 定时器后再结算"的任务会提前退出 → 走
  "settle 未调用"补发 error。v1 接受；需要时再把 timer 纳入 `pending_`。
  （共享实例跑 `run()` 服务模式无此问题——循环本来就不会退出。）
- channel B 的完成发生在任务 settle 所在线程（`channel.hpp:26-29`）：调用端
  `co_await result_rx` 后在该线程恢复；重活要 `continues_on` 回自己的调度器。
- 20 worker = 20 线程：仅 debug 场景建议开满。
- 永不结算且无任何在飞异步的 JS（`new Promise(()=>{})` 型）：池路径靠
  "settle 未调用"补发 error 兜底；共享实例路径（服务模式）只能依赖取消。

## 7. 关闭协议

- **TaskRunner**：不拥有 Runtime，无关闭职责；宿主按既有协议停 Runtime
  （`stop()` → `shutdown()`，在飞任务的 promise 以 AbortError reject，
  trampoline 的 catch 分支经 settle 把 error 结果送回各调用端）。
- **TaskPool::shutdown()**：置拒收标志 → 锁内清空 `queue`（全部置 cancelled）→
  全部 worker 置退出标志 + cv notify_all → join 各线程 → Runtime 在各自 worker
  线程上析构（走既有 `shutdown()` 协议，`loop.hpp:98-131`）。
