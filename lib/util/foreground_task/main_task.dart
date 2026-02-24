import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/src/rust/frb_generated.dart';
import 'package:zephyr/util/download/download_queue_manager.dart';
import 'package:zephyr/util/download/platform/android_download_runner.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  late AndroidProgressReporter _reporter;
  final DownloadQueueManager _manager = DownloadQueueManager.instance;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    objectbox = await ObjectBox.create();
    await RustLib.init();
    final setting = objectbox.userSettingBox.get(1);
    final globalSetting = setting?.globalSetting;
    if (globalSetting?.socks5Proxy != null &&
        globalSetting!.socks5Proxy.isNotEmpty) {
      SocksProxy.initProxy(proxy: 'SOCKS5 ${globalSetting.socks5Proxy}');
    }

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
    _manager.watchTasksForAndroid(_reporter);
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    FlutterForegroundTask.updateService(
      notificationTitle: _reporter.comicName,
      notificationText: _reporter.message,
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    _manager.stopWatchingTasks();
  }

  @override
  void onReceiveData(Object data) {}

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'cancel') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {
    FlutterForegroundTask.stopService();
  }
}
