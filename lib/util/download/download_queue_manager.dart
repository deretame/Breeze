import 'dart:async';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/util/download/download_progress_reporter.dart';
import 'package:zephyr/util/download/platform/desktop_download_runner.dart';
import 'package:zephyr/util/foreground_task/task/bika_download.dart';
import 'package:zephyr/util/foreground_task/task/jm_download.dart';
import 'package:zephyr/widgets/toast.dart';

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
  StreamSubscription? _watchSubscription;

  /// 进度 Stream，供 UI 监听
  final _progressController = StreamController<DownloadProgress>.broadcast();

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  /// 当前是否有任务在执行
  bool get isProcessing => _isProcessing;

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
      _isProcessing = false;
      return;
    }

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

    dbTask.isDownloading = true;
    dbTask.status = "开始下载...";
    logger.d("dbTask.status: ${dbTask.status}");
    objectbox.downloadTaskBox.put(dbTask);

    _progressController.add(
      DownloadProgress(comicName: task.comicName, message: '开始下载...'),
    );

    try {
      desktopReporter.updateComicName(task.comicName);
      if (task.from == "bika") {
        await bikaDownloadTask(desktopReporter, task);
      } else if (task.from == "jm") {
        await jmDownloadTask(desktopReporter, task);
      } else {
        logger.w("未知任务来源: ${task.from}");
      }

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
      await desktopReporter.sendNotification("下载失败", "${task.comicName} 下载失败");
    } finally {
      Future.microtask(() => _processQueueDesktop());
    }
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
      if (task.from == "bika") {
        await bikaDownloadTask(reporter, task);
      } else if (task.from == "jm") {
        await jmDownloadTask(reporter, task);
      } else {
        logger.w("未知任务来源: ${task.from}");
      }

      logger.d("任务 ${task.comicName} 完成");

      dbTask.isCompleted = true;
      dbTask.isDownloading = false;
      objectbox.downloadTaskBox.put(dbTask);

      await reporter.sendNotification("下载完成", "${task.comicName} 下载完成");
      _sendTaskCompleted(task.comicName);
    } catch (e, s) {
      logger.e("任务 ${task.comicName} 失败", error: e, stackTrace: s);

      dbTask.isDownloading = false;
      objectbox.downloadTaskBox.put(dbTask);

      await reporter.sendNotification("下载失败", "${task.comicName} 下载失败");
    } finally {
      Future.microtask(() => processQueueWithReporter(reporter));
    }
  }

  void watchTasks({required bool isDesktop}) {
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
        if (isDesktop) {
          _processQueueDesktop();
        }
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
}

void _sendTaskCompleted(String comicName) {
  if (Platform.isAndroid) {
    FlutterForegroundTask.sendDataToMain(comicName);
  } else {
    showSuccessToast('$comicName 下载完毕');
  }
}
