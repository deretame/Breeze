#include <gtest/gtest.h>
#include <quickjs.h>

#include <dart_cpp_bridge/runtime.hpp>
#include <stdexec/execution.hpp>

namespace {
// 全局启动 dcb::Runtime：dcb::sleep 的默认调度器、co::stream::interval 等
// 都跑在它的 io 线程上。
struct DcbRuntimeEnvironment : ::testing::Environment {
  void SetUp() override { dcb::Runtime::instance().start(); }
  void TearDown() override { dcb::Runtime::instance().stop(); }
};
[[maybe_unused]] auto* g_dcb_runtime_env =
    ::testing::AddGlobalTestEnvironment(new DcbRuntimeEnvironment);
}  // namespace

#ifdef _WIN32
// 抑制 Windows 断言/abort/GPF 弹窗：崩溃时只输出到 stderr，进程以非零码退出
// （否则调试构建的 Assertion failed 对话框需要手动关闭，CI/脚本无法自动处理）
#include <crtdbg.h>
#include <cstdlib>
#include <windows.h>
namespace {
struct suppress_crash_dialogs {
    suppress_crash_dialogs()
    {
        // CRT assert / abort 报告改走 stderr（默认弹窗）
        _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE);
        _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
        _CrtSetReportMode(_CRT_ERROR, _CRTDBG_MODE_FILE);
        _CrtSetReportFile(_CRT_ERROR, _CRTDBG_FILE_STDERR);
        _CrtSetReportMode(_CRT_WARN, _CRTDBG_MODE_FILE);
        _CrtSetReportFile(_CRT_WARN, _CRTDBG_FILE_STDERR);
        // abort() 不写消息、不弹窗、不调报告器，直接终止
        // （新版 UCRT flag 宏为 _WRITE_ABORT_MSG | _CALL_REPORTFAULT）
        _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
        // 全局错误模式：不弹「严重错误/GPF/打开文件失败」对话框
        SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX | SEM_NOOPENFILEERRORBOX);
    }
} g_suppress_crash_dialogs;
} // namespace
#endif

TEST(Quickjs, Eval) {
    JSRuntime* rt = JS_NewRuntime();
    ASSERT_NE(rt, nullptr);
    JSContext* ctx = JS_NewContext(rt);
    ASSERT_NE(ctx, nullptr);

    JSValue result = JS_Eval(ctx, "40 + 2", 6, "<test>", JS_EVAL_TYPE_GLOBAL);
    ASSERT_FALSE(JS_IsException(result));
    int32_t value = 0;
    ASSERT_EQ(JS_ToInt32(ctx, &value, result), 0);
    EXPECT_EQ(value, 42);

    JS_FreeValue(ctx, result);
    JS_FreeContext(ctx);
    JS_FreeRuntime(rt);
}

TEST(Stdexec, Just) {
    auto result = stdexec::sync_wait(stdexec::just(7));
    ASSERT_TRUE(result.has_value());
    EXPECT_EQ(std::get<0>(*result), 7);
}
