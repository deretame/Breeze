#include <gtest/gtest.h>
#include <qjsbind/qjsbind.hpp>
#include <qjsbind/std_exec.hpp>
#include <stdexec/execution.hpp>

using namespace qjs;

// Runtime + std_exec::task（std::exec::task 参考实现）：无挂起点（co_return 直接）
TEST(MiniTask, RuntimeNoSuspend)
{
    Runtime rt;
    Context ctx = rt.main_context();
    for (int i = 0; i < 2; ++i) {
        auto sndr = []() -> std_exec::task<int> { co_return 1; }();
        auto chained = std::move(sndr)
            | stdexec::then([&](int) noexcept {})
            | stdexec::upon_error([&](std::exception_ptr) noexcept {})
            | stdexec::upon_stopped([&]() noexcept {});
        rt.spawn(std::move(chained));
        rt.run_to_completion();
    }
}

// Runtime + std_exec::task：有挂起点（co_await just）
TEST(MiniTask, RuntimeWithSuspend)
{
    Runtime rt;
    Context ctx = rt.main_context();
    for (int i = 0; i < 2; ++i) {
        auto sndr = []() -> std_exec::task<int> {
            co_await stdexec::just();
            co_return 1;
        }();
        auto chained = std::move(sndr)
            | stdexec::then([&](int) noexcept {})
            | stdexec::upon_error([&](std::exception_ptr) noexcept {})
            | stdexec::upon_stopped([&]() noexcept {});
        rt.spawn(std::move(chained));
        rt.run_to_completion();
    }
}
