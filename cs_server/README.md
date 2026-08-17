# Breeze CS Server

这是 Breeze 根目录下独立的 Rust 服务端工程。它直接复用
`../rust/rquickjs_playground`，不依赖 Flutter Rust Bridge 的 `windcore` crate。
它与现有 Flutter 本地模式并存：只有客户端显式连接并启用 CS 模式时，相关请求才会走这里。

## 本地运行

先在仓库根目录构建独立前端：

```powershell
pnpm --dir cs_web install
pnpm --dir cs_web format
pnpm --dir cs_web lint
pnpm --dir cs_web build
```

然后启动服务端：

```powershell
cargo run --manifest-path cs_server/Cargo.toml
```

默认监听 `127.0.0.1:8787`，会直接提供 `cs_web/dist` 中的 HTML、JavaScript 和 CSS，
不需要 Nginx。没有前端构建产物时，API 仍然可以独立启动。

## 配置

服务端通过环境变量配置：

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `BREEZE_SERVER_HOST` | `127.0.0.1` | 监听地址 |
| `BREEZE_SERVER_PORT` | `8787` | 监听端口 |
| `BREEZE_DATA_DIR` | `cs_server/data` | SQLite 数据目录 |
| `BREEZE_WEB_ROOT` | `cs_web/dist` | 静态前端目录 |
| `BREEZE_PLUGIN_ROOT` | `cs_server/plugins` | 已安装插件 bundle 的受限根目录 |
| `BREEZE_ALLOW_PLUGIN_INSTALL` | 回环地址默认开启 | 是否允许已登录客户端从真实插件目录安装/更新插件；这是部署开关，不是插件权限系统 |
| `BREEZE_ADMIN_TOKEN` | 未设置 | 管理接口令牌；未设置时禁用 `/api/v1/admin/*` |
| `BREEZE_SERVER_DOWNLOAD` | `false` | 是否声明支持服务端下载 |
| `BREEZE_ALLOW_REGISTRATION` | 回环地址默认开启 | 是否允许注册新账号；非回环监听建议显式关闭 |
| `BREEZE_SESSION_TTL_DAYS` | `30` | Bearer 会话有效期 |
| `BREEZE_CORS_ORIGIN` | 未设置 | 开发时允许的前端来源 |
| `BREEZE_HTTP_PROXY` | 未设置 | 全局 HTTP 代理，与 SOCKS5 二选一 |
| `BREEZE_SOCKS5_PROXY` | 未设置 | 全局 SOCKS5 代理，与 HTTP 二选一 |
| `BREEZE_DISABLE_TLS_VERIFY` | `false` | 是否关闭 TLS 校验，默认开启 |
| `BREEZE_ALLOW_PRIVATE_NETWORK` | `false` | 是否允许插件请求内网地址 |

SQLite 使用 `rusqlite` 的 `bundled` feature，构建时嵌入官方 SQLite C 实现。
服务端所有主动 HTTP 请求的共享 `reqwest::Client` 与 QuickJS `fetch` 都从同一套
`rquickjs_playground::HttpClientConfig` 初始化。

## 当前接口

- `GET /api/v1/health`：检查服务端运行状态；
- `GET /api/v1/capabilities`：查看浏览器前端、服务端下载、QuickJS 和 HTTP 能力；
- `GET /api/v1/plugins`：读取当前用户已安装插件清单和服务端 `getInfo` 元数据；
- `GET /api/v1/plugins/catalog`：由服务端通过共享 reqwest 客户端读取本体真实插件目录，并带 CDN/直连回退；
- `POST /api/v1/plugins/catalog/install`：已登录用户请求服务端下载、校验并安装目录中的插件；
- `POST /api/v1/plugins/install-url`：让服务端下载并安装 HTTPS 插件地址；
- `POST /api/v1/plugins/install-bundle`：上传 bundle 到服务端，由服务端校验并安装；
- `GET /api/v1/plugins/{pluginId}`：读取当前用户插件详情和服务端 `getInfo` 元数据；
- `PATCH /api/v1/plugins/{pluginId}`：修改当前用户的启用、调试和调试 bundle 地址；
- `DELETE /api/v1/plugins/{pluginId}`：卸载当前用户插件关联，不删除其他用户仍在使用的全局 bundle；
- `POST /api/v1/auth/register`、`POST /api/v1/auth/login`：创建账号并获得 Bearer 会话；
- `POST /api/v1/auth/logout`、`GET /api/v1/auth/me`：注销并检查当前会话；
- `GET/PATCH /api/v1/settings/account`：按用户保存账号级设置，并用 revision 防止覆盖；
- `GET/POST/DELETE /api/v1/library/{favorites|history|follows}`：按用户读写业务记录；
- `GET/PATCH /api/v1/plugins/{pluginId}/config`：按用户保存插件配置，并用 revision 防止覆盖；
- `GET /api/v1/ws?access_token={token}`：认证后的插件宿主回调 WebSocket；
- `POST /api/v1/plugins/{pluginId}/invoke`：在用户隔离、无文件系统权限的 QuickJS runtime 中调用插件；
- `POST /api/v1/plugins/{pluginId}/invoke-bytes`：调用返回图片等二进制数据的插件函数；
- `POST /api/v1/plugins/{pluginId}/cancel`：取消当前用户指定任务组中的插件调用；调用请求可通过 `taskGroupKey` 绑定任务组；
- `POST /api/v1/plugins/{pluginId}/search`：调用插件搜索漫画；
- `POST /api/v1/plugins/{pluginId}/comic/{comicId}/detail`：读取漫画详情和章节；
- `POST /api/v1/plugins/{pluginId}/comic/{comicId}/chapter/{chapterId}`：读取章节内容；
- `POST /api/v1/plugins/{pluginId}/comic/{comicId}/read`：读取阅读器快照；
- `PUT /api/v1/admin/plugins/{pluginId}`：使用 `X-Breeze-Admin-Token` 原子安装或更新插件 bundle；
- `GET/POST /api/v1/downloads/tasks`、`GET /api/v1/downloads/tasks/{taskId}`、`POST /api/v1/downloads/tasks/{taskId}/cancel`：创建、查询和取消服务端下载任务；
- `GET /api/v1/downloads/comics/{pluginId}:{comicId}/manifest`：读取服务端下载清单；
- `GET /api/v1/downloads/assets/{assetId}`：读取当前用户有权访问的远程图片资源；
- `POST /api/v1/migrations/import`：登录后以 JSON 事务导入本地业务、插件配置和可选下载记录；
- `POST /api/v1/migrations/assets`：登录后逐文件上传迁移下载文件，并关联到用户下载清单；
- `GET /api/v1/migrations/export?include_downloads=true|false`：导出当前用户数据，用于关闭 CS 时按选择覆盖本地；插件 bundle 随 JSON 返回，下载文件通过资产接口读取；
- `/` 及其他非 API 路径：提供独立前端静态资源，并回退到 `index.html`。

服务端下载只有在 `BREEZE_SERVER_DOWNLOAD=true` 时才接受任务；任务会把图片保存到服务端私有资产目录，
并通过用户隔离的 manifest 和 asset API 提供给客户端。CS 模式获取插件设置时，服务端会过滤浏览器登录相关设置项；
下载任务的状态变化和插件自动更新结果会通过认证 WebSocket 推送，断线后客户端仍以 HTTP 返回的权威状态为准。
插件 runtime 按用户和插件隔离，空闲超过 30 分钟会由后台任务回收；服务端下载对可重试的网络错误最多尝试三次，
失败或取消会清理已写入的临时文件及 SQLite 资产记录，只有 manifest 成功保存的资产才会保留。缓存仍是进程内缓存，
不作为持久化下载或业务数据存储。
本阶段不改变 Flutter 原有纯本地模式。

### 插件登录态与请求头边界

CS 模式下，插件登录态和普通插件配置统一由服务端 SQLite 保存，按 `user_id + plugin_id` 隔离，
直接复用本体已有的 `load_plugin_config` / `save_plugin_config` QuickJS 宿主 bridge。插件把账号、
Cookie、token 等自己的数据按配置键保存即可，不新增专用登录态接口。

服务端不会替插件维护 Cookie jar，也不会自动读取、注入或改写 `Cookie`、`Authorization`、`Token`
等请求头。插件必须自己从 SQLite 宿主接口读取登录态，在自己的 HTTP 请求中显式设置请求头，并自行
解析登录响应中的 `Set-Cookie` 或 token 后再次保存。这样 Web、Flutter 和服务端执行插件时共享的是
插件自己的持久化登录态，而不是服务端偷偷代理认证。

### 插件产品边界

CS 服务端的账号认证只用于避免任何人仅凭 URL 匿名读取漫画数据，不以建设完善的公共漫画网站为目标。
本项目不实现插件级角色权限、作者审核、配额、运营后台或其他漫画站点管理能力；用户如何部署和使用插件由用户自行负责。

插件只保留当前正在使用的 bundle。插件版本字符串用于 `getInfo` 展示和自动更新比较，Brotli 与 hash 用于压缩、去重和完整性校验，
但服务端不提供版本选择、版本历史、版本锁定或回滚。自动更新不可关闭，服务端参考本体
`lib/plugin/plugin_cloud_update_service.dart` 的云端目录和自身更新通道自动更新；服务端启动后检查一次，之后每四小时检查一次。
更新成功后直接替换当前 bundle，用户手动安装低版本插件时不拦截，该版本会成为新的当前 bundle。

插件自动更新与服务端自身自动更新是两项独立任务。插件自动更新优先级较高，必须由服务端后台任务按四小时周期执行，不能依赖客户端在线。
服务端自身自动更新优先级暂时较低，未来再实现服务端发行包检查、替换和重启；它不能阻塞插件自动更新功能。

### 插件宿主回调与实时事件 WebSocket

HTTP 是漫画业务请求的主通道，WebSocket 只负责把服务端 QuickJS 插件运行时需要的
Flutter 宿主能力回传给当前用户的客户端，并接收下载、迁移和插件更新等实时通知。客户端可以通过 query 参数或 `Authorization: Bearer`
请求头携带会话 token：

```text
GET /api/v1/ws?access_token=<session-token>
```

当前协议是 JSON request/response：

```json
{
  "type": "bridge.request",
  "requestId": "...",
  "method": "dart.getLocaleInfo",
  "args": ["runtime-name"]
}
```

客户端使用相同的 `requestId` 返回 `bridge.response`，成功时填写 `ok: true` 和 `result`，
失败时填写 `ok: false` 和 `error`。目前转发的注册函数是：

- `dart.getAppVersion`
- `dart.getLocaleInfo`
- `flutter.showToast`

Flutter 客户端在 CS 模式启用且拥有有效会话 token 时会自动连接该通道；WebSocket 暂时不可用时，
HTTP 请求仍可使用，但调用上述宿主函数的插件操作会得到明确的 bridge 错误。未来独立 Web 前端
可以复用同一协议实现浏览器侧的本地化信息、通知展示和任务进度更新。

实时通知使用独立的 `event` 消息，不与宿主回调的 request/response 混用：

```json
{
  "type": "event",
  "eventId": "...",
  "topic": "downloads.progress",
  "occurredAt": "1786924800000",
  "payload": {}
}
```

`occurredAt` 是服务端生成的 Unix 毫秒时间戳字符串。第一批通知主题包括 `downloads.progress`、`downloads.status`、`plugins.updated`、
`migrations.progress`、`migrations.status` 和 `system.notice`。事件只负责通知，
写操作仍使用 HTTP；客户端断线重连后通过 HTTP 重新读取权威状态，不依赖本地事件缓存恢复状态。

### CS 模式插件设置中的浏览器登录过滤

CS 模式主要在获取插件 `getInfo` 和设置项时隐藏浏览器登录功能。服务端在返回 Flutter/Web 之前过滤包含
`openUrl`、`redirectWatchUrl`、`setCookieFnPath`、Cookie 轮询、WebView、系统浏览器、外部 Chromium
或客户端 Cookie 自动采集要求的设置字段和操作项，客户端不会显示浏览器登录入口。
普通插件业务响应中的 URL 不需要一概过滤；如果显式执行插件操作时仍返回浏览器登录描述，服务端返回
`plugin_browser_login_unsupported`，不能把登录 URL 或 Cookie 操作数据传给客户端，也不能回退到本地插件或本地 QuickJS。
普通设置字段和账号密码类插件登录仍然可以在服务端执行。

### 安装插件 bundle

插件目录、插件 bundle 下载、Brotli 解码、QuickJS `getInfo` 校验、文件落盘和 SQLite 登记全部在服务端完成，
客户端不会在 CS 模式下执行本地插件安装逻辑。回环地址默认允许已登录用户安装本体真实插件目录中的条目；部署到非回环地址时，
应显式关闭 `BREEZE_ALLOW_PLUGIN_INSTALL`，并使用管理令牌安装部署者允许的 bundle：

```powershell
$headers = @{ 'X-Breeze-Admin-Token' = $env:BREEZE_ADMIN_TOKEN }
$body = @{
  version = '1.0.0'
  bundle = (Get-Content .\plugin.cjs -Raw)
  enabled = $true
} | ConvertTo-Json -Depth 10
Invoke-RestMethod -Method Put `
  -Uri http://127.0.0.1:8787/api/v1/admin/plugins/demo `
  -Headers $headers -ContentType 'application/json' -Body $body
```

插件 bundle 应遵守 Breeze 插件契约，并通过服务端提供的 `fetch`/请求配置访问图源。
插件执行按“用户 + 插件”隔离 QuickJS runtime；服务端不会把客户端提交的任意文件路径传给插件。

## 验证

```powershell
cargo fmt --manifest-path cs_server/Cargo.toml -- --check
cargo check --manifest-path cs_server/Cargo.toml
cargo test --manifest-path cs_server/Cargo.toml
pnpm --dir cs_web format:check
pnpm --dir cs_web lint
pnpm --dir cs_web test
pnpm --dir cs_web build
```

### 端到端冒烟测试

服务端构建完成、独立前端构建完成，并且当前机器可以访问插件目录和 CDN 时，运行：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\script\test_cs_server.ps1
```

这份测试会使用和 Flutter 本体 `PluginInstallService` 相同的云端目录、CDN 顺序、
`.cjs.br` Brotli 解码和 `.cjs` 回退逻辑，实际下载一个云端插件并安装到临时服务端，
然后覆盖服务端连通性、HTML 直出、认证/注销、错误状态、SQLite 用户隔离、账号设置、
插件配置 revision、WebSocket 宿主回调、真实插件 `getInfo`/搜索、QuickJS 语义接口、二进制调用、服务端下载
任务、manifest、图片资源、ETag、取消边界和跨用户访问控制。测试数据只写入临时目录，
测试结束后会清理，不会改动 `cs_server/data` 或安装真实插件到开发环境。
