// fetchcore —— 标准 P2300 task（stdexec::task）别名头
//
// 2026-08 起 stdexec master 重写了 __detail/__task.hpp（2026 新实现）：
//   - 旧版 stdexec::task 的 C2938（completion signatures 推导失败）已消除；
//   - PR #2159（__any_allocator 跨特化私有成员访问，task_scheduler 堆分配
//     路径编译失败）已修复（b73f140d 含 friend 声明）。
// 因此从 experimental::execution::task（exec/task.hpp basic_task）切换到
// stdexec::task。std_exec 别名保持不变，调用点零改动。
#pragma once

#include <stdexec/execution.hpp> // 导出 stdexec::task

namespace std_exec {
    template <class T = void>
    using task = stdexec::task<T>;
}
