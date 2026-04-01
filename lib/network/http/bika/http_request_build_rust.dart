import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unauthorized_payload.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/download/qjs_download_runtime.dart';
import 'package:zephyr/util/event/event.dart';

const _kQjsRuntimeCancelled = '__QJS_RUNTIME_CANCELLED__';
const _kDownloadTaskCancelled = '__DOWNLOAD_TASK_CANCELLED__';

Future<Map<String, dynamic>> request(
  String url,
  String method, {
  dynamic body,
  bool cache = false,
  String? imageQuality,
  String qjsName = kBikaPluginUuid,
  String qjsTaskGroupKey = '',
}) async {
  try {
    final settings = objectbox.userSettingBox.get(1)!.bikaSetting;
    final args = {
      'url': url,
      'method': method,
      'body': body,
      'cache': cache,
      'imageQuality': imageQuality,
      'authorization': settings.authorization,
      'settings': {
        'proxy': settings.proxy,
        'imageQuality': settings.imageQuality,
        'authorization': settings.authorization,
      },
    }.let(jsonEncode);

    final raw = await executeQjsCall(
      pluginId: kBikaPluginUuid,
      runtimeName: qjsName,
      fnPath: 'bikaRequest',
      argsJson: args,
      taskGroupKey: qjsTaskGroupKey.isEmpty ? null : qjsTaskGroupKey,
    );

    final decoded = jsonDecode(raw);
    final data = _toStringKeyMap(decoded);

    if (data['code'] == 401 && data['message'] == 'unauthorized') {
      eventBus.fire(NeedLogin(from: kBikaPluginUuid));
    }

    return data;
  } catch (e, stackTrace) {
    logger.e(e, stackTrace: stackTrace);

    final message = _normalizeErrorMessage(e);
    if (_isQjsRuntimeCancelled(message)) {
      throw Exception(_kDownloadTaskCancelled);
    }
    final unauthorized = parseUnauthorizedPayload(
      e,
      fallbackPluginId: kBikaPluginUuid,
    );
    if (unauthorized != null) {
      eventBus.fire(
        NeedLogin(
          from: unauthorized.pluginId,
          scheme: unauthorized.scheme,
          data: unauthorized.data,
          message: unauthorized.message,
        ),
      );
      throw Exception(unauthorized.message);
    }

    if (message.contains('__NEED_LOGIN__') ||
        message.contains('unauthorized')) {
      eventBus.fire(NeedLogin(from: kBikaPluginUuid));
    }

    throw Exception(message);
  }
}

Map<String, dynamic> _toStringKeyMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map((entry) {
        return MapEntry(entry.key.toString(), entry.value);
      }),
    );
  }

  throw Exception('Bika JS 请求返回格式错误: ${value.runtimeType}');
}

String _normalizeErrorMessage(Object error) {
  var text = error.toString().trim();

  if (text.startsWith('Exception:')) {
    text = text.replaceFirst('Exception:', '').trim();
  }

  final line = text
      .split('\n')
      .firstWhere(
        (part) => part.trim().isNotEmpty && !part.trim().startsWith('at '),
        orElse: () => text,
      );

  return line.replaceAll('__NEED_LOGIN__:', '').trim();
}

bool _isQjsRuntimeCancelled(String message) {
  return message.contains(_kQjsRuntimeCancelled);
}
