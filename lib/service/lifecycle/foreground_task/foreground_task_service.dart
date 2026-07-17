import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/service/download/download_queue_manager.dart';
import 'package:zephyr/service/lifecycle/foreground_task/foreground_task_handler.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/toast.dart';

/// Android 前台服务封装。
///
/// 该模块只负责前台服务的生命周期和通知栏展示，不涉及任何下载业务逻辑。
/// 下载与保活共用同一前台服务：
/// - 有下载任务时展示下载进度（可取消）
/// - 仅保活开启时展示保活文案（无取消按钮）
/// - 仅当两者都不需要时才真正停止服务
class ForegroundTaskService {
  ForegroundTaskService._();

  static final ForegroundTaskService instance = ForegroundTaskService._();

  bool _initialized = false;

  bool get _keepAliveEnabled =>
      Platform.isAndroid && globalSetting.androidKeepAliveEnabled;

  bool get _hasPendingDownloads =>
      DownloadQueueManager.instance.queueLength > 0;

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

  /// 应用冷启动后根据保活开关与下载队列同步前台服务。
  Future<void> syncOnAppStart() async {
    if (!Platform.isAndroid) return;
    if (!_keepAliveEnabled && !_hasPendingDownloads) return;
    await _ensureRunning(forDownload: _hasPendingDownloads);
  }

  /// 开启保活（设置开关打开时调用）。
  ///
  /// 若前台服务已在运行（例如已有下载任务），则不重复启动。
  Future<void> enableKeepAlive() async {
    if (!Platform.isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) {
      if (!_hasPendingDownloads) {
        await _applyKeepAliveNotification();
      }
      return;
    }
    await _ensureRunning(forDownload: _hasPendingDownloads);
  }

  /// 关闭保活（设置开关关闭时调用）。
  ///
  /// 若仍有下载/排队任务，则不停止前台服务，仅切回下载通知样式。
  Future<void> disableKeepAlive() async {
    if (!Platform.isAndroid) return;
    if (_hasPendingDownloads) {
      if (await FlutterForegroundTask.isRunningService) {
        await _applyDownloadNotification();
      }
      return;
    }
    await _stopService();
  }

  /// 启动前台服务（下载需要保活时调用）。
  ///
  /// 若服务已因保活运行，则跳过启动，仅更新为下载通知样式。
  Future<void> start() async {
    if (!Platform.isAndroid) return;
    if (await FlutterForegroundTask.isRunningService) {
      await _applyDownloadNotification();
      return;
    }
    await _ensureRunning(forDownload: true);
  }

  /// 停止前台服务（下载队列为空时调用）。
  ///
  /// 若保活开关仍开启，则不停止服务，仅更新为保活通知样式。
  Future<void> stop() async {
    if (!Platform.isAndroid) return;
    if (_keepAliveEnabled) {
      if (await FlutterForegroundTask.isRunningService) {
        await _applyKeepAliveNotification();
      }
      return;
    }
    await _stopService();
  }

  /// 更新前台服务通知栏内容（下载进度等）。
  Future<void> updateNotification(String title, String message) async {
    if (!Platform.isAndroid) return;
    if (!await FlutterForegroundTask.isRunningService) return;
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

  Future<void> _ensureRunning({required bool forDownload}) async {
    if (await FlutterForegroundTask.isRunningService) {
      if (forDownload) {
        await _applyDownloadNotification();
      } else {
        await _applyKeepAliveNotification();
      }
      return;
    }

    await _ensureNotificationPermission();

    final notificationText = forDownload
        ? t.foregroundTask.waitingForTask
        : t.foregroundTask.keepAliveRunning;
    final notificationButtons = forDownload
        ? [NotificationButton(id: 'cancel', text: t.foregroundTask.cancel)]
        : <NotificationButton>[];

    final ServiceRequestResult result =
        await FlutterForegroundTask.startService(
          serviceTypes: [ForegroundServiceTypes.dataSync],
          serviceId: Random().nextInt(1000),
          notificationTitle: appName,
          notificationText: notificationText,
          callback: startCallback,
          notificationButtons: notificationButtons,
        );

    if (result is ServiceRequestSuccess) {
      logger.i('前台服务启动成功 (download=$forDownload)');
    } else {
      String errorDetail = t.common.unknown;
      if (result is ServiceRequestFailure) {
        errorDetail = result.error.toString();
      }
      throw Exception(t.foregroundTask.startFailed(error: errorDetail));
    }
  }

  Future<void> _stopService() async {
    if (!await FlutterForegroundTask.isRunningService) return;
    await FlutterForegroundTask.stopService();
  }

  Future<void> _applyDownloadNotification() async {
    await FlutterForegroundTask.updateService(
      notificationTitle: appName,
      notificationText: t.foregroundTask.waitingForTask,
      notificationButtons: [
        NotificationButton(id: 'cancel', text: t.foregroundTask.cancel),
      ],
    );
  }

  Future<void> _applyKeepAliveNotification() async {
    await FlutterForegroundTask.updateService(
      notificationTitle: appName,
      notificationText: t.foregroundTask.keepAliveRunning,
      notificationButtons: const <NotificationButton>[],
    );
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
