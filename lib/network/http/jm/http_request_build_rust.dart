import 'dart:async';
import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/jm_error_message.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/download/qjs_download_runtime.dart';
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
  String qjsTaskGroupKey = '',
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
    }.let(jsonEncode);

    final raw = await executeQjsCall(
      source: 'jm',
      runtimeName: qjsName,
      fnPath: 'jmRequest',
      argsJson: args,
      taskGroupKey: qjsTaskGroupKey.isEmpty ? null : qjsTaskGroupKey,
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
