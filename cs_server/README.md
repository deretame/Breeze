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
| `BREEZE_ADMIN_TOKEN` | 未设置 | 插件安装管理令牌；未设置时禁用管理接口 |
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

- `GET /api/v1/health`：检查服务端和 SQLite schema 版本；
- `GET /api/v1/capabilities`：查看浏览器前端、服务端下载、QuickJS 和 HTTP 能力；
- `GET /api/v1/plugins`：读取服务端已安装插件清单；
- `GET /api/v1/plugins/{pluginId}`：读取插件元信息；
- `POST /api/v1/auth/register`、`POST /api/v1/auth/login`：创建账号并获得 Bearer 会话；
- `POST /api/v1/auth/logout`、`GET /api/v1/auth/me`：注销并检查当前会话；
- `GET/PATCH /api/v1/settings/account`：按用户保存账号级设置，并用 revision 防止覆盖；
- `GET/POST/DELETE /api/v1/library/{favorites|history|follows}`：按用户读写业务记录；
- `GET/PATCH /api/v1/plugins/{pluginId}/config`：按用户保存插件配置，并用 revision 防止覆盖；
- `GET /api/v1/ws?access_token={token}`：认证后的插件宿主回调 WebSocket；
- `POST /api/v1/plugins/{pluginId}/invoke`：在用户隔离、无文件系统权限的 QuickJS runtime 中调用插件；
- `POST /api/v1/plugins/{pluginId}/invoke-bytes`：调用返回图片等二进制数据的插件函数；
- `POST /api/v1/plugins/{pluginId}/search`：调用插件搜索漫画；
- `POST /api/v1/plugins/{pluginId}/comic/{comicId}/detail`：读取漫画详情和章节；
- `POST /api/v1/plugins/{pluginId}/comic/{comicId}/chapter/{chapterId}`：读取章节内容；
- `POST /api/v1/plugins/{pluginId}/comic/{comicId}/read`：读取阅读器快照；
- `PUT /api/v1/admin/plugins/{pluginId}`：使用 `X-Breeze-Admin-Token` 原子安装或更新插件 bundle；
- `GET/POST /api/v1/downloads/tasks`、`GET /api/v1/downloads/tasks/{taskId}`、`POST /api/v1/downloads/tasks/{taskId}/cancel`：创建、查询和取消服务端下载任务；
- `GET /api/v1/downloads/comics/{pluginId}:{comicId}/manifest`：读取服务端下载清单；
- `GET /api/v1/downloads/assets/{assetId}`：读取当前用户有权访问的远程图片资源；
- `/` 及其他非 API 路径：提供独立前端静态资源，并回退到 `index.html`。

服务端下载只有在 `BREEZE_SERVER_DOWNLOAD=true` 时才接受任务；任务会把图片保存到服务端私有资产目录，
并通过用户隔离的 manifest 和 asset API 提供给客户端。插件登录挑战、数据导入导出和更细的权限管理仍属于后续增强项。
本阶段不改变 Flutter 原有纯本地模式。

### 插件宿主回调 WebSocket

HTTP 是漫画业务请求的主通道，WebSocket 只负责把服务端 QuickJS 插件运行时需要的
Flutter 宿主能力回传给当前用户的客户端。客户端可以通过 query 参数或 `Authorization: Bearer`
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
可以复用同一协议实现浏览器侧的本地化信息和通知展示。

### 安装插件 bundle

服务端不自动从不受信任的网络地址执行插件。部署者需要通过管理令牌安装已经审核过的 bundle：

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
