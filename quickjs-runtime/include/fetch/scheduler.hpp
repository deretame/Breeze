// fetchcore —— asio io_context 的 stdexec scheduler 适配
//
// 从 qjsbind/context.hpp 的 io_context_scheduler 下沉（fetch_cpp_decoupling.md
// §4.5/§7-8：核心库自带一份，绑定层复用本版本，避免两份实现漂移）。
// schedule() = post 到 io_context，并用 upon_error/upon_stopped 在完成信号
// 层面消化 error/stopped（post 本身不失败），使 io_scheduler 满足
// stdexec::task 对 start scheduler 的 __infallible_scheduler 约束
//（task_scheduler 类型擦除的构造要求）。注意：task_scheduler 有 72 字节
// inline 存储限制，本链的 opstate 较大，需在构建时定义
// STDEXEC_TASK_SCHEDULE_OPSTATE_SIZE=256（见 CMakeLists.txt）。
#pragma once

#include <boost/asio/io_context.hpp>
#include <exec/asio/use_sender.hpp>
#include <stdexec/execution.hpp>

#include <stdexcept>

namespace fetch {

// ---- 线程本地 io_context（fetch 内部取调度器的默认来源）----
// 约定：发起 fetch（构造 Client/BeastTransport/MultipartEncoder、easy 请求）的
// 线程必须已 set_thread_io()（绑定层在 Runtime 构造时设置；测试/直连用户在
// 自己的 io 线程设置）。thread_local 每线程独立——多线程各自 set 各自的 io。
// 未设置时 thread_io() 抛 std::logic_error（编程错误，快速暴露）。
namespace detail {
inline boost::asio::io_context*& thread_io_slot() noexcept
{
    static thread_local boost::asio::io_context* slot = nullptr;
    return slot;
}
} // namespace detail

inline void set_thread_io(boost::asio::io_context& io) noexcept
{
    detail::thread_io_slot() = &io;
}

inline void clear_thread_io() noexcept
{
    detail::thread_io_slot() = nullptr;
}

inline boost::asio::io_context& thread_io()
{
    auto* slot = detail::thread_io_slot();
    if (!slot)
        throw std::logic_error("fetch: 当前线程未设置 io_context（先 fetch::set_thread_io）");
    return *slot;
}

inline bool has_thread_io() noexcept
{
    return detail::thread_io_slot() != nullptr;
}

class io_scheduler {
public:
    using scheduler_concept = stdexec::scheduler_tag;
    explicit io_scheduler(boost::asio::io_context& ioc) noexcept : ioc_(&ioc) {}

    stdexec::sender auto schedule() const noexcept
    {
        // 完成信号收敛为 set_value_t()（infallible）；post 本身不失败，
        // 停止路径实际不触发，吞掉后按普通完成处理
        return exec::asio::asio_impl::post(*ioc_, exec::asio::use_sender)
             | stdexec::upon_error([](std::exception_ptr) noexcept {})
             | stdexec::upon_stopped([]() noexcept {});
    }

    bool operator==(const io_scheduler&) const noexcept = default;

private:
    boost::asio::io_context* ioc_;
};

} // namespace fetch
