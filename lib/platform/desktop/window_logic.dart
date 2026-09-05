import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/platform/desktop/native_window.dart';

bool isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

enum DesktopCloseBehavior {
  ask,
  hide,
  close;

  const DesktopCloseBehavior();

  String get label {
    return switch (this) {
      DesktopCloseBehavior.ask => t.settings.desktopCloseAsk,
      DesktopCloseBehavior.hide => t.settings.desktopCloseHide,
      DesktopCloseBehavior.close => t.settings.desktopCloseClose,
    };
  }

  static DesktopCloseBehavior fromName(String? name) {
    return DesktopCloseBehavior.values.firstWhere(
      (value) => value.name == name,
      orElse: () => DesktopCloseBehavior.ask,
    );
  }
}

class WindowLogic {
  static const _windowMaximizedPrefsKey = 'desktop_window_maximized';
  static const _closeBehaviorPrefsKey = 'desktop_close_behavior';

  static const _saveDebounceDuration = Duration(milliseconds: 500);
  static Timer? _saveTimer;

  /// 初始化窗口并恢复上次的状态
  static Future<void> initWindow(BuildContext context) async {
    if (!isDesktop) {
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
    final wasMaximized = await _loadWindowMaximized();

    // 校验保存的坐标：如果窗口被最小化过，Windows 会把坐标扔到 (-16000,-16000)
    // 这种值不能直接使用，否则窗口会创建在屏幕外。
    final savedX = state.windowX;
    final savedY = state.windowY;
    final isPositionValid = await _isSavedPositionValid(
      x: savedX,
      y: savedY,
      width: width,
      height: height,
    );

    logger.d(
      'initWindow: $width x $height @ $savedX,$savedY (valid=$isPositionValid), maximized=$wasMaximized',
    );

    WindowOptions windowOptions = WindowOptions(
      size: Size(width, height),
      center: !isPositionValid,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    // 等待窗口准备好再显示
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      // 先设置位置（窗口此时还不可见），再 show，避免闪烁跳动
      if (isPositionValid) {
        await windowManager.setPosition(Offset(savedX, savedY));
      }
      if (wasMaximized) {
        await windowManager.maximize();
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
  static void saveWindowState(BuildContext context) {
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounceDuration, () {
      _saveTimer = null;
      unawaited(_saveWindowState(context));
    });
  }

  /// 退出或隐藏前立即保存一次，避免节流漏掉最后一次最大化状态变化。
  static Future<void> saveWindowStateImmediately(BuildContext context) async {
    _saveTimer?.cancel();
    _saveTimer = null;
    await _saveWindowState(context);
  }

  static Future<void> _saveWindowState(BuildContext context) async {
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return;
    }

    if (!context.mounted) return;
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    // 窗口最小化时，Windows、macOS 和 Linux 可能会返回虚拟的屏幕外坐标。
    // 直接跳过保存，保留最近一次正常窗口状态，避免下次启动窗口跑到屏幕外。
    if (await windowManager.isMinimized()) return;

    final maximized = await windowManager.isMaximized();
    await _saveWindowMaximized(maximized);
    final current = globalSettingCubit.state;
    final size = maximized
        ? Size(current.windowWidth, current.windowHeight)
        : await windowManager.getSize();
    final pos = maximized
        ? Offset(current.windowX, current.windowY)
        : await windowManager.getPosition();

    globalSettingCubit.updateState(
      (current) => current.copyWith(
        windowWidth: size.width,
        windowHeight: size.height,
        windowX: pos.dx,
        windowY: pos.dy,
      ),
    );
  }

  /// 判断保存的窗口中心是否仍在可见屏幕区域内。
  ///
  /// 坐标超出范围或窗口已完全离开屏幕时，启动时应重新居中，避免窗口无法找回。
  static Future<bool> _isSavedPositionValid({
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    if (!x.isFinite ||
        !y.isFinite ||
        !width.isFinite ||
        !height.isFinite ||
        width <= 0 ||
        height <= 0 ||
        x == 0 ||
        y == 0) {
      return false;
    }

    try {
      final windowRect = Rect.fromLTWH(x, y, width, height);
      final displays = await screenRetriever.getAllDisplays();
      return displays.any((display) {
        final visiblePosition = display.visiblePosition;
        final visibleSize = display.visibleSize ?? display.size;
        if (visiblePosition == null ||
            visibleSize.width <= 0 ||
            visibleSize.height <= 0) {
          return false;
        }
        final visibleRect = Rect.fromLTWH(
          visiblePosition.dx,
          visiblePosition.dy,
          visibleSize.width,
          visibleSize.height,
        );
        return visibleRect.contains(windowRect.center);
      });
    } catch (error, stackTrace) {
      logger.w('检查保存的窗口位置失败，将在启动时居中: $error', stackTrace: stackTrace);
      return false;
    }
  }

  static Future<bool> _loadWindowMaximized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_windowMaximizedPrefsKey) ?? false;
  }

  static Future<void> _saveWindowMaximized(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_windowMaximizedPrefsKey, value);
  }

  static Future<DesktopCloseBehavior> loadCloseBehavior() async {
    final prefs = await SharedPreferences.getInstance();
    return DesktopCloseBehavior.fromName(
      prefs.getString(_closeBehaviorPrefsKey),
    );
  }

  static Future<void> saveCloseBehavior(DesktopCloseBehavior value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_closeBehaviorPrefsKey, value.name);
  }
}
