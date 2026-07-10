import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:toastification/toastification.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/service/download/download_queue_manager.dart';
import 'package:zephyr/page/comic_follow/cubit/comic_follow_cubit.dart';
import 'package:zephyr/service/lifecycle/foreground_task/foreground_task_service.dart';
import 'package:zephyr/service/lifecycle/notification_service.dart';
import 'package:zephyr/service/update/check_update.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/manage_cache.dart';
import 'package:zephyr/widgets/memory/memory_overlay_widget.dart';
import 'package:zephyr/widgets/toast.dart';

import '../main.dart';
import '../network/sync/sync_service.dart';
import '../util/debouncer.dart';
import '../util/event/event.dart';
import '../widgets/dialog.dart';
import 'bookshelf/bookshelf.dart';
import 'discover/view/discover_page.dart';
import 'more/view/more.dart';
import 'old_page/old_home/old_home_page.dart';
import 'old_page/old_ranking/old_ranking_page.dart';

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
  DateTime? _lastLoginNavigateAt;
  String? _lastLoginPluginId;
  DateTime? _lastToastShownAt;
  (ToastType, String?, String, Duration)? _lastToastEvent;
  late HideOnScrollSettings hideOnScrollSettings;

  static bool _notificationsInitialized = false; // ← 使用静态变量，跨实例共享
  bool _isInitializingNotifications = false;
  static bool _followUpdateChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      checkUpdate(context);
      _autoSync();
      manageCacheSize(context);
      DownloadQueueManager.instance.resetStuckTasks();
      DownloadQueueManager.instance.watchTasks();
      if (Platform.isAndroid && DownloadQueueManager.instance.queueLength > 0) {
        ForegroundTaskService.instance.start();
      }
    });
    final globalSetting = objectbox.userSettingBox.get(1)!.globalSetting;
    final configuredIndex = globalSetting.welcomePageNum;
    final initialIndex = _normalizeWelcomePageIndex(
      configuredIndex,
      _buildPageList(globalSetting.oldPageRollbackEnabled).length,
    );
    _controller = PersistentTabController(initialIndex: initialIndex);
    _selectedIndex = initialIndex;
    ForegroundTaskService.instance.init();

    initializeNotificationsOnce();
    _scheduleFollowUpdateCheck(context);

    // 每隔 5 分钟执行一次
    const duration = Duration(minutes: 5);
    Timer.periodic(duration, (Timer timer) async {
      await _autoSync();
    });

    // 用来手动触发同步
    eventBus.on<NoticeSync>().listen((event) {
      _autoSync(force: event.force);
    });

    eventBus.on<NeedLogin>().listen((event) {
      _goToLoginPage(
        event.from,
        loginScheme: event.scheme,
        loginData: event.data,
        message: event.message,
      );
    });

    eventBus.on<ToastEvent>().listen((event) {
      _showToast(event);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final pageList = _buildPageList(globalSettingState.oldPageRollbackEnabled);
    final navBarItems = _navBarItems(globalSettingState.oldPageRollbackEnabled);
    final navRailDestinations = _navRailDestinations(
      globalSettingState.oldPageRollbackEnabled,
    );
    final normalizedIndex = _normalizeWelcomePageIndex(
      _selectedIndex,
      pageList.length,
    );
    if (normalizedIndex != _selectedIndex) {
      _selectedIndex = normalizedIndex;
      _controller.index = normalizedIndex;
    }
    return MemoryOverlayWidget(
      enabled: globalSettingState.enableMemoryDebug,
      updateInterval: Duration(seconds: 1),
      child: Builder(
        builder: (context) {
          if (isTablet(context) ||
              Platform.isWindows ||
              Platform.isLinux ||
              Platform.isMacOS) {
            return _buildTabletLayout(
              pageList: pageList,
              navRailDestinations: navRailDestinations,
            );
          } else {
            return _buildMobileLayout(
              pageList: pageList,
              navBarItems: navBarItems,
            );
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout({
    required List<Widget> pageList,
    required List<PersistentBottomNavBarItem> navBarItems,
  }) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: pageList,
      items: navBarItems,
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
  Widget _buildTabletLayout({
    required List<Widget> pageList,
    required List<NavigationRailDestination> navRailDestinations,
  }) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Row(
        children: [
          Column(
            children: [
              Expanded(
                child: NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                      _controller.index = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: context.backgroundColor,
                  destinations: navRailDestinations,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: IconButton(
                  icon: Icon(Icons.search),
                  tooltip: t.common.search,
                  onPressed: () {
                    context.pushRoute(
                      SearchRoute(
                        searchState: SearchStates.initial(),
                        aggregateMode: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: pageList),
          ),
        ],
      ),
    );
  }

  // 底部导航栏的配置项
  List<PersistentBottomNavBarItem> _navBarItems(bool oldPageRollbackEnabled) {
    final activeColor = context.theme.colorScheme.primary;
    final inactiveColor = context.textColor;

    final items = <PersistentBottomNavBarItem>[
      PersistentBottomNavBarItem(
        icon: Icon(Icons.menu_book_sharp),
        title: t.navigation.bookshelf,
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.explore_outlined),
        title: t.navigation.discover,
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.apps_outlined),
        title: t.navigation.more,
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
    ];
    if (!oldPageRollbackEnabled) {
      return items;
    }

    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.home_outlined),
        title: t.navigation.home,
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.leaderboard_outlined),
        title: t.navigation.rank,
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      ...items,
    ];
  }

  int _normalizeWelcomePageIndex(int rawIndex, int pageCount) {
    if (pageCount <= 0) {
      return 0;
    }
    return rawIndex.clamp(0, pageCount - 1);
  }

  // 为平板侧边导航栏生成 NavigationRailDestination
  List<NavigationRailDestination> _navRailDestinations(
    bool oldPageRollbackEnabled,
  ) {
    final destinations = <NavigationRailDestination>[
      NavigationRailDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book_sharp),
        label: Text(t.navigation.bookshelf),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: Text(t.navigation.discover),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.apps_outlined),
        selectedIcon: Icon(Icons.apps),
        label: Text(t.navigation.more),
      ),
    ];
    if (!oldPageRollbackEnabled) {
      return destinations;
    }
    return [
      NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text(t.navigation.home),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.leaderboard_outlined),
        selectedIcon: Icon(Icons.leaderboard),
        label: Text(t.navigation.rank),
      ),
      ...destinations,
    ];
  }

  List<Widget> _buildPageList(bool oldPageRollbackEnabled) {
    final pages = <Widget>[
      const BookshelfPage(),
      const DiscoverPage(),
      const MorePage(),
    ];
    if (!oldPageRollbackEnabled) {
      return pages;
    }
    return [const OldHomePage(), const OldRankingPage(), ...pages];
  }

  Future<void> _autoSync({bool force = false}) async {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final globalState = globalSettingCubit.state;

    if (!force && globalState.syncSetting.autoSync == false) {
      return;
    }

    if (!isSyncServiceConfigured(globalState)) {
      return;
    }

    try {
      await autoSync(
        globalState,
        globalSettingCubit: globalSettingCubit,
        comicFollowCubit: context.read<ComicFollowCubit>(),
      );
      if (globalState.syncSetting.syncNotify) {
        showSuccessToast(
          force ? t.navigation.syncSuccess : t.navigation.autoSyncSuccess,
        );
      }
    } catch (e, stackTrace) {
      logger.e(e.toString(), stackTrace: stackTrace);
      showErrorToast(
        t.navigation.syncFailedMessage(error: normalizeSearchErrorMessage(e)),
        title: force ? t.navigation.syncFailed : t.navigation.autoSyncFailed,
      );
    }
  }

  void _goToLoginPage(
    String from, {
    Map<String, dynamic>? loginScheme,
    Map<String, dynamic>? loginData,
    String? message,
  }) {
    try {
      final pluginId = from.trim();
      if (pluginId.isEmpty) {
        logger.w('Skip login navigation: empty plugin id');
        return;
      }

      final navigator = Navigator.maybeOf(context);
      if (navigator == null) {
        logger.w('Navigator not available');
        return;
      }

      debouncer.run(() {
        if (!mounted) {
          return;
        }

        final now = DateTime.now();
        final recentDuplicate =
            _lastLoginPluginId == pluginId &&
            _lastLoginNavigateAt != null &&
            now.difference(_lastLoginNavigateAt!).inMilliseconds < 1500;
        if (recentDuplicate) {
          return;
        }

        final hasLoginRoute = navigator.widget.pages.any(
          (route) => (route.name ?? '').contains('LoginRoute'),
        );
        if (!hasLoginRoute) {
          showErrorToast(message ?? t.navigation.loginExpired);

          _lastLoginNavigateAt = now;
          _lastLoginPluginId = pluginId;
          context.navigateTo(
            LoginRoute(
              from: pluginId,
              loginScheme: loginScheme,
              loginData: loginData,
            ),
          );
        }
      });
    } catch (e, stackTrace) {
      logger.e('Failed to navigate to login', error: e, stackTrace: stackTrace);
    }
  }

  void _showToast(ToastEvent event) {
    final now = DateTime.now();
    final toastEvent = (event.type, event.title, event.message, event.duration);
    if (_lastToastEvent == toastEvent &&
        _lastToastShownAt != null &&
        now.difference(_lastToastShownAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastToastEvent = toastEvent;
    _lastToastShownAt = now;

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
            title = t.common.success;
            break;
          case ToastType.error:
            title = t.common.error;
            break;
          case ToastType.warning:
            title = t.common.warning;
            break;
          case ToastType.info:
            title = t.common.info;
            break;
        }
      }
      commonDialog(context, title, event.message);
    }
  }

  void _scheduleFollowUpdateCheck(BuildContext context) {
    if (_followUpdateChecked) {
      return;
    }
    _followUpdateChecked = true;

    Future.delayed(const Duration(minutes: 1), () async {
      try {
        if (!context.mounted) {
          return;
        }
        await context.read<ComicFollowCubit>().checkUpdates();
      } catch (e, stackTrace) {
        logger.e('启动后追更检测失败', error: e, stackTrace: stackTrace);
      }
    });
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
