# 插件运行时 C++ 迁移设计（最小可用版）

> 目标：把 Breeze 插件运行时的**最基础流程**从 Rust 迁移到 C++：初始化（build runtime）、发布任务并获取结果（qjs_task_call）、销毁（drop）、替换 bundle（replace/clear/current）、debug（once 热重载调用 + debug snapshot）。
>
> 明确**不做**（至少本期）：并发上限/信号量、SSRF 私网拦截、bridge 路由层（cache.\*/opencc.convert/runtime.\*）、Dart 回调（register_function/save_plugin_config 等）、日志 HTTP 转发、错误消息 i18n、任务组取消协议、内置 bundle asset 化。这些等基础流程跑通后再逐个补。
>
> 参考实现：`C:\Users\windy\Documents\project\Breeze`（Rust 侧优化精简版），以其 API 形态为基准，**不**照搬本仓库 `rust/src/qjs/mod.rs` 旧版 start/wait 两阶段 API。
>
> 状态：**最小可用版已实施**（2026-08-13）。`qjs_build_runtime` / `qjs_task_call`（常驻 + once 热重载）/ `qjs_drop_runtime` / `qjs_replace_bundle` / `qjs_clear_bundle` / `qjs_current_bundle` / `qjs_debug_snapshot` / 三个 fetch 配置 setter 已落地（`native/api/bridge_api.h` + `native/api_impl/wind_qjs.cpp`）；bridge 路由以**进程内 stub** 形式提供（cache.* 内存存储、opencc.convert 接 `__opencc_convert`、runtime.is_task_group_cancelled 恒 false、save/load_plugin_config 内存 stub、flutter.showToast/dart.* 占位）；Dart 侧经 `lib/network/http/plugin/qjs_backend.dart` 的 `useCppQjsRuntime` 开关切换（默认 true）。冒烟测试 `test/cpp_qjs_smoke_test.dart` 2/2 通过（example 插件全流程 + 异常传播）。

---

## 1. 背景

Breeze 的漫画内容由 JS 插件（CommonJS bundle，导出 `searchComic` / `getComicDetail` / `getChapter` / `fetchImageBytes` / `init` 等）提供。Dart 统一入口 `callUnifiedComicPlugin`（`lib/network/http/plugin/unified_comic_plugin.dart`）→ 执行器 `qjs_download_runtime.dart` → QuickJS 运行时。

`quickjs-runtime/` 已有成熟的 C++ QuickJS 封装（`qjs::HostRuntime`：命名 bundle 实例管理、`init/call/reload/cancel/stop` 消息、BlobStore 二进制通道、Web API polyfill + fetchcore 后端），语义与 Rust `AsyncHostRuntime` 对齐。本期工作 = 在它外面包一层 dcb 桥接，把 Dart 插件调用切过来。

约束：

- 不改动插件 JS 侧 API 契约（`fetch` / `console` / `Headers` 等保持可用——`HostRuntime` 的 `Options.enable_fetch` 已装配）。
- 不改动 Dart 侧 `callUnifiedComicPlugin` / `executeQjsCall` / `executeQjsFetchImageBytes` 的公开签名，只换内部实现。
- Rust 侧 QJS 代码保留不动（本期做完后 Dart 可灰度切换，全量切走后再删）。

---

## 2. 功能基准（Rust 精简版中本期涉及的部分）

| Rust 函数 | 语义 |
|---|---|
| `build_qjs_runtime(request{runtime_name, bundle?{bundle_name, bundle_js}})` | 建 runtime；带 bundle 则随即加载到 Primary context |
| `is_qjs_runtime_initialized(name)` | 查活 |
| `qjs_task_call(runtime_name, task_group_key, is_once, bundle_js?, bundle_url?, fn_path, args_json) -> Vec<u8>` | 唯一调用入口。常驻走 Primary context；`is_once=true` 走 once 池（按 bundle 源码哈希缓存，hash 相同不重 eval）。JS 返回 Uint8Array/ArrayBuffer → 真实字节；否则 `JSON.stringify` 的 UTF-8 字节 |
| `qjs_replace_bundle(runtime_name, bundle_name, bundle_js)` | 热替换常驻 bundle |
| `qjs_clear_bundle(runtime_name)` / `qjs_current_bundle(runtime_name)` | 清 / 查当前 bundle 名（JSON：`null` 或 `"name"`） |
| `qjs_drop_runtime(runtime_name)` | 销毁 runtime |
| `qjs_debug_snapshot(runtime_name)` | pretty JSON 状态快照（调试用） |
| `set_http_proxy` / `set_socks5_proxy` / `set_tls_verify_enabled` | 进程级 fetch 配置（保留最小三个，插件离开代理/TLS 设置就跑不动） |

关键语义（实现时必须对齐）：

- **返回值协议**：跨边界统一 `Vec<u8>`；二进制走 native buffer 旁路，一次性消费。
- **args 归一化**：`args_json` 非数组包装成单元素数组，`null` → `[]`；JS 侧 `fn.apply(owner, args)`。
- **错误协议**：JS 异常 → `{"ok":false,"error","stack"}`，宿主拼成带 `[bundle:… fn:… args:…]` scope 的错误文本抛给 Dart。Dart 的 `parseUnauthorizedPayload` 靠错误文本识别 401 类错误，**错误文案格式不能变**。
- **`init` 缺失不算错误**：匹配错误文本 `target is not function: init` 跳过。
- **exports 解包**：bundle exports 含 `.default` 优先取它。
- **fnPath 安全**：点路径解析，拒绝 `__proto__`/`prototype`/`constructor` 段。
- **取消**：本期只做 HostRuntime 自带的单任务 `cancel` 能力透传（逻辑取消，不中断 JS）；`task_group_key` 参数保留在签名里、内部仅记录不实现组取消。
- **无内存限制 / 无 interrupt**：与 Rust 版一致，不新增。

---

## 3. 桥接 API 设计（native/api/bridge_api.h 新增）

```cpp
// 生命周期（bundle_js 空串 = 建空 runtime；重复 build 幂等）
BRIDGE_ASYNC dcb::task<void> qjs_build_runtime(
    std::string runtime_name, std::string bundle_name, std::string bundle_js);
BRIDGE_ASYNC dcb::task<bool> qjs_is_initialized(std::string runtime_name);
BRIDGE_ASYNC dcb::task<bool> qjs_drop_runtime(std::string runtime_name);

// bundle 管理
BRIDGE_ASYNC dcb::task<void> qjs_replace_bundle(
    std::string runtime_name, std::string bundle_name, std::string bundle_js);
BRIDGE_ASYNC dcb::task<bool> qjs_clear_bundle(std::string runtime_name);
BRIDGE_ASYNC dcb::task<std::string> qjs_current_bundle(std::string runtime_name); // "null" | "\"name\""

// 调用（对应 Rust qjs_task_call；bundle_url 参数删除——.br 解压下沉到 Dart 侧 loadQjsBundleJs，已有该路径）
BRIDGE_ASYNC dcb::task<std::vector<std::uint8_t>> qjs_task_call(
    std::string runtime_name,
    std::string task_group_key,
    bool is_once,
    std::optional<std::string> bundle_js,
    std::string fn_path,
    std::string args_json);

// debug
BRIDGE_ASYNC dcb::task<std::string> qjs_debug_snapshot(std::string runtime_name);

// 进程级 fetch 配置（BRIDGE_SYNC，与 WindHttpConfig 并存、main.dart 同步设置）
BRIDGE_SYNC void qjs_set_http_proxy(std::string proxy);   // 空串清除；设置即强制关 TLS 校验（对齐 Rust 坑）
BRIDGE_SYNC void qjs_set_socks5_proxy(std::string proxy); // 与 http 代理互斥
BRIDGE_SYNC void qjs_set_tls_verify_enabled(bool enabled);
```

实现文件：`native/api_impl/wind_qjs.cpp`。

内部结构：

- `static` registry：`unordered_map<string, unique_ptr<qjs::HostRuntime>>` + mutex；双重检查创建；同名重复 build 直接返回（对齐 Rust 语义）。
- 每个实例 = HostRuntime 的一条 `init(name, source)`；`qjs_task_call` → `call(name, fn_path, args[, bundle])`，拿到 `std::string` 结果后：若是 `"\x00buf:"+id` 则从 BlobStore 取真实字节，否则返回 JSON 的 UTF-8 字节，统一成 `vector<uint8_t>`。
- 线程模型：BRIDGE_ASYNC 协程在 dcb io 线程入口；投递到 HostRuntime 后 co_await task_handle（若只有阻塞 wait，则挪到 worker 线程等待，别堵 io 线程）。JS 侧 fetch 的 fetchcore 线程亲和按 `wind_http.cpp` 的 `ensure_fetch_io` 模式处理。
- once 调用：`is_once=true` 且带 `bundle_js` 走 HostRuntime 的 once/携带 bundle 调用路径（HostRuntime 若无源码哈希缓存则按参考实现补：hash 相同跳过重新 eval）。
- 代理/TLS setter 写进程级配置，新实例创建时应用；已存活实例投递配置更新（HostRuntime 若无此消息，则先只对新建实例生效，标注 TODO）。

---

## 4. Dart 侧改造点

只动执行器内部，公开 API 不变：

- `lib/network/http/plugin/qjs_download_runtime.dart`：
  - `ensureQjsRuntimeReady`：`isQjsRuntimeInitialized` / `buildQjsRuntime` → 换 `native.qjsIsInitialized` / `qjsBuildRuntime`（bundle 来源不变：ObjectBox `originScript` / debugUrl）。
  - `executeQjsCall`：常驻 → `qjsTaskCall(is_once: false, ...)`；debug → `qjsTaskCall(is_once: true, bundle_js: ...)`。原来的 start/wait 两段合并成一次 await。`raceWithDownloadCancel` 保留（组取消未实现前，Dart 侧超时/放弃仍有效，只是 C++ 侧任务继续跑完被丢弃）。
  - `executeQjsFetchImageBytes`：同样走 `qjsTaskCall`，返回即 `Uint8List`。
  - `cancelTrackedQjsTasks`：本期退化为仅清理 Dart 侧追踪表（标注 TODO 接 C++ 组取消）。
- `lib/plugin/plugin_registry_service.dart`：runtime 预热/销毁调用换到 C++ 版。
- `lib/main.dart`：启动时对 C++ 侧同步设置 proxy/TLS（与 Rust 侧并存设置，灰度期间两份都设）。
- 切换开关：`GlobalSetting` 或 dart-define `use_cpp_qjs`，默认先关，灰度验证后默认开。

---

## 5. 验证方式

1. `pixi run test`：C++ 回归不红。
2. 新增 C++ 侧 HostRuntime 用例（若缺）：常驻 call / once call（hash 缓存命中）/ replace / clear / drop / snapshot / 二进制返回。
3. Dart 冒烟：参照 `test/cpp_fetch_smoke_test.dart` 模式起本地 `dart:io` HttpServer + 一个最小 JS 插件 fixture（导出 `init`/`searchComic`/`fetchImageBytes`），跑通 build → call（JSON 与二进制两种返回）→ replace → once 热重载 → snapshot → drop。
4. 手动：开 `use_cpp_qjs` 跑应用，内置插件（Bika/JM）完成搜索 → 详情 → 章节 → 出图。

已知会失败/降级的点（本期接受）：插件若调用 `save_plugin_config` 等 Dart 路由或 `cache.*` 宿主路由会报错（Bika/JM 的未登录搜索/阅读链路若踩到，再提前补对应路由）；任务组取消不生效（下载中取消只会丢弃结果）。

---

## 6. 后续补全清单（本期不做，按优先级）

1. ~~bridge 路由：`cache.*` / `opencc.convert` / `runtime.*`~~（已做，见 `install_wind_apis` polyfill）+ 白名单与大小限制。
2. ~~Dart 回调通路（`register_function` → dcb DartFn）~~（已做：`qjs_register_function`/`qjs_unregister_function`，dyn 全局表 + bridge.call/callSync 优先于内建 stub；尚缺 Rust 版的回调超时保护）。
3. 任务组取消协议（TTL 取消组 + `runtime.is_task_group_cancelled`）。
4. 日志 HTTP 转发、错误消息 i18n。
5. fetch 并发上限/超时/SSRF 对齐 Rust 参数。
6. 内置 bundle asset 化，删 Rust QJS（`rust/src/api/qjs.rs`、`rust/src/qjs/`、`rquickjs_playground`、`build.rs` 插件下载）。
