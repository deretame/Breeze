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
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    if (readSetting.readMode == 0) {
      onToggleMenu();
      return;
    }

    final Offset tapPosition = details.globalPosition;
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final thirdWidth = screenWidth / 3;
    final thirdHeight = screenHeight / 3;
    final inCenterControlArea =
        tapPosition.dx >= thirdWidth &&
        tapPosition.dx < thirdWidth * 2 &&
        tapPosition.dy >= thirdHeight &&
        tapPosition.dy < thirdHeight * 2;

    if (inCenterControlArea) {
      onToggleMenu();
      return;
    }

    final shouldNext = switch (readSetting.tapPageTurnMode) {
      ReaderTapPageTurnMode.fullScreen => true,
      ReaderTapPageTurnMode.leftHand => tapPosition.dx < (screenWidth / 2),
      ReaderTapPageTurnMode.rightHand => tapPosition.dx >= (screenWidth / 2),
    };

    onBeforePageTurn?.call();
    if (shouldNext) {
      actionController.onPageActionNext();
    } else {
      actionController.onPageActionPrev();
    }
  }
}
