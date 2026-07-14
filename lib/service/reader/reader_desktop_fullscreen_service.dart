import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

/// 阅读器桌面端全屏服务。
///
/// 封装 `window_manager` 的全屏操作与全局全屏状态通知，
/// 使 controller 层不再直接调用窗口管理 API。
class ReaderDesktopFullscreenService {
  static final ReaderDesktopFullscreenService instance =
      ReaderDesktopFullscreenService._();
  ReaderDesktopFullscreenService._();

  final ValueNotifier<bool> fullscreenNotifier = ValueNotifier(false);

  bool get _isDesktopPlatform =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  /// 查询当前窗口是否处于全屏状态。
  Future<bool> isFullscreen() async {
    if (!_isDesktopPlatform) return false;
    return windowManager.isFullScreen();
  }

  /// 设置窗口全屏状态，并同步全局通知。
  Future<void> setFullscreen(bool value) async {
    if (!_isDesktopPlatform) return;
    await windowManager.setFullScreen(value);
    _setFullscreen(value);
  }

  /// 仅同步全局通知状态，不调用窗口 API（用于初始化时与窗口实际状态对齐）。
  void syncFullscreen(bool value) => _setFullscreen(value);

  void _setFullscreen(bool value) {
    if (fullscreenNotifier.value == value) return;
    fullscreenNotifier.value = value;
  }
}
