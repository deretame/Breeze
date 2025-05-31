import 'dart:io';
import 'dart:math';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zephyr/util/foreground_task/main_task.dart';
import 'package:zephyr/widgets/toast.dart';

Future<void> initForegroundTask(String comicName) async {
  final notificationPermission =
      await FlutterForegroundTask.checkNotificationPermission();
  if (notificationPermission != NotificationPermission.granted) {
    await FlutterForegroundTask.requestNotificationPermission();
  }

  if (Platform.isAndroid) {
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    if (!await FlutterForegroundTask.canScheduleExactAlarms) {
      await FlutterForegroundTask.openAlarmsAndRemindersSettings();
    }
  }

  if (await FlutterForegroundTask.isRunningService) {
    throw Exception("已有下载任务进行中");
  } else {
    await FlutterForegroundTask.startService(
      serviceTypes: [ForegroundServiceTypes.dataSync],
      serviceId: Random().nextInt(1000),
      notificationTitle: '下载任务',
      notificationText: '$comicName 下载中...',
      callback: startCallback,
      notificationButtons: [const NotificationButton(id: 'cancel', text: '取消')],
    );
  }
}
