import 'package:flutter/services.dart';
import 'package:zephyr/page/comic_read/controller/reader_action_controller.dart';

/// 全局按键处理函数
/// 返回 true 表示：事件已处理，不要再发给 ListView 了（彻底屏蔽默认行为）
/// 返回 false 表示：我不关心这个键，继续往下传
bool handleGlobalKeyEvent(
  KeyEvent event,
  ReaderActionController actionController,
) {
  // 只响应按下瞬间 (KeyDown) 和 长按重复 (KeyRepeat)
  if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;

  final key = event.logicalKey;

  // 1. 定义所有“向下/下一步”的键
  final isNext =
      key == LogicalKeyboardKey.arrowDown ||
      key == LogicalKeyboardKey.numpad2 || // 小键盘 2
      key == LogicalKeyboardKey.keyS ||
      key == LogicalKeyboardKey.arrowRight || // 习惯上右也是下
      key == LogicalKeyboardKey.numpad6 || // 小键盘 6
      key == LogicalKeyboardKey.keyD;

  // 2. 定义所有“向上/上一步”的键
  final isPrev =
      key == LogicalKeyboardKey.arrowUp ||
      key == LogicalKeyboardKey.numpad8 || // 小键盘 8
      key == LogicalKeyboardKey.keyW ||
      key == LogicalKeyboardKey.arrowLeft || // 习惯上左也是上
      key == LogicalKeyboardKey.numpad4 || // 小键盘 4
      key == LogicalKeyboardKey.keyA;

  if (isNext) {
    actionController.onKeyScrollNext();
    return true; // 拦截！ListView 也就是这一刻收不到事件了，也就不会跳页了
  }

  if (isPrev) {
    actionController.onKeyScrollPrev();
    return true; // 拦截！
  }

  return false; // 其他键（比如音量键）放行
}
