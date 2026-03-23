import 'dart:convert';

import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/download/qjs_download_runtime.dart';
import 'package:zephyr/util/json/json_value.dart';

String _defaultRuntimeName(From from) =>
    from == From.bika ? 'bikaComic' : 'jmComic';

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
  return requireJsonMap(decoded, message: '插件返回格式错误');
}

Future<String> _invokeQjs({
  required From from,
  required String runtimeName,
  required String fnPath,
  required String argsJson,
}) async {
  return executeQjsCall(
    source: from == From.bika ? 'bika' : 'jm',
    runtimeName: runtimeName,
    fnPath: fnPath,
    argsJson: argsJson,
  );
}
