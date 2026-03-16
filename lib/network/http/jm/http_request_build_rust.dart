import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/network/http/jm/jm_error_message.dart';
import 'package:zephyr/src/rust/api/qjs.dart' as rust_qjs;
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/direct_dio.dart';
import 'package:zephyr/util/event/event.dart';

const _kQjsRuntimeCancelled = '__QJS_RUNTIME_CANCELLED__';
const _kDownloadTaskCancelled = '__DOWNLOAD_TASK_CANCELLED__';

Future<dynamic> request(
  String path, {
  String method = 'GET',
  Map<String, dynamic>? params, // URL 参数
  dynamic data,
  Map<String, dynamic>? formData,
  bool cache = false,
  bool useJwt = true,
  String qjsName = "jmComic",
}) async {
  try {
    final args = {
      'path': path,
      'method': method,
      'params': params,
      'data': data,
      'formData': formData,
      'cache': cache,
      'useJwt': useJwt,
      'jwtToken': JmConfig.jwt,
    }.let(jsonEncode);

    var raw = "";
    if (kDebugMode) {
      final js = await directDio.get(await jmJsUrl);
      raw = await rust_qjs.qjsCallOnce(
        runtimeName: qjsName,
        bundleJs: js.data,
        fnPath: "jmRequest",
        argsJson: args,
      );
    } else {
      raw = await rust_qjs.qjsCall(
        runtimeName: qjsName,
        fnPath: "jmRequest",
        argsJson: args,
      );
    }

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
    if (_isQjsRuntimeCancelled(message)) {
      throw Exception(_kDownloadTaskCancelled);
    }
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

bool _isQjsRuntimeCancelled(String message) {
  return message.contains(_kQjsRuntimeCancelled);
}

class JmResponseParser {
  static dynamic toMap(dynamic data, {String? ts}) {
    return data;
  }
}
