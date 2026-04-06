import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/util/download/download_cancel_signal.dart';
import 'package:zephyr/util/direct_dio.dart';

class _TrackedQjsTaskRef extends Equatable {
  const _TrackedQjsTaskRef({required this.runtimeName, required this.taskId});

  final String runtimeName;
  final BigInt taskId;

  @override
  List<Object?> get props => [runtimeName, taskId];
}

final Map<String, Set<_TrackedQjsTaskRef>> _trackedTaskRefsByGroup = {};
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

void _trackTaskRef({
  required String pluginId,
  required String taskGroupKey,
  required _TrackedQjsTaskRef taskRef,
}) {
  (_trackedTaskRefsByGroup[_buildTaskGroupId(pluginId, taskGroupKey)] ??=
          <_TrackedQjsTaskRef>{})
      .add(taskRef);
}

void _untrackTaskRef({
  required String pluginId,
  required String taskGroupKey,
  required _TrackedQjsTaskRef taskRef,
}) {
  final groupId = _buildTaskGroupId(pluginId, taskGroupKey);
  final refs = _trackedTaskRefsByGroup[groupId];
  refs?.remove(taskRef);
  if (refs != null && refs.isEmpty) {
    _trackedTaskRefsByGroup.remove(groupId);
  }
}

Future<void> ensureQjsRuntimeReady({required String pluginId}) async {
  final normalizedPluginId = (pluginId).trim();
  final runtimeName = runtimeNameForPluginId(normalizedPluginId);
  final bundleName = runtimeName;

  try {
    final ready = await isQjsRuntimeInitialized(name: runtimeName);
    if (!ready) {
      final bundleJs = await loadQjsBundleJs(normalizedPluginId);
      await initQjsRuntimeWithBundle(
        runtimeName: runtimeName,
        bundleName: bundleName,
        bundleJs: bundleJs,
      );
      _runtimeInitDone.remove(runtimeName);
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
    await qjsCall(runtimeName: runtimeName, fnPath: 'init', argsJson: '{}');
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

Future<String> executeQjsCall({
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
  final bundleJs = useCallOnce ? await loadQjsBundleJs(resolvedPluginId) : null;

  final taskId = useCallOnce
      ? await qjsCallOnceTaskStart(
          runtimeName: resolvedRuntimeName,
          bundleJs: bundleJs!,
          fnPath: resolvedFnPath,
          argsJson: argsJson,
          taskGroupKey: taskGroupKey ?? '',
        )
      : await () async {
          await ensureQjsRuntimeReady(pluginId: resolvedPluginId);
          return qjsCallTaskStart(
            runtimeName: resolvedRuntimeName,
            taskGroupKey: taskGroupKey ?? '',
            fnPath: resolvedFnPath,
            argsJson: argsJson,
          );
        }();

  final taskRef = _TrackedQjsTaskRef(
    runtimeName: resolvedRuntimeName,
    taskId: taskId,
  );
  if (taskGroupKey != null && taskGroupKey.isNotEmpty) {
    _trackTaskRef(
      pluginId: resolvedPluginId,
      taskGroupKey: taskGroupKey,
      taskRef: taskRef,
    );
  }

  try {
    final waitFuture = useCallOnce
        ? qjsCallOnceTaskWait(runtimeName: resolvedRuntimeName, taskId: taskId)
        : qjsCallTaskWait(runtimeName: resolvedRuntimeName, taskId: taskId);
    return taskGroupKey != null && taskGroupKey.isNotEmpty
        ? raceWithDownloadCancel(taskGroupKey, waitFuture)
        : waitFuture;
  } finally {
    if (taskGroupKey != null && taskGroupKey.isNotEmpty) {
      _untrackTaskRef(
        pluginId: resolvedPluginId,
        taskGroupKey: taskGroupKey,
        taskRef: taskRef,
      );
    }
  }
}

Future<Uint8List> executeQjsFetchImageBytes({
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
  final bundleJs = useCallOnce ? await loadQjsBundleJs(resolvedPluginId) : null;

  final taskId = useCallOnce
      ? await qjsFetchImageBytesOnceTaskStart(
          runtimeName: resolvedRuntimeName,
          bundleJs: bundleJs!,
          fnPath: resolvedFnPath,
          argsJson: argsJson,
          taskGroupKey: taskGroupKey ?? '',
        )
      : await () async {
          await ensureQjsRuntimeReady(pluginId: resolvedPluginId);
          return qjsFetchImageBytesTaskStart(
            runtimeName: resolvedRuntimeName,
            taskGroupKey: taskGroupKey ?? '',
            fnPath: resolvedFnPath,
            argsJson: argsJson,
          );
        }();

  final taskRef = _TrackedQjsTaskRef(
    runtimeName: resolvedRuntimeName,
    taskId: taskId,
  );
  if (taskGroupKey != null && taskGroupKey.isNotEmpty) {
    _trackTaskRef(
      pluginId: resolvedPluginId,
      taskGroupKey: taskGroupKey,
      taskRef: taskRef,
    );
  }

  try {
    final waitFuture = useCallOnce
        ? qjsFetchImageBytesOnceTaskWait(
            runtimeName: resolvedRuntimeName,
            taskId: taskId,
          )
        : qjsFetchImageBytesTaskWait(
            runtimeName: resolvedRuntimeName,
            taskId: taskId,
          );
    return taskGroupKey != null && taskGroupKey.isNotEmpty
        ? raceWithDownloadCancel(taskGroupKey, waitFuture)
        : waitFuture;
  } finally {
    if (taskGroupKey != null && taskGroupKey.isNotEmpty) {
      _untrackTaskRef(
        pluginId: resolvedPluginId,
        taskGroupKey: taskGroupKey,
        taskRef: taskRef,
      );
    }
  }
}

bool _shouldUseQjsCallOnce(String pluginId) {
  // return true;
  final normalized = normalizePluginId(pluginId);
  final state = PluginRegistryService.I.getByUuid(normalized);
  return state?.debug == true;
}

Future<void> cancelTrackedQjsTasks({
  required String pluginId,
  required String taskGroupKey,
}) async {
  final normalizedPluginId = (pluginId).trim();
  final groupId = _buildTaskGroupId(normalizedPluginId, taskGroupKey);
  final refs = _trackedTaskRefsByGroup.remove(groupId)?.toList() ?? const [];

  if (refs.isEmpty) {
    logger.d('取消 QJS 任务组: $groupId -> no_tracked_tasks');
    return;
  }

  var cancelledCount = 0;
  var notFoundCount = 0;
  final failedTaskIds = <String>[];
  final runtimeNames = refs.map((ref) => ref.runtimeName).toSet().toList();

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
          notFoundCount += refs
              .where((ref) => ref.runtimeName == runtimeName)
              .length;
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
    final response = await directDio.get(bundleUrl);
    final body = response.data?.toString() ?? '';
    if (body.trim().isNotEmpty) {
      return body;
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
