import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/service/download/download_queue_manager.dart';
import 'package:zephyr/service/lifecycle/foreground_task/foreground_task_handler.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/toast.dart';

/// Android 前台服务封装。
///
/// 该模块只负责前台服务的生命周期和通知栏展示，不涉及任何下载业务逻辑。
/// 下载进度、任务取消等事件由 [DownloadQueueManager] 处理，本模块仅在需要时
/// 把进度转发给前台服务以更新通知，并把通知栏上的取消操作转发给下载管理器。
class ForegroundTaskService {
  ForegroundTaskService._();

  static final ForegroundTaskService instance = ForegroundTaskService._();

  bool _initialized = false;

  /// 初始化前台任务配置。应用启动时调用一次即可。
  void init() {
    if (_initialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_download_task',
        channelName: t.foregroundTask.channelName,
        channelDescription: t.foregroundTask.channelDescription,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    _initialized = true;
  }

  /// 启动前台服务（Android）。
  ///
  /// 由主 Isolate 在确认有下载任务需要保活时调用。
  Future<void> start() async {
    if (!Platform.isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) return;

    await _ensureNotificationPermission();

    final ServiceRequestResult result =
        await FlutterForegroundTask.startService(
          serviceTypes: [ForegroundServiceTypes.dataSync],
          serviceId: Random().nextInt(1000),
          notificationTitle: appName,
          notificationText: t.foregroundTask.waitingForTask,
          callback: startCallback,
          notificationButtons: [
            NotificationButton(id: 'cancel', text: t.foregroundTask.cancel),
          ],
        );

    if (result is ServiceRequestSuccess) {
      logger.i('前台服务启动成功');
    } else {
      String errorDetail = t.common.unknown;
      if (result is ServiceRequestFailure) {
        errorDetail = result.error.toString();
      }
      throw Exception(t.foregroundTask.startFailed(error: errorDetail));
    }
  }

  /// 停止前台服务（Android）。
  ///
  /// 由主 Isolate 在确认没有下载任务需要保活时调用。
  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    await FlutterForegroundTask.stopService();
  }

  /// 更新前台服务通知栏内容。
  Future<void> updateNotification(String title, String message) async {
    if (!Platform.isAndroid) return;
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: message,
    );
  }

  /// 监听前台服务发送给主 Isolate 的事件（如取消下载），
  /// 并把下载进度同步到前台服务通知。
  ///
  /// 应在主 Isolate 应用启动后调用一次。
  void listenEvents() {
    if (!Platform.isAndroid) return;

    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    DownloadQueueManager.instance.progressStream.listen((progress) {
      FlutterForegroundTask.sendDataToTask(
        jsonEncode({'title': progress.comicName, 'message': progress.message}),
      );
    });
  }

  Future<void> _ensureNotificationPermission() async {
    if (!Platform.isAndroid) return;

    NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();

    if (notificationPermission == NotificationPermission.granted) {
      return;
    }

    showInfoToast(t.foregroundTask.notificationPermissionRequired);

    notificationPermission =
        await FlutterForegroundTask.requestNotificationPermission();

    if (notificationPermission != NotificationPermission.granted) {
      throw Exception(t.foregroundTask.cannotStartWithoutPermission);
    }
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map && data['action'] == 'cancel_download') {
      DownloadQueueManager.instance.cancelCurrentTask();
    }
  }
}
