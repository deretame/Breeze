import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/download/download_progress_reporter.dart';

/// iOS 后台下载进度报告实现
///
/// 使用 flutter_local_notifications 发送系统通知，
/// 进度信息通过 [DownloadQueueManager] 的 Stream 传播给 UI。
class IOSProgressReporter extends DownloadProgressReporter {
  @override
  Future<void> sendNotification(String title, String body) async {
    try {
      const notificationDetails = NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      );

      await flutterLocalNotificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: 'download_complete',
      );
    } catch (e, s) {
      logger.e('iOS notification failed', error: e, stackTrace: s);
    }
  }
}
