#include "bridge_api.h"

#include <thread>
#include <chrono>

// ============================================================
// Example implementation — replace with your own logic.
// ============================================================

std::int32_t add(std::int32_t a, std::int32_t b) {
  return a + b;
}

std::string heavy_compute(std::int32_t input) {
  std::this_thread::sleep_for(std::chrono::milliseconds(50));
  return "computed: " + std::to_string(input * input);
}

async_simple::coro::Lazy<std::string> fetch_greeting(std::string name) {
  co_return "Hello, " + name + "! (from coroutine)";
}
