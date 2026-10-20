# 老页面（OldHome / OldRanking）插件化复活

> 已实现（2026-10-20）。插件先发版，app 后删旧。kit 未改，新类型用 `Record<string, unknown>`。

## 1. 背景

- `OldHomePage`（`lib/page/old_page/old_home/old_home_page.dart`）、`OldRankingPage`（`lib/page/old_page/old_ranking/old_ranking_page.dart`）原本为兼容老页面保留，后改为插件模式后废弃，靠设置项（`oldPageRollbackEnabled`，见 `lib/page/navigation_bar.dart`）开关。
- 现状是 bika / jm 双写死：
  - UUID 硬编码 `_pluginA` / `_pluginB`，首页写死 `hotSearch / navigation / recommend + getLatestData`，榜单写死 `getRankingData + getRankingFilterBundle`。
  - 切换是 FAB 二选一取反（`_tabIndex`），`IndexedStack + AutomaticKeepAlive` 全量预建，首次 2s 延迟加载 hack。
- 对应插件侧能力：`lib/page/discover/widgets/plugin_card.dart` 的 `_buildFunctionButtons`（读 `info['functions']`，`ActionChip`，缺 `action` 默认 `openPluginFunction/page`），`DiscoverRouter.route / attachSource` 与 `OldHomePage._handleAction` 是同一套 action 协议的两份实现。

## 2. 目标

- 把老两页复用为**插件通用页**：行为类似 discover 的插件功能按钮，但按插件规范来做，插件按规定导出即可接入。
- 第一页：显示插件功能，可返回多个，用 `TabView` 切换。
- 第二页：显示插件云端收藏。

## 3. 已定决策

1. **新增俩插件入口，不复用任何现成 `fnPath`**：`getFunctionPage / getComicListSceneBundle / getCloudFavoriteSceneBundle / getRankingData` 等一律不直接用。新入口隔离，显式 opt-in，避免兼容性问题。返回体内部的线格式复用现有（`scheme+data / scene+filter`），Dart 不写新渲染器。
2. **发布顺序**：两个插件都是用户自己维护。先独立更新插件，加上俩新函数导出（纯新增，老 app 不调用，无兼容问题）；隔一段时间后再推新 app，新 app 删掉原本 oldpage 硬编码，只调新函数。无双轨、无 fallback、无硬编码映射表。
3. **bundle 覆盖问题不需要管**（用户确认不存在，app 侧不处理）。
4. **切换器**：FAB 二选一删掉。插件多了（十几个几十个）点不过来，改为点击后弹窗（bottom sheet / dialog，带图标 + 名 + 搜索）切换。标题可点与 FAB 同入口。`<=3` 也不做分段，保持单一交互。
5. **不保留状态**：多标签页/多插件不保活。不用 `IndexedStack`，一次只装一个 panel。内容每次重进重载。
6. **右上自定义**：右上角的筛选功能走现有的 `ComicListScene.filter` 规约（`ListFilterBundle`：`PluginListFilterSchema scheme + defaultSelections`，见 `lib/page/comic_list/models/list_filter_bundle.dart`），不另起一套。插件在新函数返回的 `header.actions` / scene 里引用之前 `getInfo.functions` 里定义过的功能，Dart 统一渲染，插件不自定义 widget。
7. **单插件多界面**：新函数一次返回 `tabs[]`（`{id, title, ...}`），Dart 通用 `TabBar + 懒加载`，`tabs.length == 1` 不显示 TabBar。`id` 稳定，用于记住选中。Tab 切换时右上角的筛选跟着变（每个 tab 有自己的 `header.actions` / `filter`）。
8. **加载时机**：删掉现在的固定等一段时间（2s 延迟 hack），改为 init 结束后就开始尝试加载。
9. **选中记忆**：记录最后选择的是哪一个插件，第一页和第二页独立记录，存本机（`SharedPreferences` 之类），不进 ObjectBox。
10. **全新界面**：原本的 `OldHomePage / OldRankingPage` 界面不用，新设计两个界面（文件/路由重建，不复用旧 widget）。
11. **getInfo 全局化**：`fetch` 成功 / 缓存失效时 service 广播 `infoStream/infoErrorStream`，全局 `PluginRegistryCubit.state` 收 `plugins + infos + infoErrors`。所有 UI（discover 卡片、书架/搜索/聚合/详情的插件名、新两页候选、选择器图标）一律订阅全局，不再各自 `getCachedPluginInfo` + 本地缓存。插件更新后新功能自动显示，无需手动刷新。失败态也进全局（`infoErrors`，成功清除），discover 的 error + 重试保留。
## 4. 删除清单（新 app 切过去时）

- `_OldHomePanelA/B`、`_InlineLatestList`、`_FunctionSection` 硬编码（`hotSearch / navigation / recommend / getLatestData`）。
- `_bikaRankingScene / _jmRankingScene`、`_pluginA/_pluginB` UUID、`_tabIndex/_panelIndex` 取反 FAB、`_hasDelayedInitialLoad` 2s hack。
- `_handleAction / _attachActionSource` 合进 `DiscoverRouter`（一份协议一个实现）。

## 5. 待补充（用户慢慢补）

- 函数名已定（拼写已确认）：第一页 `getPluginHomePagesBundle`，第二页 `getPluginCloudFavoritePagesBundle`。
- 入参：`core: {} + extern: {source}` 空参，不塞业务参数（JM `getHomeLatestData` 的 page 由 tab 内 scene 分页自己管，不走新函数参数）。
- 返回结构（两边对称）：
  ```
  { source, scheme: {version:"1.0.0", type:"homePagesBundle"|"cloudFavoritePagesBundle"},
    data: { pages/tabs: [{id, title, scene?: ComicListScene, page?: FunctionPageContract, header?: {actions: PluginAction[]}}] } }
  ```
  tab 内两种载荷：`scene`（走 `ComicListPage` 现成渲染，filter 走现有 `filter` bundle，右上联动每个 tab 独立）或 `page`（`FunctionPageContract` 的 scheme+data，走 `DiscoverSchemeRenderer`）。Dart 不写新渲染器。
  kit 先不改：新类型用 `Record<string, unknown>` + 局部类型守卫，不用 `any`（仓库 lint 规则禁 `any`）。
- 本机 key 已定：`homePluginId`（第一页）、`cloudFavoritePluginId`（第二页），存本机。记忆插件不在候选中（被删/禁用/失位）时静默选第一项。
- 未就绪等待：调 bundle 前等该插件 initOk（init 登录走完）。选择器照常列（有位就行），点进未就绪插件就 loading 一直等，不超时。
- 空态/错误：不区分文案。记忆插件不存在时静默选第一项；其他报错直接透传。调用前先看标准位，有才调。
- 选择器：只列出标准位支持的插件，不预调用探测。
- 右上联动：tab 页级 `filter`/`header.actions`，TabBar 切换时 AppBar actions 跟着换。`filter` 复用 `ComicListRequest` 规约（引用 `functions` 已定义功能）。
- `oldPageRollbackEnabled` 开关直接删掉，老两页默认显示。
- init 语义（JM/bika）：无账号直接成功；有账号登录最多 3 次，成功才返回；3 次失败抛错（App 侧一直 loading）。签到后台跑一次，不阻塞 init。
- TabView：支持左右滑动；同插件切 tab 保活（`AutomaticKeepAlive`），切插件 key 变化整棵丢掉不保活。
- 待定：header 的搜索 action 语义。`openSearch` 空 keyword 会直进 `SearchResultRoute` 发一次空搜；旧首页是进 `SearchRoute` 搜索框页。需要新增 action 类型（如 `openSearchPage`）或约定空 keyword 走搜索框页。
- 待定：首页内嵌分页的“限制”具体是什么。
