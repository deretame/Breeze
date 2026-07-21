# 类 FRB 原生桥：机制说明与 C++ 实现草案

> 通用设计文档：说明 Flutter Rust Bridge（FRB）如何对接原生异步运行时与 Dart 事件循环，以及若用 C++20 按同一模式自研桥时如何落地。
>
> **与具体应用仓库解耦。** 实现可在独立工程中试验，成熟后再决定是否接入业务项目。
>
> C++ 部分为设计草案，默认尚未生产化。

---

## 1. 问题本质

Dart/Flutter 与原生代码（Rust / C++ / …）各自有独立执行模型：

| 侧 | 典型模型 | 特点 |
|----|----------|------|
| Dart | Isolate 事件循环 | 单线程协作；`Future` / `Stream` 挂在该循环上 |
| Rust | 常见为 tokio 等 | 多线程异步 |
| C++ | 常见为 asio 等 | 多线程异步 |

**两边不能共享同一个 event loop。** 桥只做三件事：

1. 把调用从 Dart 安全投递到原生调度器；
2. 在原生侧执行业务（可 async）；
3. 把结果 / 错误 / 流式事件投递回 **发起调用的 Dart Isolate**。

稳定抽象是三通道：

```text
sync       调用线程立刻返回
async RPC  一次请求 → 一次完成（Dart Future）
stream     一次订阅 → 多次事件（Dart Stream）
```

```text
Dart Isolate  ←—— port / FFI / 回调指针 ——→  原生 Runtime
(Future/Stream)                              (tokio / asio / …)
```

---

## 2. FRB 是怎么实现的

以下描述以 **flutter_rust_bridge 2.x** 默认 Handler 为准（概念级，便于对照自研）。

### 2.1 角色划分

| 组件 | 职责 |
|------|------|
| Codegen | 读 Rust API 上的 `#[frb]` 等标记，生成 Dart API + Rust `wire_*` |
| Dart `BaseHandler` | 把一次调用变成 `Future`（或 sync 返回值） |
| Rust `DefaultHandler` | 解码参数、选择调度器、编码结果、发回 port |
| `SimpleThreadPool` | 跑「非 async 的普通 `fn`」 |
| `SimpleAsyncRuntime` | 内部持有 **`tokio::Runtime`**，跑 `async fn` |
| `DartFnHandler` | Rust 回调 Dart 并可 `await` 返回值 |
| Codec（如 SSE） | 参数/返回值二进制布局 |

默认（非 web）结构：

```text
FLUTTER_RUST_BRIDGE_HANDLER
  = SimpleHandler
      + SimpleExecutor
          + SimpleThreadPool      // normal
          + SimpleAsyncRuntime    // tokio::Runtime::new()
      + DartFnHandler             // 反向调用
```

业务侧一般**不必**再 `#[tokio::main]`。  
在 FRB `wrap_async` 路径里，`tokio::spawn` / `Handle::try_current()` 可用，因为 future 已跑在 FRB 创建的 Runtime 上。

### 2.2 Dart → 原生（async RPC）

Dart 侧（`executeNormal` 思路）：

```text
1. Completer completer = Completer()
2. SendPort = 一次性 ReceivePort 的 sendPort
3. FFI: wire_xxx(nativePort, 编码参数…)
4. return completer.future.then(decode)
```

Rust 侧：

```text
1. wrap_async：解码参数，得到 async 闭包
2. async_runtime.spawn { 业务.await; 编码; sender.send(port) }
3. 消息进入 Dart ReceivePort → Completer.complete
```

**Dart 事件循环与 tokio 只通过 isolate port 交接，互不嵌入。**

### 2.3 业务 API 长什么样（重点）

FRB **不要求**业务返回特殊的 `BridgeFuture<T>` / `BridgeStream<T>`。  
业务只写「普通函数」；**Future/Stream 由 codegen + 运行时在外侧包出来**。

| 通道 | Rust 业务签名（概念） | 生成的 Dart |
|------|----------------------|-------------|
| async RPC | `async fn fetch(req) -> Result<Resp>` | `Future<Resp> fetch(req)` |
| stream | `fn ticks(sink: StreamSink<T>) -> Result<()>` | `Stream<T> ticks()` |
| sync | `fn version() -> i32`（`#[frb(sync)]`） | `int version()` |

**async：** 就是语言自带的 `async fn` + 普通返回值。  
wire 层负责 `runtime.spawn`、把 `Ok/Err` 编码后 `port.send`。业务**看不到** port。

**stream（官方模式）：**

```rust
// 参数里要一个 StreamSink；可放到任意参数位置
fn f(sink: StreamSink<T>, /* 其它参数 */) -> Result<()> { ... }
// 或
fn f(a: i32, sink: StreamSink<String>) -> Result<()> { ... }
```

- Dart 调用后立刻得到 `Stream<T>`，与 `sink` 已接通。
- Rust 函数本身可以**马上返回**；`StreamSink` 可继续持有，稍后（甚至很久以后）`sink.add` / 结束。
- 日志流、进度、长生命周期事件都靠这个，而不是 `fn f() -> Stream<T>`。

这是自研桥应优先对齐的形状：**业务不包 Future/Stream 包装类型；包装是桥的事。**

### 2.4 三种调度

| API 形态 | 调度 | 说明 |
|----------|------|------|
| `async fn` + `#[frb]` | **tokio**（`wrap_async`） | IO、真正异步；返回普通 `T`/`Result<T>` |
| 普通 `fn` + `#[frb]` | **thread pool**（`wrap_normal`） | 含带 `StreamSink` 的启动函数等 |
| `#[frb(sync)]` | **当前 FFI 线程**（`wrap_sync`） | 立刻返回；必须短小、无阻塞 |
| `#[frb(init)]` | 库初始化时调用 | 全局一次性设置 |

### 2.5 反向调用

**DartFn（Rust → Dart → 再回 Rust）**

```text
Rust await dart_callback(args)
  → 经 dart_handler_port 把闭包调用丢到 Dart Isolate
  → Dart 执行
  → 结果经 port 回 Rust（oneshot 完成）
```

### 2.6 端到端时序

```text
┌────────────── Dart Isolate ──────────────┐
│  await api.doWork(...)                   │
│    Completer + SendPort                  │
│    FFI(wire, port, args)                 │
└──────────────────┬───────────────────────┘
                   │
┌──────────────────▼──── 原生 so/dll ──────┐
│  wire_impl                               │
│    wrap_async → tokio::spawn             │
│      业务.await → Post 结果到 port       │
└──────────────────┬───────────────────────┘
                   │
┌──────────────────▼───────────────────────┐
│  ReceivePort → complete → 业务继续       │
└──────────────────────────────────────────┘
```

### 2.7 和 `NativeCallable.listener` 的关系

| API | 能力 |
|-----|------|
| `NativeCallable.listener` | 任意线程可调；投回创建它的 Isolate；**仅 void**；必须 `close()` |
| `NativeCallable.isolateLocal` | 同线程；可同步有返回值 |
| `NativeCallable.isolateGroupBound` | 任意线程；group 内同步执行 |

FRB 的 **RPC 主路径**是 **Completer + port**（要返回值/错误）。  
`listener` 适合单向事件（进度、日志），**不能**单独替代整座桥。

---

## 3. C++ 自研桥：目标

用 **C++20** 做与 FRB **同构**的半边：

| 层 | 选型 | 角色 |
|----|------|------|
| IO / 调度 | **asio**（`io_context` + 线程池 + `strand`） | 原生事件循环 |
| 协程 | **async-simple** | 业务 `async/await` |
| Codegen | **libclang** 解析窄 API 头 | 生成 Dart + C++ dispatch |
| 回 Dart | port /（可选）`NativeCallable.listener` | 进 Isolate 的唯一入口 |

非目标（第一阶段）：

- 不把 asio 与 Dart 跑在同一线程；
- 不把 asio/async-simple/STL 实现细节导出进 AST；
- 不支持任意模板/重载/默认参数作为稳定 API 面。

```text
┌──────────────── Dart Isolate ────────────────┐
│  生成的 API：Future / Stream / sync          │
└─────────────────────┬────────────────────────┘
                      │ FFI / port / 函数指针
┌─────────────────────▼── bridge.so ───────────┐
│  Codec + HandleTable + Cancel + Dispatch     │
│                   │                          │
│          asio::io_context (workers)          │
│                   │                          │
│          async-simple 协程业务               │
└──────────────────────────────────────────────┘
```

硬规则：

1. asio 工作线程不直接碰 Dart API（除文档保证线程安全的 post）；
2. C++ 异常不穿越 FFI，边界统一编成错误帧；
3. dispose / isolate 销毁时要取消 inflight 并拒绝再 post。

---

## 4. C++ 运行时

### 4.1 Runtime

```text
BridgeRuntime
  ├─ io_context
  ├─ N 个 worker 线程
  ├─ 按 session 可选 strand
  └─ shutdown: 取消 → stop → join
```

生命周期：

1. Dart `Bridge.init()` → 建 Runtime、起线程；
2. 运行期任务 `post` 到 `io_context`；
3. `Bridge.dispose()` → cancel inflight → stop → join。

### 4.2 业务 API 形态（对齐 FRB，不要返回 Future 包装）

**反例（早期草案，已废弃）：**

```cpp
// 不好：业务被迫返回 bridge::Future<T>，手写别扭，codegen 也难
bridge::Future<FetchResponse> fetch(FetchRequest req) {
  return runtime_->spawn_on_asio([...]() -> Lazy<FetchResponse> { ... });
}
```

问题：

1. 每个 async API 都要会「装 Future」，心智重；
2. codegen 要识别/生成包装类型，和业务返回值缠在一起；
3. **FRB 根本不是这么做的**——业务写普通 `async fn` / 普通 `fn`+`StreamSink`，包装在 wire。

**正例：业务只写普通签名，桥在外侧调度。**

```cpp
// ---- 业务（人手写，或以后由 impl 文件提供）----

// async RPC：C++20 协程，返回普通结果（或 expected）
async_simple::coro::Lazy<tl::expected<FetchResponse, BridgeError>>
fetch(FetchRequest req) {
  auto body = co_await http_get(req.url, req.timeout_ms);
  co_return FetchResponse{std::move(body)};
}

// stream：参数带 StreamSink；函数可立刻返回，sink 可长期持有
void create_log_stream(StreamSink<std::string> sink) {
  // 注册到全局 logger；之后任意线程/协程 sink.add(...)
  Logger::instance().subscribe(std::move(sink));
}

void download(std::string url, std::string path, StreamSink<Progress> sink) {
  runtime().spawn([...]() -> Lazy<> {
    // 下载循环里 sink.add(progress)；结束 sink.end() / sink.add_error(...)
    co_return;
  });
}

// sync
int32_t bridge_version() { return 1; }
```

```cpp
// ---- wire / 生成代码（业务不写这些）----

// async：看到「协程函数」或 [[bridge::async]]，生成：
void wire_fetch(ReplyPort port, bytes args) {
  auto req = decode<FetchRequest>(args);
  runtime().spawn_on_asio([port, req = std::move(req)]() -> Lazy<> {
    auto result = co_await fetch(std::move(req));  // 调业务
    post_result(port, result);                     // Ok/Err → Dart Completer
  });
}

// stream：参数里出现 StreamSink<T>，生成 Dart Stream，并把 sink 注入业务：
void wire_create_log_stream(StreamPort port, bytes args) {
  auto sink = StreamSink<std::string>::from_port(port);
  try {
    create_log_stream(std::move(sink));  // 业务可马上返回
    // 不在这里 end；由业务/持有方决定何时 end
  } catch (...) {
    post_stream_error(port, ...);
  }
}
```

| 谁 | 职责 |
|----|------|
| **业务** | 普通协程 / 普通函数；stream 只依赖 `StreamSink<T>` 的 `add`/`end`/`error` |
| **wire（生成）** | 解码、`spawn` 到 asio、把 port 封成 Sink 或 Reply、编码回传 |
| **Dart（生成）** | `Future`/`Stream` 外壳；业务 C++ **不出现** `Future`/`Stream` 类型名 |

`StreamSink<T>` 是桥提供的**小工具类型**（类似 FRB 的 `StreamSink`），不是业务返回值。  
实现上内部就是「能安全 post 到某 port 的句柄」，可 `shared_ptr` 式共享，便于长期持有。

### 4.3 async-simple 放哪

- **业务协程体**里用 async-simple（`co_await` IO 等）；
- **启动**只发生在 wire：`runtime.spawn_on_asio(业务协程)`；
- 业务函数**不要**自己 `return runtime.spawn(...)` 再包一层。

### 4.4 三通道（实现视角）

**(A) sync**  
`[[bridge::sync]]` 或签名可同步识别 → FFI 当前线程直接调业务 → 同步返回 buffer。

**(B) async RPC**

```text
Dart:  Completer + reply port（可多路复用 request_id）
wire:  spawn { co_await 业务(...); post 一次结果 }
业务:  Lazy<T> / Lazy<expected<T,E>>，无 port 参数
```

**(C) stream（FRB StreamSink 模式）**

```text
Dart:  得到 Stream<T>；port 与 StreamSink 绑定
wire:  构造 StreamSink 传给业务；业务函数返回后 sink 仍可用
业务:  fn(StreamSink<T>, ...)；随时 add；最后 end/error
```

可选补充：全局 void 事件可用 `NativeCallable.listener`；**主推仍是 StreamSink+port**，与 FRB 一致、能带类型载荷与错误。

### 4.5 取消 / 句柄 / 错误

- **取消**：Dart `cancel(id)` → C++ `cancellation_signal`（或等价）沿协程链传播。
- **句柄**：`uint64_t` + 进程内表；Dart `Finalizer` → `release`；dispose 清空。
- **错误**：`ok + payload` / `err + code + message`；禁止 exception 出动态库。

---

## 5. 线协议（草案）

```text
magic:       u32   // 如 'BRG1'
version:     u16
msg_type:    u8    // Request / Response / StreamData / StreamEnd / Error / Cancel
flags:       u8
request_id:  u64
method_id:   u32   // codegen 分配
payload_len: u32
payload:     bytes
```

类型白名单（先做这些）：

| C++ 桥接面 | Dart |
|------------|------|
| 标量 `bool` / 定宽整数 / `double` | 对应标量 |
| `std::string` | `String`（UTF-8） |
| `std::vector<uint8_t>` | `Uint8List` |
| 聚合 `struct` | class |
| `enum class : int32_t` | enum |
| `Handle<T>` | 不透明包装 |
| 参数 `StreamSink<T>` | （该函数）`Stream<T>`；**sink 不出现在 Dart 参数列表** |
| 协程返回 `T` / `expected<T,E>` | `Future<T>`（async 函数） |

说明：Dart 的 `Future`/`Stream` **不**对应 C++ 业务返回类型里的包装类，而对应 **函数形态**（是否 async、是否带 `StreamSink` 参数）。

禁止：裸指针、`std::function`、随意模板、虚接口导出、重载、默认参数。  
协议按 **逻辑类型** 编，不要直接拿 C++ ABI 当线格式。

---

## 6. Codegen：libclang

### 6.1 原则

- 只解析 **窄桥接头**（如 `bridge_api.h` + `bridge_types.h`）；
- 实现、asio、async-simple **不进**导出 AST；
- 用 `[[bridge::export]]` 标结构体；函数用 `[[bridge::sync]]` / `[[bridge::async]]`，或靠签名推断（见下）；
- **stream 不靠返回 `Stream<T>`**，靠参数列表里出现 `StreamSink<T>`（与 FRB 相同）；
- compile flags 与真编译一致（`-std=c++20`、`-I`、宏）；CI 锁定 clang 版本。

### 6.2 API 面示例（对齐 FRB）

```cpp
// bridge_api.h — codegen 唯一入口（概念）
#pragma once
#include "bridge_types.h"  // StreamSink<T>、BridgeError 等

namespace demo::api {

struct [[bridge::export]] FetchRequest {
  std::string url;
  int32_t timeout_ms;
};

struct [[bridge::export]] FetchResponse {
  int32_t status;
  std::vector<uint8_t> body;
};

struct [[bridge::export]] Progress {
  int64_t received;
  int64_t total;
};

// sync → Dart: int bridgeVersion()
[[bridge::sync]]
int32_t bridge_version();

// async：普通协程 + 普通返回值 → Dart: Future<FetchResponse> fetch(...)
// 不要写成 Future<FetchResponse> fetch(...)
[[bridge::async]]
async_simple::coro::Lazy<FetchResponse> fetch(FetchRequest req);

// 或返回 expected，由 wire 映射为 Dart 抛错 / Result
// Lazy<expected<FetchResponse, BridgeError>> fetch(FetchRequest req);

// stream：参数带 StreamSink → Dart: Stream<Progress> download(url, path)
// sink 从 Dart 参数中剥掉，由 wire 注入
void download(std::string url, std::string path, StreamSink<Progress> sink);

// 可长期持有 sink（函数立刻返回）→ Dart: Stream<String> createLogStream()
void create_log_stream(StreamSink<std::string> sink);

}  // namespace demo::api
```

Codegen 识别规则（建议）：

| 条件 | 生成 |
|------|------|
| 参数含 `StreamSink<T>` | Dart `Stream<T>`；C++ wire 注入 sink |
| `[[bridge::async]]` 或返回 `Lazy<T>` | Dart `Future<T>`；wire `spawn` + 单次 reply |
| `[[bridge::sync]]` | Dart 同步调用 |
| 仅普通 `T foo(...)` 且非 sync | 可默认 thread-pool 跑同步函数（类 FRB normal） |

### 6.3 流水线

```text
bridge_api.h
    → libclang AST
    → 过滤标记
    → IR (JSON)
    → Dart 生成物 + C++ dispatch 表 + schema
```

原型可用 Python `clang.cindex`；稳定后可改 C++ 链 libclang。

### 6.4 IR 示例

```json
{
  "version": 1,
  "functions": [
    {
      "name": "fetch",
      "method_id": 1001,
      "kind": "async",
      "args": [
        {"name": "req", "type": {"kind": "struct", "name": "FetchRequest"}}
      ],
      "returns": {"kind": "struct", "name": "FetchResponse"}
    },
    {
      "name": "download",
      "method_id": 1002,
      "kind": "stream",
      "stream_item": {"kind": "struct", "name": "Progress"},
      "args": [
        {"name": "url", "type": {"kind": "string"}},
        {"name": "path", "type": {"kind": "string"}}
      ],
      "sink_param": "sink",
      "returns": {"kind": "void"}
    },
    {
      "name": "create_log_stream",
      "method_id": 1003,
      "kind": "stream",
      "stream_item": {"kind": "string"},
      "args": [],
      "sink_param": "sink",
      "returns": {"kind": "void"}
    }
  ]
}
```

注意：IR 里 **没有** `returns: Future<...>` / `returns: Stream<...>`；  
`kind: async|stream|sync` +（stream 时）`stream_item` 就够生成 Dart 外壳。

---

## 7. Dart 侧最小封装

```dart
abstract final class NativeBridge {
  static Future<void> init();
  static void dispose();

  static T invokeSync<T>(/* method + args */);
  static Future<T> invokeAsync<T>(int methodId, Uint8List args);
  static Stream<T> invokeStream<T>(int methodId, Uint8List args);
}
```

- async：`request_id` → `Completer` 表；
- stream：`subscription_id` → `StreamController`，认 `Done`/`Error`；
- 全局 void 事件可选用 `NativeCallable.listener`，生命周期与 `close()` 必须闭环。

---

## 8. FRB vs C++ 草案对照

| 维度 | FRB 2.x 默认 | C++ 草案 |
|------|----------------|----------|
| API 标记 | `#[frb]` 等 | `[[bridge::*]]` |
| 解析 / 生成 | FRB codegen | **libclang** + 自研模板 |
| Async 运行时 | **tokio** | **asio** |
| 协程 | Rust `async fn` | 业务用 **async-simple**；wire 负责 spawn |
| 普通同步任务 | thread pool | asio 池或分立池 |
| 业务 async 签名 | `async fn f() -> T` | `Lazy<T> f()`（**不**返回桥 Future 包装） |
| 业务 stream 签名 | `fn f(sink: StreamSink<T>)` | `void f(StreamSink<T> sink, ...)` |
| Dart Future | Completer + port | 同构（建议多路复用） |
| 流 | `StreamSink` 参数 | 同构 `StreamSink` + port 多帧 |
| 反向调用 | DartFn | port RPC / 同步 callable |

要抄的不是语言，而是：

1. **业务 API 保持「普通函数」**；Future/Stream 外壳在 wire/Dart 生成；  
2. stream 用 **`StreamSink` 入参**，可长期持有，函数可先返回；  
3. Handler = 调度器 + 回 port；  
4. wire：解码 → 调度 → 编码 → send；  
5. 句柄与 dispose；codegen 保证两侧一致。

---

## 9. 建议落地顺序（独立工程）

### Phase 1 — 手写骨架（无 codegen）

- Runtime（asio 线程池 + shutdown）
- 三个 API：`version` sync、`add` async、`ticks` stream
- Dart：`invokeSync` / `invokeAsync` / `invokeStream`
- 至少两个平台各跑通（例如 Windows + Android）

### Phase 2 — libclang

- 解析窄头 → IR → 生成 Dart + dispatch
- CI 锁 clang；可选：生成物 diff

### Phase 3 — 生产能力

- 取消、超时、错误表、Handle+Finalizer
- 拷贝与大 blob 策略
- 压测：并发、热重启、快速 cancel、listener 泄漏

### Phase 4 — 再谈接入业务

- 仅新模块 / 逐步迁移 / 或长期独立库  
- **未到 Phase 3 前，不替换任何已有 FRB/生产桥**

---

## 10. 独立工程目录建议

```text
native_bridge/
├── include/
│   ├── bridge_api.h          # codegen 入口
│   ├── bridge_types.h
│   └── bridge_runtime.h
├── src/
│   ├── runtime/              # asio + async-simple
│   ├── codec/
│   ├── api_impl/
│   └── ffi_entry.cc          # C ABI
├── codegen/
│   ├── parse_libclang.py
│   └── templates/
├── generated/
├── dart/                     # 或独立 Flutter package
│   └── lib/
│       ├── bridge.dart
│       └── bridge_generated.dart
└── README.md
```

---

## 11. 风险（短表）

| 风险 | 缓解 |
|------|------|
| 工作量接近「迷你 FRB」 | 严守阶段；先 3 个 API |
| clang / NDK 不一致 | CI 统一版本与 flags |
| dispose 与 post 竞态 | 取消 + 世代号 + dispose 后丢弃 |
| listener 未 close | 包装强制 close；文档与 lint |
| 异常出 FFI | 边界 catch；异常策略全库一致 |

---

## 12. 参考

- Flutter Rust Bridge：<https://cjycode.com/flutter_rust_bridge/>
- Dart `NativeCallable.listener`：<https://api.dart.dev/dart-ffi/NativeCallable/NativeCallable.listener.html>
- asio、async-simple、libclang：各自上游文档

本地若已缓存 FRB 源码，可对照：

- `handler/implementation/handler.rs` — `DefaultHandler`
- `handler/implementation/executor.rs` — `execute_async` / `execute_normal`
- `rust_async/io.rs` — `SimpleAsyncRuntime`（tokio）
- Dart `BaseHandler.executeNormal` — Completer + port

---

## 13. 一句话

- **FRB**：业务写普通 `async fn` / 普通 `fn(StreamSink<T>, …)`；**不**返回桥专用 Future/Stream 类型。Dart 的 Future/Stream 由运行时 + codegen 用 **port** 接出来；async 跑在内置 **tokio** 上。  
- **C++ 草案**：同样——业务写 `Lazy<T> fetch(...)` 与 `void f(StreamSink<T>)`；wire 里 **asio spawn** 与 **Sink 注入**；用 **libclang** 认签名形态，而不是认 `bridge::Future` 包装类。  
- **listener** 只覆盖单向 void 事件，替不了 RPC / 类型化 Stream。

先在独立仓库把 Phase 1–2 做稳，再考虑与任何业务工程集成。
