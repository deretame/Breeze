import 'dart:async';
import 'dart:io';

import 'package:zephyr/util/volume_key_handler.dart';

/// 阅读器音量键服务。
///
/// 封装 Android 音量键拦截的 `MethodChannel` / `EventChannel`，
/// 提供事件流与引用计数式的启用/禁用接口。
class ReaderVolumeService {
  static final ReaderVolumeService instance = ReaderVolumeService._();
  ReaderVolumeService._();

  Stream<String>? _volumeKeyStream;
  int _interceptionCount = 0;

  /// 音量键事件流，值为 `'volume_up'` 或 `'volume_down'`。
  Stream<String> get volumeEvents {
    _volumeKeyStream ??= VolumeKeyHandler.volumeKeyEvents;
    return _volumeKeyStream!;
  }

  /// 启用音量键拦截（引用计数，可安全重复调用）。
  void enableInterception() {
    if (!Platform.isAndroid) return;
    if (_interceptionCount == 0) {
      VolumeKeyHandler.enableVolumeKeyInterception();
    }
    _interceptionCount++;
  }

  /// 禁用音量键拦截（引用计数归零后才真正禁用）。
  void disableInterception() {
    if (!Platform.isAndroid) return;
    if (_interceptionCount > 0) {
      _interceptionCount--;
      if (_interceptionCount == 0) {
        VolumeKeyHandler.disableVolumeKeyInterception();
      }
    }
  }

  /// 强制禁用并清理引用计数，通常在页面 dispose 时调用。
  void dispose() {
    if (!Platform.isAndroid) return;
    _interceptionCount = 0;
    VolumeKeyHandler.disableVolumeKeyInterception();
  }
}
