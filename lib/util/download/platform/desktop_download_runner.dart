import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/download/download_progress_reporter.dart';

/// 桌面端下载进度报告实现
///
/// 使用 flutter_local_notifications 发送系统通知，
/// 进度信息通过 [DownloadQueueManager] 的 Stream 传播给 UI。
class DesktopProgressReporter extends DownloadProgressReporter {
  @override
  Future<void> sendNotification(String title, String body) async {
    try {
      NotificationDetails? notificationDetails;

      if (Platform.isWindows) {
        notificationDetails = const NotificationDetails(
          windows: WindowsNotificationDetails(),
        );
      } else if (Platform.isLinux) {
        notificationDetails = const NotificationDetails(
          linux: LinuxNotificationDetails(),
        );
      } else if (Platform.isMacOS) {
        notificationDetails = const NotificationDetails(
          macOS: DarwinNotificationDetails(),
        );
      }

      if (notificationDetails != null) {
        await flutterLocalNotificationsPlugin.show(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          notificationDetails: notificationDetails,
          payload: 'download_complete',
        );
      }
    } catch (e, s) {
      logger.e('Desktop notification failed', error: e, stackTrace: s);
    }
  }
}
