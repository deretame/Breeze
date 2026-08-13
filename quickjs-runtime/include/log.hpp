// log.hpp — 项目通用日志模块（对 spdlog 的轻量封装，不绑定任何子模块）
//
// 设计要点：
//   1. 全局单例：程序内唯一一个 spdlog logger。存储只在本模块内部可见
//      （detail::logger_storage 的 Meyers singleton），外部代码无法直接
//      读写该变量，只能通过 qlog::set_logger() / qlog::get_logger() 访问。
//      存储用裸指针（参照 spdlog registry::get_default_raw 的设计）：
//      全局实例的生命周期与进程一致，调用方负责在程序结束前保持 logger
//      存活，不要自行 delete（便捷重载创建的 logger 归单例所有）。
//   2. 日志输出完全交给 spdlog：格式化 / sink / 级别过滤 / 线程同步等
//      全部由 spdlog 完成。
//   3. 两种调用模式（都带 fmt 编译期检查格式化）：
//        a) 宏模式（推荐）：QLOG_INFO("x = {}", 42)
//           大写宏在调用点展开，自动注入 std::source_location::current()，
//           位置自动生效，无需手动传参。
//        b) 函数模式：qlog::log::info(std::source_location::current(), "x = {}", 42)
//           手动传位置，适合需要自定义 loc（如封装层转发调用点）的场景。
//   4. 并发：日志调用（打印）本身线程安全（spdlog 负责同步）；
//      set_logger / set_level 等配置操作请在日志开始前完成（配置阶段），
//      不要在打印进行中切换 logger——本模块不设锁（锁对高频日志调用
//      性能影响太大），同时设置与打印是数据竞争（未定义行为）。
//
// 为什么宏用大写 QLOG_*（而不是小写 log::info）：
//   原 temp.cpp 用 `loc = std::source_location::current()` 默认参数在调用点
//   自动取值。clang（含 clang-cl 22）对“函数参数包后面还有参数”的模板
//   推导会把包推空（与 GCC/MSVC 的实现分歧），导致
//   `(fmt_str, Args&&... args, loc = current())` 结构在带格式化参数时无法
//   编译（已用最小用例验证）。自动位置只能靠宏在调用点展开实现；
//   小写宏（info/error/...）会污染所有同名标识符（如对象的 .error() 方法、
//   spdlog::info），因此宏统一采用 QLOG_* 大写形式。
//   函数模式位于 qlog::log 嵌套命名空间（不是全局 namespace log）：
//   全局 log 命名空间与 MSVC 标准库头 <random>/<complex> 内部的
//   未限定 log 调用冲突（reference to 'log' is ambiguous），必须嵌套。
//
// 使用示例：
//   #include <log.hpp>
//
//   QLOG_INFO("hello {}", "world");                              // 宏：自动带调用点位置
//   qlog::log::info(std::source_location::current(), "hello {}", "world"); // 函数：手动传位置
//   qlog::set_level(qlog::log_level::debug);                      // 调整全局级别
//   qlog::set_logger({file_sink, stdout_sink}, "app");           // 或按 sinks 创建

#pragma once

#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>

#include <fmt/format.h>

#include <memory>
#include <source_location>
#include <string>
#include <utility>
#include <vector>

namespace qlog {

// =========================
// log level
// =========================
// 对齐 spdlog 的级别（比 temp.cpp 多 trace / critical 两档）
enum class log_level {
    trace,
    debug,
    info,
    warning,
    error,
    critical
};

constexpr spdlog::level::level_enum to_spdlog(log_level level) noexcept
{
    switch (level) {
    case log_level::trace:    return spdlog::level::trace;
    case log_level::debug:    return spdlog::level::debug;
    case log_level::info:     return spdlog::level::info;
    case log_level::warning:  return spdlog::level::warn;
    case log_level::error:    return spdlog::level::err;
    case log_level::critical: return spdlog::level::critical;
    }
    return spdlog::level::info;
}

constexpr log_level from_spdlog(spdlog::level::level_enum level) noexcept
{
    switch (level) {
    case spdlog::level::trace:    return log_level::trace;
    case spdlog::level::debug:    return log_level::debug;
    case spdlog::level::info:     return log_level::info;
    case spdlog::level::warn:     return log_level::warning;
    case spdlog::level::err:      return log_level::error;
    case spdlog::level::critical: return log_level::critical;
    case spdlog::level::off:
    case spdlog::level::n_levels: break;
    }
    return log_level::info;
}

constexpr const char* level_name(log_level level) noexcept
{
    switch (level) {
    case log_level::trace:    return "TRACE";
    case log_level::debug:    return "DEBUG";
    case log_level::info:     return "INFO";
    case log_level::warning:  return "WARN";
    case log_level::error:    return "ERROR";
    case log_level::critical: return "CRITICAL";
    }
    return "UNKNOWN";
}

// =========================
// 全局 logger 单例（存储只在本模块可见）
// =========================
namespace detail {

// 默认 logger：stderr 彩色输出，pattern 含时间 / 级别 / 源位置。
// 不经 spdlog registry（避免与全局 registry 的注册名冲突）。
// new 出的实例归全局单例所有，进程结束前不释放（全局实例生命周期）。
inline spdlog::logger* make_default_logger()
{
    auto logger = new spdlog::logger(
        "qlog",
        std::make_shared<spdlog::sinks::stderr_color_sink_mt>());
    logger->set_pattern("[%Y-%m-%d %H:%M:%S.%e] [%^%l%$] [%s:%#] %v");
    logger->set_level(spdlog::level::trace); // 默认全开，需要过滤时由调用方 set_level
    return logger;
}

// 全局单例存储：只有本模块能读写这个变量。
// 函数内 static（Meyers singleton）保证程序内唯一实例，且外部代码拿不到
// 它的引用——只能走下面的 set_logger / get_logger。
// 裸指针：全局实例生命周期与进程一致，不要 delete。
inline spdlog::logger*& logger_storage()
{
    static spdlog::logger* logger = make_default_logger();
    return logger;
}

// 取当前 logger（裸指针，无锁）。
// 多个线程并发调用本函数（只读）是安全的；但若与 set_logger 并发
// （一边打印一边切换）会形成数据竞争，请遵守“配置阶段设置、
// 运行期只打印”的约定（见文件头）。
inline spdlog::logger* current_logger()
{
    return logger_storage();
}

} // namespace detail

// =========================
// 全局单例的读写接口
// =========================

// 设置全局 logger（裸指针）。传 nullptr 时回退到默认 logger。
// 生命周期：全局实例与进程一致，调用方须在程序结束前保持 logger 存活，
// 不要自行 delete（单例切换后旧 logger 归调用方管理）。
// 注意：请在日志开始前（配置阶段）调用；运行期并发打印时调用
// 会与读取形成数据竞争（无锁设计，见文件头“并发”说明）。
inline void set_logger(spdlog::logger* logger)
{
    if (!logger)
        logger = detail::make_default_logger();

    detail::logger_storage() = logger;
}

// 便捷重载：用一组 sink 创建命名 logger 并设为全局。
// 创建的实例归全局单例所有，进程结束前不释放（全局实例生命周期）。
inline void set_logger(std::vector<spdlog::sink_ptr> sinks, std::string name = "qlog")
{
    set_logger(new spdlog::logger(
        std::move(name), sinks.begin(), sinks.end()));
}

// 获取当前全局 logger（裸指针，与日志调用并发读取安全）。
// 返回的指针在下次 set_logger 前有效；不要自行 delete。
inline spdlog::logger* get_logger()
{
    return detail::current_logger();
}

// 便捷：设置全局日志级别（配置阶段调用，透传 spdlog 的级别过滤）
inline void set_level(log_level level)
{
    get_logger()->set_level(to_spdlog(level));
}

// =========================
// 带位置的日志写入（log::* 函数与 QLOG_* 宏的展开目标）
// =========================

template<class... Args>
inline void log_at(
    std::source_location loc,
    log_level level,
    fmt::format_string<Args...> fmt_str,
    Args&&... args)
{
    auto logger = detail::current_logger();
    if (!logger || !logger->should_log(to_spdlog(level)))
        return;

    logger->log(
        spdlog::source_loc{
            loc.file_name(),
            static_cast<int>(loc.line()),
            loc.function_name()
        },
        to_spdlog(level),
        fmt_str,
        std::forward<Args>(args)...);
}

} // namespace qlog

// =========================
// qlog::log 命名空间：函数模式（手动传 std::source_location）
// =========================
// 普通函数（非宏），不会污染任何标识符。位置参数必须显式传入：
//   qlog::log::info(std::source_location::current(), "x = {}", 42);
// 宏模式 QLOG_INFO(...) 展开后即调用这里的函数。
// 注意嵌套在 qlog 下：全局 namespace log 与 MSVC 标准库头冲突。
namespace qlog {
namespace log {

template<class... Args>
inline void trace(std::source_location loc, fmt::format_string<Args...> fmt_str, Args&&... args)
{
    qlog::log_at(loc, qlog::log_level::trace, fmt_str, std::forward<Args>(args)...);
}

template<class... Args>
inline void debug(std::source_location loc, fmt::format_string<Args...> fmt_str, Args&&... args)
{
    qlog::log_at(loc, qlog::log_level::debug, fmt_str, std::forward<Args>(args)...);
}

template<class... Args>
inline void info(std::source_location loc, fmt::format_string<Args...> fmt_str, Args&&... args)
{
    qlog::log_at(loc, qlog::log_level::info, fmt_str, std::forward<Args>(args)...);
}

template<class... Args>
inline void warning(std::source_location loc, fmt::format_string<Args...> fmt_str, Args&&... args)
{
    qlog::log_at(loc, qlog::log_level::warning, fmt_str, std::forward<Args>(args)...);
}

template<class... Args>
inline void error(std::source_location loc, fmt::format_string<Args...> fmt_str, Args&&... args)
{
    qlog::log_at(loc, qlog::log_level::error, fmt_str, std::forward<Args>(args)...);
}

template<class... Args>
inline void critical(std::source_location loc, fmt::format_string<Args...> fmt_str, Args&&... args)
{
    qlog::log_at(loc, qlog::log_level::critical, fmt_str, std::forward<Args>(args)...);
}

} // namespace log
} // namespace qlog

// =========================
// 大写宏：QLOG_INFO("...", x) 自动携带调用点位置
// =========================
// 宏在调用点展开，std::source_location::current() 作为实参在调用点求值，
// 因此位置自动生效。QLOG_* 是独立大写 token，不会与 info/error 等
// 小写标识符冲突（区别于小写宏方案）。
#define QLOG_TRACE(...)    qlog::log::trace(std::source_location::current(), __VA_ARGS__)
#define QLOG_DEBUG(...)    qlog::log::debug(std::source_location::current(), __VA_ARGS__)
#define QLOG_INFO(...)     qlog::log::info(std::source_location::current(), __VA_ARGS__)
#define QLOG_WARNING(...)  qlog::log::warning(std::source_location::current(), __VA_ARGS__)
#define QLOG_ERROR(...)    qlog::log::error(std::source_location::current(), __VA_ARGS__)
#define QLOG_CRITICAL(...) qlog::log::critical(std::source_location::current(), __VA_ARGS__)
