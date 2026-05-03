# 插件 API 契约（按 fnPath）

本文档给出 Breeze 插件 `fnPath` 的调用语义、请求结构与返回结构。

## 0. 通用调用规则

### 0.1 调用入参

客户端调用时会把参数组装成：

```ts
const payload = {
  ...core,
  extern: extern ?? {}
};
```

函数签名通常可写为：

```ts
async function someFn(payload: {
  // core 字段
  comicId?: string;
  page?: number;
  // 透传字段
  extern?: Record<string, unknown>;
} = {}) {}
```

### 0.2 通用返回 envelope

大部分接口返回结构可统一为：

```ts
type PluginEnvelope = {
  source?: string;
  scheme?: Record<string, unknown>;
  data?: Record<string, unknown>;
  extern?: Record<string, unknown>;
  [key: string]: unknown;
};
```

### 0.3 错误与格式

- 插件返回值必须是可 JSON 解析的对象（非对象会触发“返回格式错误”）
- 建议始终返回 `source` 字段，便于排障
- 抛出的错误字符串会直接显示在客户端

### 0.4 `init` 是可选但推荐实现

- 客户端可能在 runtime 启动后调用 `init`
- 如果没实现，客户端会跳过
- 若实现 `init`，建议返回 `{ source, data: { ok: true } }`

## 0.5 fnPath 职责总览

下表用于快速定位每个函数的职责与触发时机。

| fnPath | 做什么 | 典型触发位置 |
| --- | --- | --- |
| `getInfo` | 返回插件基本信息和首页功能入口 | 主页加载插件卡片时 |
| `searchComic` | 按关键词/筛选返回漫画列表 | 用户在搜索页点击搜索 |
| `getComicDetail` | 返回漫画详情与章节目录 | 用户打开漫画详情页 |
| `getChapter` | 返回某一章节的图片列表 | 用户进入阅读页后 |
| `fetchImageBytes` | 把图片 URL 转成可下载二进制缓冲 | 阅读/下载图片时 |
| `getLoginBundle` | 返回登录表单结构 | 进入插件登录页或登录过期 |
| `loginWithPassword` | 执行账号密码登录并保存会话 | 用户点登录按钮 |
| `clearPluginSession` | 清理插件登录态/会话数据 | 设置页点击“清理会话” |
| `getSettingsBundle` | 返回插件设置项结构和值 | 打开插件设置页 |
| `getCapabilitiesBundle` | 返回设置页“操作按钮”列表 | 打开插件设置页 |
| `getUserInfoBundle` | 返回用户头像与信息摘要 | 设置页显示用户卡片 |
| `getFunctionPage` / `get_function_page` | 返回某个“插件功能页”的页面方案 | 主页功能入口 `openPluginFunction` |
| `getComicListSceneBundle` | 返回默认漫画列表场景定义 | 列表页按 source 自动加载时 |
| `getCloudFavoriteSceneBundle` / `get_cloud_favorite_scene_bundle` | 返回“云端收藏”列表场景 | 点击云端收藏入口 |
| `getRankingFilterBundle` 等 filter bundle | 返回列表筛选项与默认值 | 列表页点筛选按钮 |
| `getAdvancedSearchScheme` / `get_advanced_search_scheme` | 返回高级搜索选项结构 | 搜索页点高级筛选 |
| `toggleLike` | 切换点赞状态 | 详情页点点赞 |
| `toggleFavorite` | 切换收藏状态 | 详情页点收藏 |
| `listFavoriteFolders` | 返回收藏夹列表 | 收藏后需选择收藏夹时 |
| `moveFavoriteToFolder` | 把漫画移动到指定收藏夹 | 用户确认收藏夹后 |
| `getCommentFeed` | 返回评论主列表 | 评论面板首次加载 |
| `loadCommentReplies` | 分页加载某条评论的回复 | 评论展开回复时 |
| `postComment` | 发布主评论 | 用户发主评论 |
| `postCommentReply` | 发布回复评论 | 用户回复某条评论 |
| `getReadSnapshot` | 返回“漫画+当前章节+页面+章节列表”快照 | 阅读页初始化或切章 |

## 1. 必需 API（推荐实现）

## `getInfo()`

用途：插件卡片、功能入口。

最小返回：

```json
{
  "name": "插件名",
  "uuid": "插件ID",
  "describe": "描述",
  "version": "1.0.0",
  "function": []
}
```

`function[]` 项结构：

```ts
type PluginFunctionItem = {
  id: string;
  title: string;
  action: PluginAction;
};

type PluginAction =
  | {
      type: "openSearch";
      payload: {
        source: string;
        keyword?: string;
        url?: string;
        categories?: string[];
      };
    }
  | {
      type: "openWeb";
      payload: { title?: string; url: string };
    }
  | {
      type: "openPluginFunction";
      payload: {
        source?: string;
        id: string;
        title?: string;
        presentation?: "page" | "dialog";
      };
    }
  | {
      type: "openCloudFavorite";
      payload: { source?: string; title?: string };
    }
  | {
      type: "openComicList";
      payload: { scene: ComicListScene };
    };
```

## `searchComic(payload)`

请求：

```ts
type SearchComicPayload = {
  keyword?: string;
  page?: number;
  extern?: Record<string, unknown>;
};
```

返回最小结构（推荐放在 `data` 下，同时可双写顶层兼容）：

```json
{
  "source": "plugin-id",
  "extern": {},
  "data": {
    "paging": {
      "page": 1,
      "pages": 1,
      "total": 0,
      "hasReachedMax": true
    },
    "items": []
  }
}
```

`items[]` 单项应可映射为统一漫画卡：

```ts
type SearchComicItem = {
  source: string;
  id: string;
  title: string;
  subtitle: string;
  finished: boolean;
  likesCount: number;
  viewsCount: number;
  updatedAt: string;
  cover: {
    id: string;
    url: string;
    path: string;
    extern: Record<string, unknown>;
  };
  metadata: Array<{
    type: string;
    name: string;
    value: string[];
  }>;
  raw: Record<string, unknown>;
  extern: Record<string, unknown>;
};
```

## `getComicDetail(payload)`

请求：

```ts
type ComicDetailPayload = {
  comicId?: string;
  extern?: Record<string, unknown>;
};
```

返回最小结构：

```json
{
  "source": "plugin-id",
  "comicId": "comic-id",
  "extern": {},
  "data": {
    "normal": {
      "comicInfo": {
        "id": "comic-id",
        "title": "标题",
        "titleMeta": [],
        "creator": {
          "id": "creator-id",
          "name": "作者",
          "avatar": {
            "id": "creator-id",
            "url": "",
            "name": "",
            "path": "",
            "extension": {}
          },
          "onTap": {},
          "extension": {}
        },
        "description": "",
        "cover": {
          "id": "comic-id",
          "url": "",
          "name": "",
          "path": "",
          "extension": {}
        },
        "metadata": [],
        "extension": {}
      },
      "eps": [],
      "recommend": [],
      "totalViews": 0,
      "totalLikes": 0,
      "totalComments": 0,
      "isFavourite": false,
      "isLiked": false,
      "allowComments": false,
      "allowLike": true,
      "allowCollected": true,
      "allowDownload": true,
      "extension": {}
    },
    "raw": {}
  }
}
```

说明：`normal` 建议完整返回，详情页依赖字段较多。

## `getChapter(payload)`

请求：

```ts
type ChapterPayload = {
  comicId?: string;
  chapterId?: string | number;
  extern?: Record<string, unknown>;
};
```

返回最小结构：

```json
{
  "source": "plugin-id",
  "comicId": "comic-id",
  "chapterId": "chapter-id",
  "extern": {},
  "data": {
    "chapter": {
      "epId": "chapter-id",
      "epName": "第1话",
      "length": 2,
      "epPages": "2",
      "docs": [
        {
          "id": "p1",
          "name": "001.jpg",
          "path": "001.jpg",
          "url": "https://example.com/001.jpg"
        }
      ]
    }
  }
}
```

兼容建议：可额外在顶层返回 `chapter`，用于兼容旧调用链。

## `fetchImageBytes(payload)`

请求：

```ts
type FetchImageBytesPayload = {
  url?: string;
  timeoutMs?: number;
};
```

返回（必需）：

```json
{ "nativeBufferId": 123 }
```

标准实现步骤：

1. 按 `url` 下载二进制（`arraybuffer`）
2. 转 `Uint8Array`
3. `runtime.native.put(bytes)`
4. 返回 `nativeBufferId`

## 2. 登录与会话 API

## `getLoginBundle()`

客户端要求：

- `scheme.fields` 至少 2 项（第 1 项账号、第 2 项密码）
- `data.account` / `data.password` 作为默认值

返回示例：

```json
{
  "source": "plugin-id",
  "scheme": {
    "version": "1.0.0",
    "type": "login",
    "title": "账号登录",
    "fields": [
      { "key": "account", "kind": "text", "label": "账号" },
      { "key": "password", "kind": "password", "label": "密码" }
    ],
    "action": { "fnPath": "loginWithPassword", "submitText": "登录" }
  },
  "data": { "account": "", "password": "" }
}
```

## `loginWithPassword(payload)`

请求：`{ account?: string; password?: string; extern?: object }`

返回结构（推荐）：

```json
{
  "source": "plugin-id",
  "data": {
    "account": "user@example.com",
    "password": "******",
    "token": "..."
  },
  "raw": {}
}
```

说明：客户端当前只校验调用是否成功，不强依赖字段名；建议保留 `data` 与 `raw`。

## `clearPluginSession()`（可选）

返回结构（推荐）：

```json
{ "ok": true, "message": "插件会话已清理" }
```

若在 `getCapabilitiesBundle` 暴露该动作，建议实现。

## 3. 设置与用户信息 API

## `getSettingsBundle()`

客户端读取：

- `scheme.sections[].fields[]`
- `data.values`
- `data.canShowUserInfo`

类型参考（TS）：

```ts
type SettingsFieldKind =
  | "text"
  | "password"
  | "switch"
  | "select"
  | "choice"
  | "multiChoice";

type BaseSettingsField = {
  key: string;
  kind: SettingsFieldKind;
  label: string;
  fnPath?: string;
  persist?: boolean; // 默认 true
};

type OptionSettingsField = BaseSettingsField & {
  kind: "select" | "choice" | "multiChoice";
  options?: Array<{ label: string; value: unknown }>;
};

type PlainSettingsField = BaseSettingsField & {
  kind: "text" | "password" | "switch";
};

type SettingsField = OptionSettingsField | PlainSettingsField;

export type SettingsBundleContract = {
  source: string;
  scheme: {
    version: "1.0.0";
    type: "settings";
    sections: Array<{
      id: string;
      title: string;
      fields: SettingsField[];
    }>;
  };
  data: {
    canShowUserInfo: boolean;
    values: Record<string, unknown>;
  };
};
```

`fnPath` 行为：用户修改该字段时，客户端会调用：

```json
{
  "key": "字段key",
  "value": "新值"
}
```

## `getCapabilitiesBundle()`

客户端读取 `scheme.actions[]`，每项至少：

```ts
type CapabilityAction = {
  key?: string;
  title: string;
  fnPath: string;
};

export type CapabilitiesBundleContract = {
  source: string;
  scheme: {
    version: "1.0.0";
    type: "capabilities";
    actions: CapabilityAction[];
  };
  data: Record<string, unknown>;
};
```

## `getUserInfoBundle()`

客户端读取 `data`：

```ts
type UserInfoData = {
  title?: string;
  avatar?: {
    id?: string;
    url?: string;
    name?: string;
    path?: string;
    extern?: { path?: string; [k: string]: unknown };
  };
  lines?: string[];
  extern?: Record<string, unknown>;
};
```

其中头像本地路径优先读 `data.avatar.extern.path`。

## 4. 页面与场景 API

## `getFunctionPage(payload)` / `get_function_page(payload)`

用途：

- 该函数用于返回功能页页面定义，而非普通数据列表。
- 当 `getInfo().function[]` 中配置 `action.type = openPluginFunction` 时，客户端会按 `payload.id` 调用该函数。
- 返回的 `scheme + data` 会被渲染为独立页面或弹窗。

调用链：

1. `getInfo` 返回功能入口：`{ action: { type: "openPluginFunction", payload: { id: "hotSearch" }}}`
2. 用户点击入口
3. 客户端调用 `getFunctionPage({ id: "hotSearch" })`
4. 客户端按 `scheme.body` 与 `data` 渲染 UI

请求常见：`{ id?: string, extern?: object }`

返回值应为 `scheme + data` 页面方案。

支持的 `scheme.body` 节点类型：

- `list`
- `chip-list`
- `action-grid`
- `comic-section-list`
- `comic-grid`

函数页示例：

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
        "cover": { "url": "", "path": "", "extern": {} },
        "action": {
          "type": "openComicList",
          "payload": { "scene": { "title": "排行榜", "source": "plugin-id" } }
        }
      }
    ]
  }
}
```

## `getComicListSceneBundle()`

返回 `data.scene`：

```ts
type ComicListScene = {
  title: string;
  source: string;
  body: {
    type: "pluginPagedComicList" | "pluginPagedCreatorList";
    request: {
      fnPath: string;
      core?: Record<string, unknown>;
      extern?: Record<string, unknown>;
    };
  };
  filter?: {
    fnPath: string;
    core?: Record<string, unknown>;
    extern?: Record<string, unknown>;
  };
};
```

## `getCloudFavoriteSceneBundle()` / `get_cloud_favorite_scene_bundle()`

结构同上，差异在于默认 scene 指向云端收藏列表函数。

## 过滤器 bundle（例如 `getRankingFilterBundle`）

返回结构：

```json
{
  "source": "plugin-id",
  "scheme": {
    "title": "筛选",
    "fields": [
      {
        "key": "ranking",
        "kind": "choice",
        "label": "榜单",
        "options": [
          {
            "label": "日榜",
            "value": "day",
            "result": {
              "core": { "days": "H24", "type": "comic" },
              "extern": { "source": "ranking" },
              "params": { "bodyType": "pluginPagedComicList" }
            }
          }
        ]
      }
    ]
  },
  "data": {
    "values": { "ranking": "day" }
  }
}
```

`result` 规则：

- `result.core` 会并入列表请求 `core`
- `result.extern` 会并入列表请求 `extern`
- `result` 的其他字段用于 UI 参数（如 `params.bodyType`）

## `getAdvancedSearchScheme()` / `get_advanced_search_scheme()`

返回结构：

```json
{
  "source": "plugin-id",
  "scheme": {
    "fields": [
      {
        "key": "sortBy",
        "kind": "choice",
        "label": "排序",
        "options": [
          { "label": "最新", "value": 1 }
        ]
      },
      {
        "key": "categories",
        "kind": "multiChoice",
        "label": "分类",
        "options": [
          { "label": "同人", "value": "同人" }
        ]
      }
    ]
  },
  "data": {
    "values": {
      "sortBy": 1,
      "categories": ["同人"]
    }
  }
}
```

## 5. 收藏 / 点赞 / 评论 API

## `toggleLike(payload)`

请求：`{ comicId?: string; currentLiked?: boolean }`

返回：

```json
{ "liked": true }
```

## `toggleFavorite(payload)`

请求：`{ comicId?: string; currentFavorite?: boolean }`

返回：

```json
{ "favorited": true, "nextStep": "none" }
```

`nextStep` 常见值：

- `none`
- `selectFolder`（客户端会继续调 `listFavoriteFolders` 和 `moveFavoriteToFolder`）

## `listFavoriteFolders(payload)`

返回：

```json
{
  "items": [
    { "id": "folder-1", "name": "默认" }
  ]
}
```

## `moveFavoriteToFolder(payload)`

请求：`{ comicId?: string; folderId?: string; folderName?: string }`

返回：

```json
{ "ok": true }
```

## `getCommentFeed(payload)`

请求：`{ comicId?: string; page?: number; extern?: object }`

返回最小结构：

```json
{
  "source": "plugin-id",
  "data": {
    "replyMode": "lazy",
    "canComment": { "comic": true, "reply": true },
    "paging": { "page": 1, "hasReachedMax": false },
    "topItems": [],
    "items": []
  }
}
```

评论项结构：

```ts
type CommentItem = {
  id: string;
  author: {
    name: string;
    avatar: {
      url: string;
      extern?: { path?: string; [k: string]: unknown };
    };
  };
  content: string;
  createdAt: string;
  replyCount: number;
  replies: CommentItem[];
  extern: Record<string, unknown>;
};
```

`replyMode` 说明：

- `embedded`：回复放在 `replies`，客户端不再调 `loadCommentReplies`
- `lazy`：客户端会按需调 `loadCommentReplies`

## `loadCommentReplies(payload)`

请求：`{ commentId?: string; page?: number; extern?: { commentId?: string } }`

返回：

```json
{
  "source": "plugin-id",
  "data": {
    "commentId": "comment-1",
    "paging": { "page": 1, "hasReachedMax": false },
    "items": []
  }
}
```

## `postComment(payload)` / `postCommentReply(payload)`

请求：

- 发主评论：`{ comicId?: string; content?: string }`
- 发回复：`{ commentId?: string; content?: string; extern?: { commentId?: string } }`

返回结构（推荐）：

```json
{
  "source": "plugin-id",
  "scheme": { "version": "1.0.0", "type": "commentMutation" },
  "data": {
    "ok": true,
    "mode": "postComment",
    "parentId": "comment-1",
    "created": {},
    "insertHint": {
      "strategy": "prependAfterTop",
      "targetCommentId": "comment-1",
      "needsRefetch": false
    }
  }
}
```

`insertHint.strategy` 常见值：

- `prependAfterTop`
- `prepend`

## 6. 阅读快照 API

## `getReadSnapshot(payload)`

请求：

```ts
type ReadSnapshotPayload = {
  comicId?: string;
  chapterId?: string | number;
  extern?: {
    order?: number;
    [k: string]: unknown;
  };
};
```

返回最小结构：

```json
{
  "source": "plugin-id",
  "extern": {},
  "data": {
    "comic": {
      "id": "comic-id",
      "source": "plugin-id",
      "title": "标题",
      "description": "",
      "cover": { "id": "", "url": "", "path": "", "extern": {} },
      "creator": { "id": "", "name": "", "avatar": { "url": "", "path": "", "extern": {} }, "extern": {} },
      "titleMeta": [],
      "metadata": [],
      "extern": {}
    },
    "chapter": {
      "id": "chapter-id",
      "name": "第1话",
      "order": 1,
      "pages": [
        { "id": "p1", "name": "001.jpg", "path": "001.jpg", "url": "https://...", "extern": {} }
      ],
      "extern": {}
    },
    "chapters": [
      { "id": "chapter-id", "name": "第1话", "order": 1, "extern": {} }
    ]
  }
}
```

## 7. fnPath 速查（客户端会直接调用）

- 基础：`init` `getInfo` `searchComic` `getComicDetail` `getChapter` `fetchImageBytes`
- 登录：`getLoginBundle` `loginWithPassword`
- 设置：`getSettingsBundle` `getCapabilitiesBundle` `getUserInfoBundle`
- 页面：`getFunctionPage` `get_function_page`
- 列表场景：`getComicListSceneBundle` `getCloudFavoriteSceneBundle` `get_cloud_favorite_scene_bundle`
- 搜索扩展：`getAdvancedSearchScheme` `get_advanced_search_scheme`
- 收藏点赞：`toggleFavorite` `toggleLike` `listFavoriteFolders` `moveFavoriteToFolder`
- 评论：`getCommentFeed` `loadCommentReplies` `postComment` `postCommentReply`
- 阅读：`getReadSnapshot`

若仅实现最小可用集，建议先完成第 1 节五件套，再逐步补齐可选能力。
