# 生命周期与结构

本章只讲第三方作者需要知道的运行规则。

## 1) Breeze 怎么调用你的插件

1. Breeze 加载你的 bundle
2. Breeze 按 `fnPath` 找到同名函数
3. Breeze 把参数传给这个函数
4. Breeze 渲染函数返回的数据

最关键的一句：**`fnPath` 必须和 `export default` 的键名一致。**

## 2) 参数模型

Breeze 调用时，通用入参模型可以理解成：

```ts
type PluginPayload<T extends Record<string, unknown>> = T & {
  extern?: Record<string, unknown>;
};
```

建议约定：

- 业务主参数（如 `comicId/page/keyword`）放顶层
- 会话/上下文透传信息放 `extern`

## 3) 返回模型

绝大多数接口建议返回：

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
- `extern`：透传上下文

## 4) Runtime 常用能力

插件环境通常提供宿主 API（名称可能因模板而异），常见有：

- `runtime.native.put(bytes)`：把图片二进制交给宿主
- `runtime.pluginConfig.*`：保存/读取插件配置
- `runtime.cache.*`：内存缓存
- `runtime.bridge.call(...)`：桥接能力（加解密等）

建议：为这些 API 做一层 `requireApi` 封装，缺失时抛出清晰错误。

## 5) 未登录错误（推荐）

当接口需要登录态时，建议抛出结构化 unauthorized 错误，让客户端可直接进入登录流程：

```json
{
  "type": "unauthorized",
  "source": "your-plugin-id",
  "message": "登录过期，请重新登录",
  "scheme": { "title": "登录", "fields": [] },
  "data": {}
}
```

## 6) 兼容性建议

- API 新增时优先保持向后兼容
- 对可选字段做默认值兜底
- 对旧命名保留别名函数（例如 `snake_case` + `camelCase` 同时导出）
