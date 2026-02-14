import 'package:flutter/widgets.dart';

class ReaderGestureLogic {
  static void handleTap({
    required PageController controller,
    required BuildContext context,
    required TapDownDetails details,
    required VoidCallback onToggleMenu,
  }) {
    // 获取点击的全局坐标
    final Offset tapPosition = details.globalPosition;
    // 将屏幕宽度分为三等份
    final double thirdWidth = MediaQuery.of(context).size.width / 3;
    // 将中间区域的高度分为三等份
    final double middleTopHeight =
        MediaQuery.of(context).size.height / 3; // 上三分之一
    final double middleBottomHeight =
        MediaQuery.of(context).size.height * 2 / 3; // 下三分之一

    // 判断点击区域
    if (tapPosition.dx < thirdWidth) {
      // 点击左边三分之一
      controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else if (tapPosition.dx < 2 * thirdWidth) {
      // 点击中间三分之一
      if (tapPosition.dy < middleTopHeight) {
        // 点击中间区域的上三分之一
        controller.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (tapPosition.dy < middleBottomHeight) {
        // 点击中间区域的中三分之一
        onToggleMenu();
      } else {
        // 点击中间区域的下三分之一
        controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      // 点击右边三分之一
      controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
