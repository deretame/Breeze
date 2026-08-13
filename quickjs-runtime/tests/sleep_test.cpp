#include <dart_cpp_bridge/runtime.hpp>
#include <qjsbind/std_exec.hpp>

#include <boost/asio/executor_work_guard.hpp>
#include <exec/windows/windows_thread_pool.hpp>
#include <gtest/gtest.h>
#include <stdexec/execution.hpp>

#include <chrono>
#include <thread>
#include <utility>

using namespace std::chrono_literals;

namespace {

// sync_wait 运行 sender 并断言：正常完成 + 耗时 ≥ min_wait（容忍调度抖动）。
template <typename Sender>
void expect_sleep_ok(Sender&& s, std::chrono::milliseconds min_wait)
{
  const auto t0 = std::chrono::steady_clock::now();
  auto res = stdexec::sync_wait(std::forward<Sender>(s));
  const auto elapsed = std::chrono::steady_clock::now() - t0;
  ASSERT_TRUE(res.has_value());
  EXPECT_GE(elapsed, min_wait);
}

// io_context + 后台 run 线程的 RAII：断言失败提前 return 时也会 stop + join。
struct io_thread_guard {
  boost::asio::io_context& io;
  boost::asio::executor_work_guard<boost::asio::io_context::executor_type> work;
  std::thread th;

  explicit io_thread_guard(boost::asio::io_context& i)
    : io(i)
    , work(boost::asio::make_work_guard(io))
    , th([&io = i] { io.run(); })
  {}

  ~io_thread_guard()
  {
    work.reset();
    io.stop();
    if (th.joinable()) th.join();
  }
};

}  // namespace

// 默认调度器：dcb::Runtime 的 io 线程（asio::steady_timer + use_sender）。
// Runtime 由全局 gtest Environment（test_main.cpp）启动。
TEST(Sleep, RuntimeIoSchedulerDefault)
{
  expect_sleep_ok(dcb::sleep(20ms), 15ms);
}

// 显式调度器：业务自己的 io_context 上套 IoContextScheduler
TEST(Sleep, ExplicitIoContextScheduler)
{
  boost::asio::io_context io;
  // RAII：work_guard 防 run() 空转返回；断言失败时析构也会 stop + join
  io_thread_guard io_guard(io);

  expect_sleep_ok(dcb::sleep(20ms, dcb::IoContextScheduler(io)), 15ms);
}

// Windows 线程池后端：exec::windows_thread_pool（CreateThreadpoolTimer）
TEST(Sleep, WindowsThreadPool)
{
  exec::windows_thread_pool pool;
  expect_sleep_ok(exec::schedule_after(pool.get_scheduler(), 20ms), 15ms);
}

// 并行 3 个 sleep：总耗时应接近单个周期（真定时，不串行）
TEST(Sleep, ParallelWaits)
{
  const auto t0 = std::chrono::steady_clock::now();
  auto res = stdexec::sync_wait(stdexec::when_all(dcb::sleep(30ms), dcb::sleep(30ms),
                                                  dcb::sleep(30ms)));
  const auto elapsed = std::chrono::steady_clock::now() - t0;
  ASSERT_TRUE(res.has_value());
  EXPECT_GE(elapsed, 25ms);
  EXPECT_LT(elapsed, 80ms);  // 若串行实现会是 ~90ms
}

// 连续多次 sleep 稳定性
TEST(Sleep, RepeatedWaits)
{
  for (int i = 0; i < 5; ++i) {
    expect_sleep_ok(dcb::sleep(10ms), 5ms);
  }
}
