import 'package:flutter/services.dart';
import 'package:zephyr/main.dart';

class VolumeKeyHandler {
  static const MethodChannel _channel = MethodChannel('volume_key_handler');
  static const EventChannel _eventChannel = EventChannel('volume_key_events');

  static Stream<String>? _volumeKeyStream;

  /// 启用音量键拦截
  static Future<void> enableVolumeKeyInterception() async {
    try {
      await _channel.invokeMethod('enableInterception');
    } catch (e) {
      logger.e('启用音量键拦截失败: $e');
    }
  }

  /// 禁用音量键拦截
  static Future<void> disableVolumeKeyInterception() async {
    try {
      await _channel.invokeMethod('disableInterception');
    } catch (e) {
      logger.e('禁用音量键拦截失败: $e');
    }
  }

  /// 监听音量键事件
  /// 返回 'volume_up' 或 'volume_down'
  static Stream<String> get volumeKeyEvents {
    _volumeKeyStream ??= _eventChannel.receiveBroadcastStream().map(
      (event) => event.toString(),
    );
    return _volumeKeyStream!;
  }
}
