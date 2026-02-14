import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/src/rust/frb_generated.dart';
import 'package:zephyr/util/download/download_queue_manager.dart';
import 'package:zephyr/util/download/platform/android_download_runner.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  late AndroidProgressReporter _reporter;
  final DownloadQueueManager _manager = DownloadQueueManager.instance;
  final Completer<void> _initCompleter = Completer<void>();

  bool _isExecuting = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    objectbox = await ObjectBox.create();
    await RustLib.init();
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {},
    );
    _reporter = AndroidProgressReporter(flutterLocalNotificationsPlugin);
    _initCompleter.complete();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_isExecuting && _initCompleter.isCompleted) {
      FlutterForegroundTask.updateService(
        notificationTitle: '${_reporter.comicName} 下载中...',
        notificationText: _reporter.message,
      );
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    final newTask = downloadTaskJsonFromJson(data as String);
    _manager.addTaskForForeground(newTask);
    if (!_isExecuting) {
      _processQueue();
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'cancel') {
      FlutterForegroundTask.sendDataToMain("clear");
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {
    FlutterForegroundTask.sendDataToMain("clear");
    FlutterForegroundTask.stopService();
  }

  Future<void> _processQueue() async {
    // Wait for onStart initialization to complete before accessing _reporter
    await _initCompleter.future;

    if (_manager.queueLength == 0) {
      _isExecuting = false;
      logger.d("所有任务完成，停止服务");
      FlutterForegroundTask.stopService();
      return;
    }

    _isExecuting = true;

    while (_manager.queueLength > 0) {
      await _manager.processQueueWithReporter(_reporter);
    }

    _isExecuting = false;
    logger.d("所有任务完成，停止服务");
    FlutterForegroundTask.stopService();
  }
}
