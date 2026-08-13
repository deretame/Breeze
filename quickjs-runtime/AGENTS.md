# AGENTS.md

面向 AI 编码代理的项目说明。读者假定对本项目一无所知。

## 项目概览

`quickjs-runtime` 是一个 **Windows-only 的 C++23 项目**：内嵌 **quickjs-ng** JavaScript 引擎，
基于 **boost::asio** + **stdexec**（P2300 执行模型）构建异步运行时，并为 JS 侧提供
Web 风格 API（fetch、Headers、URL、Stream、Blob、定时器等）。

主要构成：

- **quickjs-ng** — 内嵌 JS 引擎（vcpkg 依赖）
- **boost-asio / boost-beast** — 异步 I/O 与 HTTP 传输
- **stdexec** — C++26 执行模型（P2300）参考实现，协程任务 (`stdexec::task`) 的基础
- **boringssl / zlib / brotli** — TLS 与内容解压
- **fmt / spdlog / gtest / glaze / ada-url / lexbor / utfcpp / mpmcqueue** — 其余支撑库

## 目录结构与模块划分

```
├── CMakeLists.txt            # CMake 工程（C++23）
├── （pixi.toml 已上移到仓库根目录，脚本在 ../script/pixi/，任务在仓库根目录 pixi run）
├── vcpkg.json                # vcpkg 依赖清单（overrides 钉死全部 75 个依赖版本）
├── vcpkg-configuration.json  # overlay-ports 指向 overlays/
├── overlays/stdexec/         # stdexec overlay port（固定 GitHub commit + Windows/vcpkg 修复）
├── include/
│   ├── log.hpp               # 通用日志模块（qlog：spdlog 单例封装，见下文）
│   ├── fetch/                # fetchcore：纯 C++ fetch 核心（client/types/middleware/…，无 quickjs 依赖）
│   │   └── easy/             # 易用层
│   └── qjsbind/              # QuickJS-NG 的 C++ 自动绑定层（header-only）
│       ├── host_runtime.hpp  # 命名 bundle 实例管理（init/call/reload/cancel/stop，
│       │                     #   见 docs/runtime_management_design.md）
│       ├── web/              # JS 侧 Web API 绑定（fetch/headers/url/stream/blob/timers/…）
│       ├── polyfill/         # JS polyfill 源（.js，在仓库内）+ 安装入口（.hpp）；
│       │                     #   *_embedded.hpp 由 embed_js.py 在 configure 期生成，不入库
│       └── cheerio/          # 基于 lexbor 的 HTML 解析绑定（BreezeHtml）
├── src/
│   ├── main.cpp              # 主程序 demo
│   └── fetch/                # fetchcore 传输实现（beast_transport/socks5/http_proxy/
│                             #   connection_pool/dns_resolver/doh_resolver/process_proxy，
│                             #   静态库 fetchcore；cacert_embedded.hpp 由脚本生成，不入库）
├── tests/                    # gtest 测试（单一可执行文件 quickjs_runtime_tests）
│   ├── certs/                # 本地 TLS 测试证书
│   ├── proxy/                # 3proxy 配置（3proxy 二进制在 third_party/3proxy，不入库）
│   └── wpt_runner.cpp        # WPT（web-platform-tests）精选子集运行器
├── （原 scripts/ 已迁移到 ../script/pixi/，由根目录 pixi run 调用，不要直接依赖系统 python）
├── js/                       # JS 资产打包工程（pnpm 管理）：npm 库经 esbuild 打成单文件
│                             #   到 include/qjsbind/polyfill/（如 source_map_lib.js），
│                             #   重建用 pixi run build-js-assets（需本机 node + pnpm）
├── docs/                     # 设计文档（fetch 设计、执行器模型用法、各子系统设计等）
└── third_party/              # vcpkg / wpt / 3proxy / cheerio / boringssl 源码克隆（均不入库）
```

关键架构边界（修改代码时必须遵守）：

- **fetchcore 与 JS 层解耦**：`include/fetch/` + `src/fetch/` 是纯 C++ 库，
  不得 include 或链接任何 quickjs/qjsbind 头文件（见 `docs/fetch_cpp_decoupling.md`）。
- **cheerio（lexbor）不属于网络层**，只被测试目标链接。
- **dart_cpp_bridge 已外置**：仓库内不再 vendored `include/dart_cpp_bridge/`，
  改为依赖 dart_cpp_bridge 包（pub git 依赖）的 `dart_cpp_bridge::runtime`，
  由 `../native/cmake/dcb_bridge.cmake` 引入（含 `if(NOT TARGET dcb_runtime)` 重复包含保护）。
- CMake target：`fetchcore`（STATIC）、
  `qjsbind`（INTERFACE）、`quickjs_runtime`（可执行）、`quickjs_runtime_tests`（测试）。
- 主程序与测试由 `QJS_RUNTIME_BUILD_TOOLS` 控制：独立构建（`cmake -S quickjs-runtime`）
  默认 ON；被 Breeze `native/CMakeLists.txt` 以 `add_subdirectory` 引入时默认 OFF，
  只暴露 `fetchcore` / `qjsbind` 库目标（hook 构建不会出现 tests 目标）。

## 构建与测试命令

所有任务通过 **pixi** 驱动（python 3.13.14 / cmake / ninja 由 pixi 环境提供；pixi.toml 在仓库根目录，以下命令均在根目录执行）：

```bash
pixi install                                  # 安装 pixi 环境
pixi run setup-vcpkg                          # 克隆并 bootstrap vcpkg 到 third_party/vcpkg
pixi run setup-wpt                            # sparse clone WPT 测试资产到 third_party/wpt
pixi run configure                            # 配置 CMake（默认 Debug + clang-cl）
pixi run build                                # 构建到 build/
pixi run test                                 # 跑全部测试（自动串联 setup-vcpkg → configure → build → test）
```

- `pixi run test` 一条命令即可完成全链路；任务间有 `depends-on` 串联。
- 等价入口：`make build` / `make test`（需在 pixi 环境中）。
- 测试分组与筛选（直接调脚本，不经 pixi task）：
  ```bash
  pixi run python script/pixi/test.py --list              # 列出全部分组与套件
  pixi run python script/pixi/test.py --group core fetch  # 只跑指定分组（可多个）
  pixi run python script/pixi/test.py --filter 'Stream.*' # 直接按 gtest filter 跑
  pixi run python script/pixi/test.py --group proxy --with-3proxy  # 脚本拉起 3proxy 跑对打
  pixi run python script/pixi/test.py --doh-e2e           # 放开 DoH 真实外网 E2E 用例
  ```
- 外部服务（目前只有 3proxy）由 `script/pixi/test.py` 统一拉起/回收，C++ 测试只认
  环境变量标记（`QJS_3PROXY_UP=1` / `DOH_E2E=1`），未设置时自动 GTEST_SKIP；
  新增外部服务依赖时同样在脚本侧管理生命周期，勿在 C++ 测试里拉进程。
- 切换配置/编译器（直接调脚本，不经 pixi task）：
  ```bash
  pixi run python script/pixi/configure.py --build-type Release
  pixi run python script/pixi/configure.py --compiler msvc   # 默认编译器是 clang-cl
  pixi run build
  ```

## 工具链与版本固定（重要约定）

- **平台**：仅 Windows（win-64），目标 Windows 10（CMake 统一定义 `_WIN32_WINNT=0x0A00`）。
- **编译器**：默认 **clang-cl**（LLVM 装在 `C:\Program Files\LLVM`），备选 MSVC cl.exe；
  `script/pixi/vs_env.py` 通过 vswhere + vcvars64 自动定位 MSVC 环境。
  ⚠️ 已知问题：MSVC cl（14.51）编译的 `quickjs_runtime_tests.exe` 在静态初始化
  注册 gtest 用例时段错误（clang-cl 正常）；测试请以 clang-cl 路径为准，cl 仅用于
  Breeze hook 构建库目标（不构建 tests）。
- **vcpkg**：由 `script/pixi/bootstrap_vcpkg.py` 克隆 master 到 `third_party/vcpkg`（不入库）。
  `vcpkg.json` 的 `overrides` 把所有直接+传递依赖的版本与 port-version 精确钉死；
  **升级依赖 = 显式修改 overrides 条目**，不要依赖 vcpkg 版本漂移。
  注意：`libpng` / `libwebp`（及 `zlib`）是给 Breeze `native/`（图片解码）用的，
  quickjs-runtime 自身不链接它们；native 侧以 `x64-windows-static-md` triplet 静态链接
  （见仓库根 `AGENTS.md` 的 native hook 小节）。
- **overlay-ports**：`overlays/stdexec` 固定 NVIDIA/stdexec 的 GitHub commit，
  含针对 Windows/vcpkg 的本地修复；升级时同步修改 port 内的 `REF`。
- **生成的文件**：`src/fetch/cacert_embedded.hpp`（由 `pixi run fetch-cacert` 下载
  Mozilla CA bundle 生成）与 `third_party/` 下各源码克隆均不入库，勿提交。
- **JS 嵌入**：polyfill/shim 等 JS 文件用 `script/pixi/embed_js.py` 转成 C++ 字符串头文件
  （每个 .js 生成一个 `inline constexpr std::string_view <文件名>_js`，raw string
  原样嵌入；`python script/pixi/embed_js.py <输出.hpp> <输入.js> [...] [--namespace NS]`），
  生成物同 cacert_embedded.hpp 模式处理（构建产物，不入库）。

## 代码风格约定

- 语言标准 **C++23**（`CMAKE_CXX_STANDARD 23`，关闭编译器扩展）。
- 注释与文档使用**中文**；提交到仓库的文本遵循项目现有中文风格。
- 项目级编译定义（所有 TU 必须一致，避免 ODR 违规）：
  `STDEXEC_TASK_SCHEDULE_OPSTATE_SIZE=256`（stdexec::task 的 inline 存储放大，原因见
  CMakeLists.txt 注释）。新增 target 时继承这些全局定义，勿私自改动。
- `fetchcore` 源文件以 MSVC 编译时加 `/utf-8`；`script/pixi/add_bom.py` 用于给 web 层
  头文件加 UTF-8 BOM 以兼容 MSVC GBK 区域设置——新增含非 ASCII 字符的头文件时注意这一点。
- 日志统一走 `include/log.hpp` 的 `qlog` 模块：
  - 打印用 **`QLOG_INFO(...)` 等大写宏**（自动携带 `std::source_location`；
    因 clang 模板推导分歧无法用小写函数+默认参数实现，详见文件头注释）。
  - `qlog::set_logger` / `qlog::set_level` 是**配置阶段**操作，无锁设计，
    禁止在打印进行中切换 logger（数据竞争 = UB）。
  - logger 以裸指针存储，生命周期由调用方保证。
- 异步设施：优先使用 `dart_cpp_bridge` 的 `co::stream` / `co::oneshot` / `co::mpsc` /
  `dcb::sleep`（基于 stdexec），用法见 `docs/cpp26_executor_model_usage.md`。
- 注册 native 函数给 JS：一律优先用 qjsbind 自动绑定（`include/qjsbind/function.hpp`
  的 `qjs::func` / `Object::set` 可调用重载，参数转换与异常边界全自动），
  不要手写 `JS_NewCFunction` / `JS_NewCClosure` 注册逻辑；
  仅特殊场景（如带 opaque 生命周期的 settle CClosure，见 task.hpp）才直接用 C API。
- 测试进程链接选项 `/STACK:16777216`（16MB 栈）：Debug 下 QuickJS `JS_CallInternal`
  栈帧约 21KB，默认 1MB 栈会在约 48 层 JS 递归时崩溃，勿移除该设置。

## 测试说明

- 框架：**GoogleTest**，全部测试编译进单个可执行文件 `quickjs_runtime_tests`。
- 运行：`pixi run test`（即 `script/pixi/test.py`，直接调 `build/quickjs_runtime_tests.exe`，
  不经 ctest）。测试分组（core / binding / fetch / proxy / cheerio / wpt）定义在
  `script/pixi/test.py` 的 `GROUPS` 字典里，按 gtest 套件名（`TEST()` 第一个参数）归类，
  支持 `--group` / `--filter` / `--list`，详见脚本 docstring。
- 新增测试文件时必须同时做两件事：加入 `CMakeLists.txt` 的
  `add_executable(quickjs_runtime_tests ...)` 列表，并把新套件名归入
  `script/pixi/test.py` 的对应分组。
- 测试类型包括：
  - 纯 C++ 单测（stream/channel/sleep/log/dynamic_call/blob_store 等）；
  - qjsbind 绑定测试（`m1`–`m4`_binding_test）；
  - fetch/fetchcore 直连与代理测试（socks5/http_proxy/3proxy 对打，
    测试内嵌代理服务器见 `tests/socks5_server.hpp`、`tests/http_proxy_server.hpp`，
    3proxy 方案见 `docs/proxy_test_plan.md`）；
  - TLS 测试使用 `tests/certs/` 下的本地证书；
  - **WPT 精选子集运行器** `tests/wpt_runner.cpp`（web-platform-tests 资产在
    `third_party/wpt/`，不入库，由 `pixi run setup-wpt` sparse clone；
    清单 `build/wpt_tests.txt` 由 `script/pixi/analyze_wpt.py` 生成——`script/pixi/test.py`
    跑 wpt 分组时资产缺失自动跳过、清单缺失自动补生成）。
- 网络类测试可能依赖本机回环与临时端口；`pool_test_tmp/` 是测试运行时残留目录，可忽略。

## 安全注意事项

- TLS CA 证书来自 Mozilla CA bundle（`script/pixi/bootstrap_cacert.py` 生成嵌入头文件），
  不要把 `tests/certs/` 的测试私钥用于任何真实用途。
- 依赖版本全部在 `vcpkg.json` overrides 钉死；引入新依赖前先确认 vcpkg 是否已收录，
  未收录的上游版本走 `overlays/` 的 overlay-port 模式并固定 commit。
- `third_party/` 下的源码克隆（vcpkg/wpt/3proxy/cheerio/boringssl）不入库、勿修改后提交。
- 代理相关代码（socks5/http_proxy/process_proxy）会读取系统代理与进程环境，
  改动时注意不要把本机凭据写入日志。

## 参考文档

设计细节记录在 `docs/`：`fetch_design.md`、`fetch_cpp_decoupling.md`、
`cpp26_executor_model_usage.md`、`exec_timer_sleep.md`、`dns_resolver_design.md`、
`blob_store_design.md`、`dynamic_call_design.md`、`known_issues.md` 等。
进行子系统级改动前先读对应设计文档；改动若使文档过时，同步更新对应文档。
