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
      scheme: asJsonMap(parsed['scheme']),
      data: asJsonMap(parsed['data']),
    );
  } catch (_) {
    return null;
  }
}
