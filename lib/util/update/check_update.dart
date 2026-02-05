import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_guard/permission_guard.dart';
import 'package:zephyr/type/pipe.dart';
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
  Future<String> createUserAgent() async {
    // 1. 获取 App 信息 (Breeze/1.0.0)
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String appName = packageInfo.appName;
    String version = packageInfo.version;

    // 2. 获取设备信息
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String systemName = Platform.isAndroid ? "Android" : "iOS";
    String? systemVersion;
    String? model;

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      systemVersion = androidInfo.version.release; // 例如: 13
      model = androidInfo.model; // 例如: Pixel 6
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      systemVersion = iosInfo.systemVersion; // 例如: 16.4
      model = iosInfo.utsname.machine; // 例如: iPhone14,2
    }

    // 3. 拼接结果: Breeze/1.0.0 (Android 13; Pixel 6)
    return "$appName/$version ($systemName $systemVersion; $model)";
  }

  while (true) {
    try {
      final response = await Dio()
          .get(
            "https://api.github.com/repos/deretame/Breeze/releases",
            options: Options(
              headers: {
                'User-Agent': await createUserAgent(),
                'Accept': 'application/vnd.github.v3+json',
              },
            ),
          )
          .let((d) => d.data)
          .let(jsonEncode)
          .let(githubReleaseJsonFromJson)
          .let((d) => d[0]);

      return response;
    } catch (e) {
      logger.e(e);
      await Future.delayed(const Duration(minutes: 5));
    }
  }
}

bool isUpdateAvailable(String cloudVersion, String localVersion) {
  logger.d('App version: $localVersion\nCloud version: $cloudVersion');

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
      Response response = await dio.get(
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
