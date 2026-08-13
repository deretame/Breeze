#pragma once

#include "dart_cpp_bridge/annotate.h"

#include <stdexec/execution.hpp>

#include <cstdint>
#include <string>

// ============================================================
// Example API — replace with your own functions.
// ============================================================

/// Sync function → Dart: int add(int a, int b)
BRIDGE_SYNC
std::int32_t add(std::int32_t a, std::int32_t b);

/// Thread-pool async (blocking work) → Dart: Future<String> heavyCompute(int input)
BRIDGE_NORMAL
std::string heavy_compute(std::int32_t input);

/// Coroutine async → Dart: Future<String> fetchGreeting(String name)
BRIDGE_ASYNC
stdexec::task<std::string> fetch_greeting(std::string name);

// ============================================================
// 禁漫图片反混淆
// ============================================================

/// 禁漫图片反混淆并保存到磁盘。
/// 协程异步（BRIDGE_ASYNC），实际工作在 4 线程的 static_thread_pool 上执行。
/// → Dart: Future<void> antiObfuscationPicture(...)
///
/// 注意：img_data 是 Dart 侧分配的指针（Pointer<Uint8>），
/// Dart 侧必须在 Future 完成前保证内存有效。
BRIDGE_ASYNC
stdexec::task<void> anti_obfuscation_picture(
    const std::uint8_t* img_data,
    std::int32_t img_data_len,
    std::int32_t chapter_id,
    std::string url,
    std::string file_name);
