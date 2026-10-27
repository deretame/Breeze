import 'dart:io';

import 'package:flutter/services.dart';
import 'package:zephyr/main.dart';

class MacOSActivity {
  static const _channel = MethodChannel('com.breeze.macos/activity');

  static Future<void> start() async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('startActivity');
    } catch (e) {
      logger.e(e);
      // ignore
    }
  }

  static Future<void> stop() async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('stopActivity');
    } catch (e) {
      logger.e(e);
      // ignore
    }
  }
}
