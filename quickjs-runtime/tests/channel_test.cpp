#include <dart_cpp_bridge/channel.hpp>
#include <qjsbind/std_exec.hpp>

#include <stdexec/execution.hpp>
#include <gtest/gtest.h>
#include <stdexec/execution.hpp>

#include <chrono>
#include <exception>
#include <optional>
#include <stdexcept>
#include <thread>
#include <utility>
#include <vector>

namespace {

template <typename T>
std::optional<T> run(std_exec::task<T> t)
{
  auto res = stdexec::sync_wait(std::move(t));
  if (!res) return std::nullopt;
  return std::get<0>(std::move(*res));
}

}  // namespace

// ---------------------------------------------------------------------------
// oneshot
// ---------------------------------------------------------------------------

TEST(Channel, OneshotSend)
{
  auto [tx, rx] = co::oneshot::channel<int>();
  tx.send(42);
  auto res = stdexec::sync_wait(std::move(rx));
  ASSERT_TRUE(res.has_value());
  EXPECT_EQ(std::get<0>(*res).value(), 42);
}

TEST(Channel, OneshotCloseDeliversNullopt)
{
  auto [tx, rx] = co::oneshot::channel<int>();
  tx.close();
  auto res = stdexec::sync_wait(std::move(rx));
  ASSERT_TRUE(res.has_value());
  EXPECT_FALSE(std::get<0>(*res).has_value());
}

TEST(Channel, OneshotSendError)
{
  auto [tx, rx] = co::oneshot::channel<int>();
  tx.send_error(std::make_exception_ptr(std::runtime_error("boom")));
  // sync_wait 遇到 set_error 会 rethrow
  EXPECT_THROW(stdexec::sync_wait(std::move(rx)), std::runtime_error);
}

// ---------------------------------------------------------------------------
// mpsc unbounded
// ---------------------------------------------------------------------------

TEST(Channel, MpscUnboundedBasic)
{
  auto [tx, rx] = co::mpsc::unbounded<int>();
  EXPECT_TRUE(tx.send(1));
  EXPECT_TRUE(tx.send(2));
  EXPECT_TRUE(tx.send(3));
  tx.close();
  auto res = run(std::move(rx).take(3).collect());
  ASSERT_TRUE(res.has_value());
  EXPECT_EQ(*res, (std::vector<int>{1, 2, 3}));
}

TEST(Channel, MpscUnboundedMultiThread)
{
  auto [tx, rx] = co::mpsc::unbounded<int>();
  constexpr int kThreads = 4;
  constexpr int kPerThread = 200;

  std::vector<std::thread> threads;
  for (int t = 0; t < kThreads; ++t) {
    threads.emplace_back([&tx, t] {
      for (int i = 0; i < kPerThread; ++i) {
        tx.send(t * kPerThread + i);
      }
    });
  }
  for (auto& th : threads) th.join();
  tx.close();

  auto res = run(std::move(rx).collect());
  ASSERT_TRUE(res.has_value());
  EXPECT_EQ(res->size(), static_cast<std::size_t>(kThreads * kPerThread));
}

TEST(Channel, MpscUnboundedCloseStopsIteration)
{
  auto [tx, rx] = co::mpsc::unbounded<int>();
  tx.send(1);
  tx.close();  // close 之后 send 失败
  EXPECT_FALSE(tx.send(2));

  auto res = run(std::move(rx).collect());
  ASSERT_TRUE(res.has_value());
  EXPECT_EQ(*res, (std::vector<int>{1}));
}

// ---------------------------------------------------------------------------
// mpsc bounded（backpressure）
// ---------------------------------------------------------------------------

TEST(Channel, MpscBoundedFifo)
{
  auto [tx, rx] = co::mpsc::bounded<int>(4);
  auto send_res = run([&tx]() -> std_exec::task<bool> {
    bool a = co_await tx.send(1);
    bool b = co_await tx.send(2);
    bool c = co_await tx.send(3);
    co_return a && b && c;
  }());
  ASSERT_TRUE(send_res.has_value());
  EXPECT_TRUE(*send_res);

  tx.close();
  auto recv_res = run(std::move(rx).take(3).collect());
  ASSERT_TRUE(recv_res.has_value());
  EXPECT_EQ(*recv_res, (std::vector<int>{1, 2, 3}));
}

TEST(Channel, MpscBoundedBackpressure)
{
  auto [tx, rx] = co::mpsc::bounded<int>(1);
  // 容量为 1：第二个 send 会 park，直到 receiver 取走一个值
  auto result = stdexec::sync_wait(stdexec::when_all(
      [&tx]() -> std_exec::task<bool> {
        bool a = co_await tx.send(10);
        bool b = co_await tx.send(20);  // 槽满 -> 挂起等 recv
        co_return a && b;
      }(),
      [&rx]() -> std_exec::task<std::optional<int>> {
        std::this_thread::sleep_for(std::chrono::milliseconds(20));
        co_return co_await rx.recv();
      }()));

  ASSERT_TRUE(result.has_value());
  EXPECT_TRUE(std::get<0>(*result));
  EXPECT_EQ(std::get<1>(*result).value_or(-1), 10);
}

TEST(Channel, MpscBoundedRendezvous)
{
  // capacity == 0：无缓冲，send 必须等到有 receiver 才会交付
  auto [tx, rx] = co::mpsc::bounded<int>(0);
  auto result = stdexec::sync_wait(stdexec::when_all(
      [&tx]() -> std_exec::task<bool> {
        bool ok = co_await tx.send(99);
        co_return ok;
      }(),
      [&rx]() -> std_exec::task<std::optional<int>> {
        std::this_thread::sleep_for(std::chrono::milliseconds(20));
        co_return co_await rx.recv();
      }()));

  ASSERT_TRUE(result.has_value());
  EXPECT_TRUE(std::get<0>(*result));
  EXPECT_EQ(std::get<1>(*result).value_or(-1), 99);
}
