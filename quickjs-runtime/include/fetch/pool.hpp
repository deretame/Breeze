// fetchcore —— 文件 I/O 线程池与 stdexec scheduler 适配
//
// 用途：请求侧流式上传（MultipartEncoder 等 BodySource）的文件读取是同步
// 阻塞 I/O，不能在 io_context 事件循环线程上执行（慢存储会卡死整个事件
// 循环）。本头提供进程级全局线程池单例 fetch::file_pool()（惰性初始化，
// 线程数 = 4 × std::thread::hardware_concurrency()，即用户线程数量 ×4），
// 以及 pool_scheduler —— asio thread_pool executor 的 stdexec scheduler
// 适配（与 scheduler.hpp 的 io_scheduler 同构：schedule() = post 到池，
// 完成信号收敛为 set_value_t()，满足 stdexec::task 对 start scheduler 的
// __infallible_scheduler 约束）。
//
// 线程切换模式：read() 内 co_await pool_sched_.schedule() 切到文件线程执行
// 阻塞读，再 co_await io_sched_.schedule() 切回 io_context 线程返回——网络
// 写入（async_write）始终在 io_context 线程发起（Asio socket 非线程安全）。
//
// 生命周期：file_pool() 为函数静态变量，程序退出时析构并 join 所有线程；
// 需保证所有 fetch 协程在 io_context 停止后结束（正常退出顺序即如此）。
#pragma once

#include <boost/asio/thread_pool.hpp>
#include <exec/asio/use_sender.hpp>
#include <stdexec/execution.hpp>

#include <thread>

namespace fetch {

// 默认线程数：4 × 用户线程数量（hardware_concurrency 为 0 时按 1 计）
inline unsigned default_file_pool_size()
{
    const unsigned hw = std::thread::hardware_concurrency();
    return 4u * (hw ? hw : 1u);
}

// 进程级文件 I/O 线程池单例（惰性初始化；thread_pool 析构自动 join）
inline boost::asio::thread_pool& file_pool()
{
    static boost::asio::thread_pool pool(default_file_pool_size());
    return pool;
}

// asio thread_pool executor 的 stdexec scheduler（与 io_scheduler 同构）
class pool_scheduler {
public:
    using scheduler_concept = stdexec::scheduler_tag;
    explicit pool_scheduler(boost::asio::any_io_executor ex) noexcept
        : ex_(std::move(ex))
    {
    }

    stdexec::sender auto schedule() const noexcept
    {
        // post 本身不失败；error/stopped 路径不触发，吞掉后按普通完成处理
        return exec::asio::asio_impl::post(ex_, exec::asio::use_sender)
             | stdexec::upon_error([](std::exception_ptr) noexcept {})
             | stdexec::upon_stopped([]() noexcept {});
    }

    bool operator==(const pool_scheduler&) const noexcept = default;

private:
    boost::asio::any_io_executor ex_;
};

} // namespace fetch
