import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/bika/http_request.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/util/download/download_cancel_signal.dart';
import 'package:zephyr/util/direct_dio.dart';
import 'package:zephyr/util/download/qjs_runtime_mode.dart';

class _TrackedQjsTaskRef extends Equatable {
  const _TrackedQjsTaskRef({required this.runtimeName, required this.taskId});

  final String runtimeName;
  final BigInt taskId;

  @override
  List<Object?> get props => [runtimeName, taskId];
}

final Map<String, Set<_TrackedQjsTaskRef>> _trackedTaskRefsByGroup = {};

String runtimeNameForSource(String source) {
  return source == 'bika' ? 'bikaComic' : 'jmComic';
}

String _buildTaskGroupId(String source, String taskGroupKey) {
  return '$source::$taskGroupKey';
}

void _trackTaskRef({
  required String source,
  required String taskGroupKey,
  required _TrackedQjsTaskRef taskRef,
}) {
  (_trackedTaskRefsByGroup[_buildTaskGroupId(source, taskGroupKey)] ??=
          <_TrackedQjsTaskRef>{})
      .add(taskRef);
}

void _untrackTaskRef({
  required String source,
  required String taskGroupKey,
  required _TrackedQjsTaskRef taskRef,
}) {
  final groupId = _buildTaskGroupId(source, taskGroupKey);
  final refs = _trackedTaskRefsByGroup[groupId];
  refs?.remove(taskRef);
  if (refs != null && refs.isEmpty) {
    _trackedTaskRefsByGroup.remove(groupId);
  }
}

Future<void> ensureQjsRuntimeReady({required String source}) async {
  if (useQjsCallOnce) {
    return;
  }

  final runtimeName = runtimeNameForSource(source);
  final bundleName = runtimeName;

  try {
    final bundleJs = await loadQjsBundleJs(source);
    await initQjsRuntimeWithBundle(
      runtimeName: runtimeName,
      bundleName: bundleName,
      bundleJs: bundleJs,
    );
  } catch (e) {
    logger.w('初始化 QJS 失败: $runtimeName', error: e);
    rethrow;
  }
}

Future<String> executeQjsCall({
  required String source,
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

  final resolvedRuntimeName = runtimeName ?? runtimeNameForSource(source);
  final bundleJs = useQjsCallOnce ? await loadQjsBundleJs(source) : null;

  final taskId = useQjsCallOnce
      ? await qjsCallOnceTaskStart(
          runtimeName: resolvedRuntimeName,
          bundleJs: bundleJs!,
          fnPath: fnPath,
          argsJson: argsJson,
          taskGroupKey: taskGroupKey ?? '',
        )
      : await () async {
          await ensureQjsRuntimeReady(source: source);
          return qjsCallTaskStart(
            runtimeName: resolvedRuntimeName,
            taskGroupKey: taskGroupKey ?? '',
            fnPath: fnPath,
            argsJson: argsJson,
          );
        }();

  final taskRef = _TrackedQjsTaskRef(
    runtimeName: resolvedRuntimeName,
    taskId: taskId,
  );
  if (taskGroupKey != null && taskGroupKey.isNotEmpty) {
    _trackTaskRef(source: source, taskGroupKey: taskGroupKey, taskRef: taskRef);
  }

  try {
    final waitFuture = useQjsCallOnce
        ? qjsCallOnceTaskWait(runtimeName: resolvedRuntimeName, taskId: taskId)
        : qjsCallTaskWait(runtimeName: resolvedRuntimeName, taskId: taskId);
    return taskGroupKey != null && taskGroupKey.isNotEmpty
        ? raceWithDownloadCancel(taskGroupKey, waitFuture)
        : waitFuture;
  } finally {
    if (taskGroupKey != null && taskGroupKey.isNotEmpty) {
      _untrackTaskRef(
        source: source,
        taskGroupKey: taskGroupKey,
        taskRef: taskRef,
      );
    }
  }
}

Future<Uint8List> executeQjsFetchImageBytes({
  required String source,
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

  final resolvedRuntimeName = runtimeName ?? runtimeNameForSource(source);
  final bundleJs = useQjsCallOnce ? await loadQjsBundleJs(source) : null;

  final taskId = useQjsCallOnce
      ? await qjsFetchImageBytesOnceTaskStart(
          runtimeName: resolvedRuntimeName,
          bundleJs: bundleJs!,
          fnPath: fnPath,
          argsJson: argsJson,
          taskGroupKey: taskGroupKey ?? '',
        )
      : await () async {
          await ensureQjsRuntimeReady(source: source);
          return qjsFetchImageBytesTaskStart(
            runtimeName: resolvedRuntimeName,
            taskGroupKey: taskGroupKey ?? '',
            fnPath: fnPath,
            argsJson: argsJson,
          );
        }();

  final taskRef = _TrackedQjsTaskRef(
    runtimeName: resolvedRuntimeName,
    taskId: taskId,
  );
  if (taskGroupKey != null && taskGroupKey.isNotEmpty) {
    _trackTaskRef(source: source, taskGroupKey: taskGroupKey, taskRef: taskRef);
  }

  try {
    final waitFuture = useQjsCallOnce
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
        source: source,
        taskGroupKey: taskGroupKey,
        taskRef: taskRef,
      );
    }
  }
}

Future<void> cancelTrackedQjsTasks({
  required String source,
  required String taskGroupKey,
}) async {
  final groupId = _buildTaskGroupId(source, taskGroupKey);
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

Future<String> loadQjsBundleJs(String source) async {
  if (!kDebugMode) {
    return getJsBundle(name: runtimeNameForSource(source));
  }

  final bundleUrl = source == 'bika' ? await bikaJsUrl : await jmJsUrl;
  final response = await directDio.get(bundleUrl);
  return response.data;
}
