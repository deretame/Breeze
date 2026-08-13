#pragma once

#include "dart_cpp_bridge/annotate.h"
#include "dart_cpp_bridge/stream_sink.hpp"

#include <stdexec/execution.hpp>

#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <unordered_map>
#include <vector>

namespace fetch {
namespace easy {
class Client;
class RequestBuilder;
}
} // namespace fetch

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

// ============================================================
// HTTP fetch（fetchcore / fetch::easy 实现，替代原 Rust reqwest 路径）
// ============================================================

/// 单次请求参数（对齐原 Rust 侧 FetchInit）。
/// → Dart data class WindFetchInit
struct BRIDGE_DATA_CLASS WindFetchInit {
  std::string method;              // "GET" 等，空 = GET
  std::unordered_map<std::string, std::string> headers;
  std::vector<std::uint8_t> body;  // 空 = 无 body（wire 走 u8vec 批量编码）
  std::int64_t timeout_ms;         // <= 0 → 用 client 默认超时
  std::optional<bool> follow_redirects; // null → 用 client 默认
};

/// 一次性收齐的响应（对齐原 Rust 侧 FetchResponse）。
/// → Dart data class WindFetchResponse
struct BRIDGE_DATA_CLASS WindFetchResponse {
  std::int32_t status;
  std::string status_text;
  std::unordered_map<std::string, std::string> headers; // 重名以 ", " 合并
  std::vector<std::uint8_t> body;
  std::string url;       // 最终 URL（重定向后）
  bool redirected;
};

/// 下载进度（StreamSink 流元素）。
/// → Dart data class WindDownloadProgress
struct BRIDGE_DATA_CLASS WindDownloadProgress {
  std::int64_t received;
  std::int64_t total; // 未知 = -1
};

/// Fetch 风格 HTTP 客户端（opaque，Dart 侧由 WindHttp 封装）。
/// 代理 / TLS 校验在 Dart 侧解析为确定值后传入：
///   proxy 为空串 = 强制直连（屏蔽进程级系统代理探测）；非空 = 代理 URL
///   （"http://[user:pass@]host:port" / "socks5://[user:pass@]host:port"）。
/// 底层 fetch::easy::Client 惰性构造于首次请求（io 线程线程契约）。
class BRIDGE_OPAQUE WindHttpClient {
public:
  BRIDGE_CONSTRUCTOR
  WindHttpClient(std::unordered_map<std::string, std::string> default_headers,
                 std::int64_t timeout_ms, bool follow_redirects,
                 std::string proxy, bool tls_verify, std::string user_agent);

  ~WindHttpClient();

  /// → Dart: Future<WindFetchResponse> fetch(String url, WindFetchInit init)
  BRIDGE_ASYNC
  stdexec::task<WindFetchResponse> fetch(std::string url, WindFetchInit init);

  /// 流式下载到磁盘（.part 临时文件 + rename，对齐原 Rust download 行为）。
  /// progress：可选进度流，total 未知时为 -1（事件即发即弃，无往返背压）。
  /// → Dart: Future<void> download(..., {StreamController<WindDownloadProgress>? progress})
  BRIDGE_ASYNC
  stdexec::task<void> download(
      std::string url, std::string save_path, WindFetchInit init,
      std::optional<dcb::StreamSink<WindDownloadProgress>> progress);

private:
  // 惰性构造底层 client（必须发生在已 set_thread_io 的 io 线程）。
  fetch::easy::Client& ensure_client();
  fetch::easy::RequestBuilder make_request(std::string url,
                                           const WindFetchInit& init);

  std::unordered_map<std::string, std::string> default_headers_;
  std::int64_t timeout_ms_;
  bool follow_redirects_;
  std::string proxy_;
  bool tls_verify_;
  std::string user_agent_;
  std::shared_ptr<fetch::easy::Client> client_;
};
