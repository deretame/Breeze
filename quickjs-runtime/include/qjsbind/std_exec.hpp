// std_exec.hpp —— 标准 P2300 task（std::exec::task 参考实现）入口
//
// 项目统一使用 stdexec::task（__detail/__task.hpp，2026 重写的新实现）：
//   - 旧版 stdexec::task 在 MSVC 19.51 下的 C2938（completion signatures
//     推导失败）已随 2026 重写消除；
//   - PR #2159（__any_allocator 跨特化私有成员访问，task_scheduler 堆分配
//     路径编译失败）已在 master 修复。
// std_exec::task<T> 别名定义在 fetchcore 的 fetch/task.hpp（核心库内，
// 避免两份实现漂移）；本头仅转发。
//
// 标准 C++26 的 <execution> 提供 std::exec::task；本项目的 stdexec 实现
// 对应的就是 stdexec::task。代码统一写 std_exec::task<T>。
#pragma once

#include <fetch/task.hpp>
