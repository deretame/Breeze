import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/src/rust/api/qjs.dart' as rust_qjs;
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/direct_dio.dart';
import 'package:zephyr/util/event/event.dart';
import 'package:zephyr/util/sundry.dart';

Future<Map<String, dynamic>> request(
  String url,
  String method, {
  dynamic body,
  bool cache = false,
  String? imageQuality,
  String? authorization,
}) async {
  try {
    final settings = objectbox.userSettingBox.get(1)!.bikaSetting;
    final js = await directDio.get(
      "http://127.0.0.1:7879/bikaComic.bundle.cjs",
    );
    final raw = await rust_qjs.qjsCallOnce(
      runtimeName: "bikaComic",
      bundleJs: js.data,
      fnPath: 'bikaRequest',
      argsJson: {
        'url': url,
        'method': method,
        'body': body,
        'cache': cache,
        'imageQuality': imageQuality,
        'authorization': authorization,
        'settings': {
          'proxy': settings.proxy,
          'imageQuality': settings.imageQuality,
          'authorization': settings.authorization,
        },
      }.toJson(),
    );

    final decoded = jsonDecode(raw);
    final data = _toStringKeyMap(decoded);

    if (data['code'] == 401 && data['message'] == 'unauthorized') {
      eventBus.fire(NeedLogin(from: From.bika));
    }

    return data;
  } catch (e, stackTrace) {
    logger.e(e, stackTrace: stackTrace);

    final message = _normalizeErrorMessage(e);
    if (message.contains('__NEED_LOGIN__') ||
        message.contains('unauthorized')) {
      eventBus.fire(NeedLogin(from: From.bika));
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
