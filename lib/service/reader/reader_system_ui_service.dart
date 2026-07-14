import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 阅读器系统 UI（状态栏/导航栏）服务。
///
/// 封装 `SystemChrome` 与 Android 原生 `MethodChannel('system_ui_control')`，
/// 使 controller 层不再直接操作平台 UI。
class ReaderSystemUiService {
  static final ReaderSystemUiService instance = ReaderSystemUiService._();
  ReaderSystemUiService._();

  static const _systemUiChannel = MethodChannel('system_ui_control');

  Timer? _syncTimer;
  bool? _lastMenuVisible;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  /// 延迟同步系统栏显隐。
  void scheduleSync(
    void Function() syncFn, {
    Duration delay = const Duration(milliseconds: 24),
  }) {
    _syncTimer?.cancel();
    _syncTimer = Timer(delay, syncFn);
  }

  /// 应用与菜单状态对应的系统栏显隐。
  Future<void> applyVisibility(bool isMenuVisible, {bool force = false}) async {
    if (!force && _lastMenuVisible == isMenuVisible) return;
    _lastMenuVisible = isMenuVisible;

    if (isMenuVisible) {
      await _showSystemBars();
    } else {
      await _hideSystemBars();
    }
  }

  /// 退出阅读页时恢复系统栏，避免影响其他页面。
  Future<void> restoreSystemBars() async => _showSystemBars();

  void dispose() => _syncTimer?.cancel();

  Future<void> _showSystemBars() async {
    if (_isAndroid) {
      await _systemUiChannel.invokeMethod('showSystemBars');
      return;
    }
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
  }

  Future<void> _hideSystemBars() async {
    if (_isAndroid) {
      await _systemUiChannel.invokeMethod('hideSystemBars');
      return;
    }
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }
}
