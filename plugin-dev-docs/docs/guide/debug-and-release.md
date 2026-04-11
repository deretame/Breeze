# 调试与发布

## 1) 调试模式（强烈推荐）

Breeze 插件管理页支持：

- 开启 `debug`
- 配置 `debugUrl`

当 `debug=true` 且 `debugUrl` 可访问时，客户端会优先加载远端 bundle。

这让你可以：

- 本地起一个静态服务
- 每次构建后直接刷新 App 验证最新代码

推荐联调流程：

1. `pnpm build`
2. 把 bundle 放到本地静态服务目录
3. 在 Breeze 设置 `debugUrl`
4. 进入搜索/详情/阅读链路做回归

## 2) 构建建议

常见脚本：

- `pnpm typecheck`
- `rspack build`
- 产物输出为单文件 bundle（如 `xxx.bundle.cjs`）

发布前至少做：

- 所有已导出 `fnPath` 冒烟
- 登录过期流程校验
- 图片下载与阅读翻页校验

## 3) 插件注册信息

你的插件元数据至少应包含：

- `name`
- `version`
- `id`
- `url`
- `main`

其中 `id` 需要与你插件内部声明的 UUID 保持一致。

## 4) 常见故障定位

### `target is not function: xxx`

原因：导出对象缺少该函数。

处理：检查 `export default { ... }` 是否包含对应键名。

### `插件返回格式错误`

原因：返回值结构不符合当前页面所需格式。

处理：先对照本手册的 API 契约和示例 JSON，逐项补齐字段。

### `plugin_not_found` / `bundle_js_missing_db`

原因：插件未正确注册，或 bundle 地址不可用。

处理：检查插件 UUID、配置元数据、`debugUrl` 与 bundle 文件是否可访问。

### 图片能显示但下载失败

原因：`fetchImageBytes` 没有返回 `nativeBufferId`，或返回的不是图片二进制。

处理：检查下载请求是否 `arraybuffer`，并确认执行了 `runtime.native.put(...)`。
