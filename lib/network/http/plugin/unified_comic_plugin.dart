import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unauthorized_payload.dart';
import 'package:zephyr/network/http/plugin/qjs_download_runtime.dart';
import 'package:zephyr/util/event/event.dart';
import 'package:zephyr/util/json/json_value.dart';

Future<Map<String, dynamic>> callUnifiedComicPlugin({
  String? from,
  String? pluginId,
  required String fnPath,
  required Map<String, dynamic> core,
  Map<String, dynamic>? extern,
  String? runtimeName,
}) async {
  final resolvedFnPath = fnPath.trim();
  if (resolvedFnPath.isEmpty) {
    throw StateError('callUnifiedComicPlugin missing fnPath');
  }

  final resolvedPluginId = normalizePluginId(
    (pluginId?.trim().isNotEmpty ?? false) ? pluginId! : (from ?? ''),
  );
  if (resolvedPluginId.isEmpty) {
    throw StateError('callUnifiedComicPlugin missing valid plugin identity');
  }

  final payload = <String, dynamic>{...core, 'extern': extern ?? const {}};
  final argsJson = jsonEncode(payload);
  final runtime = runtimeName ?? resolvedPluginId;
  try {
    final raw = await _invokeQjs(
      pluginId: resolvedPluginId,
      runtimeName: runtime,
      fnPath: resolvedFnPath,
      argsJson: argsJson,
    );
    final decoded = requireJsonMap(jsonDecode(raw), message: '插件返回格式错误');
    return _normalizePluginSourceFields(decoded, resolvedPluginId);
  } catch (error) {
    final unauthorized = parseUnauthorizedPayload(
      error,
      fallbackPluginId: resolvedPluginId,
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
    rethrow;
  }
}

Future<String> _invokeQjs({
  required String pluginId,
  required String runtimeName,
  required String fnPath,
  required String argsJson,
}) async {
  return executeQjsCall(
    pluginId: pluginId,
    runtimeName: runtimeName,
    fnPath: fnPath,
    argsJson: argsJson,
  );
}

Map<String, dynamic> _normalizePluginSourceFields(
  Map<String, dynamic> input,
  String pluginId,
) {
  dynamic walk(dynamic node) {
    if (node is Map) {
      final map = Map<String, dynamic>.from(node);
      if (map.containsKey('source')) {
        map['source'] = pluginId;
      }
      for (final entry in map.entries.toList()) {
        map[entry.key] = walk(entry.value);
      }
      return map;
    }
    if (node is List) {
      return node.map(walk).toList();
    }
    return node;
  }

  return walk(input) as Map<String, dynamic>;
}
