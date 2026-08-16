# Breeze CS Server

这是 Breeze 根目录下独立的 Rust 服务端工程。它直接复用
`../rust/rquickjs_playground`，不依赖 Flutter Rust Bridge 的 `windcore` crate。

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
| `BREEZE_SERVER_DOWNLOAD` | `false` | 是否声明支持服务端下载 |
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
- `/` 及其他非 API 路径：提供独立前端静态资源，并回退到 `index.html`。

业务数据仓储、插件调用、认证和下载 Worker 会在后续阶段接入；本阶段不改变 Flutter
原有纯本地模式。

## 验证

```powershell
cargo fmt --manifest-path cs_server/Cargo.toml -- --check
cargo check --manifest-path cs_server/Cargo.toml
cargo test --manifest-path cs_server/Cargo.toml
pnpm --dir cs_web format:check
pnpm --dir cs_web lint
pnpm --dir cs_web build
```
