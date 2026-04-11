# 插件 API 契约（按 fnPath）

这页是给第三方作者直接抄规格用的。

目标：你实现的每个 `fnPath`，都能被 Breeze 正常消费，不靠猜。

## 0. 通用调用规则

### 0.1 调用入参

客户端调用时会把参数组装成：

```ts
const payload = {
  ...core,
  extern: extern ?? {}
};
```

所以你的函数签名通常写成：

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

大部分接口建议返回：

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

- 插件必须返回可 JSON 解析的对象（非对象会报“返回格式错误”）
- `source` 字段建议始终返回（便于调试）
- 你抛出错误时，字符串会直接显示给用户

### 0.4 `init` 是可选但推荐实现

- 客户端可能在 runtime 启动后调用 `init`
- 如果没实现，客户端会跳过
- 如果实现了，建议返回 `{ source, data: { ok: true } }`

## 1. 必需 API（建议全部实现）

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

`items[]` 单项必须可映射为统一漫画卡：

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

说明：`normal` 建议完整返回；客户端详情页依赖字段较多。

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

兼容建议：可额外顶层双写 `chapter`，提高旧调用兼容性。

## `fetchImageBytes(payload)`

请求：

```ts
type FetchImageBytesPayload = {
  url?: string;
  timeoutMs?: number;
};
```

返回（必须）：

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

返回建议：

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

说明：客户端当前只看调用是否成功，不强依赖字段名，但建议返回 `data` 与 `raw`。

## `clearPluginSession()`（可选）

返回建议：

```json
{ "ok": true, "message": "插件会话已清理" }
```

若你在 `getCapabilitiesBundle` 暴露了这个动作，建议实现。

## 3. 设置与用户信息 API

## `getSettingsBundle()`

客户端读取：

- `scheme.sections[].fields[]`
- `data.values`
- `data.canShowUserInfo`

字段结构：

```ts
type SettingsField = {
  key: string;
  kind: "text" | "password" | "switch" | "select" | "choice" | "multiChoice";
  label: string;
  options?: Array<string | { label?: string; value: unknown }>;
  fnPath?: string;
  persist?: boolean;
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

请求常见：`{ id?: string, extern?: object }`

返回必须是 `scheme + data` 页面方案。

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

同上，区别是默认 scene 指向你的云端收藏列表函数。

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

返回建议：

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

如果你只实现最小可用集，至少先把第 1 节五件套做完整，再逐步加可选能力。
