import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:zephyr/network/http/bika/http_request.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/direct_dio.dart';

String _defaultRuntimeName(From from) => from == From.bika ? 'bikaComic' : 'jmComic';

Future<Map<String, dynamic>> callUnifiedComicPlugin({
  required From from,
  required String fnPath,
  required Map<String, dynamic> core,
  Map<String, dynamic>? extern,
  String? runtimeName,
}) async {
  final payload = <String, dynamic>{...core, 'extern': extern ?? const {}};
  final argsJson = jsonEncode(payload);
  final runtime = runtimeName ?? _defaultRuntimeName(from);

  final raw = await _invokeQjs(
    from: from,
    runtimeName: runtime,
    fnPath: fnPath,
    argsJson: argsJson,
  );
  final decoded = jsonDecode(raw);
  return _asMap(decoded);
}

Future<String> _invokeQjs({
  required From from,
  required String runtimeName,
  required String fnPath,
  required String argsJson,
}) async {
  if (kDebugMode) {
    final bundleUrl = from == From.bika ? await bikaJsUrl : await jmJsUrl;
    final bundleJs = (await directDio.get(bundleUrl)).data;
    return qjsCallOnce(
      runtimeName: runtimeName,
      bundleJs: bundleJs,
      fnPath: fnPath,
      argsJson: argsJson,
    );
  }

  return qjsCall(runtimeName: runtimeName, fnPath: fnPath, argsJson: argsJson);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map((entry) => MapEntry(entry.key.toString(), entry.value)),
    );
  }
  throw Exception('插件返回格式错误: ${value.runtimeType}');
}
