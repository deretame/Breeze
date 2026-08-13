# fetch 流式 body + 自动解压 设计文档（v2）

> 状态：已实现（M1–M4 全部完成，2026-08；全量 120/120 测试绿，含 wpt 精选子集）。
> v1 设计见 `docs/fetch_design.md`（整收式 body）。实现落点：`include/qjsbind/web/stream.hpp`（流绑定）、
> `include/qjsbind/web/interceptor.hpp`（拦截器/解压/SRI/代理选路）、`src/net/socks5.{hpp,cpp}`（SOCKS5 握手/隧道）。
> 范围：① ReadableStream + `response.body.getReader()` 流式读取；② 自动 `Accept-Encoding` + 透明解压（以拦截器机制实现）。

## 1. 目标与非目标

### 目标

- `fetch()` 在**响应头到达时**即 resolve（不再等全量 body），`response.body` 返回 `ReadableStream`
- `ReadableStream` / `ReadableStreamDefaultReader` 子集：`getReader()` / `read()` / `cancel()` / `releaseLock()` / `locked` / `closed`
- `text()/json()/arrayBuffer()/bytes()/blob()/formData()` 改为"读干流"实现，JS 侧行为不变
- 拦截器管线：around 模型协程链（`co_await next` 分界前置/后置），全链路 `exec::task`——写法同步、全程非阻塞；内建 `AcceptEncodingInterceptor`：自动加 `Accept-Encoding: gzip, deflate, br`，按 `Content-Encoding` 透明解压
- SOCKS5 代理：拦截器按策略选路（直连 / 代理隧道交换）；握手机制在 net 层，支持无认证与 username/password（§3.4、§5.7）

### 非目标（v2 不做）

- JS 侧构造自定义流（`new ReadableStream({start, pull, cancel})`）、`tee()` 公开、`pipeTo/pipeThrough`、`TransformStream`、BYOB reader —— 机制预留，见 §7
- 请求侧流式上传（Request body 仍为字节；spec 的 `duplex` 字段不做）
- HTTP CONNECT 代理、SOCKS4 不做（后续按需）
- CORS / credentials / cache 等 v1 既有边界不变

## 2. 总体架构

```
【请求路径：协程链（around 拦截器逐层嵌套，每一跳都走全链）】
fetch_impl（redirect 循环）
        │ co_await I₁.intercept(req, st, next)
        │     └─ co_await I₂.intercept(req, st, next)
        │           └─ … 链尾默认直连 backend->request；
        │                代理拦截器可不调 next、改走 SOCKS5 隧道交换（§5.7）
        │ ◀── co_return 途中逐层加工 head / 包装 body（如 DecompressSource）
        ▼
ResponseImpl.body_stream ── ReadableStreamImpl（queue + reader 槽 + disturbed/locked）

【读取路径：拉模型协程链】
JS reader.read()  →  co_await ReadableStreamImpl.pull
                          └─ co_await DecompressSource.read()（拦截器包装，可多层嵌套）
                                └─ co_await BeastBodySource.read()
                                      └─ co_await http::async_read_some（64 KiB 块）
                                            └─ beast stream（tcp / ssl）
```

两条路径都是 `exec::task` 协程链：**写法是同步顺序的，但每个 `co_await` 点都不阻塞 io 线程**。唯一的同步例外是 `BodySource::cancel()`——它是命令式动作，由 `stop_callback` 触发（可能跨线程），不能是协程。

关键决策：**读取路径全链路拉（pull）模型**。`read()` 才触发一次网络读，不预读、不后台 pump——TCP 窗口自然形成背压，且取消/错误路径单一。io 单线程（Runtime 的 io_context 跑在 JS 线程），流内部状态无需锁；仅 `stop_callback` 可能跨线程触发（沿用 v1 注释约定）。

## 3. 后端接口变更（`include/qjsbind/web/net.hpp` + `src/net/`）

### 3.1 类型变更

```cpp
// web 层：body 字节源（取代整收 body）
struct BodySource {
    virtual ~BodySource() = default;
    // 返回一块字节；nullopt = EOF。失败抛 std::exception（网络/协议/解压错误）。
    virtual exec::task<std::optional<std::string>> read() = 0;
    // 尽力取消：关闭 socket、释放资源。幂等。可能在其他线程触发。
    virtual void cancel() = 0;
};

struct HttpResponse {
    int status = 0;
    std::string reason;
    std::vector<Header> headers;
    std::shared_ptr<BodySource> body; // null = 无 body（HEAD/204/205/304）
};

// FetchBackend 语义变化：读出头即返回，body 流尚未读完；
// 签名改 const HttpRequest&（后置拦截器需要本跳最终请求，见 §5.3）
```

`std::string body` 字段删除。`FetchBackend::request()` 实现改为"读出头 + 交出 body 源"即返回；签名微调为 `request(const HttpRequest& req, std::stop_token st)`——原来按值 move，现在驱动层要保留 `req` 给后置拦截器（§5.4），后端改为只读引用。

### 3.2 beast 实现（`src/net/http_client.cpp`）

- `do_exchange` 拆两段：`async_write` + `http::async_read_header`（`http::response_parser<http::buffer_body>`）→ 组装 head 返回；body 由 `BeastBodySource<Stream>` 持有
- `BeastBodySource` 持有：stream（move 进来，模板覆盖 tcp/ssl 两种）、`flat_buffer`、parser、64 KiB 读缓冲。`read()` = `http::async_read_some(stream, buffer, parser)` → 返回本次消费的字节；`parser.is_done()` → `nullopt`（chunked / content-length / `need_eof` 的连接关闭终止都由 beast 处理）
- **取消链改动**：v1 的 `stop_callback` 挂在 `http_request` 协程作用域内（全量读完即销毁）。v2 改为 `BeastBodySource` 构造时注册、析构时注销——fetch 在头部 resolve 后 abort 仍需能取消 body 读取
- `cancel()` = `lowest_layer().close()`（同时唤醒挂起的 read，以 `operation_aborted` 完成）
- 重定向中间响应：v1 无连接复用（不设 keep-alive，socket 用完即关），中间跳 body 直接丢弃 source 即可
- 无 body 场景（HEAD / 204 / 205 / 304）：`body = nullptr`，交给 web 层映射为 `null`

### 3.3 错误时序（行为变化，需记录）

| 阶段 | v1 | v2 |
|---|---|---|
| DNS/连接/TLS/写请求/读头失败 | fetch reject TypeError | 同左 |
| **读 body 中途失败** | fetch reject TypeError | fetch 已 resolve；`read()`/消费方法 reject TypeError |
| body 中途 abort | fetch reject AbortError | 挂起的 `read()` reject AbortError |

### 3.4 SOCKS5 代理（新文件 `src/net/socks5.{hpp,cpp}`）

```cpp
struct Socks5Proxy {
    std::string host;
    uint16_t port = 1080;
    std::optional<std::pair<std::string, std::string>> auth; // username/password（RFC 1929）
};

// 建立经 SOCKS5 到目标的 TCP 隧道：greeting（方法协商：无认证 / user-pass）
// →（可选）RFC 1929 子协商 → CONNECT（ATYP = 域名 / IPv4 / IPv6）→ 校验 REP=0x00。
// 失败抛 boost::system::system_error。
exec::task<tcp::socket> socks5_connect(boost::asio::io_context& io,
                                       const Socks5Proxy& proxy,
                                       std::string_view target_host, uint16_t target_port,
                                       std::stop_token st);
```

- `http_request` 增加可选尾参：`http_request(io, req, tls, st, std::optional<Socks5Proxy> proxy)`。有代理时 `socks5_connect` 替代直连；**https 在隧道上照常 TLS handshake**（SNI 与证书校验按目标 host，与代理无关）；http 则隧道内明文
- 取消链不变：隧道 socket 同样 `shared_ptr` + `stop_callback` → `cancel()`（握手阶段也可被取消）
- `BeastFetchBackend` 增加 `request_via_socks5(const HttpRequest&, const Socks5Proxy&, st)`——与 `request()` 共用类型桥接，供代理拦截器作为"另一条 handler"调用（§5.7）
- 机制（握手/隧道）只在 net 层；**走不走代理是拦截器的策略决策**，net 层不感知策略

## 4. web 层流机制（新文件 `include/qjsbind/web/stream.hpp`）

### 4.1 ReadableStreamImpl（C++ 状态机，不直接暴露）

```cpp
struct ReadableStreamImpl {
    enum class State { Readable, Closed, Errored };
    State state = State::Readable;
    std::shared_ptr<BodySource> source;      // 底层字节源（网络/解压/内存）
    std::deque<std::string> queue;           // 已拉未读块（拉驱动下通常 ≤1）
    std::exception_ptr error;                // Errored 时的原因
    bool disturbed = false;                  // 发生过 read → bodyUsed
    ReadableStreamDefaultReaderImpl* reader = nullptr; // 唯一 reader 槽（locked）
    std::deque<PendingRead> pending_reads;   // 挂起的 read()（FIFO，并发 read 按序结算）
};
```

语义规则（WHATWG Streams 子集）：

- `read()`：queue 非空 → 立即 resolve `{value, done:false}`；否则挂起并触发一次 source pull。EOF → resolve `{value:undefined, done:true}`，状态 Closed
- source `read()` 抛异常 → 状态 Errored，存 error；**挂起及后续所有** `read()` 以该 error reject
- `cancel()` → `source.cancel()`，状态 Closed，挂起 read 全部 resolve `{done:true}`
- `disturbed` 在首次实际 read 时置位（仅 `getReader()` 不置位）——`bodyUsed` 映射到它
- reader 释放（`releaseLock()`）后流仍可读，可再次 `getReader()`；有挂起 read 时 `releaseLock()` 抛 TypeError（spec）
- 并发 `read()`：进 `pending_reads` FIFO，按序结算（spec 允许）

### 4.2 JS 绑定

```cpp
// ReadableStream：内部构造（fetch/Response 注入 source），v2 不支持 JS new
class ReadableStream {
    getReader()           // locked → TypeError；返回 ReadableStreamDefaultReader
    get locked()
    cancel(reason)        // → Promise<undefined>
};

class ReadableStreamDefaultReader {
    read()                // → Promise<{value: Uint8Array|undefined, done: boolean}>
    cancel(reason)        // → Promise<undefined>（顺带 releaseLock）
    releaseLock()
    get closed()          // → Promise（Closed resolve / Errored reject）
};
```

- chunk 类型恒为 `Uint8Array`（`JS_NewUint8ArrayCopy`，沿 `consume_bytes` 先例）
- `read()` 绑定为 `exec::task<qjs::Value>`（沿 `text()` 先例），结算回 JS 线程由绑定层保证
- 两类的 JS 对象都持 `shared_ptr<ReadableStreamImpl>` + `qjs::RtValue` 互持，`qjs_mark` 标记（沿 `headers_js`/`signal_js` 先例；注意 reader↔stream 环引用走 mark，不靠析构）
- **GC 回收路径**：Response 被 GC 且 body 未消费 → `ReadableStreamImpl` 析构 → `BodySource` 释放 → socket 关闭（文档化行为：不读完的 body 连接被丢弃）

### 4.3 Request/Response 集成（`request_response.hpp`）

- `body_bytes: std::string` 旁新增 `std::shared_ptr<ReadableStreamImpl> body_stream`。两者统一为"内部 body"：
  - **字节 body**（`new Response("x")`、data: URL、构造 Request）：包一层 `MemorySource`（一次性吐出）——body 模型统一为流，克隆/消费路径单一
  - **流 body**（fetch 响应）：`BeastBodySource`（可能被拦截器包装）
- `body` getter：恒返回流（`has_body=false` 仍返回 `null`）；**SameObject 缓存**（`RtValue body_js`，沿 headers 先例）
- `bodyUsed` getter：改读 `stream->disturbed`（字节 body 走同一路径）
- 消费方法（`text()` 等六件套）：改为 C++ 侧 pull 循环读干（**不经 JS reader**），完成后按原逻辑解码。前置检查：locked → TypeError；disturbed → TypeError（与 v1 "body 已被消费" 语义衔接）
- `clone()`：
  - 字节 body：照 v1 拷贝
  - 流 body：locked 或 disturbed → TypeError（v1 语义不变）；否则内部 **tee**：原对象持分支 A，克隆持分支 B
- `try_extract_init_body`：`new Request(url, response)` 的 body 复制——源为字节时照旧拷贝；源为流且未 disturbed → tee 共享（已 disturbed → TypeError 不变）

### 4.4 tee 实现（内部，支撑 clone）

```
tee(source) → (branchA, branchB)
共享状态：{ source, bufA, bufB, closedA, closedB, done, error }
分支 read：本分支 buf 空 → pull source → 块推入两侧 buf（已关闭分支不推）→ 从本分支弹出
分支 cancel：标记关闭；两侧都关闭 → source.cancel()
```

- 内存说明：慢分支会积压缓冲；分支被 GC → 视为 cancel 释放缓冲（文档化为已知限制：两分支都活跃且速度悬殊时内存随差值增长）
- v2 不公开 `stream.tee()`，仅 clone 内部使用

### 4.5 SRI（integrity）时机变化

v1 在 fetch resolve 时对整收 body 校验。v2 改为**消费末端校验**：消费/读取过程中增量算摘要，EOF 时比对——不匹配则消费 Promise reject TypeError（getReader 路径则流进 Errored）。摘要必须对**解码后**字节计算（spec），与 §5 解压层序衔接。

## 5. 拦截器 + 自动解压（新文件 `include/qjsbind/web/interceptor.hpp`）

拦截器是 **around 模型的协程链**：每个拦截器收到内层 `next`，`co_await next` 之前是前置相位、之后是后置相位。选 around 而非平面管线的动因是**传输选路**：SOCKS5 代理要求拦截器能决定"这次交换走哪条传输"（直连 `next` / 代理隧道），以及重试——包裹式控制流，平面管线（只能改 req 字段）表达不了（§8 决策记录 6）。

### 5.1 拦截器接口

```cpp
// 链尾处理器：最终落到 FetchBackend::request
using FetchHandler =
    std::function<exec::task<HttpResponse>(const HttpRequest& req, std::stop_token st)>;

struct FetchInterceptor {
    virtual ~FetchInterceptor() = default;
    // co_await next 之前 = 前置相位；之后 = 后置相位。
    // req 为 const 引用、贯穿整个调用：后置相位仍可读（日志/指标/复核）。
    // 短路 = 不调 next 直接 co_return；重试 = 多次调 next；换传输 = 调别的 handler。
    // 自身有异步操作时须转发 st 以响应 abort。
    virtual exec::task<HttpResponse> intercept(const HttpRequest& req, std::stop_token st,
                                               FetchHandler next) = 0;
};
```

设计要点：

- **协程天然表达**：前置/后置在同一函数体里，局部变量即 per-request ctx（不需要 ctx token 手工传递）
- **同步非阻塞**：每个 `co_await` 点让出 io 线程；异步拦截器（刷新 token、请求签名、将来 JS 桥回调）直接 `co_await`
- **包裹式控制流**：短路 / 重试 / 传输选路 / 异常转换都只是"怎么调 next"——这是选 around 的动因
- **req 只读贯穿**：要改请求先拷贝再传给 `next`（§5.2）

### 5.2 前置相位规约（`co_await next` 之前）

- **改请求**：`req` 只读；要改先拷贝——`HttpRequest r = req; r.headers.push_back(...); co_await next(r, st);`（改头 / 改 URL / 改 body 同此；URL 重写可用于灰度路由、mock 指向）。拦截器是 C++ 侧信任代码，blocked-port 等构造期检查不重复做
- **短路**：不 `co_await next`，直接 `co_return` 构造的 `HttpResponse`（缓存命中、mock、离线降级）。注意：**短路响应照样过 `fetch_impl` 的 redirect / SRI 逻辑**——返回 3xx + Location 会被当重定向跟随；想给 JS 一个最终响应就不要用 3xx 状态
- **抛异常**：`std::exception` 沿嵌套链向外抛——外层拦截器可 catch（错误归一 / 降级）；最终未被捕获则由 `fetch_impl` 统一转 fetch reject `TypeError("fetch failed: ...")`；`qjs::js_error` 原样透传（沿 v1 的 catch 分层）
- **abort**：纯同步代码无需检查 `st`（取消最终在链尾 socket 操作生效）；钩子里若有异步操作（刷新 token 等），应把 `st` 传给自己的异步源，或操作前 `st.stop_requested()` 早退，否则取消要等到网络阶段才生效

### 5.3 后置相位规约（`co_await next` 返回之后）

响应是 `HttpResponse` 值，可改可换：

- **改 head**：status / reason / headers 都可改（剥头：解压剥 `content-encoding` / `content-length`；加头：注入 `x-from-cache` 等）
- **包装 body 流**：`resp.body = std::make_shared<XxxSource>(std::move(resp.body), ...)`——可多层嵌套；外层拦截器的包装在 read 路径上先执行（解压、进度统计、落盘 tee、限流）
- **req 可读**：本跳最终请求仍在作用域（`const HttpRequest&`），日志 / 指标 / 复核直接读
- **异常捕获 / 重试**：`try { co_await next(...) } catch (...) { ... }`。后端"读出头即返回"保证了 **catch 到的异常一定发生在响应头之前**（DNS / 连接 / TLS / 写请求 / 读头）；body 流错误不在此出现（推迟到 read 时，见 §3.3）——重试不会撞上"body 已消费一半"的二义性。保守策略：仅重试 GET/HEAD 等幂等方法，并设次数上限
- **abort**：`co_await next` 被取消时是 `set_stopped` 而**非异常**——协程不再恢复，后置代码不执行，清理靠 RAII（局部变量析构）

### 5.4 链组装与执行顺序

`fetch_impl` 的 redirect 循环内，**每一跳都走全链**（每跳重新组装）：

```cpp
FetchHandler h = [backend](const HttpRequest& req, std::stop_token st) {
    return backend->request(req, st);
};
for (auto it = chain.rbegin(); it != chain.rend(); ++it) {
    h = [interceptor = *it, next = std::move(h)](const HttpRequest& req,
                                                 std::stop_token st) {
        // next 拷贝传递（非 move）：handler 必须可重入——重试会多次调用
        return interceptor->intercept(req, st, next);
    };
}
HttpResponse resp = co_await h(req, st);
```

注册顺序 = 嵌套顺序（洋葱）：**先注册者在最外层**——前置相位按注册顺序进入，后置相位逆序返回：

```
fetch_impl（一跳）
  ├─ I₁ 前置（最先看到请求）
  │    ├─ I₂ 前置
  │    │     └─ backend->request / 或代理拦截器的 SOCKS5 交换（读出头即返回）
  │    ├─ I₂ 后置（最先看到响应，body 包装在最内层）
  ├─ I₁ 后置（最后加工响应，body 包装在最外层）
```

read 路径上外层先执行：`reader.read() → I₁ 包的 source → I₂ 包的 source → BeastBodySource`。

排序与跳转细则：

- **AcceptEncoding 注册在最前（最外层）**：read 时先解压；其内层拦截器读到的是压缩字节——内层做进度统计时口径 = 网络字节数，通常正是想要的效果
- **代理拦截器注册在最末（最贴近后端）**：无论直连还是代理隧道，请求都先经过全部前置（加头、Accept-Encoding 标记等）
- **redirect**：跳与跳之间拦截器不共享状态（协程帧随跳销毁）；`fetch_impl` 的 redirect 处理（转 GET、剥 body 相关头）在两跳之间完成，下一跳前置看到的是"干净"请求（每跳重新加 Accept-Encoding）
- **SRI**：摘要在消费末端对**最外层拦截器的输出**计算（§4.5），与包装顺序无关地保持正确

### 5.5 注册点

```cpp
inline void install_web_apis(qjs::Context& ctx, std::shared_ptr<FetchBackend> backend,
                             std::vector<std::shared_ptr<FetchInterceptor>> interceptors = {
                                 std::make_shared<AcceptEncodingInterceptor>() });
```

v2 仅 C++ 侧注册；JS 侧暴露（JS 函数作拦截器，经 Promise 桥 `co_await` 回调）是 M5 演进方向——around 协程接口已为此留好形状。

### 5.6 AcceptEncodingInterceptor 行为

```cpp
exec::task<HttpResponse> intercept(const HttpRequest& req, std::stop_token st,
                                   FetchHandler next) override {
    // ---- 前置相位 ----
    const bool auto_added = !has_header(req.headers, "accept-encoding") &&
                            !has_header(req.headers, "range");
    HttpResponse resp;
    if (auto_added) {
        HttpRequest r = req; // req 只读：拷贝后改
        r.headers.push_back({"Accept-Encoding", "gzip, deflate, br"});
        resp = co_await next(r, st);
    } else {
        resp = co_await next(req, st);
    }

    // ---- 后置相位：局部变量 auto_added 即 per-request ctx ----
    if (auto_added && resp.body) {
        if (auto enc = single_content_encoding(resp.headers)) { // gzip/x-gzip/deflate/br
            strip_headers(resp.headers, {"content-encoding", "content-length"});
            resp.body = std::make_shared<DecompressSource>(std::move(resp.body), *enc);
        }
    }
    co_return resp;
}
```

行为细则：

- 无 `accept-encoding` 且无 `range`（压缩使 Range 偏移失效）才自动加头
- 用户自己设了 `accept-encoding` → 原样透传不解压（undici 语义：显式要编码 = 要原始字节）
- `content-encoding` 取单个编码；逗号多个 → 不处理透传（避免歧义）；`identity` 或无此头 → 不处理
- 命中 → 剥 `content-encoding` + `content-length`（解压后长度失效，undici 同），包 `DecompressSource`
- HEAD / null body status：body 为空，天然跳过
- （偏离说明：浏览器仅 https 发 br；本实现不区分 scheme，与 undici 一致）

### 5.7 SOCKS5 代理拦截器

机制在 net 层（§3.4）；拦截器只做**策略**（哪些 URL 走代理、走哪个）与**选路**（调不调 `next`）：

```cpp
class Socks5ProxyInterceptor : public FetchInterceptor {
    std::shared_ptr<net::BeastFetchBackend> backend_; // 提供 request_via_socks5
    Route route_; // 策略：url → std::optional<Socks5Proxy>（空 = 直连）

    exec::task<HttpResponse> intercept(const HttpRequest& req, std::stop_token st,
                                       FetchHandler next) override {
        if (auto proxy = route_(req.url))
            co_return co_await backend_->request_via_socks5(req, *proxy, st); // 不调 next
        co_return co_await next(req, st); // 直连
    }
};
```

- **注册在最末**（最贴近后端）：代理 / 直连两条路径都先经过全部前置拦截器
- 不调 `next` 意味着其内层只剩链尾 backend——代理拦截器应始终放在最后
- 路由策略可以是静态表、CIDR 规则或回调；v2 内置"全走一个代理 / 全直连"两档即可，策略接口留敞
- 代理链（代理套代理）、HTTP CONNECT 代理：后续按需

### 5.8 DecompressSource

`read()` 同样是协程，与上下游同一风格（拉模型上唯一被 `co_await` 的环节）：

```cpp
class DecompressSource : public BodySource {
    std::shared_ptr<BodySource> upstream;
    Decoder dec; // gzip/deflate: zlib inflate 流；br: BrotliDecoderDecompressStream

    exec::task<std::optional<std::string>> read() override {
        // 循环 { co_await upstream->read() 拉一块 → 喂 decoder → 榨取输出 }
        // 直到产出 ≥1 字节，或上游 EOF 且 decoder 收尾（co_return nullopt）。
        // decoder 报错 / 流截断（EOF 时 decoder 未到 stream end）→ 抛 std::runtime_error
        //   → read() reject TypeError("fetch failed: ...")（沿网络错误同一路径）
    }
};
```

- gzip：`inflateInit2(15 + 16)`；deflate：`inflateInit2(15)`，首个块 `Z_DATA_ERROR` 时回退裸 deflate（`-15`，兼容不规范服务器）
- 依赖：vcpkg 增加 `zlib`、`brotli`；`qjsbind_net` PUBLIC 链接（沿 OpenSSL 传播先例，`fetch.hpp` 注释同款说明）
- 输出块大小 16–64 KiB，与上游解耦（解压 1 块输入可能产出 0 或多块输出）

### 5.9 典型场景

| 场景 | 相位 | 说明 |
|---|---|---|
| 自动解压（内建） | 前置加头 + 后置包流 | §5.6；局部变量传"头是我加的" |
| SOCKS5 代理 | 传输选路 | §5.7；调不调 `next` |
| 鉴权头注入 | 前置 | token 过期先 `co_await` 刷新再加头 |
| 请求签名（SigV4 风格） | 前置 | 拷贝 req，对规范化内容算签名后写 Authorization |
| 缓存 | 前置短路 + 后置写缓存 | 短路响应避开 3xx；写缓存包一层 tee source |
| mock / 离线降级 | 前置短路 | 构造 `HttpResponse` + 内存 body 源 |
| 限流 | 前置 | `co_await` 令牌桶后再进 `next` |
| 日志 / 指标 | 前置 + 后置 | `req` 贯穿可读；局部变量存起始时间 |
| 错误码映射（5xx 降级） | 后置 | 改 status / 替换 body |
| 重试 | try/catch + 多次调 `next` | 仅幂等方法 + 头前错误（§5.3） |
| 进度统计 / 下载落盘 | 后置包 body 流 | 包一层观察 source，read 时回调 |

## 6. 里程碑

| 里程碑 | 内容 | 验收 |
|---|---|---|
| M1 | 后端流式化（BodySource/buffer_body）+ 六件套改读干实现；`body` 仍返回 null | ✅ 完成：`BeastBodySource` 64 KiB 分块；wpt 全套绿；resolve 提前无 JS 可见差异（bad-length.py 断流 → TypeError 单测） |
| M2 | ReadableStream/reader JS 绑定 + `body` getter + bodyUsed/disturbed + tee/clone 改造 | ✅ 完成：`stream.hpp` 绑定 + MemorySource + tee；wpt 解除 ReadableStream skip（fetch/string 源用例全过；stream 源用例按 §7 范围登记 expected） |
| M3 | 协程拦截器框架（around）+ AcceptEncodingInterceptor（gzip/deflate/br）+ SRI 末端校验 | ✅ 完成：`interceptor.hpp`；compress.py 端点 + gzip/deflate/br 往返/损坏流/自动协商头/SRI+压缩 单测 |
| M4 | SOCKS5：net 层握手/隧道（`socks5_connect` + `http_request` 代理参数）+ 代理拦截器 | ✅ 完成：mini SOCKS5 对打 7 件套（无认证/user-pass/ATYP 域名与 IPv4/REP 错误/选路/握手 abort/https over tunnel） |
| M5（可选） | JS 构造 ReadableStream（underlyingSource start/pull/cancel）、公开 `tee()`、JS 侧拦截器（Promise 桥） | 另行设计细化 |

## 7. 测试计划

- **单测**（`tests/fetch_test.cpp` 扩）：getReader 循环拼回 == text()；多 chunk 边界；cancel 后 read done；locked 消费 → TypeError；clone 两分支各自读全；abort 中途流；gzip/deflate/br 往返；用户自设 accept-encoding 透传原始字节；带 `range` 不加自动头；截断 gzip → TypeError；SRI + gzip（对解压后字节校验）
- **拦截器单测**：异步拦截器（体内 `co_await` 定时器再 `co_await next`）验证不阻塞 io 线程；嵌套顺序断言（前置正序、后置逆序）；短路（不调 `next` 直接返回响应：断言未发网络请求；3xx 短路响应触发 redirect 跟随）；重试（`next` 调两次，验证 handler 可重入）
- **SOCKS5 单测**：本地 mini SOCKS5 server fixture 对打握手（无认证 / user-pass / 域名与 IPv4 ATYP / REP 错误码）；选路断言（命中策略走隧道、未命中直连）；https over tunnel（自签 + `extra_trust_pem`）；握手阶段 abort
- **wpt_server**：新增 gzip/deflate/br 端点（服务端用 zlib/brotli 现压 fixture）；`.asis` 机制沿用
- **analyze_wpt.py**：依赖表移除 ReadableStream（M2 后）、content-encoding 目录放行（M3 后），expected 清单更新
- **既有坑沿用**（见进度台账）：新增 web 头文件先过 `scripts/add_bom.py`；JS 补丁字符串禁 `//` 注释；异常类型保持可拷贝；`stop_callback` 跨线程仅触碰共享 socket

## 8. 风险与决策记录

1. **fetch resolve 时机提前**是 spec 行为，但 v1 的"网络错误必 reject fetch"直觉不再成立——body 中途断流错误推迟到读取时；文档与测试需明确（§3.3）
2. **tee 内存**：慢分支积压为已知限制；激进方案（分支 HWM + 拉取悬挂）复杂度不值，v2 不做
3. **undici 语义 vs 浏览器语义**：用户显式 `accept-encoding` 时不解压（undici），与 v1 "参照 Node" 的总基调一致
4. **多编码 content-encoding**（如 `gzip, br` 叠加）：v2 透传不处理，避免错误解压
5. **请求流式上传**整体推迟：涉及 `duplex`、beast 写侧流化，与读侧无耦合
6. **拦截器取 around 模型**：动因是 SOCKS5 代理——传输选路要求拦截器能决定"调不调 `next`、调哪条 handler"，包裹式控制流是刚需；重试、短路、异常转换也随之自然获得。曾按平面管线（前置/后置两段式）设计过一版，因代理需求回摆——平面模型下加头/日志/短路等九成场景固然好写，但"换传输"无处可放。注意 SOCKS5 握手机制本身在 net 层（§3.4），拦截器只是策略与选路点，协议逻辑不写进拦截器
7. **`cancel()` 保持同步**：取消由 `stop_callback` 触发（可能跨线程），协程化反而引入生命周期与竞态问题——全链路唯一的非协程点，刻意为之
