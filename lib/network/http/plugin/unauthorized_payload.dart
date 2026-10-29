import 'dart:convert';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:zephyr/util/json/json_value.dart';

// need-login 错误只携带插件身份与提示文案。
// 旧插件可能在错误里附带 scheme/data，解析时直接忽略：
// 登录页统一跳转后再调 getLoginBundle 现取表单。
class UnauthorizedPayload {
  const UnauthorizedPayload({required this.pluginId, required this.message});

  final String pluginId;
  final String message;
}

/// suppressNeedLoginEvent 为 true 时抛出的结构化登录错误。
///
/// 调用方用 `is` 判断即可，无需二次解析；文案直接透传。
class PluginUnauthorizedException implements Exception {
  const PluginUnauthorizedException({
    required this.pluginId,
    required this.message,
  });

  final String pluginId;
  final String message;

  @override
  String toString() => message;
}

/// 插件调用抛出的原始错误文本。
///
/// QJS/Rust 抛回的一定是 [AnyhowException]，取其 `message` 原文；
/// 其他 Dart 异常（如 FormatException）返回 null，调用方走普通失败。
/// 登录解析（[parseUnauthorizedPayload]）永远走原文，
/// 不受展示层精简开关影响。
String? extractPluginErrorRawText(Object error) {
  if (error is! AnyhowException) {
    return null;
  }
  return error.message;
}

UnauthorizedPayload? parseUnauthorizedPayload(
  Object error, {
  required String fallbackPluginId,
}) {
  // 登录识别永远走原文：release + 配了日志转发时展示层会精简堆栈，
  // 但这里必须用完整原文做 JSON 匹配，否则 need-login 会被吞掉。
  final raw = extractPluginErrorRawText(error);
  if (raw == null) {
    return null;
  }
  // cubit 侧只认 PluginUnauthorizedException，不再调本函数。
  final text = raw.trim().split('\n').first;
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
