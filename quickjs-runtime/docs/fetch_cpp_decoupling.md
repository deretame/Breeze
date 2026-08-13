# fetch C++ 核心解耦 迁移参照文档（v3 设计提案）

> 状态：设计提案（2026-08-08，未实施）。本文只做设计参照，不含实现。
> **实施状态（2026-08-08 当日）**：✅ 已按本提案完成迁移（fetchcore 落地、
> 绑定层变薄、wpt 878 pass / 0 fail 不回归），见 `docs/fetch_milestone_progress.md` §v3。
> 前置文档：`docs/fetch_design.md`（v1）、`docs/fetch_streaming_design.md`（v2）、`docs/known_issues.md`。
> 动机：现有 fetch 功能已相当齐全（wpt 精选子集 30/30 文件全过，510 pass / 0 fail），但与 QuickJS/qjsbind
> 耦合较深。目标是抽出一个**独立的纯 C++ fetch 核心库**——C++ 业务代码可以像用 JS fetch 一样方便地发请求；
> JS 绑定层退化为薄适配层，行为不变、wpt 不回归。

## 1. 现状与耦合点盘点

### 1.1 现状分层（已实现）

```
JS (quickjs-ng) ── qjsbind 绑定层 ── qjsbind::web（header-only，混合层）
                                        │
                                        ▼
                              FetchBackend 抽象接口（include/qjsbind/web/net.hpp）
                                        │
                                        ▼
                        qjsbind_net 静态库（src/net/，boost::beast + OpenSSL + socks5）
```

### 1.2 已经具备的解耦基础（迁移成本低的关键事实）

- `include/qjsbind/web/net.hpp` 的 `Header` / `HttpRequest` / `HttpResponse` / `BodySource` / `FetchBackend`
  是**纯 C++ 类型**，不含任何 `JSValue`/`JSContext`。
- `src/net/` 全部文件**不出现任何 QuickJS 类型**；`http_request(io, req, tls, st, proxy)` 签名本身就是纯 C++。
- 异步通货是 `std_exec::task`（stdexec P2300 协程），取消通货是 `std::stop_token`——两者都与 JS 无关。
- io_context 全程外注：`http_request` 第一参、`BeastFetchBackend` 构造参数都是外部 `boost::asio::io_context&`。
- 拦截器链（`interceptor.hpp`）的接口签名是纯 C++ 类型，around 协程洋葱链已实现解压/SOCKS5 选路。

### 1.3 残余耦合点（本次要拆掉的）

| 耦合点 | 位置 | 说明 |
|---|---|---|
| 双类型 + 桥接 | `src/net/http_client.cpp`（`net_request_from_web` / `web_response_from_net`） | `net::HttpRequest/HttpResponse` 与 `web::HttpRequest/HttpResponse` 同名同构两套，逐字段互转 |
| 核心类型住在绑定层目录 | `include/qjsbind/web/net.hpp` | 纯 C++ 类型物理上位于 JS 层 include 树内，核心库无法独立引用 |
| 策略逻辑在 JS 层 | `include/qjsbind/web/fetch.hpp` 的 `fetch_impl` | 重定向循环（≤20 跳/follow/error/manual）、SRI 包装、`data:` URL 处理都是纯 C++ 逻辑却长在绑定层，且直接调 `throw_type_error`（JS 异常） |
| 中间件住在 JS 层 | `include/qjsbind/web/interceptor.hpp` | 解压/SOCKS5 选路是纯 C++，但该头反向 include `<net/http_backend.hpp>` 且直接用 OpenSSL/zlib/brotli |
| 注册入口绑定 JS | `install_web_apis(ctx, backend, interceptors)` | Client/中间件配置与 JS 安装函数耦在一起，C++ 侧无独立入口 |
| TLS 取循环的暗道 | `qjs::current_io()` / `io_of(ctx)` | TLS 反查 Runtime 的 io（绑定层）；核心库用独立的 thread_local 槽 `fetch::thread_io()`（绑定层在 Runtime 构造时 `set_thread_io`，两套互不干扰） |
| 无任何 C++ 直连用例 | 全仓库 | `http_request` / `BeastFetchBackend` 只被 JS fetch 触发，无 `sync_wait`/直调调用点 |

## 2. 目标与非目标

### 2.1 目标

1. **独立 C++ fetch 核心库**（下称 `fetchcore`）：不 include、不链接任何 quickjs/qjsbind 头与库；
   C++ 代码 `co_await client.fetch(req)` 即可发请求，具备与 JS fetch 同等的传输语义（重定向/解压/SRI/代理/中止）。
2. **调度器来源（thread_local）**：核心库不再层层传递 io 参数——`Client`/`BeastTransport`/`MultipartEncoder`/easy 全部从当前线程的
   `fetch::set_thread_io()` 绑定槽取 `io_context`（`fetch::thread_io()`，见 `scheduler.hpp`）。发起 fetch 的线程必须先绑定；
   thread_local 每线程独立（多线程各自 set 各自的 io），多实例可共用一个 io（各自独立的中间件/TLS/代理配置互不干扰）。
3. **JS 绑定层变薄**：只做 JS 类型世界 ⇄ C++ 值类型的转换与桥接（Promise、ReadableStream、AbortSignal、body 消费）；
   JS API 行为不变，wpt 精选子集 510 pass / 0 fail / expected 数不增。
4. **中间件分层划界**（详见 §5）：C++ 中间件是核心库能力，注册入口只在 C++ API，**不以任何形式暴露给 JS**；
   JS 侧中间件（如未来需要）只在绑定层内实现，两条链不混用。

### 2.2 非目标（v3 不做，沿用 v1/v2 边界）

- 不改 JS API 表面与行为（Headers guard/forbidden 语义、Node(undici) 头策略、body 消费六件套等全部照旧）。
- 不做连接池/keep-alive 复用、HTTP/2、cookie jar、cache、CORS/credentials、HTTP CONNECT 代理。
- 请求侧支持流式上传（`Request::body_stream`（BodySource）+ `body_size` 预计算
  Content-Length；`MultipartEncoder` 流式 multipart 编码器，文件 part 不整读进内存）；
  `duplex`（请求/响应同时双向流）仍不做。
- **不在本次实现 JS 侧中间件**——只在 §5 划定它未来该挂的位置。
- 不更换异步框架（继续 stdexec `std_exec::task` + asio，理由见 §4.5）。

## 3. 目标分层架构

```
┌────────────────────────────────────────────────────────────────┐
│ JS 绑定层 qjsbind::web（变薄）                                   │
│  JS 类与规范语义：Headers/Request/Response/Blob/FormData/URL/    │
│  AbortController；body 提取与消费（text/json/...）；             │
│  Promise 桥（promise_from_sender）；ReadableStream 桥；          │
│  【JS 中间件（未来）：纯业务，只在绑定层，见 §5】                 │
├────────────────────────────────────────────────────────────────┤
│ fetchcore 核心库（新增，纯 C++，namespace fetch）                │
│  fetch::Client（注入 io_context&）+ fetch::Request/Response/    │
│  Headers/BodySource                                             │
│  内建管线：redirect 循环 / SRI / data: URL                       │
│  C++ 中间件洋葱链（解压、SOCKS5 选路 + 用户插件：鉴权/日志/      │
│  重试/缓存/mock……）——仅 C++ 可见                                 │
├────────────────────────────────────────────────────────────────┤
│ 传输实现（现 src/net 演进为 fetch::BeastTransport）              │
│  beast + OpenSSL + SOCKS5 + 内嵌 CA；BodySource 拉模型 64KiB 块  │
└────────────────────────────────────────────────────────────────┘
```

依赖方向严格向下：绑定层 → fetchcore →（asio/beast/OpenSSL）。fetchcore 反向依赖为零。

## 4. 核心库 API 设计（草图）

### 4.1 统一类型系统（废除双类型桥接）

`web/net.hpp` 与 `src/net/http_client.hpp` 的两套 `HttpRequest/HttpResponse` 合并为一套核心类型：

```cpp
namespace fetch {

struct Header { std::string name; std::string value; };
using Headers = std::vector<Header>;            // 保序、允许重复名；大小写不敏感查找工具随库提供

struct Request {
    std::string method = "GET";
    std::string url;                            // 绝对 http/https/data URL（相对 URL 解析是绑定层职责）
    Headers headers;
    std::string body;                           // 整收；流式上传不做
    std::string integrity;                      // SRI 表达式，空 = 不校验
    enum class Redirect { follow, error, manual } redirect = Redirect::follow;
};

struct Response {
    int status = 0;
    std::string reason;
    Headers headers;
    std::string url;                            // 最终 URL（重定向后）
    bool redirected = false;
    std::shared_ptr<BodySource> body;           // null = 无 body；拉模型，64 KiB 块
};

}
```

- `BodySource` 接口原样下沉（`read() -> std_exec::task<std::optional<std::string>>` + `cancel()`，跨线程 cancel 约定不变）。
- 现 `interceptor.hpp` 里的 `has_header` / `strip_headers` 等头操作工具一并迁入核心库。
- 核心 Request/Response 是**纯值类型**——不含 JS guard、forbidden 检查、规范化逻辑；那些是 JS 规范语义，留在绑定层（§4.4）。

### 4.2 Client 与 io_context 注入（核心需求）

```cpp
namespace fetch {

struct Options {
    TlsOptions tls{};                 // verify / extra_trust_pem（现 src/net 已有）
    bool auto_decompress = true;      // 内建 Accept-Encoding 中间件开关
    int max_redirects = 20;
};

class Client {
public:
    // io_context 从当前线程 thread_local 取（须先 fetch::set_thread_io()）
    explicit Client(Options opt = {});

    // 注册 C++ 中间件（仅 C++ 可见，见 §5）。先注册者在最外层。
    Client& use(std::shared_ptr<Middleware> mw);

    // 主入口：redirect 循环 + SRI + data: + 中间件链 + 传输。
    std_exec::task<Response> fetch(Request req, std::stop_token st = {});
};

// 便捷整读（C++ 侧没有 .text()，给一个等效物）
std_exec::task<std::string> read_all(const Response& resp);

}
```

**生命周期与线程契约**（沿用现有实现已遵守的假设，成文化）：

1. `Client` 不拥有 io；**io 必须比 Client 及其在飞请求活得久**（与 beast `ssl::context` shared_ptr 先例一致）。
2. io 为单线程驱动、无 strand：`Client` 只能由跑 `io.run()` 的那根线程使用；唯一跨线程入口是
   `std::stop_token` 触发的 `cancel()`（只碰 socket，沿用 `http_client.cpp` 注释约定）。
3. `Client` 无全局状态、无 TLS 依赖（不碰 `qjs::current_io()`）；可在任意作用域构造，多实例共存。
   唯一要求：**构造 Client 的线程已 `fetch::set_thread_io(io)`**（绑定层在 Runtime 构造时自动绑定；
   直连用户在发起线程自行绑定）。构造后跨线程使用不受限（io 引用在构造时已固化）。
4. 唯一保留的进程级共享是内嵌 CA `X509_STORE`（`shared_ca_store()`，现 `http_client.cpp:92` 已有），
   属实现细节，不构成实例间耦合。

**C++ 侧两种驱动方式**：

```cpp
// A. 已在 io 线程的协程内（嵌入场景，宿主程序自己在跑 io.run()）
auto resp = co_await client.fetch({.url = "https://example.com/api"});
auto text = co_await fetch::read_all(resp);

// B. 独立程序一次性使用：spawn 上 io 调度器后自己跑 io.run()
boost::asio::io_context io;
fetch::set_thread_io(io);            // 绑定当前线程的 fetch io
fetch::Client client{};
stdexec::counting_scope scope;
stdexec::spawn(client.fetch({.url = "https://example.com/api"})
               | stdexec::then([](fetch::Response r){ /* ... */ }),
               fetch_scheduler(io), scope);          // 调度器适配见 §4.5
io.run();
```

（可选便捷封装 `fetch::run_blocking(client.fetch(req))`：内部 spawn + 自跑 io 直至完成，给 CLI/脚本式用法。
非必须，列为可选。）

### 4.3 中间件（C++ 专属）

接口沿用现有 around 协程洋葱链（`interceptor.hpp:38-66` 原样下沉）：

```cpp
namespace fetch {

using Handler = std::function<std_exec::task<Response>(const Request&, std::stop_token)>;

struct Middleware {
    virtual ~Middleware() = default;
    virtual std_exec::task<Response> intercept(const Request& req, std::stop_token st, Handler next) = 0;
};

}
```

语义全部沿用 v2 已验证的约定（`fetch_streaming_design.md` §5）：

- `co_await next` 前是前置相位、之后是后置相位；可改请求（拷贝后改）、短路、抛异常、catch 重试、
  改响应 head、包装 `BodySource`（多层嵌套）。
- **注册顺序 = 嵌套顺序：先注册者在最外层**；前置按注册序进入，后置逆序返回；链尾是传输。
- **重定向每一跳都走全链**（redirect 循环在 `Client::fetch` 内，每跳重新组装链，跳间不共享状态）。
- 装配约定：内建 Accept-Encoding 固定最外层（read 路径先解压）；SOCKS5 选路固定最内层（贴近传输）；
  用户 `use()` 的中间件夹在两者之间，按注册序。

**内建中间件/管线清单**（迁移来源）：

| 能力 | 现位置 | 迁移后 |
|---|---|---|
| Accept-Encoding + 透明解压（gzip/deflate/br） | `web/interceptor.hpp` `AcceptEncodingInterceptor`/`DecompressSource` | fetchcore 内建中间件（`Options::auto_decompress` 开关） |
| SOCKS5 选路 | `web/interceptor.hpp` `Socks5ProxyInterceptor` | fetchcore 内建中间件（Route 回调注入） |
| 重定向循环 | `web/fetch.hpp` `fetch_impl` | `Client::fetch` 内建管线 |
| SRI/integrity 校验 | `web/fetch.hpp` + `IntegritySource` | `Client::fetch` 按 `Request::integrity` 包装 |
| `data:` URL | `web/fetch.hpp` | `Client::fetch`（纯 C++ 构造响应；JSON MIME 的 JS 解析仍在绑定层消费侧） |

**用户中间件示例（草图）**——体现"给底层请求夹功能的插件"定位：

```cpp
struct AuthMiddleware : fetch::Middleware {           // 鉴权头注入
    std_exec::task<fetch::Response> intercept(const fetch::Request& req, std::stop_token st,
                                              fetch::Handler next) override {
        auto r = req;                                  // req 只读，修改先拷贝
        r.headers.push_back({"authorization", "Bearer " + token()});
        co_return co_await next(r, st);
    }
};
// 同理可写：日志/指标、限流、按状态码重试、缓存（前置短路 + 后置 tee）、mock/离线降级、超时
```

### 4.4 错误与取消模型

- 核心库**只抛中性 C++ 异常**：URL 非法 `std::invalid_argument`；头前网络/协议/TLS/SOCKS5 错误
  `boost::system::system_error`；body 阶段 `BodySource::read()` 抛 `std::exception`；SRI 不匹配抛
  `fetch::Error`（新增，**必须可拷贝**——MSVC 协程异常传播对 move-only 异常类型损坏，KI-051 前车之鉴）。
- 取消继续走 `std::stop_token` 全链贯穿：`socket.cancel()` → `operation_aborted` → `use_sender` 转
  `set_stopped`（KI-028：`use_sender` 不桥接 stop token，硬取消沿用现有 socket 方案）。C++ 用户自备
  `std::stop_source`；超时用"stop_source + steady_timer"配方（可作示例中间件）。
- **JS 语义映射全部在绑定层**：核心异常 → reject TypeError；stopped → reject AbortError
  （`promise_from_sender` 现有三路结算不变）。核心库永远不知道 TypeError 的存在。

### 4.5 异步框架决策：继续 stdexec，不换 asio awaitable

理由：① 传输层与流状态机全链路已是 `std_exec::task`，换框架等于重写；② `promise_from_sender` 桥现成；
③ `stop_token` 语义与 stdexec 取消模型天然对齐；④ stdexec 只需 C++20，无工具链门槛
（`docs/cpp26_executor_model_usage.md`）。唯一要补的：现 `std_exec.hpp` 别名头在 qjsbind 树内，
核心库需自带一份等价别名头（`fetch/task.hpp`，纯 stdexec 别名，无 JS）；io 调度器适配
（现 `context.hpp:40-54` 的 `io_context_scheduler`）同样复制/下沉为核心库内部设施，绑定层改用核心库版本。

### 4.6 JS 绑定层映射表（迁移后每个特性的落点）

| JS fetch 特性 | 迁移后落点 | 说明 |
|---|---|---|
| `fetch(input, init)` 参数解析、Request 构造语义（method 规范化、相对 URL 以 location 为 base、forbidden method-override、GET/HEAD 禁 body） | 绑定层 | JS 规范语义，产出核心 `fetch::Request` |
| Headers 类（guard、同名多值、活迭代器、Symbol.iterator） | 绑定层 | 核心 `fetch::Headers` 只是有序多值表，无规范语义 |
| body 提取（string/ArrayBuffer/URLSearchParams/Blob/FormData → 字节 + Content-Type） | 绑定层 | 物化为 `Request::body` + 头（现状即如此）；FormData 数据模型与 multipart 编解码已下沉 fetchcore（`fetch/formdata.hpp`），绑定层只做 JS ⇄ 条目转换 |
| 重定向 / SRI / data: / 解压 / SOCKS5 | **fetchcore** | 行为不变，绑定层只传字段 |
| AbortController/Signal | 绑定层持 `stop_source` → 核心收 `stop_token` | 现状已是此形态，不变 |
| `response.body` ReadableStream、reader、tee/clone | 绑定层 | `ReadableStreamImpl` 保留，底层 `BodySource` 来自核心 |
| `text()/json()/arrayBuffer()/bytes()/blob()/formData()` | 绑定层 | 现状已是"读干流再解析"，不变 |
| Promise 创建/resolve/reject | 绑定层 `promise_from_sender` | 不变 |
| `install_web_apis(ctx, backend, interceptors)` | 改为 `install_web_apis(ctx, fetch::Client&)` | 中间件配置在 install 之前由 C++ 宿主完成 |

## 5. 中间件边界（关键约束）

用户核心诉求：**C++ 中间件不暴露给 JS，两条链不混用**。定位与规则如下。

### 5.1 定位

- **C++ 中间件（fetchcore）**：给底层请求夹功能的插件。面向基础设施：解压、代理选路、鉴权头注入、
  签名、日志/指标、限流、重试、缓存、mock、超时。它是宿主可信代码，可改任意头、可短路、可换传输；
  写业务逻辑也可以，但它运行在 C++ 值类型世界，对 JS 完全不可见。
- **JS 中间件（未来，绑定层）**：纯业务逻辑。它看到的就是 JS 的 Request/Response 对象，
  写法是 JS 函数包裹 fetch（如埋点、加载态、领域级重试）。

### 5.2 执行位置

```
JS 业务中间件（可选/未来，绑定层内，JS 对象世界）
        │  转换（JS ⇄ C++，install_fetch lambda）
C++ 核心中间件链（Client::use 注册，值类型世界）
        │  链尾
Transport（BeastTransport / SOCKS5 / TLS）
```

### 5.3 隔离规则（迁移与评审的检查点）

1. 中间件注册入口只有 `fetch::Client::use()`（C++ API）；绑定层**不向 JS 导出**任何中间件注册/枚举/移除能力；
   `install_web_apis` 只收一个已装配好的 `Client&`。
2. fetchcore target 不 include、不链接 quickjs/qjsbind——**编译期保证**核心侧不可能泄漏 JS 类型；
   验收时以 grep/编译验证（§8）。
3. JS 侧如未来要做中间件，只在绑定层实现（JS 函数包裹/类封装），**不得**翻译为 `Client::use` 调用，
   两条链在类型世界分界处天然断开（一边 JS 对象、一边 C++ 值，无共享接口）。
4. C++ 宿主在 `install_web_apis` 之前完成全部中间件装配；JS 运行时期间核心链对 JS 是黑盒——
   JS 能感知到的只是 fetch 行为本身（例如被注入了鉴权头、被 mock 短路），无法触及链。

## 6. 迁移步骤（分阶段，每阶段可独立验收）

### P0：基线冻结

- 跑全量测试 + wpt 精选子集，记录基线（510 pass / 0 fail / expected 数）：
  ```bash
  python scripts/analyze_wpt.py
  cd build && ./quickjs_runtime_tests.exe --gtest_filter="WptRunner.*"
  ```
- 明确 acceptance：新增一个"纯 C++ 直连"测试目标作为终点标尺（不建 Runtime，直接 io_context + Client +
  `tests/wpt_server.hpp` 的 WptTestServer 发请求）。

### P1：抽核心类型（机械移动，零行为变化）

- 新建 `include/fetch/`（task.hpp / types.hpp / body.hpp / error.hpp），`web/net.hpp` 的类型迁过去；
  `web/net.hpp` 过渡期改为 alias 引用核心类型。
- `src/net/` 改用核心类型，删除 `net::HttpRequest/HttpResponse` 双类型与桥接函数。
- 新 CMake target `fetchcore`（STATIC；链 Boost::asio/url、OpenSSL、ZLIB、brotli、stdexec；**不链 qjs**）。
- 验收：全量测试绿，wpt 不回归。

### P2：Transport 抽象 + Client 落地

- `FetchBackend` 演变为 `fetch::Transport` 抽象（接口形状不变），`BeastFetchBackend` 演变为
  `fetch::BeastTransport`（ socks5、TLS、CA、BodySource 实现全部随迁）。
- 落地 `fetch::Client{io, Options}` + `use()` + 链组装（`make_chain` 迁核心）。
- 绑定层 `install_web_apis(ctx, fetch::Client&)` 切换调用点（fetch_test / wpt_runner / socks5_test）。
- 验收：P0 的 C++ 直连测试能跑通 GET/HTTPS/流式读/abort；JS 侧全量不回归。

### P3：策略下沉（redirect / SRI / data: / 中间件）

- `fetch_impl` 的重定向循环、SRI 包装、`data:` 处理迁入 `Client::fetch`；SRI 失败等 JS throw 点改为
  `fetch::Error`，绑定层捕获后映射 TypeError。
- `AcceptEncodingInterceptor`/`DecompressSource`/`Socks5ProxyInterceptor`/`IntegritySource` 迁入 fetchcore
  （zlib/brotli 依赖随 target 走）；`interceptor.hpp` 删除。
- 绑定层 `fetch.hpp` 只剩：JS 参数 → 核心 Request、核心 Response → JS Response、异常映射。
- 验收：wpt 510 pass 不回归（重点：redirect、compressed、integrity、data: 相关文件）；socks5_test 绿；
  C++ 直连用例补齐解压/代理/SRI 场景。

### P4：清理与成文

- 删 `web/net.hpp`、alias 过渡层、死代码；`fetch.hpp` 复核变薄结果。
- 顺手修正：`qjsbind_net` 上误挂的 `lexbor::lexbor`（cheerio 用，不属网络库）移回正确 target。
- 更新 `docs/fetch_design.md` 架构图与实现落点说明、`docs/known_issues.md` 补记迁移中发现的新坑、
  `AGENTS.md` 的架构描述。

## 7. 风险与已知坑（迁移时必须复核）

1. **MSVC 协程异常传播**（KI-051）：核心库自定义异常类型（`fetch::Error`）必须可拷贝，禁用 move-only 成员。
2. **取消不桥接**（KI-028）：`use_sender` 不转发 stdexec stop——继续沿用 stop_callback → socket.cancel() 硬取消；
   下沉时 `BeastBodySource::arm_stop` 的注册/注销时序（构造注册、析构注销）原样保留。
3. **JS 线程亲和**（KI-026/KI-035）：绑定层继续保证 JS 对象只在 JS 线程触碰；核心库本身无线程亲和要求，
   但遵守 §4.2 的单线程 io 契约。
4. **生命周期**：io 先于 Client/在飞请求销毁 = 悬垂引用（§4.2-1）；`ssl::context` 由 body source 持有至流结束的
   现有做法（`http_client.cpp:259`）随迁不丢。
5. **隐藏 include**：迁移 `interceptor.hpp` 时剥掉它对 `<net/http_backend.hpp>` 的具体类依赖（SOCKS5 选路改为
   面向 `Transport` 抽象 + Route 回调）——否则"抽象层"仍绑死 beast 实现。
6. **`data:` URL 的 JSON 语义**：响应构造下沉后，`response.json()` 的 JS 解析仍在绑定层（wpt 有
   "correct JSON parser" 相关用例，注意不引入 C++ 侧 JSON 解析）。
7. **expected 清单**（KI-055，28 个 expected 口径）不增不减；迁移中若行为微差导致 expected 变化，
   先修行为再登记，不许直接改 expected 充数。
8. **调度器适配复制**：`io_context_scheduler` 等适配设施从 qjsbind 下沉为核心库内部件时，注意 qjsbind 侧
   改为复用核心库版本，避免两份实现漂移。

## 8. 目录与 CMake 目标建议

```
include/fetch/                 # fetchcore 公共头（纯 C++；禁止 include quickjs/qjsbind 头）
  task.hpp                     #   stdexec 别名（std_exec.hpp 等价物）
  types.hpp                    #   Header/Headers/Request/Response/Options/TlsOptions
  formdata.hpp                 #   FormData 条目表 + multipart 编解码（encode/parse_multipart）
  body.hpp                     #   BodySource + read_all
  middleware.hpp               #   Middleware/Handler/链组装 + 内建中间件（解压/SOCKS5 选路）
  client.hpp                   #   Client
  transport.hpp                #   Transport 抽象
  error.hpp                    #   fetch::Error（可拷贝）
src/fetch/                     # 实现（可由 src/net/ 演进，改名与否均可）
  beast_transport.{hpp,cpp}    #   现 http_client 演进（含 BeastBodySource）
  socks5.{hpp,cpp}             #   原样
  cacert_embedded.hpp          #   原样（脚本生成）
include/qjsbind/web/           # 绑定层（变薄）
  fetch.hpp                    #   仅 JS⇄C++ 适配
  net.hpp / interceptor.hpp    #   删除（迁入 fetchcore）
  stream.hpp / request_response.hpp / headers.hpp / ...   # 保留，BodySource 改引 fetch/body.hpp

CMake：
  fetchcore  STATIC   —— Boost::asio Boost::url OpenSSL::SSL OpenSSL::Crypto ZLIB brotlidec brotlicommon stdexec
  qjsbind    INTERFACE—— 追加链接 fetchcore
  qjsbind_net          —— 由 fetchcore 取代后删除（lexbor 依赖移回 cheerio 相关 target）
```

## 9. 验收清单

- [ ] fetchcore 独立可编：头文件树 grep 无 `quickjs`/`qjsbind` include，target 不链接 qjs。
- [ ] C++ 直连用例（不建 JSRuntime）：GET/HTTPS/流式读/解压/SRI/data:/abort/SOCKS5 全过（打 WptTestServer）。
- [ ] `fetch::Client` 可在函数局部作用域随手构造，多实例共用同一 io 互不干扰（用例覆盖）。
- [ ] wpt 精选子集：510 pass / 0 fail / expected 数不增；全量 ctest 绿。
- [ ] JS 全局对象无中间件注册/枚举 API（`install_web_apis(ctx, Client&)` 为唯一注入点）。
- [ ] 文档同步：`fetch_design.md` / `known_issues.md` / `AGENTS.md` 更新。
