import 'dart:async';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/page/ranking_list/ranking_list.dart';
import 'package:zephyr/page/user_profile/view/view.dart';

import '../main.dart';
import '../network/http/http_request.dart';
import '../network/webdav.dart';
import '../util/dialog.dart';
import 'home/view/home.dart';
import 'search/search_page.dart';
import 'setting/setting_page.dart';

class NoticeSync {}

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
    HomePage(),
    RankingListPage(),
    SearchPage(),
    UserInfoPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
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
        resizeToAvoidBottomInset: true,
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
        icon: Icon(Icons.home),
        title: "首页",
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
        icon: Icon(Icons.search),
        title: "搜索",
        activeColorPrimary: materialColorScheme.primary,
        inactiveColorPrimary: globalSetting.textColor,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.person),
        title: "个人",
        activeColorPrimary: materialColorScheme.primary,
        inactiveColorPrimary: globalSetting.textColor,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.settings),
        title: "设置",
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
        var historyFromWebdav = await getHistoryFromWebdav(needDownloadUrl);
        await updateHistory(historyFromWebdav);
      }
      await uploadFile2WebDav();
      await deleteFileFromWebDav(files);
      EasyLoading.showSuccess("自动同步成功！");
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
        EasyLoading.showSuccess("自动签到成功！");
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
