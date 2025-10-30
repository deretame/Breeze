import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_guard/permission_guard.dart';

/// 动态请求存储权限
Future<bool> requestStoragePermission() async {
  if (!Platform.isAndroid) {
    // 如果不是安卓平台，直接返回 true
    return true;
  }

  // 1. 获取 Android SDK 版本
  final deviceInfo = await DeviceInfoPlugin().androidInfo;
  final sdkInt = deviceInfo.version.sdkInt;

  PermissionStatus status;

  if (sdkInt >= 30) {
    // Android 11 (API 30) 及以上
    // 请求 "所有文件访问" 权限
    status = await Permission.manageExternalStorage.request();
  } else {
    // Android 10 (API 29) 及以下
    // 请求老式的 "读写" 权限
    status = await Permission.storage.request();
  }

  return status.isGranted;
}
