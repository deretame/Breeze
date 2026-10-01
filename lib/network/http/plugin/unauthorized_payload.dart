import 'dart:convert';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:zephyr/util/json/json_value.dart';

// need-login 错误只携带插件身份与提示文案。
// 旧插件可能在错误里附带 scheme/data，解析时直接忽略：
// 登录页统一跳转后再调 getLoginBundle 现取表单。
class UnauthorizedPayload {
  const UnauthorizedPayload({required this.pluginId, required this.message});

  final String pluginId;
  final String message;
}

UnauthorizedPayload? parseUnauthorizedPayload(
  Object error, {
  required String fallbackPluginId,
}) {
  final text = (error as AnyhowException).message.trim().split('\n').first;
  final regExp = RegExp(
    r'(?:bundle:.*?cjs\]|source:.*?cjs\])\s*(\{.*\})',
    dotAll: true,
  );
  final match = regExp.firstMatch(text);
  final jsonText = match != null ? match.group(1)! : text;
  try {
    final parsed = requireJsonMap(jsonDecode(jsonText));
    if (parsed['type']?.toString() != 'unauthorized') {
      return null;
    }
    final pluginId = parsed['source']?.toString().trim();
    return UnauthorizedPayload(
      pluginId: pluginId?.isNotEmpty == true ? pluginId! : fallbackPluginId,
      message: parsed['message']?.toString().trim().isNotEmpty == true
          ? parsed['message'].toString().trim()
          : '登录过期，请重新登录',
    );
  } catch (_) {
    return null;
  }
}
