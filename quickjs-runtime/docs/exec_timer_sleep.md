# dcb::sleep 实施文档 —— 基于 exec 命名空间定时设施

> 状态：实施中（2026-08）
> 顺序：本文档 → 实现 `include/dart_cpp_bridge/sleep.hpp` → 测试 `tests/sleep_test.cpp`
> 相关代码：`include/dart_cpp_bridge/stream.hpp`（`interval()` 需要 `dcb::sleep` 的前向声明）

## 1. 背景与目标

`stream.hpp` 的 `interval()` 工厂在 `next()` 里 `co_await dcb::sleep(period)`，
但 `dcb::sleep` 只有前向声明（正式实现在 `runtime.hpp`，尚未提供）。当前测试用
`std::thread` 的 hack 顶住。

目标：

1. 用 stdexec **`exec` 命名空间**的定时设施实现正式的 `dcb::sleep`
2. 支持多种后端并分别测试：`timed_thread_scheduler`、Windows 线程池、
   `std::thread`、`boost::asio::steady_timer`
3. 接口与 `stream.hpp` 前向声明完全兼容（调用方零感知）

## 2. 事实背景：timer 在标准与 stdexec 中的位置

| 层 | 定时能力 | 说明 |
| --- | --- | --- |
| C++26 `std::execution` | ❌ 无 | P2300 进入 C++26 时把 timer 移出采用范围 |
| stdexec 核心 `stdexec::` | ❌ 无 | 与标准保持一致 |
| **stdexec 扩展 `exec::`** | ✅ 有 | `schedule_after` / `schedule_at` / 具体 scheduler |

**结论**：定时设施只能走 `exec::` 扩展命名空间。

## 3. exec 命名空间定时 API（已查证，stdexec 0.10.0 / 2026-05-25）

### 3.1 `exec::schedule_after` / `exec::schedule_at`

头文件：`<exec/timed_scheduler.hpp>`（`schedule_after` 也见 `timed_thread_scheduler.hpp` 与 `windows_thread_pool.hpp`）

```cpp
namespace experimental::execution {   // 即 exec::
  extern schedule_after_t const schedule_after;
  extern schedule_at_t const    schedule_at;
}
```

- 签名：`exec::schedule_after(sched, dur)` → sender
- 约束：scheduler 需满足 `__has_schedule_after_member`（有 `sched.schedule_after(dur)` 成员）
  或提供 `tag_invoke`；`schedule_after` 不满足时退化到 `schedule_at(sched, now() + dur)`
- 类型：`time_point_of_t<Sched>` = `now(sched)` 的返回类型（如 `steady_clock::time_point`）；
  `duration_of_t<Sched>` = 该 time_point 的 `duration`
- 完成：`set_value()`（无值）；支持 stop token（scheduler 实现内处理）

### 3.2 `exec::timed_thread_scheduler`

头文件：`<exec/timed_thread_scheduler.hpp>`

```cpp
exec::timed_thread_context ctx;        // 默认构造即启动一个专用线程
auto sched = ctx.get_scheduler();      // timed_thread_scheduler
sched.now();                           // steady_clock::now()
exec::schedule_after(sched, 20ms);     // 到点在专用线程上 set_value
```

- 内部：intrusive heap（deadline 最小堆）+ mpsc 命令队列 + condition_variable + 单线程
- 生命周期：析构自动 `request_stop()` 并 join 线程；**context 必须活得比所有 sleep 操作久**
- 跨平台（Windows/Linux 同一实现）

### 3.3 `exec::windows_thread_pool`

头文件：`<exec/windows/windows_thread_pool.hpp>`（Windows 专用）

```cpp
exec::windows_thread_pool pool;        // 系统线程池（可选 min/max 线程数）
auto sched = pool.get_scheduler();     // scheduler
exec::schedule_after(sched, 20ms);     // CreateThreadpoolTimer / SetThreadpoolTimer
```

- 优点：**不占用额外线程**（复用系统线程池的定时器队列），生产环境首选
- 内部：`CreateThreadpoolTimer` + `SetThreadpoolTimer`，支持停止

### 3.4 asio：无现成适配

`<exec/asio/>` 只有 `asio_thread_pool`（普通线程池）等，**没有** timer 相关的
sender 适配。`steady_timer::async_wait` 需自行包装成 sender（见 §5）。

## 4. dcb::sleep 设计

### 4.1 公开接口（与 stream.hpp 前向声明一致）

```cpp
namespace dcb {
  template <typename Rep, typename Period>
  stdexec::sender auto sleep(std::chrono::duration<Rep, Period> dur);
}
```

`interval()` 与所有现有调用零改动。

### 4.2 后端与选型

| 后端 | 机制 | 完成位置 | 线程成本 | 选型 |
| --- | --- | --- | --- | --- |
| `exec::timed_thread_scheduler` | 专用线程 + 最小堆 | 定时线程 | 每 context 1 线程 | **默认**（通用、简单） |
| `exec::windows_thread_pool` | `CreateThreadpoolTimer` | 系统线程池 | 0 | 生产优化项 |
| `std::thread` | 每 sleep 一个线程 | 新线程 | 每 sleep 1 线程 | 兜底/对照 |
| `boost::asio::steady_timer` | asio 定时器队列 | io 线程 | 0（需 io_context run） | 集成对照 |

- 默认后端用**函数级静态单例** `timed_thread_context`（C++11 线程安全初始化），
  生命周期由静态存储期管理
- 各后端以独立的实现函数暴露（`sleep_impl_*` 或命名空间），便于测试注入；
  顶层 `dcb::sleep` 绑定默认后端

### 4.3 关键点

- **完成位置**随后端不同：默认（timed 线程）/ 系统线程池 / 新线程 / io 线程。
  需要回到特定上下文时用 `stdexec::continues_on` / `starts_on` 迁移
- **取消**：timed/windows 后端原生支持 stop token；两个对照后端（std::thread /
  asio）在"协程挂起中销毁 opstate"时**安全**——receiver 由共享控制块
  `shared_control_block`（mutex + cv + done + in_flight + completing_thread +
  optional<receiver>）持有，完成回调经 `begin_completion` 取得唯一交付权
  （in_flight++ 并记录回调线程），`abandon()`（opstate 析构）置 done 后：
  - 析构发生在**回调线程自身**（协程被 resume 后 co_return，帧销毁连带
    `~Op`）：receiver 已被回调 move 到栈上持有，直接返回不等待；
  - 其他线程取消：等待 in_flight == 0（进行中的回调结束）后才销毁 receiver。
  `end_completion` 由 RAII guard 保证必达。取消要么令回调短路（done 分支），
  要么等待回调结束后再析构，不存在悬垂回调访问已销毁帧，也无死锁
- **生命周期**：所有后端都要求上下文对象活得比 sleep 操作久

## 5. asio 后端实现要点（自包 sender）

```cpp
// asio_timer_sender: io_context& + duration -> sender
// receiver 由共享控制块 shared_control_block（mutex + cv + done + in_flight
// + completing_thread + optional<R>）持有：
//   - async_wait handler 捕获 shared_ptr（不捕获裸 this），触发时
//     begin_completion() 在锁内检查 done 并 move 出 receiver（in_flight++，
//     记录回调线程），锁外完成（set_stopped / set_error / set_value），
//     completion_guard RAII 保证 end_completion 必达
//   - opstate 析构（abandon）：置 done + 销毁仍持有的 receiver；回调线程
//     自身析构（协程帧销毁）直接返回，其他线程取消等待 in_flight == 0；
//     timer 析构取消 async_wait，迟到的 handler 见 done 短路
// 约束：io_context 必须有人 run()（如后台 std::thread 跑 io.run()，
//       需 executor_work_guard 防止空转返回）
```

## 6. 测试计划（tests/sleep_test.cpp）

每个测试验证：完成路径正确 + 耗时 ≥ dur 的下限（允许调度抖动）

1. `Sleep.ExecTimedThread` —— 默认后端：`sync_wait(dcb::sleep(20ms))`
2. `Sleep.WindowsThreadPool` —— `exec::schedule_after(pool.get_scheduler(), 20ms)`
3. `Sleep.StdThread` —— `std::thread` 后端（现有 hack 正式化）
4. `Sleep.AsioTimer` —— 自包 asio sender；io_context 在后台线程 run
5. `Sleep.IntervalIntegration` —— `interval` + 正式 `dcb::sleep`（替换 hack）

## 7. 集成步骤

1. 新增 `include/dart_cpp_bridge/sleep.hpp`（`dart_cpp_bridge` target 已含 include 目录）
2. `tests/stream_test.cpp` 删除 `dcb::sleep` 测试 hack，`#include <dart_cpp_bridge/sleep.hpp>`
3. `pixi run configure`（若需新依赖）+ `pixi run build` + `pixi run test` 全量通过

## 8. 风险与待办

- `timed_thread_context` 静态单例的析构顺序（静态析构期再触发 sleep 属 UB，
  实际不会发生；所有 opstate 必须先于 ctx 销毁）
- 对照后端的完成回调在锁外执行；R 的 move 构造与 receiver 析构假定为
  noexcept / 无副作用（stdexec receiver 惯例），begin_completion 锁内 move
  若抛异常会 terminate（当前风险低）；completion_guard 保证 in_flight 归零
- asio 后端要求调用方维护 `io_context` 的 `run()`（配 work_guard），文档需注明
- `windows_thread_pool` 仅 Windows
- stdexec 版本升级后 `exec::` API 可能漂移（文档 §3 已锚定 0.10.0）
