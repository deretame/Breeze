# comic_read 模块架构与维护说明

> 面向后续维护者与 AI 助手。阅读器逻辑本身复杂、无法避免；本文目标是让「改哪里、谁说了算」尽量清晰，而不是假装简单。

相关文档：

- `view/parts/README.md`：页面 part 快速索引
- `REFACTOR_PHASE2.md`：类型收束方案（`dynamic` / `int` readMode / sealed union 等）

---

## 1. 总评

| 维度 | 现状 | 说明 |
|------|------|------|
| 目录可读性 | 较好 | 按 bloc / cubit / controller / view / widgets 分层，符合项目惯例 |
| 职责边界 | 一般 | 状态多头、State 仍是总编排器 |
| 小需求改动 | 尚可 | 设置页、chrome、纯 UI 相对好找 |
| 核心阅读行为 | 偏难 | 无缝拼接 + 槽位跳转 + 多控制器协作 |
| 可测试性 | 弱 | `part` 文件与回调式 controller 难以独立测 |

**结论**：目录结构已经比「单文件巨石」好很多，属于合理的中期形态；真正拖累维护的是**状态归属分散**、**State 编排过重**、**`ReaderSeamlessCubit` 过大**，而不是再缺几个子文件夹。

---

## 2. 目录结构

```text
comic_read/
├── comic_read.dart                 # barrel：对外 export
├── ARCHITECTURE.md                 # 本文
├── REFACTOR_PHASE2.md              # 类型改造方案（未全部落地）
│
├── view/
│   ├── comic_read.dart             # 路由页 + State 编排中枢
│   └── parts/                      # State 按职责拆出的 part（非独立模块）
│       ├── comic_read_init_part.dart
│       ├── comic_read_interaction_part.dart
│       ├── comic_read_system_ui_part.dart
│       ├── comic_read_auto_read_part.dart
│       ├── comic_read_view_part.dart
│       └── README.md
│
├── bloc/                           # 首章加载（PageBloc）
├── cubit/
│   ├── reader_cubit.dart           # 菜单显隐、当前槽位、滑动条等 UI 状态
│   ├── reader_seamless_cubit.dart  # 半无缝章节拼接（最大复杂度）
│   └── image_size_cubit.dart       # 图片尺寸缓存与估算
│
├── controller/                     # 副作用控制器（不持有长期业务真相源）
│   ├── reader_action_controller.dart
│   ├── reader_input_controller.dart
│   ├── reader_history_controller.dart
│   ├── reader_auto_read_controller.dart
│   ├── reader_system_ui_controller.dart
│   ├── reader_volume_controller.dart
│   └── reader_lifecycle_controller.dart
│
├── widgets/                        # UI 按界面职责分包
│   ├── chrome/                     # AppBar / 底部栏
│   ├── controls/                   # 滑动条等
│   ├── modes/                      # 列模式 / 行模式 / 槽位构建
│   ├── image/                      # 图片展示
│   ├── overlay/                    # 页码信息
│   ├── settings/                   # 阅读设置 Sheet
│   ├── transition/                 # 章节过渡卡片
│   ├── navigation/                 # 上下拉导航
│   ├── layout/ feedback/ dialogs/ success/
│   └── widgets.dart
│
├── method/                         # 工具与业务函数（当前偏杂物间）
├── model/                          # 领域/页面模型
├── json/                           # 章节 JSON 模型
└── type/                           # 类型别名（如 ChapterExtern）
```

---

## 3. 运行时职责：谁拥有什么

改 bug 时优先回答：**这个状态的真相源是谁？**

| 状态 / 能力 | 真相源 | 备注 |
|-------------|--------|------|
| 首章加载结果（成功/失败/epInfo） | `PageBloc` / `PageState` | 只负责进入阅读器时的第一次加载 |
| 菜单显隐、当前全局槽位、滑动条值 | `ReaderCubit` / `ReaderState` | 轻量 UI 状态 |
| 已加载章节列表、过渡卡片、槽位映射、边界加载 | `ReaderSeamlessCubit` | 半无缝核心；**不要**在 Widget 里再维护一份章节队列 |
| 图片宽高缓存 / 列高估算输入 | `ImageSizeCubit` + `ImageSizeCacheStore` | Cubit 偏运行时，Store 偏持久化 |
| 历史写入 / 恢复滚动 | `ReaderHistoryController` | 副作用；结果写回 Cubit / 滚动控制器 |
| 键盘、点击翻页、缩放、多指锁 | `ReaderInputController` + interaction part | 输入事件入口 |
| 统一动作（下一页/上一页/跳槽位等） | `ReaderActionController` | 被 input / volume / auto-read 调用 |
| 音量键翻页 | `ReaderVolumeController` | 平台侧拦截后转 action |
| 自动阅读计时 | `ReaderAutoReadController` + auto_read part | 参数同步与 UI 浮动按钮仍可能在 part |
| 系统栏 / 全屏 | `ReaderSystemUiController` + system_ui part | 菜单显隐联动 |
| 生命周期、首帧 bootstrap 标记 | `ReaderLifecycleController` | `hasBootstrappedReadState` 等 |
| 章节跳转（换路由/换章入口） | `JumpChapter`（method） | 与 seamless 边界加载不是同一条路径 |
| `PageController` / `ScrollController` / `TransformationController` | `_ComicReadPageState` | 仍由 State 持有，Cubit 不直接拥有 |

### 3.1 数据流（简化）

```text
路由参数 (comicId, order, comicInfo, type, ...)
        │
        ▼
 ComicReadPage
  ├─ PageBloc ──加载首章──► PageState.success(epInfo)
  ├─ ReaderCubit
  └─ ReaderSeamlessCubit.bootstrap(epInfo)
        │
        ▼
 ComicReadSuccessWidget
  ├─ ColumnMode / RowMode  ◄── seamless 构建的 entries / slots
  ├─ chrome / slider / page_count  ◄── ReaderCubit + settings
  └─ controllers（输入/音量/自动阅读/历史）
        │
        ▼ 边界滚动 / 点过渡卡片
 ReaderSeamlessCubit 加载邻章 → 改 totalSlots / entries
        │
        ▼
 State / ActionController 跳转全局槽位（列：Scroll；行：PageView）
```

### 3.2 常见「改哪里」索引

| 你想改什么 | 优先打开 |
|------------|----------|
| 首章加载失败 / 重试 | `bloc/page_bloc.dart`、`widgets/feedback/error.dart` |
| 菜单、当前页、滑动条数值 | `cubit/reader_cubit.dart`、`widgets/controls/slider.dart` |
| 半无缝、前后章、过渡卡片、总页数 | `cubit/reader_seamless_cubit.dart`、`widgets/transition/` |
| 列/行渲染、双页槽位 | `widgets/modes/*`、`read_mode_utils.dart` |
| 点击/双击/缩放冲突 | `controller/reader_input_controller.dart`、`view/parts/comic_read_interaction_part.dart` |
| 音量键 | `controller/reader_volume_controller.dart` |
| 自动阅读 | `controller/reader_auto_read_controller.dart`、`view/parts/comic_read_auto_read_part.dart` |
| 历史记录恢复 | `controller/reader_history_controller.dart`、`method/history_isolate_messages.dart` |
| 跳转其他章节（非 seamless 边界） | `method/jump_chapter.dart` |
| 图片显示 / 占位高度 | `widgets/image/*`、`cubit/image_size_cubit.dart` |
| 阅读设置 UI | `widgets/settings/*` |
| 底栏 / AppBar | `widgets/chrome/*` |
| 初始化顺序、dispose | `view/parts/comic_read_init_part.dart`、`view/comic_read.dart` |

---

## 4. 当前结构的优点

1. **顶层分层符合项目惯例**（bloc / cubit / view / widgets / method / model），新人能按惯例落点。
2. **副作用抽到 `controller/`**，比全部堆在 `State` 方法里更容易按主题搜索。
3. **`widgets/` 按界面职责分子目录**（chrome / modes / settings / overlay），UI 改动路径短。
4. **`view/parts` + README** 给 State 大文件做了可读性拆分，并有文字索引。
5. **多数文件体积可控**（多数 < 15KB）；复杂度相对集中，而不是均匀糊在所有文件上。
6. **已有类型改造文档**（Phase 2），说明团队意识到 `dynamic` / 魔法数字的问题。

---

## 5. 当前结构的主要问题

### 5.1 目录清晰 ≠ 职责清晰

运行时同时存在：

- 1 个 Bloc
- 3 个 Cubit（含巨型 seamless）
- 7 个 Controller
- `JumpChapter`
- State 自身持有的多个滚动/变换控制器与字段

改一个「翻到下一章并更新历史」类行为，往往要在 3～5 个文件间跳转。  
**文件夹告诉你“大概是哪一类文件”，但没有强制“只有一处能改”。**

### 5.2 `view` 仍是总编排器

`view/comic_read.dart` + `parts/*` 本质是**一个巨大的 `State` 类被物理切开**：

- Dart `part` **不能独立 import / 单测**
- `initState` 仍需串联多个 controller
- 如 `_jumpToGlobalSlot` 的编排逻辑仍在 State

`controller` 与 `part` 在自动阅读、系统 UI 等处还有职责重叠，容易出现：

> 「到底改 part 还是改 controller？」

### 5.3 复杂度热点：`ReaderSeamlessCubit`

| 文件 | 量级 | 角色 |
|------|------|------|
| `cubit/reader_seamless_cubit.dart` | ~40KB+ / 1200+ 行 | 章节目录、加载/预取、槽位映射、条目构建、列高估算、边界解析… |

这是维护瓶颈的核心。目录再漂亮，改无缝阅读仍要啃这一文件。

### 5.4 `method/` 偏杂物间

当前混有：

- 数据获取：`get_plugin_read_snapshot`、`get_local_info`
- 跳转：`jump_chapter`
- 缓存：`image_size_cache_store`
- 纯逻辑：`reader_gesture_logic`
- isolate 消息：`history_isolate_messages`

缺少「repository / domain / service」边界，只能靠文件名猜测。

### 5.5 领域类型放在 UI 层

`ReadModeEntry`、`ReadModeDoublePageSlot` 等定义在 `widgets/modes/`，  
而 `ReaderSeamlessCubit` 等业务层依赖它们——**领域模型与 Widget 耦合**，后续抽测或复用成本高。

### 5.6 类型债（Phase 2 未完成部分）

仍存在例如：

- `dynamic comicInfo` 贯穿路由 / Bloc / seamless / history
- `ChapterExtern = Map<String, dynamic>`
- `readMode` 等用 `int` 分支

类型不收束时，编译器无法兜住漏改的分支；复杂逻辑下回归成本高。详见 `REFACTOR_PHASE2.md`。

---

## 6. 约定（维护时尽量遵守）

1. **半无缝章节列表只由 `ReaderSeamlessCubit` 维护**；UI 只消费 state / 调用 public 方法。
2. **Controller 不成为第二套业务状态机**；需要持久展示的状态进 Cubit，瞬时副作用进 Controller。
3. **新增阅读设置 UI** 优先放 `widgets/settings/`，不要塞进 `view/parts`。
4. **新增纯计算**（槽位映射、手势区域判定）优先可单测的顶层函数或独立 class，避免只写在 Widget `build` 里。
5. **不要扩大 `dynamic comicInfo` 的使用面**；新代码尽量向 `ComicReadSource`（Phase 2）靠拢。
6. **`part` 文件只服务 `_ComicReadPageState`**；不要把可复用逻辑继续堆进 part。
7. **生成文件**（`*.freezed.dart`、`*.g.dart`）禁止手改。

---

## 7. 建议的演进方向（按收益排序）

> 原则：不大拆、不推倒重来；每次改动能独立验证、可回滚。

### P0 — 状态归属写清楚（已部分完成于本文）

- 改 bug 前先查第 3 节表格。
- 若发现表格与代码不符，**先改本文再改代码**，避免口头知识漂移。

### P1 — 拆分 `ReaderSeamlessCubit`（最高 ROI）

建议抽离（名称可调整，边界比命名重要）：

| 组件 | 职责 |
|------|------|
| `ChapterCatalog` | 章节列表、order ↔ index |
| `ChapterLoader` | 加载 / 预取 / 错误态 |
| `SlotMapper` | 全局槽位 ↔ 本地页、entries / double-page 构建 |
| `ColumnHeightEstimator` | 列模式高度估算（可依赖 ImageSize） |
| `ReaderSeamlessCubit` | 只做编排 + `emit` |

验收：单测可覆盖 SlotMapper / Catalog；Cubit 文件行数明显下降。

### P2 — 定死「副作用在 controller，State 只接线」

- 能搬的 part 逻辑继续搬进 controller 或纯函数。
- 最终 `part`  ideally 只保留 build 拼装；或取消 part，改为独立 `Coordinator` / 子 Widget。
- 自动阅读、系统 UI **只保留一处实现**，另一处只调用。

### P3 — 整理 `method/`

可选目标结构：

```text
data/          # snapshot、local 读取
domain/        # gesture、slot 纯逻辑
service/       # jump、history isolate 协作
```

不要求一次搬完；**新文件按新位置放**，旧文件触碰时再挪。

### P4 — 领域模型上移

- `ReadModeEntry` / slot 相关类型 → `model/`（或 `domain/`）
- `widgets/modes` 只负责渲染

### P5 — 落地 Phase 2 类型

- `ComicReadSource` 替代 `dynamic comicInfo`
- `ReaderLayoutMode` 等 enum 替代 `int` readMode
- `PageState` / entry 类型改为 sealed union（见 `REFACTOR_PHASE2.md`）

---

## 8. 明确不建议的做法

1. **仅为“目录好看”再套一层空文件夹**——当前瓶颈不在目录深度。
2. **把 seamless 逻辑复制一份到 Widget「图省事」**——会立刻出现双真相源。
3. **在 Controller 里 `emit` Cubit 状态的同时再在 State 里缓存同一份章节列表**。
4. **继续扩展 `Map<String, dynamic>` / `dynamic` 作为阅读器主数据通道**。
5. **在未理解槽位模型前“优化”滚动跳转**——列模式有估算高度 + post-frame 精修两段逻辑，易引入跳动。

---

## 9. 验证清单（改核心逻辑后）

手动回归至少覆盖：

1. 首章加载成功 / 失败重试
2. 列模式滚动、行模式 LTR / RTL、双页（若开启）
3. 半无缝：滚到边界加载前后章、过渡卡片点击、prepend 后位置不跳飞
4. 滑动条跳转、页码信息显示
5. 菜单显隐与系统栏 / 桌面全屏
6. 音量键翻页（Android）
7. 自动阅读启停与参数变更
8. 历史进入恢复进度、阅读中历史写入
9. 阅读设置各项切换后布局正确

静态检查：

```bash
# 按项目习惯，可用 puro flutter / puro dart
flutter analyze lib/page/comic_read
```

涉及 freezed / 路由时再跑 `dart ./script/code_generate.dart`。

---

## 10. 一句话备忘

> **文件夹已经够用；维护性取决于：状态只有一个真相源、seamless 可拆可测、State 只编排不堆业务、类型逐步收紧。**
