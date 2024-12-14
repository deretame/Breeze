import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../bloc/get_category_bloc.dart';
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
      body: BlocBuilder<GetCategoryBloc, GetCategoryState>(
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
                  .where(
                      (category) => !(shieldCategoryMap[category.id] ?? false))
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
    );
  }

  // 获取应用的版本信息
  Future<String> getAppVersion() async {
    String version = 'Unknown';
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version; // 获取版本号
    });

    return version;
  }

  Future<Map<String, dynamic>> getCloudVersion() async {
    // 获取响应并提取 data 部分
    final response =
        await dio.get("https://api.github.com/repos/deretame/Breeze/releases");

    // 从 response.data 获取返回的列表数据，并将其转换为 List<Map<String, dynamic>>
    final List<Map<String, dynamic>> releases =
        List<Map<String, dynamic>>.from(response.data);

    // 返回版本号
    return {
      "cloudVersion": releases[0]['tag_name'] as String,
      "releaseInfo": releases[0]['body'] as String,
    };
  }

  bool isUpdateAvailable(String cloudVersion, String localVersion) {
    debugPrint('App version: $localVersion');
    debugPrint('Cloud version: $cloudVersion');

    // 去掉云端版本的前缀 'v'
    cloudVersion = cloudVersion.replaceFirst('v', '');

    // 将版本号划分为主要版本、次要版本和补丁版本
    final cloudVersionParts = cloudVersion.split('.');
    final localVersionParts = localVersion.split('.');

    // 比较版本号的每一部分
    for (int i = 0; i < 3; i++) {
      final int cloudPart = int.parse(cloudVersionParts[i]);
      final int localPart = int.parse(localVersionParts[i]);

      if (cloudPart > localPart) {
        return true; // 云端版本大于本地版本，表示需要更新
      } else if (cloudPart < localPart) {
        return false; // 本地版本大于云端版本，表示不需要更新
      }
    }

    return false; // 版本相同，不需要更新
  }

  Future<void> _checkUpdate() async {
    final temp = await getCloudVersion();
    final cloudVersion = temp['cloudVersion'] as String;
    final releaseInfo = temp['releaseInfo'] as String;
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
                child: Text('前往 GitHub'),
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
}
