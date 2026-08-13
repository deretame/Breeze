import 'dart:convert';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:zephyr/util/json/json_value.dart';

class UnauthorizedPayload {
  const UnauthorizedPayload({
    required this.pluginId,
    required this.message,
    this.scheme,
    this.data,
  });

  final String pluginId;
  final String message;
  final Map<String, dynamic>? scheme;
  final Map<String, dynamic>? data;
}

UnauthorizedPayload? parseUnauthorizedPayload(
  Object error, {
  required String fallbackPluginId,
}) {
  // C++ 后端（dcb）的错误是 StateError 等普通异常，不是 AnyhowException；
  // 统一取文本再匹配，两类后端都兼容。
  final text = (error is AnyhowException ? error.message : error.toString())
      .trim()
      .split('\n')
      .first;
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
      scheme: asJsonMap(parsed['scheme']),
      data: asJsonMap(parsed['data']),
    );
  } catch (_) {
    return null;
  }
}
