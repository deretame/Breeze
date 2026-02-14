import 'dart:io';
import 'dart:math';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zephyr/util/download/download_queue_manager.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/main_task.dart';

/// 统一的下载任务启动入口
///
/// Android 端：启动前台服务，通过 IPC 发送任务
/// 桌面端：直接将任务添加到 [DownloadQueueManager]
Future<void> startDownloadTask(DownloadTaskJson task) async {
  if (Platform.isAndroid) {
    await _startAndroidDownload(task);
  } else {
    _startDesktopDownload(task);
  }
}

/// Android 端：通过前台服务启动下载
Future<void> _startAndroidDownload(DownloadTaskJson task) async {
  final notificationPermission =
      await FlutterForegroundTask.checkNotificationPermission();
  if (notificationPermission != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }

  if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }

  if (!await FlutterForegroundTask.canScheduleExactAlarms) {
    await FlutterForegroundTask.openAlarmsAndRemindersSettings();
  }

  final String encodedTask = downloadTaskJsonToJson(task);

  if (await FlutterForegroundTask.isRunningService) {
    // 服务已在运行，直接发送新任务
    FlutterForegroundTask.sendDataToTask(encodedTask);
  } else {
    // 启动新的前台服务
    await FlutterForegroundTask.startService(
      serviceTypes: [ForegroundServiceTypes.dataSync],
      serviceId: Random().nextInt(1000),
      notificationTitle: '下载任务',
      notificationText: '${task.comicName} 下载中...',
      callback: startCallback,
      notificationButtons: [const NotificationButton(id: 'cancel', text: '取消')],
    );
    // 等待服务启动后发送任务
    await Future.delayed(const Duration(seconds: 1));
    FlutterForegroundTask.sendDataToTask(encodedTask);
  }
}

/// 桌面端：直接添加到队列管理器
void _startDesktopDownload(DownloadTaskJson task) {
  DownloadQueueManager.instance.addTask(task);
}
