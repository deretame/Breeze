import 'dart:async';
import 'dart:convert';

import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/jm_error_message.dart';
import 'package:zephyr/src/rust/api/js.dart' as rust_js;
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/event/event.dart';

Future<dynamic> request(
  String path, {
  String method = 'GET',
  Map<String, dynamic>? params, // URL 参数
  dynamic data,
  Map<String, dynamic>? formData,
  bool cache = false,
  bool useJwt = true,
}) async {
  try {
    final raw = await rust_js.jmRequest(
      payloadJson: jsonEncode({
        'path': path,
        'method': method,
        'params': params,
        'data': data,
        'formData': formData,
        'cache': cache,
        'useJwt': useJwt,
        'jwtToken': JmConfig.jwt,
      }),
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      decoded = raw;
    }

    if (decoded is Map) {
      final parsedMap = Map<String, dynamic>.fromEntries(
        decoded.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      );
      final code = parsedMap['code'] is num
          ? (parsedMap['code'] as num).toInt()
          : null;
      final serverMsgRaw =
          (parsedMap['errorMsg'] ?? parsedMap['msg'] ?? parsedMap['message'])
              ?.toString();
      if (code == 401 || serverMsgRaw == '請先登入會員') {
        eventBus.fire(NeedLogin(from: From.jm));
        throw Exception('登录过期，请重新登录');
      }
      return parsedMap;
    }

    return decoded;
  } catch (e, stackTrace) {
    logger.e(e, stackTrace: stackTrace);
    final message = _extractErrorMessage(e);
    if (message.contains('登录过期') || message.contains('請先登入會員')) {
      eventBus.fire(NeedLogin(from: From.jm));
    }
    throw Exception(sanitizeJmErrorMessage(message, fallback: '网络错误，请稍后再试'));
  }
}

String _extractErrorMessage(Object error) {
  final raw = error.toString().trim();
  if (raw.startsWith('Exception:')) {
    return raw.replaceFirst('Exception:', '').trim();
  }
  return raw;
}

class JmResponseParser {
  static dynamic toMap(dynamic data, {String? ts}) {
    return data;
  }
}
