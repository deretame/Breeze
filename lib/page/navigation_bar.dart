import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/ui/fluent_compat.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toastification/toastification.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/page/ranking_list/ranking_list.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/auto_check_in.dart';
import 'package:zephyr/util/download/download_queue_manager.dart';
import 'package:zephyr/util/download_plugin.dart';
import 'package:zephyr/util/foreground_task/init.dart';
import 'package:zephyr/util/jm_url_set.dart';
import 'package:zephyr/util/manage_cache.dart';
import 'package:zephyr/util/memory/memory_overlay_widget.dart';
import 'package:zephyr/util/notice.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/util/update/check_update.dart';
import 'package:zephyr/widgets/toast.dart';

import '../network/sync/sync_service.dart';
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
  int _selectedIndex = 0;
  final debouncer = Debouncer(milliseconds: 100);

  static bool _notificationsInitialized = false; // 跨实例共享
  bool _isInitializingNotifications = false;

  // 主页面列表
  final List<Widget> _pageList = [
    HomePage(),
    RankingListPage(),
    BookshelfPage(),
    MorePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      checkUpdate(context);
      bikaSignIn(context);
      jmLogin(context);
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
      downloadPlugin();
      setLogHttpForward(url: "http://127.0.0.1:7879/log");
    });

    _selectedIndex = objectbox.userSettingBox
        .get(1)!
        .globalSetting
        .welcomePageNum
        .clamp(0, _pageList.length - 1);

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
        await Future.wait([setFastestUrlIndex(), setFastestImagesUrlIndex()]);
        showSuccessToast("禁漫已自动选择最快线路");
      } catch (e) {
        logger.e(e);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.read<GlobalSettingCubit>().state;

    return MemoryOverlayWidget(
      enabled: globalSettingState.enableMemoryDebug,
      updateInterval: const Duration(seconds: 1),
      child: NavigationView(
        pane: NavigationPane(
          selected: _selectedIndex,
          onChanged: (index) {
            setState(() => _selectedIndex = index);
          },
          displayMode: PaneDisplayMode.auto,
          items: [
            PaneItem(
              icon: const Icon(FluentIcons.home),
              title: const Text("首页"),
              body: _pageList[0],
            ),
            PaneItem(
              icon: const Icon(FluentIcons.chart),
              title: const Text("排行"),
              body: _pageList[1],
            ),
            PaneItem(
              icon: const Icon(FluentIcons.library),
              title: const Text("书架"),
              body: _pageList[2],
            ),
            PaneItem(
              icon: const Icon(FluentIcons.more),
              title: const Text("更多"),
              body: _pageList[3],
            ),
          ],
        ),
      ),
    );
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
      if (mounted) {
        jmLogin(context);
      }
    } catch (e, stackTrace) {
      logger.e(e.toString(), stackTrace: stackTrace);
      showErrorToast("请检查网络连接或稍后再试。\n${e.toString()}", title: "自动同步失败");
    }
  }

  void _goToLoginPage(From from) {
    try {
      final navigator = Navigator.maybeOf(context);
      if (navigator == null) {
        logger.w('Navigator not available');
        return;
      }

      String allRoutes = "";
      for (final route in navigator.widget.pages) {
        final routeName = route.name ?? 'UnknownRoute';
        allRoutes += "$routeName ";
      }

      logger.d('All routes: $allRoutes');

      debouncer.run(() {
        if (!allRoutes.contains('LoginRoute')) {
          showErrorToast('登录过期，请重新登录');

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
