import 'dart:convert';

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
  final text = error.toString().trim();
  final jsonText = _firstJsonObject(text);
  if (jsonText == null) {
    return null;
  }
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

String? _firstJsonObject(String text) {
  var value = text;
  if (value.startsWith('Exception:')) {
    value = value.replaceFirst('Exception:', '').trim();
  }
  if (value.startsWith('Error:')) {
    value = value.replaceFirst('Error:', '').trim();
  }

  final start = value.indexOf('{');
  final end = value.lastIndexOf('}');
  if (start < 0 || end <= start) {
    return null;
  }
  return value.substring(start, end + 1);
}
