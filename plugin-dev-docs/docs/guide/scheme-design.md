# Scheme 设计

`scheme + data` 是插件驱动 UI 的核心协议。

定义：

- `scheme` 定义页面长什么样、有哪些字段和动作
- `data` 提供当前页面值

## 1) 设置页 `getSettingsBundle`

Breeze 读取：

- `scheme.sections[].fields[]`
- `data.values`
- `data.canShowUserInfo`

字段常用 `kind`：

- `text`
- `password`
- `switch`
- `choice` / `select`
- `multiChoice`

字段可携带：

- `key`: 配置键
- `label`: 展示文案
- `persist`: 是否由客户端持久化（默认 `true`）
- `fnPath`: 变更时回调插件

示例：

```json
{
  "source": "plugin-id",
  "scheme": {
    "sections": [
      {
        "title": "网络",
        "fields": [
          { "key": "network.proxy", "label": "代理", "kind": "choice", "options": [
            { "label": "关闭", "value": "0" },
            { "label": "系统", "value": "1" }
          ] }
        ]
      }
    ]
  },
  "data": {
    "values": { "network.proxy": "0" },
    "canShowUserInfo": true
  }
}
```

## 2) 能力区 `getCapabilitiesBundle`

Breeze 读取 `scheme.actions[]`，每项至少包含：

- `title`
- `fnPath`

点击后会调用对应 `fnPath`。

示例：

```json
{
  "source": "plugin-id",
  "scheme": {
    "actions": [
      { "title": "清理会话", "fnPath": "clearPluginSession" },
      { "title": "同步收藏", "fnPath": "syncFavorite" }
    ]
  },
  "data": {}
}
```

## 3) 登录页 `getLoginBundle`

Breeze 要求 `scheme.fields` 至少两个字段（账号、密码）。

约定：

- `scheme.title` 指定页面标题
- `data.account` / `data.password` 可做默认填充

示例：

```json
{
  "source": "plugin-id",
  "scheme": {
    "title": "账号登录",
    "fields": [
      { "key": "account", "label": "账号", "kind": "text" },
      { "key": "password", "label": "密码", "kind": "password" }
    ]
  },
  "data": { "account": "", "password": "" }
}
```

## 4) 功能页 `getFunctionPage`

`getInfo().function[].action` 常见类型：

- `openPluginFunction`
- `openCloudFavorite`
- `openSearch`
- `openComicList`
- `openWeb`

`openPluginFunction` 会继续调用 `getFunctionPage({ id })`，由插件返回页面方案。

函数页返回示例：

```json
{
  "source": "plugin-id",
  "scheme": {
    "version": "1.0.0",
    "type": "page",
    "title": "导航",
    "body": {
      "type": "list",
      "direction": "vertical",
      "children": [{ "type": "action-grid", "key": "items" }]
    }
  },
  "data": {
    "items": [
      {
        "title": "排行榜",
        "action": {
          "type": "openComicList",
          "payload": { "scene": { "title": "排行榜", "source": "plugin-id" } }
        }
      }
    ]
  }
}
```

## 5) 列表场景 `getComicListSceneBundle`

Breeze 会解析 `data.scene`（或直接 `data`）作为列表页配置。

关键结构：

```json
{
  "source": "plugin-id",
  "data": {
    "scene": {
      "title": "排行榜",
      "source": "plugin-id",
      "body": {
        "type": "pluginPagedComicList",
        "request": {
          "fnPath": "getRankingData",
          "core": {},
          "extern": {}
        }
      },
      "filter": {
        "fnPath": "getRankingFilterBundle",
        "core": {},
        "extern": {}
      }
    }
  }
}
```

## 6) 过滤器 Bundle

过滤器由单独的 `fnPath` 返回，客户端读取：

- `scheme.fields[].options[].result`
- `data.values`

`result` 可拆分为：

- `core`
- `extern`
- 其他平铺参数（给 UI 用）

实践建议：

- 所有 `options.value` 保持稳定，不要随版本改变语义
- `data.values` 一定给默认值，避免空选项导致请求参数缺失
- 过滤器里能放进 `core` 的参数，不要混进 `extern`
