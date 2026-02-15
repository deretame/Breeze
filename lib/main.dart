import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:event_bus/event_bus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:logger/logger.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/config/mobx/theme_mode_adapter.dart';
import 'package:zephyr/firebase_options.dart';
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

var logger = Logger();

List<String> cfIpList = [];

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 初始化环境变量
      await dotenv.load(fileName: ".env");

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

      // 初始化Hive
      await Hive.initFlutter(await getDbPath());
      // 注册 Color 适配器
      Hive.registerAdapter(ThemeModeAdapter());

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

      if (kDebugMode) {
        FlutterError.onError = (FlutterErrorDetails details) {
          logger.e(
            details,
            error: details.exception,
            stackTrace: details.stack,
          );
        };

        PlatformDispatcher.instance.onError = (error, stack) {
          logger.e(error, error: error, stackTrace: stack);
          return true; // 表示错误已处理
        };
      } else {
        if (!Platform.isLinux) {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );

          FlutterError.onError = (FlutterErrorDetails errorDetails) {
            FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
          };

          PlatformDispatcher.instance.onError = (error, stack) {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
            return true; // 表示错误已处理
          };
        } else {
          logger = Logger(filter: ProductionFilter(), output: ConsoleOutput());
        }
      }

      runApp(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: globalSettingCubit),
            BlocProvider.value(value: jmSettingCubit),
            BlocProvider.value(value: bikaSettingCubit),
          ],
          child: MyApp(),
        ),
      );
    },
    (error, stackTrace) {
      if (kDebugMode) {
        logger.e(error, error: error, stackTrace: stackTrace);
      } else {
        if (Platform.isLinux) {
          return;
        }

        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
      }
    },
  );
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
    windowManager.addListener(this);
    _init();
    WindowLogic.initWindow(context).then((_) {
      // 窗口初始化完成后，拦截关闭按钮
      windowManager.setPreventClose(true);
    });
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
    windowManager.removeListener(this);
    trayManager.removeListener(this);
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

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      final dialogContext = appRouter.navigatorKey.currentContext;
      if (dialogContext == null || !dialogContext.mounted) return;
      showDialog(
        context: dialogContext,
        builder: (context) {
          return AlertDialog(
            title: Text('您确定要关闭此窗口吗？'),
            actions: [
              TextButton(
                child: Text('否'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('是'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await windowManager.destroy();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _performGracefulExit() async {
    exit(0);
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
    // 添加此行以覆盖默认的关闭处理程序
    await windowManager.setPreventClose(true);
    setState(() {});
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

            // 桌面平台添加自定义标题栏
            if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
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
