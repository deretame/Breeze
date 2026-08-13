# quickjs-runtime 与 rquickjs_playground 重量级功能对照

> 目的：对比本项目（C++ / quickjs-ng + asio + stdexec）与
> `D:\Project\flutter\Breeze\rquickjs_playground`（Rust / rquickjs + tokio）
> 在**重量级功能**上的差距。
>
> 不计入对照的范围：加解密、哈希、console 转发、URL/Headers 包装、
> TextEncoder/Decoder、structuredClone 等"注册一个原生函数 + JS 转发一层"
> 即可完成的轻量功能。只讨论必须 native 或 JS 侧大量投入的能力。

## 一、两个项目的定位差异

| | quickjs-runtime（本项目） | rquickjs_playground |
|---|---|---|
| 语言/引擎 | C++23 + quickjs-ng | Rust + rquickjs |
| 异步底座 | boost.asio + stdexec（P2300 协程） | tokio |
| 定位 | 嵌入式 JS 运行时库（Web API 按浏览器规范对齐，WPT 验证） | Breeze（Flutter 应用）的 JS 插件运行时实验场 |
| 模块系统 | ESM 原生 C 模块（`JS_NewCModule`），无文件 ESM 加载器 | CJS 风格 require + bundle 插件调度，无 ESM |
| 对外接口 | C++ 库 + dynamic_call JSON RPC | Rust API `AsyncHostRuntime`（无 Dart FFI） |

注意：rquickjs_playground 目前也**没有** Dart/Flutter 桥接代码，
两边的"与宿主通信"都停留在 native 进程内（本项目是 dynamic_call RPC 注册中心，
对方是 Rust API + bridge 动态路由）。

## 二、两边都有、且都做得很重的功能（对等项）

这些不算差距，但列出以便评估相对成熟度：

- **fetch 全栈**：两边都是最大投入。
  - 本项目：自研传输层（Beast + BoringSSL）、连接池、DNS/DoH、HTTP CONNECT/SOCKS5/外部进程代理、
    流式解压（gzip/deflate/br）、SRI 校验、中间件框架（`include/fetch/` + `src/fetch/`，约 5500 行）。
  - 对方：reqwest 客户端池 + 并发信号量 + 挂起请求池 + 取消 + body 状态机（`http.rs` 791 行 + `30_fetch.js` 1142 行）。
  - 网络纵深本项目更强（DoH、连接池、三种代理、SRI 都是对方没有的）；
    规范一致性验证对方有 `docs/WPT_FETCH_REPORT.md`，本项目也有 WPT runner（`tests/wpt_runner.cpp`），大体对等。
- **异步运行时 / 事件循环**：本项目 asio io_context 与 QuickJS job 泵融合 + stdexec 协程 + counting_scope；
  对方 tokio + 事件化 host 绑定（`__*_start` / `try_take` 轮询模型）。各自极重，对等。
- **定时器**：双方都是 native 定时器 + JS 调度层，中量级，对等。
- **AbortController / EventTarget / 流式 body**：对等。
- **HTML 解析（cheerio 风格）**：本项目 lexbor + 自研选择器匹配封装（约 2100 行）；
  对方 scraper/ego-tree（约 1000 行）。对等，本项目略深。
- **并发原语**：本项目 dart_cpp_bridge 的 channel/stream（约 2100 行，tokio 风格 oneshot/mpsc，
  完整 stdexec sender 化）——对方靠 tokio 生态直接获得，不算对方的成果，但本项目的这部分是基础设施而非 JS 可见功能。

## 三、本项目缺少、且属于重量级的功能（差距清单）

按补齐成本从高到低排序：

### 1. fs 文件系统 API（Node 风格，含流与 watch）— 差：重
- 对方：`fs_ops.rs`（621 行 native）+ `50_fs.js`（891 行 JS），近 30 个 API：
  `open/FileHandle`、`opendir/Dir`、`watch/FSWatcher`、`createReadStream/WriteStream`、Dirent/Stats，
  异步操作走任务池（start / try_take / promise / cancel）。
- 本项目：完全没有暴露给 JS 的 fs（文件访问只在 C++ 内部）。
- 补齐成本：native 侧异步文件任务池 + JS 侧 FileHandle/Dir/Stream 包装，
  是"native 和 JS 都要写很多"的典型。可复用本项目的 asio 调度器与 TaskPool。

### 2. Intl（ECMA-402）— 差：极重
- 对方：`intl.rs`（805 行）基于 jiff + ICU4X 实现 `Intl.DateTimeFormat`
  （formatToParts / resolvedOptions / hourCycle / 时区 canonicalize）。
- 本项目：无。quickjs-ng 自身不带完整 Intl。
- 补齐成本：需要引入 ICU4X（或 ICU4C）依赖并做格式化语义对齐，native 工作量极大。
  若目标场景不需要本地化格式化，可明确列为"不打算做"。

### 3. Temporal（Stage 4）— 差：极重（但基本是纯 JS 资产）
- 对方：内嵌 temporal-polyfill（`70_temporal.js`，4631 行）+ test262 套件
  （`tests/test262_temporal.rs` + expected-failures 清单）。
- 本项目：无。
- 补齐成本：polyfill 本身是现成开源资产，真正的工作量在**接入 + test262 验证**，
  属于"JS 侧要写/搬很多"的项。引擎层面 quickjs-ng 与 rquickjs 对新语法的支持差异需要先验证。

### 4. Bundle 插件系统 — 差：重
- 对方：`host_runtime.rs` 内嵌 `BUNDLE_DISPATCHER_JS`：
  `bundle_load / bundle_call(_bytes/_start/_once) / bundle_unload / bundle_list`，
  CJS 模块注册表、函数路径解析、错误栈增强（`__bundle_scope`）、`sourceURL` 注入。
  这是"JS 插件"运行模型的核心，配套 examples 有插件池压测。
- 本项目：只有单脚本运行 + TaskPool 多实例热重载，没有"插件包"概念
  （没有模块注册表、没有按路径调用插件导出函数、没有 bundle 生命周期管理）。
- 补齐成本：JS 侧 dispatcher 是主体（模块注册表 + 作用域 + 错误栈增强），
  native 侧需要 bundle 生命周期 API。若 Breeze 的插件模型是最终目标，这一项是最核心的差距。

### 5. source map 支持 — 差：中（已补齐，见 docs/runtime_management_design.md §7）
- 对方：`src/source_map.rs`（srcmap-sourcemap），错误栈自动映射回源码位置，
  配合 bundle 的 `sourceURL` 注入。
- 本项目：无。
- 补齐成本：C++ 侧没有现成的 srcmap 库那么顺手，需自实现 VLQ 解析或引入库；
  配合错误栈 hook 是中等工作量，但对插件调试体验影响很大。

### 6. Bridge 二进制通道与 native buffer 池 — 差：中（已补齐，见 docs/runtime_management_design.md §3）
- 对方：`native_buffer.rs`（325 行）跨 JS/host 的字节缓冲池
  （put/take/takeInto/free + GC TTL），bridge 调用二进制自动转 host buffer，
  还有 `execChain` 字节算子链（为图像处理插件准备）。
- 本项目：dynamic_call 只有 JSON RPC，参数/返回值走 JSON 序列化，
  大二进制数据会被 base64/JSON 开销拖垮，没有零拷贝二进制通道。
- 补齐成本：需要在 dynamic_call 之上加 buffer 句柄表 + ArrayBuffer 外部内存挂载，
  native 中等工作量。若插件涉及图片/字节处理，这项是刚需。

### 7. 错误消息 i18n — 差：轻-中（边界项）
- 对方：fluent-rs 的 zh-CN/en-US 错误消息（`i18n.rs`）。
- 本项目：无。
- 属于工程化锦上添花，工作量不大但繁琐，可视目标用户决定是否做。

### 8. 压测/示例资产 — 差：中（非功能，但反映成熟度）
- 对方：examples 有 axum 本地服务器 100 并发 fetch / 100 并发文件操作 / 插件池压测。
- 本项目：测试覆盖功能正确性（30 个测试文件 + WPT runner），但缺并发压测示例。

## 四、本项目有、对方没有的功能（领先项）

- **连接池 + DoH + 三种代理（CONNECT / SOCKS5 / 外部进程）+ SRI + 流式解压中间件**：
  网络栈纵深明显更强（对方代理只到 HTTP/SOCKS5 配置级）。
- **ReadableStream 自研状态机**（挂起 read 的协程帧 FIFO 结算）：对方的流主要在 fs/fetch body 内部，
  没有独立暴露的 ReadableStream Web API。
- **TaskPool 多实例 + JS 源码热重载**（编译验证后先建后拆）：对方只有运行时线程池，无热重载语义。
- **dart_cpp_bridge 的 channel/stream/sleep 并发原语库**（tokio 风格 sender 化 channel，1371 行）。
- **Blob / File + Blob 存储**（对方未见 Blob）。
- **ESM 原生模块注册**（对方只有 CJS require）。
- **WPT 更广覆盖**（自写 testharness 兼容层，对方 WPT 只覆盖 fetch）。

## 五、结论

真正需要"写很多"才能补的差距是五块，按建议优先级：

1. **Bundle 插件系统**——若目标是承接 Breeze 的插件模型，这是差距核心；
   本项目的 TaskPool 热重载已是很好的地基。
2. **fs 全套（含流与 watch）**——native 任务池 + JS 包装双重重活，插件几乎必然需要。
3. **bridge 二进制通道 / native buffer 池**——JSON RPC 之上的性能补丁，插件传图传字节绕不开。
4. **source map**——插件调试体验，中等成本。
5. **Intl / Temporal**——成本最高、与插件运行时主目标相关性最低，建议明确决策
   "做（搬 polyfill + 接 test262）还是不做"，而不是默默缺失。

网络栈（fetch/连接池/代理/DoH）本项目已领先，不需要对齐对方。
