import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/network/dio_cache.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/src/rust/api/system.dart' as rust_system;
import 'package:zephyr/src/rust/frb_generated.dart';
import 'package:zephyr/util/debouncer.dart';
import 'package:zephyr/util/desktop/custom_title_bar.dart';
import 'package:zephyr/util/desktop/intent.dart';
import 'package:zephyr/util/desktop/native_window.dart';
import 'package:zephyr/util/desktop/system_tray.dart';
import 'package:zephyr/util/desktop/window_logic.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/jm_url_set.dart';
import 'package:zephyr/util/manage_cache.dart';
import 'package:zephyr/util/router/router.dart';

late final ObjectBox objectbox;

// 定义全局Dio实例
final dio = Dio();
// 定义缓存拦截器
final cacheInterceptor = DioCacheInterceptor(ExpiringMemoryCache());
final appRouter = AppRouter();

// 全局事件总线实例
EventBus eventBus = EventBus();

var logger = Logger(printer: TersePrettyPrinter());

List<String> cfIpList = [];

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // 1. 基础初始化
  WidgetsFlutterBinding.ensureInitialized();

  const sentryDsn = String.fromEnvironment('sentry_dsn', defaultValue: '');

  if (sentryDsn.isEmpty) {
    if (!kDebugMode) logger = Logger(filter: ProductionFilter());
    // 1. 如果是调试模式，配置 logger 捕获全局错误
    if (kDebugMode || sentryDsn.isEmpty) {
      // 捕获 Flutter 框架层错误（如 Widget 构建中的异常）
      FlutterError.onError = (FlutterErrorDetails details) {
        logger.e(
          "Flutter Framework Error",
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      // 捕获异步错误和底层错误（如 Future.error, Timer 等）
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        logger.e("Async/Platform Error", error: error, stackTrace: stack);
        return true; // 表示错误已被处理
      };
    }

    try {
      // 2. 执行业务初始化
      final (globalSettingCubit, jmSettingCubit, bikaSettingCubit) =
          await _initServices();

      runApp(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: globalSettingCubit),
            BlocProvider.value(value: jmSettingCubit),
            BlocProvider.value(value: bikaSettingCubit),
          ],
          child: const MyApp(),
        ),
      );
    } catch (e, stack) {
      // 捕获初始化阶段（_initServices）可能抛出的异常
      if (kDebugMode || sentryDsn.isEmpty) {
        logger.e("App Setup Failed", error: e, stackTrace: stack);
      }
    }

    return;
  }

  // 2. 使用 Sentry 包装整个应用生命周期
  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;

      // 开启默认的个人信息采集（IP/Header），有助于分析用户分布
      options.sendDefaultPii = true;

      // 仅在调试模式下打印 Sentry 内部日志
      options.enableLogs = kDebugMode;

      // --- Sentry Sponsored Business 特权配置 ---
      // 性能追踪采样率
      options.tracesSampleRate = 1.0;

      // 性能剖析采样率
      // ignore: experimental_member_use
      options.profilesSampleRate = 1.0;

      // 会话回放设置：平时抽样 10%，遇到错误时 100% 录制
      options.replay.sessionSampleRate = 0.1;
      options.replay.onErrorSampleRate = 1.0;

      // 附加线程信息和堆栈，增强原生层（Rust/C++）错误分析
      options.attachThreads = true;
      options.attachStacktrace = true;
    },
    appRunner: () async {
      try {
        final (globalSettingCubit, jmSettingCubit, bikaSettingCubit) =
            await _initServices();

        runApp(
          SentryWidget(
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: globalSettingCubit),
                BlocProvider.value(value: jmSettingCubit),
                BlocProvider.value(value: bikaSettingCubit),
              ],
              child: MyApp(),
            ),
          ),
        );
      } catch (exception, stackTrace) {
        await Sentry.captureException(exception, stackTrace: stackTrace);
      }
    },
  );
}

Future<(GlobalSettingCubit, JmSettingCubit, BikaSettingCubit)>
_initServices() async {
  // 初始化rust
  await RustLib.init();

  // 配置http代理，方便开发测试
  if (kDebugMode) {
    await enableProxy();
  }

  // 初始化前台任务
  FlutterForegroundTask.initCommunicationPort();

  // 重采样触控刷新率
  GestureBinding.instance.resamplingEnabled = true;

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  final isWin = Platform.isWindows;
  final cache = PaintingBinding.instance.imageCache;

  cache.maximumSizeBytes = 300 * 1024 * 1024 * (isWin ? 3 : 1);
  cache.maximumSize = 50 * (isWin ? 3 : 1);

  // 如果是手机的话就固定为只能使用横屏模式
  if (!isTabletWithOutContext()) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // 用来判断要不要使用skia
  const skia = String.fromEnvironment('use_skia', defaultValue: 'false');
  if (skia == 'true') {
    useSkia = true;
  } else {
    useSkia = false;
  }

  objectbox = await ObjectBox.create();

  final setting = objectbox.userSettingBox.get(1);
  if (setting == null) {
    objectbox.userSettingBox.put(UserSetting());
  }

  final globalSettingCubit = GlobalSettingCubit();
  await globalSettingCubit.initBox();

  final jmSettingCubit = JmSettingCubit();
  await jmSettingCubit.initBox();

  final bikaSettingCubit = BikaSettingCubit();
  await bikaSettingCubit.initBox();
  // await initCfIpList('https://ip.164746.xyz/ipTop.html');

  if (globalSettingCubit.state.needCleanCache) {
    await clearCache(await getCachePath());
  }

  // logger.d(globalSetting.socks5Proxy);
  if (globalSettingCubit.state.socks5Proxy.isNotEmpty) {
    // proxy -> "SOCKS5/SOCKS4/PROXY username:password@host:port;" or "DIRECT"
    SocksProxy.initProxy(
      proxy: 'SOCKS5 ${globalSettingCubit.state.socks5Proxy}',
    );
  }

  return (globalSettingCubit, jmSettingCubit, bikaSettingCubit);
}

class MyApp extends StatefulWidget with WindowListener {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.addListener(this);
      _init();
      WindowLogic.initWindow(context).then((_) {
        windowManager.setPreventClose(true);
      });
    }
    trayManager.addListener(this);
    initSystemTray();

    // 启动命名管道监听，用于接收外部退出信号（仅 Windows）
    if (Platform.isWindows) {
      rust_system.startShutdownListener().listen((shouldExit) {
        if (shouldExit) {
          _performGracefulExit();
        }
      });
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowResized() {
    super.onWindowResized();
    WindowLogic.saveWindowState(context);
  }

  @override
  void onWindowMoved() {
    super.onWindowMoved();
    WindowLogic.saveWindowState(context);
  }

  /// 立即隐藏窗口再退出，让用户感知不到 Dart VM 清理的延迟
  void _forceExit() {
    if (Platform.isWindows) {
      NativeWindow.hide(); // 同步 Win32 调用，零延迟
    } else {
      windowManager.hide(); // 其他桌面平台
    }
    exit(0);
  }

  @override
  void onWindowClose() async {
    final dialogContext = appRouter.navigatorKey.currentContext;
    if (dialogContext == null || !dialogContext.mounted) {
      _forceExit();
      return;
    }
    showDialog(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: Text('您确定要退出软件吗？'),
          actions: [
            TextButton(
              child: Text('否'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('是'),
              onPressed: () {
                _forceExit();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performGracefulExit() async {
    _forceExit();
  }

  @override
  void onWindowFocus() {
    super.onWindowFocus();
    setState(() {});
  }

  @override
  void onTrayIconMouseDown() {
    NativeWindow.show();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      NativeWindow.show();
    } else if (menuItem.key == 'exit_app') {
      // 真正退出：清理资源后退出
      _performGracefulExit();
    }
  }

  void _init() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      await windowManager.setPreventClose(true);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        // 根据 dynamicColor 的值决定是否使用动态颜色
        if (globalSettingState.dynamicColor == true) {
          lightColorScheme =
              lightDynamic ??
              ColorScheme.fromSeed(
                seedColor: globalSettingState.seedColor, // 默认颜色
                brightness: Brightness.light,
              );
          darkColorScheme =
              darkDynamic ??
              ColorScheme.fromSeed(
                seedColor: globalSettingState.seedColor, // 默认颜色
                brightness: Brightness.dark,
              );
        } else {
          var primary = globalSettingState.seedColor;

          lightColorScheme = ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.light,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: primary,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp.router(
          routerConfig: appRouter.config(),
          builder: (context, child) {
            Widget content = Actions(
              actions: <Type, Action<Intent>>{
                EscapeIntent: CallbackAction<EscapeIntent>(
                  onInvoke: (intent) {
                    appRouter.maybePop();
                    return null;
                  },
                ),
              },
              child: Shortcuts(
                shortcuts: <ShortcutActivator, Intent>{
                  const SingleActivator(LogicalKeyboardKey.escape):
                      const EscapeIntent(),
                },
                child: Focus(autofocus: true, child: child!),
              ),
            );

            content = Listener(
              onPointerDown: (PointerDownEvent event) {
                if (event.buttons & kBackMouseButton != 0) {
                  appRouter.maybePop();
                }
              },
              child: content,
            );

            // 桌面平台添加自定义标题栏
            if (Platform.isWindows || Platform.isLinux) {
              return Column(
                children: [
                  const CustomTitleBar(),
                  Expanded(child: content),
                ],
              );
            }
            return content;
          },
          locale: globalSettingState.locale,
          title: appName,
          themeMode: globalSettingState.themeMode,
          supportedLocales: [
            Locale('en', 'US'), // English
            Locale('zh', 'CN'), // Chinese
            // 其他支持的语言
          ],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData.light().copyWith(
            primaryColor: lightColorScheme.primary,
            colorScheme: lightColorScheme,
            scaffoldBackgroundColor: lightColorScheme.surface,
            cardColor: lightColorScheme.surfaceContainer,
            chipTheme: ChipThemeData(backgroundColor: lightColorScheme.surface),
            canvasColor: lightColorScheme.surfaceContainer,
            dialogTheme: DialogThemeData(
              backgroundColor: lightColorScheme.surfaceContainer,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: globalSettingState.isAMOLED
                ? Colors.black
                : darkColorScheme.surface,
            tabBarTheme: TabBarThemeData(dividerColor: Colors.transparent),
            colorScheme: darkColorScheme,
          ),
        );
      },
    );
  }
}
