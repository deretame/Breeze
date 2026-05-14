# 调试与发布

## 1) 调试模式

Breeze 插件管理页支持：

- 开启 `debug`
- 配置 `debugUrl`

当 `debug=true` 且 `debugUrl` 可访问时，客户端会优先加载远端 bundle。

注意：

- 调试模式下，如果 `cjs` 文件发生变更，宿主会重建 QJS 实例
- 插件内的内存状态不会保留
- 如果需要保留短期数据，放入 `cache`
- 如果需要保留长期数据，放入 `config`

## 2) 发布流程

推荐发布流程：

1. 先执行 `pnpm run build`
2. 确认本地构建成功，`manifest.json` 已更新
3. 把代码和发布产物更新到 GitHub 仓库
4. 基于 GitHub Release 发布新版本

发布前至少做：

- 所有已导出 `fnPath` 冒烟
- 登录过期流程校验
- 图片下载与阅读翻页校验

## 3) 自动更新

后续客户端会通过 `manifest.json` 里的 `version` 自动检测是否存在更新版本，并执行自动更新。

`updateUrl` 推荐使用 GitHub 最新 Release API：

```text
https://api.github.com/repos/<owner>/Breeze-plugin-<name>/releases/latest
```

例如：

```text
https://api.github.com/repos/deretame/Breeze-plugin-example/releases/latest
```

如果不使用 GitHub，目前将无法自动更新。

后续会尝试补充非 GitHub 仓库的自动更新能力。

## 4) 插件注册信息

插件元数据至少应包含：

- `name`
- `uuid`
- `describe`
- `version`
- `home`
- `updateUrl`

其中 `uuid` 需要与插件内部声明的 UUID 保持一致。

其中：

- `version` 用于后续自动更新检测
- `updateUrl` 用于获取最新版本发布信息

## 5) 常见故障定位

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
