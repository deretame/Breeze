# 生命周期与结构

本章描述第三方插件运行规则与数据流。

## 1) Breeze 如何调用插件

1. Breeze 加载插件 bundle
2. Breeze 按 `fnPath` 找到同名函数
3. Breeze 把参数传给这个函数
4. Breeze 渲染函数返回的数据

核心规则：**`fnPath` 必须与 `export default` 的键名一致。**

## 2) 参数模型

Breeze 调用时，通用入参模型可以理解成：

```ts
type PluginPayload<T extends Record<string, unknown>> = T & {
  extern?: Record<string, unknown>;
};
```

推荐约定：

- 业务主参数（如 `comicId/page/keyword`）放顶层
- 会话/上下文透传信息放 `extern`

## 3) 返回模型

绝大多数接口可返回：

```ts
type PluginEnvelope = {
  source: string;
  scheme?: Record<string, unknown>;
  data?: Record<string, unknown>;
  extern?: Record<string, unknown>;
};
```

说明：

- `source`：插件 ID
- `scheme`：页面渲染协议（可选）
- `data`：业务数据
- `extern`：透传上下文。宿主会把返回的 `extern` 存下来，下次请求时原样传回

## 4) 运行时 API

Breeze 插件运行在 **QuickJS-NG** 引擎中，不是 Node.js 也不是浏览器环境。

可用的全局 API（`fetch`、`bridge`、`crypto`、`console` 等）详见 [运行时 API](/guide/runtime-api)。

## 5) 调试与状态

调试模式下，如果 bundle 文件发生变更，宿主会重建 QJS 实例。

这意味着：

- 插件内的内存状态不会保留
- 模块级变量会重新初始化

如果需要存储数据，建议按生命周期拆分：

- 短期数据放 `cache`（随进程存在）
- 长期数据放 `config`（跨重启保留）

## 6) 兼容性

- API 新增时优先保持向后兼容
- 对可选字段做默认值兜底

## 7) 常见陷阱

### QJS 实例重建

调试模式下每次 bundle 变更都重建 QJS 实例。这意味着：
- 顶层模块代码（除了 `export default`）每次都会重新执行
- `init` 也会重新调用
- 不要依赖模块级变量保存状态

### `getInfo` 变更需要重装

`getInfo()` 返回的 `function` 入口列表在插件加载时读取一次。修改后需要：
- 重启软件，或
- 卸载后重新安装插件

热更新不会触发 `getInfo` 重新读取。

### 单文件 bundle

构建产物是单文件 `.cjs`，所有依赖必须通过 Rspack 打包进去。**不能有运行时 npm 外部依赖。**

### `bridge.callSync` 限制

同步调用会阻塞宿主线程，仅适合极短操作。**不要在 `bridge.callSync` 中执行网络请求或文件读写。**

### `extern` 闭环

插件返回的 `extern` 会被宿主存储，下次请求同一上下文时会原样传回。利用这个机制可以在 `extern` 中携带分页 token、会话状态等上下文数据。

### `ImageItem.url` 规则

`ImageItem` 有 `url` 字段，且 `fetchImageBytes` 会收到这个 `url`，但**宿主本身不会用 `url` 来下载图片**——图片下载完全由插件在 `fetchImageBytes` 中自行处理。

不过这并不意味着 `url` 可以乱填。**不能为 404 地址，也不能是空字符串**，必须是一个有效格式的占位符字符串（如 `"https://example.com/placeholder.jpg"`），否则宿主会拒绝渲染。
