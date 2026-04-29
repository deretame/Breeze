import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart' as bd;
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/qjs_download_runtime.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/util/download/download_cancel_signal.dart';
import 'package:zephyr/util/download/download_progress_reporter.dart';
import 'package:zephyr/util/download/platform/desktop_download_runner.dart';
import 'package:zephyr/util/download/platform/ios_download_runner.dart';
import 'package:zephyr/util/foreground_task/task/unified_download_task.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/macos_activity.dart';
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
/// 在 Android 端，由 [MyTaskHandler] 在前台服务 Isolate 中创建和使用。
/// 在桌面端，直接在主 Isolate 中运行。
class DownloadQueueManager {
  static final DownloadQueueManager instance = DownloadQueueManager._();

  DownloadQueueManager._();

  String _downloadingComicId = "";

  bool _isProcessing = false;
  bool _iosRecoveryDone = false;
  StreamSubscription? _watchSubscription;

  /// 进度 Stream，供 UI 监听
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
    dbTask.status = "取消中...";
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
      DownloadProgress(comicName: dbTask.comicName, message: '取消中...'),
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

  /// 桌面端队列处理（直接在主线程异步执行）
  Future<void> _processQueueDesktop() async {
    final pendingTasks = objectbox.downloadTaskBox
        .query(DownloadTask_.isCompleted.equals(false))
        .build()
        .find();

    if (pendingTasks.isEmpty) {
      MacOSActivity.stop();
      _isProcessing = false;
      return;
    }

    MacOSActivity.start();
    _isProcessing = true;

    final desktopReporter = DesktopProgressReporter();
    final dbTask = pendingTasks.first;
    final task = dbTask.taskInfo;

    if (task == null) {
      logger.w("任务 ${dbTask.comicName} 无任务信息，跳过");
      dbTask.isCompleted = true;
      objectbox.downloadTaskBox.put(dbTask);
      Future.microtask(() => _processQueueDesktop());
      return;
    }

    if (_downloadingComicId == task.comicId) {
      logger.w("重复添加任务 ${task.comicName}");
      _isProcessing = false;
      Future.microtask(() => _processQueueDesktop());
      return;
    }

    _downloadingComicId = task.comicId;
    prepareDownloadCancelSignal(task.comicId);
    prepareDownloadCancelSignal(task.comicId);

    dbTask.isDownloading = true;
    dbTask.status = "开始下载...";
    logger.d("dbTask.status: ${dbTask.status}");
    objectbox.downloadTaskBox.put(dbTask);

    _progressController.add(
      DownloadProgress(comicName: task.comicName, message: '开始下载...'),
    );

    try {
      desktopReporter.updateComicName(task.comicName);
      await unifiedDownloadTask(desktopReporter, task);

      logger.d("任务 ${task.comicName} 完成");

      showSuccessToast("${task.comicName} 下载完成");

      dbTask.isCompleted = true;
      dbTask.isDownloading = false;
      objectbox.downloadTaskBox.put(dbTask);

      _progressController.add(
        DownloadProgress(
          comicName: task.comicName,
          message: '下载完成',
          isCompleted: true,
        ),
      );
      await desktopReporter.sendNotification("下载完成", "${task.comicName} 下载完成");
    } catch (e, s) {
      if (_isTaskCancelledOrMarked(task.comicId, e)) {
        logger.i('任务已取消: ${task.comicName}');
        await _removeCancelledTaskRecord(task.comicId, source: task.from);

        _progressController.add(
          DownloadProgress(comicName: task.comicName, message: '已取消'),
        );
      } else {
        if (_isTaskGoneOrCompleted(task.comicId)) {
          logger.i('任务状态已变更，跳过失败回写: ${task.comicName}');
          await _removeCancelledTaskRecord(task.comicId, source: task.from);
          _progressController.add(
            DownloadProgress(comicName: task.comicName, message: '已取消'),
          );
          return;
        }

        logger.e("任务 ${task.comicName} 失败", error: e, stackTrace: s);

        showErrorToast("${task.comicName} 下载失败 ${e.toString()}");

        dbTask.isDownloading = false;
        objectbox.downloadTaskBox.put(dbTask);

        _progressController.add(
          DownloadProgress(
            comicName: task.comicName,
            message: '下载失败',
            isFailed: true,
          ),
        );
        await desktopReporter.sendNotification(
          "下载失败",
          "${task.comicName} 下载失败",
        );
      }
    } finally {
      clearDownloadCancelSignal(task.comicId);
      _downloadingComicId = "";
      Future.microtask(() => _processQueueDesktop());
    }
  }

  /// iOS 队列处理（主线程异步执行）
  ///
  /// iOS 不支持前台服务，采用与桌面端一致的队列调度方式，
  /// 实际图片下载由 picture.dart 内部切换到 background_downloader。
  Future<void> _processQueueIOS() async {
    final pendingTasks = objectbox.downloadTaskBox
        .query(DownloadTask_.isCompleted.equals(false))
        .build()
        .find();

    if (pendingTasks.isEmpty) {
      _isProcessing = false;
      return;
    }

    _isProcessing = true;

    final iosReporter = IOSProgressReporter();
    final dbTask = pendingTasks.first;
    final task = dbTask.taskInfo;

    if (task == null) {
      logger.w("任务 ${dbTask.comicName} 无任务信息，跳过");
      dbTask.isCompleted = true;
      objectbox.downloadTaskBox.put(dbTask);
      Future.microtask(() => _processQueueIOS());
      return;
    }

    if (_downloadingComicId == task.comicId) {
      logger.w("重复添加任务 ${task.comicName}");
      _isProcessing = false;
      Future.microtask(() => _processQueueIOS());
      return;
    }

    _downloadingComicId = task.comicId;

    dbTask.isDownloading = true;
    dbTask.status = "开始下载...";
    objectbox.downloadTaskBox.put(dbTask);

    _progressController.add(
      DownloadProgress(comicName: task.comicName, message: '开始下载...'),
    );

    try {
      iosReporter.updateComicName(task.comicName);
      await unifiedDownloadTask(iosReporter, task);

      logger.d("任务 ${task.comicName} 完成");

      showSuccessToast("${task.comicName} 下载完成");

      dbTask.isCompleted = true;
      dbTask.isDownloading = false;
      objectbox.downloadTaskBox.put(dbTask);

      _progressController.add(
        DownloadProgress(
          comicName: task.comicName,
          message: '下载完成',
          isCompleted: true,
        ),
      );
      await iosReporter.sendNotification("下载完成", "${task.comicName} 下载完成");
    } catch (e, s) {
      if (_isTaskCancelledOrMarked(task.comicId, e)) {
        logger.i('任务已取消: ${task.comicName}');
        await _removeCancelledTaskRecord(task.comicId, source: task.from);

        _progressController.add(
          DownloadProgress(comicName: task.comicName, message: '已取消'),
        );
      } else {
        if (_isTaskGoneOrCompleted(task.comicId)) {
          logger.i('任务状态已变更，跳过失败回写: ${task.comicName}');
          await _removeCancelledTaskRecord(task.comicId, source: task.from);
          _progressController.add(
            DownloadProgress(comicName: task.comicName, message: '已取消'),
          );
          return;
        }

        logger.e("任务 ${task.comicName} 失败", error: e, stackTrace: s);

        showErrorToast("${task.comicName} 下载失败 ${e.toString()}");

        dbTask.isDownloading = false;
        objectbox.downloadTaskBox.put(dbTask);

        _progressController.add(
          DownloadProgress(
            comicName: task.comicName,
            message: '下载失败',
            isFailed: true,
          ),
        );
        await iosReporter.sendNotification("下载失败", "${task.comicName} 下载失败");
      }
    } finally {
      clearDownloadCancelSignal(task.comicId);
      _downloadingComicId = "";
      Future.microtask(() => _processQueueIOS());
    }
  }

  Future<void> _recoverIOSPendingTasksOnStartup() async {
    if (_iosRecoveryDone) {
      return;
    }

    try {
      await bd.FileDownloader().trackTasks(markDownloadedComplete: true);
      await bd.FileDownloader().resumeFromBackground();

      final nativeTasks = await bd.FileDownloader().allTasks(allGroups: true);
      final tempTasks = nativeTasks
          .where((task) => task.filename.startsWith('bg_dl_'))
          .toList();

      if (tempTasks.isNotEmpty) {
        await bd.FileDownloader().cancelTasksWithIds(
          tempTasks.map((task) => task.taskId),
        );
        logger.d("iOS 启动恢复：取消了 ${tempTasks.length} 个旧后台临时任务");
      }
    } catch (e, s) {
      logger.w(
        "iOS 启动恢复：处理 background_downloader 状态失败",
        error: e,
        stackTrace: s,
      );
    }

    final tasksToReset = objectbox.downloadTaskBox
        .query(
          DownloadTask_.isCompleted
              .equals(false)
              .and(DownloadTask_.isDownloading.equals(true)),
        )
        .build()
        .find();

    if (tasksToReset.isNotEmpty) {
      for (final task in tasksToReset) {
        task.isDownloading = false;
      }
      objectbox.downloadTaskBox.putMany(tasksToReset);
      logger.d("iOS 启动恢复：重置了 ${tasksToReset.length} 个任务的下载状态");
    }

    _iosRecoveryDone = true;
  }

  /// 供前台服务 Isolate 使用的队列处理
  ///
  /// Android 端在 [MyTaskHandler] 中调用，传入 Android 特定的 reporter。
  Future<void> processQueueWithReporter(
    DownloadProgressReporter reporter,
  ) async {
    final pendingTasks = objectbox.downloadTaskBox
        .query(DownloadTask_.isCompleted.equals(false))
        .build()
        .find();

    if (pendingTasks.isEmpty) {
      reporter.updateComicName(appName);
      reporter.updateMessage("等待下载任务中...");
      _isProcessing = false;
      FlutterForegroundTask.stopService();
      return;
    }

    if (_downloadingComicId == pendingTasks.first.comicId) {
      logger.w("重复添加任务 ${pendingTasks.first.comicName}");
      return;
    }

    _downloadingComicId = pendingTasks.first.comicId;
    prepareDownloadCancelSignal(pendingTasks.first.comicId);

    _isProcessing = true;

    final dbTask = pendingTasks.first;
    final task = dbTask.taskInfo;

    if (task == null) {
      logger.w("任务 ${dbTask.comicName} 无任务信息，跳过");
      dbTask.isCompleted = true;
      objectbox.downloadTaskBox.put(dbTask);
      Future.microtask(() => processQueueWithReporter(reporter));
      return;
    }

    dbTask.isDownloading = true;
    objectbox.downloadTaskBox.put(dbTask);

    try {
      await unifiedDownloadTask(reporter, task);

      logger.d("任务 ${task.comicName} 完成");

      dbTask.isCompleted = true;
      dbTask.isDownloading = false;
      objectbox.downloadTaskBox.put(dbTask);

      await reporter.sendNotification("下载完成", "${task.comicName} 下载完成");
      _sendTaskCompleted(task.comicName);
    } catch (e, s) {
      if (_isTaskCancelledOrMarked(task.comicId, e)) {
        logger.i('任务已取消: ${task.comicName}');
        await _removeCancelledTaskRecord(task.comicId, source: task.from);
      } else {
        if (_isTaskGoneOrCompleted(task.comicId)) {
          logger.i('任务状态已变更，跳过失败回写: ${task.comicName}');
          await _removeCancelledTaskRecord(task.comicId, source: task.from);
          return;
        }

        logger.e("任务 ${task.comicName} 失败", error: e, stackTrace: s);

        dbTask.isDownloading = false;
        objectbox.downloadTaskBox.put(dbTask);

        await reporter.sendNotification("下载失败", "${task.comicName} 下载失败");
      }
    } finally {
      clearDownloadCancelSignal(task.comicId);
      _downloadingComicId = "";
      Future.microtask(() => processQueueWithReporter(reporter));
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
        _processQueueDesktop();
      }
    });
  }

  Future<void> watchTasksForIOS() async {
    await _recoverIOSPendingTasksOnStartup();

    _watchSubscription?.cancel();
    _watchSubscription = null;

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
        _processQueueIOS();
      }
    });
  }

  void watchTasksForAndroid(DownloadProgressReporter reporter) {
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
        processQueueWithReporter(reporter);
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
      final pluginId = normalizePluginId(source);
      final downloadRoot = await getDownloadPath();
      final targetDir = Directory(
        '$downloadRoot${Platform.pathSeparator}$pluginId${Platform.pathSeparator}original${Platform.pathSeparator}${comicId.trim()}',
      );
      if (await targetDir.exists()) {
        await targetDir.delete(recursive: true);
        logger.i('已删除取消任务文件夹: ${targetDir.path}');
      }
    } catch (e, s) {
      logger.w(
        '删除取消任务文件夹失败: comicId=$comicId, source=$source',
        error: e,
        stackTrace: s,
      );
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
      task.isCompleted && !task.isDownloading && status.contains('取消');

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

void _sendTaskCompleted(String comicName) {
  if (Platform.isAndroid) {
    FlutterForegroundTask.sendDataToMain(comicName);
  } else {
    showSuccessToast('$comicName 下载完毕');
  }
}
