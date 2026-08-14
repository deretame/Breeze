#pragma once

#include "dart_cpp_bridge/annotate.h"
#include "dart_cpp_bridge/dart_fn.hpp"
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

// ============================================================
// 插件 QJS 运行时（qjs::HostRuntime 桥接，替代原 Rust rquickjs 路径）
// 最小可用版：初始化 / 任务调用 / 销毁 / 替换 / debug / Dart 回调注册。
// 组取消等见 docs/cpp_plugin_runtime_design.md 后续补全清单。
// ============================================================

/// 建 runtime（重复调用幂等）。bundle_js 为空 = 建空 runtime（无插件函数）。
/// → Dart: Future<void> qjsBuildRuntime(String runtimeName, String bundleName, String bundleJs)
BRIDGE_ASYNC
stdexec::task<void> qjs_build_runtime(std::string runtime_name,
                                      std::string bundle_name,
                                      std::string bundle_js);

/// → Dart: Future<bool> qjsIsInitialized(String runtimeName)
BRIDGE_ASYNC
stdexec::task<bool> qjs_is_initialized(std::string runtime_name);

/// 销毁 runtime（排干后回收实例线程）。→ Dart: Future<bool>
BRIDGE_ASYNC
stdexec::task<bool> qjs_drop_runtime(std::string runtime_name);

/// 热替换常驻 bundle（原子替换，失败保留旧代码）。
/// → Dart: Future<void> qjsReplaceBundle(...)
BRIDGE_ASYNC
stdexec::task<void> qjs_replace_bundle(std::string runtime_name,
                                       std::string bundle_name,
                                       std::string bundle_js);

/// 清空常驻 bundle（替换为空 exports）。→ Dart: Future<bool>
BRIDGE_ASYNC
stdexec::task<bool> qjs_clear_bundle(std::string runtime_name);

/// 当前 bundle 名（JSON 文本："null" 或 "\"name\""）。→ Dart: Future<String>
BRIDGE_ASYNC
stdexec::task<std::string> qjs_current_bundle(std::string runtime_name);

/// 唯一调用入口（对齐 Rust qjs_task_call）。
/// is_once=true 且带 bundle_js = debug 热重载调用（屏障 + 串行 + 源码哈希
/// 缓存跳过重复 eval）。args_json 约定：JSON 文本整体 parse 后作为唯一参数
/// 传给目标函数。返回值：JS 返回 Uint8Array/ArrayBuffer → 真实字节；
/// 否则 JSON.stringify 的 UTF-8 字节。
/// task_group_key 仅签名对齐，组取消本期未实现。
/// → Dart: Future<Uint8List> qjsTaskCall(...)
BRIDGE_ASYNC
stdexec::task<std::vector<std::uint8_t>> qjs_task_call(
    std::string runtime_name, std::string task_group_key, bool is_once,
    std::optional<std::string> bundle_js, std::string fn_path,
    std::string args_json);

/// 实例诊断快照（pretty JSON）。→ Dart: Future<String>
BRIDGE_ASYNC
stdexec::task<std::string> qjs_debug_snapshot(std::string runtime_name);

/// 注册 Dart 回调为 JS bridge 路由（对齐 Rust register_function）。
/// JS 侧 bridge.call / bridge.callSync 均可触达（dyn 全局表，所有实例共享）。
/// handler 输入是 "[runtime, ...args]" JSON 文本；Dart 返回字符串，
/// 空串 → JS null，非空 → JS 字符串（对齐 Rust 的返回约定）。
/// 与内建静态路由同名时 Dart 注册优先（如 save_plugin_config 持久化版
/// 覆盖内存 stub）。BRIDGE_PERSIST：Dart 闭包持久保留，允许反复调用。
/// → Dart: bool qjsRegisterFunction(String functionName, Future<String> Function(String) callback)
BRIDGE_SYNC
BRIDGE_PERSIST
bool qjs_register_function(std::string function_name,
                           dcb::DartFn<std::string(std::string)> callback);

/// 注销已注册的 Dart 回调路由（不存在返回 false）。→ Dart: bool
BRIDGE_SYNC
bool qjs_unregister_function(std::string function_name);

/// 进程级 fetch 配置（仅对之后新建的 runtime 实例生效）。
/// 空串 = 清除/直连。设置 http 代理会强制关闭 TLS 校验（对齐 Rust 行为）。
/// socks5 与 http 代理互斥（socks5 优先）。
BRIDGE_SYNC
void qjs_set_http_proxy(std::string proxy);
BRIDGE_SYNC
void qjs_set_socks5_proxy(std::string proxy);
BRIDGE_SYNC
void qjs_set_tls_verify_enabled(bool enabled);
