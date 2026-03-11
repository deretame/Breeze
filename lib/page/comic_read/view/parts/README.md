# comic_read view parts 维护笔记

`comic_read.dart` 按职责拆成了 5 个 part，后面回看逻辑时可先按下面索引找。

## 快速索引

- `comic_read_init_part.dart`
  - 初始化和释放：控制器、订阅、历史管理器、首帧收尾。
- `comic_read_interaction_part.dart`
  - 阅读交互：键盘、点击/双击、缩放、多指锁滚动、行列模式容器。
- `comic_read_system_ui_part.dart`
  - 系统 UI 和音量键拦截：菜单显隐联动、Android 特殊处理、防抖同步。
- `comic_read_auto_read_part.dart`
  - 自动阅读：参数同步、计时器、暂停/继续、右下角浮动按钮。
- `comic_read_view_part.dart`
  - 页面拼装和历史定位：app bar、底部栏、页码组件、历史恢复跳转。

## 常用定位方式

- 先从 `comic_read.dart` 的 `build` 看当前入口状态。
- 查初始化问题直接看 `comic_read_init_part.dart`。
- 查手势/翻页/缩放冲突看 `comic_read_interaction_part.dart`。
- 查状态栏或音量键行为看 `comic_read_system_ui_part.dart`。
- 查自动阅读不触发或频率异常看 `comic_read_auto_read_part.dart`。
- 查历史跳转错位看 `comic_read_view_part.dart` 里的 `_handleHistoryScroll`。
