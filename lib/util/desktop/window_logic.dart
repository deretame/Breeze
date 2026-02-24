import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/desktop/native_window.dart';

class WindowLogic {
  static DateTime lastSaveTime = DateTime.now();

  /// 初始化窗口并恢复上次的状态
  static Future<void> initWindow(BuildContext context) async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return;
    }
    // 必须先确保绑定初始化
    await windowManager.ensureInitialized();
    if (!context.mounted) return;
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final state = globalSettingCubit.state;

    // 1. 读取保存的大小 (默认为 1280x720)
    final width = state.windowWidth;
    final height = state.windowHeight;

    logger.d(
      'initWindow: $width x $height @ ${state.windowX},${state.windowY}',
    );

    WindowOptions windowOptions = WindowOptions(
      size: Size(width, height),
      center: state.windowX == 0 && state.windowY == 0,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    // 等待窗口准备好再显示
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // 先设置位置（窗口此时还不可见），再 show，避免闪烁跳动
      if (state.windowX != 0 && state.windowY != 0) {
        await windowManager.setPosition(Offset(state.windowX, state.windowY));
      }
      await windowManager.show();
      await windowManager.focus();

      // 窗口可见后缓存 HWND，供同步操作使用
      if (Platform.isWindows) {
        NativeWindow.init();
      }
    });
  }

  /// 保存当前窗口状态
  static Future<void> saveWindowState(BuildContext context) async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return;
    }
    // 一秒钟最多更新一次
    final now = DateTime.now();
    if (now.difference(lastSaveTime).inMilliseconds < 1000) {
      return;
    }
    lastSaveTime = now;

    if (!context.mounted) return;
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final size = await windowManager.getSize();
    final pos = await windowManager.getPosition();

    globalSettingCubit.updateWindowWidth(size.width);
    globalSettingCubit.updateWindowHeight(size.height);
    globalSettingCubit.updateWindowX(pos.dx);
    globalSettingCubit.updateWindowY(pos.dy);
  }
}
