# 调试与发布

## 1) 调试

调试模式的具体操作步骤见 [快速开始](/guide/quick-start)。要点：

- 在插件设置页开启调试模式，填入 dev server 输出的 bundle 地址
- bundle 文件变更时宿主会重建 QuickJS 实例，内存状态不保留
- 部分功能（`init`、`getInfo` 的 `function` 入口）无法热更新，需重启或重装插件

### 远程日志

dev server 提供 `/log` 端点用于远程查看插件日志。在本体设置中填入 log 地址后，插件的 `console.log/warn/error` 输出会转发到终端。

## 2) 构建

**构建前请先更新 `src/get-info.ts` 中 `buildPluginInfo()` 的 `version` 字段**，构建脚本会据此自动同步 `package.json` 和 `manifest.json`。

```bash
pnpm run build
```

构建流程：typecheck → 同步版本号（`get-info.ts` → `package.json`）→ 生成 `manifest.json` → rspack 打包 → Brotli 压缩。

产物在 `dist/` 目录，包括 `<package-name>.bundle.cjs` 和 `<package-name>.bundle.cjs.br`。

## 3) 发布

### 3.1 命名规范

插件仓库名必须以 `Breeze-plugin-` 开头，例如 `Breeze-plugin-example`。

本体中的插件列表会搜索 GitHub 上所有以 `Breeze-plugin-` 开头的仓库。使用其他名称开头将不会被收集到插件列表中。

### 3.2 发布到 GitHub

1. 更新 `src/get-info.ts` 中 `buildPluginInfo()` 的 `version` 字段
2. 执行 `pnpm run build`
3. 推送代码和 `dist/` 产物到 GitHub 仓库
4. 创建 GitHub Release，**tag 必须与 `manifest.json` 中的 `version` 一致**（否则自动更新失效）

`updateUrl` 推荐填写：

```
https://api.github.com/repos/<owner>/Breeze-plugin-<name>/releases/latest
```

### 3.3 发布到 npm（可选）

不强制发布到 npm，但推荐。发布后可通过 jsDelivr CDN 加速下载。

发布前确保：
- `package.json` 的 `name` 与 `manifest.json` 的 `npmName` 一致
- `version` 格式为 `x.y.z`

### 3.4 常见问题

**插件一定要开源吗？**
不一定。插件列表的收录条件是 GitHub 上有以 `Breeze-plugin-` 开头的仓库且包含 `manifest.json`，与源码是否公开无关。如果连 `manifest.json` 都不放到 GitHub 上，插件不会出现在列表中，用户只能通过"网络安装"手动输入 bundle URL。

**为什么已经发布了，插件列表里还看不到？**
插件收集有延迟，通常在 2~4 小时内入库。如果超时仍未出现，检查：
- 仓库名是否以 `Breeze-plugin-` 开头
- `manifest.json` 格式是否正确
- 是否创建了 GitHub Release 且 tag 与版本号一致

**不想发布到 GitHub 可以吗？**
可以，但需要用户手动通过"网络安装"加载 bundle URL，不能通过插件列表发现和自动更新。

## 4) 自动更新

客户端通过 `manifest.json` 的 `version` 字段检测是否存在新版本。版本号按 `x.y.z` 语义比较。

`updateUrl` 目前只支持 GitHub Release API 格式：

```text
https://api.github.com/repos/<owner>/<repo>/releases/latest
```

非 GitHub 仓库暂不支持自动更新。

## 5) 故障定位

### `target is not function: xxx`

原因：`export default` 中缺少该函数。

处理：检查 `export default { ... }` 是否包含对应键名，键名大小写是否与 `fnPath` 一致。

### `插件返回格式错误`

原因：返回值结构不符合当前页面所需的类型。

处理：对照 [API 契约](/guide/plugin-api-contract) 中的 TypeScript 类型定义，逐项补齐字段。

### `plugin_not_found` / `bundle_js_missing_db`

原因：插件未正确注册，或 bundle 地址不可用。

处理：检查插件 UUID、配置元数据、`debugUrl` 与 bundle 文件是否可访问。

### 图片能显示但下载失败

原因：`fetchImageBytes` 没有返回有效的 `Uint8Array`。

处理：
1. 确认请求头加了 `x-rquickjs-host-offload-binary-v1: 1`
2. 确认返回 `new Uint8Array(await res.arrayBuffer())`
3. 检查图片 `url` 是否有效（不能为空或 404）

### 图片不显示

原因：`ImageItem.url` 为空字符串或 404 地址。

处理：`url` 必须是有效格式的占位符字符串，如 `"https://example.com/placeholder.jpg"`。宿主会校验格式但不会用这个 URL 下载图片。
