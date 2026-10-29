import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
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

import 'package:zephyr/main.dart';
import 'package:zephyr/network/sync/sync_service.dart';
import 'package:zephyr/util/debouncer.dart';
import 'package:zephyr/util/event/event.dart';
import 'package:zephyr/widgets/dialog.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';
import 'package:zephyr/page/discover/view/discover_page.dart';
import 'package:zephyr/page/more/view/more.dart';
import 'package:zephyr/page/plugin_home/plugin_home.dart';

@RoutePage()
class NavigationBar extends StatefulWidget {
  const NavigationBar({super.key});

  @override
  State<NavigationBar> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<NavigationBar> {
  // _controller 用于控制手机底部导航栏和页面切换（下标为过滤后的可见位置）
  late PersistentTabController _controller;
  // _selectedBaseIndex 为规范 tab 序号：0 首页，1 云收藏，2 书架，3 发现，4 更多；
  // 前两项可隐藏，实际位置由可见列表换算，切换开关时保持指向同一页面。
  int _selectedBaseIndex = 0;
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
      DownloadQueueManager.instance.watchTasks(
        startupResumeDelay: const Duration(minutes: 1),
      );
      if (Platform.isAndroid) {
        await ForegroundTaskService.instance.syncOnAppStart();
      }
    });
    final globalSetting = objectbox.userSettingBox.get(1)!.globalSetting;
    _selectedBaseIndex = _normalizeBaseIndex(
      globalSetting.welcomePageNum,
      globalSetting,
    );
    _controller = PersistentTabController(
      initialIndex: _visibleIndexOf(_selectedBaseIndex, globalSetting),
    );
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
      _goToLoginPage(event.from, message: event.message);
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
    // 开关仅在 Android 展示；同时限制实际行为，避免同步设置后影响其他平台。
    final backPressExitEnabled =
        Platform.isAndroid && globalSettingState.backPressExitEnabled;
    // 隐藏中的当前页可能是被开关关掉的 tab，这里把它挪到最近的可见页，
    // 可见位置由规范序号换算，确保开关切换时仍停留在同一页面。
    _selectedBaseIndex = _normalizeBaseIndex(
      _selectedBaseIndex,
      globalSettingState,
    );
    final visibleBaseIndexes = _visibleBaseIndexes(globalSettingState);
    final visibleIndex = _visibleIndexOf(
      _selectedBaseIndex,
      globalSettingState,
    );
    if (_controller.index != visibleIndex) {
      _controller.index = visibleIndex;
    }
    final pageList = _buildPageList(globalSettingState);
    final navBarItems = _navBarItems(globalSettingState);
    final navRailDestinations = _navRailDestinations(globalSettingState);
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
              visibleBaseIndexes: visibleBaseIndexes,
            );
          } else {
            return _buildMobileLayout(
              pageList: pageList,
              navBarItems: navBarItems,
              backPressExitEnabled: backPressExitEnabled,
              visibleBaseIndexes: visibleBaseIndexes,
            );
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout({
    required List<Widget> pageList,
    required List<PersistentBottomNavBarItem> navBarItems,
    required bool backPressExitEnabled,
    required List<int> visibleBaseIndexes,
  }) {
    return PersistentTabView(
      context,
      controller: _controller,
      screens: pageList,
      items: navBarItems,
      backgroundColor: context.backgroundColor,
      // 由组件自身的 PopScope 接收返回事件。此前把 PopScope 包在组件外层，
      // 容易被每个 tab 的内部 Navigator 先消费，导致开关看起来没有效果。
      handleAndroidBackButtonPress: !backPressExitEnabled,
      onWillPop: backPressExitEnabled ? _handleExitOnBack : null,
      resizeToAvoidBottomInset: false,
      hideNavigationBarWhenKeyboardAppears: false,
      stateManagement: true,
      navBarStyle: NavBarStyle.style3,
      onItemSelected: (index) {
        setState(() {
          _selectedBaseIndex = visibleBaseIndexes[index];
        });
      },
    );
  }

  Future<bool> _handleExitOnBack(BuildContext? _) async {
    // 子页面仍由 PersistentTabView 的内部 Navigator 正常返回；只有当前 tab
    // 已无子页面时才会调用这里。首页隐藏时第一个可见页即视为首页。
    final globalSetting = context.read<GlobalSettingCubit>().state;
    if (_visibleIndexOf(_selectedBaseIndex, globalSetting) != 0) {
      setState(() {
        _selectedBaseIndex = _visibleBaseIndexes(globalSetting).first;
      });
      _controller.jumpToTab(0);
      return false;
    }

    await SystemNavigator.pop();
    // 已由系统关闭 Activity，不再让组件继续 pop 根路由。
    return false;
  }

  // 平板布局 (使用 NavigationRail)
  Widget _buildTabletLayout({
    required List<Widget> pageList,
    required List<NavigationRailDestination> navRailDestinations,
    required List<int> visibleBaseIndexes,
  }) {
    final visibleIndex = visibleBaseIndexes.indexOf(_selectedBaseIndex);
    final selectedIndex = visibleIndex < 0 ? 0 : visibleIndex;
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Row(
        children: [
          Column(
            children: [
              Expanded(
                child: NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedBaseIndex = visibleBaseIndexes[index];
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
            child: IndexedStack(index: selectedIndex, children: pageList),
          ),
        ],
      ),
    );
  }

  // 底部导航栏的配置项（按开关过滤，只保留可见 tab）
  List<PersistentBottomNavBarItem> _navBarItems(GlobalSettingState state) {
    final activeColor = context.theme.colorScheme.primary;
    final inactiveColor = context.textColor;

    final homeItem = PersistentBottomNavBarItem(
      icon: Icon(Icons.home_outlined),
      title: t.navigation.home,
      activeColorPrimary: activeColor,
      inactiveColorPrimary: inactiveColor,
    );
    final cloudFavoriteItem = PersistentBottomNavBarItem(
      icon: Icon(Icons.cloud_outlined),
      title: t.oldHome.cloudFavorite,
      activeColorPrimary: activeColor,
      inactiveColorPrimary: inactiveColor,
    );
    final bookshelfItem = PersistentBottomNavBarItem(
      icon: Icon(Icons.menu_book_sharp),
      title: t.navigation.bookshelf,
      activeColorPrimary: activeColor,
      inactiveColorPrimary: inactiveColor,
    );
    final discoverItem = PersistentBottomNavBarItem(
      icon: Icon(Icons.explore_outlined),
      title: t.navigation.discover,
      activeColorPrimary: activeColor,
      inactiveColorPrimary: inactiveColor,
    );
    final moreItem = PersistentBottomNavBarItem(
      icon: Icon(Icons.apps_outlined),
      title: t.navigation.more,
      activeColorPrimary: activeColor,
      inactiveColorPrimary: inactiveColor,
    );
    return _pickVisible(state, [
      homeItem,
      cloudFavoriteItem,
      bookshelfItem,
      discoverItem,
      moreItem,
    ]);
  }

  /// 规范序号转可见位置；隐藏中的序号回退到最近的可见页。
  int _visibleIndexOf(int baseIndex, GlobalSettingState state) {
    final visible = _visibleBaseIndexes(state);
    final position = visible.indexOf(baseIndex);
    if (position >= 0) return position;
    // 向前找最近可见，找不到则取第一个可见（至少书架/发现/更多常驻）。
    for (var candidate = baseIndex - 1; candidate >= 0; candidate--) {
      final fallback = visible.indexOf(candidate);
      if (fallback >= 0) return fallback;
    }
    return 0;
  }

  /// 规范序号归一化：越界钳制，隐藏中的序号挪到最近可见页。
  int _normalizeBaseIndex(int rawIndex, GlobalSettingState state) {
    final visible = _visibleBaseIndexes(state);
    if (visible.isEmpty) return 2;
    if (visible.contains(rawIndex)) return rawIndex;
    return visible[_visibleIndexOf(rawIndex, state)];
  }

  /// 当前可见 tab 的规范序号列表，顺序与页面列表一致。
  List<int> _visibleBaseIndexes(GlobalSettingState state) {
    return [
      if (state.showPluginHome) 0,
      if (state.showPluginCloudFavorite) 1,
      2,
      3,
      4,
    ];
  }

  List<T> _pickVisible<T>(GlobalSettingState state, List<T> all) {
    final visible = _visibleBaseIndexes(state);
    return [for (final baseIndex in visible) all[baseIndex]];
  }

  // 为平板侧边导航栏生成 NavigationRailDestination（按开关过滤）
  List<NavigationRailDestination> _navRailDestinations(
    GlobalSettingState state,
  ) {
    final all = [
      NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text(t.navigation.home),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.cloud_outlined),
        selectedIcon: Icon(Icons.cloud),
        label: Text(t.oldHome.cloudFavorite),
      ),
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
    return _pickVisible(state, all);
  }

  List<Widget> _buildPageList(GlobalSettingState state) {
    const all = [
      PluginHomePage(),
      PluginCloudFavoritePage(),
      BookshelfPage(),
      DiscoverPage(),
      MorePage(),
    ];
    return _pickVisible(state, all);
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

  void _goToLoginPage(String from, {String? message}) {
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
        if (hasLoginRoute) {
          return;
        }
        _lastLoginNavigateAt = now;
        _lastLoginPluginId = pluginId;
        unawaited(_confirmAndGoToLogin(pluginId, message: message));
      });
    } catch (e, stackTrace) {
      logger.e('Failed to navigate to login', error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _confirmAndGoToLogin(String pluginId, {String? message}) async {
    if (!mounted) {
      return;
    }
    final goLogin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.navigation.needLoginTitle),
        content: Text(message ?? t.navigation.loginExpired),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.navigation.goLogin),
          ),
        ],
      ),
    );
    if (goLogin != true || !mounted) {
      return;
    }
    try {
      final navigator = Navigator.maybeOf(context);
      if (navigator == null) {
        return;
      }
      final hasLoginRoute = navigator.widget.pages.any(
        (route) => (route.name ?? '').contains('LoginRoute'),
      );
      if (hasLoginRoute) {
        return;
      }
      context.navigateTo(LoginRoute(from: pluginId));
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
