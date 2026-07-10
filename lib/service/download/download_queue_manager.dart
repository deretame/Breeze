import 'dart:async';
import 'dart:io';

import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/network/http/plugin/qjs_download_runtime.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/service/download/comic_download_task.dart';
import 'package:zephyr/service/download/download_cancel_signal.dart';
import 'package:zephyr/service/download/download_notification_reporter.dart';
import 'package:zephyr/service/download/models/download_task_json.dart';
import 'package:zephyr/service/lifecycle/foreground_task/foreground_task_service.dart';

import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/macos_activity.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/toast.dart';

const _kQjsRuntimeCancelledMessage = '__QJS_RUNTIME_CANCELLED__';

/// 下载进度信息
class DownloadProgress {
  final String comicName;
  final String message;
  final bool isCompleted;
  final bool isFailed;

  DownloadProgress({
    required this.comicName,
    required this.message,
    this.isCompleted = false,
    this.isFailed = false,
  });
}

/// 跨平台下载队列管理器（单例）
///
/// 在所有平台的主 Isolate 中运行，负责统一下载调度。
/// Android 端配合前台服务使用，前台服务仅用于保活和通知栏展示。
class DownloadQueueManager {
  static final DownloadQueueManager instance = DownloadQueueManager._();

  DownloadQueueManager._();

  String _downloadingComicId = "";

  bool _isProcessing = false;
  StreamSubscription? _watchSubscription;

  /// 进度 Stream，供 UI 和前台服务通知监听
  final _progressController = StreamController<DownloadProgress>.broadcast();

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  /// 当前是否有任务在执行
  bool get isProcessing => _isProcessing;

  /// 取消当前正在执行的下载任务
  ///
  /// 如果当前没有运行中的任务，此方法无任何副作用。
  void cancelCurrentTask() {
    final downloadingTask = objectbox.downloadTaskBox
        .query(
          DownloadTask_.isCompleted
              .equals(false)
              .and(DownloadTask_.isDownloading.equals(true)),
        )
        .order(DownloadTask_.id)
        .build()
        .findFirst();

    if (downloadingTask != null) {
      logger.i('收到取消请求，正在取消当前任务: ${downloadingTask.comicName}');
      _cancelTask(downloadingTask);
      return;
    }

    if (_downloadingComicId.isEmpty) {
      return;
    }

    final fallbackTask = objectbox.downloadTaskBox
        .query(
          DownloadTask_.comicId
              .equals(_downloadingComicId)
              .and(DownloadTask_.isCompleted.equals(false)),
        )
        .build()
        .findFirst();

    if (fallbackTask != null) {
      logger.i('收到取消请求(回退匹配)，正在取消任务: ${fallbackTask.comicName}');
      _cancelTask(fallbackTask);
    }
  }

  void _cancelTask(DownloadTask dbTask) {
    dbTask.status = t.download.statusCancelling;
    dbTask.isDownloading = false;
    dbTask.isCompleted = true;
    objectbox.downloadTaskBox.put(dbTask);
    triggerDownloadCancelSignal(dbTask.comicId);

    final source = dbTask.taskInfo?.from;
    if (source != null && source.isNotEmpty) {
      unawaited(
        cancelTrackedQjsTasks(pluginId: source, taskGroupKey: dbTask.comicId),
      );
    }

    _progressController.add(
      DownloadProgress(
        comicName: dbTask.comicName,
        message: t.download.statusCancelling,
      ),
    );
  }

  /// 队列中剩余任务数
  int get queueLength => objectbox.downloadTaskBox
      .query(DownloadTask_.isCompleted.equals(false))
      .build()
      .find()
      .length;

  /// 检查任务是否已存在（未完成的任务）
  bool taskExists(String comicId) {
    final existingTask = objectbox.downloadTaskBox
        .query(
          DownloadTask_.comicId
              .equals(comicId)
              .and(DownloadTask_.isCompleted.equals(false)),
        )
        .build()
        .findFirst();
    return existingTask != null;
  }

  /// 统一的队列处理入口
  Future<void> _processQueue() async {
    final pendingTasks = objectbox.downloadTaskBox
        .query(DownloadTask_.isCompleted.equals(false))
        .build()
        .find();
    logger.d('_processQueue: 发现 ${pendingTasks.length} 个待处理任务');

    if (pendingTasks.isEmpty) {
      if (Platform.isMacOS) {
        MacOSActivity.stop();
      }
      _isProcessing = false;
      if (Platform.isAndroid) {
        await ForegroundTaskService.instance.stop();
      }
      return;
    }

    if (Platform.isMacOS) {
      MacOSActivity.start();
    }
    _isProcessing = true;

    final reporter = DownloadNotificationReporter();
    reporter.setOnUpdate((comicName, message) {
      _progressController.add(
        DownloadProgress(comicName: comicName, message: message),
      );
    });
    final dbTask = pendingTasks.first;
    final task = dbTask.taskInfo;
    logger.d(
      '_processQueue: 处理任务 id=${dbTask.id}, comicId=${dbTask.comicId}, taskInfo=${task != null}',
    );

    if (task == null) {
      logger.w("任务 ${dbTask.comicName} 无任务信息，跳过");
      dbTask.isCompleted = true;
      objectbox.downloadTaskBox.put(dbTask);
      Future.microtask(() => _processQueue());
      return;
    }

    if (_downloadingComicId == task.comicId) {
      logger.w("重复添加任务 ${task.comicName}");
      _isProcessing = false;
      Future.microtask(() => _processQueue());
      return;
    }

    _downloadingComicId = task.comicId;
    prepareDownloadCancelSignal(task.comicId);

    dbTask.isDownloading = true;
    dbTask.status = t.download.statusStartDownload;
    logger.d("dbTask.status: ${dbTask.status}");
    objectbox.downloadTaskBox.put(dbTask);

    _progressController.add(
      DownloadProgress(
        comicName: task.comicName,
        message: t.download.statusStartDownload,
      ),
    );

    try {
      reporter.updateComicName(task.comicName);
      await unifiedDownloadTask(reporter, task);

      logger.d("任务 ${task.comicName} 完成");

      dbTask.isCompleted = true;
      dbTask.isDownloading = false;
      objectbox.downloadTaskBox.put(dbTask);

      _progressController.add(
        DownloadProgress(
          comicName: task.comicName,
          message: t.download.notificationCompleteTitle,
          isCompleted: true,
        ),
      );

      if (!Platform.isAndroid) {
        showSuccessToast(
          t.download.toastDownloadComplete(comicName: task.comicName),
        );
      }
      await reporter.sendNotification(
        t.download.notificationCompleteTitle,
        t.download.toastDownloadComplete(comicName: task.comicName),
      );

      // 下载成功后清理所有已完成的任务记录
      _removeAllCompletedTasks();
      logger.d('_processQueue: 任务完成并清理');
    } catch (e, s) {
      if (_isTaskCancelledOrMarked(task.comicId, e)) {
        logger.i('任务已取消: ${task.comicName}');
        await _removeCancelledTaskRecord(task.comicId, source: task.from);

        _progressController.add(
          DownloadProgress(
            comicName: task.comicName,
            message: t.download.statusCancelling,
          ),
        );
      } else {
        if (_isTaskGoneOrCompleted(task.comicId)) {
          logger.i('任务状态已变更，跳过失败回写: ${task.comicName}');
          await _removeCancelledTaskRecord(task.comicId, source: task.from);
          _progressController.add(
            DownloadProgress(
              comicName: task.comicName,
              message: t.download.statusCancelling,
            ),
          );
          return;
        }

        logger.e("任务 ${task.comicName} 失败", error: e, stackTrace: s);

        dbTask.isDownloading = false;
        objectbox.downloadTaskBox.put(dbTask);

        _progressController.add(
          DownloadProgress(
            comicName: task.comicName,
            message: t.download.notificationFailedTitle,
            isFailed: true,
          ),
        );

        if (!Platform.isAndroid) {
          showErrorToast(
            t.download.toastDownloadFailed(
              comicName: task.comicName,
              error: normalizeSearchErrorMessage(e),
            ),
          );
        }
        await reporter.sendNotification(
          t.download.notificationFailedTitle,
          t.download.toastDownloadFailed(
            comicName: task.comicName,
            error: normalizeSearchErrorMessage(e),
          ),
        );
      }
    } finally {
      clearDownloadCancelSignal(task.comicId);
      _downloadingComicId = "";
      Future.microtask(() => _processQueue());
    }
  }

  /// 添加一个下载任务到队列。
  ///
  /// 任务会被持久化到 ObjectBox，随后 [watchTasks] 的 query watcher 会触发
  /// [_processQueue] 开始执行。
  void addTask(DownloadTaskJson task) {
    if (taskExists(task.comicId)) {
      logger.w("任务 ${task.comicName} 已存在，跳过添加");
      showInfoToast(
        t.download.toastTaskAlreadyExists(comicName: task.comicName),
      );
      return;
    }

    final box = objectbox.downloadTaskBox;
    final downloadTask = DownloadTask()
      ..comicId = task.comicId
      ..comicName = task.comicName
      ..isCompleted = false
      ..isDownloading = false
      ..status = t.download.statusWaiting
      ..taskInfo = task;

    final id = box.put(downloadTask);
    logger.d(
      'addTask: 已添加任务 id=$id, comicId=${task.comicId}, '
      'taskInfoStr=${downloadTask.dbTaskInfoStr?.substring(0, downloadTask.dbTaskInfoStr!.length > 50 ? 50 : downloadTask.dbTaskInfoStr!.length)}',
    );
  }

  /// 重置异常退出时遗留的“下载中”状态。
  ///
  /// 应用启动后、开始监听任务队列前调用一次，避免上次崩溃/杀进程后留下的
  /// `isDownloading == true` 任务永远无法被调度。
  void resetStuckTasks() {
    final pendingTasks = objectbox.downloadTaskBox
        .query(DownloadTask_.isCompleted.equals(false))
        .build()
        .find();

    final tasksToReset = pendingTasks
        .where((task) => task.isDownloading)
        .toList();

    if (tasksToReset.isNotEmpty) {
      for (final task in tasksToReset) {
        task.isDownloading = false;
      }
      objectbox.downloadTaskBox.putMany(tasksToReset);
      logger.d("重置了 ${tasksToReset.length} 个任务的下载状态");
    }
  }

  void watchTasks() {
    final watchedQuery = objectbox.downloadTaskBox
        .query(
          DownloadTask_.isCompleted
              .equals(false)
              .and(DownloadTask_.isDownloading.equals(false)),
        )
        .watch(triggerImmediately: true);

    _watchSubscription = watchedQuery.listen((query) {
      final pendingTasks = query.find();
      if (pendingTasks.isNotEmpty && !_isProcessing) {
        _processQueue();
      }
    });
  }

  void stopWatchingTasks() {
    _watchSubscription?.cancel();
    _watchSubscription = null;
  }

  void dispose() {
    _progressController.close();
    stopWatchingTasks();
  }

  Future<void> _removeCancelledTaskRecord(
    String comicId, {
    String? source,
  }) async {
    final cancelledTasks = objectbox.downloadTaskBox
        .query(DownloadTask_.comicId.equals(comicId))
        .build()
        .find();
    final fallbackSource = cancelledTasks.isNotEmpty
        ? (cancelledTasks.first.taskInfo?.from ?? "")
        : "";
    final resolvedSource = (source ?? fallbackSource).trim();
    if (cancelledTasks.isNotEmpty) {
      objectbox.downloadTaskBox.removeMany(
        cancelledTasks.map((e) => e.id).toList(),
      );
    }
    await _deleteCancelledTaskFiles(comicId, source: resolvedSource);
  }

  Future<void> _deleteCancelledTaskFiles(
    String comicId, {
    required String source,
  }) async {
    if (comicId.trim().isEmpty || source.trim().isEmpty) {
      return;
    }
    try {
      await deleteComicDownloadDirectory(source, comicId.trim());
      logger.i('已删除取消任务文件夹: $source:$comicId');
    } catch (e, s) {
      logger.w(
        '删除取消任务文件夹失败: comicId=$comicId, source=$source',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// 删除所有已完成的任务记录
  void _removeAllCompletedTasks() {
    final completedTasks = objectbox.downloadTaskBox
        .query(DownloadTask_.isCompleted.equals(true))
        .build()
        .find();

    if (completedTasks.isNotEmpty) {
      objectbox.downloadTaskBox.removeMany(
        completedTasks.map((e) => e.id).toList(),
      );
      logger.d('清理了 ${completedTasks.length} 个已完成的任务记录');
    }
  }
}

bool _isTaskCancelledError(Object error) {
  return error.toString().contains(downloadTaskCancelledMessage);
}

bool _isTaskCancelledOrMarked(String comicId, Object error) {
  if (_isTaskCancelledError(error) ||
      error.toString().contains(_kQjsRuntimeCancelledMessage)) {
    return true;
  }

  final task = objectbox.downloadTaskBox
      .query(DownloadTask_.comicId.equals(comicId))
      .build()
      .findFirst();

  if (task == null) {
    return true;
  }

  final status = task.status;
  final isMarkedCancelled =
      task.isCompleted && !task.isDownloading && status.contains('取消') ||
      status.toLowerCase().contains('cancel');

  return isMarkedCancelled;
}

bool _isTaskGoneOrCompleted(String comicId) {
  final task = objectbox.downloadTaskBox
      .query(DownloadTask_.comicId.equals(comicId))
      .build()
      .findFirst();

  if (task == null) {
    return true;
  }

  return task.isCompleted || !task.isDownloading;
}

/// 启动一个下载任务。
///
/// 所有平台都会把任务写入数据库，由 [DownloadQueueManager] 统一调度。
/// Android 端会额外启动前台服务以保活，但前台服务本身不管理下载逻辑。
Future<void> startDownloadTask(DownloadTaskJson task) async {
  logger.d(
    'startDownloadTask: comicId=${task.comicId}, comicName=${task.comicName}',
  );

  DownloadQueueManager.instance.addTask(task);

  if (Platform.isAndroid) {
    await ForegroundTaskService.instance.start();
  }
}
