#pragma once

#include "dart_cpp_bridge/annotate.h"

#include <async_simple/coro/Lazy.h>

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
async_simple::coro::Lazy<std::string> fetch_greeting(std::string name);
