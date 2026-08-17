# Breeze CS Web

独立的浏览器前端工程，不参与当前 Flutter Web 构建。技术栈为 React、TypeScript、
Vite 和 React Router，包管理器固定使用 pnpm。

## 命令

```powershell
pnpm install
pnpm format
pnpm lint
pnpm format:check
pnpm test
pnpm build
```

每次修改前端文件后，至少依次执行 `pnpm format`、`pnpm lint` 和 `pnpm test`。
生产构建输出到 `dist/`，可由 `cs_server` 直接提供。

`pnpm test:watch` 可启动 Vitest 监听模式。目前共有 15 个测试文件、35 个测试，使用
jsdom 和 Testing Library，覆盖：

- 应用路由兜底、登录/注册/退出登录、会话持久化和 401 自动清理会话；
- 首页服务状态、能力声明、插件列表和搜索入口；
- 搜索成功、分页、匿名限制、失败态和空结果；
- 漫画详情、收藏、下载、未登录提示和错误态；
- 收藏/历史书架的加载、刷新、空态和服务端错误边界；
- 下载任务的状态展示、取消操作和空态；
- 阅读器章节图片、沉浸式阅读、阅读历史、空章节和错误态；
- 设置页能力信息、远程图片鉴权/失败回退；
- 所有 RTK Query endpoint 的 HTTP 方法、路径、参数编码、请求体和会话行为。

当前页面包括登录/注册、服务状态、真实插件目录、插件搜索、漫画详情、阅读器、收藏与历史书架、
服务端下载任务和连接设置。跨页面客户端状态使用 Redux Toolkit，服务端数据请求和
缓存使用 RTK Query；基础按钮、卡片和交互控件按 shadcn/ui + Radix UI 的方式放在
`src/components/ui/`，页面样式同时覆盖桌面侧边栏和手机底部导航。

开发时 `pnpm dev` 会把 `/api` 和 `/media` 请求代理到
`http://127.0.0.1:8787`。
