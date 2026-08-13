# fetch HTTP/1.1 连接池设计文档（参照 hyper/reqwest）

> 状态：设计稿（未实现）。
> 参照对象：hyper-util `src/client/legacy/pool.rs` / `client.rs`（hyper 1.x 把 0.14 时代的池与高层 Client 整体迁到了 hyper-util 的 legacy 模块，reqwest 的池能力即来自这里），外加 hyper `src/client/conn/http1.rs`、`src/rt/`。
> 本地参考克隆（均为 shallow clone，仅供对照，勿入库）：
> - `build/tmp/hyper-src`（hyper 1.11.0，master `8a98d13`）
> - `build/tmp/hyper-util-src`（master `4684c71`，池实现 1115 行 + legacy client 1712 行）
> - `build/tmp/reqwest-src`（master `17e9bcb`）
> 文中 `pool.rs:NNN` 等行号对应上述快照，上游漂移后以结构名为准。
> 前置文档：`docs/fetch_streaming_design.md`（流式 body / BodySource 拉模型）、`docs/fetch_cpp_decoupling.md`（Transport 抽象与线程契约）、`docs/beast_ssl_backend.md`（BoringSSL 后端）。

## 1. 背景与目标

### 1.1 现状（无池、无复用）

当前每个 fetch 请求走完整建连链路，用完即关：

```
async_resolve → async_connect →（每请求新建 ssl::context）→ TLS handshake
→ async_write → async_read_header → 交出 BeastBodySource → body 读干/析构 → socket 直接析构关闭
```

具体证据：

- `src/fetch/beast_transport.cpp:199-200`：刻意不设 `Connection` 头，响应读完 socket 析构即关；
- `src/fetch/beast_transport.cpp:284-289`：`BeastBodySource` 析构无条件关 socket；
- `src/fetch/beast_transport.cpp:106-158,361`：`make_ssl_context` 每请求新建 `ssl::context`（CA store 靠 `X509_STORE_up_ref` 共享，但上下文对象本身每次重建）；
- `src/fetch/beast_transport.cpp:406`：DNS 每请求重新解析，无缓存；
- 文档层面早已声明"池化是传输层未来的事"（`docs/fetch_easy_design.md:55`、`docs/fetch_streaming_design.md:83`），且 `fetch::Transport` 抽象（`include/fetch/transport.hpp`）就是为此预留的接缝。

代价：同 host 连续请求的 TCP/TLS 握手延迟叠加（TLS 1.2 完整握手 2-RTT），服务端 TIME_WAIT/握手开销放大。

### 1.2 目标

- HTTP/1.1 keep-alive 连接复用池：同 host 的后续请求直接复用空闲连接，跳过 resolve/connect/handshake。
- 以**新的 `Transport` 实现**落地（`PooledTransport`），对 `fetch::Client`、中间件链、JS 绑定完全透明；不重用的代码路径（首连、代理握手、流式读写）最大化复用现有 `beast_transport.cpp` 的函数。
- 行为语义对齐 hyper/reqwest：LIFO 复用、`max_idle_per_host`、`idle_timeout`、后台清扫、陈旧连接自动重试（见 §2、§3）。
- 代理（SOCKS5 / HTTP CONNECT / http 正向代理）下的池化有明确定义（§3.8）——这是 hyper 没细做、我们需要自己补的部分。

### 1.3 非目标（本期不做）

- HTTP/2：项目明确 h1-only（`beast_transport.cpp:174` 固定 `version(11)`，无 ALPN），因此 hyper 池里最复杂的部分——`Ver`、`connecting` single-flight、`Reservation::Shared` 多路复用——**整体不需要**，这是我们能比 hyper 简单一个量级的根本原因（§3.2）。
- DNS 缓存：hyper 也不做（解析在 connector 内，池键不含 DNS 结果，`connect/dns.rs:42-55`）；我们同样把 DNS 留给每次新建连接，后续可独立加。
- TLS session resumption：列为可选增强（§3.9），不进首版。
- 全局/每 host 的**并发连接数硬上限**与等待队列：hyper 对 h1 本就不限并发建连（只有 h2 才 single-flight），我们保持一致。
- `100-continue`、HTTP/1.0 持久连接的完整适配：沿用 beast `keep_alive()` 判定结果即可，不额外处理。

## 2. hyper 连接池模型精读

> 本章是对 hyper-util `src/client/legacy/pool.rs`（下称 `pool.rs`）与 `src/client/legacy/client.rs`（下称 `client.rs`）的源码级梳理，是 §3 设计的对照基准。

### 2.1 分层与代码位置

```
reqwest::ClientBuilder ── pool_idle_timeout / pool_max_idle_per_host（reqwest client.rs:1498-1511）
        │ 透传（reqwest client.rs:980-981）
        ▼
hyper_util::client::legacy::Client ── 持有 Pool<PoolClient<B>, PoolKey>（client.rs:37-46）
        │ checkout / connecting / pooled / put
        ▼
Pool<T, K>（pool.rs）── 纯数据结构 + 一把 Mutex + 一个可选清扫任务
        │
        ▼
Poolable trait（pool.rs:35-42）── is_open() / reserve() / can_share()
        │ 由 PoolClient 实现（client.rs:850-883），内部是 hyper::client::conn 的 SendRequest
        ▼
hyper::client::conn::http1/http2 ── 裸连接握手与 dispatch（hyper 仓库）
```

注意 hyper 1.x 里 `hyper` crate 只剩 `conn`（裸连接），**池和高层 Client 都在 hyper-util 的 legacy 模块**；reqwest 包的就是这个 legacy Client。

### 2.2 核心数据结构

| 类型 | 位置 | 要点 |
|---|---|---|
| `Pool<T, K>` | pool.rs:25-28 | 单字段 `inner: Option<Arc<Mutex<PoolInner<T, K>>>>`；`None` = 池被禁用。`Clone` 共享同一 `Arc` |
| `PoolInner<T, K>` | pool.rs:77-102 | `connecting: HashSet<K>`（h2 建连去重）、`idle: HashMap<K, Vec<Idle<T>>>`、**`Vec` 当栈用 = LIFO**、`max_idle_per_host`、`waiters: HashMap<K, VecDeque<oneshot::Sender<T>>>`、`idle_interval_ref`（仅存来在池销毁时取消清扫任务）、`exec` / `timer` / `timeout` |
| `Idle<T>` | pool.rs:588-591 | `{ idle_at: Instant, value: T }` |
| `Config` | pool.rs:108-117 | `{ idle_timeout: Option<Duration>, max_idle_per_host: usize }`；`max_idle_per_host == 0` 即禁用池。**默认值由 Client Builder 给**：`idle_timeout = 90s`、`max_idle_per_host = usize::MAX`（client.rs:1043-1046）；`pool_timer` 默认 `None`（client.rs:1047）——**默认不主动清扫，只在 checkout 时惰性判过期** |
| `PoolKey` | client.rs:92 | `type PoolKey = (Scheme, Authority)`——只按 scheme + authority（含端口）。DNS 结果、path、代理状态都不在键里 |
| `Ver` | pool.rs:49-54 | `{ Auto, Http2 }`——只用于建连 single-flight，不描述已有连接 |
| `Reservation<T>` | pool.rs:56-72 | `Unique(T)`（h1 独占）/ `Shared(T, T)`（h2：一份回插 idle，一份交给取用者） |
| `Checkout<T, K>` | pool.rs:595-600 | 取连接的 Future；`Drop` 时清理自己挂的 waiter（pool.rs:725-734） |
| `Pooled<T, K>` | pool.rs:522-527 | `{ value: Option<T>, is_reused: bool, key: K, pool: WeakOpt<Mutex<PoolInner>> }`；`Deref` 到 `T`；**回池全靠它的 `Drop`** |
| `Poolable` | pool.rs:35-42 | `is_open()` / `reserve() -> Reservation` / `can_share()`——池对"连接"的全部要求 |
| `pool::Error` | pool.rs:603-613 | `PoolDisabled` / `CheckoutNoLongerWanted` / `CheckedOutClosedValue`；只有最后者算 `is_canceled()`，驱动重试 |

两个零碎但关键的辅助件：`WeakOpt`（pool.rs:106，包 `Option<Weak>`，因为 `Weak::new()` 要分配）；`Expiration`（pool.rs:772-778，统一用 `saturating_duration_since` 避免 `Instant` 减法 panic）。

### 2.3 取连接：checkout

`Pool::checkout(key)`（pool.rs:165-171）只构造 `Checkout` future，逻辑都在 `poll`（pool.rs:705-723）里：

1. **先查 waiter**（`poll_waiter`，pool.rs:628-652）：上一轮没拿到连接而停放的 oneshot 若已收到值，**收到后还要再查一次 `value.is_open()`**（pool.rs:635），已关闭则报 `CheckedOutClosedValue`。
2. **弹 idle 栈**（`IdlePopper::pop`，pool.rs:300-338），全程持锁：
   - `self.list.pop()`——**LIFO**（pool.rs:301）；
   - 跳过 `!entry.value.is_open()` 的（**关闭检查发生在弹出时**，pool.rs:304-307，惰性发现服务端已关的连接）；
   - 跳过 `now - idle_at > timeout` 的（过期检查同样在弹出时，pool.rs:314-317）；
   - 命中后 `entry.value.reserve()`（pool.rs:319）：`Shared` 把一份以新 `idle_at` 回插栈顶、交出另一份（pool.rs:321-327）；`Unique` 直接取走（pool.rs:328）。
3. 栈空则把 key 从 map 里删掉（pool.rs:679-682）。
4. 没拿到且还没挂过 waiter：建 oneshot、sender 进 `waiters[key]`（pool.rs:684-695），返回 `Pending`——**这只对 h2 single-flight 有意义**，h1 场景马上会被建连路径绕过（见 §2.5）。

**LIFO 的理由**（值得照抄）：最近用过的连接最热（TCP 拥塞窗口、TLS 状态、服务端 keep-alive 计时都最新鲜），复用它；最冷的连接沉在栈底，自然成为被 idle 清扫/过期检查杀掉的那批——在波动负载下保活的 socket 数最少。pool.rs:308-313 的 TODO 还指出：因为条目按时间追加，弹到一条过期即意味着剩下的全过期，但实现仍保持简单循环。

### 2.4 还连接：`Pooled::Drop` → `put`

hyper 没有显式的"归还"API——**`Drop for Pooled`（pool.rs:560-580）就是全部归还路径**：

1. `if !value.is_open() { return; }`（pool.rs:563-567）：已知死连接永不回池；
2. h1（`Unique`）连接持有池的 `Weak` 回引用，`upgrade` 成功则 `inner.put(key, value)`（pool.rs:569-572）；池已销毁则直接丢弃连接；
3. h2（`Shared`）连接**不带池回引用**——池里本来就留着一份克隆，drop 掉 checkout 出来的克隆即可（pool.rs:576-577 注释）。

`PoolInner::put`（pool.rs:348-412，调用方持锁）：

1. h2 且该 key 已有 idle 条目 → 直接丢弃多余克隆（pool.rs:349-352），**每 key 至多一条 idle h2**；
2. 先喂 waiter：`waiters[key]` FIFO 弹出，跳过已取消的，`reserve()` 后一份经 oneshot 交给等待者（pool.rs:357-388）；
3. 还有剩余则执行上限：`if max_idle_per_host <= idle_list.len() { return; }`——**超上限直接丢弃连接**（pool.rs:396-399），注意上限只在 put 时执行，清扫任务不管；
4. 否则 `push(Idle { value, idle_at: now })`（pool.rs:401-405），并 `spawn_idle_interval`（pool.rs:408）。

**h1 的"延迟归位"**（client.rs:348-363，最容易被忽略的一条）：响应头到达 ≠ 连接空闲。h1 连接要等响应 body 流完、dispatcher 重新 `poll_ready` 才真正可用，所以 Client 在 body 仍在流式传输时，会 spawn 一个任务持有 `Pooled` 直到 `poll_ready` 再 drop——**连接回 idle 栈的时刻 = 它真正可复用的时刻**。这条语义在我们的设计里以另一种方式天然成立（§3.5）。

### 2.5 建连与 checkout 的竞争（`one_connection_for`）

client.rs:391-481 是池与建连的编排骨：

```rust
let checkout = self.pool.checkout(key);
let connect  = self.connect_to(key);        // hyper_lazy：首次 poll 才真正开始干活
future::select(checkout, connect).await     // checkout 在前，顺序有意义
```

- **connect 是 lazy 的**（`common/lazy.rs`，闭包首次 poll 才执行）：checkout 若立即命中，TCP 连接**根本没发起**——零浪费；
- checkout 晚命中但 connect 已启动：把建连 spawn 到后台跑完，**新 socket 直接入池变 idle** 而不是浪费（client.rs:435-447）；
- connect 赢：drop checkout（其 `Drop` 清掉 waiter）。

**single-flight**：`Pool::connecting(key, ver)`（pool.rs:175-205）。`Ver::Http2` 时往 `connecting: HashSet<K>` 插入，已存在则返回 `None`（调用方改去等 checkout）；**HTTP/1 永远成功且不加锁不去重**——h1 允许多个并发建连。`Connecting` 是 RAII guard，`Drop` 调 `connected(&key)`（pool.rs:754-763 → 416-423）：既移出 `connecting`，又**drop 掉该 key 所有 waiter**——若建连任务死了，绝不让 waiter 饿死。

**新连接入池**：`connect_to`（client.rs:484-666）完成 TCP/TLS/握手后，`pool.pooled(connecting, value)`（pool.rs:223-265）：`reserve()` 为 `Shared` 时当场 `put` 一份进 idle 并消掉 guard；`Unique` 时 `Pooled` 带 `Weak` 回引用等 drop 时归位。`is_reused = false`（pool.rs:261）。连接的 dispatcher future 被 spawn 进 executor 后台跑，`SendRequest` 半部进 `PoolClient`。

### 2.6 空闲连接清扫

- **触发**：`spawn_idle_interval`（pool.rs:425-461）在每次 `put` 成功插入后调用。提前返回条件：已在跑（`idle_interval_ref.is_some()`）、未配 timeout、timeout 为 0、**未安装 timer**（pool.rs:437-441——所以默认配置下根本没有后台清扫，只有 checkout 时惰性过期）。
- **周期**：`max(timeout, MIN_CHECK)`，`MIN_CHECK = 90ms`（pool.rs:443-448）——亚 90ms 的 timeout 仍会在 checkout 时生效，只是不主动扫。
- **任务**：`IdleTask::run`（pool.rs:792-819）= `select(pool_drop_notifier, sleep_until(now + duration))` 循环；醒来后 `pool.upgrade()` → 锁 → `clear_expired()` → 重置 timer。
- **淘汰**：`clear_expired`（pool.rs:483-509）对每条 idle 查 `!is_open()` 或 `now - idle_at > timeout`，空栈删 key。
- **取消**：池销毁时 `PoolInner` 里的 oneshot sender 被 drop，receiver 解出 `Err(Canceled)`，任务退出（pool.rs:798-801）——**取消机制就是一个 oneshot，没有代数计数**。timer 任务持 `Weak`，永不给池续命。

**Exec/Timer 抽象**（hyper `src/rt/mod.rs:45-48`、`src/rt/timer.rs:70-88`）：`Executor` 只有一个 `execute(fut)`；`Timer` 有 `sleep`/`sleep_until`/`now`/`reset`。hyper 核心 crate 不依赖 tokio，池的清扫任务和 h2 keep-alive 都通过注入的 `TokioExecutor`/`TokioTimer` 跑。**这个抽象是为"runtime 无关"服务的，我们不需要**（§3.6）。

### 2.7 锁与线程

- 整个池一把 `std::sync::Mutex<PoolInner>`；所有变更路径都拿锁，但**临界区极小**：只有哈希表操作和 `is_open()` 检查，无 I/O、持锁期间不 `.await`。
- 建连（DNS/TCP/TLS/握手）完全在锁外；只有最终 `pooled()`/`put()` 拿锁。
- 回引用一律 `Weak`（`Pooled.pool`、`Connecting.pool`、`IdleTask.pool`），池与连接/任务互不续命。
- `Drop` 里拿锁用 `if let Ok(...)` 容忍中毒（pool.rs:757 注释："No need to panic on drop, that could abort!"）。

### 2.8 失败重试语义（精华，务必照抄）

`Client::send_request`（client.rs:241-272）的重试条件非常克制：

```
重试 ⟺ 请求被证明"从未到达线上"（TrySendError 把请求体原样带回，client.rs:327-333）
       ∧ connection_reused（pooled.is_reused()）
       ∧ config.retry_canceled_requests（默认 true）
```

要点：

- **不是按 HTTP 方法幂等性判断**——安全性来自"字节根本没写出去"，GET/POST 一视同仁；
- **新连接失败绝不重试**——那是真实故障；只有复用连接才可能撞上"服务端刚关了空闲连接"这种池自身引入的竞态，这个竞态由池负责吸收；
- 服务端随时可能关空闲连接（如 nginx 默认 `keepalive_timeout 75s`，比池的 90s 短），所以这个重试不是边缘情况，是池正确性的一部分。

### 2.9 poison pill

`Connected` 携带 `PoisonPill`（`Arc<AtomicBool>`，`connect/mod.rs:108-137`），`Connected::poison()` 是**公开用户 API**（connect/mod.rs:217-222）：调用方（如捕获到协议级不一致响应的中间层）可标记"此连接永不复用"。效果经 `PoolClient::is_open()`（client.rs:854-856 = `!poisoned && is_ready`）传导到池的所有出入口：弹出时跳过、drop 时不回插、清扫时淘汰。hyper-util 自身从不调 `poison()`。

### 2.10 reqwest 的暴露面

reqwest 对池只做两件事（`src/async_impl/client.rs`）：

- 配置：`pool_idle_timeout`（默认 `Some(90s)`，client.rs:302；`None` = 永不过期）、`pool_max_idle_per_host`（默认 `usize::MAX`，client.rs:303），builder 方法在 client.rs:1498-1511，透传给 hyper-util builder（client.rs:980-981）；
- 重试与重定向：reqwest 自己包 redirect 循环（hyper legacy Client 不做重定向），每跳重新过 `Client::request` → 重新算 `pool_key`——**同域重定向链自然共享连接**，零额外代码。

另有一个值得知道的联动：`build_http` 会把池的 `idle_timeout` 传给 `HttpConnector::set_keepalive` 当 TCP keep-alive 用（client.rs:1619-1623），让内核层保活节奏与池一致。

## 3. 本项目设计（对照 hyper 逐条映射）

### 3.1 总体架构

```
fetch::Client（重定向循环，include/fetch/client.hpp:112）
   │  每一跳走完整中间件链（代理选路在中间件，机制在 Transport）
   ▼
fetch::Transport 接口（include/fetch/transport.hpp）
   │
   ├── BeastTransport（现状：无池，保留为无池模式/对照实现）
   │
   └── PooledTransport（新）── 组合一个 ConnectionPool
          │  request() / request_via_socks5() / request_via_http_proxy()
          │  三个入口 = 三条既有建连路径，各自算出 PoolKey
          ▼
      ConnectionPool（新，include/fetch/connection_pool.hpp + src/fetch/connection_pool.cpp）
          │  checkout(PoolKey) → optional<PooledConnection>   （同步，LIFO pop + 过期/活性检查）
          │  put(PoolKey, IdleEntry)                          （同步，上限 + 唤醒清扫定时器）
          ▼
      PooledConnection（RAII 句柄，move-only）
          │  交付给 do_exchange_head → 归属转移到 BeastBodySource
          ▼
      BeastBodySource（改造）：body 读干且 keep_alive → put 回池；否则 close
```

分层对照：hyper 的 `Poolable`/`Pooled` ≈ 我们的 `PooledConnection`；hyper 的 `PoolInner` ≈ `ConnectionPool`；hyper legacy `Client` 的 `connection_for/connect_to` ≈ `PooledTransport::acquire`。中间件链、redirect 循环、`easy::Client` 全部不动。

### 3.2 与 hyper 的差异一览（每条都有理由）

| 维度 | hyper / hyper-util | 本项目设计 | 理由 |
|---|---|---|---|
| 线程模型 | 多线程，池内一把 `Mutex`，临界区无 I/O 不 await | **无锁**。池只允许在 io 线程访问（`debug_assert` 守线程契约） | 项目线程契约本就是"io 单线程驱动、无 strand"（`docs/fetch_cpp_decoupling.md` §4.2、`include/fetch/client.hpp:7-13`），锁是纯负担 |
| checkout/connect 竞争 | `future::select(checkout, lazy_connect)`，checkout 优先 | **不需要竞争**：单线程先同步 `checkout`，未命中再 `co_await` 建连 | hyper 的竞争源于多线程下"checkout 等待期间别人可能建好"；单线程顺序化后"lazy connect"天然成立——checkout 不命中前一行网络代码都不会跑 |
| waiter 队列 / single-flight | h2 用 `connecting: HashSet` + waiter oneshot | **不要**。h1 并发建连本就允许，与 hyper 的 h1 行为一致 | 我们没有 h2；给 h1 加 single-flight 反而损害并发首开性能 |
| 连接共享语义 | `Reservation::Unique/Shared` | **全部 `Unique`**（检出即从 idle 移除，归还才回插） | h1 连接是独占字节流，没有多路复用 |
| 活性检查 `is_open()` | dispatcher 的 want 状态 + poison 标志，廉价精确 | 分层降级：socket `is_open()` → plain TCP 加一次性 `MSG_PEEK` 探测 → **统一靠复用重试兜底**（§3.4、§3.7） | 我们没有 dispatcher 状态机可查；TLS 连接的死活在不写读前无法廉价确知（`close_notify` 可能还堆在 TCP 缓冲里），hyper 式 hint + 重试的组合拳照旧，只是 hint 更弱、重试更关键 |
| 池键 `PoolKey` | `(Scheme, Authority)` | `(scheme, host, port, proxy_id, tls_fingerprint)` | hyper 的代理在 connector 层，键外另有状态；我们的**代理选路在中间件层**（`middleware.hpp:471/497`），不同代理/TLS 选项产生的连接绝不能混用，必须进键（§3.8、§3.9） |
| 清扫任务 | 注入 `Exec`/`Timer` 抽象，后台 task + oneshot 取消 | `boost::asio::steady_timer` 直接挂在 io_context 上，`weak_ptr` 防续命 | hyper 抽象是为 runtime 无关；我们的 executor 已固定为 asio+stdexec，抽象无收益。`timers.hpp` 已有同款模式 |
| 归还 API | `Pooled::Drop` 即归还 | `PooledConnection` 析构即归还（可复用时），显式 `discard()` 即 poison | 同款 RAII；`discard()` 对应 `Connected::poison()` |
| 默认配置 | `idle_timeout=90s`、`max_idle_per_host=usize::MAX`、默认不装 timer | **照抄**，但我们始终装清扫定时器（steady_timer 成本可忽略），不设"无 timer"模式 | 行为对齐 reqwest 用户预期；简化心智 |
| 重试 | 复用 ∧ 请求未发出 ∧ 开关开启 | 同左，追加一个条件：**非流式上传**（`body_stream` 不可重放） | 我们的 `Request.body_stream` 是单向拉流（`include/fetch/types.hpp`），重放等于数据错乱 |
| 重定向 | legacy Client 不做；reqwest 每跳重算 pool_key | 现状即每跳走全链，**同域重定向链自动共享连接**，零改动 | 与 reqwest 相同 |

### 3.3 核心类型（`include/fetch/connection_pool.hpp`）

命名注意：`include/fetch/pool.hpp` 已被**文件读取线程池**占用，新文件用 `connection_pool.hpp`，类名一律带 `Connection` 前缀，避免混淆。

```cpp
namespace fetch {

// ---- 池键：hyper 的 (Scheme, Authority) 扩展版 ------------------------
struct PoolKey {
    std::string scheme;          // "http" | "https"
    std::string host;            // 小写规范化后的目标 host（或代理 host，见 §3.8）
    uint16_t    port = 0;        // 显式化后的端口（http=80, https=443）
    std::string proxy_id;        // 空 = 直连；否则 "socks5://u@h:p" / "connect://u@h:p" / "http://u@h:p"
    std::string tls_fingerprint; // 空 = 明文；否则 TLS 选项指纹（verify/额外 CA/最低版本），见 §3.9
    bool operator==(const PoolKey&) const = default;
};
struct PoolKeyHash { size_t operator()(const PoolKey&) const noexcept; };

// ---- 配置：对齐 reqwest 暴露面 ----------------------------------------
struct PoolOptions {
    std::optional<std::chrono::milliseconds> idle_timeout = std::chrono::seconds{90};
        // nullopt = 永不过期（对应 reqwest pool_idle_timeout(None)）
    size_t max_idle_per_host = std::numeric_limits<size_t>::max();
        // 0 = 禁用池（对应 hyper Config::is_enabled() == false）
    bool retry_on_reused_failure = true;
        // 对应 hyper retry_canceled_requests（默认 true）
};

// ---- 连接实体：现有三种 stream 的 variant ------------------------------
using PlainStream = boost::asio::ip::tcp::socket;
using TlsStream   = boost::asio::ssl::stream<boost::asio::ip::tcp::socket>;
using TunnelTls   = boost::asio::ssl::stream<TunnelStream>;   // HTTP CONNECT 隧道上的 TLS
using AnyStream   = std::variant<PlainStream, TlsStream, TunnelTls>;
// 选 variant 而非虚接口：三个类型已存在（BeastBodySource 模板实例化的就是它们），
// 静态分派零堆分配；若未来类型增多再改类型擦除。

struct IdleEntry {
    AnyStream                        stream;
    boost::beast::flat_buffer        buffer;   // 连接上残留的 over-read 字节，属于连接不属于请求
    std::shared_ptr<boost::asio::ssl::context> tls_ctx; // TLS 连接的 ctx 必须随连接存活（现状即如此）
    std::chrono::steady_clock::time_point idle_at;
};

// ---- RAII 句柄：hyper Pooled 的对应物 ---------------------------------
class PooledConnection {
public:
    PooledConnection(PooledConnection&&) noexcept;
    PooledConnection(const PooledConnection&) = delete;   // move-only，对应 Unique 语义

    AnyStream& stream();                                  // 交给 do_exchange_head / BeastBodySource
    beast::flat_buffer& buffer();                         // 带出残留字节
    std::shared_ptr<ssl::context>& tls_ctx();
    bool is_reused() const;                               // 对应 Pooled::is_reused，驱动重试统计/日志

    void discard();                                       // = hyper 的 poison：标记"永不复用"，析构时关闭
    IdleEntry release();                                  // 交出所有权（BodySource 读干回池时调用）
    ~PooledConnection();                                  // 未 release 且未 discard：按 keep-alive 判定回池或关闭（见 §3.5）
private:
    std::weak_ptr<ConnectionPool> pool_;                  // 对应 Pooled.pool 的 WeakOpt：互不续命
    PoolKey key_;
    std::optional<IdleEntry> entry_;
    bool is_reused_ = false;
    bool discard_ = false;
};

// ---- 池本体 ------------------------------------------------------------
class ConnectionPool : public std::enable_shared_from_this<ConnectionPool> {
public:
    ConnectionPool(boost::asio::io_context& io, PoolOptions opts);

    std::optional<PooledConnection> checkout(const PoolKey& key); // 仅 io 线程；同步；§3.4
    void put(PoolKey key, IdleEntry entry);                       // 仅 io 线程；同步；§3.5
    void close_all();                                             // Runtime 关闭/Client 析构时排空

    size_t idle_count() const;                                    // 测试/观测用
private:
    void ensure_sweeper();                                        // §3.6
    boost::asio::io_context& io_;
    PoolOptions opts_;
    std::unordered_map<PoolKey, std::vector<IdleEntry>, PoolKeyHash> idle_; // vector 当栈 = LIFO
    std::shared_ptr<boost::asio::steady_timer> sweeper_;          // 存在即在跑
};
} // namespace fetch
```

### 3.4 取连接流程（checkout，对应 `IdlePopper::pop`）

全部同步、仅 io 线程：

1. `idle_.find(key)`，无栈或栈空 → 返回 `nullopt`（调用方走既有建连路径，一行网络代码都没跑——单线程版的 "lazy connect"）；
2. 从栈顶 `pop_back` 循环（**LIFO**，理由同 hyper §2.3）：
   - **过期检查**：`idle_timeout` 有值且 `now - idle_at > idle_timeout` → 丢弃（`shutdown`+`close`，TLS 不费心做 `async_shutdown`，直接 lowest-layer close）；
   - **活性检查（分层降级版 `is_open()`）**：
     - `socket.is_open()` 为 false → 丢弃；
     - plain TCP 追加一次性探测：`recv(native_handle, &c, 1, MSG_PEEK | MSG_DONTWAIT)` 返回 0（对端 FIN）或 -1 且 `errno == ECONNRESET` → 丢弃；返回 1 或 `EAGAIN` → 视为存活。注意这只清掉"TCP 层已可见的死连接"；
     - **TLS 连接不做 MSG_PEEK 判活**：对端 `close_notify` 是 TLS 记录层数据，TCP 层 `MSG_PEEK` 看到的是密文有字节，会误判为存活。TLS 的死活交给 §3.7 的重试兜底（这正是 hyper 的组合：`is_open` 只是 hint，正确性由重试保证）；
   - 命中 → 构造 `PooledConnection{ is_reused = true, ... }` 返回；
3. 栈空 → 从 map 删 key（保持 map 紧凑，同 pool.rs:679-682）。

**与 hyper 的有意差别**：hyper 在 pop 时跳过死连接但不关清扫任务；我们同样只在 pop 时惰性清理。另外 hyper 的 TODO（pool.rs:308-313，"弹到一条过期即全部过期"）我们直接采纳——栈内条目按 `idle_at` 单调有序，过期弹栈时可一次性清空，少个循环。

### 3.5 还连接流程（put + BodySource 改造，对应 `Pooled::Drop` + 延迟归位）

**归还时机的 hyper 语义**：连接不是"响应头到了"就空闲，而是"body 流完"才空闲（client.rs:348-363 的延迟归位）。我们的现状恰好天然满足：建连完成后连接所有权本来就在 `BeastBodySource` 手里直到 body EOF 或析构——所以**归还点不需要新机制，就是 BodySource 的生命周期终点**。要改的是终点行为：

`BeastBodySource` 改造（`src/fetch/beast_transport.cpp:272-289` 一带）：

1. 构造时额外持有 `PooledConnection`（原来裸持 `shared_ptr<Stream>` 的位置改为持有句柄；stream/buffer/parser 的既有关系不变）；
2. `read()` 返回 `nullopt`（`parser.is_done()`）时判定：
   - `parser.keep_alive() == true`（beast 已综合 `Connection: close`、HTTP/1.0、`need_eof` 等情况）→ `pool->put(key, handle.release())`，连接带着 `flat_buffer` 里的残留字节一起回池；
   - 否则 → 维持现状：关闭；
3. **body 未读干就析构**（用户丢弃了响应流）→ 直接关闭，不回池。对应 hyper：h1 上有未读 body 时 drop 掉请求 future 会关连接（`http1.rs:205-233` 的 cancel-safety 注释）——h1 字节流上有未知残余数据，复用即错乱，没有第二种选择；
4. `cancel()`（AbortSignal 链路）→ 关闭，不回池；
5. 中途 I/O 错误 → 关闭不回池；若上层判定是协议级不一致（如 SRI 校验失败后的连接）→ 可调 `discard()` 显式 poison（对应 §2.9，首版只提供机制，中间件不主动调）。

`put` 本体（对应 `PoolInner::put`）：

1. 仅 io 线程；`discard` 标记或 `!socket.is_open()` → 直接关闭（对应 pool.rs:563-567）；
2. 该 key 栈长已达 `max_idle_per_host` → 丢弃关闭（对应 pool.rs:396-399，上限只在 put 执行）；
3. push `IdleEntry{ idle_at = now }`；`ensure_sweeper()`（§3.6）；
4. **无 waiter 分发**——我们没有 waiter 队列，这是与 hyper `put` 的唯一结构差异。

**新连接首次入池**（对应 `Pool::pooled`）：`PooledTransport` 建连成功后构造 `PooledConnection{ is_reused = false }`，**不预先 put**——h1 独占语义下连接要先服务完当前请求，归还发生在 BodySource 终点，与 hyper 的 `Unique` 分支（`Pooled` 带 Weak 等 drop 归位）完全同构。

### 3.6 空闲清扫（对应 `IdleTask`）

- 首次 `put` 插入后 `ensure_sweeper()` 建 `steady_timer`（io_context 上，与 `include/qjsbind/web/timers.hpp` 同款模式）；
- 周期 = `max(idle_timeout, 90ms)`（照抄 hyper 的 `MIN_CHECK` 下限，pool.rs:443-448）；`idle_timeout == nullopt` 则只扫死连接、周期固定 60s（防御性，基本扫不到东西）；
- 每跳回调：`weak_ptr<ConnectionPool>.lock()` 失败 → 不再 reschedule（对应 hyper 的 oneshot cancel-on-drop 与 `Weak` 不续命，pool.rs:798-801）；成功则遍历 map，丢弃 `!is_open()` 或过期的条目，空栈删 key；map 全空 → 停表（`sweeper_.reset()`），下次 `put` 再启动——对应 hyper "清扫任务懒创建、至多一个、池空自停"；
- `ConnectionPool` 析构 → 析构 `sweeper_` 即取消定时器，map 内所有 idle 连接随 `IdleEntry` 析构关闭。

### 3.7 陈旧连接与重试（对应 §2.8，池正确性的另一半）

`PooledTransport::request` 的骨架（实现期说明：重试判据为 `!write_done || header_eof`——
写失败即"请求从未上线"，另加"写成功但读响应头零字节 EOF/RST"的陈旧 keep-alive 放宽，见下）：

```cpp
auto handle = pool_->checkout(key);
bool reused = handle.has_value();
if (!handle) handle = co_await connect_fresh(key, ...);   // 既有 connect_tcp/exchange_over_tls 路径
bool write_done = false;                                   // 请求字节已全部交给内核
try {
    co_return co_await exchange(key, std::move(*handle), req, st);  // 写请求 + 读头 + 交出 BodySource
} catch (const boost::system::system_error& e) {
    // 写成功但读响应头零字节失败（end_of_stream/eof/stream_truncated/reset/aborted）
    const bool header_eof = e.code() == http::error::end_of_stream
        || e.code() == asio::error::eof
        || e.code() == ssl::error::stream_truncated
        || e.code() == asio::error::connection_reset
        || e.code() == asio::error::connection_aborted;
    if (reused && opts_.retry_on_reused_failure
        && !req.body_stream            // 流式上传不可重放（hyper 未写可带回 body 重放，我们保守排除）
        && (!write_done                // 请求"从未上线"= 写阶段失败，等价 hyper 的 TrySendError
            || header_eof)             // 写成功但读响应头零字节 EOF/RST = 陈旧 keep-alive（额外放宽）
        && e.code() != asio::error::operation_aborted) {             // 用户取消不重试
        handle2 = co_await connect_fresh(key, ...);                  // 只重试一次
        co_return co_await exchange(key, std::move(*handle2), req, st);
    }
    throw;
}
```

语义与 hyper 逐条对齐（实现期说明：初稿以 `!headers_started`（响应头一字未达）作重试
判据，后收紧为 `!write_done`，但实现最终保留了两种形态：`!write_done`（写阶段失败 =
请求从未上线，等价 hyper 的 TrySendError，request 原样带回可重放）与 `header_eof`
（写成功但读响应头零字节 EOF/RST = 陈旧 keep-alive 半开）。注意后者是相对 hyper 的
额外放宽——hyper 只在"请求从未开始写"时重试（message 原样带回），写成功后的读头
失败属在飞失败（message 不可带回）、不重试；我们靠"请求大概率未被服务端处理"的
假设兜底（curl 风格），stale 连接上服务端已关闭、FIN/RST 丢弃随后的请求字节，
重试基本安全，代价是极小概率下服务端已处理请求时可能重复（非幂等风险））：

- **只有复用连接触发的失败才重试**——fresh 连接失败是真实故障，直接抛（client.rs:257-261）；
- **安全性来自"请求从未上线"而不是方法幂等性**——`write_done == false` 时写阶段
  失败，服务端要么没收到、要么收到不完整请求（h1 服务端忽略不完整请求）；
  GET/POST 一视同仁；
- 服务端随时关空闲连接（nginx 默认 75s < 我们默认 90s），这条路径不是边缘情况，必须有测试覆盖（§5）。

### 3.8 代理下的池化（hyper 没细做，我们显式设计）

hyper 的 `PoolKey` 不含代理维度（代理藏在 connector 里），reqwest 混用代理时只能依赖"同一 Client 的代理配置不变"。我们的代理是 **ProxyMiddleware 统一选路**（请求级 > 实例级 URL 分流/默认 > 进程级，见 middleware.hpp），同一 Client 不同请求可走不同代理，键必须显式区分：

| 路径 | Transport 入口 | PoolKey 取法 | 可复用范围 |
|---|---|---|---|
| 直连 | `request()` | `(scheme, host, port, "", tls_fp)` | 同 origin |
| SOCKS5 隧道 | `request_via_socks5()` | `(scheme, 目标host, 目标port, "socks5://[user@]h:p", tls_fp)` | 同目标 × 同代理（隧道端到端，与目标绑定） |
| CONNECT 隧道 | `request_via_http_proxy()` 的 https 分支 | 同上，`proxy_id = "connect://[user@]h:p"` | 同目标 × 同代理 |
| http 正向代理明文转发 | `request_via_http_proxy()` 的 http 分支 | `("http", 代理host, 代理port, "http://[user@]h:p", "")` | **跨 origin 共享**——absolute-form 转发允许同一条代理连接服务任意 http 目标，这是正向代理白捡的复用红利 |

`proxy_id` 含用户名不含密码：密码不进键避免落日志。注意：同 host/port/用户名但
**不同密码**的代理配置会共享连接（密码不参与键）——与 hyper 的"代理藏在
connector 里、键不含代理凭证"同层语义；若目标代理按连接记忆认证态，换密码后
需重建 Client（池随 Client 销毁）。

三个入口函数签名不变（`transport.hpp` 的 `Transport` 接口不动），`PooledTransport` 在各自入口内算好 key 再走 §3.7 骨架；隧道建立（`socks5_connect`、`http_proxy_connect`）与 `TunnelStream` 包裹逻辑原样复用。

### 3.9 TLS 上下文缓存（顺带收益）

现状每请求 `make_ssl_context`（`beast_transport.cpp:106-158`）建一个全新的 `ssl::context`——这本身就浪费，池化后更显眼（连接都复用了，首连还要重建上下文）。设计：

- `PooledTransport` 内挂一个 `tls_fingerprint → shared_ptr<ssl::context>` 的小缓存（指纹 = verify 开关 + 额外 CA PEM 哈希 + 最低版本；容量上限 32，满则 LRU 淘汰）；
- `PoolKey.tls_fingerprint` 即此指纹，保证"连接用的 ctx"与"键描述的 ctx"一致——`IdleEntry.tls_ctx` 存的就是缓存里的同一个 `shared_ptr`；
- 可选增强（不进首版）：给缓存的 `SSL_CTX` 开 `SSL_SESS_CACHE_CLIENT`，首连之外还能拿到 TLS session resumption，把 2-RTT 压到 1-RTT。hyper 层不做这件事（rustls/native-tls 各自在 connector 处理），我们做了就是比参照物多赚的部分，单列里程碑。

### 3.10 配置暴露（对齐 reqwest 命名）

- `fetch::Options`（`include/fetch/types.hpp:67`）新增 `pool` 字段（`PoolOptions`，默认即上表默认值）；
- `easy::ClientBuilder`（`include/fetch/easy.hpp`）新增两个方法，命名直接对齐 reqwest：
  - `pool_idle_timeout(std::optional<std::chrono::milliseconds>)`
  - `pool_max_idle_per_host(size_t)`（`0` = 关池，等价 reqwest 的同名语义）
- `easy::ClientBuilder::transport(...)` 已有自定义入口；默认构造时改为 `PooledTransport`（`Options::pool.max_idle_per_host == 0` 时退化为无池行为，不必单独实例化 `BeastTransport`）；
- JS 绑定层**零改动**：池对 `fetch()` 透明。

### 3.11 取消与线程安全边界

- 池本体：仅 io 线程访问，无锁；`debug_assert`（或 `assert` on `std::this_thread::get_id()`）守契约；
- 在飞连接的取消链不变：`stop_callback` → `socket.cancel()/lowest_layer().close()`（可能跨线程触发，沿用 `fetch_cpp_decoupling.md` §4.2 的既有约定）。被取消的连接不会回池（§3.5-4），池永远不会持有"正在被 cancel 的"连接——cancel 只发生在连接被 `PooledConnection`/`BodySource` 持有期间，此时它不在 idle 栈里；
- idle 栈里的连接**没有任何挂起的异步操作**（回池前 body 已读干、无在读），因此无需对 idle 连接做跨线程防护；
- 生命周期：沿用"io 必须长于 Client 与在飞请求"。`ConnectionPool` 由 `PooledTransport` 以 `shared_ptr` 持有，`PooledConnection`/`BodySource`/清扫定时器一律 `weak_ptr` 回指——池可以先于句柄销毁，句柄 upgrade 失败即退化为直接关闭（对应 hyper 全链 `Weak` 的设计，§2.7）；
- `Runtime::shutdown` 排空（`include/qjsbind/loop.hpp`）时，`close_all()` 提供显式排空入口，避免 io_context 停止后 idle socket 才析构的尴尬。

### 3.12 首版刻意不做的简化（记录在案）

1. 不做 h2 的 `Ver`/`Shared`/single-flight/waiter 全家桶（无 h2）；
2. 不做"checkout 与 connect 竞争 + 输家后台跑完入池"（单线程下该竞态不存在；且 hyper 这么做是为了不浪费已启动的 TCP 连接，我们压根不会提前启动）；
3. 不做 TLS 闲置连接的`close_notify` 主动探测（依赖重试兜底，见 §3.4）；若日后实测陈旧 TLS 连接重试率过高，再加"回池时挂一个 0 字节 `async_read` 看门狗，有数据/EOF 即剔除"的方案——那是 hyper 也没有的东西，按需再加；
4. 不做 DNS 缓存、不做全局连接数上限、不做每 host 并发上限排队。

## 4. 文件落点

| 文件 | 动作 | 内容 |
|---|---|---|
| `include/fetch/connection_pool.hpp` | 新增 | `PoolKey`/`PoolOptions`/`IdleEntry`/`PooledConnection`/`ConnectionPool`（§3.3） |
| `src/fetch/connection_pool.cpp` | 新增 | checkout/put/清扫定时器/MSG_PEEK 探测 |
| `include/fetch/pooled_transport.hpp` + `src/fetch/pooled_transport.cpp` | 新增 | `PooledTransport : public Transport`；复用 `beast_transport.cpp` 抽出的共用函数；§3.7 重试骨架；§3.9 TLS ctx 缓存 |
| `src/fetch/beast_transport.cpp` | 改造 | ① `BeastBodySource` 改持 `PooledConnection`（或抽象出的"归还回调"），EOF 按 `keep_alive()` 决定回池/关闭（§3.5）；② `connect_tcp`/`exchange_over_tls`/`do_exchange_head` 提为可被 PooledTransport 复用的自由函数（移出匿名命名空间或抽到内部头）；③ `make_ssl_context` 支持外部传入缓存的 `shared_ptr<ssl::context>` |
| `include/fetch/types.hpp` | 小改 | `Options` 加 `PoolOptions pool` 字段 |
| `include/fetch/easy.hpp` | 小改 | `ClientBuilder::pool_idle_timeout` / `pool_max_idle_per_host`（§3.10） |
| `tests/connection_pool_test.cpp` | 新增 | §5 用例 |
| `tests/wpt_server.hpp` | 可能小改 | 需要一个能辨识"同一连接"的测试钩子（§5） |

不触碰：`Transport` 接口、中间件链、`fetch::Client` 重定向循环、JS 绑定层。

## 5. 测试计划

基础设施：`tests/wpt_server.hpp` 的 beast 测试服务端**已支持 keep-alive**（`res.keep_alive(req.keep_alive())`，wpt_server.hpp:210），只需加一个辨识连接的钩子——例如响应头回写服务端侧连接序号（accept 计数），或测试客户端直接断言 `socket.native_handle()`/远端端口不变。

| # | 用例 | 断言 |
|---|---|---|
| 1 | 同 host 连续两请求 | 第二请求复用连接（连接序号相同）；`is_reused() == true` |
| 2 | LIFO 语义 | 先后归还 A、B 两条连接，下次 checkout 拿到 B |
| 3 | body 读干才回池 | 第一请求只读一半 body → 连接不复用（新请求走新连接）；读干 → 复用 |
| 4 | `Connection: close` 响应 / `need_eof` 响应 | 连接不回池 |
| 5 | `max_idle_per_host = 1`，归还两条 | 后还的被丢弃关闭，池中只有一条 |
| 6 | `max_idle_per_host = 0` | 行为等同无池，每次新建 |
| 7 | 短 `idle_timeout`（如 100ms）+ 清扫定时器 | 到期后 idle 连接被回收，`idle_count() == 0`；定时器在池空后自停 |
| 8 | **陈旧连接重试**：请求一完成后，测试服务端强行 close 该连接（客户端不感知），再发请求 | 客户端自动换新连接重试且请求成功一次到位（对齐 hyper §2.8） |
| 9 | fresh 连接失败 | 不重试，错误原样上抛 |
| 10 | 流式上传（`body_stream`）在复用连接上失败 | **不**重试 |
| 11 | 并发 N 个请求打向冷 host | 建立 N 条连接（h1 无 single-flight），全部成功后 N-1 条进 idle（受上限约束） |
| 12 | 同域重定向链 | 各跳共享连接 |
| 13 | SOCKS5 / CONNECT 隧道复用 | 同目标同代理复用；不同目标不复用；不同代理不复用 |
| 14 | http 正向代理 | 两个不同 http origin 经同一代理 → 共享一条代理连接 |
| 15 | AbortSignal 取消在读 body 中途 | 连接关闭不回池；池状态不腐化，后续请求正常 |
| 16 | TLS：同 host 两请求 | 复用；且第二请求未重建 `ssl::context`（指纹缓存命中计数断言） |
| 17 | 池先于 `PooledConnection` 销毁 | 句柄析构退化为关闭，不崩溃不悬挂 |

## 6. 里程碑

- **M1 池核心 + 明文直连**：`connection_pool.{hpp,cpp}`（checkout/put/LIFO/上限）、`PooledConnection`、`BeastBodySource` 归还改造、http 直连复用；用例 1-6、11-12。
- **M2 TLS + ctx 缓存**：TLS 连接入池、`tls_fingerprint` 缓存；用例 16。
- **M3 清扫 + 重试**：清扫定时器、过期、`retry_on_reused_failure` 骨架；用例 7-10、15、17。
- **M4 代理池化 + 配置暴露**：三条代理路径的 key 设计落地、`easy::ClientBuilder` 两个新方法、`Options::pool`；用例 13-14；更新 `docs/fetch_milestone_progress.md`。
- **可选 M5**：`SSL_SESS_CACHE_CLIENT` session resumption（§3.9）；idle 连接 0 字节读看门狗（§3.12-3，视实测决定）。

## 7. 开放问题

1. **plain 连接 MSG_PEEK 探测的跨平台性**：`recv(..., MSG_PEEK | MSG_DONTWAIT)` 在 Windows（Winsock `MSG_PARTIAL`/无 `MSG_DONTWAIT`，需 `ioctlsocket(FIONBIO)` 或先 `WSAEventSelect`）语义不同。首版可以只做 POSIX 探测、Windows 退化为只靠重试兜底；或干脆全平台不探测，统一靠 §3.7 重试（hyper 在没有任何探测的情况下也只靠 dispatcher hint + 重试，代价是偶发一次重试延迟）。倾向：**首版全平台不探测，只查 `is_open()`**，把复杂度留给实测数据说话。
2. **`idle_timeout` 默认值 90s 与常见服务端 75s 的倒挂**：hyper/reqwest 用户也活在这个倒挂里，靠重试吸收。我们照抄 90s 对齐心智，但在 `easy` 文档注释里写明"若目标服务端 keep-alive 超时更短，调小本值可减少首包重试"。
3. **PooledTransport 与 BeastTransport 的代码复用粒度**：改造 `beast_transport.cpp` 抽出共用函数 vs 直接参数化 `BeastTransport` 加一个可选池成员。前者边界清晰（两个 Transport 实现），后者改动面小。倾向参数化方案——`BeastTransport` 加一个 `shared_ptr<ConnectionPool>` 可选成员（null = 无池），`PooledTransport` 只作为 `easy` 层的构造便利存在，避免两套传输代码漂移。实现期定稿。

## 8. 附录：hyper 侧关键源码索引

本地快照：`build/tmp/hyper-util-src`（`4684c71`）、`build/tmp/hyper-src`（`8a98d13`）、`build/tmp/reqwest-src`（`17e9bcb`）。**仅供对照阅读，勿提交入库**（`build/` 已在 `.gitignore` 内）。

| 主题 | 位置 |
|---|---|
| 池数据结构（Pool/PoolInner/Idle/Config） | hyper-util `src/client/legacy/pool.rs:25-141,588-591` |
| `Poolable` trait / `Reservation` / `Ver` | pool.rs:35-72,49-54 |
| checkout / `IdlePopper`（LIFO、过期、is_open、reserve） | pool.rs:165-171,294-338,654-723 |
| waiter 机制与 `Checkout::Drop` 清理 | pool.rs:628-652,684-695,725-734,469-479 |
| single-flight（`connecting` / `Connecting` guard / `connected()`） | pool.rs:175-205,738-763,416-423 |
| 新连接入池 / 复用包装（`pooled` / `reuse`） | pool.rs:223-290 |
| 归还（`Pooled::Drop` / `put` / 上限 / h2 去重） | pool.rs:560-580,348-412 |
| 空闲清扫（`spawn_idle_interval` / `IdleTask` / `clear_expired` / 90ms 下限） | pool.rs:425-461,781-819,483-509 |
| `WeakOpt` / `Expiration`（saturating 减法） | pool.rs:106,822-838,772-778 |
| legacy Client 请求编排骨（retry、`one_connection_for`、lazy connect 竞争） | hyper-util `src/client/legacy/client.rs:241-481`；`common/lazy.rs` |
| `PoolClient` 的 `Poolable` 实现（h1 Unique / h2 Shared） | client.rs:766-883 |
| h1 延迟归位（body 流完才算 idle） | client.rs:348-363 |
| 默认池配置（90s / usize::MAX / 默认无 timer） | client.rs:1043-1047,1561-1566 |
| poison pill（`Connected::poison` / `PoisonPill`） | hyper-util `src/client/legacy/connect/mod.rs:101-137,217-222` |
| pool_key 提取（scheme+authority） | client.rs:92,933-955 |
| TCP keep-alive 与池 idle_timeout 联动 | client.rs:1619-1623 |
| h1 连接语义（`is_open` 只是 hint；取消 in-flight 请求 = 关连接） | hyper `src/client/conn/http1.rs:167-176,205-233` |
| `Executor` / `Timer` 抽象（我们不需要，但要知道为什么存在） | hyper `src/rt/mod.rs:45-48`、`src/rt/timer.rs:70-88` |
| reqwest 池配置暴露与默认值 | reqwest `src/async_impl/client.rs:174-175,302-303,980-981,1498-1511` |
