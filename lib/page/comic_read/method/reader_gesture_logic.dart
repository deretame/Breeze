import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/controller/reader_action_controller.dart';

class ReaderGestureLogic {
  static void handleTap({
    required ReaderActionController actionController,
    required PageController controller,
    required BuildContext context,
    required TapDownDetails details,
    required VoidCallback onToggleMenu,
    VoidCallback? onBeforePageTurn,
  }) {
    if (context.read<GlobalSettingCubit>().state.readSetting.readMode == 0) {
      onToggleMenu();
      return;
    }

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
      onBeforePageTurn?.call();
      actionController.onPageActionPrev();
    } else if (tapPosition.dx < 2 * thirdWidth) {
      // 点击中间三分之一
      if (tapPosition.dy < middleTopHeight) {
        // 点击中间区域的上三分之一
        onBeforePageTurn?.call();
        actionController.onPageActionPrev();
      } else if (tapPosition.dy < middleBottomHeight) {
        // 点击中间区域的中三分之一
        onToggleMenu();
      } else {
        // 点击中间区域的下三分之一
        onBeforePageTurn?.call();
        actionController.onPageActionNext();
      }
    } else {
      // 点击右边三分之一
      onBeforePageTurn?.call();
      actionController.onPageActionNext();
    }
  }
}
