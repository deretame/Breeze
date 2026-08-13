# DNS 解析器抽象与缓存设计文档

> 状态：已实现（§6 步骤 1–6 + §4.2 DoH；剩 JS 绑定，见 §6 步骤 7）。实现备注：
> `CachingResolver` 构造函数带 `boost::asio::io_context&` 首参（singleflight 等待者的
> 唤醒 timer 需要 io）；`DnsResolver` 增加 `report_success(host, service, addr)` 虚方法
> （默认空实现，CachingResolver 覆写）作为 §3.3 last_good 的回报通道。
> DoH（§4.2）与备忘的出入：`DohOptions` 增加 `timeout`（默认 5s，单次查询超时，
> 备忘未列）；A 与 AAAA 各发一个查询（先 A 后 AAAA 合并）；RCODE=3（NXDOMAIN）
> 抛 `system_error(host_not_found)` 供缓存层负缓存；内部传输为专用
> BeastTransport + 独立连接池（复用到 DoH server 的连接），超时经内层
> stop_source 级联取消实现。
> 前置文档：`docs/proxy_pool_review.md`（H1/H2/M6 审查发现）、`docs/fetch_connection_pool_design.md`、`docs/fetch_cpp_decoupling.md`。
> 相关代码：`src/fetch/beast_transport.cpp:591-623`（connect_tcp）、`src/fetch/socks5.cpp:100-110`、`src/fetch/http_proxy.cpp:25-35`、`include/fetch/transport.hpp`、`include/fetch/types.hpp`（Options/PoolOptions）。

## 1. 背景与动机

### 1.1 现状

三处建连路径各自现造 `tcp::resolver`，裸调 asio `async_resolve`（即系统 `getaddrinfo`），完全无缓存：

- `beast_transport.cpp:618-620`（直连）
- `socks5.cpp:100-101`（SOCKS5 代理地址解析；注意目标 host 由代理远端解析，本地只解析代理地址）
- `http_proxy.cpp:25-26`（HTTP 代理地址解析；同理）

代价与问题：

1. **延迟**：连接池省了 TCP/TLS 握手，但每个首连及池内连接过期后的重连仍付一次完整 DNS。Linux 默认无系统级缓存（除非 nscd/systemd-resolved）；Windows dnscache 语义不可控。
2. **取消空洞（review H2）**：asio resolver 在内部线程池跑阻塞式 `getaddrinfo`，慢 DNS 时占住 resolver 线程，且 stop_token 在 resolve 期间无效，取消延迟可达数十秒。
3. **只连第一个端点（review H1）**：`async_connect(*results.begin(), ...)` 丢弃其余 A/AAAA 记录。
4. **无 TTL 概念**：`getaddrinfo` 不返回 TTL，任何基于它的缓存只能拍固定上限——这决定了 DoH 的独特价值（§4.2）。

### 1.2 目标

- 引入 **`DnsResolver` 抽象**（与 `Transport` 同级的可替换接缝），三处 resolve 调用点统一走它。
- 提供 **`CachingResolver`**：包装任意底层 resolver，加内存缓存（TTL/LRU/负缓存策略）。
- **为 DoH 预留空间**：抽象设计从第一天起按"上游可插拔、结果带 TTL"建模，DoH 作为后续一个 `DohResolver` 实现插入，不需要改动接口与调用点。
- 顺带修复 review H1（解析结果整体传递，由连接层循环尝试所有 endpoint）。

### 1.3 非目标

- **不做 DoT**：相对 DoH 无功能优势（同样加密、同样拿 TTL），853 端口易被掐，公共端点少，且需自行处理 TCP 分帧；curl/Node 同样只做 DoH。如未来有明确需求，`DnsResolver` 接口可容纳，但本期不设计。
- 不做 happy eyeballs（RFC 8305 双栈竞速）：仅做"按上次成功排序 + 依次尝试"的简化版（§3.3）。
- 不做 mDNS / /etc/hosts 之外的本地名称解析扩展。
- 不改 SOCKS5/CONNECT 的语义：目标 host 仍由代理远端解析（这是正确行为，本地解析目标会泄露且破坏远端选路）。

## 2. 接口设计

### 2.1 核心类型

```cpp
// include/fetch/dns_resolver.hpp
namespace fetch {

// 单个解析结果：已解析的地址 + 可选 TTL。
// 系统解析（getaddrinfo）拿不到 TTL → ttl = nullopt，由缓存层用固定上限（§3.2）。
// DoH 解析 → ttl 取自应答报文的资源记录真实值。
struct DnsEntry {
    asio::ip::address addr;   // v4 或 v6
    std::optional<std::chrono::seconds> ttl; // nullopt = 上游未提供
};

// 一次解析的完整结果集（而非单个地址）：
// - H1 修复要求连接层能尝试所有 endpoint，故接口传递整个列表；
// - 列表顺序即建议尝试顺序（实现可按历史成功率排序，见 §3.3）。
using DnsResult = std::vector<DnsEntry>;

// DNS 解析抽象。实现必须可跨线程安全调用（stop_token 可能在其他线程触发，
// 与 Transport 契约一致：include/fetch/transport.hpp:3）。
struct DnsResolver {
    virtual ~DnsResolver() = default;

    // 解析 host（主机名或字面 IP）+ service（端口字符串）。
    // - host 为字面 IP 时必须短路返回，不发起任何网络查询（§3.1）。
    // - 失败抛 std::exception；st 触发时尽快以 stopped 完成（修复 H2 的责任在实现侧）。
    virtual std_exec::task<DnsResult> resolve(std::string host, std::string service,
                                              std::stop_token st) = 0;
};

} // namespace fetch
```

设计要点：

- **结果带 TTL 是 DoH 预留的核心**：`getaddrinfo` 返回不了 TTL，所以字段必须是 `optional`——接口容忍"上游不知道"，缓存策略在"知道时用真值、不知道时用上限"（§3.2）。若现在把 TTL 漏掉，将来 DoH 接入时接口必须breaking change。
- **整个列表传递**（而非逐条 callback）：同时满足 H1 修复与缓存的天然粒度（缓存的就是一份列表）。
- **`service` 用字符串**：与 asio resolver 对齐，避免在 DNS 层做端口校验（端口校验留在 `connect_tcp`，与 review M6 的统一校验修复不冲突）。

### 2.2 实现一：`SystemResolver`（现状的搬家 + H2 修复）

```cpp
// 包装 asio tcp::resolver（getaddrinfo）。行为等同现状，外加：
// - 字面 IP 短路；
// - stop_callback 同时 resolver.cancel()（修复 review H2：resolve 阶段可取消）；
// - 结果 ttl 一律 nullopt。
class SystemResolver : public DnsResolver { /* io_context& */ };
```

这是默认实现，未配置缓存时行为与现状完全一致（零回归面）。

### 2.3 实现二：`CachingResolver`（装饰器）

```cpp
// 包装任意底层 DnsResolver，加内存缓存。装饰器形态是 DoH 预留的另一半：
// DohResolver 落地后直接 CachingResolver{DohResolver{...}} 即获得带真 TTL 的缓存，
// 缓存代码零改动。
struct DnsCacheOptions {
    std::chrono::seconds max_ttl{60};      // 上游无 TTL 时的固定上限（对齐 Java
                                           // networkaddress.cache.ttl / Node 默认 30s 量级）
    std::chrono::seconds negative_ttl{5};  // 负缓存（解析失败）时长；防 DNS 抖动放大，
                                           // 又避免一次失败把域名拉黑数分钟
    size_t capacity = 256;                 // 条目上限，LRU 淘汰
};

class CachingResolver : public DnsResolver {
public:
    CachingResolver(std::shared_ptr<DnsResolver> upstream, DnsCacheOptions opt = {});
};
```

缓存键：`(host 小写规范化, service)`。service 进键是因为同一域名不同端口的解析结果集相同但将来 DoH 实现可能支持 SRV 类语义，保守进键不损失什么（getaddrinfo 本身也按 service 过滤数值端口）。

### 2.4 与连接层（`connect_tcp` 等）的接缝

`connect_tcp` 签名增加 resolver 参数（或经 `BeastTransport` 成员注入，见 §5），内部改为：

```
results = co_await resolver->resolve(host, port, st);   // 整个列表
// H1 修复：依次尝试所有 endpoint，全部失败才抛最后一个错误
for (const auto& e : results) { try { co_await sock->async_connect(e.addr, ...); break; } ... }
```

SOCKS5 / HTTP 代理路径同理：**只替换"解析代理地址"这一步**；发给代理的 CONNECT 目标 / SOCKS5 请求仍携带原始目标域名，语义不变（§1.3）。

## 3. 缓存策略（CachingResolver 细节）

### 3.1 字面 IP 短路

`host` 能被 `asio::ip::make_address` 解析时直接返回单元素列表（ttl=nullopt），不进缓存、不触上游。代理配置里写 IP 是常见形态，避免缓存被一次性条目污染。

### 3.2 TTL 决策

- 条目有真 TTL（未来 DoH）：`expires = now + min(ttl, max_ttl)`——`max_ttl` 兼作真 TTL 的上限钳制，防异常报文给超大值。
- 条目无 TTL（getaddrinfo）：`expires = now + max_ttl`（默认 60s）。
- **负缓存**：上游抛错时缓存"失败 + negative_ttl"，期间直接重放上次的异常副本（错误码而非异常对象，避免异常跨协程复用的坑）。

### 3.3 端点排序（简化版 happy eyeballs）

缓存命中且上次连接成功的地址仍在列表中时，把它排到最前。这是对 H1 修复的补充：多 A/AAAA 记录下优先走历史上可达的地址，避免每次都先撞一个不可达端点。排序信息只存在缓存条目里（一个 `last_good` 下标），连接层无感知。真正的双栈竞速（RFC 8305）不做（§1.3）。

### 3.4 并发与击穿

- 所有缓存访问限定 io 线程（与 `ConnectionPool` 同一契约：仅 io 线程访问，`assert_io_thread` 同款守卫），不需要锁。
- **单飞（singleflight）**：同 key 解析进行中时，后续协程挂起等待首个完成并共享结果，防缓存失效瞬间的击穿（连接池集中过期时会真实发生）。实现：条目状态 = `Ready(result)` | `Pending(等待者列表)` | `Negative(error)`。

### 3.5 与连接池的关系（明确不做的事）

IP 变更后池里旧 IP 的活连接继续可用（池键是 host 不是 IP），**不做**缓存失效联动清池。DNS 缓存与连接池是两层独立的复用，各自过期即可。

## 4. DoH（DNS over HTTPS，RFC 8484）

### 4.1 接口层面已经预留的部分

| 预留点 | 位置 | DoH 落地时的收益 |
|--------|------|------------------|
| `DnsEntry::ttl` 为 optional | §2.1 | 报文真 TTL 直接填入，接口不变 |
| `CachingResolver` 是装饰器 | §2.3 | `CachingResolver{DohResolver{}}` 组合即用 |
| 结果集为列表且排序语义在缓存层 | §2.1/§3.3 | DoH 的 A/AAAA 混合应答天然契合 |
| 三处调用点统一走 `DnsResolver` | §2.4 | DoH 只新增一个类，不改任何调用点 |

### 4.2 `DohResolver` 实现要点（已实现：`include/fetch/doh_resolver.hpp` + `src/fetch/doh_resolver.cpp`）

- 传输：HTTPS `POST /dns-query`（`application/dns-message`，RFC 8484），内部专用
  `BeastTransport`（自带连接池，复用到 DoH server 的连接）；wire format
  （RFC 1035）自行打包/解包（`build_dns_query` / `parse_dns_response`，传输无关
  的自由函数，可独立单测），不引新依赖。A 与 AAAA 各发一个查询（先 A 后 AAAA
  合并结果）；应答的 A/AAAA 记录真 TTL 填入 `DnsEntry::ttl`（上限钳制仍在缓存层
  `max_ttl`，解析层不重复）。
- **循环依赖**：内部传输的 `DnsOptions::custom_resolver = SystemResolver`——DoH
  server 域名永远走系统解析，绝不递归进 DohResolver 自身。构造时校验 endpoint
  必须 https；host 建议字面 IP（不强制，非字面 IP 时经 SystemResolver 解析）。
- SNI/证书校验用 DoH 服务器 host；`TlsOptions` 沿用全局配置（BeastTransport 组装
  时传入自身 tls）。
- 应答处理：报文严格边界检查（指针压缩跳转限 128 次防环、指针/标签/RDATA 越界
  均抛错）；响应 ID 与查询 ID 校验回显；RCODE≠0 → 抛错（RCODE=3 NXDOMAIN 抛
  `host_not_found`，供缓存层负缓存）；只提取 CLASS=IN 的 A/AAAA 记录（RDLENGTH
  必须恰为 4/16，否则视为畸形抛错），跳过 CNAME 等其余类型。
- 超时：`DohOptions::timeout`（默认 5s）单次查询超时——内层 stop_source 级联
  取消传输 + deadline timer（connect_util.hpp HandshakeDeadline 同款分流），超时
  抛 `timed_out` 触发 fallback 而非拖住请求。
- 配置面：`DnsOptions` 增加 `std::optional<DohOptions> doh`，
  `DohOptions { std::string endpoint; bool fallback_to_system = true; milliseconds timeout = 5s; }`。
  `fallback_to_system` 控制 DoH 失败（网络错/超时/RCODE 错/NODATA）时是否回落
  内部 SystemResolver 重试一次（隐私与可用性的权衡，默认回落，与 Firefox 语义
  一致）；用户取消不 fallback，直接传播 stopped。
- 组装链：`custom_resolver` >（有 doh）`CachingResolver{DohResolver}` >
  （无 doh）`CachingResolver{SystemResolver}` > `SystemResolver`
  （cache_enabled=false 且无 doh）；cache_enabled=false 且有 doh 时裸 DohResolver。

### 4.3 明确不做：DoT

理由见 §1.3。若未来翻案，`DnsResolver` 接口同样可容纳 `DotResolver`，本设计不阻碍。

## 5. 配置面与接线

```cpp
// types.hpp Options 增加：
struct DnsOptions {
    bool cache_enabled = true;       // 默认开缓存（行为改进，无 API 变化）
    DnsCacheOptions cache{};
    std::shared_ptr<DnsResolver> custom_resolver; // 非空则完全接管（测试/高级用户）
    std::optional<DohOptions> doh;   // §4.2，非空 → CachingResolver{DohResolver}
};
```

- `BeastTransport` 构造时按 `DnsOptions` 组装：`custom_resolver` >（有 doh）`CachingResolver{DohResolver}` > `CachingResolver{SystemResolver}` > `SystemResolver`，持有 `shared_ptr<DnsResolver>` 成员。
- `connect_tcp` / `socks5_connect` / `http_proxy_connect` 改为接收该成员（参数或捕获），三处替换为 §2.4 形态。
- JS 绑定层暂只暴露开关与 TTL（`fetch.setDnsCache({ maxTtl, ... })`），DoH 端点的 JS 绑定仍为 backlog（C++ 侧 `DohOptions` 已落地，§4.2）。

## 6. 实施步骤

1. `include/fetch/dns_resolver.hpp`：`DnsEntry`/`DnsResult`/`DnsResolver`/`DnsCacheOptions`。
2. `src/fetch/dns_resolver.cpp`：`SystemResolver`（含 H2 修复：stop_callback 持 resolver 并 cancel；字面 IP 短路）。
3. `connect_tcp` / socks5 / http_proxy 三处改走 `DnsResolver` + 循环尝试所有 endpoint（H1 修复）。
4. `CachingResolver`：LRU + TTL + 负缓存 + singleflight + last_good 排序；io 线程契约守卫。
5. `Options::dns` 配置面 + `BeastTransport` 接线。
6. 测试：
   - 字面 IP 短路（不触网）；
   - 缓存命中（同一进程内第二次 resolve 不触上游，用 fake resolver 计数）；
   - TTL 过期重新解析；负缓存 5s 内重放失败；
   - singleflight（并发同 key 只触一次上游）；
   - H2 回归：resolve 期间 abort 立即返回（fake resolver 挂起 + cancel）；
   - H1 回归：首个 endpoint 不可达时落到第二个（本地双端口 server 模拟）。
7. backlog：~~DoH（§4.2）~~（已实现）、JS 绑定细化。

## 7. 风险与权衡

- **缓存正确性风险低于收益**：60s 固定上限与浏览器/JVM 默认同量级；DNS 变更导致的短暂陈旧由连接层 H1 重试与池重试兜底。
- **不做 hosts 文件变更监听**：getaddrinfo 本身每次读 hosts，缓存 60s 内可能滞后 hosts 修改——可接受（与系统 dnscache 行为一致）。
- **io 线程契约沿用池的假设**（单 io 线程），多 io 线程场景下缓存需改 strand/锁——与池同进退，不单独解决。
