import 'dart:async';

import 'package:zephyr/main.dart';
import 'package:zephyr/util/download/download_progress_reporter.dart';
import 'package:zephyr/util/download/platform/desktop_download_runner.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
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

  final List<DownloadTaskJson> _queue = [];
  bool _isProcessing = false;

  /// 进度 Stream，供 UI 监听
  final _progressController = StreamController<DownloadProgress>.broadcast();

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  /// 当前是否有任务在执行
  bool get isProcessing => _isProcessing;

  /// 队列中剩余任务数
  int get queueLength => _queue.length;

  /// 添加下载任务（桌面端入口）
  ///
  /// 在桌面端，直接调用此方法添加任务并开始处理。
  /// 在 Android 端，任务通过前台服务的 IPC 传入。
  void addTask(DownloadTaskJson task) {
    _queue.add(task);
    if (!_isProcessing) {
      _processQueueDesktop();
    }
  }

  /// 桌面端队列处理（直接在主线程异步执行）
  Future<void> _processQueueDesktop() async {
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }

    _isProcessing = true;

    // 确保 ObjectBox 和 RustLib 已初始化（桌面端应该在 main 中已经初始化过）
    // 这里不需要额外初始化

    final reporter = DesktopProgressReporter();
    final task = _queue.removeAt(0);
    reporter.comicName = task.comicName;

    _progressController.add(
      DownloadProgress(comicName: task.comicName, message: '开始下载...'),
    );

    showInfoToast("${task.comicName} 开始下载");

    try {
      if (task.from == "bika") {
        await bikaDownloadTask(reporter, task);
      } else if (task.from == "jm") {
        await jmDownloadTask(reporter, task);
      } else {
        logger.w("未知任务来源: ${task.from}");
      }

      logger.d("任务 ${task.comicName} 完成");
      _progressController.add(
        DownloadProgress(
          comicName: task.comicName,
          message: '下载完成',
          isCompleted: true,
        ),
      );
      await reporter.sendNotification("下载完成", "${task.comicName} 下载完成");
    } catch (e, s) {
      logger.e("任务 ${task.comicName} 失败", error: e, stackTrace: s);
      _progressController.add(
        DownloadProgress(
          comicName: task.comicName,
          message: '下载失败',
          isFailed: true,
        ),
      );
      await reporter.sendNotification("下载失败", "${task.comicName} 下载失败");
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
    if (_queue.isEmpty) {
      _isProcessing = false;
      return;
    }

    _isProcessing = true;

    final task = _queue.removeAt(0);
    reporter.comicName = task.comicName;

    showInfoToast("${task.comicName} 开始下载");

    try {
      if (task.from == "bika") {
        await bikaDownloadTask(reporter, task);
      } else if (task.from == "jm") {
        await jmDownloadTask(reporter, task);
      } else {
        logger.w("未知任务来源: ${task.from}");
      }

      logger.d("任务 ${task.comicName} 完成");
      await reporter.sendNotification("下载完成", "${task.comicName} 下载完成");
    } catch (e, s) {
      logger.e("任务 ${task.comicName} 失败", error: e, stackTrace: s);
      await reporter.sendNotification("下载失败", "${task.comicName} 下载失败");
    } finally {
      Future.microtask(() => processQueueWithReporter(reporter));
    }
  }

  /// 添加任务到队列（供 Android 前台服务使用）
  void addTaskForForeground(DownloadTaskJson task) {
    _queue.add(task);
  }

  void dispose() {
    _progressController.close();
  }
}
