import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as p;
import 'package:permission_guard/permission_guard.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/widgets/toast.dart';

Future<void> initForegroundTask() async {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: '前台任务',
      channelName: '前台下载任务',
      channelDescription: '这个是用来保证下载任务在后台也能继续执行的',
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
}

Future<void> initializeNotifications() async {
  const initializationSettingsAndroid = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );
  final appDirectory = await getAppDirectory();
  final windowsIconPath = p.join(
    appDirectory,
    'data',
    'flutter_assets',
    'asset',
    'image',
    'app-icon.png',
  );
  final initializationSettingsWindows = WindowsInitializationSettings(
    appName: 'Zephyr',
    appUserModelId: 'com.zephyr.breeze',
    guid: 'c4fce75a-b087-44bf-ac62-cc52b8e56990',
    iconPath: windowsIconPath,
  );
  final initializationSettingsLinux = LinuxInitializationSettings(
    defaultActionName: 'Open notification',
    defaultIcon: AssetsLinuxIcon('asset/image/app-icon.png'),
  );
  const initializationSettingsDarwin = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
    notificationCategories: [],
  );
  final initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    windows: initializationSettingsWindows,
    linux: initializationSettingsLinux,
    macOS: initializationSettingsDarwin,
  );
  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {},
  );
  if (Platform.isLinux) return;
  try {
    if (Platform.isMacOS) {
      final bool? granted = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      if (granted == true) {
        logger.d('macOS Notification permission granted');
      } else {
        logger.w('macOS Notification permission denied');
        showErrorToast("请在系统设置中开启通知权限");
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        showErrorToast("请开启通知权限");
      }
    }
  } catch (e, stackTrace) {
    logger.e('权限请求异常', error: e, stackTrace: stackTrace);
    if (!e.toString().contains('already running')) {
      rethrow;
    }
  }
}
