import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_guard/permission_guard.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../../main.dart';
import 'json/github_release_json.dart';

Future<String> getAppVersion() async {
  String version = 'Unknown';

  try {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();

    version = packageInfo.version; // 获取版本号
  } catch (e, stackTrace) {
    logger.e(e, stackTrace: stackTrace);
  }

  return version;
}

Future<GithubReleaseJson> getCloudVersion() async {
  final response = await dio.get(
    "https://api.github.com/repos/deretame/Breeze/releases",
  );

  final List<Map<String, dynamic>> releases =
      List<Map<String, dynamic>>.from(response.data);

  return GithubReleaseJson.fromJson(releases[0]);
}

bool isUpdateAvailable(String cloudVersion, String localVersion) {
  debugPrint('App version: $localVersion');
  debugPrint('Cloud version: $cloudVersion');

  cloudVersion = cloudVersion.replaceFirst('v', '');

  final cloudVersionParts = cloudVersion.split('.');
  final localVersionParts = localVersion.split('.');

  for (int i = 0; i < 3; i++) {
    final int cloudPart = int.parse(cloudVersionParts[i]);
    final int localPart = int.parse(localVersionParts[i]);

    if (cloudPart > localPart) {
      return true;
    } else if (cloudPart < localPart) {
      return false;
    }
  }

  return false;
}

Future<void> installApk(String apkUrl) async {
  if (await _requestInstallPackagesPermission()) {
    try {
      // 使用 Dio 下载 APK 文件
      Response response = await Dio().get(
        apkUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // 获取应用的文档目录，存储 APK 文件
      Directory tempDir = await getTemporaryDirectory();
      String apkFilePath = '${tempDir.path}/app.apk';

      // 将下载的字节写入 APK 文件
      File apkFile = File(apkFilePath);
      await apkFile.writeAsBytes(response.data);

      // 打开 APK 文件以启动安装
      OpenFile.open(apkFilePath);
    } catch (e) {
      showErrorToast("下载失败，请稍后再试！");
    }
  } else {
    showErrorToast("请授予安装应用权限！");
  }
}

Future<bool> _requestInstallPackagesPermission() async {
  if (Platform.isAndroid) {
    var status = await Permission.requestInstallPackages.status;
    if (status.isGranted) {
      return true;
    } else if (status.isDenied) {
      var requestResult = await Permission.requestInstallPackages.request();
      return requestResult.isGranted;
    }
  }
  return false; // 仅考虑 Android 平台
}
