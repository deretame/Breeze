import 'dart:convert';
import 'dart:typed_data';

import 'package:cbor/cbor.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:zephyr/src/rust/api/qjs.dart' as rust_qjs;

const int _protocolVersion = 1;

const CborSimpleCodec _codec = CborSimpleCodec(
  parseDateTime: false,
  parseUri: false,
  decodeBase64: false,
);

class QjsCancelTasksByGroupResult {
  final int cancelled;
  final int notFound;
  final List<String> failedRuntimeGroups;

  const QjsCancelTasksByGroupResult({
    required this.cancelled,
    required this.notFound,
    required this.failedRuntimeGroups,
  });
}

class QjsRuntimeBuildRequest {
  final String runtimeName;
  final bool injectFilesystem;
  final QjsRuntimeBundleBuild? bundle;

  const QjsRuntimeBuildRequest({
    required this.runtimeName,
    required this.injectFilesystem,
    this.bundle,
  });
}

class QjsRuntimeBundleBuild {
  final String bundleName;
  final String bundleJs;

  const QjsRuntimeBundleBuild({
    required this.bundleName,
    required this.bundleJs,
  });
}

Future<Object?> _call(Map<String, dynamic> request) async {
  final responseBytes = await rust_qjs.pluginGatewayCall(
    request: _codec.encode(request),
  );
  final decoded = _codec.decode(responseBytes);
  if (decoded is! Map) {
    throw StateError('插件网关返回格式错误: response 不是 map');
  }
  if (decoded['version'] != _protocolVersion) {
    throw StateError('插件网关返回了不支持的协议版本');
  }

  if (decoded['ok'] != true) {
    throw AnyhowException(decoded['error']?.toString() ?? '插件网关调用失败');
  }
  return decoded['value'];
}

Map<String, dynamic> _request(String operation) => <String, dynamic>{
  'version': _protocolVersion,
  'op': operation,
};

Future<Uint8List> qjsTaskCall({
  required String runtimeName,
  required String taskGroupKey,
  required bool isOnce,
  String? bundleJs,
  String? bundleUrl,
  required String fnPath,
  required String argsJson,
}) async {
  final request = _request('task_call')
    ..addAll({
      'runtimeName': runtimeName,
      'taskGroupKey': taskGroupKey,
      'isOnce': isOnce,
      'bundleJs': bundleJs,
      'bundleUrl': bundleUrl,
      'fnPath': fnPath,
      'args': jsonDecode(argsJson),
    });
  final value = await _call(request);
  if (value is! List) {
    throw StateError('插件网关 task_call 返回值不是 bytes');
  }
  return Uint8List.fromList(value.cast<int>());
}

Future<void> buildQjsRuntime({required QjsRuntimeBuildRequest request}) async {
  final encodedBundle = request.bundle == null
      ? null
      : <String, dynamic>{
          'bundleName': request.bundle!.bundleName,
          'bundleJs': request.bundle!.bundleJs,
        };
  final payload = _request('build_runtime')
    ..addAll({
      'runtimeName': request.runtimeName,
      'injectFilesystem': request.injectFilesystem,
      'bundle': encodedBundle,
    });
  await _call(payload);
}

Future<bool> isQjsRuntimeInitialized({required String name}) async {
  final request = _request('is_runtime_initialized')..['name'] = name;
  final value = await _call(request);
  if (value is! bool) {
    throw StateError('插件网关 is_runtime_initialized 返回值不是 bool');
  }
  return value;
}

Future<String> qjsCurrentBundle({required String runtimeName}) async {
  final request = _request('current_bundle')..['runtimeName'] = runtimeName;
  final value = await _call(request);
  if (value is! String) {
    throw StateError('插件网关 current_bundle 返回值不是 text');
  }
  return value;
}

Future<bool> qjsDropRuntime({required String runtimeName}) async {
  final request = _request('drop_runtime')..['runtimeName'] = runtimeName;
  final value = await _call(request);
  if (value is! bool) {
    throw StateError('插件网关 drop_runtime 返回值不是 bool');
  }
  return value;
}

Future<bool> qjsClearBundle({required String runtimeName}) async {
  final request = _request('clear_bundle')..['runtimeName'] = runtimeName;
  final value = await _call(request);
  if (value is! bool) {
    throw StateError('插件网关 clear_bundle 返回值不是 bool');
  }
  return value;
}

Future<void> qjsReplaceBundle({
  required String runtimeName,
  required String bundleName,
  required String bundleJs,
}) async {
  final request = _request('replace_bundle')
    ..addAll({
      'runtimeName': runtimeName,
      'bundleName': bundleName,
      'bundleJs': bundleJs,
    });
  await _call(request);
}

Future<QjsCancelTasksByGroupResult> qjsCancelTasksByGroup({
  required String runtimeName,
  required String taskGroupKey,
}) async {
  final request = _request('cancel_tasks')
    ..addAll({'runtimeName': runtimeName, 'taskGroupKey': taskGroupKey});
  final value = await _call(request);
  if (value is! Map) {
    throw StateError('插件网关 cancel_tasks 返回值不是 map');
  }
  return QjsCancelTasksByGroupResult(
    cancelled: (value['cancelled'] as num?)?.toInt() ?? 0,
    notFound: (value['notFound'] as num?)?.toInt() ?? 0,
    failedRuntimeGroups: (value['failedRuntimeGroups'] as List? ?? const [])
        .map((item) => item.toString())
        .toList(),
  );
}

Future<String> qjsDebugSnapshot({required String runtimeName}) async {
  final request = _request('debug_snapshot')..['runtimeName'] = runtimeName;
  final value = await _call(request);
  if (value is! String) {
    throw StateError('插件网关 debug_snapshot 返回值不是 text');
  }
  return value;
}
