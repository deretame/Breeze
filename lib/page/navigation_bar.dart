import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:toastification/toastification.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/ranking_list/ranking_list.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/auto_check_in.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/download/download_queue_manager.dart';
import 'package:zephyr/util/foreground_task/init.dart';
import 'package:zephyr/util/jm_url_set.dart';
import 'package:zephyr/util/manage_cache.dart';
import 'package:zephyr/util/memory/memory_overlay_widget.dart';
import 'package:zephyr/util/notice.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/update/check_update.dart';
import 'package:zephyr/widgets/toast.dart';

import '../config/global/global.dart';
import '../main.dart';
import '../network/webdav.dart';
import '../util/debouncer.dart';
import '../util/dialog.dart';
import '../util/event/event.dart';
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
      checkUpdate(context);
      bikaSignIn(context);
      jmLogin(context);
      _autoSync();
      manageCacheSize(context);
      resetDownloadTasks();
      if (Platform.isWindows ||
          Platform.isLinux ||
          Platform.isMacOS ||
          Platform.isIOS) {
        DownloadQueueManager.instance.watchTasks(isDesktop: true);
      } else if (Platform.isAndroid) {
        if (DownloadQueueManager.instance.queueLength > 0) {
          initDownloadTask();
        }
      }
    });
    _controller = PersistentTabController(
      initialIndex: objectbox.userSettingBox
          .get(1)!
          .globalSetting
          .welcomePageNum,
    );
    scrollControllers.forEach((key, value) {
      _scrollControllers.add(value);
    });
    hideOnScrollSettings = HideOnScrollSettings(
      scrollControllers: _scrollControllers,
    );
    hideOnScrollSettings = HideOnScrollSettings(); // 先去掉这个东西
    initForegroundTask();

    initializeNotificationsOnce();

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
        showSuccessToast("禁漫已自动选择最快线路");
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
    final globalSettingState = context.read<GlobalSettingCubit>().state;
    return MemoryOverlayWidget(
      enabled: globalSettingState.enableMemoryDebug,
      updateInterval: Duration(seconds: 1),
      child: Builder(
        builder: (context) {
          if (isTablet(context) ||
              Platform.isWindows ||
              Platform.isLinux ||
              Platform.isMacOS) {
            return _buildTabletLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
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

  Future<void> initializeNotificationsOnce() async {
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

      await initializeNotifications();

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
}
