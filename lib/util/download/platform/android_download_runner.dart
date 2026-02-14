import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:zephyr/util/download/download_progress_reporter.dart';

/// Android 前台服务下载进度报告实现
///
/// 在前台服务 Isolate 中运行，通过前台通知和系统通知报告进度。
class AndroidProgressReporter extends DownloadProgressReporter {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  AndroidProgressReporter(this._notificationsPlugin);

  @override
  Future<void> sendNotification(String title, String body) async {
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

    await _notificationsPlugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: 'download_complete',
    );
  }
}
