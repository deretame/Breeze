# Breeze 插件 API 差距分析与实现决策（v1）

> 状态：**决策已落地，实现进行中**（本文档同时作为决策追踪记录）。
> 对比对象：`D:\Project\web\Breeze-plugin\breeze-plugin-kit\src`（Breeze 插件开发工具包，
> 纯 TS 类型声明 + 工具函数层，不包含实现）。
> 对比基线：quickjs-runtime 当前 `include/qjsbind/` + `src/`（不含生成物与 third_party）。
> 相关文档：`docs/dynamic_call_design.md`（call/callSync 通道）、`docs/blob_store_design.md`
> （二进制暂存）、`docs/runtime_management_design.md`（bundle 实例管理）、`docs/fetch_cpp_decoupling.md`。

## 0. 背景与目的

`breeze-plugin-kit` 是 Breeze 插件运行时（Rust 宿主 + Dart 宿主）对插件作者暴露的
**类型声明层**：它声明的全部 API（`fs`/`bridge`/`native`/`crypto`/`base64`/`BreezeHtml`/
`Buffer`/`Intl`/`Temporal`/`cache`/`pluginConfig`/`opencc`/`runtime`/`flutterTools` 等）
均由**宿主在运行时注入 `globalThis`**，kit 本身只有声明与薄封装（`hostRuntime`、
`cache`/`pluginConfig`/`opencc`/`flutterTools` 等工具对象实际是 `bridge.call("...")`
的路由封装）。

`quickjs-runtime` 是独立的 **C++23 内嵌 quickjs-ng 运行时**，目标是提供同类（或超集）
的 JS 运行能力。本文档逐项对比 kit 声明的注入能力与 quickjs-runtime 已注册的全局能力，
记录 **已有 / 缺失 / 不实现** 三类决策与实现方案，作为后续实现工作的路线图。

> **对比口径说明**：kit 是"声明"，quickjs-runtime 是"实现"；两侧 API 名称与签名以
> kit 的 `.d.ts` 为准（Breeze 宿主已按此实现），quickjs-runtime 侧以实际注册的全局函数为准。

## 1. 对比范围与方法

### 1.1 kit 侧文件清单（对比来源）

```
src/
├── index.ts                  # 统一出口：runtime-api + tools + types
├── runtime-api.ts            # RuntimeFacade / hostRuntime / getApi / requireApi /
│                             #   requireCryptoLike（含 14 个 deprecated B64 变体）
├── runtime-api.typecheck.ts  # 类型自检（测试用）
├── tools.ts                  # cache / pluginConfig / runtime / opencc / flutterTools
└── types/
    ├── index.d.ts            # 统一出口
    ├── bridge.d.ts           # BridgeApi（call / callSync 命名路由）
    ├── runtime.d.ts          # RuntimeApiSet + 全局声明（__web / fs / path / native /
    │                         #   bridge / hostCrypto / nodeCryptoCompat / uuidv4）
    ├── fs.d.ts               # FsApi / FsStats / FsDirent / PathApi
    ├── crypto.d.ts           # CryptoApi（Node 风格子集）+ 输入/输出编码类型
    ├── base64.d.ts           # Base64Api + 全局 bytesToBase64 / bytesFromBase64
    ├── buffer.d.ts           # Buffer 类（Node 兼容子集）
    ├── native.d.ts           # NativeApi（二进制内存池 + 操作链）
    ├── breeze-html.d.ts      # BreezeHtml（cheerio 子集）+ Cheerio 兼容别名
    ├── intl.d.ts             # 时间向 Intl 子集（DateTimeFormat 等）
    ├── temporal.d.ts         # 完整 Temporal（Now/PlainDate/PlainTime/PlainDateTime/
    │                         #   ZonedDateTime/Instant/Duration/PlainYearMonth/PlainMonthDay）
    └── type.d.ts             # 插件业务模型类型（ComicListItem 等，非运行时能力）
```

### 1.2 quickjs-runtime 侧核对清单

- `include/qjsbind/web/web.hpp` — `install_web_apis()` 注册的 Web 标准 API（§3 前导）；
- `include/qjsbind/dynamic_call.hpp` — `call` / `callSync` 动态调用路由；
- `include/qjsbind/blob_store.hpp` — `native_put` / `native_get` 二进制暂存；
- `include/qjsbind/cheerio/cheerio.hpp` — `BreezeHtml.load`；
- `include/qjsbind/polyfill/bundle_dispatcher.hpp` — `__native_b64encode` /
  `__native_buf_put` / `__native_buf_take` 等内部全局；
- `include/qjsbind/context.hpp` — `make_uuid_v4()`（C++ 内部，未暴露给 JS）；
- `src/fetch/`（fetchcore）— `fetch::base64_encode` / `fetch::base64_decode`（内部）。

## 2. 结论总览

| # | 能力 | kit 声明位置 | quickjs-runtime 现状 | 决策 |
|---|------|--------------|----------------------|------|
| 1 | `BreezeHtml`（cheerio 子集） | breeze-html.d.ts | ✅ 已有（lexbor 实现） | 已对齐 |
| 2 | `bridge.call` / `callSync` | bridge.d.ts / runtime.d.ts | ✅ 已有（dynamic_call，JSON 进出） | 已对齐 |
| 3 | 二进制暂存 `native_put/get` | native.d.ts | 🔶 部分（BlobStore） | ✅ **polyfill 实现**（复用已有 + 新增 free） |
| 4 | base64 编码 | base64.d.ts | 🔶 部分（仅 `__native_b64encode`） | ✅ **polyfill 实现**（优先用已有 native） |
| 5 | `crypto`（Node 风格子集） | crypto.d.ts | ❌ 缺失 | ✅ **已实现**（BoringSSL EVP + stdexec 真异步，全签名对齐） |
| 6 | `Buffer`（Node 兼容类） | buffer.d.ts | ❌ 缺失 | ✅ **已实现**（npm `buffer` 包） |
| 7 | base64 解码 + `base64` 对象 | base64.d.ts | ❌ 缺失 | ✅ **已实现**（polyfill） |
| 8 | `uuidv4` 全局函数 | runtime.d.ts | ❌ 缺失（C++ 内部已有） | ✅ **已实现**（C++ `make_uuid_v4` 暴露） |
| 9 | `native` 内存池完整 API | native.d.ts | ❌ 缺失 | 🔶 **只实现 `free`**；exec/execChain/run/chain 是多余声明，不实现 |
| 10 | `gzipCompress` / `gzipDecompress` | bridge.d.ts / native.d.ts | ❌ 缺失 | ✅ **已实现**（C++ zlib 只收二进制 + JS polyfill 多格式收窄） |
| 11 | `Intl`（时间向子集） | intl.d.ts | ❌ 缺失 | 🚫 **暂不实现** |
| 12 | `Temporal` | temporal.d.ts | ❌ 缺失 | 🚫 **暂不实现** |
| 13 | `cache`（进程内 KV） | tools.ts | ❌ 缺失 | 🚫 **不实现**（用户：不是本项目的事） |
| 14 | `pluginConfig`（持久化配置） | tools.ts | ❌ 缺失 | 🚫 **不实现**（用户：不是本项目的事） |
| 15 | `opencc`（简繁转换） | tools.ts | ❌ 缺失 | ✅ **已实现**（C++ 自实现 + 官方数据嵌入，六种简繁 + 两种日文配置） |
| 16 | `runtime.gc` / `isTaskGroupCancelled` | tools.ts | ❌ 缺失 | ✅ **已实现**（gc polyfill + C++ JS_RunGC；isTaskGroupCancelled 对接现有 taskid） |
| 17 | `flutterTools`（Dart 宿主能力） | tools.ts | ❌ 缺失（无 Dart 宿主概念） | 🚫 **不实现**（用户：不是我要实现的东西） |
| 18 | `fs` / `FSError` / `path` | fs.d.ts | ❌ 缺失 | 🚫 **不实现**（用户拍板，见 §5.1） |

## 3. 已对齐（无需工作）

### 3.1 `BreezeHtml`（cheerio 子集）✅

- **kit 声明**：`BreezeHtml.load(html)` → 可调用 `$(selector)` / `$(selection)` →
  `BreezeSelection`（find/first/last/eq/closest/parent/children/siblings/next/prev/is/
  filter/has/slice/index/attr/text/html/val/toArray/each/map），另有
  `CheerioAPI` / `Cheerio` 兼容别名。
- **quickjs-runtime 现状**：`include/qjsbind/cheerio/`（lexbor 实现），
  `install_cheerio(ctx)` 注册全局 `BreezeHtml`，API 面与 kit 声明一一对应。
- **结论**：已对齐，无需工作。注意 Breeze 侧为 Rust 原生实现、本侧为 lexbor C 实现，
  行为差异不在本次范围内。

### 3.2 `bridge.call` / `bridge.callSync` ✅

- **kit 声明**：`BridgeApi.call(name, ...args): Promise<unknown>` /
  `callSync(name, ...args): unknown`，带若干命名路由重载
  （`math.add`、`native.put/take/exec`、`crypto.*`、`compression.gzip_*`）与兜底签名。
- **quickjs-runtime 现状**：`include/qjsbind/dynamic_call.hpp` 的 `install_dynamic_call(ctx)`
  注册全局 `call` / `callSync`，`qjs::dyn::register_global` / `register_global_async`
  即命名路由注册表（sync/async 两表独立，可同名双注册）；JSON 字符串进出。
- **差异点**：Breeze 的 bridge 支持二进制参数（`BinaryInput`，经宿主二进制通道）；
  quickjs-runtime 的 dynamic_call 是纯 JSON，二进制走 `dyn_blob`（`{"$blob": "<uuid>"}`）
  间接传递。**通道语义已对齐，二进制传输方式不同**。

### 3.3 二进制暂存（`native_put` / `native_get` → `native` 对象）✅

- **kit 声明**：`NativeApi.put(input): Promise<number>`（返回 id）、
  `take(id): Promise<Uint8Array>`（取出并释放）、`free(id): Promise<void>`。
- **quickjs-runtime 现状**：`include/qjsbind/blob_store.hpp` 的 `install_blob_store(ctx)`
  注册全局 `native_put(bytes) → id` / `native_get(id) → bytes|null`（同步、TTL 15 分钟
  滑动过期、按 host 分桶）。
- **实现方案（v1）**：JS polyfill（`runtime_api.js`）定义 `native` 对象：
  - `put(input)` → 复用已有 `native_put`（返回 string id）；
  - `take(id)` → `native_get` + `__native_buf_free`（消费语义，miss → null）；
  - `free(id)` → 新增 C++ 全局 `__native_buf_free`（`BlobStore::remove`，见 §8）。
  - `exec` / `execChain` / `run` / `chain` / `supportsBinaryBridge`：**不实现**
    （用户：多余但未删除的声明）。
- **已知差异**：id 为 string（kit 类型声明为 number）；put/take/free 为同步函数
  （kit 为 Promise）。kit 类型面以 Breeze 宿主为准，本侧运行时行为以本实现为准。

### 3.4 base64 ✅

- **kit 声明**：全局 `bytesToBase64(input): string` / `bytesFromBase64(text): Uint8Array`；
  `base64.encode(input): string` / `base64.decode(text): Uint8Array`。
- **quickjs-runtime 现状**：`bundle_dispatcher.hpp` 注册 `__native_b64encode`（BoringSSL
  EVP_EncodeBlock，经 `fetch::base64_encode`）；仅编码方向，名称内部化。
- **实现方案（v1）**：JS polyfill（`runtime_api.js`）：
  - `bytesToBase64` 优先调 `__native_b64encode`（已存在功能），缺失时 JS fallback；
  - `bytesFromBase64` 优先调新增 `__native_b64decode`（`fetch::base64_decode` 一行
    thunk），缺失时 JS fallback；
  - `base64` 对象 = `{ encode: bytesToBase64, decode: bytesFromBase64 }`。
  - 输入统一收窄为二进制（ArrayBuffer/TypedArray/DataView/number[]），非二进制抛
    TypeError（与 native 侧 `js_bytes` 语义一致）。

## 4. 缺失 — 决策与实现记录

### 4.1 `crypto`（Node 风格子集）✅ 已实现

- **kit 声明**（crypto.d.ts，`CryptoApi`）：`createHash/createHmac` 流式哈希、
  `md5/sha1/sha256/sha512`、`hmacSha1/256/512`、AES-ECB/CBC/GCM（ECB 无 B64，
  CBC/GCM 含 deprecated `*B64` 变体）、`randomBytes`、`randomUUID`、
  `timingSafeEqual`、`pbkdf2/pbkdf2Sync`（默认 **sha256**，kit 注释明示）。
- **实现方案（用户指示"直接注册 API 即可"，不管 Breeze 内部实现）**：
  - **C++ native 层**（`include/qjsbind/polyfill/crypto.hpp`，BoringSSL EVP）：
    11 个同步"字节进 → 字节出"函数（createHash/digest 用，Node 同步语义）
    + 9 个异步版（Promise 方法用）；
  - **异步 = 项目既有 stdexec 模式**（重做版，不再手写 Promise）：
    协程**自由函数**（KI-001：无捕获、值形参），`co_await fetch::pool_scheduler`
    （**复用 fetchcore 全局线程池 `fetch::file_pool()`**，不另起线程池）切后台
    线程计算，`co_await qjs::io_context_scheduler` 切回 JS 线程构造
    Uint8Array；function.hpp 检测 sender 返回类型自动经 `promise_from_sender`
    转 Promise（链尾 continues_on(js_sched) 强制结算回 JS 线程）；二进制全程
    直传（std::vector<std::byte> / Uint8Array），不转字符串；
  - **JS polyfill**（`include/qjsbind/polyfill/crypto.js`）：`crypto` /
    `hostCrypto` / `nodeCryptoCompat` 三个全局；流式 createHash/createHmac
    （digest 走同步 native）、hex/base64/latin1/utf8 编解码、Promise 包装
    （prom()：同步异常转 reject）、B64 变体、pbkdf2 callback（真异步）。
  - 输入约定：`TextInput` 的 string 分支按 **UTF-8** 取字节；AES key 字节长度
    16/24/32 → AES-128/192/256（其它抛）；CBC IV 长度必须恰为 16 字节（防
    EVP 越界读，security-review 修复）；ECB/CBC 启用 PKCS7 padding；
    GCM 输出 = **密文 || 16 字节 tag**（解密尾部拆 tag，认证失败抛）；
    `timingSafeEqual` 不等长返回 false（不抛）；
    pbkdf2 iterations 上限 1000 万、salt 上限 1MB（防滥用）。
- **安全注意（security-review 结论）**：CBC/ECB-PKCS7 为**无认证加密**——
  若用密钥解密攻击者可控密文，异常/成功差异构成 padding oracle，敏感场景
  应优先 GCM；`timingSafeEqual` 对字符串输入先做内容相关的 UTF-8 编码，
  机密比较建议传入等长字节缓冲。
- **依赖**：BoringSSL（已有，`openssl/evp.h` `hmac.h` `mem.h` `rand.h`）；
  线程池复用 fetch::file_pool（无新增）。
- **测试**：`CryptoFixture` 17 用例——标准向量互操作（sha256/md5/sha1/sha512、
  HMAC RFC 4231、PBKDF2 RFC 7914/6070、AES-128-CBC/GCM 用 node crypto 生成向量）、
  流式 update 与输入编码、digest 默认 Buffer、AES 往返与 PKCS7 padding、
  GCM tag 拼接与认证失败（篡改/aad 不匹配）、B64 变体、异步 API、
  randomBytes/randomUUID、timingSafeEqual、pbkdf2 callback（真异步）、
  **AsyncDoesNotBlockLoop**（300k 迭代调用后同步 JS 立即执行，验证不阻塞
  事件循环）、错误路径、三全局挂载。

### 4.2 `Buffer`（Node 兼容类）✅ 已实现

- **kit 声明**（buffer.d.ts）：`class Buffer extends Uint8Array`，构造 6 重载 +
  实例方法（write/toString/equals/compare/copy/slice/fill/indexOf/includes、
  read*/write* 全套、swap16/32/64）+ 静态（from/isBuffer/isEncoding/byteLength/
  concat/compare/alloc/allocUnsafe/allocUnsafeSlow）。即 Node Buffer 常用子集。
- **实现方案（v1）**：从 Node 生态取 `buffer`（feross/buffer，Node.js Buffer API 的
  官方 JS polyfill，npm `buffer@6.0.3`），经 js/ 资产工程 esbuild 打成 IIFE
  （`--global-name=__buffer_lib`）→ `include/qjsbind/polyfill/buffer_lib.js`（入库）→
  `embed_js.py` 嵌入 → `runtime_api.js` 挂载 `globalThis.Buffer = __buffer_lib.Buffer`。
- **Breeze 侧同思路**：`js/00_bootstrap.js` 也是 buffer polyfill 挂载。

### 4.3 `uuidv4` 全局函数 ✅ 已实现

- **kit 声明**：`uuidv4(): string` 全局函数（runtime.d.ts）。
- **实现方案（v1）**：C++ 注册全局 `uuidv4`，thunk 直接调 `make_uuid_v4()`
  （context.hpp:60-63，boost::uuids random_generator，已存在）。
- **依赖**：boost::uuids（已有）。

### 4.4 `Intl`（时间向子集）🚫 暂不实现

- **kit 声明**（intl.d.ts）：`Intl.DateTimeFormat`（format/formatToParts/
  resolvedOptions）、`supportedValuesOf("timeZone"|"calendar")`、
  `getCanonicalLocales`、`Date.prototype.toLocale*`。
- **Breeze 侧实现参考**：`js/07_intl.js` + 宿主 `src/web_runtime/intl.rs`
  （jiff 时区 + ICU4X locale 格式化）。
- **决策**：**暂不实现**。若后续要做，先调研 quickjs-ng 内置 Intl 编译选项，
  再定是否走 Breeze 同款（JS 胶水 + 宿主实现）路线。

### 4.5 `Temporal` 🚫 暂不实现

- **kit 声明**（temporal.d.ts，738 行）：完整 Temporal（Now/PlainDate/PlainTime/
  PlainDateTime/ZonedDateTime/Instant/Duration/PlainYearMonth/PlainMonthDay 等）。
- **Breeze 侧实现参考**：`js/70_temporal.js`（TC39 Temporal 官方 polyfill）。
- **决策**：**暂不实现**。若后续要做，推荐引入 `@js-temporal/polyfill` 经现有
  js/ 资产管线嵌入。

### 4.6 `cache`（进程内 KV）🚫 不实现

- **kit 声明**（tools.ts）：`cache.get/getSync/set/setSync/setIfAbsent/compareAndSet/
  delete`，全部走 `bridge.call("cache.*")`。
- **决策**：**不实现**（用户：不是本项目要做的事情）。

### 4.7 `pluginConfig`（持久化配置）🚫 不实现

- **kit 声明**（tools.ts）：`pluginConfig.save/load`；Breeze 侧为 Dart 宿主
  ObjectBox 持久化。
- **决策**：**不实现**（用户：不是本项目要做的事情）。

### 4.8 `opencc`（简繁转换）✅ 已实现

- **kit 声明**（tools.ts）：`opencc.convert(text, config)`，config ∈
  `s2t.json / t2s.json / s2tw.json / tw2s.json / s2hk.json / hk2s.json`。
- **Breeze 侧实现参考**：宿主 Rust（opencc crate）。
- **实现方案（v1，中途修正）**：~~opencc-js 资产~~ → **C++ 自实现**（用户指示：
  JS 版不好使，其他地方也要调用，改用 C++/C 实现）：
  - 数据：`scripts/bootstrap_opencc.py` 下载 **OpenCC 官方 ver.1.1.9 tag** 的
    词典 txt（主源 raw.githubusercontent + jsdelivr 备源），生成
    `include/opencc/opencc_data.hpp`（14 个常量：11 正向/自带反向 + 3 脚本生成
    的单字反向 Rev），构建产物不入库；
  - 实现：`include/opencc/opencc.hpp`（纯 C++，无 quickjs 依赖）——按官方
    ver.1.1.9 `data/config/*.json` 的转换链做**链式 MaxMatch**（每步一个合并
    词典：词组+单字 group 合并、多候选取第一个、最长匹配优先），八种配置：
      s2t = [ST]；t2s = [TS]；s2tw = [ST] → [TW]；
      tw2s = [TWRevPhrases+TWRev] → [TS]；s2hk = [ST] → [HK]；
      hk2s = [HKRevPhrases+HKRev] → [TS]；
      **jp2t = [JPShinjitaiPhrases+JPShinjitaiCharacters+JPVariantsRev]
      （日文新字体→旧字体）；t2jp = [JPVariants]（旧字体→日文新字体）**；
  - API：`opencc::convert(text, config)` / `opencc::is_valid_config(config)`，
    词典懒加载（每配置独立 static，仅被请求的配置触发解析）；
  - JS 侧：`runtime_api.hpp` 注册 `__opencc_convert`（C++ thunk），
    `runtime_api.js` 定义 `opencc = { convert }` 薄包装。
  - 与 vcpkg 官方 opencc 库的取舍：官方库运行时按相对路径
    （OPENCC_SYSTEM_CONFIG_PATH / cwd）加载配置与 .ocd2 词典，Windows 嵌入
    场景定位不可靠；本方案数据嵌入二进制、运行时无外部文件依赖。
- **供应链加固（security-review MEDIUM 修复）**：下载内容按 **SHA-256 白名单**
  （DICT_SHA256，对处理后文本计算）校验，主源/备源任何不一致即拦截；
  生成时检查 raw string 分隔符序列（`)opencc"`）防注入破坏头文件。
- **风险**：自实现 MaxMatch 与官方分词细节在极端用例可能有差异；数据固定
  ver.1.1.9 可复现（双源 + 哈希双保险）。

### 4.9 `runtime` 工具（gc / isTaskGroupCancelled）✅ 已实现

- **kit 声明**（tools.ts）：`runtime.gc(): Promise<void>`、`runtime.isTaskGroupCancelled(
  taskGroupKey): Promise<boolean>`（bridge route `runtime.gc` / `runtime.is_task_group_cancelled`）。
- **实现方案（v1）**：
  - `gc`：JS polyfill 定义 `runtime.gc = () => __native_gc()`；新增 C++ 全局
    `__native_gc`（`JS_RunGC(rt)` 一行）。
  - `isTaskGroupCancelled`：**使用现有 taskid**——polyfill 调 `__native_task_cancelled(id)`；
    新增 C++ 能力：`TaskRunner` 记录被取消的任务 id（cancel 时置位，settle 时入
    cancelled 集合），注册全局 `__native_task_cancelled(id) → bool` 查询。
  - 语义说明：本侧没有 Breeze 的"任务组"概念，`taskGroupKey` 参数即
    `TaskHandle.id`（`submit` 返回值）；查询"该 id 是否被 cancel() 过"。
    TaskPool 排队中取消（未达 runner）的任务查询返回 false（边缘语义，可接受）。

### 4.10 `gzipCompress` / `gzipDecompress` ✅ 已实现

- **kit 声明**：`bridge.gzipCompress/gzipDecompress(input): Promise<Uint8Array>`
  （bridge.d.ts）与 `native.gzipCompress/gzipDecompress`（native.d.ts）同签名。
- **实现方案（用户设计）**：
  - **C++ 只收二进制**：`include/gzip/gzip.hpp`（纯 C++，无 quickjs 依赖）——
    `gzip::compress/decompress(const std::byte*, size_t) → std::vector<std::byte>`，
    zlib 封装（`deflateInit2` 15+16 写 gzip header/trailer 含 CRC32；
    `inflateInit2` 15+32 自动探测 gzip/zlib；解压输出动态增长；错误 → 异常）；
  - **JS polyfill 负责多种格式输入**：`runtime_api.js` 的 `gzipCompress` /
    `gzipDecompress` 用 `toBytes` 把 ArrayBuffer/TypedArray/DataView/number[]
    统一收窄成 `Uint8Array` 再调 native（`__native_gzip_compress` /
    `__native_gzip_decompress`，js_bytes 只收二进制，非二进制 → TypeError）；
  - 全局函数 + `native` 对象双挂载（对齐 kit 两处声明）。
- **依赖**：zlib（已有，fetchcore 传递链接）。
- **测试**：`GzipTest`（纯 C++：往返/空输入/gzip 魔数 1f 8b/标准向量互操作——
  node `zlib.gzipSync` 产物硬编码解压验证/非法输入抛异常/压缩率）+
  `RuntimeApiFixture.Gzip*`（JS 侧：多格式输入往返、native 挂载、TypeError）。

### 4.11 `flutterTools`（Dart 宿主能力）🚫 不实现

- **kit 声明**（tools.ts）：`flutterTools.getAppVersion() / getLocaleInfo() /
  showToast(...)`，走 `bridge.call("dart.*" / "flutter.*")`。
- **决策**：**不实现**（用户：不是我要实现的东西）。

## 5. 不实现（已决策）🚫

### 5.1 `fs` / `FSError` / `path`

- **决策**：**完全不实现**（用户拍板）。
- **理由**：Breeze 侧该能力**从未真正注入过运行时**——kit 只是声明了类型
  （`FsApi`/`FsStats`/`FsDirent`/`PathApi`），实际宿主从未注册 `globalThis.fs` /
  `globalThis.path`（runtime.d.ts 中 `fs`/`path` 也标注了"可能不存在于纯 Node 测试
  环境"）；且没有实际使用方。
- **备注**：若未来需要，需重新设计（跨平台文件 I/O + 权限边界 + 路径语义），
  不在本次范围内。

## 6. 决策清单（已全部落地）

| # | 条目 | 决策 | 备注 |
|---|------|------|------|
| D1 | §4.1 crypto | ✅ 实现（BoringSSL EVP + stdexec 真异步） | 全签名对齐；GCM 密文||tag 约定 |
| D2 | §4.2 Buffer | ✅ 实现（npm buffer 包） | 与 Breeze 同思路 |
| D3 | §3.4 base64 | ✅ 实现（polyfill 优先 native） | 补解码 + base64 对象 |
| D4 | §4.3 uuidv4 | ✅ 实现（C++ 一行） | make_uuid_v4 暴露 |
| D5 | §3.3 native | ✅ 只实现 free | exec 系列不实现；put 返回 string id |
| D6 | §4.10 gzip | ✅ 实现（C++ zlib 二进制进出 + JS polyfill 收窄） | 全局函数 + native 双挂载 |
| D7 | §4.4 Intl | 🚫 暂不实现 | — |
| D8 | §4.5 Temporal | 🚫 暂不实现 | — |
| D9 | §4.6 cache | 🚫 不实现 | 非本项目 |
| D10 | §4.7 pluginConfig | 🚫 不实现 | 非本项目 |
| D11 | §4.8 opencc | ✅ 实现（C++ 自实现 + 官方数据嵌入） | 六种配置 |
| D12 | §4.9 runtime | ✅ 实现 | gc polyfill + taskid 取消查询 |
| D13 | §4.11 flutterTools | 🚫 不实现 | 非本项目 |

## 7. 参考锚点

- kit 侧：`D:\Project\web\Breeze-plugin\breeze-plugin-kit\src\{index,runtime-api,tools}.ts`、
  `src/types/*.d.ts`（§1.1 清单）。
- Breeze 宿主实现位置线索（来自 kit 注释）：`js/00_bootstrap.js`（__web 组装、
  cryptoModule、buffer polyfill、bytesToBase64/bytesFromBase64）、`js/99_exports.js`
  （globalThis 导出）、`js/07_intl.js` + `src/web_runtime/intl.rs`（Intl，jiff + ICU4X）、
  `js/70_temporal.js`（Temporal polyfill）。
- quickjs-runtime 侧：`include/qjsbind/web/web.hpp:31-45`（install_web_apis 清单）、
  `include/qjsbind/dynamic_call.hpp:85-93`（register_global / register_global_async）、
  `include/qjsbind/blob_store.hpp:86-103`（put/get/remove，TTL 15min）、
  `include/qjsbind/polyfill/bundle_dispatcher.hpp:167-188`（__native_b64encode /
  __native_buf_put / __native_buf_take）、`include/qjsbind/cheerio/cheerio.hpp:25-33`
  （install_cheerio / BreezeHtml.load）、`include/qjsbind/context.hpp:60-63`
  （make_uuid_v4）、`src/main.cpp:63-98`（dynamic_call 注册示例）。
- 依赖现状：BoringSSL（crypto/base64 可用）、zlib（gzip 可用）、boost::uuids
  （uuid 可用）、lexbor（BreezeHtml 已用）、无 ICU/ICU4X/jiff/opencc。

## 8. 本次实现记录（v1）

### 8.1 新增/修改文件

| 文件 | 内容 |
|------|------|
| `include/qjsbind/polyfill/runtime_api.js`（新，入库） | base64 / native / runtime / opencc 对象 + Buffer 挂载（优先 native，JS fallback） |
| `include/qjsbind/polyfill/runtime_api.hpp`（新，入库） | `install_runtime_api(ctx)`：注册 `__native_b64encode` / `__native_b64decode` / `__native_gc` / `uuidv4` / `__opencc_convert`，eval runtime_api.js + buffer_lib.js |
| `include/qjsbind/polyfill/runtime_api_embedded.hpp`（生成物，不入库） | embed_js.py 生成（runtime_api.js + buffer_lib.js 两输入） |
| `include/qjsbind/polyfill/buffer_lib.js`（生成，入库） | js/ 工程 esbuild 产物（npm buffer → IIFE `__buffer_lib`） |
| `js/package.json` / `js/src/buffer_entry.js`（新） | 资产工程 buffer 依赖与打包入口（opencc-js 依赖已移除） |
| `include/opencc/opencc.hpp`（新，入库） | 纯 C++ 简繁转换：链式 MaxMatch + 六配置 + 懒加载词典 |
| `include/opencc/opencc_data.hpp`（生成物，不入库） | bootstrap_opencc.py 下载 OpenCC ver.1.1.9 官方词典生成（10 个常量） |
| `scripts/bootstrap_opencc.py`（新，入库） | 下载（11 词典 + SHA-256 白名单校验 + raw string 转义检查）+ 反向词典生成（3 个 Rev，reverse_swap 复刻官方 reverse.py）+ 幂等 |
| `include/gzip/gzip.hpp`（新，入库） | 纯 C++ gzip 压缩/解压（zlib，只收二进制进出；解压输出上限 256MB 防 zip bomb） |
| `include/qjsbind/polyfill/runtime_api.hpp` | 增注册 `__native_gzip_compress` / `__native_gzip_decompress`（js_bytes 进、Uint8Array 出） |
| `include/qjsbind/polyfill/runtime_api.js` | 增 `gzipCompress` / `gzipDecompress` 全局（toBytes 多格式收窄）+ native 对象挂载 |
| `tests/gzip_test.cpp`（新） | gzip 纯 C++ 单测（往返/空/魔数/标准向量互操作/非法输入/压缩率/解压上限） |
| `include/qjsbind/polyfill/crypto.hpp`（新，入库） | install_crypto：11 个同步 __crypto_* + 9 个异步 __crypto_*_async（BoringSSL EVP；异步 = 协程自由函数 + fetch::file_pool 线程池 + promise_from_sender 自动 Promise） |
| `include/qjsbind/polyfill/crypto.js`（新，入库） | crypto/hostCrypto/nodeCryptoCompat 全局；createHash/createHmac 流式（同步 digest）、hex/base64/latin1/utf8 编解码、Promise 方法（真异步）、B64 变体、pbkdf2 callback |
| `include/qjsbind/polyfill/crypto_embedded.hpp`（生成物，不入库） | embed_js.py 生成（crypto.js） |
| `tests/crypto_test.cpp`（新） | CryptoFixture 17 用例（标准向量互操作/AES 往返与认证/B64 变体/异步 API/不阻塞验证/错误路径等） |
| `include/qjsbind/blob_store.hpp` | `install_blob_store` 增注册 `__native_buf_free`（BlobStore::remove） |
| `include/qjsbind/task.hpp` | TaskEntry 加 cancelled 标志；TaskRunner 加 cancelled id 集合 + `is_cancelled(id)` + 全局 `__native_task_cancelled` |
| `include/qjsbind/host_runtime.hpp` | `setup_apis` 接入 `install_runtime_api`（web API 之后、宿主 register_all 之前） |
| `pixi.toml` | 新增 `fetch-opencc` task；`configure` depends-on 加入 |
| `CMakeLists.txt` | embed_js.py 生成 runtime_api_embedded.hpp；测试列表加 opencc_test / runtime_api_test |
| `tests/opencc_test.cpp`（新） | opencc::convert 纯 C++ 单测（六配置 + 边界 + 往返 + 长文本） |
| `tests/runtime_api_test.cpp`（新） | JS 侧集成测试（base64 native/fallback 双路径、native、uuidv4、runtime.gc/isTaskGroupCancelled、Buffer、opencc） |

### 8.2 关键设计点

- **polyfill 优先 native**：`runtime_api.js` 对 base64 编码优先调 `__native_b64encode`
  （已存在），解码优先调新增 `__native_b64decode`（fetchcore 的 `fetch::base64_decode`
  已有实现）；两者都带纯 JS fallback（native 缺失时仍可用）。
- **fetchcore 解耦**：`__native_b64decode` thunk 放 qjsbind 侧、经公开纯函数入口调用
  fetchcore，与 bundle_dispatcher.hpp 先例一致，不违反 fetch_cpp_decoupling。
- **native.free**：`__native_buf_free` 挂在 `install_blob_store`（与 native_put/get
  同文件同桶语义）；`native.take` 在 JS 侧实现消费语义（get + free）。
- **isTaskGroupCancelled**：cancelled 集合随 TaskRunner 生命周期；任务 id 空间
  per-runner（从 1 递增），查询只对本 runner 的任务有意义。
- **opencc（C++）**：`opencc::convert(text, config)` 纯 C++ API（无 quickjs 依赖，
  其它模块可直接调用）；六配置 = 官方 ver.1.1.9 转换链的链式 MaxMatch（每步一个
  group 合并词典，词组+单字合并、最长匹配优先、多候选取第一个）；tw2s/hk2s 用
  反向变体词典（RevPhrases 仓库自带 + 单字 Rev 由 reverse_swap 生成）；词典懒加载
  （仅被请求的配置触发解析）；数据嵌入二进制，运行时无外部文件依赖。
