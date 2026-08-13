# 直连 / SOCKS5 / CONNECT / forward proxy 与连接池代码审查报告

> 状态：审查结论（基于 `main` e1b04ab 快照）。
> 修复状态（2026-08-11）：H1–H4、M1–M6、L1–L6 全部修复，backlog 清空。
> 修复要点：
> H1/H2 由新文件 `src/fetch/connect_util.hpp` 统一承载（`connect_all` 循环尝试所有
> endpoint、resolver 共享持有补了三处取消空洞）；M1 超时经 `HandshakeDeadline`+`await_op`
> 区分超时与用户取消；H3 实测 Windows 上该场景返回 WSAECONNABORTED(10053)，故重试分支
> 覆盖 reset/aborted 错误形态；M3 析构守卫放宽为"io 停止后任意线程可释放"。
> M5 实现形态：`BeastTransport::TlsSessionCacheImpl`（beast_transport.cpp，与 ctx 缓存
> 并列）——键 host:port|tls_fingerprint、值 SSL_SESSION*+过期点、LRU 128、仅 io 线程；
> TLS 1.2 握手成功后 SSL_get1_session 入库，TLS 1.3 ticket 经
> SSL_CTX_sess_set_new_cb + SSL ex_data 链接块捕获入库；握手前 lookup 命中即
> SSL_set_session（single-use 票取出即焚）。仅池化路径启用，无池行为不变。
> M6：统一 `parse_port`（beast_transport.cpp），池键与 socks5/http_proxy 建连路径
> 共用同一份校验，非法端口在构造键时即抛（不再静默归 0）。
> L2：清扫周期改 `max(idle_timeout/2, 90ms)`，回收延迟从近 2× 降到 ~1.5×。
> L3：absolute-form 显式端口仅补注释说明有意不省略（不改代码）。
> L4：`parse_url` 拒绝带 userinfo 的 URL（对齐 WHATWG fetch，提示改用 Authorization 头）。
> L5：CONNECT 失败响应保留 body 前 4 KiB 摘要进错误信息（2xx 成功路径不读 body）。
> 范围：
> - 代理四条建连路径：`src/fetch/socks5.cpp`、`src/fetch/http_proxy.cpp`、`include/fetch/tunnel_stream.hpp`、`src/fetch/beast_transport.cpp`
> - 连接池：`include/fetch/connection_pool.hpp`、`src/fetch/connection_pool.cpp`、`src/fetch/pooled_transport.cpp`、`include/fetch/pooled_transport.hpp`
> 前置文档：`docs/fetch_connection_pool_design.md`、`docs/fetch_cpp_decoupling.md`、`docs/beast_ssl_backend.md`。
> 行号对应当前快照，代码漂移后以结构/函数名为准。

## 0. 总体评价

整体质量高，协议正确性与取消/生命周期模型明显经过推敲。以下设计点确认无误，值得保留：

- **TLS 层叠顺序正确**：四条路径均先建隧道（SOCKS5/CONNECT）再做 TLS 握手，且 SNI / `host_name_verification` 使用**目标** host 而非代理 host（`beast_transport.cpp:674-706`）——常见出错点，做对了。
- **CONNECT over-read 处理正确**：`http_proxy_connect` 用局部 `flat_buffer` 读 CONNECT 响应并移交 leftover（`http_proxy.cpp:50-59`）；`TunnelStream::async_read_some` 先消费 leftover 再读 socket（`tunnel_stream.hpp:42-52`），并用 `post` 避免异步完成内联递归。leftover 随连接入池。
- **跨线程取消回调的悬挂防护**：`exchange_pooled` 头阶段用裸指针 + `valid` 原子双检 + 互斥锁处理"跨线程 stop_callback vs 连接所有权转移"竞态（`beast_transport.cpp:480-524`）；`BeastBodySource` 成员声明序（`stop_cb_ → mu_ → conn_`，`:454-464`）保证析构逆序下并发 cancel 回调安全。
- **hop-by-hop 凭据隔离**：`Proxy-Authorization` 只出现在发往代理的连接上；`proxy_id` 不含密码，避免落日志（`beast_transport.cpp:211-221`）。
- **池键设计完备**：scheme/host/port + proxy_id + tls_fingerprint 五元组（`types.hpp:72-100`）；http 正向代理以代理本身为键实现跨 origin 复用（absolute-form 转发本就允许）；CONNECT/SOCKS5 隧道端到端绑定目标进键，不会把 A 站隧道误发给 B 站。
- **连接复用语义严谨**：need_eof 响应不回池（`beast_transport.cpp:227-239`）；复用连接失败仅在"请求从未上线"时重试且排除流式上传；abort 不回池；LIFO + 单调 `idle_at` 不变量成立。
- **SOCKS5 协议细节**：BND.ADDR 变长读取、REP → 可读错误 category、禁止从 auth 降级到免认证，符合 RFC 1928/1929。
- **407 可区分**：CONNECT 拒绝与转发 407 均映射到 `http_proxy_category`，错误码即 HTTP 状态码。
- **池与句柄互不续命**：`PooledConnection` 用 `weak_ptr` 回指池（`connection_pool.hpp:86`），池先销毁时 `put_back` 退化为直接关闭（`connection_pool.cpp:57-66`）。

## 1. 高严重度

### H1. 三条建连路径都只尝试 DNS 结果的第一个端点

- 位置：`src/fetch/socks5.cpp:110`、`src/fetch/http_proxy.cpp:35`、`src/fetch/beast_transport.cpp:621`，均为 `async_connect(*results.begin(), ...)`。
- 问题：`async_resolve` 返回多个 endpoint（典型 AAAA + A，或多 A 记录），只连第一个；第一个失败（IPv6 不可达、connection refused）整个请求即失败，即使其余端点可用。对代理路径影响更大：代理一个地址宕掉即全挂。
- 修法：循环尝试所有 endpoint，或使用 beast 的 composed connect（`beast::get_lowest_layer(stream).async_connect(results, ...)`）。

### H2. DNS 解析阶段 AbortSignal 无效

- 位置：`socks5.cpp:100-110`、`http_proxy.cpp:25-35`、`beast_transport.cpp:611-621`。
- 问题：stop_callback 只 `sock->cancel()`，而 resolve 阶段 socket 上没有任何挂起操作，回调为空操作；`resolver` 本身未被取消。stop 在 resolve 期间到达时，操作阻塞至 DNS 超时（Windows 下可达数十秒）。
- 修法：stop_callback 中以 `shared_ptr` 持有 resolver 并调用 `resolver.cancel()`。

### H3. 陈旧 keep-alive 连接"写成功、读 EOF"不重试 —— 最高频的半开场景没有兜底

- 位置：`src/fetch/beast_transport.cpp:508`（写成功后立即 `write_done = true`）、`:577-579`（重试条件要求 `!write_done`）。
- 问题：服务器对空闲 keep-alive 连接发 FIN（优雅关闭）时，复用连接的写通常成功（字节进内核缓冲），随后的 `read_header` 才拿到 EOF / stream truncated —— 此时 `write_done == true`，不重试，错误直接抛给用户。这正是生产环境最高频的陈旧连接形态。
- 加剧因素：`types.hpp:105-107` 默认 `idle_timeout = 90s` **大于** nginx 默认 `keepalive_timeout 75s`，倒挂。
- 承诺落空：`connection_pool.cpp:163-165`（Windows 不探测）、`:167-169`（TLS 不探测）、`connection_pool.hpp:6-7` 三处注释均声称"靠复用重试兜底"，在此场景全部失效。且"对齐 hyper"的说法不准确：hyper 只重试"请求从未开始写"的竞态（入队前连接已死，request 原样带回），写成功后的读头 EOF 属在飞失败（message 不可带回）、hyper 不重试。
- 状态：修法 1 已在 v4 实施——`pooled_flow` 现在对"写成功但读响应头零字节 EOF/RST"的复用连接也重试一次（`!write_done || header_eof`，见 `fetch_connection_pool_design.md` §3.7），本项已闭环。
- 修法（二选一或并用）：
  1. 对 `reused && !body_stream` 且读头阶段**零字节**失败（beast `http::error::end_of_stream` / EOF）允许重试一次，至少对幂等方法；
  2. 把默认 `idle_timeout` 降到显著低于常见服务端超时（如 30s）。
- 测试佐证：`tests/connection_pool_test.cpp:391-416` 用例靠等 250ms 让 RST 到达才能让写失败，注释明确"写成功读失败不重试"。

### H4. 清扫定时器 handler 强捕获自身：取消失效 + 可能出现双清扫链

- 位置：`src/fetch/connection_pool.cpp:191`：
  ```cpp
  timer->async_wait([weak = weak_from_this(), timer](...) { ... });
  ```
- 问题：形成 timer → operation → handler → timer 循环。`sweeper_.reset()`（`:75` 析构、`:141` close_all、`:199` 池空自停）只是释放池持有的引用，挂起的 `async_wait` 靠 handler 的强捕获让 timer 继续存活，**等待不会被取消**。`:75`、`:141` 处"取消定时器"/"析构即取消"的注释是错的。
- 可观察 bug：`close_all()` 后再 `put()` → `ensure_sweeper()` 创建新 timer；旧 timer 到期触发 handler，`idle_` 非空 → `schedule_sweep(旧timer)` —— 新旧两条链各自永续 reschedule，双倍清扫常驻（功能无害但违背 `connection_pool.hpp:114` "至多一个"的设计声明）。
- 修法：handler 改捕获 `std::weak_ptr<steady_timer>`（一行修复），或 reset 前显式 `sweeper_->cancel()`。

## 2. 中严重度

### M1. 代理握手全程无超时

- SOCKS5 greeting / CONNECT / RFC 1929 子协商、TCP connect、TLS handshake 均无 deadline。僵死代理可让 `async_read(*sock, buffer(rh, 4), ...)`（`socks5.cpp:156`）永远挂起，唯一逃生通道是外部 stop_token。
- 建议：至少为 CONNECT / SOCKS5 握手加秒级超时（常见代理库 10–30s）。

### M2. SOCKS5 超长域名/凭据被静默截断，导致连到错误目标

- 位置：`socks5.cpp:84-85`（域名 >255 时 `substr(0,255)` 静默截断）、`:60-63`（user/pass 同样截断）。
- 问题：代理会去连一个**被截断的主机名**——语义错误而非可接受降级；凭据截断表现为神秘的认证失败。
- 修法：超长直接抛 `invalid_argument`。

### M3. `~ConnectionPool()` 跨线程析构竞态

- 位置：`connection_pool.cpp:73-77`。
- 问题：池由 `shared_ptr` 持有（`BeastTransport::pool_`），若最后一个引用在非 io 线程释放（如 JS 主线程销毁 Client，而 io_context 正在 poll），timer 销毁/sweeper handler 执行与 socket 析构构成数据竞争。契约只约束了 checkout/put（"仅 io 线程"），未约束析构线程。
- 建议：文档/注释明确"池的最后引用必须在 io 线程释放"，或 `~ConnectionPool` 加 `assert_io_thread()`，最好把池所有权收进 io 线程的 shutdown 流程。

### M4. `assert_io_thread` 的"首次访问线程"记录本身有数据竞争

- 位置：`connection_pool.cpp:79-91`。
- 问题：`io_thread_` / `io_thread_set_` 非原子，两线程并发首次访问即 UB；且语义脆弱——任何一次误用（如错误线程先调 `idle_count()`）会把错误线程**永久钉为**合法 io 线程，后续真正的 io 线程访问全部 assert。
- 建议：用 `std::atomic<std::thread::id>` / once-flag，或由构造方显式传入 io 线程 id。

### M5. TLS session 复用未实现

- 位置：`beast_transport.cpp:154-170`（`make_ssl_context` 无 `SSL_CTX_set_session_cache_mode(SSL_SESS_CACHE_CLIENT)`，握手后无 `SSL_get1_session` / `SSL_set_session`）。
- 说明：`TlsContextCacheImpl`（`:627-651`）缓存的是 `ssl::context`，**不等于** session 缓存——每条新 TLS 连接都是完整握手（1-RTT/2-RTT + 证书传输）。池内复用不受影响，但 idle_timeout 过期或 per-host 上限丢弃后的重连成本高。若是刻意推迟，建议在设计文档标注。

### M6. `port_number()` 与建连路径的端口校验不一致

- 位置：`beast_transport.cpp:190-197`：池键用 `port_number()`，非法端口返回 0；实际建连路径的 stoi 校验抛异常。结果：池键 `port=0` 的连接先被建立/复用决策，然后建连抛错——行为仍正确，但键语义脏了。
- 建议：统一在校验后再构造 key。

## 3. 低严重度

- **L1** `probe_plain`（`connection_pool.cpp:38-52`）：`recv` 返回 1（有数据）判活。空闲明文连接上出现字节几乎必然是异常（对端乱发/代理污染），复用后会被当响应头解析出错。返回 >0 时应判死丢弃。
- **L2** 清扫周期 = `max(idle_timeout, 90ms)`（`connection_pool.cpp:183-189`）：刚清扫完就 idle 的连接要等近 2× timeout 才被淘汰。无碍正确性。
- **L3** forward proxy 的 absolute-form 永远带显式端口（`beast_transport.cpp:831,861`）：`http://host:80/path`。绝大多数代理接受，极少数敏感。cosmetic。
- **L4** URL 中的 userinfo 被静默丢弃：`parse_url`（`beast_transport.cpp:72-107`）不处理 `http://user:pass@host/`。用户常在代理 URL 里写凭据，建议在更高层显式拒绝或提取。
- **L5** CONNECT 响应解析（`http_proxy.cpp:51-53`）用 `empty_body` parser + `skip(true)`：407 响应 body 被消费丢失，只保留状态码，调试 407 时少了线索。
- **L6** SOCKS5 greeting 服务器回 0xFF 时（`socks5.cpp:120`）错误信息 "no acceptable authentication method" 无法区分"代理只支持免认证"与"代理根本拒绝"。诊断性小问题。

## 4. 修复优先级建议

| 优先级 | 项 | 说明 |
|--------|----|------|
| P0 | H4 | 一行 weak 捕获，消除取消语义错误与双清扫链 |
| P0 | H3 | 重试补"读头零字节 EOF"分支，或降默认 idle_timeout —— 决定池在真实网络下的可用性 |
| P1 | H1 | composed connect / 循环尝试所有 endpoint |
| P1 | H2 | resolve 阶段挂接 resolver.cancel() |
| P2 | M1、M2 | 握手超时；SOCKS5 超长输入改抛异常 |
| P3 | M3–M6、L1–L6 | 线程契约补全、session 复用、诊断性改进，进 backlog |
