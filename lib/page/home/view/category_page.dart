import 'dart:isolate';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../home_page.dart';

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
    // Isolate.spawn(downloadComic, "676ed5839a648f08d0c82731");
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
                      await installApk(apkUrl.browserDownloadUrl);
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

  void backDownloadThread(SendPort sendPort) {}
}
