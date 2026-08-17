import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:zephyr/main.dart';
import 'package:zephyr/cs/application/cs_runtime_context.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/plugin/utils/qjs_task_bytes_handle.dart';
import 'package:zephyr/service/download/download_cancel_signal.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/src/rust/qjs.dart';
import 'package:zephyr/type/pipe.dart';

final Map<String, Set<String>> _trackedRuntimesByGroup = {};
final Set<String> _runtimeInitDone = <String>{};

String runtimeNameForPluginId(String pluginIdOrLegacy) {
  return normalizePluginId(pluginIdOrLegacy);
}

String normalizePluginId(String raw) {
  var value = raw.trim();
  while (value.length >= 2 && value.startsWith('(') && value.endsWith(')')) {
    value = value.substring(1, value.length - 1).trim();
  }
  return value;
}

String _buildTaskGroupId(String pluginId, String taskGroupKey) {
  return '$pluginId::$taskGroupKey';
}

void _trackRuntime({
  required String pluginId,
  required String taskGroupKey,
  required String runtimeName,
}) {
  (_trackedRuntimesByGroup[_buildTaskGroupId(pluginId, taskGroupKey)] ??=
          <String>{})
      .add(runtimeName);
}

void _untrackRuntime({
  required String pluginId,
  required String taskGroupKey,
  required String runtimeName,
}) {
  final groupId = _buildTaskGroupId(pluginId, taskGroupKey);
  final refs = _trackedRuntimesByGroup[groupId];
  refs?.remove(runtimeName);
  if (refs != null && refs.isEmpty) {
    _trackedRuntimesByGroup.remove(groupId);
  }
}

Future<void> ensureQjsRuntimeReady({required String pluginId}) async {
  if (CsRuntimeContext.I.isCsMode) {
    return;
  }
  final normalizedPluginId = (pluginId).trim();
  final runtimeName = runtimeNameForPluginId(normalizedPluginId);
  final bundleName = runtimeName;

  try {
    Future<void> installBundle() async {
      final bundleJs = await loadQjsBundleJs(normalizedPluginId);
      await buildQjsRuntime(
        request: QjsRuntimeBuildRequest(
          runtimeName: runtimeName,
          injectFilesystem: false,
          bundle: QjsRuntimeBundleBuild(
            bundleName: bundleName,
            bundleJs: bundleJs,
          ),
        ),
      );
      _runtimeInitDone.remove(runtimeName);
    }

    final ready = await isQjsRuntimeInitialized(name: runtimeName);
    if (!ready) {
      await installBundle();
    } else {
      String? currentBundle;
      try {
        final currentBundleRaw = await qjsCurrentBundle(
          runtimeName: runtimeName,
        );
        currentBundle = jsonDecode(currentBundleRaw) as String?;
      } catch (_) {
        currentBundle = null;
      }
      if (currentBundle == null || currentBundle.trim().isEmpty) {
        await installBundle();
      }
    }
    await _runRuntimeInitIfNeeded(runtimeName);
  } catch (e) {
    logger.w('初始化 QJS 失败: $runtimeName', error: e);
    rethrow;
  }
}

Future<void> _runRuntimeInitIfNeeded(String runtimeName) async {
  if (_runtimeInitDone.contains(runtimeName)) {
    return;
  }
  try {
    wrapQjsTaskBytes(
      await qjsTaskCall(
        runtimeName: runtimeName,
        taskGroupKey: '',
        isOnce: false,
        fnPath: 'init',
        argsJson: '{}',
      ),
    ).free();
    _runtimeInitDone.add(runtimeName);
  } catch (e) {
    if (e.toString().contains('target is not function: init')) {
      _runtimeInitDone.add(runtimeName);
      return;
    }
    logger.w('插件 init 执行失败: $runtimeName', error: e);
    rethrow;
  }
}

/// 统一执行插件 JS 任务,返回原始字节。
///
/// 内部按需走常驻 bundle(非 once)或一次性 debug 池(once,`bundleUrl`/`bundleJs` 二选一),
/// 并维护取消用的 runtime 跟踪。
Future<Uint8List> _runQjsTask({
  required String pluginId,
  required String fnPath,
  required String argsJson,
  String? runtimeName,
  String? taskGroupKey,
}) async {
  if (taskGroupKey != null && taskGroupKey.isNotEmpty) {
    if (isDownloadCancelSignaled(taskGroupKey)) {
      throw const DownloadTaskCancelledException();
    }
  }

  final normalizedPluginId = (pluginId).trim();
  final resolvedRuntimeName =
      runtimeName ?? runtimeNameForPluginId(normalizedPluginId);
  final resolvedPluginId = normalizedPluginId.isNotEmpty
      ? normalizedPluginId
      : (resolvedRuntimeName).trim();
  if (resolvedPluginId.isEmpty) {
    throw StateError('pluginId/runtimeName 不能为空');
  }
  final resolvedFnPath = fnPath.trim();
  if (resolvedFnPath.isEmpty) {
    throw StateError('fnPath 不能为空: pluginId=$resolvedPluginId');
  }

  final useCallOnce = _shouldUseQjsCallOnce(resolvedPluginId);
  final debugBundleUrl = useCallOnce
      ? loadQjsDebugBundleUrl(resolvedPluginId)
      : null;
  final bundleJs = useCallOnce && debugBundleUrl == null
      ? await loadQjsBundleJs(resolvedPluginId)
      : null;

  if (!useCallOnce) {
    await ensureQjsRuntimeReady(pluginId: resolvedPluginId);
  }

  // qjsTaskCall 返回 Rust 堆缓冲句柄：这里立刻包成零拷贝视图，所有权挂在
  // 视图上（GC 回收时自动归还给 Rust），图片字节不再经 FRB 复制。
  final waitFuture = qjsTaskCall(
    runtimeName: resolvedRuntimeName,
    taskGroupKey: taskGroupKey ?? '',
    isOnce: useCallOnce,
    bundleJs: bundleJs,
    bundleUrl: debugBundleUrl,
    fnPath: resolvedFnPath,
    argsJson: argsJson,
  ).then<Uint8List>((bytes) => wrapQjsTaskBytes(bytes).bytes);

  var didUntrack = false;
  void untrackOnce() {
    if (didUntrack) return;
    didUntrack = true;
    if (taskGroupKey != null && taskGroupKey.isNotEmpty) {
      _untrackRuntime(
        pluginId: resolvedPluginId,
        taskGroupKey: taskGroupKey,
        runtimeName: resolvedRuntimeName,
      );
    }
  }

  if (taskGroupKey != null && taskGroupKey.isNotEmpty) {
    _trackRuntime(
      pluginId: resolvedPluginId,
      taskGroupKey: taskGroupKey,
      runtimeName: resolvedRuntimeName,
    );
  }

  unawaited(
    waitFuture.then<void>((_) {}).catchError((_) {}).whenComplete(untrackOnce),
  );
  // 注意：不要在 try/finally 里 return Future（会触发
  // unawaited_return_in_try_block）。untrack 已由上面的 whenComplete 在
  // future 完成时统一处理；空 taskGroupKey 时 untrackOnce 本身也是 no-op。
  return taskGroupKey != null && taskGroupKey.isNotEmpty
      ? raceWithDownloadCancel(taskGroupKey, waitFuture)
      : waitFuture;
}

/// 调用插件函数,返回 JSON 字符串。
Future<String> executeQjsCall({
  required String pluginId,
  required String fnPath,
  required String argsJson,
  String? runtimeName,
  String? taskGroupKey,
}) async {
  if (CsRuntimeContext.I.isCsMode) {
    final decoded = jsonDecode(argsJson);
    final payload = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};
    if (taskGroupKey != null && taskGroupKey.isNotEmpty) {
      payload['taskGroupKey'] = taskGroupKey;
    }
    final result = await CsRuntimeContext.I.invokePlugin(
      pluginId: pluginId,
      function: fnPath,
      payload: payload,
      taskGroupKey: taskGroupKey,
    );
    return jsonEncode(result);
  }
  final bytes = await _runQjsTask(
    pluginId: pluginId,
    fnPath: fnPath,
    argsJson: argsJson,
    runtimeName: runtimeName,
    taskGroupKey: taskGroupKey,
  );
  return utf8.decode(bytes, allowMalformed: true);
}

/// 调用插件函数,返回原始字节(如图片)。
Future<Uint8List> executeQjsFetchImageBytes({
  required String pluginId,
  required String fnPath,
  required String argsJson,
  String? runtimeName,
  String? taskGroupKey,
}) {
  if (CsRuntimeContext.I.isCsMode) {
    return CsRuntimeContext.I.invokePluginBytes(
      pluginId: pluginId,
      function: fnPath,
      argsJson: argsJson,
      taskGroupKey: taskGroupKey,
    );
  }
  return _runQjsTask(
    pluginId: pluginId,
    fnPath: fnPath,
    argsJson: argsJson,
    runtimeName: runtimeName,
    taskGroupKey: taskGroupKey,
  );
}

bool _shouldUseQjsCallOnce(String pluginId) {
  if (CsRuntimeContext.I.isCsMode) {
    return false;
  }
  // return true;
  final normalized = normalizePluginId(pluginId);
  final state = PluginRegistryService.I.getByUuid(normalized);
  return state?.debug == true;
}

String? loadQjsDebugBundleUrl(String pluginId) {
  if (CsRuntimeContext.I.isCsMode) {
    return null;
  }
  final normalizedPluginId = normalizePluginId(pluginId);
  if (normalizedPluginId.isEmpty) {
    throw StateError('pluginId 不能为空');
  }
  final runtimeState = PluginRegistryService.I.getByUuid(normalizedPluginId);
  if (runtimeState == null || runtimeState.isDeleted) {
    throw StateError('plugin_not_found:$normalizedPluginId');
  }
  if (!runtimeState.debug) {
    return null;
  }
  final bundleUrl = runtimeState.debugUrl?.trim() ?? '';
  return bundleUrl.isEmpty ? null : bundleUrl;
}

Future<void> cancelTrackedQjsTasks({
  required String pluginId,
  required String taskGroupKey,
}) async {
  if (CsRuntimeContext.I.isCsMode) {
    await CsRuntimeContext.I.cancelPluginTaskGroup(
      pluginId: pluginId,
      taskGroupKey: taskGroupKey,
    );
    return;
  }
  final normalizedPluginId = (pluginId).trim();
  final groupId = _buildTaskGroupId(normalizedPluginId, taskGroupKey);
  final runtimeNames = _trackedRuntimesByGroup.remove(groupId)?.toList() ?? [];
  if (runtimeNames.isEmpty) {
    logger.d(
      '取消 QJS 任务组: $groupId -> no_tracked_tasks, fallback_runtime_cancel',
    );
    final fallbackRuntime = runtimeNameForPluginId(normalizedPluginId);
    if (fallbackRuntime.isNotEmpty) {
      runtimeNames.add(fallbackRuntime);
    }
  }

  var cancelledCount = 0;
  var notFoundCount = 0;
  final failedTaskIds = <String>[];

  await Future.wait(
    runtimeNames.map((runtimeName) async {
      try {
        final result = await qjsCancelTasksByGroup(
          runtimeName: runtimeName,
          taskGroupKey: taskGroupKey,
        );

        if (result.cancelled == 0 &&
            result.notFound == 0 &&
            result.failedRuntimeGroups.isEmpty) {
          notFoundCount += 1;
          logger.d('取消 QJS 任务组未找到: $runtimeName/$taskGroupKey');
          return;
        }

        final cancelled = result.cancelled;
        final notFound = result.notFound;
        cancelledCount += cancelled;
        notFoundCount += notFound;

        logger.d(
          '取消 QJS 任务组结果: $runtimeName/$taskGroupKey -> cancelled=$cancelled, not_found=$notFound',
        );

        if (result.failedRuntimeGroups.isNotEmpty) {
          failedTaskIds.addAll(
            result.failedRuntimeGroups.map(
              (group) => '$runtimeName/$taskGroupKey:$group',
            ),
          );
        }
      } catch (e) {
        failedTaskIds.add('$runtimeName/$taskGroupKey:${e.toString()}');
        logger.w('取消 QJS 任务组失败: $runtimeName/$taskGroupKey', error: e);
      }
    }),
  );

  logger.d(
    '取消 QJS 任务组结果: $groupId -> cancelled=$cancelledCount, not_found=$notFoundCount, failed=${failedTaskIds.length}',
  );

  if (failedTaskIds.isNotEmpty) {
    throw Exception('取消 QJS 任务组失败: ${failedTaskIds.join('; ')}');
  }
}

Future<String> loadQjsBundleJs(String pluginId) async {
  if (CsRuntimeContext.I.isCsMode) {
    throw StateError('CS 模式下插件 bundle 由服务端管理');
  }
  final normalizedPluginId = normalizePluginId(pluginId);
  if (normalizedPluginId.isEmpty) {
    throw StateError('pluginId 不能为空');
  }
  final runtimeState = PluginRegistryService.I.getByUuid(normalizedPluginId);
  if (runtimeState == null || runtimeState.isDeleted) {
    throw StateError('plugin_not_found:$normalizedPluginId');
  }
  if (!runtimeState.debug) {
    final dbBundle = runtimeState.originScript;
    if (dbBundle.trim().isNotEmpty) {
      return dbBundle;
    }
    throw StateError('bundle_js_missing_db:$normalizedPluginId');
  }

  final bundleUrl = runtimeState.debugUrl?.trim() ?? '';
  if (bundleUrl.isEmpty) {
    final dbBundle = runtimeState.originScript;
    if (dbBundle.trim().isNotEmpty) {
      return dbBundle;
    }
    throw StateError('bundle_js_missing_db:$normalizedPluginId');
  }

  try {
    if (bundleUrl.split(".").last == "br") {
      final response = await fetchDirect(bundleUrl);
      return await decompressExtreme(data: response.body).let(utf8.decode);
    } else {
      final response = await fetchDirect(bundleUrl);
      final body = response.text;
      if (body.trim().isNotEmpty) {
        return body;
      }
    }
    logger.w('debug bundle 为空，回退数据库: $bundleUrl');
  } catch (e) {
    logger.w('debug bundle 拉取失败，回退数据库: $bundleUrl', error: e);
  }
  final dbBundle = runtimeState.originScript;
  if (dbBundle.trim().isNotEmpty) {
    return dbBundle;
  }
  throw StateError('bundle_js不能为空: $normalizedPluginId');
}
