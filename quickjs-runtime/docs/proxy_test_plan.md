# 代理（SOCKS5 / HTTP / HTTPS）测试计划与 HTTP 代理编写计划

> 状态：**已完成** · 2026-08-09（执行记录见下）
> 范围：fetchcore（`include/fetch/` + `src/fetch/`）的代理能力。
> 方法：**3proxy 作为真实代理服务器，curl 作为基准对照**。

## 执行记录（2026-08-09）

- §1 环境：3proxy 0.9.8 已下载至 `third_party/3proxy/3proxy.exe`（`*.exe` 已被
  .gitignore 覆盖，不入库）；`tests/proxy/3proxy.cfg` 已建（**实测去掉 `-e`**：
  填 127.0.0.1 会强制从回环出网导致公网目标 502，见 §1.2 注释修正）。
- §2 curl 基线：C1–C12 全部实测通过（C3 exit=97、C10 407、C11 超时、C12 exit=7；
  3proxy 日志可见 ATYP 域名/IP 差异、absolute-form、CONNECT、认证记录）。
- §3 对打测试：`tests/proxy_3proxy_test.cpp` 已建，12 用例全绿（P1–P8 + C7–C10），
  P1/C7 含 curl 基准字节对照；`QJS_TEST_3PROXY` 未设置时整 suite SKIP。
  注意：3proxy 日志按 ~1s 周期 flush，测试 Teardown 需先等 flush 再杀进程，
  否则强杀丢最后一批日志（对打证据缺失）。
- **2026-08-12 机制调整**：3proxy 进程管理从 C++ fixture 移到测试驱动脚本
  （`scripts/test.py --with-3proxy` 负责拉起/回收，跨平台启停逻辑都在 Python 侧）；
  C++ 侧只认环境变量 `QJS_3PROXY_UP=1`（表示 3proxy 已在运行），未设置 → SKIP。
  日志 flush 等待也随之挪到脚本侧（杀进程前 sleep 2s）。
- §4 HTTP 代理：**已全部实现**（M-P1…M-P4）——`HttpProxy` 值类型 +
  `Transport::request_via_http_proxy`、`src/fetch/http_proxy.{hpp,cpp}`
  （CONNECT 握手 + TunnelStream 移交 over-read 字节）、`BeastTransport` 共享
  `exchange_over_tls` helper、统一选路的 `ProxyMiddleware`（初版为
  `HttpProxyMiddleware`，后合并入 ProxyMiddleware）；`tests/http_proxy_server.hpp`
  + `tests/http_proxy_test.cpp`（8 用例）+ fetchcore 纯 C++ 用例（2）。
  407（CONNECT 与 absolute-form 转发两条路径）→ 传输层抛可区分错误 → JS TypeError。
- 全量回归：既有测试全部通过（SOCKS5 重构为共享 helper 后无回归）。
- 2026-08-11：`Socks5ProxyMiddleware`/`HttpProxyMiddleware` 已删除，选路统一为
  `ProxyMiddleware`（三级优先级 + 实例级 URL 分流 `Options::proxy_routes`）。

## 0. 现状盘点

已实现（M4，见 `docs/fetch_milestone_progress.md`）：

- SOCKS5 客户端握手/隧道：`src/fetch/socks5.cpp`（`socks5_connect()`，
  支持无认证 / RFC 1929 user-pass、ATYP 域名/IPv4/IPv6、REP 错误码、取消）。
- 传输层入口：`BeastTransport::request_via_socks5()`（https 在隧道上照常 TLS handshake）。
- 策略层：`fetch::ProxyMiddleware`（统一选路：请求级 > 实例级 URL 分流
  `Options::proxy_routes`/默认 `Options::proxy` > 进程级 `process_proxy.hpp`，
  命中走代理隧道/转发、未命中直连；由 Client 自动装配，配置声明式提供）。
  **纯 C++ API，JS 侧不可见**。
- 单测：`tests/socks5_test.cpp` / `tests/fetchcore_test.cpp`，全部使用进程内
  mini SOCKS5 服务器（`tests/socks5_server.hpp`）对打。

未实现：

- HTTP 代理（absolute-form 转发）与 HTTPS 代理（CONNECT 隧道）。
  编写计划见本文档 §4。
- JS 侧代理配置入口（本计划不涉及，列为后续可选项，见 §5）。

现有测试的盲区：mini 服务器是自家人写的，无法证明与真实代理服务器的
协议互操作性。因此引入 3proxy + curl 做第三方对打与基准对照。

术语约定（本文档）：

- **HTTP 代理**：HTTP forward proxy。http 目标 → 向代理发送 absolute-form
  请求；https 目标 → 先 `CONNECT host:port` 建隧道，再在隧道上 TLS。
- **HTTPS 代理**（代理连接本身 TLS 加密，curl `-x https://…`）：列入
  低优先级可选项（§4.6），不作为本期目标。

## 1. 测试环境

### 1.1 3proxy 安装（Windows）

- 下载 GitHub release 压缩包（如 `3proxy-0.9.5-x64.zip`，
  <https://github.com/3proxy/3proxy/releases>），解压取 `bin64/3proxy.exe`；
  或 `choco install 3proxy`（若可用）。
- 建议放 `third_party/3proxy/3proxy.exe`（该目录已 gitignore 则不受版本管理；
  二进制不入库）。

### 1.2 3proxy 配置（`tests/proxy/3proxy.cfg`，需新建）

```
# 日志：代理侧证据（断言请求确实经过代理）
log tests/proxy/3proxy.log D
logformat "L%d-%m-%Y %H:%M:%S %N %p %E %U %C:%c %R:%r %O %I %h %T"

# ---- 实例 1：SOCKS5 无认证，端口 11080 ----
auth none
socks -p11080 -i127.0.0.1 -e127.0.0.1

# ---- 实例 2：SOCKS5 user/pass（RFC 1929），端口 11081 ----
flush
auth strong
users alice:CL:s3cret
allow alice
socks -p11081 -i127.0.0.1 -e127.0.0.1

# ---- 实例 3：HTTP 代理无认证（含 CONNECT），端口 13128 ----
flush
auth none
proxy -p13128 -i127.0.0.1 -e127.0.0.1

# ---- 实例 4：HTTP 代理 Basic 认证，端口 13129 ----
flush
auth strong
users bob:CL:passw0rd
allow bob
proxy -p13129 -i127.0.0.1 -e127.0.0.1
```

启动（前台控制台模式，方便看日志）：

```
third_party/3proxy/3proxy.exe tests/proxy/3proxy.cfg
```

注意：

- `auth` / `users` / `allow` 对**其后**定义的服务生效，所以每个实例前要
  `flush` 清 ACL 再重新声明。
- `-i` 只监听回环；`-e` 是出网接口（本机对打填 127.0.0.1 即可；若目标是
  公网，`-e` 填本机外网地址或去掉该参数）。
- CONNECT 目标端口由 `allow` 的 ACL 控制；上面配置里 `allow alice` /
  `allow bob` 不带端口列表即放行全部端口，`auth none` 无 ACL 时也不限。
  但**一旦给 ACL 加了端口列表，CONNECT 到未列端口会被拒**——本计划对打的
  本地 TLS 回声服务器是随机高端口，改配置时留意（Squid 等其他代理则默认
  只允许 CONNECT 到 443，换代理服务器对打时这是常见踩坑点）。

### 1.3 基准工具

- curl：环境已有 `curl 8.21.0`（Schannel 后端，支持 socks5/http(s) 代理）。
- 目标服务：
  - 自动化：测试进程内嵌 `WptTestServer`（http）与 `TlsEchoServer`（https，
    自签证书 + `extra_trust_pem` 信任注入，同 `tests/socks5_test.cpp`）。
  - 手动冒烟：`http://httpbin.org/ip`、`https://httpbin.org/ip`（需外网），
    或本地 `python -m http.server`。

## 2. curl 基线对照矩阵

每条用例先跑 curl 确认 3proxy 行为符合预期，作为项目实现的**行为基准**。
预期响应体记为基准输出，供 §3 自动化用例做字节级对照。

| # | 用例 | curl 命令（模板） | 预期 |
|---|------|-------------------|------|
| C1 | SOCKS5 无认证，http 目标 | `curl -v --socks5 127.0.0.1:11080 http://<host:port>/echo-content.py -d 'x'` | 200，回显 body |
| C2 | SOCKS5 user/pass | `curl -v --socks5 127.0.0.1:11081 --proxy-user alice:s3cret http://…` | 200 |
| C3 | SOCKS5 错误凭据 | 同 C2，密码改 `wrong` | curl 报错（exit≠0，代理拒绝） |
| C4 | SOCKS5 域名交代理解析 | `curl -v --socks5-hostname 127.0.0.1:11080 http://localhost:<port>/…` | 200；3proxy 日志可见域名目标（ATYP=0x03） |
| C5 | SOCKS5 本地解析走 IPv4 | `curl -v --socks5 127.0.0.1:11080 http://127.0.0.1:<port>/…` | 200；日志为 IPv4 目标（ATYP=0x01） |
| C6 | HTTPS over SOCKS5 隧道 | `curl -v --socks5 127.0.0.1:11080 https://<host:port>/echo --cacert tests/certs/server.crt -d 'x'` | 200；证书按目标 host 校验 |
| C7 | HTTP 代理，http 目标（absolute-form） | `curl -v -x http://127.0.0.1:13128 http://<host:port>/echo-content.py -d 'x'` | 200 |
| C8 | HTTP 代理，https 目标（CONNECT） | `curl -v -x http://127.0.0.1:13128 https://<host:port>/echo --cacert tests/certs/server.crt` | 200；verbose 可见 `CONNECT … 200` |
| C9 | HTTP 代理 Basic 认证 | `curl -v -x http://bob:passw0rd@127.0.0.1:13129 http://…` | 200 |
| C10 | HTTP 代理缺凭据 | `curl -v -x http://127.0.0.1:13129 http://…` | **407 Proxy Authentication Required** |
| C11 | SOCKS5 代理拒绝（REP≠0） | `curl -v --socks5 127.0.0.1:11080 http://10.255.255.1/…`（不可达目标） | curl 报错，SOCKS5 REP 非 0 |
| C12 | 代理未监听 | `curl -v --socks5 127.0.0.1:19999 http://…` | 连接拒绝，curl 报错 |

补充说明：

- C4/C5 的 ATYP 差异是 curl 侧 `--socks5-hostname`（域名交由代理解析）与
  `--socks5`（本地解析后发 IP）的区别；项目实现与之对应（`socks5.cpp`：
  IP 字面量 → ATYP=0x01/0x04，域名 → ATYP=0x03）。
- 每条命令保存 verbose 输出（`curl -v … 2> baseline/cN.log`）与响应体
  （`-o baseline/cN.body`），作为自动化对照素材。
- 3proxy 日志（`3proxy.log`）是「请求确实经过代理」的第三方证据：
  每个用例跑完后应能在日志里看到对应的目标地址与端口。

## 3. 项目侧自动化测试方案

### 3.1 新测试文件：`tests/proxy_3proxy_test.cpp`

与 `tests/socks5_test.cpp` 的用例一一对应，但代理换成真实 3proxy 进程：

- **3proxy 生命周期**：**（2026-08-12 起）由 `scripts/test.py --with-3proxy`
  统一拉起/回收**：脚本定位 `third_party/3proxy/3proxy.exe`，以
  `3proxy.exe tests/proxy/3proxy.cfg` 启动子进程，等 SOCKS5 11080 就绪后
  带 `QJS_3PROXY_UP=1` 跑测试，结束后先等 2s（日志 flush）再终止进程。
  C++ fixture（SetUpTestSuite）只检查 `QJS_3PROXY_UP=1` 与端口可达，
  **未设置 → `GTEST_SKIP()`**，不做任何进程管理（便于跨平台扩展）。
- **客户端构造**：同 `socks5_test.cpp` 的 `init()`——`BeastTransport` +
  `Socks5ProxyMiddleware`，`Socks5Proxy{127.0.0.1, 11080/11081, auth?}`。
- **目标**：进程内 `WptTestServer`（http）/ `TlsEchoServer`（https），
  与现有用例完全一致。

用例矩阵（与 §2 对照）：

| # | 对应 curl | 断言 |
|---|-----------|------|
| P1 | C1 | fetch 经 11080 取回 body == 直连取回的 body（== curl 基准体） |
| P2 | C2 | 正确凭据经 11081 成功 |
| P3 | C3 | 错误凭据 → fetch reject `TypeError` |
| P4 | C4 | URL host=localhost：成功（ATYP=0x03，由 3proxy 解析） |
| P5 | C5 | URL host=127.0.0.1：成功（ATYP=0x01） |
| P6 | C6 | https over 隧道成功（`extra_trust_pem` 注入自签证书） |
| P7 | C11 | 不可达目标 → fetch reject `TypeError`（3proxy 回 REP≠0） |
| P8 | C12 | 代理端口未监听 → fetch reject `TypeError`（连接拒绝） |
| P9 | —   | 握手中止：3proxy 无 greet_delay 配置，用「慢目标 + 短 abort」
      间接覆盖；中止语义已由 mini 服务器用例覆盖，本项可降级为手动 |

基准对照（P1 的「== curl 基准体」）：测试内用 `_popen("curl … -s")` 同步
抓取同一 URL 的 curl 输出做字符串相等断言；curl 不可用时退化为与直连
fetch 结果对照（并注释说明）。

### 3.2 手动冒烟（可选）

JS 侧尚无代理配置入口（中间件是 C++ API），手动验证以 gtest 二进制
单跑为主：

```
./build/quickjs_runtime_tests.exe --gtest_filter='Proxy3proxy.*'
```

### 3.3 通过标准

1. `--with-3proxy` 跑 proxy 分组时：`Proxy3proxyTest.*` 全部通过；
   不加该开关时全部 SKIP，其余既有测试不受影响。
2. P1 响应体与 curl 基准**字节一致**。
3. 每个用例执行期间 3proxy 日志出现对应目标记录（人工抽查即可，
   不做自动化日志解析）。
4. 负向用例（P3/P7/P8）的 JS 侧表现与 curl 的失败语义一致
   （都是传输层失败 → fetch reject TypeError）。

## 4. HTTP/HTTPS 代理编写计划

目标：在 fetchcore 增加 HTTP forward proxy 支持——http 目标走
absolute-form 转发、https 目标走 CONNECT 隧道，含 Basic 代理认证与
407 处理。风格全面对齐现有 SOCKS5 实现（机制在传输层，策略在中间件）。

### 4.1 协议要点（实现前确认）

- **http 目标**：TCP 连到代理，请求行用 absolute-form
  `GET http://host:port/path HTTP/1.1`；`Host` 头仍写目标 host；
  需要认证时加 `Proxy-Authorization: Basic base64(user:pass)`。
  其余与直连完全一致（beast 可直接复用，只需改 request target）。
- **https 目标**：先向代理发 `CONNECT host:port HTTP/1.1`（+ `Host`、
  可选 `Proxy-Authorization`），读到 **200** 后隧道建立；随后在同一
  socket 上照常 TLS handshake（SNI/证书校验按目标 host，与
  `request_via_socks5` 的 https 路径完全同构）。
  - CONNECT 响应读取用 `http::response_parser<http::empty_body>`；
    **解析器剩余 buffer 里的字节属于隧道流**，必须移交后续 TLS 层
    （beast 经典坑；客户端 CONNECT 场景代理一般不会抢先发字节，
    但代码上仍要正确移交）。
  - 非 200（407/403/502…）→ 失败，映射为 `fetch::Error`
    （JS 侧 TypeError），与 SOCKS5 REP 错误的对外语义一致。
- **407**：语义 = 缺/错代理凭据。本期只做到「抛出可区分错误」，
  不做自动凭据重试握手。
- hop-by-hop 头：`Proxy-Authorization` 只发给代理，绝不进入隧道内
  发给目标的请求；`Proxy-Connection` 不主动发。

### 4.2 代码改动点（镜像 SOCKS5 结构）

1. `include/fetch/transport.hpp`
   - 新增值类型 `struct HttpProxy { std::string host; uint16_t port = 8080;
     std::optional<std::pair<std::string,std::string>> auth; /* Basic */ };`
   - `Transport` 增加虚函数 `request_via_http_proxy(req, proxy, st)`，
     默认抛「不支持」（与 `request_via_socks5` 同款）。
2. `src/fetch/http_proxy.{hpp,cpp}`（新文件）
   - `http_proxy_connect(io, proxy, target_host, target_port, st)`
     → `std_exec::task<std::shared_ptr<tcp::socket>>`：CONNECT 握手 +
     200 校验 + 取消（stop_token → socket cancel()，同 socks5）。
   - 错误码：新增 `http_proxy` error category（407/非 200/连接失败），
     对齐 `socks5` category 的做法（`include/fetch/error.hpp`）。
3. `include/fetch/beast_transport.hpp` + `src/fetch/beast_transport.cpp`
   - 实现 `request_via_http_proxy()`：
     - https：调 `http_proxy_connect` 拿隧道 socket，然后**复用现有
       「socket → ssl::stream → handshake → do_exchange_head」段**
       （`beast_transport.cpp:363-380` 与 `:411-441` 已经是这个形状，
       把这段抽成共享 helper，socks5/http_proxy 两条路径共用）。
     - http：TCP 连代理，请求 target 改写为 absolute-form 后直接复用
       `do_exchange_head(*sock, …)`。
4. `include/fetch/middleware.hpp`
   - 新增 `HttpProxyMiddleware`（与 `Socks5ProxyMiddleware` 同构：
     Route 回调 `url → optional<HttpProxy>`）。
   - 后续可选：统一 `Proxy = std::variant<Socks5Proxy, HttpProxy>` +
     单一 `ProxyMiddleware`；**本期不做**，保持最小改动。
5. `CMakeLists.txt`：`fetchcore` 源文件加 `src/fetch/http_proxy.cpp`；
   tests 加新测试文件。

### 4.3 测试计划（HTTP 代理自身）

1. 进程内 mini HTTP 代理 `tests/http_proxy_server.hpp`（新，镜像
   `socks5_server.hpp`）：支持 absolute-form 转发、CONNECT 中继、
   Basic 认证校验 / 强制回 407、记录目标（选路断言）、CONNECT 响应
   延迟（中止测试）。
2. `tests/http_proxy_test.cpp`（新，镜像 `socks5_test.cpp`）：
   http 经代理 / https 经 CONNECT / Basic 认证对错 / 407 → TypeError /
   选路命中与直连 / 握手中止 AbortError。
3. `tests/fetchcore_test.cpp`：补纯 C++ 用例（不建 JSRuntime）。
4. 3proxy 对打：`tests/proxy_3proxy_test.cpp` 增加 HTTP 代理用例
   （对应 §2 的 C7–C10），与 curl 基准体字节对照。

### 4.4 里程碑拆分

| 里程碑 | 内容 | 验收 |
|--------|------|------|
| M-P1 | `http_proxy_connect`（CONNECT 隧道）+ 共享 TLS-over-socket helper 重构 | mini 代理 + https over CONNECT 单测绿；既有 socks5 测试不回归 |
| M-P2 | absolute-form http 转发 + Basic 认证 + 407 错误映射 | `http_proxy_test.cpp` 全绿 |
| M-P3 | `HttpProxyMiddleware` + fetchcore 纯 C++ 用例 | fetchcore 用例绿，ctest 全绿 |
| M-P4 | 3proxy 对打 + curl 基线对照（§3 矩阵扩展 C7–C10） | `Proxy3proxy.*` 全绿，基准体一致 |

### 4.5 风险与注意点

- **absolute-form vs origin-form**：转发给代理的请求行必须带完整 URI；
  经隧道（https）发给目标的请求行仍是 origin-form。两条路径别混。
- **凭据泄漏**：`Proxy-Authorization` 只在「发往代理的连接」上出现；
  https 场景只出现在 CONNECT 报文里，隧道内请求不得携带。
- **CONNECT 响应 over-read**：见 §4.1，剩余 buffer 移交 TLS 层。
- **keep-alive**：http 代理连接可复用，但本期沿用现有「一请求一连接」
  模型（直连也是这个模型），不引入代理连接池。
- **CONNECT 端口 ACL**：给 3proxy 的 `allow` 加端口列表时，CONNECT 到未列
  端口会被拒；本地 TLS 服务器是随机高端口，配置 ACL 时留意（见 §1.2）。

### 4.6 本期不做（后续可选）

- HTTPS 代理（代理连接本身 TLS，curl `-x https://…`）：3proxy 需额外
  TLS 插件配置，需求低；架构上只是「到代理的 TCP 换 TLS」，后续可加。
- JS 侧代理配置入口（如 `fetch(url, {proxy: …})` 或全局 `setProxy`）：
  涉及 Web API 设计，单独立项。
- PAC / 环境变量（`http_proxy`/`https_proxy`/`no_proxy`）选路：
  Route 回调已经留好了位置，届时只是再写一个路由函数。
- HTTP/2 代理（CONNECT over h2）。

## 5. 附：快速上手清单

```bash
# 1. 装 3proxy（一次性）
#    下载 release zip 解压到 third_party/3proxy/3proxy.exe

# 2. 写配置 tests/proxy/3proxy.cfg（见 §1.2）并启动
third_party/3proxy/3proxy.exe tests/proxy/3proxy.cfg

# 3. curl 基线（§2 矩阵逐条过一遍，确认 3proxy 行为）
curl -v --socks5 127.0.0.1:11080 http://httpbin.org/ip
curl -v -x http://127.0.0.1:13128 https://httpbin.org/ip

# 4. 跑项目对打测试（脚本自动拉起/回收 3proxy）
pixi run build
pixi run python scripts/test.py --group proxy --with-3proxy
```
