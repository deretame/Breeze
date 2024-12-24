import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_guard/permission_guard.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../bloc/get_category_bloc.dart';
import '../json/github_release_json/github_release_json.dart';
import '../models/category.dart';
import '../widgets/category.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({
    super.key,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('主页'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // 刷新数据
          context.read<GetCategoryBloc>().add(GetCategoryStarted());
        },
        child: BlocBuilder<GetCategoryBloc, GetCategoryState>(
          builder: (context, state) {
            switch (state.status) {
              case GetCategoryStatus.failure:
                if (state.result!.contains("1005") ||
                    state.result!.contains("401") ||
                    state.result!.contains("unauthorized") ||
                    bikaSetting.authorization == '') {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '登录状态无效，请重新登录',
                          style: TextStyle(fontSize: 20),
                        ),
                        SizedBox(height: 10), // 添加间距
                        ElevatedButton(
                          onPressed: () {
                            AutoRouter.of(context).push(LoginRoute());
                          },
                          child: Text('前往登录'),
                        ),
                      ],
                    ),
                  );
                }
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(state.result!),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<GetCategoryBloc>()
                              .add(GetCategoryStarted());
                        },
                        child: const Text('重新加载'),
                      ),
                    ],
                  ),
                );
              case GetCategoryStatus.success:
                final Map<String, bool> shieldCategoryMap =
                    bikaSetting.shieldCategoryMap;

                List<HomeCategory> homeCategories = state.categories!
                    .where((category) =>
                        !(shieldCategoryMap[category.id] ?? false))
                    .toList();
                // 构建并返回组件
                var rows = buildCategoriesWidget(homeCategories);
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      ...rows,
                      SizedBox(
                        height: 50,
                      ),
                    ],
                  ),
                );

              case GetCategoryStatus.initial:
                return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  // 其他方法保持不变
  // 获取应用的版本信息
  Future<String> getAppVersion() async {
    String version = 'Unknown';
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version; // 获取版本号
    });

    return version;
  }

  Future<GithubReleaseJson> getCloudVersion() async {
    final response =
        await dio.get("https://api.github.com/repos/deretame/Breeze/releases");

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

  Future<void> _checkUpdate() async {
    final temp = await getCloudVersion();
    final cloudVersion = temp.tagName;
    final releaseInfo = temp.body;
    final String localVersion = await getAppVersion();

    if (isUpdateAvailable(cloudVersion, localVersion)) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('发现新版本'),
            content: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: globalSetting.textColor,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: '$cloudVersion\n$releaseInfo\n\n如果不知道下载什么版本请选择\n',
                  ),
                  TextSpan(
                    text: 'app-arm64-v8a-release.apk',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // 加粗
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('下载安装'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  for (var apkUrl in temp.assets) {
                    if (apkUrl.browserDownloadUrl
                        .contains("app-arm64-v8a-release.apk")) {
                      await _installApk(apkUrl.browserDownloadUrl);
                    }
                  }
                },
              ),
              TextButton(
                child: Text('前往GitHub'),
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                      'https://github.com/deretame/Breeze/releases/tag/$cloudVersion',
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('取消'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _installApk(String apkUrl) async {
    if (await _requestInstallPackagesPermission()) {
      try {
        // 使用 Dio 下载 APK 文件
        Response response = await Dio().get(
          apkUrl,
          options: Options(responseType: ResponseType.bytes), // 将响应类型设置为字节
        );

        // 获取应用的文档目录，存储 APK 文件
        Directory tempDir = await getTemporaryDirectory();
        String apkFilePath = '${tempDir.path}/your-app.apk'; // 文件名可以自定义

        // 将下载的字节写入 APK 文件
        File apkFile = File(apkFilePath);
        await apkFile.writeAsBytes(response.data);

        // 打开 APK 文件以启动安装
        OpenFile.open(apkFilePath);
      } catch (e) {
        EasyLoading.showError('下载失败，请稍后再试！');
      }
    } else {
      EasyLoading.showError('请授予安装应用权限！');
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
}
