// 日志模块单测：验证全局单例的读写接口、两种调用模式（QLOG_* 宏 / log::* 函数）
// 与 spdlog 转发行为、线程安全
#include <log.hpp>

#include <gtest/gtest.h>
#include <spdlog/sinks/ringbuffer_sink.h>

#include <atomic>
#include <chrono>
#include <memory>
#include <string>
#include <thread>
#include <vector>

namespace {

// 环形缓冲 sink：捕获格式化后的消息，便于断言
std::shared_ptr<spdlog::sinks::ringbuffer_sink_mt> make_test_sink()
{
    auto sink = std::make_shared<spdlog::sinks::ringbuffer_sink_mt>(128);
    sink->set_pattern("[%s:%#] %v");
    return sink;
}

// 测试 logger：unique_ptr 持有，set_logger 传裸指针（全局单例不接管生命周期）
std::unique_ptr<spdlog::logger> make_test_logger()
{
    auto logger = std::make_unique<spdlog::logger>("test", make_test_sink());
    logger->set_level(spdlog::level::trace);
    return logger;
}

std::shared_ptr<spdlog::sinks::ringbuffer_sink_mt> sink_of(const spdlog::logger* logger)
{
    return std::static_pointer_cast<spdlog::sinks::ringbuffer_sink_mt>(
        logger->sinks().front());
}

// 最后一条格式化消息（ringbuffer 的 last_formatted 返回 vector）
std::string last_line(const std::shared_ptr<spdlog::sinks::ringbuffer_sink_mt>& sink)
{
    auto lines = sink->last_formatted();
    return lines.empty() ? std::string{} : lines.back();
}

// 每个用例结束后恢复默认 logger，避免用例间串扰
struct LogTest : testing::Test {
    void TearDown() override
    {
        qlog::set_logger(nullptr); // 回退到默认 logger
    }
};

} // namespace

TEST_F(LogTest, DefaultLoggerIsUsable)
{
    auto logger = qlog::get_logger();
    ASSERT_NE(logger, nullptr);
    EXPECT_EQ(logger->name(), "qlog");

    // 默认 logger 可直接写日志（不抛异常、不崩溃）
    EXPECT_NO_THROW(QLOG_INFO("default logger smoke"));
    EXPECT_NO_THROW(QLOG_ERROR("error path {}", 1));
}

TEST_F(LogTest, SetLoggerReplacesGlobal)
{
    auto logger = make_test_logger();
    qlog::set_logger(logger.get());

    // 读取返回同一实例
    EXPECT_EQ(qlog::get_logger(), logger.get());

    QLOG_INFO("hello {}", 42);

    auto sink = sink_of(logger.get());
    EXPECT_EQ(sink->last_formatted().size(), 1u);
    EXPECT_NE(last_line(sink).find("hello 42"), std::string::npos);
}

TEST_F(LogTest, SetLoggerFromSinks)
{
    auto sink = make_test_sink();
    qlog::set_logger({sink}, "custom");

    auto logger = qlog::get_logger(); // 便捷重载创建的实例归单例所有
    EXPECT_EQ(logger->name(), "custom");

    QLOG_INFO("via sinks");
    EXPECT_EQ(sink->last_formatted().size(), 1u);
}

TEST_F(LogTest, SetLoggerNullFallsBackToDefault)
{
    qlog::set_logger(nullptr);
    auto logger = qlog::get_logger();
    ASSERT_NE(logger, nullptr);
    EXPECT_EQ(logger->name(), "qlog");
}

TEST_F(LogTest, MacroAutoLocation)
{
    auto logger = make_test_logger();
    qlog::set_logger(logger.get());

    // QLOG_* 宏：展开为 log::*(std::source_location::current(), ...)，
    // 位置自动取自调用点（本文件）
    QLOG_INFO("macro with {}", 42);
    QLOG_WARNING("macro warn {}", "x");

    auto sink = sink_of(logger.get());
    auto lines = sink->last_formatted();
    ASSERT_EQ(lines.size(), 2u);
    EXPECT_NE(lines[0].find("macro with 42"), std::string::npos);
    EXPECT_NE(lines[0].find("log_test.cpp:"), std::string::npos);
    EXPECT_NE(lines[1].find("log_test.cpp:"), std::string::npos);
}

TEST_F(LogTest, FunctionModeExplicitLocation)
{
    auto logger = make_test_logger();
    qlog::set_logger(logger.get());

    // 函数模式：手动传 std::source_location（本文件调用点）
    qlog::log::info(std::source_location::current(), "fn mode {}", 7);

    auto sink = sink_of(logger.get());
    EXPECT_NE(last_line(sink).find("fn mode 7"), std::string::npos);
    EXPECT_NE(last_line(sink).find("log_test.cpp:"), std::string::npos);
}

TEST_F(LogTest, LevelFilterRespected)
{
    auto logger = make_test_logger();
    logger->set_level(spdlog::level::warn);
    qlog::set_logger(logger.get());

    QLOG_TRACE("hidden");
    QLOG_DEBUG("hidden");
    QLOG_INFO("hidden too");
    QLOG_WARNING("shown");
    QLOG_ERROR("shown too");

    auto sink = sink_of(logger.get());
    auto lines = sink->last_formatted();
    EXPECT_EQ(lines.size(), 2u);
    EXPECT_NE(lines.back().find("shown too"), std::string::npos);
}

TEST_F(LogTest, AllLevelsForwarded)
{
    auto logger = make_test_logger();
    qlog::set_logger(logger.get());

    QLOG_TRACE("t");
    QLOG_DEBUG("d");
    QLOG_INFO("i");
    QLOG_WARNING("w");
    QLOG_ERROR("e");
    QLOG_CRITICAL("c");

    auto sink = sink_of(logger.get());
    auto lines = sink->last_formatted();
    ASSERT_EQ(lines.size(), 6u);
    EXPECT_NE(lines.back().find("c"), std::string::npos);
}

TEST_F(LogTest, LevelMappingRoundTrip)
{
    const qlog::log_level levels[] = {
        qlog::log_level::trace,
        qlog::log_level::debug,
        qlog::log_level::info,
        qlog::log_level::warning,
        qlog::log_level::error,
        qlog::log_level::critical,
    };
    for (auto l : levels) {
        EXPECT_EQ(qlog::from_spdlog(qlog::to_spdlog(l)), l);
        EXPECT_NE(qlog::level_name(l), nullptr);
    }
}

TEST_F(LogTest, SetLevelHelper)
{
    auto logger = make_test_logger();
    qlog::set_logger(logger.get());

    qlog::set_level(qlog::log_level::error);
    EXPECT_EQ(logger->level(), spdlog::level::err);

    qlog::set_level(qlog::log_level::debug);
    EXPECT_EQ(logger->level(), spdlog::level::debug);
}

TEST_F(LogTest, SequentialSetLoggerReplacesRepeatedly)
{
    // 配置阶段多次顺序替换（无并发）：每次替换后日志写入新 logger
    for (int i = 0; i < 5; ++i) {
        auto logger = make_test_logger();
        qlog::set_logger(logger.get());
        QLOG_INFO("round {}", i);

        auto sink = sink_of(logger.get());
        EXPECT_EQ(sink->last_formatted().size(), 1u);
        EXPECT_NE(last_line(sink).find("round " + std::to_string(i)), std::string::npos);
    }
}

TEST_F(LogTest, ConcurrentLoggingIsSafe)
{
    // 无锁约定：set_logger 在并发打印开始前完成，运行期只并发打印
    //（spdlog logger 与 ringbuffer sink 均线程安全），不应崩溃 / 死锁
    auto logger = make_test_logger();
    qlog::set_logger(logger.get());

    std::atomic<bool> stop{false};
    std::vector<std::thread> writers;
    for (int t = 0; t < 4; ++t) {
        writers.emplace_back([&, t] {
            while (!stop.load(std::memory_order_relaxed)) {
                QLOG_INFO("thread {}", t);
                QLOG_DEBUG("noise");
            }
        });
    }

    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    stop.store(true, std::memory_order_relaxed);
    for (auto& th : writers)
        th.join();

    SUCCEED(); // 到达此处即证明并发打印未崩溃 / 未死锁
}
