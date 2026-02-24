import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/util/download/download_queue_manager.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/main_task.dart';
import 'package:zephyr/widgets/toast.dart';

/// 统一的下载任务启动入口
///
/// Android 端：启动前台服务，通过 IPC 发送任务
/// 桌面端：直接将任务添加到 [DownloadQueueManager]
void startDownloadTask(DownloadTaskJson task) {
  _updateDb(task);
  if (Platform.isAndroid) {
    unawaited(_startAndroidDownload());
  }
}

/// Android 端：通过前台服务启动下载
Future<void> _startAndroidDownload() async {
  if (await FlutterForegroundTask.isRunningService) {
    return;
  }
  resetDownloadTasks();
  // 启动新的前台服务
  await initDownloadTask();
}

Future<void> initDownloadTask() async {
  if (!Platform.isAndroid) return;

  final notificationPermission =
      await FlutterForegroundTask.checkNotificationPermission();
  if (notificationPermission != NotificationPermission.granted) {
    try {
      await FlutterForegroundTask.requestNotificationPermission();
    } catch (e) {
      logger.w('Notification permission request failed: $e');
    }
  }

  if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }

  if (!await FlutterForegroundTask.canScheduleExactAlarms) {
    await FlutterForegroundTask.openAlarmsAndRemindersSettings();
  }

  FlutterForegroundTask.startService(
    serviceTypes: [ForegroundServiceTypes.dataSync],
    serviceId: Random().nextInt(1000),
    notificationTitle: appName,
    notificationText: '等待下载任务中...',
    callback: startCallback,
    notificationButtons: [const NotificationButton(id: 'cancel', text: '取消')],
  );

  FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
}

void _onReceiveTaskData(Object data) {
  showSuccessToast('$data 下载完毕');
}

void _updateDb(DownloadTaskJson task) {
  if (DownloadQueueManager.instance.taskExists(task.comicId)) {
    logger.w("任务 ${task.comicName} 已存在，跳过添加");
    showInfoToast("${task.comicName} 任务已存在");
    return;
  }

  final box = objectbox.downloadTaskBox;
  final downloadTask = DownloadTask();
  downloadTask
    ..comicId = task.comicId
    ..comicName = task.comicName
    ..isCompleted = false
    ..isDownloading = false
    ..status = "等待中"
    ..taskInfo = task;

  box.put(downloadTask);
}

void resetDownloadTasks() {
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
