# C++26 执行器模型（std::execution / P2300）使用指南

> 本文档讲解 C++26 标准执行器模型（P2300 `std::execution`，senders/receivers）的
> **使用方法**：怎么启动任务、协程环境怎么用、普通函数怎么用、发射后不理、切换执行器、
> 取消、编排、结构化并发，以及怎么把回调式 C API 包成 sender。
>
> 所有示例均基于本仓库克隆的参考实现 `third_party/stdexec`（stdexec 是 P2300 的参考
> 实现，`std::execution` 与它几乎一一对应）。**版本锚定：commit `f0e8ae6f`（约 v0.11.0，
> nvhpc-26.05 基线）**——stdexec 的 API 随版本漂移较快，升级克隆后请重新核对示例。
>
> **不需要 C++26 工具链**：stdexec 只要求 C++20（见[第 1 节](#1-工具链与接入)）。
> 本文核心示例已用 Clang 22 + 本克隆编译并运行验证；未来切到标准库时，把 `stdexec::`
> 换成 `std::execution::` 即可（`exec::` 扩展没有标准对应物，见
> [1.4](#14-与标准库的对应关系)）。

## 目录

- [0. 一句话模型](#0-一句话模型)
- [1. 工具链与接入](#1-工具链与接入)
- [2. 核心概念](#2-核心概念)
- [3. 头文件与命名空间](#3-头文件与命名空间)
- [4. 怎么启动：总览](#4-怎么启动总览)
- [5. 在普通函数中启动](#5-在普通函数中启动)
- [6. 在协程环境中启动](#6-在协程环境中启动)
- [7. 切换执行器](#7-切换执行器)
- [8. 取消（Cancellation）](#8-取消cancellation)
- [9. 编排（组合子）](#9-编排组合子)
- [10. 结构化并发](#10-结构化并发)
- [11. 生命周期与 RAII](#11-生命周期与-raii)
- [12. 进阶设施](#12-进阶设施)
- [13. 与回调式 API 互操作](#13-与回调式-api-互操作)
- [14. 常见编译错误速查](#14-常见编译错误速查)
- [15. 附录：速查表](#15-附录速查表)

---

## 0. 一句话模型

**Sender（发送者）** 是"异步计算的配方"——它描述 _要做什么_，但本身不执行。
**Receiver（接收者）** 是执行结果的汇——约定三个完成通道：`set_value` / `set_error` / `set_stopped`。
**Scheduler（调度器）** 表示一个执行上下文（线程池、事件循环等），`schedule(sched)` 产生一个
"在这个上下文上跑一次"的 sender。
把 sender **connect** 到 receiver 得到 **operation state（操作状态）**，对它 **start** 才会真正开始执行。

```text
sender（配方）--connect--> operation state（活体）--start--> 执行 --> receiver（三个完成通道之一）
```

要点：

- sender 是**惰性**的：光构造 sender 不产生任何副作用；只有 `start` 之后副作用才发生。
- sender 是**值语义、可组合**的：用适配器（`then`、`when_all`、`upon_error` …）把它们拼成更大的 sender。
- 完成通道是**唯一的**：一个操作恰好完成一次（value 或 error 或 stopped），且调用完成函数之后
  操作状态立刻失效，实现可以立刻回收它——所以**完成回调里不能再用 receiver/opstate**。
- 组合子负责把子 sender 的完成重新路由给上层 receiver，业务代码不需要自己写回调样板。

---

## 1. 工具链与接入

### 1.1 只需要 C++20

stdexec 把 P2300 回植到了 C++20——**不需要 C++26 工具链**：

- 语言标准：**C++20**（库通过 `target_compile_features(... cxx_std_20)` 要求；
  仅当开启实验性的 `STDEXEC_BUILD_MODULES` 时才需要 C++23，默认关闭）。
- 编译器：需要较新的主流编译器（GCC / Clang / MSVC 近年版本）。具体支持矩阵随版本变动，
  以 `third_party/stdexec/README.md` 和它的 CI 配置为准，本文不抄录。
  实测备注（Windows + 本克隆）：MSYS2 UCRT64 的 **GCC 16.1** 编译 stdexec 时
  cc1plus 会静默崩溃（无任何错误输出即退出）；同环境的 **Clang 22** 编译运行全部正常，
  本文示例即用 Clang 22 验证。Windows 上踩到 GCC 崩溃就换 Clang 或 MSVC。
- 用 CMake target 接入时，必要的编译选项会自动带上：
  - MSVC：`/Zc:__cplusplus /Zc:preprocessor /Zc:externConstexpr /bigobj`
  - GCC：`-fcoroutines`
- 线程库：CMake target 会传递链接 `Threads::Threads`（Linux/macOS 的 pthread；
  Windows 上无额外依赖）。

### 1.2 CMake 接入

```cmake
# 作为子项目引入时关掉不需要的部分
set(STDEXEC_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(STDEXEC_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(STDEXEC_INSTALL OFF CACHE BOOL "" FORCE)
add_subdirectory(third_party/stdexec)

target_link_libraries(your_target PRIVATE STDEXEC::stdexec)
```

- `stdexec` 默认是**纯头文件** `INTERFACE` 库（`STDEXEC::stdexec` 是它的别名 target），
  不编译任何源文件。要求 CMake ≥ 3.28。
- 不用 CMake 也可以：头文件直接 `-I third_party/stdexec/include` 即可使用。
  但官方推荐走 CMake target，因为 1.1 里那些编译选项由 target 自动设置。
- 可选组件（默认均 OFF，详见 `third_party/stdexec/CMakeLists.txt`）：
  `STDEXEC_BUILD_PARALLEL_SCHEDULER`（系统级并行调度器，见 [12.4](#124-系统级并行调度器get_parallel_scheduler)）、
  `STDEXEC_ENABLE_ASIO`（Asio 适配器 `exec::asio`，见 12.6.6）、
  `STDEXEC_BUILD_MODULES`、`STDEXEC_ENABLE_CUDA`、`STDEXEC_ENABLE_IO_URING` 等。
  Windows 上 `STDEXEC_ENABLE_WINDOWS_THREAD_POOL` 按 `windows.h` 探测自动开启（见 [12.5](#125-windows-线程池后端windows_thread_pool)）。

### 1.3 版本锚定与 API 漂移

stdexec 跟随标准草案持续演进，老名字不断被改名（保留 `[[deprecated]]` 别名）。
本克隆（`f0e8ae6f`）里的新旧名对照：

| 旧名（deprecated）                            | 当前名                                        |
| --------------------------------------------- | --------------------------------------------- |
| `start_on`                                    | `stdexec::starts_on`                          |
| `transfer`                                    | `stdexec::continues_on`                       |
| `stdexec::read`                               | `stdexec::read_env`                           |
| `exec::write` / `exec::write_env`             | `stdexec::write_env`                          |
| `exec::on`                                    | `stdexec::on`                                 |
| `exec::inline_scheduler`                      | `stdexec::inline_scheduler`                   |
| `stdexec::split` / `ensure_started` / `start_detached` | `exec::split` / `exec::ensure_started` / `exec::start_detached` |
| 头文件 `exec/repeat_effect_until.hpp`         | `exec/repeat_until.hpp`                       |
| `exec/system_context.hpp` / `get_system_scheduler` | `stdexec::get_parallel_scheduler`（见 12.4） |

本文一律使用"当前名"。注意 **`exec::reschedule` 不是 deprecated**——它是正经的扩展算法。

### 1.4 与标准库的对应关系

- `stdexec::` ≈ 未来的 `std::execution::`（P2300 + P3149 + P3325 的内容）。迁移时机械替换
  命名空间即可，但实现细节（如 `on()` 的回退调度器行为）以标准文案为准。
- `exec::` 是 NVIDIA 的实验扩展命名空间（= `experimental::execution`），**没有标准对应物**：
  `async_scope`、`static_thread_pool`、`single_thread_context`、`task`（扩展版）、`when_any`、
  `split`、`ensure_started`、`start_detached`、`timed_thread_context`、`at_coroutine_exit`、
  `create` 等。其中 `async_scope` 的思想已标准化为 `counting_scope`（API 不同，见
  [10.3](#103-stdexeccounting_scope--simple_counting_scope标准)）；具体线程池未来可能由
  "system context / parallel scheduler" 系列提案覆盖（见 [12.4](#124-系统级并行调度器get_parallel_scheduler)）。

---

## 2. 核心概念

| 概念                  | 说明                                                                                                | 判定概念 / 设施            |
| --------------------- | --------------------------------------------------------------------------------------------------- | -------------------------- |
| `sender`              | 描述异步操作；声明它能以哪些方式完成（completion signatures）                                       | `stdexec::sender`          |
| `receiver`            | 完成信号的汇：`set_value(vs...)` / `set_error(e)` / `set_stopped()`                                 | `stdexec::receiver`        |
| `scheduler`           | 执行上下文；`schedule(s)` 返回"在该上下文执行一次"的 sender                                         | `stdexec::scheduler`       |
| operation state       | `connect(s, r)` 的结果；`start(op)` 启动；`op` 不可移动                                             | `connect_result_t`         |
| environment           | 接收者附带的环境，用 CPO 查询：`get_scheduler`、`get_start_scheduler`、`get_stop_token`、`get_allocator`… | `env_of_t`                 |
| completion signatures | 编译期的完成签名集合，如 `completion_signatures<set_value_t(int), set_error_t(std::exception_ptr)>` | `completion_signatures_of_t` |
| sender adaptor        | 接受 sender、返回新 sender 的组合器（`then`、`upon_error`、`when_all` …），支持管道写法 `sndr \| then(f)` | —                          |

三个完成通道的约定：

- `set_value(vs...)`：成功，携带结果值。
- `set_error(e)`：失败，携带错误（通常 `std::exception_ptr`）。
- `set_stopped()`：被取消/主动放弃，**没有值**。
- 发送方在调用完成函数**之前**必须把所有资源状态切换到"已就绪"，完成后立刻丢弃内部状态。

---

## 3. 头文件与命名空间

stdexec 里有两层命名空间：

```cpp
#include <stdexec/execution.hpp>       // 核心 + P2300 标准算法（stdexec:: 命名空间）
#include <exec/static_thread_pool.hpp>  // stdexec 扩展（exec:: 命名空间）
```

| 命名空间                             | 内容                                                                                                                                                                                                         | 对应标准                                |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------- |
| `stdexec`（内部宏 `STDEXEC`）        | P2300 标准 API：`schedule`、`then`、`when_all`、`sync_wait`、`just`、`on`、`starts_on`、`continues_on`、`get_scheduler`、`get_stop_token`、`task`、`run_loop`、`spawn`、`spawn_future`、`counting_scope`、`read_env`、`write_env`、`prop`、`inline_scheduler`… | 未来 `std::execution`                   |
| `exec`（=`experimental::execution`） | 参考实现扩展：`static_thread_pool`、`single_thread_context`、`async_scope`、`start_detached`、`split`、`ensure_started`、`when_any`、`finally`、`repeat_until`、`unless_stop_requested`、`reschedule`、`task`（扩展版）、`timed_thread_context`、`create`、`at_coroutine_exit`… | 部分将进 C++26 之后的修订（LWG/P 提案） |

常用头文件：

```cpp
#include <stdexec/execution.hpp>          // 一切核心：sender/receiver/CPO/sync_wait/stdexec::task/run_loop
                                         //   /spawn/spawn_future/counting_scope/read_env/write_env/prop
#include <exec/static_thread_pool.hpp>    // exec::static_thread_pool（多线程池）
#include <exec/single_thread_context.hpp> // exec::single_thread_context（单线程）
#include <exec/start_detached.hpp>        // exec::start_detached（发射后不理）
#include <exec/async_scope.hpp>           // exec::async_scope（结构化并发）
#include <exec/task.hpp>                  // exec::task、exec::reschedule_coroutine_on
#include <exec/reschedule.hpp>            // exec::reschedule（迁移到环境的 start scheduler）
#include <exec/when_any.hpp>              // exec::when_any（竞争）
#include <exec/finally.hpp>               // exec::finally（清理 sender）
#include <exec/split.hpp>                 // exec::split（广播，可多次订阅）
#include <exec/ensure_started.hpp>        // exec::ensure_started（立即启动+缓存，单次订阅）
#include <exec/repeat_until.hpp>          // exec::repeat_until / repeat_effect_until（循环）
#include <exec/unless_stop_requested.hpp> // exec::unless_stop_requested（停止检查）
#include <exec/just_from.hpp>             // exec::just_from（惰性 just）
#include <exec/timed_thread_scheduler.hpp>// exec::timed_thread_context / timed_thread_scheduler
#include <exec/timed_scheduler.hpp>       // exec::now / exec::schedule_at / exec::schedule_after（CPO）
#include <exec/at_coroutine_exit.hpp>     // exec::at_coroutine_exit（协程清理）
#include <exec/on_coro_disposition.hpp>   // exec::on_coroutine_succeeded / stopped / failed
#include <exec/create.hpp>                // exec::create（把回调包成 sender）
#include <exec/materialize.hpp>           // exec::materialize / dematerialize
#include <exec/trampoline_scheduler.hpp>  // exec::trampoline_scheduler（防递归栈溢出）
#include <exec/asio/use_sender.hpp>       // exec::asio::use_sender（Asio 完成令牌 → sender）
#include <exec/asio/asio_thread_pool.hpp> // exec::asio::asio_thread_pool（Asio 版线程池）
                                         //   ↑ exec::asio 需 STDEXEC_ENABLE_ASIO=ON（见 12.6.6）
#include <stdexec/stop_token.hpp>         // inplace_stop_source / inplace_stop_token / inplace_stop_callback
```

> 注意：`stdexec/coroutine.hpp` 只有内部协程设施，不需要直接包含；
> `stdexec::task` 由 `<stdexec/execution.hpp>` 提供。
>
> 改名与 deprecated 别名见 [1.3](#13-版本锚定与-api-漂移)。特别提醒：`exec::on` 是
> deprecated 别名（用 `stdexec::on`）；`exec::reschedule` **没有** deprecated。

---

## 4. 怎么启动：总览

"启动"在 senders 世界里有五种典型方式，按场景选择：

| 场景                                    | 方式                                                                                        | 头文件                                       | 生命周期             |
| --------------------------------------- | ------------------------------------------------------------------------------------------- | -------------------------------------------- | -------------------- |
| 同步阻塞等待结果                        | `stdexec::sync_wait(sndr)`                                                                  | `stdexec/execution.hpp`                      | 栈上，函数返回即结束 |
| 发射后不理（fire-and-forget，不跟踪）   | `exec::start_detached(sndr)`                                                                | `exec/start_detached.hpp`                    | 堆上，自己删除自己   |
| 发射后不理（标准版，必须有 scope 收养） | `stdexec::spawn(sndr, token)`                                                               | `stdexec/execution.hpp`                      | scope 持有           |
| 发射进 scope 且想拿结果                 | `scope.spawn_future(sndr)` / `stdexec::spawn_future(sndr, token)`                           | `exec/async_scope.hpp` / `stdexec/execution.hpp` | scope 持有           |
| 完全手动控制生命周期                    | `connect(sndr, rcvr)` + `start(op)`                                                         | `stdexec/execution.hpp`                      | 你说了算             |

另外在**协程里**，sender 可以直接 `co_await`（见[第 6 节](#6-在协程环境中启动)），
协程本身再通过上面五种方式之一启动。

---

## 5. 在普通函数中启动

### 5.1 sync_wait：阻塞等待结果

`sync_wait(sndr)` 把 sender 原地跑完并阻塞当前线程直到完成：

```cpp
#include <stdexec/execution.hpp>
#include <exec/static_thread_pool.hpp>

using namespace stdexec;

int main()
{
  exec::static_thread_pool pool{8};          // 8 个线程的池
  scheduler auto sch = pool.get_scheduler(); // 拿到调度器

  sender auto work = schedule(sch)                       // 在池上跑一次
    | then([] { return 13; })                            // 返回值 13
    | then([](int x) { return x + 42; });                // 55

  auto [result] = sync_wait(std::move(work)).value();    // std::optional<std::tuple<int>>
  std::cout << result << '\n';                           // 55
}
```

语义：

- 返回值是 `std::optional<std::tuple<Ts...>>`：**值**为各 `set_value` 参数；
- sender 以 `set_stopped()` 结束 → 返回 `std::nullopt`；
- sender 以 `set_error(e)` 结束 → **抛出** `e`（`std::exception_ptr` 会 `std::rethrow_exception`）。
- `sync_wait` 内部自带一个 `stdexec::run_loop` 作为调度上下文：它的环境同时应答
  `get_scheduler` / `get_start_scheduler` / `get_delegation_scheduler`（都指向这个
  run_loop 的 scheduler），所以"谁调用 sync_wait，完成就回到谁的线程上"（见下例）。

```cpp
// 零参的 get_scheduler() 是一个 sender（等价于 read_env(get_scheduler)）：
auto [sch2] = sync_wait(get_scheduler()).value();   // 拿到 sync_wait 提供的调度器（run_loop）
```

> 限制：
>
> - sender 必须**恰好有一个 `set_value` 完成签名**（编译期静态断言）。
>   `when_all(a, b)` 产出的扁平 `set_value(x, y)` 也算"一种"，合法。
>   有多种成功形态的 sender 请改用 `stdexec::sync_wait_with_variant()`（返回 variant-of-tuples）。
> - 不可取消：环境不提供 stop token（查询回退到 `never_stop_token`）。
> - `sync_wait` 只能在**非协程函数**里用（它内部是阻塞的）。

### 5.2 start_detached：发射后不理（fire-and-forget）

```cpp
#include <exec/start_detached.hpp>

exec::static_thread_pool pool{4};

void kick_off_logging(std::string msg)
{
  exec::start_detached(
    schedule(pool.get_scheduler())
    | then([msg = std::move(msg)]() noexcept {
        // 在线程池上做后台工作，没有人等待结果
        write_log(msg);
      }));
}
```

要点：

- 立即 `connect + start`，操作状态**堆上分配**（可用环境里的 allocator 定制），
  完成后**自己 delete 自己**，调用方无需管理。
- 不允许 `set_error`，但**不是编译期拦截**：头文件注释声称有静态断言，代码里实际
  没有——会失败的 sender 照样编译通过，出错时内置 receiver 的 `set_error` 直接
  `std::terminate()`（见 `exec/start_detached.hpp`）。想要**编译期**拒绝，用
  `stdexec::spawn`（见 5.3）。业务可能失败时，先 `| upon_error(...)` 把错误吞掉或记录下来。
- **没有 scope 收养**：程序退出时这些工作可能还在飞。如果需要"退出前等所有后台任务做完"，
  用 `async_scope`（见[第 10 节](#10-结构化并发)）或 `stdexec::spawn`。

> 小贴士：`then` / `upon_error` 等适配器会按 lambda **是否 `noexcept`** 决定是否给完成签名
> 附加 `set_error_t(std::exception_ptr)`。凡是最终喂给 `start_detached` / `stdexec::spawn`
> 的链，把收尾 lambda 标成 `noexcept`（并确保前面已兜底），否则 `spawn` 会在编译期拒绝、
> `start_detached` 则留下 terminate 的口子。

### 5.3 stdexec::spawn / spawn_future：标准化的 fire-and-forget

C++26 标准（P3149）的 `stdexec::spawn` 也做"发射后不理"，但它**要求操作被一个异步
scope 收养**（通过 scope 的 token 关联），以便 scope 关闭/join 时能保证它们结束：

```cpp
#include <stdexec/execution.hpp>
#include <exec/static_thread_pool.hpp>
#include <exec/async_scope.hpp>

int main()
{
  exec::static_thread_pool pool{2};

  // 方式 A：标准 API —— 用 scope token 收养（stdexec::counting_scope 提供 get_token()）
  stdexec::counting_scope scope;
  stdexec::spawn(
    schedule(pool.get_scheduler()) | then([]() noexcept { /* ... */ }),
    scope.get_token());
  // 注意 noexcept：then 的 lambda 可抛时会附加 set_error_t(exception_ptr) 签名，
  // 而 spawn 在编译期就拒绝会失败的 sender

  scope.close();                       // 不再接受新任务
  sync_wait(scope.join());             // 等 scope 里所有任务结束

  // 方式 B：exec::async_scope（stdexec 扩展，更常用）
  exec::async_scope scope2;
  scope2.spawn(schedule(pool.get_scheduler()) | then([] { /* ... */ }));
  sync_wait(scope2.on_empty());        // 或 scope2.request_stop(); sync_wait(scope2.on_empty());
}
```

签名与约束：

- `stdexec::spawn(sndr, token)` / `stdexec::spawn(sndr, token, env)`：env 可为子操作注入
  额外环境（allocator 等）。**编译期**要求 sender 不可能 `set_error`
  （`requires __never_sends<set_error_t, ...>`；不满足时落到诊断重载，报
  `static_assert: "spawn expects a sender that cannot fail"`）。
  内部执行 `token.wrap(sndr)` + 关联到 scope。
- `stdexec::spawn_future(sndr, token)` / `(sndr, token, env)`：返回一个**能等到结果的
  sender**（像 `std::async` 的 future）。
- 日常代码直接 `async_scope.spawn(...)` / `spawn_future(...)` 更简单；但注意
  `exec::async_scope::spawn` 对失败**没有**编译期拦截（出错 terminate，见 10.2）。

```cpp
exec::async_scope scope;

sender auto fut = scope.spawn_future(
  schedule(pool.get_scheduler()) | then([] { return 42; }));

// 可以在别处 co_await / sync_wait 这个 sender：
auto [n] = sync_wait(std::move(fut) | stopped_as_optional()).value();
// 注意：fut 只能被连接一次；没人连它时结果会被丢弃（无泄漏）
```

### 5.4 connect + start：完全手动控制

当你不想要堆分配、不需要等待、要自己精确控制 opstate 生存期时，直接 connect + start：

```cpp
#include <stdexec/execution.hpp>
#include <exec/static_thread_pool.hpp>
#include <latch>

using namespace stdexec;

struct my_receiver
{
  using receiver_concept = receiver_tag;

  std::latch& done;                              // 用来通知"操作已完成"

  void set_value(int v) noexcept
  {
    std::cout << "got " << v << '\n';
    done.count_down();
  }

  void set_error(std::exception_ptr e) noexcept
  {
    try { std::rethrow_exception(e); }
    catch (std::exception const& ex) { std::cerr << "err: " << ex.what() << '\n'; }
    done.count_down();
  }

  void set_stopped() noexcept
  {
    std::cout << "stopped\n";
    done.count_down();
  }

  auto get_env() const noexcept
  {
    return prop{get_stop_token, never_stop_token{}};   // 环境：不可取消
  }
};

int main()
{
  exec::static_thread_pool pool{1};
  std::latch done{1};

  auto op = connect(schedule(pool.get_scheduler()) | then([] { return 7; }),
                    my_receiver{done});
  start(op);      // 立即返回；操作在池线程上异步执行
  done.wait();    // op 是栈对象，必须等完成回调之后才能析构！
}
```

规则：

- **opstate 不可移动、不可拷贝**，必须在 `connect` 的上下文中存到一个比操作寿命长的存储里。
- `start(op)` 只调用一次；一旦完成函数被调用，opstate 立即失效。
- `schedule(pool...)` 这类 sender 是**异步入队**的：`start()` 返回时操作还没跑完，
  opstate 必须活到完成回调之后（上例用 latch 保证）。若忘了等，就是最典型的
  opstate 生命周期 UB。
- 这条路径是其余所有启动方式的基石，但业务代码**几乎不需要**直接用它，
  除非你在写自定义 receiver（例如给 C 回调做适配器，见[第 13 节](#13-与回调式-api-互操作)）。

### 5.5 run_loop：自己驱动事件循环

`stdexec::run_loop` 是一个"由你手动 run 的循环"，scheduler 把任务投进队列，`run()` 消费：

```cpp
#include <stdexec/execution.hpp>
#include <exec/start_detached.hpp>
using namespace stdexec;

int main()
{
  run_loop loop;

  exec::start_detached(     // 丢进 run_loop（fire-and-forget，需 <exec/start_detached.hpp>）
    schedule(loop.get_scheduler()) | then([&loop]() noexcept {
      std::cout << "tick\n";
      loop.finish();        // 在任务里关闭循环：run() 才会返回
    }));

  loop.run();               // 阻塞处理队列，直到 finish() 被调且队列排空
}
```

要点：

- `run()` 的退出条件是：**`finish()` 已被调用，且队列排空，且在飞任务归零**。
  光把任务跑完它不会返回——必须有人调 `finish()`。
- `finish()` 可以从任意线程调用，也可以从队列里的任务中调用（`sync_wait` 内部
  就是这样退出它的 run_loop 的）；重复调用安全。
- 所以把 `loop.finish()` 顺序写在 `loop.run()` **后面**会死锁——`run()` 永远不返回，
  `finish()` 永远执行不到。

典型用途：把事件循环塞进你自己的线程（`exec::single_thread_context` 就是这么实现的）、
给 GUI/游戏主循环集成、实现 `sync_wait` 之类的手动阻塞等待。

---

## 6. 在协程环境中启动

### 6.1 两种协程类型：stdexec::task 和 exec::task

| 类型               | 头文件                  | 特点                                                                                                              |
| ------------------ | ----------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `stdexec::task<T>` | `stdexec/execution.hpp` | P2300 标准协程；`co_await` 任何 sender；取消/执行器靠环境传播                                                     |
| `exec::task<T>`    | `exec/task.hpp`         | 扩展版：**调度亲和**（默认粘在启动它的调度器上）、支持 `co_await exec::reschedule_coroutine_on(sched)` 切换       |

写异步业务代码就是写协程：

```cpp
#include <stdexec/execution.hpp>
#include <exec/static_thread_pool.hpp>
#include <exec/task.hpp>    // exec::task

using namespace stdexec;

// 普通函数风格 + 协程：
auto fetch_and_add(exec::static_thread_pool& pool) -> exec::task<int>
{
  // co_await 一个 sender：单值解包成裸值、错误抛出、停止则向上传播（见 6.2）
  // 注意括号：co_await 优先级高于 |，管道必须整体括起来（见 6.2 末尾的陷阱说明）
  int a = co_await (schedule(pool.get_scheduler())
                  | then([] { return 20; }));
  int b = co_await (schedule(pool.get_scheduler())
                  | then([] { return 22; }));
  co_return a + b;                          // 42
}

int main()
{
  exec::static_thread_pool pool{2};
  auto [ans] = sync_wait(fetch_and_add(pool)).value();
  std::cout << ans << '\n';
}
```

### 6.2 co_await 的语义

在 `stdexec::task` / `exec::task` 里 `co_await sndr`：

| 上游完成                          | `co_await` 表达式的行为                       |
| --------------------------------- | --------------------------------------------- |
| `set_value()`                     | `void`                                        |
| `set_value(v)`（恰好一个值）      | **`v` 本身（裸值，不是 tuple！）**            |
| `set_value(v1, v2, …)`（多个值）  | `std::tuple<...>`（decayed）                  |
| `set_error(e)`                    | **抛出** `e`                                  |
| `set_stopped()`                   | 见下面的精确语义                              |

> 对比：`sync_wait` 的返回**总是** `std::optional<std::tuple<...>>`，所以
> `auto [v] = sync_wait(...).value()` 对单值也成立；而 `co_await` 对单值给裸值，
> 要写 `int a = co_await ...`，`auto [a] = co_await ...` 只对多值结果成立。
>
> 陷阱：`co_await` 的优先级**高于** `|`——`co_await a | then(f)` 会被解析成
> `(co_await a) | then(f)`（然后编译报错 `'void' does not satisfy 'sender'`）。
> `co_await` 一个管道时务必整体加括号：`co_await (a | then(f))`。

`set_stopped()` 的精确语义：等待中的协程**不再被 resume**；停止信号沿 promise 链向上
找 `unhandled_stopped()`——`stdexec::task` / `exec::task` 都有，于是停止逐层向外传播；
协程作为 sender 被 connect 时（`sync_wait`、`when_all`、`spawn` 等），最外层的
`unhandled_stopped` 变成对下游 receiver 的 `set_stopped`。如果某层 promise 没有
`unhandled_stopped()`（比如你自己的普通协程类型），默认回调是 `std::terminate()`。

协程本身是 sender：`stdexec::task<T>` 和 `exec::task<T>` 的完成签名都是
`set_value_t(T)`（`T = void` 时为 `set_value_t()`）/ `set_error_t(std::exception_ptr)` /
`set_stopped_t()`，所以它可以被 `when_all`、`then` 等组合，也可以被 `sync_wait` 直接等。

### 6.3 协程里查询执行环境

协程的 promise 里可以直接用这些"查询"（零参调用时是一个 sender，等价于
`read_env(query)`，值 = 查询结果）：

```cpp
auto query_env() -> exec::task<void>
{
  scheduler auto sch = co_await get_scheduler();      // 当前在哪执行？(sender 形式)
  auto tok = co_await get_stop_token();               // 当前 stop token
  (void) sch; (void) tok;
  co_return;
}
```

- 这套零参写法在普通函数里同样有效，例如 `sync_wait(get_scheduler())`。
- 相关的第三个查询是 `get_start_scheduler()`（"本操作在哪个调度器上启动的"，见
  [第 7 节](#72-get_start_scheduler回家机制)）。
- stdexec 扩展（非标准）：env 不应答 `get_scheduler` 但应答 `get_start_scheduler` 时，
  `get_scheduler` 查询会回退到后者。`exec::task` 的 context 就是只应答
  `get_start_scheduler`，靠这个回退让 `co_await get_scheduler()` 可用。

### 6.4 协程里切换执行器

`exec::task` 支持把协程"搬家"到别的执行器上继续跑：

```cpp
#include <exec/task.hpp>

auto worker(exec::single_thread_context& io,
            exec::single_thread_context& ui) -> exec::task<void>
{
  // ... 在调用方的执行器上做轻量准备 ...

  co_await exec::reschedule_coroutine_on(io.get_scheduler());   // 切到后台线程
  do_heavy_work();                                              // 在后台线程上跑

  co_await exec::reschedule_coroutine_on(ui.get_scheduler());   // 切到 UI 线程
  update_ui();                                                  // 在 UI 线程上跑
}
```

> `reschedule_coroutine_on` 做三件事：把 continuation 投递到给定 scheduler 上恢复执行；
> 把协程的 **home scheduler 更新为新 scheduler**（之后每次 `co_await` 结束都回到新 home）；
> 并注册协程退出时的清理（`at_coroutine_exit`）。Apple Clang 上不可用。
>
> 注意：它会把调度器**类型擦除**后存进 task 的 context（`exec/any_sender_of.hpp` 的
> `any_scheduler`），个别调度器类型擦除不进去会编译失败——本版本里
> `static_thread_pool` 的 scheduler 在 Clang 下就擦除不了；库自带测试用的是
> `single_thread_context` 的 scheduler，最稳妥。
>
> exec::task 的"调度亲和"：每次 `co_await` 一个 sender 后，协程自动调度回 home
> scheduler（除非被 await 的 sender 保证"在哪启动就在哪完成"）。home 的初始值 =
> 启动时父环境的 `get_start_scheduler`。

### 6.5 启动一个协程任务（汇总）

协程写好了之后，用第 4 节的五种方式启动它：

```cpp
// 1) 阻塞等结果（main 或普通线程里）：
auto [v] = sync_wait(my_task()).value();

// 2) 发射后不理：task 的完成签名带 set_error/set_stopped，
//    start_detached 出错会 terminate，所以先全部兜底（注意 noexcept，见 5.2）：
exec::start_detached(my_task()
  | upon_error([](std::exception_ptr e) noexcept { log_error(e); })
  | upon_stopped([]() noexcept { /* 停止时兜底 */ }));

// 3) 进 scope 跟踪：
exec::async_scope scope;
scope.spawn(my_task());

// 4) 进 scope 并拿结果：
sender auto fut = scope.spawn_future(my_task());

// 5) 手动：
auto op = connect(my_task(), my_receiver{});
start(op);
```

> 注意：`exec::task` 启动/`co_await` 时要求**父环境能应答 `get_start_scheduler`**，
> 否则 `static_assert`：`"exec::task<T> cannot be co_await-ed in a coroutine that does
> not have an associated start scheduler."`。`sync_wait` 的环境提供它；裸
> `exec::start_detached(my_task())` 走 root env 的 `inline_scheduler` 回退，通常也没问题。
> `when_all` 里的多个 `exec::task` 共享同一个环境，即共享同一个 start scheduler。

---

## 7. 切换执行器

调度上下文迁移是 senders 模型最核心的能力之一。

### 7.1 迁移算法

| 算法                                | 作用                                                                      | 管道写法                        |
| ----------------------------------- | ------------------------------------------------------------------------- | ------------------------------- |
| `stdexec::starts_on(sched, sndr)`   | **在 sched 上启动** sndr；启动之后 sndr 内部自己调度自己                  | **无管道形式**                  |
| `stdexec::continues_on(sndr, sched)`| sndr **完成后**迁移到 sched 上继续（执行下游）                            | `sndr \| continues_on(sched)`   |
| `stdexec::on(sched, sndr)`（形式 1）| 在 sched 上启动 sndr，完成后**迁回"启动处"的调度器**                      | 无（会遮住形式 2）              |
| `stdexec::on(sndr, sched, closure)`（形式 2）| sndr 原地跑 → 切到 sched 应用 closure → 切回启动处调度器          | `sndr \| on(sched, closure)`    |
| `exec::reschedule`                  | 迁移到 receiver 环境的 `get_start_scheduler`                              | `sndr \| exec::reschedule()`    |
| `stdexec::schedule_from`            | `continues_on` 的内部构件（本版本仅单参标记用途）                         | 业务代码别直接用                |

⚠ `on()` 是最容易被误解的算法：**完成后不是留在 sched 上，而是回到"启动处"的调度器**。
等价关系：

```text
on(sched, sndr)          = continues_on(starts_on(sched, sndr), old_sched)
on(sndr, sched, closure) = sndr 原地完成 → continues_on(·, sched) → 应用 closure
                           → continues_on(·, old_sched)
```

`old_sched` 从下游 receiver 环境的 `get_start_scheduler` 读取；root env（裸 connect）
回退到 `inline_scheduler`；自定义 env 不提供 → 编译错误
`_CANNOT_RESTORE_EXECUTION_CONTEXT_AFTER_ON_`（见[第 14 节](#14-常见编译错误速查)）。

```cpp
using namespace stdexec;

exec::static_thread_pool    pool{4};
exec::single_thread_context ui;              // 单线程，模拟 UI 线程

sender auto pipeline =
  just()                                     // 在调用方线程内联完成
  | on(pool.get_scheduler(),                 // 形式 2：切到池上应用闭包，
       then([] { return heavy_compute(); })) //   完成后回到启动处调度器（这里是 sync_wait 的 run_loop）
  | continues_on(ui.get_scheduler())         // 再迁到 UI 线程
  | then([](int r) { update_ui(r); });       // 在 UI 线程上跑

sync_wait(std::move(pipeline));
```

`starts_on` 没有管道形式，要写成嵌套：

```cpp
sender auto s =
  starts_on(pool.get_scheduler(),             // 整体在池上启动并留在池上
            just(42) | then([](int x) { return x * 2; }));
```

`exec::reschedule` 的典型用法：把当前环境里的 scheduler 当作"回到这里"的目标，
常用于回调 API 与 sender 世界对接（C 回调进来后 `| exec::reschedule()` 回到线程池/事件循环）。
注意管道里要写 `exec::reschedule()`（零参调用返回闭包），不是裸的 `exec::reschedule`。

> 性能提示：每次 `on/continues_on` 都会经过一次队列投递 + 唤醒，链太长有额外开销；
> 高频路径上尽量少迁移。

### 7.2 get_start_scheduler："回家"机制

`on()`、`exec::reschedule`、`exec::task` 三处都依赖 `get_start_scheduler(env)`——
"当前操作是在哪个调度器上启动的"：

- `sync_wait` 的环境同时应答 `get_scheduler` / `get_start_scheduler` /
  `get_delegation_scheduler`，都指向它内部的 run_loop——所以
  `sync_wait(on(pool, ...))` 能回到等待线程。
- `exec::task` 的 context 应答 `get_start_scheduler`（即它的 home scheduler，见 6.4）。
- `exec::reschedule` = `continues_on(sndr, 特殊调度器)`，这个特殊调度器在 connect 时
  从 receiver 环境读 `get_start_scheduler`；env 没有则编译错误 `_CANNOT_RESCHEDULE_`。
- stdexec 扩展（非标准）：env 不应答 `get_scheduler` 但应答 `get_start_scheduler` 时，
  `get_scheduler` 查询回退到后者。

---

## 8. 取消（Cancellation）

### 8.1 取消基础设施

```cpp
#include <stdexec/stop_token.hpp>

stdexec::inplace_stop_source  src;                      // 取消源（RAII）
stdexec::inplace_stop_token   tok = src.get_token();    // 只读令牌
stdexec::inplace_stop_callback<F> cb{tok, f};           // 注册回调：request_stop() 时调用 f
src.request_stop();                                     // 触发取消：之后 tok.stop_requested() == true
```

- `request_stop()` 后，**每个**已注册的回调**恰好被调用一次**（可能在 `request_stop()`
  的调用线程上同步执行）。
- 回调的析构与 `request_stop()` 线程安全同步：回调析构返回后，源侧不会再触碰它。
- `inplace_stop_callback` 必须在 `inplace_stop_source` **存活期内**析构（它持有源的
  回调链表）；别在回调里销毁源。

### 8.2 把取消传入 sender：环境

取消不靠参数传递，而是靠 **receiver 环境里的 stop token**：

```cpp
using namespace stdexec;

inplace_stop_source src;

sender auto work =
  schedule(pool.get_scheduler())
    | then([] { /* 可被停止的耗时工作 */ })
    | exec::unless_stop_requested()                       // 若已请求停止，直接 set_stopped 短路
    | write_env(prop{get_stop_token, src.get_token()});   // 给上游接收者环境注入 stop token
```

- `get_stop_token(env)`：从环境查询当前 stop token；缺失时默认 `never_stop_token`（不可取消）。
- `write_env(sndr, prop{...})` / `sndr | write_env(prop{...})`：把 `prop`（键值对）注入
  左侧 sender 可见的环境。**注意名字是 `write_env`**（`write` / `exec::write_env` 都是
  deprecated 旧名），且直接调用时参数顺序是 sender 在前。
- `exec::unless_stop_requested(sndr)`：执行前检查停止标记，已停止则 `set_stopped` 短路。
- 组合子（`when_all` 等）**自动**把外层的 stop token 传播给子 sender。

### 8.3 在业务代码里响应取消

如果 sender 内部做的是可中断的轮询/等待，读 token 自己做检查：

```cpp
sender auto cancellable_loop(inplace_stop_token tok)
{
  return schedule(pool.get_scheduler())
       | then([tok] {
           for (int i = 0; i < 1'000'000; ++i)
           {
             if (tok.stop_requested())
               return 0;                     // 尽早退出
             work_unit(i);
           }
           return 1;
         });
}
```

或者用 `inplace_stop_callback` 注册异步回调（例如中断一个正在等待的第三方调用，
完整配方见 [13.3](#133-让包装支持取消)）。

### 8.4 把取消变成值/错误：`stopped_as_*`

`set_stopped` 没有值，调用方往往需要把它转成可处理的东西：

```cpp
// stopped -> optional（空即被取消）
sender auto opt = stopped_as_optional(work);      // set_value(std::optional<T>)

// stopped -> 指定的错误值
sender auto err = stopped_as_error(work, my_error{"cancelled"});  // set_error(my_error)

// stopped -> 回调
sender auto cb  = upon_stopped(work, [] { std::cout << "cancelled\n"; });
```

### 8.5 超时与竞速：用 when_any 实现"trigger 取消"

> 注意：P2300 早期草案里的 `stop_when(sndr, trigger)` 在标准化前被移除了。stdexec
> 里只剩内部实现 `__stop_when`（`counting_scope::token::wrap` 在用），**没有公开
> CPO**——`stdexec::stop_when(...)` 编译不过。要"trigger 完成即取消 sndr"，用
> `exec::when_any` 竞速：

```cpp
exec::timed_thread_context timer;   // 长寿命对象（成员变量或静态），见 12.1

sender auto fetch_with_timeout()
{
  auto timeout = exec::schedule_after(timer.get_scheduler(), 200ms)
               | then([] -> int { throw timeout_error{}; });   // 抛异常 → set_error

  // 谁先完成谁赢；败者分支收到 request_stop（协作式取消）
  return exec::when_any(fetch_from_network(), std::move(timeout));
}
```

- 网络先完成 → 定时分支被取消，`when_any` 以网络结果完成；
- 定时先触发 → `then` 里抛异常 → `when_any` 以 `set_error(timeout_error)` 完成，
  网络分支被取消。
- `when_any` 内部所有分支**共享一个** `inplace_stop_source`：首个完成者胜出后对它
  `request_stop()`，败者收到停止信号。取消是**协作式**的：败者分支若不检查 stop
  token，仍会跑完，只是结果被丢弃。
- `when_any` 的完成签名是所有分支的**并集**（值取各自形态，不包 variant），
  下游 `then` 的参数类型要兼容各分支的值。

### 8.6 协程里取消

`stdexec::task` / `exec::task` 自带与父环境的停止联动：

```cpp
auto guarded() -> exec::task<int>
{
  std::optional<int> r = co_await stopped_as_optional(expensive_work());
  co_return r.value_or(-1);
}
```

- 协程 `co_await get_stop_token()` 拿到父环境传播来的 token，自行决定如何响应。
- 父协程或外层 `when_any` 请求停止时，内层 sender 得到 `set_stopped`，停止沿
  promise 链向上传播（精确语义见 6.2）。

### 8.7 channel 的协作取消（co::mpsc，已验证）

`co::mpsc` 的 `send()` / `recv()` park 路径原生支持 stop token（完整设计与语义见
`docs/channel_stop_token_design.md`）。注入 token 的三种形态（均已验证）：

```cpp
auto [tx, rx] = co::mpsc::bounded<int>(1);
stdexec::inplace_stop_source src;

// 形态 1：sender 链上用 write_env 注入（注意 sender 在前）
auto result = stdexec::sync_wait(
  stdexec::write_env(tx.send(v),
                     stdexec::prop{stdexec::get_stop_token, src.get_token()}));
// src.request_stop() 后：parked 的 send 以 set_stopped 完成，sync_wait 返回空 optional，
// 值被撤回、不落通道。

// 形态 2：自定义 receiver —— get_env() 返回
//   stdexec::env{stdexec::prop{stdexec::get_stop_token, tok}}

// 形态 3：exec::task 里 co_await —— 外层 receiver env 里的 token 会被 task 转发到
// co_await 的 channel 操作（透传已验证）。顶层启动一个可取消的 task
// （exec::task 要求 env 里有调度器）：
auto op = stdexec::connect(
  stdexec::starts_on(stdexec::inline_scheduler{},
    stdexec::write_env(task(), stdexec::prop{stdexec::get_stop_token, src.get_token()})),
  my_receiver{});
```

- **撤回语义（tokio cancel-safety）**：值在交付（claimed）前始终属于发送方 opstate；
  取消（stop 请求，或销毁 opstate 的兜底路径）⟹ 值不落通道。认领与 stop 并发时先到
  先得（通道锁下裁决），认领后 stop 认输。
- **`exec::task` 遇 `set_stopped` 的表现（已验证）**：`co_await` 的 sender 以 stopped
  完成时，协程**不再恢复**（对称转移到 promise 的 `unhandled_stopped`），task 自身以
  `set_stopped` 完成，`co_await` 之后的语句不执行。需要区分「关闭」与「取消」的
  调用方用 `stopped_as_optional` 或 receiver 的 `set_stopped` 分支处理。
- **生命周期**：`inplace_stop_source` 必须比注册在它上面的 opstate 活得久——先析构
  opstate，再析构 source。
- `co::oneshot` 有意不接 stop token（DartFn 回执等场景走析构即取消的兜底路径）。

---

## 9. 编排（组合子）

| 组合子                                 | 作用                                                                                                   | 例子                                                                    |
| -------------------------------------- | ------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------- |
| `just(vs...)`                          | 立即（同步）完成并带值                                                                                 | `just(42)`                                                              |
| `exec::just_from(f)`                   | 惰性 `just`：**start 时**才调用 f；f 收到一个 sink，调 `sink(vs...)` 即发值（f 可抛时自动附加 `set_error_t(std::exception_ptr)`） | 构造昂贵对象                                            |
| `then(sndr, f)`                        | 成功后映射（f 可抛时自动附加 `set_error_t(std::exception_ptr)` 签名）                                  | `sndr \| then(f)`                                                       |
| `let_value(sndr, f)`                   | 成功后**动态拼接**新 sender（f 返回 sender）                                                           | 依赖上一步结果发起新请求                                                |
| `upon_error(sndr, f)`                  | 错误恢复                                                                                               | `sndr \| upon_error([](std::exception_ptr e){ ...; return fallback; })` |
| `upon_stopped(sndr, f)`                | 停止时兜底                                                                                             | `sndr \| upon_stopped(f)`                                               |
| `when_all(sndrs...)`                   | 全部成功才完成；任一失败/停止→对其余分支 `request_stop` 并整体失败/停止                                | 并行请求                                                                |
| `exec::when_any(sndrs...)`             | 第一个完成者胜出，其余取消                                                                             | 超时竞争、多源选择（见 8.5）                                            |
| `bulk(sndr, pol, shape, f)`            | 对 shape 个索引并行执行 f（线程池上自动分块）                                                          | 并行循环                                                                |
| `starts_on(sched, sndr)`               | 指定启动执行器                                                                                         | 见[第 7 节](#7-切换执行器)                                              |
| `continues_on(sndr, sched)`            | 指定继续执行器                                                                                         | 见[第 7 节](#7-切换执行器)                                              |
| `on(sched, sndr)` / `on(sndr, sched, closure)` | 启动/执行一段后回到启动处调度器                                                                | 见[第 7 节](#7-切换执行器)                                              |
| `exec::split(sndr)`                    | 把"只能消费一次"的 sender 变成可多次订阅（lvalue 可反复 connect；首个 connect 才真正 start，结果广播） | 多消费者                                                  |
| `exec::ensure_started(sndr)`           | 立即 start 并缓存结果；**返回的 sender 只能 connect 一次**（要多次订阅用 `split`）                     | 提前预热                                                                |
| `exec::finally(sndr, cleanup)`         | initial 无论以何种通道完成都接着跑 cleanup；cleanup 必须是 "sender of void"（只发 `set_value_t()`）；cleanup 失败会替换 initial 的结果下传 | 释放资源、埋点                            |
| `exec::repeat_until(sndr, pred)`       | 循环执行直到 pred 满足（`repeat_effect_until` 是它的别名；旧头文件 `exec/repeat_effect_until.hpp` 已废弃） | 轮询                                                              |
| `exec::materialize(sndr)`              | 把完成信号变成值：`set_value(vs...)` → `set_value(set_value_t{}, vs...)`、`set_error(e)` → `set_value(set_error_t{}, e)`、`set_stopped()` → `set_value(set_stopped_t{})`；逆操作 `exec::dematerialize` | 错误变成值处理   |
| `into_variant(sndr)`                   | 把多个 value 完成签名合并成变体                                                                        | 消除类型分支                                                            |
| `stopped_as_optional(sndr)`            | stopped → 空 optional                                                                                  | 见[第 8 节](#8-取消cancellation)                                        |
| `stopped_as_error(sndr, e)`            | stopped → 错误                                                                                         | 见[第 8 节](#8-取消cancellation)                                        |
| `write_env(sndr, prop{...})` / `read_env(q)` | 注入 / 读取环境                                                                                  | 传 stop token、allocator                                                |
| `get_scheduler()` / `get_stop_token()` | 以 sender 形式查询环境（零参 = `read_env(query)`）                                                     | 协程里 `co_await`                                                       |

`let_value` 示例（依赖上一步结果的动态编排）：

```cpp
sender auto download_and_parse(std::string url)
{
  return just(std::move(url))
       | let_value([](std::string u) {            // 返回新 sender
           return download(u)                     // async sender
                | then([](std::vector<std::byte> raw) {
                    return parse(raw);
                  });
         });
}
```

`when_all` 并行：

> **`when_all` 的值形态**：全部成功时把各分支的值**扁平拼接**成一次
> `set_value(vs1..., vs2..., ...)`（不是 tuple-of-tuples）。配合 6.2 的解包规则，
> 各分支各产一个值时：`auto [a, b] = co_await when_all(x, y);` 直接可用。

```cpp
using namespace stdexec;

// bulk 需要执行策略：seq / par / par_unseq（语义同 <execution>）
// 并行真正生效的前提是：sender 完成在线程池 scheduler 上（pool 的 domain 会
// 把 bulk_chunked 派发成多线程分块执行）。
sender auto parallel_double(exec::static_thread_pool& pool, span<int> data)
{
  return schedule(pool.get_scheduler())              // 在池上启动；set_value() 无值
       | bulk(stdexec::par, data.size(),             // 并行循环（逐索引调用 f(i, vs...)）
              [data](std::size_t i) { data[i] *= 2; })
       | then([data] { return sum(data); });         // 所有分块完成后继续
}
```

> 注意：`bulk` 的函数签名是**逐索引** `f(i, vs...)`（`vs...` 是上游值，所有迭代共享）；
> 分块策略（chunked / unchunked）由线程池的 domain 在内部决定，业务代码用
> `stdexec::par` 即可。线程池还支持 `bulk_chunked`（显式块式函数 `f(begin, end, vs...)`）。

---

## 10. 结构化并发

### 10.1 为什么需要结构化并发

`start_detached` 的问题是：**发起者不能确定后台工作何时结束**，程序退出时会有悬空操作；
手动 `connect + start` 的问题是：**opstate 的析构顺序得自己保证**，容易写出生命周期 bug。
结构化并发把"一组并发子任务"绑定到一个 **scope 对象**上：scope 析构（或显式 `join`）时，
保证所有子任务已完成。这恢复了两条宝贵的不变量：

1. **子任务不越过父作用域的生命周期**（父 scope 存活 ⇒ 子任务存活；子任务跑完之前 scope 不会空）。
2. **失败/取消可以整体传播**：scope.request_stop() 通知所有子任务。

### 10.2 exec::async_scope（最常用）

```cpp
#include <exec/async_scope.hpp>

exec::static_thread_pool pool{4};

{
  exec::async_scope scope;                       // RAII：析构时断言 scope 已空

  scope.spawn(schedule(pool.get_scheduler()) | then(task_a));
  scope.spawn(schedule(pool.get_scheduler()) | then(task_b));

  sender auto fut = scope.spawn_future(          // 想要结果的那个
    schedule(pool.get_scheduler()) | then(task_c));

  sync_wait(when_all(scope.on_empty(),           // 等所有子任务结束
                     std::move(fut) | then([](int v) { use(v); })));
}  // 此时 scope 保证空（若没等，debug 断言失败 / release UB——见下）
```

成员速查：

| 成员                                     | 作用                                                                                                                          |
| ---------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `spawn(sndr, env = {})`                  | 发射后不理。对会 `set_error` 的 sender **没有编译期拦截**：出错时内置 receiver 直接 `std::terminate()`（源码里挂着 `BUGBUG NOT TO SPEC` 注释）。请先 `upon_error` 兜底，或改用有编译期约束的 `stdexec::spawn`（见 10.3） |
| `spawn_future(sndr, env = {})`           | 发射并返回一个可等待的 sender；返回值只能被连接一次；没人连接时结果被丢弃（无泄漏）                                             |
| `nest(sndr)`                             | 得到"被 scope 收养"的 sender（connect 时注册、完成时注销），可手动 connect/start                                                |
| `on_empty()`                             | 一个 sender：scope 变空时以 `set_value()` 完成（= `when_empty(just())`）                                                        |
| `when_empty(sndr)`                       | 等 scope 排空后才启动 sndr；完成通道与 sndr 完全相同                                                                            |
| `request_stop()`                         | 向 scope 内所有子任务请求停止（通过环境 stop token）                                                                            |
| `get_stop_source()` / `get_stop_token()` | 访问 scope 自己的停止源                                                                                                         |

典型模式（服务生命周期）：

```cpp
struct server
{
  exec::async_scope scope;

  void start(exec::static_thread_pool& pool)
  {
    scope.spawn(schedule(pool.get_scheduler())
              | then([this] { accept_loop(); }));      // 常驻循环
  }

  void shutdown()
  {
    scope.request_stop();          // 通知 accept_loop 停止
    sync_wait(scope.on_empty());   // 等它真正退出
  }
};
```

### 10.3 stdexec::counting_scope / simple_counting_scope（标准）

C++26 标准版 scope（P3149，`stdexec::counting_scope` 在 `stdexec/execution.hpp` 中）：

```cpp
using namespace stdexec;

counting_scope scope;

// 在 scope 的关联下启动子操作：token 包装 sender（wrap 会把停止请求转发给子操作）
auto token = scope.get_token();
auto child = token.wrap(schedule(pool.get_scheduler()) | then(work));
exec::start_detached(std::move(child));    // 或 sync_wait(child) / connect+start

scope.close();                             // 不再接受新关联
sync_wait(scope.join());                   // 等所有已关联操作完成

scope.request_stop();                      // （可在 close 前）请求取消全部
```

| 成员                    | 作用                                                           |
| ----------------------- | -------------------------------------------------------------- |
| `get_token()`           | 拿到关联令牌；`token.wrap(sndr)` 给 sender 绑定 scope 的停止源 |
| `token.try_associate()` | 手动关联（count 用尽返回 null assoc）                          |
| `max_associations()`    | 允许的最大并发关联数（防御性上限）                             |
| `close()`               | 关闭：之后 `try_associate` 失败                                |
| `join()`                | 返回 sender：所有关联操作结束后完成                            |
| `request_stop()`        | 取消所有关联操作（仅 counting_scope）                          |

`simple_counting_scope` 与 `counting_scope` 的区别：前者没有停止源、`wrap` 不转发取消（更轻量）。

> ⚠ **析构纪律**：`counting_scope` / `simple_counting_scope` 析构时若没走到
> joined（或"从未使用且已 close"）状态，**直接 `std::terminate()`**。
> 也就是说 `close()` + 等待 `join()` 完成（`sync_wait` 或 `co_await`）必须发生在
> scope 析构之前。

### 10.4 嵌套 scope：结构化并发可以递归

scope 可以嵌套——外层等内层。要点是 **scope 对象的生命周期必须由"等待它排空的那层
结构"持有**。用协程帧持有最自然：

```cpp
// 正确姿势：inner 活在协程帧里，co_await 排空之后才析构
auto phase(exec::static_thread_pool& pool) -> stdexec::task<void>
{
  exec::async_scope inner;
  inner.spawn(schedule(pool.get_scheduler()) | then(sub_task1));
  inner.spawn(schedule(pool.get_scheduler()) | then(sub_task2));

  co_await inner.on_empty();      // 等 inner 排空；协程帧保证 inner 一直活着
  finalize_inner();
}

// 启动（stdexec::task 可能 set_error，async_scope::spawn 出错会 terminate，先兜底）：
outer.spawn(phase(pool) | upon_error([](std::exception_ptr e) noexcept { log_error(e); }));
```

> 反例：把 `inner` 写成**普通函数的局部变量**，再把 `inner.on_empty()` 挂进外层
> scope——函数一返回 `inner` 就析构，而此时它的任务和 waiter 可能还活着
> （debug 断言 `__active_ == 0` 失败 / release UB）。`when_all(inner.on_empty())`
> 只是**引用**它，并不延长它的寿命。

### 10.5 与 connect/start 的关系

`async_scope::nest` 的本质就是"记账版 connect"：`nest(sndr)` 返回一个 sender，
它 connect 时把活跃计数 +1、完成时 -1（在完成回调里，严格遵守"完成后不得再碰 opstate"的规则）。
`spawn` = `nest` + 堆上 opstate + 自删除；`spawn_future` = `nest` + 共享状态缓存结果。

> 正因为完成回调里维护计数，scope 的实现对完成回调的顺序有严格要求：
> 不要在完成回调里同步调用可能死锁的东西（如 `sync_wait(scope.on_empty())`）。

---

## 11. 生命周期与 RAII

1. **sender 是值**：可以移动、可以按值捕获进 `then` 的 lambda；连接后 sender 可以丢弃。
2. **opstate 不可移动**：`connect` 的结果必须放在一个稳定的存储里，
   存活到操作完成之后（栈上、成员里、或者堆上让操作自己删除自己）。
3. **完成后不得触碰**：receiver 的完成函数被调用后，opstate、receiver、以及
   捕获进操作状态里的所有东西都算"已死"，不能再使用（这是最常见的 UB 来源）。
4. **scope 先于子操作析构是错误**：`async_scope` 析构时若 `__active_ != 0`，
   debug 断言失败 / release UB；`counting_scope` 系列更狠——没 join 完析构直接
   `std::terminate()`。想"不管了直接退出"，请先 `request_stop()` + 等排空/join，
   或让 scope 存活更久。
5. **stop callback 生命周期**：`inplace_stop_callback` 必须在源存活期内析构；
   别在回调里销毁源。
6. **错误必须处理**：`stdexec::spawn` 在**编译期**拒绝会 `set_error` 的 sender；
   `exec::start_detached` / `async_scope::spawn` **没有**编译期拦截，出错
   `std::terminate()`；`when_all` 中任一失败会取消其余分支并整体失败。
7. **取消是协作式的**：`request_stop()` 只保证"收到停止信号"，
   不保证操作立即停止；业务代码必须自己检查 stop token 才能提前退出。

---

## 12. 进阶设施

### 12.1 定时调度：timed_thread_context + schedule_after

```cpp
#include <exec/timed_thread_scheduler.hpp>   // exec::timed_thread_context
#include <exec/timed_scheduler.hpp>          // exec::now / schedule_at / schedule_after（CPO）

exec::timed_thread_context timer;             // 默认构造即起一根定时线程；析构自动 request_stop + join
auto tsch = timer.get_scheduler();

// 延时 200ms 执行：
sync_wait(exec::schedule_after(tsch, 200ms) | then([] { std::cout << "ding\n"; }));

// 指定时间点：
sync_wait(exec::schedule_at(tsch, exec::now(tsch) + 200ms) | then([] { /* ... */ }));
```

- `timed_thread_context` 必须比所有挂在它上面的操作活得久（典型：成员变量/静态对象）。
- `timed_thread_scheduler` 的成员只有 `now()` / `schedule()` / `schedule_at()`；
  `schedule_after` 是 CPO，scheduler 没有对应成员时自动用 `schedule_at(now + d)` 兜底。
- 定时 sender 的完成签名是 `set_value_t()` / `set_stopped_t()`——可以被取消。
- 与取消组合做超时的完整例子见 [8.5](#85-超时与竞速用-when_any-实现trigger-取消)。
- 已经维护着自己的 `asio::io_context` 时，定时也可以直接用
  `steady_timer + async_wait(use_sender)`（见 12.6.3），不必引入定时线程。

### 12.2 trampoline_scheduler：防递归 schedule 栈溢出

`repeat_until` / 轮询链这类"完成回调里又 schedule 自己"的模式，在单线程/内联调度器上
会无限递归压栈。`trampoline_scheduler` 把超过深度/栈量限额的递归 schedule 挂到
thread_local 链表，由最外层帧循环排空：

```cpp
#include <exec/trampoline_scheduler.hpp>

exec::trampoline_scheduler tramp;             // 可选参数：(最大递归深度, 最大递归栈量)
sender auto s = schedule(tramp) | then([] { /* ... */ });
```

### 12.3 协程清理：at_coroutine_exit

RAII 的协程版：无论协程以哪种方式退出（值/异常/停止）都执行一段**异步**清理：

```cpp
#include <exec/at_coroutine_exit.hpp>
#include <exec/on_coro_disposition.hpp>

auto use_connection() -> exec::task<void>
{
  auto conn = co_await open_connection();

  co_await exec::at_coroutine_exit(
    [&conn]() -> exec::task<void> { co_await conn.async_close(); });

  // 也可以只在特定结局执行（succeeded / failed / stopped 三选一）：
  // co_await exec::on_coroutine_succeeded(
  //   [&conn]() -> exec::task<void> { co_await conn.commit(); });

  co_await conn.async_use();
}
```

- `at_coroutine_exit` 接受一个 callable（可带额外参数），协程退出时 `co_await` 它的返回值。
- Apple Clang 不支持（头文件直接 `#error`）。

### 12.4 系统级并行调度器：get_parallel_scheduler

对应标准提案里的 "system context / parallel scheduler"：一个进程级共享的并行调度器，
库的用户不必自己传线程池：

```cpp
auto psch = stdexec::get_parallel_scheduler();   // 无后端时抛 std::runtime_error
sender auto work = schedule(psch) | bulk(stdexec::par, n, f);
```

- 默认关闭：CMake 开 `STDEXEC_BUILD_PARALLEL_SCHEDULER=ON` 并链接
  `STDEXEC::parallel_scheduler`；或定义 `STDEXEC_PARALLEL_SCHEDULER_HEADER_ONLY`
  使用头文件内联的默认实现。
- Windows 上默认后端是 `windows_thread_pool`（见 12.5）；也可用
  `parallel_scheduler_replacement::query_parallel_scheduler_backend()`（weak 符号，
  仅 GCC/Clang 有效）在链接时替换成自己的后端。
- 旧名 `exec/system_context.hpp`、`exec::get_parallel_scheduler`、`get_system_scheduler`
  均已废弃，别用。

### 12.5 Windows 线程池后端：windows_thread_pool

Windows 上 `STDEXEC_ENABLE_WINDOWS_THREAD_POOL` 自动开启（探测到 `windows.h` 即开）：

```cpp
#include <exec/windows/windows_thread_pool.hpp>

exec::__win32::windows_thread_pool pool;            // 默认：进程共享线程池
// 或显式区间：exec::__win32::windows_thread_pool pool{minThreads, maxThreads};
auto sch = pool.get_scheduler();                    // 成员含 schedule() / now() / schedule_at() / schedule_after()
```

注意它在 `__win32` 子命名空间（实现细节命名空间），接口可能随版本调整；
要写可移植代码还是用 `exec::static_thread_pool`。

### 12.6 Asio 适配：exec::asio

stdexec 自带 Asio 适配层（`exec::asio` 命名空间），两件套：`use_sender` 完成令牌
（Asio 异步操作 → sender）和 `asio_thread_pool`（Asio 版线程池 scheduler）。
像本项目这样已经围绕 `asio::io_context` 事件循环构建的代码，主要用前者把
io_context 包成 scheduler，而不用另起线程池。

#### 12.6.1 use_sender：把 Asio 异步操作变成 sender

```cpp
#include <exec/asio/use_sender.hpp>

asio::steady_timer timer{ioc, 200ms};
sender auto s = timer.async_wait(exec::asio::use_sender);
// socket.async_read_some(buf, exec::asio::use_sender) → sender of (bytes_transferred)
```

任何接受完成令牌的 Asio 异步操作都能套。完成映射（`error_code` 参数被剥掉）：

| Asio 完成                                     | sender 完成                                        |
| --------------------------------------------- | -------------------------------------------------- |
| `ec == 0`                                     | `set_value(args...)`                               |
| `operation_aborted` / `operation_canceled`    | `set_stopped()`                                    |
| 其他非零 `ec`                                 | `set_error(std::exception_ptr)`（包成 `system_error`） |

完成签名 = 值形态（剥掉 `error_code`）+ `set_error_t(std::exception_ptr)` +
`set_stopped_t()`。外层 stop token 请求停止时，适配器会对 Asio 操作
`emit(cancellation_type::all)`（走 Asio 的 `cancellation_slot` 机制）。

#### 12.6.2 把现有 io_context 包成 scheduler

"在事件循环上跑一次"的 sender 就是 `post(ioc, use_sender)`，包一层即得 scheduler：

```cpp
class io_context_scheduler
{
 public:
  using scheduler_concept = stdexec::scheduler_tag;

  explicit io_context_scheduler(asio::io_context& ioc) : ioc_(&ioc) {}

  stdexec::sender auto schedule() const noexcept
  {
    return exec::asio::asio_impl::post(*ioc_, exec::asio::use_sender);
  }

  bool operator==(const io_context_scheduler&) const noexcept = default;

 private:
  asio::io_context* ioc_;
};
```

- `asio_impl` 是**生成的**命名空间别名：standalone 时 = `::asio`，boost 时 =
  `::boost::asio`（`asio_config.hpp`，见 12.6.6）。
- 之后 `starts_on(sched, ...)` / `on(sched, ...)` / `continues_on(sched)` 都能把
  链路搬上 io 线程；协程里 `co_await exec::reschedule_coroutine_on(sched)` 也行。
- 生命周期：schedule() 的 sender 捕获 io_context 的引用，**scheduler 不得比
  io_context 活得久**（本项目由 Runtime 的成员声明顺序保证）。
- 驱动侧：`io_context::run()` 在队列变空时就会返回——常驻事件循环要用
  `asio::make_work_guard(ioc)` 保活，退出前 `guard.reset()` 让 `run()` 收尾。

#### 12.6.3 定时：steady_timer + use_sender（可取消 sleep）

```cpp
// timer 必须活得比操作久：用 shared_ptr 保活到完成
sender auto sleep_on(asio::io_context& ioc, std::chrono::milliseconds d)
{
  auto timer = std::make_shared<asio::steady_timer>(ioc, d);
  return timer->async_wait(exec::asio::use_sender)
       | then([timer] {});
}
```

- 效果等价于 12.1 的 `schedule_after`，但跑在**你自己的事件循环**上，不需要另开
  定时线程。请求停止 → timer 被 cancel → `operation_aborted` → `set_stopped`。
- 反模式：局部变量 timer 直接 `async_wait` 后函数返回——timer 析构即取消操作。

#### 12.6.4 asio_thread_pool：Asio 版线程池

```cpp
#include <exec/asio/asio_thread_pool.hpp>

exec::asio::asio_thread_pool pool{4};        // 默认构造 = hardware_concurrency
auto sch = pool.get_scheduler();             // 继承 thread_pool_base：支持 bulk
sync_wait(schedule(sch) | then([] { return 42; }));
```

- 接口与 `exec::static_thread_pool` 一致（同继承 `thread_pool_base`），底层是
  `asio::thread_pool`；`get_executor()` 可取底层 Asio executor 与 Asio 生态互操作。
- 析构自动 stop + join。

#### 12.6.5 executor_with_default / as_default_on：默认完成令牌

给 io 对象绑定默认完成令牌，省去每次传 `use_sender`（`use_sender` 是令牌实例，
对应类型是 `use_sender_t`）：

```cpp
auto timer2 = exec::asio::use_sender.as_default_on(asio::steady_timer{ioc, 100ms});
sender auto s = timer2.async_wait();        // 不再需要显式传 token
```

（等价底层形式：`exec::asio::as_default_on<exec::asio::use_sender_t>(io_obj)`，
以及手写的 `executor_with_default<Executor, Token>`。）

#### 12.6.6 CMake 接入（重要：必须走 CMake）

`exec::asio` 的头文件依赖**生成的** `asio_config.hpp`（选择 standalone/boost 命名
空间），不能像其他头一样纯 `-I` 使用：

```cmake
set(STDEXEC_ENABLE_ASIO ON CACHE BOOL "" FORCE)
set(STDEXEC_ASIO_IMPLEMENTATION "standalone" CACHE STRING "" FORCE)  # 或 "boost"（默认）
# standalone 模式由 stdexec 自动拉取 asio-1.31.0
target_link_libraries(your_target PRIVATE STDEXEC::asioexec)  # 兼容别名：STDEXEC::asio_pool
```

---

## 13. 与回调式 API 互操作

桥接场景（FFI、C 回调、平台 API）里最常见的需求：把"注册回调，回头调你"式的 API
包成 sender，接入第 4–10 节的整个世界。两条路：`exec::create`（省事）和手写
sender（完全控制）。

### 13.1 exec::create：最省事的包装

```cpp
// 假设的 C API：注册回调，完成后以 (user, result) 调回
// void dcb_fetch(int id, void (*cb)(void* user, int result), void* user);

#include <exec/create.hpp>

sender auto fetch_async(int id)
{
  return exec::create<set_value_t(int)>(          // 完成签名在编译期固定
    [id]<class Ctx>(Ctx& ctx) noexcept {          // start() 时被调用，必须 nothrow
      dcb_fetch(id, [](void* p, int result) noexcept {
        auto& c = *static_cast<Ctx*>(p);
        set_value(std::move(c.receiver), result); // 完成 receiver：恰好一次
      }, &ctx);
    });
}
```

要点：

- 模板实参是完成签名列表；C API 可能失败就把错误通道也列上（如
  `set_error_t(std::exception_ptr)`），在回调里 `set_error`。
- `ctx` 的地址可以安全交给 C API 当 `void*`：opstate 不可移动，地址稳定；
  但完成函数调用后 `ctx` 立即失效（同第 11 节规则），回调里完成之后就别再碰它。
- receiver 必须**恰好完成一次**（value/error/stopped 之一），多调少调都是契约违反。
- `fn` 在 `start()` 时**同步**执行——只该做"注册回调"，别在里面跑耗时逻辑
  （要迁移线程就套 `starts_on` / `continues_on`）。

包好的 sender 用法与普通 sender 完全相同：
`sync_wait(fetch_async(1))`、`co_await fetch_async(1)`、
`scope.spawn(fetch_async(1) | upon_error(...))`。

### 13.2 手写最小 sender（需要完全控制时）

这个版本手写 sender 的最小样板（对照 `third_party/stdexec/test/test_common/schedulers.hpp`）：

```cpp
struct tick_sender
{
  using sender_concept        = stdexec::sender_tag;
  using completion_signatures =
    stdexec::completion_signatures<stdexec::set_value_t(int)>;

  template <class Rcvr>
  struct opstate
  {
    using operation_state_concept = stdexec::operation_state_tag;
    Rcvr rcvr_;

    void start() & noexcept
    {
      // ...真正发起异步操作，完成时：
      stdexec::set_value(std::move(rcvr_), 42);
    }
  };

  template <class Rcvr>
  auto connect(Rcvr rcvr) const -> opstate<Rcvr>
  {
    return {static_cast<Rcvr&&>(rcvr)};
  }
};
```

- `sender_concept` + `completion_signatures`（成员别名；或
  `static consteval get_completion_signatures()`）+ `connect` 三件套即可满足
  `stdexec::sender` 概念。
- opstate 需要 `operation_state_concept` 和 `void start() & noexcept`；
  实际代码里应令其不可移动（库内用 `STDEXEC_IMMOVABLE`）。
- 可选：给 sender 加 `get_env()` 应答 `get_completion_scheduler<set_value_t>`，
  让 `on()` / `continues_on` 等知道完成后在哪个上下文。
- 什么时候手写而不是用 `exec::create`：需要暴露 scheduler 属性、需要复杂的
  完成签名变换、或要在 connect 期（而非 start 期）做事。

### 13.3 让包装支持取消

在 `exec::create` 的 fn 里从 receiver 环境读 stop token，把取消转发给 C API：

```cpp
sender auto fetch_cancellable(int id)
{
  return exec::create<set_value_t(int), set_stopped_t()>(
    [id]<class Ctx>(Ctx& ctx) noexcept {
      auto tok = get_stop_token(get_env(ctx.receiver));
      if (!tok.stop_possible())
      {
        // 环境不可取消：注册普通完成回调即可
        register_completion(id, &ctx);
        return;
      }
      // 可取消：再注册一个 inplace_stop_callback，
      // request_stop 时调 dcb_cancel(id)，并在取消回调里
      // set_stopped(std::move(ctx.receiver))
      register_completion_with_cancel(id, &ctx, tok);
    });
}
```

要点：先查 `stop_possible()` / `stop_requested()`；取消路径同样遵守
"恰好完成一次、完成后不碰 ctx"。

---

## 14. 常见编译错误速查

stdexec 的模板诊断按 `_WHAT_(...) / _WHY_(...) / _WHERE_(_IN_ALGORITHM_, ...) /
_WITH_ENVIRONMENT_(...)` 的结构组织，看懂结构就能定位。常见条目：

| 错误文案（节选）                                                                                                                            | 出处                 | 原因与解法                                                                                                  |
| ------------------------------------------------------------------------------------------------------------------------------------------- | -------------------- | ----------------------------------------------------------------------------------------------------------- |
| `exec::task<T> cannot be co_await-ed in a coroutine that does not have an associated start scheduler.`                                      | `exec/task.hpp`      | 父协程/环境没有 start scheduler。用 `sync_wait` / `when_all` / scope 启动，或让父 promise 的环境应答 `get_start_scheduler` |
| `_CANNOT_RESTORE_EXECUTION_CONTEXT_AFTER_ON_` + `_THE_CURRENT_EXECUTION_ENVIRONMENT_DOESNT_HAVE_A_SCHEDULER_`（`on_t`）                      | `__on.hpp`           | `on()` 完成后找不到"回家"的调度器。外层接 `sync_wait`（其环境提供），或在 receiver env 里提供 `get_start_scheduler` |
| `_CANNOT_RESCHEDULE_`（同上 WHY）                                                                                                           | `exec/reschedule.hpp` | `exec::reschedule` 需要 env 的 `get_start_scheduler`，解法同上                                              |
| `The argument to stdexec::sync_wait() is a sender that cannot complete successfully... exactly one signature of the form set_value_t(...)` | `__sync_wait.hpp`    | 被等的 sender 没有 value 通道（只会 stopped/error）                                                          |
| `...can complete successfully in more than one way. Use stdexec::sync_wait_with_variant() instead.`                                         | `__sync_wait.hpp`    | 多种 value 形态；改用 `stdexec::sync_wait_with_variant()`（返回 variant）                                    |
| `spawn expects a sender that cannot fail`                                                                                                   | `__spawn.hpp`        | `stdexec::spawn` 的 sender 带 `set_error` 签名；先 `upon_error` 兜底并把收尾 lambda 标 `noexcept`            |
| `_INVALID_ARGUMENT_TO_THE_FINALLY_ALGORITHM_` / `_THE_FINAL_SENDER_MUST_BE_A_SENDER_OF_VOID_`                                               | `__finally.hpp`      | `finally` 的 cleanup 不是 void-sender；cleanup 只许发 `set_value_t()`                                       |

---

## 15. 附录：速查表

### 启动

```cpp
sync_wait(sndr);                              // 阻塞等待（普通函数）；多形态用 sync_wait_with_variant
exec::start_detached(sndr);                   // 发射后不理（无 scope；出错 terminate）
stdexec::spawn(sndr, scope.get_token());      // 发射进 scope（编译期拒绝失败 sender）
scope.spawn(sndr);                            // 发射进 async_scope（出错 terminate，先兜底）
scope.spawn_future(sndr);                     // 发射进 scope + 返回结果 sender（只能 connect 一次）
connect(sndr, rcvr) -> start(op);             // 手动（op 必须活到完成回调之后）
run_loop loop; loop.get_scheduler();          // 自驱事件循环：run() 内/外调 finish() 才退出
co_await sndr;                                // 协程内启动并等待（单值给裸值，多值给 tuple）
co_await stdexec::task / exec::task 协程      // 协程本身就是 sender
```

### 执行器

```cpp
exec::static_thread_pool pool{N};
auto sch = pool.get_scheduler();
auto sch0 = pool.get_scheduler_on_thread(0);   // 绑到第 0 号线程
exec::single_thread_context single;            // 单线程上下文（内部 run_loop + 一根线程）
stdexec::run_loop loop;                        // 手动驱动
stdexec::inline_scheduler{};                   // 内联（立即）执行
exec::timed_thread_context timer;              // 定时线程；auto tsch = timer.get_scheduler();
exec::trampoline_scheduler tramp;              // 防递归 schedule 压栈
stdexec::get_parallel_scheduler();             // 系统级并行调度器（12.4，需开 build 选项）
exec::asio::asio_thread_pool apool{N};         // Asio 版线程池（需 STDEXEC_ENABLE_ASIO）
// 把现有 asio::io_context 包成 scheduler：schedule() 返回
//   exec::asio::asio_impl::post(ioc, exec::asio::use_sender)（见 12.6.2）
// Asio 定时：steady_timer + async_wait(exec::asio::use_sender)（见 12.6.3）
```

### 迁移

```cpp
stdexec::on(sched, sndr);                    // 在 sched 上启动，完成后回到启动处调度器
sndr | on(sched, closure);                   // 形式 2：切到 sched 应用闭包再切回
stdexec::starts_on(sched, sndr);             // 在 sched 上启动（无管道形式）
sndr | continues_on(sched);                  // 完成后迁到 sched
sndr | exec::reschedule();                   // 回 env 的 get_start_scheduler
co_await exec::reschedule_coroutine_on(sched);  // exec::task 内迁移（并更新 home scheduler）
```

### 取消

```cpp
stdexec::inplace_stop_source src;  src.get_token();  src.request_stop();
sndr | write_env(prop{get_stop_token, tok});   // 注入 stop token（名字是 write_env！）
get_stop_token(env);                           // 读环境（协程里 co_await get_stop_token()）
read_env(get_stop_token);                      // 以 sender 形式读环境（read 是旧名）
exec::unless_stop_requested(sndr);
stopped_as_optional(sndr);  stopped_as_error(sndr, err);  upon_stopped(sndr, f);
exec::when_any(a, b);                          // 竞速：胜者完成即取消败者（超时模式见 8.5）
scope.request_stop();        counting_scope::request_stop();
```

### 定时

```cpp
exec::timed_thread_context timer;  auto tsch = timer.get_scheduler();
exec::schedule_after(tsch, 200ms);             // 延时执行（完成签名 set_value_t()/set_stopped_t()）
exec::schedule_at(tsch, exec::now(tsch) + 200ms);
```

### 结构化并发

```cpp
exec::async_scope scope;
scope.spawn(s); scope.spawn_future(s); scope.nest(s);
sync_wait(scope.on_empty());  scope.when_empty(sndr);
scope.request_stop();
// 析构前必须排空（debug 断言 / release UB）

stdexec::counting_scope cs;
auto t = cs.get_token();  auto wrapped = t.wrap(s);  cs.close();  sync_wait(cs.join());
cs.request_stop();
// 析构前必须完成 close()+join()，否则 std::terminate()
```

---

## 参考

- 本仓库：`third_party/stdexec` @ `f0e8ae6f`（≈ v0.11.0，nvhpc-26.05 基线），示例见
  `third_party/stdexec/examples/`（hello_world.cpp / hello_coro.cpp / scope.cpp 等）。
- **P2300** `std::execution`（senders/receivers）：2024 年并入 C++26 工作草案。
  `schedule` / `then` / `when_all` / `on` / `starts_on` / `continues_on` / `sync_wait`
  等核心均出自它。
- **P3149** `async_scope`：`spawn` / `spawn_future` / `counting_scope` /
  `simple_counting_scope` 的出处（2025 年推进进入 C++26）。
- **P3325** A Utility for Creating Execution Environments：`prop` / `env` /
  `write_env` 环境工具的出处。
- `third_party/stdexec/README.md`：编译器支持矩阵与接入方式（CPM / add_subdirectory /
  Conan / 手动 `-I`）。
