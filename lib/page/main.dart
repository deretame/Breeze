import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/page/ranking_list/ranking_list.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/toast.dart';

import '../main.dart';
import '../network/http/http_request.dart';
import '../network/webdav.dart';
import '../util/dialog.dart';
import '../util/update/check_update.dart';
import 'bookshelf/bookshelf.dart';
import 'category/view/category.dart';
import 'more/view/more.dart';

class NoticeSync {}

class NeedLogin {}

@RoutePage()
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final bikaSetting = BikaSetting();

  // PersistentTabController 用于控制底部导航栏
  final PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);

  StreamSubscription<NoticeSync>? _subscription;

  // 页面列表
  final List<Widget> _pageList = [
    BookshelfPage(),
    RankingListPage(),
    CategoryPage(),
    MorePage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkUpdate();
    _signIn();
    // 先执行一次
    _autoSync();

    // 每隔 5 分钟执行一次
    const duration = Duration(minutes: 5);
    Timer.periodic(duration, (Timer timer) async {
      await _autoSync();
    });

    // 用来手动触发同步
    _subscription = eventBus.on<NoticeSync>().listen((event) {
      _autoSync();
    });

    eventBus.on<NeedLogin>().listen((event) {
      _goToLoginPage();
    });

    eventBus.on<ToastEvent>().listen((event) {
      _showToast(event);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(builder: (context) {
      debugPrint("surfaceBright = ${materialColorScheme.surfaceBright}");
      return PersistentTabView(
        context,
        controller: _controller,
        // 页面列表
        screens: _pageList,
        // 导航栏项
        items: _navBarItems(),
        // 导航栏背景颜色
        backgroundColor: globalSetting.backgroundColor,
        // 处理 Android 返回按钮
        handleAndroidBackButtonPress: true,
        // 调整布局以避免键盘遮挡
        resizeToAvoidBottomInset: false,
        // 避免在键盘弹出时隐藏导航栏
        hideNavigationBarWhenKeyboardAppears: false,
        // 保持页面状态
        stateManagement: true,
        // decoration: NavBarDecoration(
        //   // borderRadius: BorderRadius.circular(10.0), // 导航栏圆角
        //   colorBehindNavBar: globalSetting.backgroundColor, // 导航栏后面的颜色
        // ),
        navBarStyle: NavBarStyle.style3, // 导航栏样式
      );
    });
  }

  // 底部导航栏的配置项
  List<PersistentBottomNavBarItem> _navBarItems() {
    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.menu_book_sharp),
        title: "书架",
        activeColorPrimary: materialColorScheme.primary,
        inactiveColorPrimary: globalSetting.textColor,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.leaderboard),
        title: "排行",
        activeColorPrimary: materialColorScheme.primary,
        inactiveColorPrimary: globalSetting.textColor,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.class_outlined),
        title: "分类",
        activeColorPrimary: materialColorScheme.primary,
        inactiveColorPrimary: globalSetting.textColor,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.more_horiz),
        title: "跟多",
        activeColorPrimary: materialColorScheme.primary,
        inactiveColorPrimary: globalSetting.textColor,
      ),
    ];
  }

  Future<void> _autoSync() async {
    if (globalSetting.autoSync == false) {
      return;
    }

    if (globalSetting.webdavHost.isEmpty) {
      return;
    }

    try {
      await testWebDavServer();
      await createParentDirectory('/Breeze');
      var files = await fetchWebDAVFiles();
      if (files.isNotEmpty) {
        var needDownloadUrl = await getNeedDownloadUrl(files);
        if (needDownloadUrl.isNotEmpty) {
          var historyFromWebdav = await getHistoryFromWebdav(needDownloadUrl);
          await updateHistory(historyFromWebdav);
        }
      }
      await uploadFile2WebDav();
      await deleteFileFromWebDav(files);
      if (globalSetting.syncNotify) {
        showSuccessToast("自动同步成功！");
      }
    } catch (e) {
      debugPrint(e.toString());
      if (!mounted) return;
      commonDialog(
        context,
        "自动同步失败",
        "请检查网络连接或稍后再试。\n${e.toString()}",
      );
    }
  }

  void _goToLoginPage() {
    final route = AutoRouter.of(context);
    route.push(const LoginRoute());
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
            content: SingleChildScrollView(
              child: SizedBox(
                width: double.maxFinite, // 设置最大宽度
                child: MarkdownBody(
                  data: '# $cloudVersion\n$releaseInfo',
                ),
              ),
            ),
            actions: [
              TextButton(
                child: Text('取消'),
                onPressed: () {
                  Navigator.of(context).pop();
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
            ],
          );
        },
      );
    }
  }

  void _showToast(ToastEvent event) {
    ToastificationType type;
    switch (event.type) {
      case ToastType.success:
        type = ToastificationType.success;
        break;
      case ToastType.error:
        type = ToastificationType.error;
        break;
      case ToastType.warning:
        type = ToastificationType.warning;
        break;
      case ToastType.info:
        type = ToastificationType.info;
        break;
    }

    toastification.show(
      context: context,
      title: event.title == null ? null : Text(event.title!),
      description: Text(event.message),
      type: type,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: event.duration,
    );
  }
}

Future<void> _signIn() async {
  if (bikaSetting.getAuthorization().isEmpty) {
    return;
  }

  // 获取当前时间
  DateTime now = DateTime.now();

  // 获取今天的日期
  DateTime today = DateTime(now.year, now.month, now.day); // 获取凌晨的时间

  if (!bikaSetting.getSignInTime().isBefore(today)) {
    debugPrint("今天已经签到过了！");
    return;
  }

  // 重置签到状态
  bikaSetting.setSignIn(false);

  while (true) {
    try {
      var result = await signIn();
      if (result.toString().contains("success")) {
        bikaSetting.setSignInTime(DateTime.now());
        bikaSetting.setSignIn(true);
        showSuccessToast("自动签到成功！");
        debugPrint("自动签到成功！");
        break;
      } else {
        break;
      }
    } catch (e) {
      debugPrint(e.toString());
      continue;
    }
  }
}
