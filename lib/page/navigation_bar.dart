import 'dart:async';
import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:permission_guard/permission_guard.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/network/http/jm/http_request.dart' as jm;
import 'package:zephyr/page/more/json/jm/jm_user_info_json.dart';
import 'package:zephyr/page/ranking_list/ranking_list.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/main_task.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/toast.dart';

import '../config/global/global.dart';
import '../main.dart';
import '../network/http/bika/http_request.dart';
import '../network/webdav.dart';
import '../util/debouncer.dart';
import '../util/dialog.dart';
import '../util/event/event.dart';
import '../util/update/check_update.dart';
import 'bookshelf/bookshelf.dart';
import 'home/view/home.dart';
import 'more/view/more.dart';

@RoutePage()
class NavigationBar extends StatefulWidget {
  const NavigationBar({super.key});

  @override
  State<NavigationBar> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  // PersistentTabController 用于控制底部导航栏
  final _controller = PersistentTabController(
    initialIndex: globalSetting.welcomePageNum,
  );
  final debouncer = Debouncer(milliseconds: 100);
  final List<ScrollController> _scrollControllers = [];
  late HideOnScrollSettings hideOnScrollSettings;

  // 页面列表
  final _pageList = [
    BookshelfPage(),
    RankingListPage(),
    HomePage(),
    MorePage(),
  ];

  // OverlayEntry 用于管理遮罩层
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    scrollControllers.forEach((key, value) {
      _scrollControllers.add(value);
    });
    hideOnScrollSettings = HideOnScrollSettings(
      scrollControllers: _scrollControllers,
    );
    hideOnScrollSettings = HideOnScrollSettings(); // 先去掉这个东西
    _checkUpdate();
    _signIn();
    _jmLogin();
    _jmSignIn();
    // 先执行一次
    _autoSync();
    _initForegroundTask();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    // 每隔 5 分钟执行一次
    const duration = Duration(minutes: 5);
    Timer.periodic(duration, (Timer timer) async {
      await _autoSync();
    });

    // 用来手动触发同步
    eventBus.on<NoticeSync>().listen((event) {
      _autoSync();
    });

    eventBus.on<NeedLogin>().listen((event) {
      _goToLoginPage(event.from);
    });

    eventBus.on<ToastEvent>().listen((event) {
      _showToast(event);
    });

    // 添加遮罩层
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addOverlay();
    });

    initializeNotifications();
  }

  @override
  void dispose() {
    _removeOverlay(); // 移除遮罩层
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
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
          navBarStyle: NavBarStyle.style3,
          // 导航栏样式
          hideOnScrollSettings: hideOnScrollSettings,
          // 自动隐藏导航栏
        );
      },
    );
  }

  // 添加遮罩层
  void _addOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Observer(
          builder:
              (context) => Positioned.fill(
                child: IgnorePointer(
                  ignoring: true, // 不拦截触控事件
                  child: Container(
                    color:
                        globalSetting.shade && !globalSetting.themeType
                            ? Colors.black.withValues(alpha: 0.5)
                            : Colors.transparent,
                  ),
                ),
              ),
        );
      },
    );

    // 将遮罩层插入到 Overlay 中
    Overlay.of(context).insert(_overlayEntry!);
  }

  // 移除遮罩层
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
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
        icon: Icon(Icons.category),
        title: "分类",
        activeColorPrimary: materialColorScheme.primary,
        inactiveColorPrimary: globalSetting.textColor,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.more_horiz),
        title: "更多",
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
      await createParentDirectory('/$appName');
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
      logger.e(e.toString());
      showErrorToast("请检查网络连接或稍后再试。\n${e.toString()}", title: "自动同步失败");
    }
  }

  void _goToLoginPage(From from) {
    String allRoutes = "";
    Navigator.of(context).widget.pages.forEach((route) {
      allRoutes += "${route.name} ";
    });
    // logger.d(allRoutes);
    debouncer.run(() {
      if (!allRoutes.contains('LoginRoute')) {
        showErrorToast('登录过期，请重新登录');
        context.navigateTo(LoginRoute(from: from));
      }
    });
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
              child: MarkdownBlock(data: '# $cloudVersion\n$releaseInfo'),
            ),
            actions: [
              TextButton(child: Text('取消'), onPressed: () => context.pop()),
              TextButton(
                child: Text('前往GitHub'),
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                      'https://github.com/deretame/Breeze/releases/tag/$cloudVersion',
                    ),
                  );
                  context.pop();
                },
              ),
              TextButton(
                child: Text('下载安装'),
                onPressed: () async {
                  context.pop();
                  for (var apkUrl in temp.assets) {
                    if (apkUrl.browserDownloadUrl.contains(
                      "app-arm64-v8a-release.apk",
                    )) {
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

    if (event.message.runes.length < 30) {
      toastification.show(
        context: context,
        title: event.title == null ? null : Text(event.title!),
        description: Text(event.message),
        type: type,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: event.duration,
        showProgressBar: true,
      );
    } else {
      late String title;
      if (event.title != null) {
        title = event.title!;
      } else {
        switch (event.type) {
          case ToastType.success:
            title = "成功";
            break;
          case ToastType.error:
            title = "错误";
            break;
          case ToastType.warning:
            title = "警告";
            break;
          case ToastType.info:
            title = "提示";
            break;
        }
      }
      commonDialog(context, title, event.message);
    }
  }

  Future<void> _signIn() async {
    while (true) {
      try {
        var result = await signIn();
        if (result == '签到成功') {
          showSuccessToast("哔咔自动签到成功！");
          bikaSetting.setSignIn(true);
          break;
        } else {
          logger.d(result);
          break;
        }
      } catch (e) {
        logger.e(e);
        await Future.delayed(Duration(seconds: 1));
        continue;
      }
    }
  }

  Future<void> _initForegroundTask() async {
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

  void _onReceiveTaskData(Object data) {
    if (data as String == "clear") {
      downloadTasks.clear();
      return;
    }

    showSuccessToast("${downloadTaskJsonFromJson(data).comicName}下载完成");
    downloadTasks.remove(data);
    logger.d(downloadTasks);
    if (downloadTasks.isEmpty) {
      FlutterForegroundTask.stopService();
    } else {
      showInfoToast(
        "${downloadTaskJsonFromJson(downloadTasks.first).comicName}开始下载",
      );
      FlutterForegroundTask.sendDataToTask(downloadTasks.first);
    }
  }

  Future<void> initializeNotifications() async {
    const initializationSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {},
    );

    final status = await Permission.notification.request();
    if (!status.isGranted) {
      showErrorToast("请开启通知权限");
      return;
    }
  }

  Future<void> _jmLogin() async {
    if (jmSetting.account.isEmpty || jmSetting.password.isEmpty) {
      return;
    }
    jmSetting.setUserInfo('');
    jmSetting.setLoginStatus(LoginStatus.loggingIn);

    while (true) {
      try {
        final result = await jm.login(jmSetting.account, jmSetting.password);
        jmSetting.setUserInfo(result.let(jsonEncode));
        jmSetting.setLoginStatus(LoginStatus.login);
        break;
      } catch (e, s) {
        logger.e(e, stackTrace: s);
        await Future.delayed(Duration(seconds: 1));
        continue;
      }
    }
  }

  Future<void> _jmSignIn() async {
    while (true) {
      if (jmSetting.loginStatus != LoginStatus.login) {
        await Future.delayed(Duration(seconds: 1));
        continue;
      }
      try {
        var dailyList = await jm.getDailyList();
        final id =
            (List<Map<String, dynamic>>.from(
              dailyList['list'].map((item) => item as Map<String, dynamic>),
            ).last['id']);
        final userId = jmUserInfoJsonFromJson(jmSetting.userInfo).uid;
        while (true) {
          try {
            final result = await jm.dailyChk(userId, id);
            logger.d(result);
            if (result['msg'] != '今天已经签到过了') {
              showSuccessToast("禁漫自动签到成功！");
            }
            break;
          } catch (e, s) {
            logger.e(e, stackTrace: s);
            await Future.delayed(Duration(seconds: 1));
            continue;
          }
        }
        break;
      } catch (e, s) {
        logger.e(e, stackTrace: s);
        await Future.delayed(Duration(seconds: 1));
        continue;
      }
    }
  }
}
