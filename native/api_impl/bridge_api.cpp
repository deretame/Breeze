#include "bridge_api.h"

#include "jm_decode.h"

#include "dart_cpp_bridge/runtime.hpp"

#include <exec/static_thread_pool.hpp>

#include <thread>
#include <chrono>
#include <utility>

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

stdexec::task<std::string> fetch_greeting(std::string name) {
  co_return "Hello, " + name + "! (from coroutine)";
}

// ============================================================
// 禁漫图片反混淆
// ============================================================

namespace {

// 业务线程池：4 个线程，承载图片解码 / 编码 / 磁盘 IO 等阻塞工作。
exec::static_thread_pool g_decode_pool{4};

}  // namespace

stdexec::task<void> anti_obfuscation_picture(
    const std::uint8_t* img_data,
    std::int32_t img_data_len,
    std::int32_t chapter_id,
    std::string url,
    std::string file_name) {
  // 阻塞工作丢到 static_thread_pool 上跑，完成后回到 io 线程；
  // 异常会在 co_await 处重新抛出，由 wire 层编码为错误帧返回 Dart。
  co_await dcb::spawn_blocking(
      [=] {
        jm_decode::anti_obfuscation_picture(img_data, img_data_len, chapter_id,
                                            url, file_name);
      },
      g_decode_pool.get_scheduler());
}
