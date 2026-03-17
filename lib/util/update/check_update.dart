import 'dart:convert';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:zephyr/util/ui/fluent_compat.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:permission_guard/permission_guard.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/update/github_update_accelerator.dart';
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

Future<GithubReleaseJson> getCloudVersion({
  GithubUpdateAccelerationSession? accelerator,
}) async {
  const releasesApi = "https://api.github.com/repos/deretame/Breeze/releases";

  while (true) {
    try {
      final activeAccelerator =
          accelerator ??
          GithubUpdateAccelerator.createSession(
            enabled: globalSetting.updateAccelerate,
          );

      try {
        await activeAccelerator.prepare();
      } catch (e, stackTrace) {
        logger.w('检查更新 API 加速不可用，回退直连', error: e, stackTrace: stackTrace);
      }

      final userAgent = await GithubUpdateAccelerator.createGithubUserAgent();
      final requestUrls = activeAccelerator.requestCandidates(releasesApi);

      Object? lastError;
      for (final requestUrl in requestUrls) {
        try {
          final response = await Dio()
              .get(
                requestUrl,
                options: Options(
                  headers: {
                    'User-Agent': userAgent,
                    'Accept': 'application/vnd.github.v3+json',
                  },
                ),
              )
              .let((d) => d.data)
              .let(jsonEncode)
              .let(githubReleaseJsonFromJson)
              .let((d) => d[0]);

          return response;
        } catch (e, stackTrace) {
          lastError = e;
          logger.w('获取云端版本失败: $requestUrl', error: e, stackTrace: stackTrace);
        }
      }

      throw lastError ?? Exception('无法获取云端版本信息');
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
      String tempDir = await getCachePath();
      String apkFilePath = p.join(tempDir, 'app.apk');

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

Future<void> checkUpdate(BuildContext context) async {
  if (!context.mounted) return;
  final accelerator = GithubUpdateAccelerator.createSession(
    enabled: context.read<GlobalSettingCubit>().state.updateAccelerate,
  );
  final temp = await getCloudVersion(accelerator: accelerator);
  final cloudVersion = temp.tagName;
  final releaseInfo = temp.body;
  final String localVersion = await getAppVersion();
  final url = 'https://github.com/deretame/Breeze/releases/tag/$cloudVersion';
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String arch = '未知';
  try {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      List<String> abis = androidInfo.supportedAbis;
      if (abis.isNotEmpty) {
        arch = abis.first;
        logger.d(arch);
      }
    }
  } catch (e) {
    logger.e(e);
    return;
  }

  if (isUpdateAvailable(cloudVersion, localVersion)) {
    if (!context.mounted) return;
    var releaseNotes = accelerator.accelerateMarkdown(releaseInfo);
    var releasePageUrl = accelerator.accelerateIfGithub(url);

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('发现新版本'),
          content: SingleChildScrollView(
            child: MarkdownBlock(data: '# $cloudVersion\n$releaseNotes'),
          ),
          actions: [
            TextButton(child: Text('取消'), onPressed: () => context.pop()),
            TextButton(
              child: Text('前往GitHub'),
              onPressed: () {
                launchUrl(Uri.parse(releasePageUrl));
                context.pop();
              },
            ),
            if (Platform.isAndroid)
              TextButton(
                child: Text('下载安装'),
                onPressed: () async {
                  context.pop();
                  for (var apkUrl in temp.assets) {
                    if (apkUrl.browserDownloadUrl.contains(arch) &&
                        !apkUrl.browserDownloadUrl.contains("skia")) {
                      var androidDownloadUrl = apkUrl.browserDownloadUrl;
                      androidDownloadUrl = accelerator.accelerateIfGithub(
                        androidDownloadUrl,
                      );
                      await installApk(androidDownloadUrl);
                    }
                  }
                },
              ),
          ],
        );
      },
    );
  }
}


