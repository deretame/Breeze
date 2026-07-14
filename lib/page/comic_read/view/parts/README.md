# comic_read view parts 维护笔记

`comic_read.dart` 按职责拆成了 4 个 part，后面回看逻辑时可先按下面索引找。

## 快速索引

- `comic_read_init_part.dart`
  - 初始化和释放：控制器、订阅、历史管理器、首帧收尾。
- `comic_read_interaction_part.dart`
  - 阅读交互：键盘、点击/双击、缩放、多指锁滚动、行列模式容器。
- `comic_read_system_ui_part.dart`
  - 系统 UI 和音量键拦截：菜单显隐联动、Android 特殊处理、防抖同步。
- `comic_read_auto_read_part.dart`
  - 自动阅读：参数同步、计时器、暂停/继续、右下角浮动按钮。

## 状态管理

半无缝章节拼接逻辑已迁移到 `lib/page/comic_read/cubit/reader_seamless_cubit.dart`。
自动阅读、系统 UI 等副作用已收敛到 `lib/page/comic_read/controller/` 下的专用控制器。

## 常用定位方式

- 先从 `comic_read.dart` 的 `build` 看当前入口状态。
- 查初始化问题直接看 `comic_read_init_part.dart`。
- 查手势/翻页/缩放冲突看 `comic_read_interaction_part.dart`。
- 查状态栏或音量键行为看 `comic_read_system_ui_part.dart`。
- 查自动阅读不触发或频率异常看 `comic_read_auto_read_part.dart`。
- 查章节加载/过渡卡片/无缝拼接看 `reader_seamless_cubit.dart`。
