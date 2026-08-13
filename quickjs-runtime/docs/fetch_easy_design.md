# fetch::easy 设计文档 —— reqwest 风格请求层

> 状态：**设计提案（未实现）**，2026-08-09
> 前提：fetchcore 已稳定（`include/fetch/`，见 `docs/fetch_cpp_decoupling.md`），
> 本文档只设计、不含实现。实现时按 §10 里程碑推进。
> 语言标准：**C++23**（决策见 §5.3，已确认可升）。
> 硬约束：**不改 fetchcore 任何现有接口**；本层是对 `fetch::Client` 的纯包装。

## 0. 动机

fetchcore 功能完善，但 C++ 侧裸用的样板太多。现状发一个带超时的 JSON POST：

```cpp
// 现状：手工拼 Request、手工桥 stop_token、手工整读 body、手工解析 JSON
fetch::Request req;
req.method = "POST";
req.url = "https://api.example.com/users";
req.headers.push_back({"Content-Type", "application/json"});
req.body = R"({"name":"tom"})";

std::stop_source src;
// ... 自己起定时器、自己 request_stop、自己 when_any ...
fetch::Response resp = co_await client.fetch(std::move(req), src.get_token());
std::string text = co_await fetch::read_all(resp);   // 整读
// ... 自己找库解析 JSON、自己判 status ...
```

目标形态（reqwest 风格，全部组合子来自执行器模型）：

```cpp
auto resp = co_await client.post("https://api.example.com/users")
    .bearer_auth(token)
    .json(User{.name = "tom"})          // glaze 序列化 + 自动 Content-Type
    .timeout(5s)                        // when_any(请求, 定时器)
    .retry(easy::retry_policy{}.max_retries(3))   // 自定义重试算子
    .send();

auto user = co_await resp.error_for_status().json<User>();  // glaze 反序列化
```

## 1. 范围与非目标

**做**：

- reqwest 风格的 `Client` / `ClientBuilder` / `RequestBuilder` / `Response` 流式 API
- 超时：纯算子组合（`exec::when_any` + 已有 `dcb::asio_sleep`），不写专用定时逻辑
- 重试：自定义 sender 算子（factory 形态，原因见 §6.3）+ `RequestBuilder::retry` 糖
- JSON：glaze 默认序列化/反序列化；保留手动 `body()` / `header()` 逃生舱
- 错误模型：单一 `Error` 类型 + `kind()` 分类（reqwest::Error 风格）

**不做**（明确边界）：

- 不改 `include/fetch/` 任何头文件、不改 `fetch::Client` 任何行为
- 不碰 JS 绑定层（`qjsbind::web`）——本层只服务 C++ 调用方
- 不做连接池（BeastTransport 现状即每请求新连接；池化是传输层未来的事，与本层无关）
- 不做 cookie jar、CORS、cache——fetchcore 同样没有
- **不提供同步阻塞接口**（`sync_wait` 风格）：Client 契约要求跑在 io 线程上，
  在 io 线程上 `sync_wait` 会自死锁；要阻塞用法请在自己的线程跑 `io.run()`，
  本层不为此开口子
- 不做流式上传（fetchcore 的 `Request::body` 就是整收 string）

## 2. 分层与文件布局

```
调用方
  │
  ▼
fetch::easy（本层，header-only，新增）        ← 只有本层是新代码
  │  Client / RequestBuilder / Response / Error / retry / timeout
  │  全部转调 ↓
  ▼
fetch::Client（fetchcore，零改动）
  │  redirect 循环 / 中间件链 / SRI / data: / 解压
  ▼
fetch::Transport（BeastTransport，零改动）
```

新增文件（全部 header-only，挂在现有 `fetchcore` target 的 include 目录）：

| 文件                             | 内容                                                             |
| -------------------------------- | ---------------------------------------------------------------- |
| `include/fetch/easy.hpp`         | 伞头：Client / ClientBuilder / RequestBuilder / Response / Error |
| `include/fetch/easy/form.hpp`    | multipart：`Form` / `Part`（reqwest::multipart 对照，§3）        |
| `include/fetch/easy/retry.hpp`   | 重试算子 + `retry_policy` / 退避策略                             |
| `include/fetch/easy/timeout.hpp` | 超时组合子（`when_any` 包装，内部设施）                          |
| `tests/fetch_easy_test.cpp`      | 测试（复用 `wpt_server.hpp` / `tls_echo_server.hpp`）            |

命名空间 `fetch::easy`（双关：curl easy handle + "简单模式"）。依赖方向：
`fetch/easy/* → fetch/client.hpp + dart_cpp_bridge/sleep.hpp + glaze + stdexec`。
禁止反向依赖，fetchcore 编译时不知道本层存在。

## 3. API 总览（reqwest 对照）

| reqwest                                                          | fetch::easy                                            | 备注                                                 |
| ---------------------------------------------------------------- | ------------------------------------------------------ | ---------------------------------------------------- |
| `Client::builder()`                                              | `easy::Client::builder()`                                | io 取当前线程 thread_local（`fetch::set_thread_io`，同 fetch::Client 契约） |
| `ClientBuilder::{timeout, user_agent, default_headers}`          | 同名                                                   | 默认值，逐请求可覆盖                                 |
| `ClientBuilder::build()`                                         | `.build()`                                             | 内含一个 `fetch::Client`                             |
| `client.get/post/put/patch/delete/head(url)`                     | 同名                                                   | 返回 `RequestBuilder`                                |
| `RequestBuilder::header(k,v)`                                    | 同名                                                   | 可重复调用                                           |
| `RequestBuilder::basic_auth / bearer_auth`                       | 同名                                                   | basic 用 `fetch::base64_encode`（types.hpp 已有）    |
| `RequestBuilder::query(&params)`                                 | `.query({{"k","v"},...})`                              | form-urlencode 后拼到 URL                            |
| `RequestBuilder::json(&body)`                                    | `.json(const T&)`                                      | glaze 序列化 + 自动 `Content-Type: application/json` |
| `RequestBuilder::form(&form)`（urlencoded）                      | `.form_urlencoded({{"k","v"},...})`                    | `k=v&...`，空格 → `+`（同 UrlSearchParams 序列化）；自动 `Content-Type: application/x-www-form-urlencoded` |
| `RequestBuilder::body(bytes)`                                    | `.octet_stream(data)`                                  | 原始字节 + 自动 `Content-Type: application/octet-stream` |
| `reqwest::multipart::Form`                                       | `easy::Form`（`text/part/file` 链式）                  | 底层 = fetchcore `fetch::FormData` + `encode_multipart` |
| `reqwest::multipart::Part`                                       | `easy::Part`（`bytes` + `file_name`/`mime`）           | `file()` 默认流式（大文件不整读进内存）：MultipartEncoder 预计算总长走 Content-Length；文件读取切到进程级文件线程池 `fetch::file_pool()`（默认 4×用户线程数，惰性初始化；`MultipartEncoder::create` 可注入自定义池）执行——慢存储不卡 io_context 事件循环，读毕切回 io 线程再写网络；mime 可选覆盖，缺省按扩展名猜（`Form::guess_mime`）；文件打不开延迟到 send 抛 decode |
| `RequestBuilder::multipart(form)`                                | 同名                                                   | 自动随机 boundary + `Content-Type: multipart/form-data; boundary=...`（缺省才填） |
| `RequestBuilder::body(x)`                                        | `.body(std::string)`                                   | 手动请求体（逃生舱）                                 |
| `RequestBuilder::timeout(d)`                                     | 同名                                                   | 每次尝试独立计时（§6.2）                             |
| `RequestBuilder::send()`                                         | 同名                                                   | 返回**惰性 sender**（`std_exec::task<Response>`）    |
| `Response::{status, headers, url}`                               | 同名                                                   | `status()` 返回 int                                  |
| `Response::error_for_status()`                                   | 同名                                                   | 4xx/5xx → 抛 `Error{kind::http_status}`              |
| `Response::{text, bytes, json::<T>()}`                           | `co_await resp.text() / .bytes() / .json<T>()`         | 消费 body；受剩余 deadline 约束                      |
| `reqwest::Error::{is_timeout, is_connect, is_decode, is_status}` | `Error::kind()` + `is_timeout()` 等便捷谓词            | §5.1                                                 |
| reqwest-retry 中间件                                             | `.retry(policy)` + `easy::retry(factory, policy)` 算子 | §6.3                                                 |

fetchcore 特有能力的透出（不削弱现有功能）：

- `ClientBuilder::options(fetch::Options)`：重定向上限/自动解压/TLS 配置
- `ClientBuilder::use(std::shared_ptr<fetch::Middleware>)`：原样转调 `Client::use()`
  （SOCKS5/HTTP 代理中间件即走此路）
- `ClientBuilder::transport(std::shared_ptr<fetch::Transport>)`：注入自定义传输
- `RequestBuilder::redirect(fetch::Request::Redirect)` / `.integrity(sri)`：透传字段
- `Response::raw()` → `const fetch::Response&`：要流式拉 body（`BodySource`）时走这里

快速上手（设计目标形态）：

```cpp
namespace easy = fetch::easy;

fetch::set_thread_io(io);                        // 先绑定当前线程的 fetch io

auto client = easy::Client::builder()
    .user_agent("my-app/1.0")
    .default_header("Accept", "application/json")
    .timeout(30s)                                  // 默认逐请求超时
    .retry(easy::retry_policy{}.max_retries(2))    // 默认重试策略
    .build();

// 最简单：GET + JSON 反序列化
auto resp = co_await client.get("https://api.example.com/users/1").send();
if (resp.ok()) {
    User u = co_await resp.json<User>();
}

// 手动 body + 手动 JSON 头（glaze 之外的逃生舱）
auto resp2 = co_await client.post(url)
    .header("Content-Type", "application/json")    // 自己设头
    .body(R"({"raw":true})")                        // 自己给体
    .send();

// 一次性用法（无复用需求时）
auto resp3 = co_await easy::get("https://example.com").send();
```

## 4. 类型设计

### 4.1 Error

```cpp
enum class error_kind {
    network,     // 连接/DNS/TLS/读写（包装 boost::system::system_error）
    timeout,     // when_any 中定时器分支胜出
    decode,      // glaze 解析失败 / body 读取失败
    http_status, // error_for_status() 命中 4xx/5xx（带 status()）
    url,         // URL 非法（send 时校验）
    policy,      // fetch::Error（重定向超限/SRI/端口封禁等策略错误）
};

class Error : public std::exception {
public:
    error_kind kind() const noexcept;
    std::optional<int> status() const noexcept;   // 仅 http_status
    const char* what() const noexcept override;
    bool is_timeout() const noexcept;             // kind()==timeout，便捷谓词
    bool is_network() const noexcept;
    bool is_decode() const noexcept;
    bool is_status() const noexcept;
    // 可拷贝（KI-051：MSVC 协程传播 move-only 异常会损坏，与 fetch::Error 同一教训）
};
```

映射规则（catch 顺序即分类顺序）：

| 来源                                                  | → kind        |
| ----------------------------------------------------- | ------------- |
| 定时器分支胜出                                        | `timeout`     |
| `boost::system::system_error`                         | `network`     |
| `fetch::Error`                                        | `policy`      |
| glaze `error_ctx` / body read 抛出的 `std::exception` | `decode`      |
| `error_for_status()`                                  | `http_status` |

**取消不是错误**：外层 stop 导致 `set_stopped` 时沿协程链原样传播
（`exec::task` 的 `unhandled_stopped` 语义），不包成 `Error`。调用方要区分
"被取消"用 `stopped_as_optional`，与本仓库既有惯例一致（cpp26_executor_model_usage.md §8.4）。

### 4.2 Client / ClientBuilder

```cpp
class Client {
public:
    static ClientBuilder builder();

    RequestBuilder get(std::string url);
    RequestBuilder post(std::string url);
    RequestBuilder put(std::string url);
    RequestBuilder patch(std::string url);
    RequestBuilder del(std::string url);       // delete 是关键字
    RequestBuilder head(std::string url);

    // 逃生舱：直接暴露底层（只读），取 io/中间件能力用
    const fetch::Client& core() const noexcept;
};
```

- `Client` 内部持有一个 `fetch::Client`（值成员，非指针）；拷贝/移动语义同
  `fetch::Client`（其成员均可拷贝：`io_context&` 引用 + 值 Options + shared_ptr vector）。
- 线程与生命周期契约**完全继承** fetch::Client（client.hpp 头部注释 §1-4）：
  io 必须比 Client 及在飞请求活得久；只能从跑 `io.run()` 的线程使用。
- 默认值（`user_agent`/`default_header`/`timeout`/`retry_policy`）以值存在
  Client 里，`get()` 等方法构造 RequestBuilder 时拷入。

```cpp
class ClientBuilder {
public:
    ClientBuilder& user_agent(std::string);
    ClientBuilder& default_header(std::string name, std::string value);
    ClientBuilder& timeout(std::chrono::milliseconds);   // 0 = 不超时（默认）
    ClientBuilder& retry(retry_policy);
    ClientBuilder& options(fetch::Options);              // 透传 fetchcore 配置
    ClientBuilder& use(std::shared_ptr<fetch::Middleware>);
    ClientBuilder& transport(std::shared_ptr<fetch::Transport>);
    Client build();
};
```

### 4.3 RequestBuilder

```cpp
class RequestBuilder {
public:
    RequestBuilder& header(std::string name, std::string value);
    RequestBuilder& bearer_auth(std::string_view token);
    RequestBuilder& basic_auth(std::string_view user, std::string_view pass);
    RequestBuilder& query(std::initializer_list<std::pair<std::string,std::string>>);

    template <typename T> RequestBuilder& json(const T& obj);  // §7
    RequestBuilder& body(std::string);                          // 手动体（逃生舱）

    RequestBuilder& timeout(std::chrono::milliseconds);  // 覆盖 Client 默认
    RequestBuilder& retry(retry_policy);                 // 覆盖 Client 默认
    RequestBuilder& redirect(fetch::Request::Redirect);  // 透传（默认 follow）
    RequestBuilder& integrity(std::string sri);          // 透传 SRI

    std_exec::task<Response> send();   // 惰性：不 co_await / connect 就不发
};
```

- `send()` 内部把 RequestBuilder 的值固化为 `fetch::Request`：默认头先铺、
  逐请求头后盖（同名后者追加，与 fetchcore 的 Headers 多值语义一致）；
  URL 在此刻用 ada 校验，非法 → 返回的 task 以 `Error{url}` 失败
  （不在 builder 链上同步抛，保证错误出口统一在 `co_await` 处）。
- method 由 `client.get/post/...` 决定；GET/HEAD 带 body 时在 send 时报
  `Error{policy}`（与 fetchcore 语义对齐：GET/HEAD 禁 body）。

### 4.4 Response

```cpp
class Response {
public:
    int status() const noexcept;
    bool ok() const noexcept;                    // [200,300)
    const fetch::Headers& headers() const noexcept;
    const std::string& url() const noexcept;     // 最终 URL（重定向后）
    bool redirected() const noexcept;

    Response& error_for_status() &;              // 4xx/5xx → 抛 Error{http_status}，否则返回 *this
                                           // 便于链式：resp.error_for_status().json<T>()

    std_exec::task<std::string> text();                  // 整读（read_all）
    std_exec::task<std::vector<std::byte>> bytes();
    template <typename T> std_exec::task<T> json();      // 整读 + glaze

    const fetch::Response& raw() const noexcept; // 逃生舱：流式 BodySource 在这里

    // 取消消费：放弃读取时调（转调 BodySource::cancel，幂等）
    void cancel() noexcept;
};
```

- `text()/bytes()/json()` 只能消费一次（body 是拉模型流）；重复消费抛
  `Error{policy, "body already consumed"}`。
- 消费受超时 deadline 约束（§6.2 的"全程语义"）。

## 5. JSON（glaze）

### 5.1 请求侧

```cpp
template <typename T>
RequestBuilder& json(const T& obj) {
    // glz::write_json(obj) 返回 glz::expected<std::string, error_ctx>：
    //   有值 → 存为 body；失败 → 记下 error_ctx，send() 时以 Error{decode} 失败
    // 自动 Content-Type: application/json（仅当用户未手动设置过该头——手动优先）
}
```

- 手动逃生舱优先级更高：`.header("Content-Type", ...)` + `.body(...)` 与
  `.json(...)` 同用时，**后调用者覆盖 body，但用户显式设置的头永远不被自动头
  覆盖**（规则一句话：自动头只在缺省时填）。
- `T` 的要求即 glaze 的要求：聚合体直接反射（C++23 + glaze v5 开箱即用），
  非聚合/私有成员提供 `glz::meta` 特化。

### 5.2 响应侧

```cpp
template <typename T>
std_exec::task<T> Response::json() {
    std::string s = co_await text();             // 同 read_all 路径，含 deadline
    // glz::read_json<T>(s) 返回 glz::expected：失败时 error_ctx 经
    // glz::format_error(ec, s) 生成带行列号的消息 → 抛 Error{decode}
}
```

- 大 body 防护沿用 fetchcore 现状：传输/解压侧上限（`max_decompressed_bytes`）
  已有；本层不另加 JSON 大小限制。
- 不要 `json<T>()` 的异步增量解析（glaze 有 partial read 能力，v1 不用：
  先整读再解析，与 reqwest 行为一致）。

### 5.3 glaze 版本与 C++ 标准（已决策：升 C++23）

背景事实：glaze v3.0.0 起要求 C++23，v2.9.5 是最后一个 C++20 版本
（[stephenberry/glaze Discussion #1715](https://github.com/stephenberry/glaze/discussions/1715)、
[glaze README](https://github.com/stephenberry/glaze)）。

**决策（2026-08-09，已确认）：项目升级为 C++23，glaze 用 vcpkg 最新 port，
不钉版本、无 overrides。** 相对钉 2.9.5 旧版的收益：

- glaze v5 的反射更完整、错误信息带行列号、性能更好；`read_json` / `write_json`
  返回 `glz::expected<T, error_ctx>`，与本层 `Error{decode}` 的转换点干净
- 无版本钉子，后续 glaze 升级随 vcpkg 滚动

升级动作（E0 完成，见 §10）：

- CMake：`target_compile_features(... cxx_std_23)`（仓库当前用 vc145 工具链，
  C++23 支持完整；Clang 侧 `-std=c++23`）
- `vcpkg.json`：`dependencies` 加 `"glaze"`；描述行 "C++20" 更新为 C++23
- 全量重编核对：stdexec（要求 C++20 起，向上兼容）、boost、quickjs-ng 等既有
  依赖在 C++23 下编译 + 既有测试零回归，然后才开始本层开发
- 实现时核对点：`glz::write_json` / `read_json` / `format_error` 的确切签名
  以落地时 vcpkg port 版本为准，本文档不逐字锚定

## 6. 执行器模型设计（核心）

### 6.1 send() 是惰性 sender

`send()` 返回 `std_exec::task<Response>`——task 本身就是 sender：

```cpp
// 三种消费方式都合法：
auto resp = co_await client.get(url).send();                    // 1) 协程里直接等
auto s    = client.get(url).send();                             // 2) 不启动
exec::when_any(std::move(s), other_sender);                     //    参与自由组合
stdexec::spawn(client.get(url).send() | stdexec::then(f), tok); // 3) spawn 出去
```

惰性的意义：**`.timeout()/.retry()` 只是给 sender 配方再包一层，组合期间
零网络副作用**；直到被 `co_await` / `connect` 才真正发请求。

### 6.2 超时 = when_any(请求, 定时器)

按用户要求纯算子组合，一个请求 sender + 一个定时器 sender，`exec::when_any` 竞速：

```cpp
// timeout.hpp 的概念形态（实现时落到具体类型；io 取当前线程 thread_local）
std_exec::task<fetch::Response> with_timeout(fetch::Client& core,
                                             fetch::Request req,
                                             std::chrono::milliseconds d)
{
    auto& io = fetch::thread_io(); // 入口捕获，协程内固定
    // 取消桥接：把 env 的 stop token（when_any 的 inplace_stop_token）
    // 翻译成 Client::fetch 要的 std::stop_token —— 见下方"桥接"小节。
    auto env_tok = co_await stdexec::get_stop_token();
    std::stop_source src;
    stdexec::stop_callback_for_t<decltype(env_tok), /*fn*/> bridge{env_tok,
        [&] { src.request_stop(); }};

    co_return co_await exec::when_any(
        core.fetch(std::move(req), src.get_token()),      // 分支 1：请求
        dcb::asio_sleep(io, d)                            // 分支 2：同 io 上的定时器
            | stdexec::then([]() -> fetch::Response {
                  throw Error(error_kind::timeout, "request timed out");
              }));
}
```

要点与设计取舍：

1. **定时器后端必须是 `dcb::asio_sleep(io, …)`**，不是默认的 `dcb::sleep`。
   后者在独立 `timed_thread_context` 线程上完成，`when_any` 胜出后协程会在
   定时线程上 resume，违反 Client 的单线程 io 契约；asio 定时器在 io 线程上
   完成，全链路保持单线程，也省一个线程。
2. **分支值签名对齐**：`when_any` 的完成签名是各分支并集，定时器分支的
   `then` 返回类型必须与请求分支一致（`fetch::Response`）——它永不正常返回
   （进了函数体就 throw），但要让编译期签名收敛。这是 `when_any` 的标准用法
   陷阱（cpp26_executor_model_usage.md §8.5 同款）。
3. **胜负语义**：请求先完成 → 定时分支被 `request_stop` 取消（asio_sleep 的
   取消路径已验证安全，sleep.hpp 头部注释）；定时先触发 → `when_any` 以
   `set_error(timeout Error)` 完成，请求分支收到停止信号。
4. **取消桥接（关键细节）**：`Client::fetch` 吃 `std::stop_token`（std 类型），
   而 `when_any` 给败者分支的是 env 里的 `inplace_stop_token`（stdexec 类型），
   两者不互通。桥法：easy 层每次尝试持有一个 `std::stop_source`，
   用 `stop_callback_for_t` 挂到 env token 上，触发时 `src.request_stop()`——
   于是 `when_any` 判负 → 传输层 socket cancel（Client 文档化取消路径）→
   连接立刻拆除，而不是等协程帧销毁的兜底路径。
5. **deadline 全程语义（reqwest 对齐）**：`.timeout(d)` 覆盖「请求发出 →
   body 消费完」全程。实现：send 入口记 `deadline = steady_clock::now() + d`，
   存入 `Response`；`text()/bytes()/json()` 消费时以 `deadline - now()`
   的**剩余量**再组一次同款 `when_any(read_all, asio_sleep)`；剩余 ≤ 0 直接
   抛 timeout。消费超时后 `Response::cancel()`（`BodySource::cancel`，幂等）
   拆掉底层连接。不消费 body（只看头）则只有首段计时生效。
6. 无超时（`d == 0`）时不组 `when_any`，原样返回请求 sender——零开销路径。

### 6.3 重试 = 自定义算子

**为什么不是 `sndr | retry(p)` 管道形态**：sender 是**单发**的——`exec::task`
只能 `connect` 一次，失败后无法原地重启。重试的本质是「重新构造一个新操作」，
所以算子必须吃**工厂**而不是吃 sender：

```cpp
// retry.hpp 的公开形态：
template <typename Factory>
std_exec::task<Response> retry(Factory&& make_attempt, retry_policy policy);
// 要求：make_attempt() -> std_exec::task<Response>（每次调用产出一次全新尝试）
```

概念实现（协程循环；task 本身是 sender，所以返回值照样可组合）：

```cpp
template <typename Factory>
std_exec::task<Response> retry(Factory make_attempt, retry_policy policy)
{
    for (int attempt = 0;; ++attempt) {
        try {
            Response resp = co_await make_attempt();
            if (!policy.should_retry_status(resp.status()) || attempt >= policy.max_retries)
                co_return resp;
            // 状态码可重试：先按 Retry-After/退避等待，再进入下一轮
            co_await dcb::asio_sleep(io, policy.delay_for(attempt, resp));
        } catch (const Error& e) {
            if (!policy.should_retry_error(e.kind()) || attempt >= policy.max_retries)
                throw;
            co_await dcb::asio_sleep(io, policy.delay_for(attempt, std::nullopt));
        }
        // 取消（set_stopped）不经 catch：沿协程链传播，绝不重试
    }
}
```

实现备注：**v1 用协程循环落地**（如上）；「真·P2300 管道 adaptor」
（自带 opstate 状态机：attempt → error → backoff 子 opstate → re-connect）
只算换了个启动机制，可观察行为与协程版完全一致，但代码量与 review 成本高一截。
留作未来演进项，不进 v1。对外暴露的 `easy::retry(factory, policy)` 返回值
就是 sender，调用方感知不到差别。

`retry_policy`（reqwest-retry 对照设计）：

```cpp
struct retry_policy {
    int max_retries = 2;                          // 额外尝试次数（不含首发）

    // 指数退避：delay_n = min(max_delay, base * factor^n)，±jitter 抖动
    std::chrono::milliseconds base_delay = 100ms;
    std::chrono::milliseconds max_delay  = 10s;
    double factor = 2.0;
    bool jitter = true;

    bool respect_retry_after = true;              // 429/503 带 Retry-After 时优先采用（封顶 max_delay）
    bool retry_non_idempotent = false;            // 默认只重试幂等方法（GET/HEAD/PUT/DELETE/OPTIONS）

    // 分类规则（可用回调覆盖）：
    //   错误：timeout/network 可重试；decode/url/policy/http_status 不可；stopped 永不重试
    //   状态码：408/429/5xx 可重试，其余不可
    std::function<bool(const Error&)> should_retry_error_override;   // 空 = 用默认规则
    std::function<bool(int status)> should_retry_status_override;
};
```

- **组合顺序**：`retry` 包住「带超时的单次尝试」——即
  `retry([]{ return with_timeout(...); }, policy)`。超时是**每次尝试独立计时**，
  重试间的退避不占超时预算。要"总预算"语义的调用方自己在最外层再组一个
  `when_any`（这正是不收进库里的理由：一层一个语义，组合留给调用方）。
- body 可重放是安全的：`fetch::Request::body` 是值语义的 string，工厂每次
  从 RequestBuilder 的固化快照重建完整 Request。
- `RequestBuilder::retry(policy)` 是上述算子的糖：捕获固化的 Request + io +
  弱化的 core 引用，生成工厂后转调 `easy::retry`。

### 6.4 一条请求的完整装配顺序

`send()` 内部（概念）：

```
固化 fetch::Request（默认头/方法/query/json body）
  → attempt = with_timeout(core, io, req, timeout)      // §6.2，无超时则直通
  → pipeline = retry([&]{ return attempt(); }, policy)  // §6.3，无策略则直通
  → co_await pipeline
```

每一层都是可选包装，无对应配置时零成本直通。

## 7. 语义速查表

| 主题     | 语义                                                                             |
| -------- | -------------------------------------------------------------------------------- |
| 惰性     | `send()` 不启动；`co_await`/`connect` 才发请求                                   |
| 取消     | 外层 stop → `set_stopped` 原样传播，不包 Error；重试永不拦截 stopped             |
| 超时     | deadline 覆盖「发送 → body 消费完」；每次重试独立计时；超时后底层连接被 cancel   |
| 线程     | 单线程 io：全部完成/回调/定时器都在 io 线程；契约与 fetch::Client 完全一致       |
| 生命周期 | io > Client > 在飞操作；Response 不保有 Client（resp 消费只依赖自身 BodySource） |
| 错误     | 单类型 `Error` + `kind()`；`what()` 带人读消息；`status()` 仅 http_status 有值   |
| body     | 整读一次；重复消费抛 policy 错误；流式需求走 `raw()`                             |
| 头       | 自动头（Content-Type/json、Accept 默认）只在缺省时填；显式设置永远优先           |

## 8. 依赖与构建变更

1. `vcpkg.json`：加 `"glaze"`（最新 port，不钉版本）；语言标准升 C++23（§5.3）。
   其余（stdexec/asio）均已是项目依赖，`dcb::asio_sleep` 已存在——**除 glaze 外零新依赖**。
2. `CMakeLists.txt`：`target_compile_features(... cxx_std_23)`；`fetchcore` target
   （或新 `fetch_easy` INTERFACE target）`target_link_libraries` 加 `glaze::glaze`；
   本层 header-only，不加源文件。
3. glaze 头文件很重（编译期反射），`easy.hpp` 的 json 模板集中在
   `easy/json.hpp`，只在用到 `.json()` 时才会实例化——不污染只用 text() 的
   编译单元。伞头默认包含；提供 `FETCH_EASY_NO_JSON` 宏可剔除 glaze 依赖
   （供不想引 glaze 的下游用）。

## 9. 测试计划（tests/fetch_easy_test.cpp）

复用现有设施：`wpt_server.hpp`（status/redirect/echo/inspect-headers 端点）、
`tls_echo_server.hpp`、fetchcore_test.cpp 的 Probe/ScopeJoiner 驱动。

| 用例                             | 验证点                                                        |
| -------------------------------- | ------------------------------------------------------------- |
| `Easy.GetJson`                   | builder → send → `json<T>()` 反序列化聚合体                   |
| `Easy.PostJsonEcho`              | `.json(obj)` 自动头 + 序列化正确（echo 端点回显）             |
| `Easy.ManualBodyHeader`          | 手动 body + 手动 Content-Type 优先于自动头                    |
| `Easy.TimeoutFires`              | 慢端点（wpt server 延时）→ `kind()==timeout`，且耗时 ≈ 设定值 |
| `Easy.TimeoutCancelsSocket`      | 超时后服务器侧看到连接断开（取消桥接生效）                    |
| `Easy.NoTimeoutPassThrough`      | 无超时不组 when_any（行为直通）                               |
| `Easy.RetryOn5xx`                | 服务器前 N 次 503 → 成功；断言到达次数 == N+1                 |
| `Easy.RetryExhausted`            | 永远 503 → 返回最后一次的 Response                            |
| `Easy.RetryNeverOnDecode`        | 非法 JSON → decode 错误不重试（到达次数 == 1）                |
| `Easy.RetryNonIdempotentDefault` | POST + 503 默认不重试；开关打开后重试                         |
| `Easy.RetryAfterHonored`         | 429 + Retry-After: 1 → 退避 ≥ 1s                              |
| `Easy.DeadlineCoversBody`        | 头快 body 慢 → text() 抛 timeout（deadline 全程语义）         |
| `Easy.ErrorForStatus`            | 404 → `error_for_status()` 抛 http_status 且带 status()       |
| `Easy.CancelPropagatesStopped`   | 外层 stop_source 取消 → stopped，非 Error，不重试             |
| `Easy.RawEscapeHatch`            | `raw()` 流式读与 fetchcore 直读结果一致                       |

## 10. 里程碑

| 阶段 | 内容                                                                                          | 验收                                           |
| ---- | --------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| E0   | C++23 升级 + glaze 依赖引入（§5.3），本层尚未开工                                             | 全量重编通过、既有测试零回归                   |
| E1   | Error + Client/ClientBuilder/RequestBuilder/Response 骨架 + text()/bytes() + 手动 body/header | `GetJson` 外的基本用例过                       |
| E2   | glaze 接入：`.json()` / `json<T>()`                                                           | `GetJson`/`PostJsonEcho`/`ManualBodyHeader` 过 |
| E3   | 超时算子（when_any + 取消桥接 + deadline）                                                    | `Timeout*`/`DeadlineCoversBody` 过             |
| E4   | 重试算子 + retry_policy + RequestBuilder::retry                                               | `Retry*` 过                                    |
| E5   | error_for_status、query、basic/bearer、raw()、一次性自由函数                                  | 全量过 + 既有 fetchcore/wpt 测试零回归         |

## 11. 风险与核对点

1. **C++23 升级连带面**：E0 独立落地（改标准 + 重编 + 全量回归）后再开始本层
   开发，避免两把火一起烧。重点核对 MSVC 与 Clang 双端、quickjs-ng 的 C 接口
   编译单元、stdexec 在 C++23 下的概念检查路径。
2. **`when_any` 分支签名**：定时器分支 `then` 的返回类型必须与请求分支严格
   一致，否则完成签名并集出现两种 `set_value` 形态，`co_await` 解包歧义——
   编译期就会炸，实现时第一眼就能看到（E3 先写最小编译验证）。
3. **取消桥接的 token 类型**：桥接回调的类型用
   `stdexec::stop_callback_for_t<Token, Fn>` 从 env token 推导，不手写
   `inplace_stop_callback`——env token 的确切类型随组合上下文变化
   （裸 connect 时甚至可能是 `never_stop_token`，桥接代码要对"不可取消"
   退化为零开销，`stop_callback_for_t` 对 never_stop_token 天然满足）。
4. **`exec::task` 的 env 透传**：when_any 子任务里 `co_await get_stop_token()`
   拿到的是 when_any 共享源的 token（§8.5/§8.7 已验证同款透传），桥接依赖此行为；
   若 stdexec 版本升级漂移，`TimeoutCancelsSocket` 用例会立刻暴露。
5. **Response 与 Client 的生命周期解耦**：Response 只持有 `fetch::Response`
   （其 BodySource 自持 socket），不反向引用 Client——Client 析构后读 body 的
   行为与 fetchcore 现状一致（BodySource 自持有），文档化即可，不加引用计数。
