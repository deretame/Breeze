// 插件 QJS 运行时桥接：qjs::HostRuntime 封装，替代原 Rust rquickjs 路径。
//
// 结构：
//   - 进程级 registry：runtime_name -> { HostRuntime, bundle_name }；
//   - 每次 qjs_task_call 投递到对应实例（HostRuntime 每实例一个 JS 线程），
//     co_await task_handle::wait() 取一次性结果；
//   - 返回协议对齐 HostRuntime：std::string 为 JSON 文本，"\x00buf:"+id 走
//     BlobStore 二进制旁路（wait() 内已取件），统一成 vector<uint8_t> 给 Dart；
//   - init/shutdown 是阻塞操作（就绪握手 / join 实例线程），丢到 dcb
//     blocking pool 执行，不堵 io 线程。
//
// 已知简化（docs/cpp_plugin_runtime_design.md 后续补全）：
//   - task_group_key 仅保留签名，组取消协议未实现；
//   - 代理/TLS 配置仅对新建实例生效（HostRuntime 无运行时改配消息）；
//   - Dart 回调无超时保护（Rust 版有 REGISTERED_DART_CALLBACK_TIMEOUT）；
//   - 无日志转发 / 错误 i18n。
#include <expected>
#include <fetch/types.hpp>
#include <glaze/glaze.hpp>
#include <log.hpp>
#include <mutex>
#include <qjsbind/dynamic_call.hpp>
#include <qjsbind/host_runtime.hpp>
#include <stdexcept>
#include <thread>
#include <tuple>
#include <utility>

#include "bridge_api.h"
#include "dart_cpp_bridge/runtime.hpp"

namespace {

// ---- registry ----

struct WindQjsEntry {
  std::shared_ptr<qjs::HostRuntime> host;
  std::string bundle_name;  // "" = 无常驻 bundle
};

std::mutex g_mu;
std::unordered_map<std::string, WindQjsEntry> g_runtimes;

// ---- 进程级 fetch 配置（独立 mutex，避免与 registry 锁嵌套）----

std::mutex g_cfg_mu;
std::string g_http_proxy;
std::string g_socks5_proxy;
bool g_tls_verify = true;

fetch::Options make_fetch_options() {
  fetch::Options opt;
  std::string proxy;
  {
    std::lock_guard lock(g_cfg_mu);
    opt.tls.verify = g_tls_verify;
    if (!g_socks5_proxy.empty()) {
      proxy = g_socks5_proxy;
    } else if (!g_http_proxy.empty()) {
      proxy = g_http_proxy;
      opt.tls.verify = false;  // 对齐 Rust：设置 http 代理强制关 TLS 校验
    }
  }
  if (!proxy.empty()) {
    if (auto p = fetch::Proxy::parse(proxy)) opt.proxy = *p;
  }
  return opt;
}

// ---- 宿主侧存储（cache / pluginConfig stub）----
// 按 JSRuntime* 隔离（每个 HostRuntime 实例一个 JSRuntime）。
// config 是内存 stub——持久化要等 Dart 回调通路（register_function）后接
// ObjectBox，见 docs/cpp_plugin_runtime_design.md 后续补全清单。

std::mutex g_store_mu;
std::unordered_map<JSRuntime*, std::unordered_map<std::string, std::string>>
    g_cache_store;
std::unordered_map<JSRuntime*, std::unordered_map<std::string, std::string>>
    g_config_store;

// __wind_cache_op(op, key, a, b) -> string
//   get:    a 忽略；返回已存 JSON 文本，无则 ""
//   set:    a = JSON 文本；返回 ""
//   set_if_absent / compare_and_set: a = 新值 JSON，b = compare_and_set 的期望
//   值 JSON；返回 "true"/"false" delete:  返回 "true"/"false"
std::string wind_cache_op(qjs::Ctx cx, const std::string& op,
                          const std::string& key, const std::string& a,
                          const std::string& b) {
  std::lock_guard lock(g_store_mu);
  auto& m = g_cache_store[JS_GetRuntime(cx.ctx)];
  if (op == "get") {
    auto it = m.find(key);
    return it == m.end() ? std::string() : it->second;
  }
  if (op == "set") {
    m[key] = a;
    return {};
  }
  if (op == "set_if_absent") return m.emplace(key, a).second ? "true" : "false";
  if (op == "compare_and_set") {
    auto it = m.find(key);
    const std::string cur = it == m.end() ? std::string() : it->second;
    if (cur != b) return "false";
    m[key] = a;
    return "true";
  }
  if (op == "delete") return m.erase(key) > 0 ? "true" : "false";
  throw std::runtime_error("unknown cache op: " + op);
}

// __wind_config_op(op, key, value) -> string（内存 stub，TODO 接 Dart）
std::string wind_config_op(qjs::Ctx cx, const std::string& op,
                           const std::string& key, const std::string& value) {
  std::lock_guard lock(g_store_mu);
  auto& m = g_config_store[JS_GetRuntime(cx.ctx)];
  if (op == "save") {
    m[key] = value;
    return {};
  }
  if (op == "load") {
    auto it = m.find(key);
    return it == m.end() ? std::string() : it->second;
  }
  throw std::runtime_error("unknown config op: " + op);
}

// ---- 每实例宿主 API 安装（console + bridge 路由）----

void install_wind_apis(qjs::Context& ctx) {
  // dyn 动态调用（call/callSync 全局 + host 表）：Dart 回调路由的载体，
  // 幂等（重复 install 仅覆盖全局函数）。
  qjs::dyn::install_dynamic_call(ctx);

  auto global = ctx.globals();
  global.set("__wind_log", [](qjs::Ctx cx, qjs::Value lv, qjs::Value msg) {
    qjs::Context c(cx.ctx);
    const std::string level = c.from_js<std::string>(lv.raw());
    const std::string text = c.from_js<std::string>(msg.raw());
    if (level == "error")
      QLOG_ERROR("[qjs] {}", text);
    else if (level == "warn")
      QLOG_WARNING("[qjs] {}", text);
    else if (level == "debug")
      QLOG_DEBUG("[qjs] {}", text);
    else
      QLOG_INFO("[qjs] {}", text);
  });
  global.set("__wind_cache_op", wind_cache_op);
  global.set("__wind_config_op", wind_config_op);
  // bridge.call/callSync 优先查 dyn 表（Dart 回调注册），未注册才落静态路由。
  global.set("__wind_dyn_has", [](qjs::Ctx cx, const std::string& name) {
    const auto& reg = qjs::dyn::Registry::instance();
    const auto& id = qjs::runtime_of(cx.ctx).id();
    return reg.find_async(id, name).has_value() ||
           reg.find_sync(id, name).has_value();
  });
  // console / bridge 路由 polyfill。bridge 路由同步实现（cache/config/opencc
  // 都是本地操作），call 包一层 Promise 对齐 kit 的异步约定。
  // opencc.convert / runtime.gc 复用 runtime_api polyfill 已装的同名全局。
  (void)ctx.eval(R"JS(
globalThis.console = (() => {
  const fmt = (a) => a.map((x) => {
    if (typeof x === 'string') return x;
    try { return JSON.stringify(x); } catch { return String(x); }
  }).join(' ');
  const mk = (lv) => (...a) => {
    try { globalThis.__wind_log(lv, fmt(a)); } catch {}
  };
  return {
    log: mk('log'), info: mk('info'), warn: mk('warn'),
    error: mk('error'), debug: mk('debug'),
  };
})();

globalThis.bridge = (() => {
  const parseOr = (s, fb) => {
    if (s === '') return fb;
    try { return JSON.parse(s); } catch { return fb; }
  };
  const routes = {
    'cache.get': (key, fb) => parseOr(__wind_cache_op('get', String(key), '', ''), fb),
    'cache.get.sync': (key, fb) => parseOr(__wind_cache_op('get', String(key), '', ''), fb),
    'cache.set': (key, v) => { __wind_cache_op('set', String(key), JSON.stringify(v ?? null), ''); },
    'cache.set.sync': (key, v) => { __wind_cache_op('set', String(key), JSON.stringify(v ?? null), ''); },
    'cache.set_if_absent': (key, v) =>
      __wind_cache_op('set_if_absent', String(key), JSON.stringify(v ?? null), '') === 'true',
    'cache.compare_and_set': (key, expected, next) =>
      __wind_cache_op('compare_and_set', String(key),
        JSON.stringify(next ?? null), JSON.stringify(expected ?? null)) === 'true',
    'cache.delete': (key) => __wind_cache_op('delete', String(key), '', '') === 'true',
    'opencc.convert': (p) =>
      globalThis.opencc.convert(String(p?.text ?? ''), String(p?.config ?? 't2s.json')),
    'runtime.gc': () => { try { globalThis.runtime.gc(); } catch {} },
    // TODO: 任务组取消协议（本期恒 false）
    'runtime.is_task_group_cancelled': (key) => false,
    // 以下为内存 stub 兜底：Dart 侧经 qjsRegisterFunction 注册同名路由后
    // 优先走 Dart（__wind_dyn_has 判定，见 bridge.call/callSync）。
    'save_plugin_config': (key, value) => {
      __wind_config_op('save', String(key), String(value ?? ''));
    },
    'load_plugin_config': (key, fb) => {
      const r = __wind_config_op('load', String(key), '');
      return r === '' ? (fb ?? '') : r;
    },
    'flutter.showToast': (msg) => {
      try { globalThis.__wind_log('info', '[toast] ' + String(msg)); } catch {}
    },
    'dart.getAppVersion': () => '0.0.0-cpp',
    'dart.getLocaleInfo': () => ({}),
    // deprecated crypto 路由（kit 兼容层）：委托 crypto 全局
    //（字符串入参，hex/b64 字符串 Promise 出参与 Rust 版一致）
    'crypto.md5_hex': (input) => globalThis.crypto.md5(String(input ?? '')),
    'crypto.sha1_hex': (input) => globalThis.crypto.sha1(String(input ?? '')),
    'crypto.sha256_hex': (input) => globalThis.crypto.sha256(String(input ?? '')),
    'crypto.sha512_hex': (input) => globalThis.crypto.sha512(String(input ?? '')),
    'crypto.hmac_sha1_hex': (key, input) =>
      globalThis.crypto.hmacSha1(String(key ?? ''), String(input ?? '')),
    'crypto.hmac_sha256_hex': (key, input) =>
      globalThis.crypto.hmacSha256(String(key ?? ''), String(input ?? '')),
    'crypto.hmac_sha512_hex': (key, input) =>
      globalThis.crypto.hmacSha512(String(key ?? ''), String(input ?? '')),
    'crypto.aes_ecb_pkcs7_decrypt_b64': (payloadB64, keyRaw) =>
      globalThis.crypto.aesEcbPkcs7Decrypt(
        globalThis.bytesFromBase64(String(payloadB64 ?? '')), String(keyRaw ?? ''))
        .then((bytes) => new TextDecoder().decode(bytes)),
    'crypto.aes_cbc_pkcs7_encrypt_b64': (plainB64, keyRaw, ivRaw) =>
      globalThis.crypto.aesCbcPkcs7EncryptB64(
        String(plainB64 ?? ''), String(keyRaw ?? ''), String(ivRaw ?? '')),
    'crypto.aes_cbc_pkcs7_decrypt_b64': (payloadB64, keyRaw, ivRaw) =>
      globalThis.crypto.aesCbcPkcs7DecryptB64(
        String(payloadB64 ?? ''), String(keyRaw ?? ''), String(ivRaw ?? '')),
    'crypto.aes_gcm_encrypt_b64': (payloadB64, keyRaw, nonceRaw, aadB64) =>
      globalThis.crypto.aesGcmEncryptB64(
        String(payloadB64 ?? ''), String(keyRaw ?? ''), String(nonceRaw ?? ''),
        aadB64 == null ? null : String(aadB64)),
    'crypto.aes_gcm_decrypt_b64': (payloadB64, keyRaw, nonceRaw, aadB64) =>
      globalThis.crypto.aesGcmDecryptB64(
        String(payloadB64 ?? ''), String(keyRaw ?? ''), String(nonceRaw ?? ''),
        aadB64 == null ? null : String(aadB64)),
  };
  return {
    call: (name, ...args) => {
      // Dart 回调路由（dyn 表）优先；未注册落静态路由
      if (__wind_dyn_has(name)) return globalThis.call(name, ...args);
      const r = routes[name];
      if (!r) return Promise.reject(new Error('bridge route not found: ' + name));
      try { return Promise.resolve(r(...args)); } catch (e) { return Promise.reject(e); }
    },
    callSync: (name, ...args) => {
      if (__wind_dyn_has(name)) return globalThis.callSync(name, ...args);
      const r = routes[name];
      if (!r) throw new Error('bridge route not found: ' + name);
      return r(...args);
    },
    gzipCompress: (b) => globalThis.gzipCompress(b),
    gzipDecompress: (b) => globalThis.gzipDecompress(b),
  };
})();
)JS",
                 "<wind-apis>");
}

std::shared_ptr<qjs::HostRuntime> find_host(const std::string& name) {
  std::lock_guard lock(g_mu);
  auto it = g_runtimes.find(name);
  return it == g_runtimes.end() ? nullptr : it->second.host;
}

std::string json_quote(const std::string& s) {
  return glz::write_json(s).value_or("\"\"");
}

}  // namespace

stdexec::task<void> qjs_build_runtime(std::string runtime_name,
                                      std::string bundle_name,
                                      std::string bundle_js) {
  if (find_host(runtime_name)) co_return;

  const std::string source = bundle_js.empty()
                                 ? std::string("module.exports = {};")
                                 : std::move(bundle_js);
  // init 会阻塞等待实例线程就绪握手（含 bundle 编译验证），丢到 blocking pool
  auto init_res = co_await dcb::spawn_blocking(
      [runtime_name, source]() mutable
          -> std::expected<std::shared_ptr<qjs::HostRuntime>, std::string> {
        qjs::HostRuntime::Options opt;
        opt.enable_fetch = true;
        opt.include_stack = true;
        opt.fetch_opts = make_fetch_options();
        opt.register_all = [](qjs::Context& c) { install_wind_apis(c); };
        auto host = std::make_shared<qjs::HostRuntime>(std::move(opt));
        auto r = host->init(runtime_name, std::move(source));
        if (!r) return std::unexpected(std::move(r.error().message));
        return host;
      });
  if (!init_res) throw std::runtime_error(std::move(init_res.error()));

  std::lock_guard lock(g_mu);
  auto [it, inserted] = g_runtimes.try_emplace(runtime_name);
  if (inserted) {
    it->second.host = std::move(*init_res);
    it->second.bundle_name = std::move(bundle_name);
  }
  // 未插入 = 并发重复 build：后建的 host 在此析构（shutdown），先到者生效
}

stdexec::task<bool> qjs_is_initialized(std::string runtime_name) {
  co_return find_host(runtime_name) != nullptr;
}

stdexec::task<bool> qjs_drop_runtime(std::string runtime_name) {
  std::shared_ptr<qjs::HostRuntime> host;
  {
    std::lock_guard lock(g_mu);
    auto it = g_runtimes.find(runtime_name);
    if (it == g_runtimes.end()) co_return false;
    host = std::move(it->second.host);
    g_runtimes.erase(it);
  }
  // 排干 + join 实例线程是阻塞操作（回收有界），丢到 blocking pool
  co_await dcb::spawn_blocking(
      [h = std::move(host)]() mutable { h->shutdown(); });
  co_return true;
}

stdexec::task<void> qjs_replace_bundle(std::string runtime_name,
                                       std::string bundle_name,
                                       std::string bundle_js) {
  auto host = find_host(runtime_name);
  if (!host)
    throw std::runtime_error("qjs runtime not initialized: " + runtime_name);
  auto receipt = host->reload(runtime_name, std::move(bundle_js));
  if (!receipt) throw std::runtime_error(receipt.error().message);
  auto r = co_await receipt->wait();
  if (!r) throw std::runtime_error(r.error().message);
  std::lock_guard lock(g_mu);
  if (auto it = g_runtimes.find(runtime_name); it != g_runtimes.end())
    it->second.bundle_name = std::move(bundle_name);
}

stdexec::task<bool> qjs_clear_bundle(std::string runtime_name) {
  auto host = find_host(runtime_name);
  if (!host) co_return false;
  auto receipt = host->reload(runtime_name, "module.exports = {};");
  if (!receipt) throw std::runtime_error(receipt.error().message);
  auto r = co_await receipt->wait();
  if (!r) throw std::runtime_error(r.error().message);
  std::lock_guard lock(g_mu);
  if (auto it = g_runtimes.find(runtime_name); it != g_runtimes.end())
    it->second.bundle_name.clear();
  co_return true;
}

stdexec::task<std::string> qjs_current_bundle(std::string runtime_name) {
  std::lock_guard lock(g_mu);
  auto it = g_runtimes.find(runtime_name);
  if (it == g_runtimes.end() || it->second.bundle_name.empty())
    co_return "null";
  co_return json_quote(it->second.bundle_name);
}

stdexec::task<std::vector<std::uint8_t>> qjs_task_call(
    std::string runtime_name, std::string task_group_key, bool is_once,
    std::optional<std::string> bundle_js, std::string fn_path,
    std::string args_json) {
  (void)task_group_key;  // 组取消协议本期未实现（仅签名对齐 Rust）
  auto host = find_host(runtime_name);
  if (!host)
    throw std::runtime_error("qjs runtime not initialized: " + runtime_name);

  std::optional<std::string> bundle;
  if (is_once && bundle_js && !bundle_js->empty())
    bundle = std::move(*bundle_js);

  auto handle = host->call(runtime_name, std::move(fn_path),
                           std::move(args_json), std::move(bundle));
  if (!handle) throw std::runtime_error(handle.error().message);
  auto res = co_await handle->wait();
  if (!res) throw std::runtime_error(res.error().message);
  co_return std::vector<std::uint8_t>(res->begin(), res->end());
}

stdexec::task<std::string> qjs_debug_snapshot(std::string runtime_name) {
  auto host = find_host(runtime_name);
  if (!host)
    throw std::runtime_error("qjs runtime not initialized: " + runtime_name);
  const auto st = host->stats();
  co_return glz::write_json(st).value_or("{}");
}

void qjs_set_http_proxy(std::string proxy) {
  std::lock_guard lock(g_cfg_mu);
  g_http_proxy = std::move(proxy);
  if (!g_http_proxy.empty())
    g_tls_verify = false;  // 对齐 Rust：设置 http 代理强制关 TLS 校验
}

void qjs_set_socks5_proxy(std::string proxy) {
  std::lock_guard lock(g_cfg_mu);
  g_socks5_proxy = std::move(proxy);
}

void qjs_set_tls_verify_enabled(bool enabled) {
  std::lock_guard lock(g_cfg_mu);
  g_tls_verify = enabled;
}

// ---- Dart 回调（register_function）----
// 对齐 Rust：handler 输入 "[runtime, ...args]" JSON 文本；Dart 返回空串 →
// JS null，非空 → JS 字符串。sync/async 两张 dyn 全局表都注册：
// bridge.call 走 async（协程 co_await DartFn sender，JS 线程不阻塞），
// bridge.callSync 走 sync（JS 线程 dcb::sync_wait 阻塞等 Dart 回复——
// 回复经 dcb io 线程投递，无自死锁）。
// TODO: Rust 版有 REGISTERED_DART_CALLBACK_TIMEOUT 超时保护，本期未加。

namespace {

// "[a,b,c]" + runtime → "[\"rt\",a,b,c]"
// host_id 是 qjs::Runtime 的 id（"host:" + 实例名，见 host_runtime.hpp），
// 传给 Dart 前剥掉前缀，对齐 Rust 的 runtime 名语义。
std::string build_dart_fn_input(std::string_view runtime,
                                std::string_view args_json) {
  constexpr std::string_view kHostPrefix = "host:";
  if (runtime.starts_with(kHostPrefix))
    runtime.remove_prefix(kHostPrefix.size());
  std::string out = "[";
  out += json_quote(std::string(runtime));
  if (args_json.size() > 2) {  // 去掉 "[]" 的壳后非空
    out += ",";
    out += args_json.substr(1, args_json.size() - 2);
  }
  out += "]";
  return out;
}

// Dart 返回串 → dyn handler 的 JSON 输出（resolve_json / JS_ParseJSON 解析）
std::string dart_fn_output_json(const std::string& out) {
  return out.empty() ? std::string("null") : json_quote(out);
}

}  // namespace

bool qjs_register_function(std::string function_name,
                           dcb::DartFn<std::string(std::string)> callback) {
  if (!callback) return false;

  QLOG_INFO("[dartfn] register({}) tid={}", function_name,
            std::hash<std::thread::id>{}(std::this_thread::get_id()));
  qjs::dyn::register_global_async(
      function_name,
      [callback](std::string host_id, std::string /*name*/,
                 std::string json_args) -> std_exec::task<std::string> {
        QLOG_INFO("[dartfn] handler invoke tid={}",
                  std::hash<std::thread::id>{}(std::this_thread::get_id()));
        const std::string input = build_dart_fn_input(host_id, json_args);
        co_return dart_fn_output_json(co_await callback(input));
      });
  qjs::dyn::register_global(
      function_name,
      [callback](std::string_view host_id, std::string_view /*name*/,
                 std::string_view json_args) -> std::string {
        const std::string input = build_dart_fn_input(host_id, json_args);
        auto out = dcb::sync_wait(callback(input));
        if (!out)
          throw std::runtime_error("DartFn cancelled: sync_wait stopped");
        return dart_fn_output_json(std::get<0>(std::move(*out)));
      });
  return true;
}

bool qjs_unregister_function(std::string function_name) {
  const auto& reg = qjs::dyn::Registry::instance();
  // dyn 表是全局的：任一 host id 都能查到全局表项，用空 id 直查全局即可
  const bool existed = reg.find_async("", function_name).has_value() ||
                       reg.find_sync("", function_name).has_value();
  qjs::dyn::unregister_global(function_name);
  return existed;
}
