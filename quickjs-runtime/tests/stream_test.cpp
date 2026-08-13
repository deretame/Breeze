#include <dart_cpp_bridge/runtime.hpp>
#include <qjsbind/std_exec.hpp>
#include <dart_cpp_bridge/stream.hpp>

#include <stdexec/execution.hpp>
#include <gtest/gtest.h>
#include <stdexec/execution.hpp>

#include <chrono>
#include <thread>
#include <utility>
#include <vector>

namespace {

// 在同步上下文中运行一个 std_exec::task（task 本身是 sender）。
template <typename T>
std::optional<T> run(std_exec::task<T> t)
{
  auto res = stdexec::sync_wait(std::move(t));
  if (!res) return std::nullopt;
  return std::get<0>(std::move(*res));
}

}  // namespace

TEST(Stream, FromVectorCollect)
{
  auto res = run(co::stream::from_vector(std::vector<int>{1, 2, 3}).collect());
  ASSERT_TRUE(res.has_value());
  EXPECT_EQ(*res, (std::vector<int>{1, 2, 3}));
}

TEST(Stream, OnceAndEmpty)
{
  auto once_res = run(co::stream::once(7).collect());
  ASSERT_TRUE(once_res.has_value());
  EXPECT_EQ(*once_res, (std::vector<int>{7}));

  auto empty_res = run(co::stream::empty<int>().collect());
  ASSERT_TRUE(empty_res.has_value());
  EXPECT_TRUE(empty_res->empty());
}

TEST(Stream, MapFilterTake)
{
  auto s = co::stream::from_vector(std::vector<int>{1, 2, 3, 4, 5, 6});
  auto res = run(std::move(s)
                     .map([](int x) { return x * 2; })    // 2, 4, 6, 8, 10, 12
                     .filter([](int x) { return x > 4; }) // 6, 8, 10, 12
                     .take(3)                              // 6, 8, 10
                     .collect());
  ASSERT_TRUE(res.has_value());
  EXPECT_EQ(*res, (std::vector<int>{6, 8, 10}));
}

TEST(Stream, TakeShortCircuit)
{
  // take 超过源长度：正常结束而不是出错
  auto s = co::stream::from_vector(std::vector<int>{1, 2});
  auto res = run(std::move(s).take(5).collect());
  ASSERT_TRUE(res.has_value());
  EXPECT_EQ(*res, (std::vector<int>{1, 2}));
}

TEST(Stream, SkipAndTakeWhile)
{
  auto s = co::stream::from_vector(std::vector<int>{1, 2, 3, 4, 5});
  auto res = run(std::move(s).skip(2).take_while([](int x) { return x < 5; }).collect());
  ASSERT_TRUE(res.has_value());
  EXPECT_EQ(*res, (std::vector<int>{3, 4}));
}

TEST(Stream, Scan)
{
  auto s = co::stream::from_vector(std::vector<int>{1, 2, 3, 4});
  auto res = run(std::move(s).scan(0, [](int acc, int v) { return acc + v; }).collect());
  ASSERT_TRUE(res.has_value());
  EXPECT_EQ(*res, (std::vector<int>{1, 3, 6, 10}));
}

TEST(Stream, Fold)
{
  auto s = co::stream::from_vector(std::vector<int>{1, 2, 3, 4});
  auto res = run(std::move(s).fold(0, [](int acc, int v) { return acc + v; }));
  ASSERT_TRUE(res.has_value());
  EXPECT_EQ(*res, 10);
}

TEST(Stream, Count)
{
  auto s = co::stream::from_vector(std::vector<int>{1, 2, 3, 4, 5});
  auto res = run(std::move(s).count());
  ASSERT_TRUE(res.has_value());
  EXPECT_EQ(*res, 5u);
}

TEST(Stream, Zip)
{
  auto a = co::stream::from_vector(std::vector<int>{1, 2, 3});
  auto b = co::stream::from_vector(std::vector<char>{'a', 'b', 'c'});
  auto res = run(std::move(a).zip(std::move(b)).collect());
  ASSERT_TRUE(res.has_value());
  ASSERT_EQ(res->size(), 3u);
  EXPECT_EQ((*res)[0], (std::pair<int, char>{1, 'a'}));
  EXPECT_EQ((*res)[1], (std::pair<int, char>{2, 'b'}));
  EXPECT_EQ((*res)[2], (std::pair<int, char>{3, 'c'}));
}

TEST(Stream, Merge)
{
  auto a = co::stream::from_vector(std::vector<int>{1, 2});
  auto b = co::stream::from_vector(std::vector<int>{10, 20});
  auto res = run(std::move(a).merge(std::move(b)).collect());
  ASSERT_TRUE(res.has_value());
  // merge 按源交替产出，但这里只断言集合与数量，不依赖具体顺序
  ASSERT_EQ(res->size(), 4u);
  auto sorted = *res;
  std::sort(sorted.begin(), sorted.end());
  EXPECT_EQ(sorted, (std::vector<int>{1, 2, 10, 20}));
}

TEST(Stream, Interval)
{
  auto res = run(co::stream::interval<int>(std::chrono::milliseconds(5)).take(3).collect());
  ASSERT_TRUE(res.has_value());
  EXPECT_EQ(*res, (std::vector<int>{0, 1, 2}));
}
