import 'dart:io';

import 'package:flutter/services.dart';

class MacOSActivity {
  static const _channel = MethodChannel('com.breeze.macos/activity');

  static Future<void> start() async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('startActivity');
    } catch (e) {
      // ignore
    }
  }

  static Future<void> stop() async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('stopActivity');
    } catch (e) {
      // ignore
    }
  }
}
