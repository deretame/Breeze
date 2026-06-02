# 插件 API 契约

本文给出 Breeze 插件每个 `fnPath` 的 TypeScript 类型定义与调用语义。

## 0. 通用约定

### 0.1 入参模型

宿主调用时总是传入一个扁平对象。顶层放业务主参数，透传字段放 `extern`：

```ts
// 泛型入参模型
type PluginPayload<T extends Record<string, unknown>> = T & {
  extern?: Record<string, unknown>;
};
```

例如 `searchComic` 的实际签名：

```ts
import type { SearchComicPayload } from "../types/type";

async function searchComic(payload: SearchComicPayload): Promise<SearchResultContract> {}
```

所有参数类型定义在示例仓库 `types/type.d.ts` 中，下文每个 `fnPath` 会标注其对应的 Payload 和返回类型。

### 0.2 返回模型

绝大部分接口返回统一信封结构：

```ts
type PluginEnvelope = {
  source: string;                       // 插件 ID
  scheme?: Record<string, unknown>;     // 页面渲染协议
  data?: Record<string, unknown>;       // 业务数据
  extern?: Record<string, unknown>;     // 透传上下文
  [key: string]: unknown;               // 其他平铺字段（如 comicId、paging）
};
```

宿主机型 `scheme` 知道"页面长什么样"，机型 `data` 知道"页面值是多少"。插件只需按类型填充即可。

### 0.3 错误处理

- 返回值必须是可 JSON 序列化的对象（非对象会触发"返回格式错误"）
- 抛出的 `Error` 字符串会直接显示在客户端
- 建议始终返回 `source` 字段，便于排查

### 0.4 `init`（可选）

宿主可能在 runtime 启动后调用 `init`。如未实现则跳过。若实现，建议返回 `{ source, data: { ok: true } }`。

注意：热更新时 QJS 实例重建，`init` 会重新调用。不要用 `init` 做一次性初始化。

### 0.5 类型引用

所有类型定义在示例仓库 `types/type.d.ts`。下文标注的 Payload 和 Contract 类型均来自该文件。

---

## 1. fnPath 职责总览

下表中 Host 调用的函数是宿主按场景主动触发；回调函数是用户在 UI 上操作后宿主代调。

| fnPath                    | 触发场景                           |
| ------------------------- | ---------------------------------- |
| `getInfo`                 | 发现页加载插件卡片                 |
| `searchComic`             | 搜索页输入关键词 / 翻页 / 高级搜索 |
| `getComicDetail`          | 打开漫画详情页                     |
| `getReadSnapshot`         | 阅读页初始化、切章                 |
| `getChapter`              | 下载章节内容                       |
| `fetchImageBytes`         | 阅读/下载时获取图片二进制          |
| `toggleLike`              | 详情页点点赞                       |
| `toggleFavorite`          | 详情页点收藏                       |
| `listFavoriteFolders`     | 收藏后需选择收藏夹                 |
| `moveFavoriteToFolder`    | 用户确认收藏夹                     |
| `getCommentFeed`          | 打开评论面板 / 翻页                |
| `loadCommentReplies`      | 展开评论回复                       |
| `postComment`             | 发送主评论                         |
| `postCommentReply`        | 回复某条评论                       |
| `getAdvancedSearchScheme` | 搜索页打开高级筛选                 |
| `getComicListSceneBundle` | 发现页按 source 加载默认列表       |
| `getRankingData`          | 列表页 body 请求                   |
| `getRankingFilterBundle`  | 列表页点筛选按钮                   |
| `getSettingsBundle`       | 打开插件设置页                     |
| `getCapabilitiesBundle`   | 打开设置页（操作区段）             |
| `getUserInfoBundle`       | 设置页显示用户卡片                 |

以下为回调函数，由插件在 setting / capability 中指定 `fnPath`，用户操作时宿主代调：

| fnPath             | 触发条件               |
| ------------------ | ---------------------- |
| `onAuthChanged` 等 | 设置页字段变更         |
| `clearPluginCache` | 设置页点击能力操作按钮 |

---

## 2. 核心 API

### `getInfo()`

返回插件基本信息与功能入口。

```ts
// 返回类型 InfoContract
type InfoContract = {
  name: string;
  uuid: string;
  iconUrl: string;
  creator: { name: string; describe: string; coverUrl?: string };
  describe: string;
  version: string;
  home?: string;
  updateUrl?: string;
  npmName?: string;
  function: PluginFunctionItem[];
};

type PluginFunctionItem = {
  id: string;
  title: string;
  action:
    | { type: "openSearch"; payload: { source: string; keyword?: string } }
    | { type: "openComicDetail"; payload: { comicId: string } }
    | { type: "openWeb"; payload: { title?: string; url: string } }
    | { type: "openComicList"; payload: { scene: ComicListScene } }
    | {
        type: "openPluginFunction";
        payload: {
          id: string;
          title?: string;
          presentation?: "page" | "dialog";
        };
      }
    | { type: "openCloudFavorite"; payload: { title: string } };
};

type ComicListScene = {
  title: string;
  source: string;
  body: {
    type: "pluginPagedComicList" | "pluginPagedCreatorList";
    request: ComicListRequest;
  };
  filter?: ComicListRequest;
};

type ComicListRequest = {
  fnPath: string; // 列表数据函数名
  core?: Record<string, unknown>; // 固定请求参数
  extern?: Record<string, unknown>; // 透传上下文
};
```

目前推荐使用 `openComicList` 作为功能入口。示例见 [快速开始](/guide/quick-start)。

### `searchComic(payload)`

```ts
// 入参 SearchComicPayload
type SearchComicPayload = {
  keyword?: string;
  page?: number;
  extern?: Record<string, unknown>;
};

// 返回 SearchResultContract
type SearchResultContract = {
  source: string;
  extern: Record<string, unknown> | null;
  scheme: {
    version: "1.0.0";
    type: "searchResult";
    source: string;
    list: string;
  };
  data: { paging: PagingInfo; items: ComicListItem[] };
  paging: PagingInfo;
  items: ComicListItem[];
};

type PagingInfo = {
  page: number;
  pages: number;
  total: number;
  hasReachedMax: boolean;
};

type ComicListItem = {
  source: string;
  id: string;
  title: string;
  subtitle: string;
  finished: boolean;
  likesCount: number;
  viewsCount: number;
  updatedAt: string;
  cover: ImageItem;
  metadata: MetadataListItem[];
  raw: Record<string, unknown>;
  extern: Record<string, unknown>;
};
```

`extern` 中会包含高级搜索选中的筛选项。

### `getComicDetail(payload)`

```ts
// 入参 ComicDetailPayload
type ComicDetailPayload = {
  comicId?: string;
  extern?: Record<string, unknown>;
};

// 返回 ComicDetailContract
type ComicDetailContract = {
  source: string;
  comicId: string;
  extern: Record<string, unknown> | null;
  scheme: { version: "1.0.0"; type: "comicDetail"; source: string };
  data: { normal: ComicDetailNormal; raw: unknown };
};

type ComicDetailNormal = {
  comicInfo: {
    id: string;
    title: string;
    titleMeta: ActionItem[];
    creator: {
      id: string;
      name: string;
      avatar: ImageItem;
      onTap: Record<string, unknown>;
      extern: Record<string, unknown>;
    };
    description: string;
    cover: ImageItem;
    metadata: MetadataListItem[];
    extern: Record<string, unknown>;
  };
  eps: ChapterSummary[]; // 章节列表
  recommend: RecommendItem[];
  totalViews: number;
  totalLikes: number;
  totalComments: number;
  isFavourite: boolean;
  isLiked: boolean;
  allowComments: boolean;
  allowLike: boolean;
  allowCollected: boolean;
  allowDownload: boolean;
  extern: Record<string, unknown>;
};

// 基础类型
type ActionItem = {
  name: string;
  onTap: Record<string, unknown>;
  extern: Record<string, unknown>;
};
type ImageItem = {
  id: string;
  url: string;
  name: string;
  path: string;
  extern: Record<string, unknown>;
};
```

> `url` 必须是非空占位符字符串，不能为 404 地址。宿主不会用它来下载图片，但会校验格式。图片下载完全由 `fetchImageBytes` 自行处理。

```ts
type MetadataListItem = { type: string; name: string; value: ActionItem[] };
```

### 章节字段说明

章节相关数据统一使用以下字段，会同时出现在 `CommonDetail` 的 `eps[]` 和 `getReadSnapshot` / `getChapter` 的返回中：

```ts
type ChapterSummary = {
  id: string;               // 章节自身标识
  requestId: string;        // 宿主调用 getReadSnapshot / getChapter 时用于请求章节
  logicalKey: string;       // 宿主内部用于识别章节（大部分时候可与 requestId 相同）
  storageChapterId: string; // 下载到本地后的目录名（大部分时候可与 requestId 相同）
  name: string;             // 章节名
  order: number;            // 章节顺序
  extern: Record<string, unknown>; // 插件透传数据
};

type ChapterPage = {
  id: string;
  name: string;
  path: string;
  url: string;
  extern: Record<string, unknown>;
};
```

### `getReadSnapshot(payload)`

```ts
// 入参 ReadSnapshotPayload
type ReadSnapshotPayload = {
  comicId?: string;
  chapterId?: string | number;  // 即 requestId
  extern?: Record<string, unknown>;
};

// 返回 ReadSnapshotContract
type ReadSnapshotContract = {
  source: string;
  extern: Record<string, unknown> | null;
  data: {
    comic: {
      id: string;
      source: string;
      title: string;
      extern: Record<string, unknown>;
    };
    chapter: ChapterWithPages; // 当前章节 + 图片列表
    chapters: Array<{
      id: string;
      name: string;
      order: number;
      extern: Record<string, unknown>;
    }>;
  };
};


type ChapterWithPages = ChapterSummary & { pages: ChapterPage[] };
```

`chapters` 是章节导航列表（精简版），`chapter` 是当前选中章节（含 `pages`）。

### `fetchImageBytes(payload)`

```ts
// 入参 FetchImageBytesPayload
type FetchImageBytesPayload = {
  url?: string;
  timeoutMs?: number;
  taskGroupKey?: string;  // 下载任务组标识，宿主可通过它批量取消
  extern?: Record<string, unknown>;
};

// 返回类型（直接返回 Uint8Array，不再返回 { nativeBufferId }）
type FetchImageBytesResult = Uint8Array<ArrayBufferLike>;
```

`url` 来自 `ImageItem.url`，宿主不会用它下载图片，下载逻辑由插件自行实现。但传入的 `url` 必须是有效占位符字符串，不能为空或 404 地址。

```ts
// 实现建议： 
async function fetchImageBytes({
  url,
  timeoutMs = 30000,
}: FetchImageBytesPayload): Promise<Uint8Array> {
  const res = await fetch(url, {
    headers: { "x-rquickjs-host-offload-binary-v1": "1" },
    signal: AbortSignal.timeout(timeoutMs),
  });
  return new Uint8Array(await res.arrayBuffer());
}
```

### `getChapter(payload)`

下载场景使用，结构与 `getReadSnapshot` 类似但携带完整的 `scheme + data + comicId/chapterId`：

```ts
// 入参 ChapterPayload
type ChapterPayload = {
  comicId?: string;
  chapterId?: string | number;
  page?: number;
  extern?: Record<string, unknown>;
};

// 返回 ChapterContentContract
type ChapterContentContract = {
  source: string;
  comicId: string;
  chapterId: string;
  extern: Record<string, unknown> | null;
  scheme: { version: "1.0.0"; type: "chapterContent"; source: string };
  data: {
    comic: {
      id: string;
      source: string;
      title: string;
      extern: Record<string, unknown>;
    };
    chapter: ChapterWithPages;
    chapters: Array<{
      id: string;
      name: string;
      order: number;
      extern: Record<string, unknown>;
    }>;
  };
};
```

---

## 3. 社交 API

### `toggleLike(payload)`

```ts
// 入参 ToggleLikePayload
type ToggleLikePayload = {
  comicId?: string;
  currentLiked?: boolean;
  extern?: Record<string, unknown>;
};

// 返回 ToggleLikeResult
type ToggleLikeResult = { liked: boolean };

```

### `toggleFavorite(payload)`

```ts
// 入参 ToggleFavoritePayload
type ToggleFavoritePayload = {
  comicId?: string;
  currentFavorite?: boolean;
  extern?: Record<string, unknown>;
};

// 返回 ToggleFavoriteResult
type ToggleFavoriteResult = {
  favorited: boolean;
  nextStep: "none" | "selectFolder";
};

```

`nextStep` 为 `selectFolder` 时，宿主会继续调用 `listFavoriteFolders` 和 `moveFavoriteToFolder`。

### `listFavoriteFolders()`

```ts
// 返回 ListFavoriteFoldersResult
type ListFavoriteFoldersResult = { items: Array<{ id: string; name: string }> };
```

### `moveFavoriteToFolder(payload)`

```ts
// 入参 MoveFavoriteToFolderPayload
type MoveFavoriteToFolderPayload = {
  comicId?: string;
  folderId?: string;
  folderName?: string;
  extern?: Record<string, unknown>;
};

// 返回 { ok: boolean }
```

### 评论流

```ts
// 入参 CommentFeedPayload
type CommentFeedPayload = {
  comicId?: string;
  page?: number;
  extern?: Record<string, unknown>;
};

// 返回 CommentFeedContract
type CommentFeedContract = {
  source: string;
  extern: Record<string, unknown> | null;
  scheme: { version: "1.0.0"; type: "commentFeed" };
  data: {
    topItems: CommentItem[];
    items: CommentItem[];
    paging: { hasReachedMax: boolean };
    replyMode: "lazy" | "embedded"; // lazy: 按需加载回复, embedded: 回复内嵌
    canComment: { comic: boolean; reply: boolean };
  };
};

type CommentItem = {
  id: string;
  author: { name: string; avatar: { url: string; path: string } };
  content: string;
  createdAt: string;
  replyCount: number;
  replies: CommentItem[];
  extern: Record<string, unknown>;
};

// 加载回复
type CommentRepliesPayload = {
  comicId?: string;
  commentId?: string;
  page?: number;
  extern?: Record<string, unknown>;
};

type CommentRepliesContract = {
  source: string;
  extern: Record<string, unknown> | null;
  scheme: { version: "1.0.0"; type: "commentReplies" };
  data: {
    commentId: string;
    items: CommentItem[];
    paging: { hasReachedMax: boolean };
  };
};

// 发评论
type CommentPostPayload = {
  comicId?: string;
  content?: string;
  extern?: Record<string, unknown>;
};

// 回复评论
type CommentReplyPayload = {
  comicId?: string;
  commentId?: string;
  content?: string;
  extern?: Record<string, unknown>;
};

// 发评/回复的统一返回
type CommentMutationContract = {
  source: string;
  scheme: { version: "1.0.0"; type: "commentMutation" };
  data: {
    ok: boolean;
    mode: "postComment" | "postReply";
    parentId?: string;
    created: CommentItem | null;
    insertHint: {
      needsRefetch: boolean;
      strategy?: "prependAfterTop" | "prepend";
      targetCommentId?: string;
    };
  };
};
```

- `replyMode: "lazy"` — 回复按需加载，宿主会调 `loadCommentReplies`
- `replyMode: "embedded"` — 回复直接放在 `replies` 中，不再调 `loadCommentReplies`
- `insertHint.strategy` — `prependAfterTop` 插到列表顶部（主评论），`prepend` 插为回复

---

## 4. 发现与列表

### `getAdvancedSearchScheme()`

定义搜索页的高级搜索筛选项。用户选中后，筛选值会通过 `extern` 传入 `searchComic`。

```ts
// 返回 AdvancedSearchContract
type AdvancedSearchContract = {
  source: string;
  scheme: {
    version: "1.0.0";
    type: "advancedSearch";
    title?: string;
    fields: AdvancedSearchField[];
  };
  data: { values: Record<string, unknown> };
};

type AdvancedSearchField = {
  key: string;
  kind: "text" | "switch" | "choice" | "multiChoice";
  label: string;
  options?: Array<{ label: string; value: unknown }>;
};
```

### `getComicListSceneBundle()`

定义发现页默认列表场景，返回 `data.scene`，宿主据此渲染列表页和调用 `body.request.fnPath` / `filter.fnPath`。

```ts
// 返回 ComicListSceneBundleContract
type ComicListSceneBundleContract = {
  source: string;
  scheme: { version: "1.0.0"; type: "comicListSceneBundle" };
  data: { scene: ComicListScene };
};
```

`ComicListScene` 类型见 `getInfo` 一节。

### `getRankingData(payload)`

列表数据函数，由 `ComicListScene.body.request.fnPath` 指定。宿主分页请求列表数据时调用。

```ts
// 入参同 SearchComicPayload（含 paging + extern）

// 返回 ComicPagedListContract
type ComicPagedListContract = {
  source: string;
  extern?: Record<string, unknown> | null;
  scheme?: Record<string, unknown>;
  data: { items: ComicListItem[]; hasReachedMax: boolean };
};
```

### `getRankingFilterBundle()`

列表筛选函数，由 `ComicListScene.filter.fnPath` 指定。用户点击列表页筛选按钮时调用。

```ts
// 返回 FilterBundleContract
type FilterBundleContract = {
  source: string;
  scheme: {
    version: "1.0.0";
    type?: string;
    title?: string;
    fields: FilterField[];
  };
  data: { values: Record<string, unknown> };
};

type FilterField = {
  key: string;
  kind: "choice";
  label: string;
  options: FilterOption[];
};

type FilterOption = {
  label: string;
  value: unknown;
  result?: {
    core?: Record<string, unknown>;   // 合并到列表请求 core
    extern?: Record<string, unknown>; // 合并到列表请求 extern
    params?: Record<string, unknown>; // UI 参数
    [key: string]: unknown;
  };
  children?: FilterOption[];
};
```



---

## 5. 设置

### `getSettingsBundle()`

```ts
// 返回 SettingsBundleContract
type SettingsBundleContract = {
  source: string;
  scheme: { version: "1.0.0"; type: "settings"; sections: SettingsSection[] };
  data: { canShowUserInfo: boolean; values: Record<string, unknown> };
};

type SettingsSection = {
  id?: string;
  title: string;
  fields: SettingsField[];
};

type SettingsField = OptionField | PlainField;

type OptionField = BaseField & {
  kind: "select" | "choice" | "multiChoice";
  options?: Array<{ label: string; value: unknown }>;
};

type PlainField = BaseField & { kind: "text" | "password" | "switch" };

type BaseField = {
  key: string; // 配置键，会出现在 values 和回调 payload 中
  kind: FieldKind; // "text" | "password" | "switch" | "select" | "choice" | "multiChoice"
  label: string; // 展示标签
  fnPath?: string; // 字段变更时回调
  persist?: boolean; // 是否由客户端持久化，默认 true
};
```

当用户修改携带 `fnPath` 的字段值时，宿主调用该函数，入参 `{ key: string, value: unknown, allValues: Record<string, unknown> }`。

### `getCapabilitiesBundle()`

设置页底部"操作"区段，点击后调用对应 `fnPath`。

```ts
// 返回 CapabilitiesBundleContract
type CapabilitiesBundleContract = {
  source: string;
  scheme: {
    version: "1.0.0";
    type: "capabilities";
    actions: CapabilityAction[];
  };
  data: Record<string, unknown>;
};

type CapabilityAction = { key?: string; title: string; fnPath: string };
```

### `getUserInfoBundle()`

设置页用户信息卡片。

```ts
// 返回 UserInfoBundleContract
type UserInfoBundleContract = {
  source: string;
  scheme: { version: "1.0.0"; type: "userInfo" };
  data: {
    title?: string;
    avatar: ImageItem;
    lines: string[];
    extern?: Record<string, unknown>;
  };
};
```

---

## 6. 数据流与调用链

### 6.1 搜索流程：高级搜索 → `searchComic`

```
用户打开搜索页 → 宿主调 getAdvancedSearchScheme() → 渲染高级搜索 UI
用户选择筛选项 → 不立即请求
用户点搜索 / 翻页 → 宿主调 searchComic({ keyword, page, extern: { sortBy, categories, ... } })
                                                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                                         高级搜索选中的 key-value 放入 extern
```

具体来说：
- `getAdvancedSearchScheme().scheme.fields[].key` 定义了筛选参数名（如 `sortBy`、`categories`）
- 用户选择后，选中的 key-value 会放入 `searchComic` 的 `extern` 字段
- 插件在 `searchComic` 中通过 `extern.sortBy` / `extern.categories` 读取筛选值

### 6.2 筛选器：filter bundle → 列表请求

```
列表页加载 → 宿主调 body.request.fnPath（如 getRankingData）获取初始数据
用户点筛选 → 宿主调 filter.fnPath（如 getRankingFilterBundle）获取筛选项
用户选择筛选项 → 宿主将 option.result 合并到下一次列表请求
```

合并规则：
- `result.core` 中的字段**直接写入**下一次列表请求的顶层
- `result.extern` 中的字段**合并进**下一次列表请求的 `extern`

```ts
// 例如 FilterOption:
{ label: "日榜", value: "day", result: { core: { type: "comic" }, extern: { rankType: "day" } } }

// 用户选择后，下一次 getRankingData 的入参变为：
{ page: 1, type: "comic", extern: { source: "ranking", rankType: "day" } }
//       ^^^^^^^^^^^^                                    ^^^^^^^^^^^^^^^^
//       result.core 平铺                                result.extern 合并
```

### 6.3 设置字段回调

设置字段可携带 `fnPath`。用户修改字段值时，宿主调用该 `fnPath`，入参为：

```ts
type SettingsFieldCallbackPayload = {
  key: string;           // 字段 key，如 "auth.account"
  value: unknown;        // 新值
  allValues: Record<string, unknown>;  // 所有字段当前值
};
```

示例仓库中的对应回调：
- 文本/密码变更 → `onAuthChanged`、`onRememberChanged`
- 开关变更 → `onAdultChanged`
- choice 变更 → `onThemeChanged`、`onQualityChanged`
- multiChoice 变更 → `onHiddenTagsChanged`

插件可在回调中做校验、保存到配置等操作。

### 6.4 能力操作回调

`getCapabilitiesBundle().scheme.actions[]` 中每项的 `fnPath` 在用户点击时被宿主调用，无入参。

### 6.5 功能入口调用链

`getInfo().function[]` 定义了插件卡片上的功能入口按钮。以 `openComicList` 为例：

```
用户点"排行榜"按钮
  → 宿主读取对应 action.payload.scene
  → 渲染列表页（标题、筛选按钮等）
  → 调用 scene.body.request.fnPath（如 getRankingData）获取列表数据
  → 用户点筛选 → 调用 scene.filter.fnPath（如 getRankingFilterBundle）
```

`scene.body.request.core` 和 `scene.body.request.extern` 作为固定参数传入每次列表请求，与筛选器动态参数合并。

### 6.6 实践建议

- **`core` 和 `extern` 各司其职**：业务参数（分页、类型、排序等）放 `core`，会话/上下文透传放 `extern`。能放进 `core` 的不要混进 `extern`。
- **筛选器 `options.value` 保持稳定**：一旦确定不要随版本改变语义，否则用户已保存的筛选值会失效。
- **`data.values` 一定给默认值**：避免空选项导致请求参数缺失，宿主不会补默认值。
- **对外提供的 `fnPath` 键名保持兼容**：如需要重命名，建议 `snake_case` + `camelCase` 同时导出。
