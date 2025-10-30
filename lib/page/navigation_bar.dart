import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:markdown_widget/widget/markdown_block.dart';
import 'package:permission_guard/permission_guard.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/network/http/jm/http_request.dart' as jm;
import 'package:zephyr/page/more/json/jm/jm_user_info_json.dart';
import 'package:zephyr/page/ranking_list/ranking_list.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/main_task.dart';
import 'package:zephyr/util/jm_url_set.dart';
import 'package:zephyr/util/manage_cache.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/settings_hive_utils.dart';
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
  // _controller 用于控制手机底部导航栏和页面切换
  late PersistentTabController _controller;
  // _selectedIndex 用于控制平板侧边导航栏和页面切换
  int _selectedIndex = 0;
  final debouncer = Debouncer(milliseconds: 100);
  final List<ScrollController> _scrollControllers = [];
  late HideOnScrollSettings hideOnScrollSettings;

  static bool _notificationsInitialized = false; // ← 使用静态变量，跨实例共享
  bool _isInitializingNotifications = false;

  // 页面列表
  final _pageList = [
    HomePage(),
    RankingListPage(),
    BookshelfPage(),
    MorePage(),
  ];

  // OverlayEntry 用于管理遮罩层
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _addOverlay();
      _checkUpdate();
      _signIn();
      _jmLogin();
      _autoSync();
      manageCacheSize(context);
    });
    _controller = PersistentTabController(
      initialIndex: SettingsHiveUtils.welcomePageNum,
    );
    scrollControllers.forEach((key, value) {
      _scrollControllers.add(value);
    });
    hideOnScrollSettings = HideOnScrollSettings(
      scrollControllers: _scrollControllers,
    );
    hideOnScrollSettings = HideOnScrollSettings(); // 先去掉这个东西
    _initForegroundTask();
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    _initializeNotificationsOnce();

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

    Future.delayed(const Duration(seconds: 1), () async {
      try {
        await setFastestUrlIndex();
        await setFastestImagesUrlIndex();
      } catch (e) {
        logger.e(e);
      }
    });
  }

  @override
  void dispose() {
    _removeOverlay(); // 移除遮罩层
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isTablet(context)) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildMobileLayout() {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: _pageList,
      items: _navBarItems(),
      backgroundColor: context.backgroundColor,
      handleAndroidBackButtonPress: true,
      resizeToAvoidBottomInset: false,
      hideNavigationBarWhenKeyboardAppears: false,
      stateManagement: true,
      navBarStyle: NavBarStyle.style3,
      onItemSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  // 平板布局 (使用 NavigationRail)
  Widget _buildTabletLayout() {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: context.backgroundColor,
            destinations: _navRailDestinations(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: _pageList),
          ),
        ],
      ),
    );
  }

  void _addOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return BlocBuilder<GlobalSettingCubit, GlobalSettingState>(
          builder: (context, globalState) {
            final bool isDarkMode = !context.isLightMode;
            final bool shadeEnabled = globalState.shade;

            return Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  color: shadeEnabled && isDarkMode
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.transparent,
                ),
              ),
            );
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  // 移除遮罩层
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // 底部导航栏的配置项
  List<PersistentBottomNavBarItem> _navBarItems() {
    final activeColor = context.theme.colorScheme.primary;
    final inactiveColor = context.textColor;

    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.home),
        title: "首页",
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.leaderboard),
        title: "排行",
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.menu_book_sharp),
        title: "书架",
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.more_horiz),
        title: "更多",
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
    ];
  }

  // 为平板侧边导航栏生成 NavigationRailDestination
  List<NavigationRailDestination> _navRailDestinations() {
    return [
      NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text("首页"),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.leaderboard_outlined),
        selectedIcon: Icon(Icons.leaderboard),
        label: Text("排行"),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book_sharp),
        label: Text("书架"),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.more_horiz_outlined),
        selectedIcon: Icon(Icons.more_horiz),
        label: Text("更多"),
      ),
    ];
  }

  Future<void> _autoSync() async {
    final globalState = context.read<GlobalSettingCubit>().state;

    if (globalState.autoSync == false) {
      return;
    }

    if (globalState.webdavHost.isEmpty) {
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
      if (globalState.syncNotify) {
        showSuccessToast("自动同步成功！");
      }
    } catch (e) {
      logger.e(e.toString());
      showErrorToast("请检查网络连接或稍后再试。\n${e.toString()}", title: "自动同步失败");
    }
  }

  void _goToLoginPage(From from) {
    try {
      final navigator = Navigator.maybeOf(context); // ← 使用 maybeOf
      if (navigator == null) {
        logger.w('Navigator not available');
        return;
      }

      String allRoutes = "";
      for (final route in navigator.widget.pages) {
        // 安全访问 route.name
        final routeName = route.name ?? 'UnknownRoute'; // ← 处理 null
        allRoutes += "$routeName ";
      }

      logger.d('All routes: $allRoutes');

      debouncer.run(() {
        if (!allRoutes.contains('LoginRoute')) {
          showErrorToast('登录过期，请重新登录');

          // 确保 mounted
          if (mounted) {
            context.navigateTo(LoginRoute(from: from));
          }
        }
      });
    } catch (e, stackTrace) {
      logger.e('Failed to navigate to login', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _checkUpdate() async {
    final temp = await getCloudVersion();
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
                  launchUrl(Uri.parse(url));
                  context.pop();
                },
              ),
              TextButton(
                child: Text('下载安装'),
                onPressed: () async {
                  context.pop();
                  for (var apkUrl in temp.assets) {
                    if (apkUrl.browserDownloadUrl.contains(arch) &&
                        !apkUrl.browserDownloadUrl.contains("skia")) {
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
    final globalState = context.read<GlobalSettingCubit>().state;
    if (globalState.disableBika) return;

    if (!mounted) return;

    final bikaCubit = context.read<BikaSettingCubit>();

    while (true) {
      try {
        var result = await signIn();
        if (result == '签到成功') {
          showSuccessToast("哔咔自动签到成功！");

          bikaCubit.updateSignIn(true);

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

  Future<void> _initializeNotificationsOnce() async {
    // 应用级别检查
    if (_notificationsInitialized) {
      logger.d('Notifications already initialized globally');
      return;
    }

    // 实例级别检查
    if (_isInitializingNotifications) {
      logger.w('Notification initialization already in progress');
      return;
    }

    try {
      _isInitializingNotifications = true;

      // 延迟执行，避免与其他初始化冲突
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;

      await _initializeNotifications();

      _notificationsInitialized = true;
      logger.d('Notifications initialized successfully');
    } catch (e, stackTrace) {
      logger.e(
        'Failed to initialize notifications',
        error: e,
        stackTrace: stackTrace,
      );
    } finally {
      _isInitializingNotifications = false;
    }
  }

  Future<void> _initializeNotifications() async {
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
    // 先检查当前状态
    try {
      final currentStatus = await Permission.notification.status;

      if (currentStatus.isGranted) {
        logger.d('Notification permission already granted');
        return;
      }

      if (currentStatus.isPermanentlyDenied) {
        logger.w('Notification permission permanently denied');
        if (mounted) {
          showErrorToast("通知权限已被永久拒绝，请在系统设置中开启");
        }
        return;
      }
      // 只在需要时请求权限
      final status = await Permission.notification.request();

      if (!status.isGranted) {
        logger.w('Notification permission denied');
        if (mounted) {
          showErrorToast("请开启通知权限");
        }
      } else {
        logger.d('Notification permission granted');
      }
    } catch (e, stackTrace) {
      logger.e('Permission request failed', error: e, stackTrace: stackTrace);

      // 如果是并发冲突，静默处理
      if (e.toString().contains('already running')) {
        logger.w('Permission request already running, ignoring...');
      } else {
        rethrow;
      }
    }
  }

  Future<void> _jmLogin() async {
    final jmCubit = context.read<JmSettingCubit>();
    final jmState = jmCubit.state;

    if (jmState.account.isEmpty || jmState.password.isEmpty) {
      return;
    }

    jmCubit.updateUserInfo('');
    jmCubit.updateLoginStatus(LoginStatus.loggingIn);

    while (true) {
      try {
        final result = await jm.login(jmState.account, jmState.password);
        jmCubit.updateUserInfo(result.let(jsonEncode));
        jmCubit.updateLoginStatus(LoginStatus.login);

        await _jmSignIn(); // 登录成功后自动签到
        break;
      } catch (e, s) {
        logger.e(e, stackTrace: s);
        await Future.delayed(Duration(seconds: 1));
        continue;
      }
    }
  }

  Future<void> _jmSignIn() async {
    final jmCubit = context.read<JmSettingCubit>();
    final jmState = jmCubit.state;
    int retryCount = 0;
    const max = 3; // 最大重试次数
    while (true) {
      retryCount++;
      if (retryCount > max) {
        logger.d("签到失败");
        break;
      }

      try {
        var dailyList = await jm.getDailyList();
        final id = (List<Map<String, dynamic>>.from(
          dailyList['list'].map((item) => item as Map<String, dynamic>),
        ).last['id']);
        final userId = jmUserInfoJsonFromJson(jmState.userInfo).uid;
        int retryCount2 = 0;
        const max2 = 3; // 最大重试次数
        while (true) {
          try {
            if (retryCount2 > max2) {
              logger.e("签到失败");
              break;
            }
            final result = await jm.dailyChk(userId, id);
            logger.d(result);
            if (result['msg'] != '今天已经签到过了') {
              showSuccessToast("禁漫自动签到成功！");
            }
            break;
          } catch (e, s) {
            logger.e(e, stackTrace: s);
            await Future.delayed(Duration(seconds: 1));
            retryCount2++;
            continue;
          }
        }
        break;
      } catch (e, s) {
        logger.e(e, stackTrace: s);
        await Future.delayed(Duration(seconds: 5));
        retryCount++;
        continue;
      }
    }
  }
}
