import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/src/rust/frb_generated.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/task/bika_download.dart';
import 'package:zephyr/util/foreground_task/task/jm_download.dart';
import 'package:zephyr/widgets/toast.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  List<DownloadTaskJson> downloadTasksList = [];
  late DownloadTaskJson currentTask;
  late String comicName;
  late String comicId;
  String message = '';

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
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_isExecuting) {
      FlutterForegroundTask.updateService(
        notificationTitle: '$comicName 下载中...',
        notificationText: message,
      );
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onReceiveData(Object data) {
    final newTask = downloadTaskJsonFromJson(data as String);
    downloadTasksList.add(newTask);
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
    if (downloadTasksList.isEmpty) {
      _isExecuting = false;
      logger.d("所有任务完成，停止服务");
      FlutterForegroundTask.stopService();
      return;
    }

    _isExecuting = true;

    currentTask = downloadTasksList.removeAt(0);
    comicName = currentTask.comicName;

    showInfoToast("${currentTask.comicName} 开始下载");

    try {
      if (currentTask.from == "bika") {
        await bikaDownloadTask(this, currentTask);
      } else if (currentTask.from == "jm") {
        await jmDownloadTask(this, currentTask);
      } else {
        logger.w("未知任务来源: ${currentTask.from}");
      }

      logger.d("任务 $comicName 完成");
      await sendSystemNotification("下载完成", "$comicName 下载完成");
    } catch (e, s) {
      logger.e("任务 $comicName 失败", error: e, stackTrace: s);
      await sendSystemNotification("下载失败", "$comicName 下载失败");
    } finally {
      Future.microtask(() => _processQueue());
    }
  }

  Future<void> sendSystemNotification(String title, String body) async {
    const androidNotificationDetails = AndroidNotificationDetails(
      'download_complete',
      '下载完成通知',
      channelDescription: '下载完成通知',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: 'download_complete',
    );
  }
}
