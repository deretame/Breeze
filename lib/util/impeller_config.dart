import 'dart:io';

import 'package:flutter/services.dart';
import 'package:zephyr/main.dart';

class ImpellerConfig {
  static const MethodChannel _channel = MethodChannel('impeller_config');

  static Future<bool> isForceEnableSupported() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'isImpellerForceEnableSupported',
      );
      return result ?? false;
    } catch (e) {
      logger.e('获取 Impeller 强制开关支持状态失败: $e');
      return false;
    }
  }

  static Future<void> setForceEnableImpeller(bool enable) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('setForceEnableImpeller', {'enable': enable});
    } catch (e) {
      logger.e('更新 Impeller 强制开关失败: $e');
    }
  }

  static Future<bool> getForceEnableImpeller() async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'getForceEnableImpeller',
      );
      return result ?? false;
    } catch (e) {
      logger.e('获取 Impeller 强制开关值失败: $e');
      return false;
    }
  }
}
