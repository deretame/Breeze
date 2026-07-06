import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/service/download/download_progress_reporter.dart';

/// 三端统一的下载完成/失败通知 reporter。
///
/// 下载过程中的进度通知由调用方各自处理：
/// - Android：通过 [FlutterForegroundTask.updateService] 更新前台服务通知
/// - 桌面端 / iOS：通过 [DownloadQueueManager.progressStream] 传播给 UI
class DownloadNotificationReporter extends DownloadProgressReporter {
  final FlutterLocalNotificationsPlugin? _notificationsPlugin;

  DownloadNotificationReporter({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin = notificationsPlugin;

  FlutterLocalNotificationsPlugin get _plugin =>
      _notificationsPlugin ?? flutterLocalNotificationsPlugin;

  @override
  Future<void> sendNotification(String title, String body) async {
    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      payload: 'download_complete',
      notificationDetails: await _buildNotificationDetails(),
    );
  }

  Future<NotificationDetails> _buildNotificationDetails() async {
    if (Platform.isAndroid) {
      return const NotificationDetails(
        android: AndroidNotificationDetails(
          'download_complete',
          '下载完成通知',
          channelDescription: '下载完成通知',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      );
    }

    if (Platform.isWindows) {
      return const NotificationDetails(windows: WindowsNotificationDetails());
    }

    if (Platform.isLinux) {
      return const NotificationDetails(linux: LinuxNotificationDetails());
    }

    if (Platform.isMacOS || Platform.isIOS) {
      return const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      );
    }

    return const NotificationDetails();
  }
}
