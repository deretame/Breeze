import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:toastification/toastification.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/download/download_queue_manager.dart';
import 'package:zephyr/util/foreground_task/init.dart';
import 'package:zephyr/util/manage_cache.dart';
import 'package:zephyr/util/memory/memory_overlay_widget.dart';
import 'package:zephyr/util/notice.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/update/check_update.dart';
import 'package:zephyr/widgets/toast.dart';

import '../main.dart';
import '../network/sync/sync_service.dart';
import '../util/debouncer.dart';
import '../util/dialog.dart';
import '../util/event/event.dart';
import 'bookshelf/bookshelf.dart';
import 'home/view/home.dart';

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
  late HideOnScrollSettings hideOnScrollSettings;

  static bool _notificationsInitialized = false; // ← 使用静态变量，跨实例共享
  bool _isInitializingNotifications = false;

  // 页面列表
  final _pageList = [const BookshelfPage(), const HomePage()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      checkUpdate(context);
      _autoSync();
      manageCacheSize(context);
      resetDownloadTasks();
      if (Platform.isAndroid) {
        if (DownloadQueueManager.instance.queueLength > 0) {
          initDownloadTask();
        }
      } else {
        DownloadQueueManager.instance.watchTasks();
      }
      setLogHttpForward(url: "http://127.0.0.1:7878/log");
    });
    final configuredIndex = objectbox.userSettingBox
        .get(1)!
        .globalSetting
        .welcomePageNum;
    final initialIndex =
        configuredIndex >= 0 && configuredIndex < _pageList.length
        ? configuredIndex
        : 0;
    _controller = PersistentTabController(initialIndex: initialIndex);
    _selectedIndex = initialIndex;
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

  // 底部导航栏的配置项
  List<PersistentBottomNavBarItem> _navBarItems() {
    final activeColor = context.theme.colorScheme.primary;
    final inactiveColor = context.textColor;

    return [
      PersistentBottomNavBarItem(
        icon: Icon(Icons.menu_book_sharp),
        title: "书架",
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(Icons.explore_outlined),
        title: "发现",
        activeColorPrimary: activeColor,
        inactiveColorPrimary: inactiveColor,
      ),
    ];
  }

  // 为平板侧边导航栏生成 NavigationRailDestination
  List<NavigationRailDestination> _navRailDestinations() {
    return [
      NavigationRailDestination(
        icon: Icon(Icons.menu_book_outlined),
        selectedIcon: Icon(Icons.menu_book_sharp),
        label: Text("书架"),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.explore_outlined),
        selectedIcon: Icon(Icons.explore),
        label: Text("发现"),
      ),
    ];
  }

  Future<void> _autoSync() async {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final bikaSettingCubit = context.read<BikaSettingCubit>();
    final jmSettingCubit = context.read<JmSettingCubit>();
    final globalState = globalSettingCubit.state;

    if (globalState.autoSync == false) {
      return;
    }

    if (!isSyncServiceConfigured(globalState)) {
      return;
    }

    try {
      await autoSync(
        globalState,
        globalSettingCubit: globalSettingCubit,
        bikaSettingCubit: bikaSettingCubit,
        jmSettingCubit: jmSettingCubit,
      );
      if (globalState.syncNotify) {
        showSuccessToast("自动同步成功！");
      }
    } catch (e, stackTrace) {
      logger.e(e.toString(), stackTrace: stackTrace);
      showErrorToast("请检查网络连接或稍后再试。\n${e.toString()}", title: "自动同步失败");
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
          showErrorToast(message ?? '登录过期，请重新登录');

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
