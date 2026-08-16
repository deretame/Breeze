# Breeze CS Web

独立的浏览器前端工程，不参与当前 Flutter Web 构建。技术栈为 React、TypeScript、
Vite 和 React Router，包管理器固定使用 pnpm。

## 命令

```powershell
pnpm install
pnpm format
pnpm lint
pnpm format:check
pnpm build
```

每次修改前端文件后，至少依次执行 `pnpm format` 和 `pnpm lint`。生产构建输出到
`dist/`，可由 `cs_server` 直接提供。

开发时 `pnpm dev` 会把 `/api` 和 `/media` 请求代理到
`http://127.0.0.1:8787`。
