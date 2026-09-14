import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/qjs_download_runtime.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/service/download/comic_download_task.dart';
import 'package:zephyr/service/download/download_cancel_signal.dart';
import 'package:zephyr/service/download/download_notification_reporter.dart';
import 'package:zephyr/service/download/download_asset_store.dart';
import 'package:zephyr/service/download/download_task_repository.dart';
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
/// Android 端配合前台服务使用；前台服务与「后台保活」共用，仅用于提权与通知展示。
class DownloadQueueManager {
  static final DownloadQueueManager instance = DownloadQueueManager._();

  DownloadQueueManager._();

  static const _taskRepository = DownloadTaskRepository();

  String _downloadingTaskKey = "";

  bool _isProcessing = false;
  StreamSubscription? _watchSubscription;
  Timer? _startupResumeTimer;
  bool _startupResumeWaiting = false;
  bool _failureDialogShowing = false;
  final Set<int> _startupResumeTaskIds = <int>{};

  /// 进度 Stream，供 UI 和前台服务通知监听
  final _progressController = StreamController<DownloadProgress>.broadcast();

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  /// 当前是否有任务在执行
  bool get isProcessing => _isProcessing;

  /// 取消当前正在执行的下载任务
  ///
  /// 如果当前没有运行中的任务，此方法无任何副作用。
  void cancelCurrentTask() {
    final downloadingTasks = _taskRepository
        .getAll(incompleteOnly: true)
        .where((task) => task.isDownloading)
        .toList();
    final downloadingTask = downloadingTasks.isEmpty
        ? null
        : downloadingTasks.first;

    if (downloadingTask != null) {
      logger.i('收到取消请求，正在取消当前任务: ${downloadingTask.comicName}');
      _cancelTask(downloadingTask);
      return;
    }

    if (_downloadingTaskKey.isEmpty) {
      return;
    }

    final fallbackTask = _taskRepository.findByTaskKey(
      _downloadingTaskKey,
      incompleteOnly: true,
    );

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
    final taskKey = downloadTaskKeyOf(dbTask);
    triggerDownloadCancelSignal(taskKey);

    final source = dbTask.taskInfo?.from;
    if (source != null && source.isNotEmpty) {
      unawaited(cancelTrackedQjsTasks(pluginId: source, taskGroupKey: taskKey));
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

  List<DownloadTask> _runnableTasks() {
    return _taskRepository
        .getAll(incompleteOnly: true)
        .where(
          (task) => _taskRepository.readPayload(task)?.stateCode != 'failed',
        )
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  /// 检查任务是否已存在（未完成的任务）
  bool taskExists(String from, String comicId) {
    return _taskRepository.findByPayload(
          from: from,
          comicId: comicId,
          incompleteOnly: true,
        ) !=
        null;
  }

  /// 统一的队列处理入口
  Future<void> _processQueue({bool bypassStartupResumeDelay = false}) async {
    final allPendingTasks = _runnableTasks();
    final pendingTasks = bypassStartupResumeDelay || !_startupResumeWaiting
        ? allPendingTasks
        : allPendingTasks
              .where((task) => !_startupResumeTaskIds.contains(task.id))
              .toList();
    logger.d('_processQueue: 发现 ${pendingTasks.length} 个待处理任务');

    if (pendingTasks.isEmpty) {
      if (_startupResumeWaiting && allPendingTasks.isNotEmpty) {
        _isProcessing = false;
        return;
      }
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

    final taskKey = task.taskKey;
    if (_downloadingTaskKey == taskKey) {
      logger.w("重复添加任务 ${task.comicName}");
      _isProcessing = false;
      Future.microtask(() => _processQueue());
      return;
    }

    _downloadingTaskKey = taskKey;
    prepareDownloadCancelSignal(taskKey);

    dbTask.isDownloading = true;
    dbTask.status = t.download.statusStartDownload;
    dbTask.taskInfo = task.copyWith(
      stateCode: 'running',
      phaseCode: 'preparingRuntime',
      attempt: task.attempt + 1,
      lastErrorCode: '',
      lastErrorMessage: '',
    );
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

      // unifiedDownloadTask 会持续更新 taskInfo。这里必须重新读取实体，
      // 不能把进入队列时保存的旧 dbTask 再写回去，否则可能覆盖掉最新的
      // completedChapterKeys / stateCode，并让恢复逻辑误判为旧任务。
      final completedDbTask = _taskRepository.findByTaskKey(taskKey);
      if (completedDbTask != null) {
        final completedPayload =
            _taskRepository.readPayload(completedDbTask) ?? task;
        completedDbTask
          ..isCompleted = true
          ..isDownloading = false
          ..taskInfo = completedPayload.copyWith(
            stateCode: 'completed',
            phaseCode: 'completed',
          );
        objectbox.downloadTaskBox.put(completedDbTask);
      }

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
      if (_isTaskCancelledOrMarked(taskKey, e)) {
        logger.i('任务已取消: ${task.comicName}');
        await _removeCancelledTaskRecord(taskKey);

        _progressController.add(
          DownloadProgress(
            comicName: task.comicName,
            message: t.download.statusCancelling,
          ),
        );
      } else {
        if (_isTaskGoneOrCompleted(taskKey)) {
          logger.i('任务状态已变更，跳过失败回写: ${task.comicName}');
          await _removeCancelledTaskRecord(taskKey);
          _progressController.add(
            DownloadProgress(
              comicName: task.comicName,
              message: t.download.statusCancelling,
            ),
          );
          return;
        }

        logger.e("任务 ${task.comicName} 失败", error: e, stackTrace: s);

        final currentDbTask = _taskRepository.findByTaskKey(taskKey) ?? dbTask;
        final currentPayload =
            _taskRepository.readPayload(currentDbTask) ?? task;
        currentDbTask.isDownloading = false;
        currentDbTask.status = t.download.notificationFailedTitle;
        currentDbTask.taskInfo = currentPayload.copyWith(
          stateCode: 'failed',
          phaseCode: 'retryWaiting',
          lastErrorCode: e.runtimeType.toString(),
          lastErrorMessage: e.toString(),
        );
        objectbox.downloadTaskBox.put(currentDbTask);

        _progressController.add(
          DownloadProgress(
            comicName: task.comicName,
            message: t.download.notificationFailedTitle,
            isFailed: true,
          ),
        );

        final failureDialogShown = await _showFailureRetryDialog(
          task: currentDbTask,
          error: e,
        );
        if (!failureDialogShown && !Platform.isAndroid) {
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
      clearDownloadCancelSignal(taskKey);
      _downloadingTaskKey = "";
      Future.microtask(() => _processQueue());
    }
  }

  Future<bool> _showFailureRetryDialog({
    required DownloadTask task,
    required Object error,
  }) async {
    if (_failureDialogShowing ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return false;
    }

    final context = navigatorKey.currentState?.overlay?.context;
    if (context == null) return false;

    _failureDialogShowing = true;
    try {
      final shouldRetry = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(t.download.notificationFailedTitle),
          content: Text(
            t.download.toastDownloadFailed(
              comicName: task.comicName,
              error: normalizeSearchErrorMessage(error),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.common.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.common.retry),
            ),
          ],
        ),
      );
      if (shouldRetry == true) {
        retryTask(task.id);
      }
      return true;
    } catch (dialogError, stackTrace) {
      logger.w(
        '显示下载失败重试对话框失败: taskId=${task.id}',
        error: dialogError,
        stackTrace: stackTrace,
      );
      return false;
    } finally {
      _failureDialogShowing = false;
    }
  }

  /// 添加一个下载任务到队列。
  ///
  /// 任务会被持久化到 ObjectBox，随后 [watchTasks] 的 query watcher 会触发
  /// [_processQueue] 开始执行。
  void addTask(DownloadTaskJson task) {
    if (taskExists(task.from, task.comicId)) {
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

  /// 手动重试一个已失败任务。
  void retryTask(int taskId) {
    final task = objectbox.downloadTaskBox.get(taskId);
    if (task == null || task.isCompleted) return;
    final payload = _taskRepository.readPayload(task);
    if (payload == null) return;

    _taskRepository.putPayload(
      task,
      payload.copyWith(
        stateCode: 'queued',
        phaseCode: 'retry',
        lastErrorCode: '',
        lastErrorMessage: '',
      ),
      status: t.download.statusWaiting,
      isDownloading: false,
      isCompleted: false,
    );
    logger.i('已重新排队下载任务: taskId=$taskId, taskKey=${payload.taskKey}');
  }

  /// 重置异常退出时遗留的“下载中”状态。
  ///
  /// 应用启动后、开始监听任务队列前调用一次，避免上次崩溃/杀进程后留下的
  /// `isDownloading == true` 任务永远无法被调度。
  void resetStuckTasks() {
    _taskRepository.resetInterruptedTasks();
  }

  void watchTasks({Duration startupResumeDelay = Duration.zero}) {
    stopWatchingTasks();

    final startupQuery = objectbox.downloadTaskBox
        .query(
          DownloadTask_.isCompleted
              .equals(false)
              .and(DownloadTask_.isDownloading.equals(false)),
        )
        .build();
    late final List<DownloadTask> startupTasks;
    try {
      startupTasks = startupQuery.find();
    } finally {
      startupQuery.close();
    }

    final watchedQuery = objectbox.downloadTaskBox
        .query(
          DownloadTask_.isCompleted
              .equals(false)
              .and(DownloadTask_.isDownloading.equals(false)),
        )
        .watch(triggerImmediately: startupResumeDelay == Duration.zero);

    _startupResumeTaskIds
      ..clear()
      ..addAll(startupTasks.map((task) => task.id));
    _startupResumeWaiting = startupResumeDelay > Duration.zero;
    if (_startupResumeWaiting) {
      logger.i(
        '应用启动后延迟 ${startupResumeDelay.inSeconds} 秒恢复下载，'
        '待恢复任务数=${_startupResumeTaskIds.length}',
      );
      _startupResumeTimer = Timer(startupResumeDelay, () {
        _startupResumeWaiting = false;
        _startupResumeTaskIds.clear();
        _startupResumeTimer = null;
        logger.i('应用启动下载恢复延迟结束，开始处理下载队列');
        if (!_isProcessing) {
          _processQueue();
        }
      });
    }

    _watchSubscription = watchedQuery.listen((query) {
      final pendingTasks = query.find();
      if (pendingTasks.isNotEmpty && !_isProcessing) {
        final hasNewTaskDuringStartupDelay =
            _startupResumeWaiting &&
            pendingTasks.any(
              (task) => !_startupResumeTaskIds.contains(task.id),
            );
        if (!_startupResumeWaiting || hasNewTaskDuringStartupDelay) {
          _processQueue(bypassStartupResumeDelay: hasNewTaskDuringStartupDelay);
        }
      }
    });
  }

  void stopWatchingTasks() {
    _watchSubscription?.cancel();
    _watchSubscription = null;
    _startupResumeTimer?.cancel();
    _startupResumeTimer = null;
    _startupResumeWaiting = false;
    _startupResumeTaskIds.clear();
  }

  void dispose() {
    _progressController.close();
    stopWatchingTasks();
  }

  Future<void> _removeCancelledTaskRecord(String taskKey) async {
    final cancelledTask = _taskRepository.findByTaskKey(taskKey);
    final resolvedTaskKey = cancelledTask == null
        ? taskKey
        : downloadTaskKeyOf(cancelledTask);
    if (cancelledTask != null) {
      objectbox.downloadTaskBox.remove(cancelledTask.id);
    }
    try {
      await cleanupDownloadTaskTemporaryFiles(resolvedTaskKey);
      logger.i('已清理取消任务的临时文件: $resolvedTaskKey');
    } catch (e, s) {
      logger.w(
        '清理取消任务临时文件失败: taskKey=$resolvedTaskKey',
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

bool _isTaskCancelledOrMarked(String taskKey, Object error) {
  if (_isTaskCancelledError(error) ||
      error.toString().contains(_kQjsRuntimeCancelledMessage)) {
    return true;
  }

  final task = const DownloadTaskRepository().findByTaskKey(taskKey);

  if (task == null) {
    return true;
  }

  final status = task.status;
  final isMarkedCancelled =
      task.isCompleted && !task.isDownloading && status.contains('取消') ||
      status.toLowerCase().contains('cancel');

  return isMarkedCancelled;
}

bool _isTaskGoneOrCompleted(String taskKey) {
  final task = const DownloadTaskRepository().findByTaskKey(taskKey);

  if (task == null) {
    return true;
  }

  return task.isCompleted || !task.isDownloading;
}

/// 启动一个下载任务。
///
/// 所有平台都会把任务写入数据库，由 [DownloadQueueManager] 统一调度。
/// Android 端会确保前台服务在跑（若保活已开启则复用），前台服务本身不管理下载逻辑。
Future<void> startDownloadTask(DownloadTaskJson task) async {
  logger.d(
    'startDownloadTask: comicId=${task.comicId}, comicName=${task.comicName}',
  );

  DownloadQueueManager.instance.addTask(task);

  if (Platform.isAndroid) {
    await ForegroundTaskService.instance.start();
  }
}
