import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:event_bus/event_bus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/firebase_options.dart';
import 'package:zephyr/network/http/jm/http_request_build.dart';
import 'package:zephyr/src/rust/frb_generated.dart';
import 'package:zephyr/util/manage_cache.dart';
import 'package:zephyr/util/pretty_log.dart';
import 'package:zephyr/util/router/router.dart';

import 'config/global/global.dart';
import 'config/global/global_setting.dart';
import 'config/mobx/theme_mode_adapter.dart';
import 'network/dio_cache.dart';
import 'object_box/object_box.dart';

final globalSetting = GlobalSetting();
final bikaSetting = BikaSetting();
final jmSetting = JmSetting();
late final ObjectBox objectbox;

// 定义全局Dio实例
final dio = Dio();
// 定义缓存拦截器
final cacheInterceptor = DioCacheInterceptor(ExpiringMemoryCache());
final appRouter = AppRouter();

// 全局事件总线实例
EventBus eventBus = EventBus();

// 获取material主题颜色方案
late ColorScheme materialColorScheme;
late ColorScheme materialColorSchemeDark;

final logger = Logger(printer: CustomPrinter());

List<String> cfIpList = [];

final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // 初始化rust
      await RustLib.init();

      // 初始化前台任务
      FlutterForegroundTask.initCommunicationPort();

      // 重采样触控刷新率
      GestureBinding.instance.resamplingEnabled = true;

      // 用来判断要不要使用skia
      const skia = String.fromEnvironment('use_skia', defaultValue: 'false');
      if (skia == 'true') {
        useSkia = true;
      } else {
        useSkia = false;
      }

      objectbox = await ObjectBox.create();

      // 初始化Hive
      await Hive.initFlutter();
      // 注册 Color 适配器
      Hive.registerAdapter(ThemeModeAdapter());
      await globalSetting.initBox();
      await bikaSetting.initBox();
      await jmSetting.initBox();
      // await initCfIpList('https://ip.164746.xyz/ipTop.html');

      if (globalSetting.needCleanCache) {
        await clearCache(await getTemporaryDirectory());
      }

      manageCacheSize();

      // logger.d(globalSetting.socks5Proxy);
      if (globalSetting.socks5Proxy.isNotEmpty) {
        // proxy -> "SOCKS5/SOCKS4/PROXY username:password@host:port;" or "DIRECT"
        SocksProxy.initProxy(proxy: 'SOCKS5 ${globalSetting.socks5Proxy}');
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
      }

      jmDio.interceptors.add(CookieManager(JmConfig.cookieJar));

      runApp(MyApp());
    },
    (error, stackTrace) {
      if (kDebugMode) {
        logger.e(error, error: error, stackTrace: stackTrace);
      } else {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          fatal: true,
        );
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  void _updateThemeSettings(BuildContext context) {
    var isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    if (globalSetting.themeMode == ThemeMode.dark) {
      isDarkMode = true;
    } else if (globalSetting.themeMode == ThemeMode.light) {
      isDarkMode = false;
    }

    globalSetting.setThemeType(!isDarkMode);
    globalSetting.setBackgroundColor(materialColorScheme.surfaceBright);
    globalSetting.setTextColor(materialColorScheme.onSurface);

    // Debug 信息
    // logger.d(
    //   "dynamicColor: ${globalSetting.dynamicColor}\n"
    //   "themeType: ${globalSetting.themeType}\n"
    //   "backgroundColor: ${globalSetting.backgroundColor}\n"
    //   "current theme: ${globalSetting.themeMode}\n"
    //   "textColor: ${globalSetting.textColor}",
    // );
  }

  @override
  Widget build(BuildContext context) {
    // 设置这个的目的是为了缓解图片重载
    PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 1024;

    statusBarHeight = MediaQuery.of(context).padding.top;
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarColor: Colors.transparent,
      ),
    );

    return Observer(
      builder: (context) {
        return DynamicColorBuilder(
          key: ValueKey(
            globalSetting.dynamicColor.toString() +
                globalSetting.seedColor.toString() +
                globalSetting.themeMode.toString() +
                globalSetting.themeType.toString() +
                globalSetting.isAMOLED.toString(),
          ), // 强制重建
          builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
            ColorScheme lightColorScheme;
            ColorScheme darkColorScheme;

            // 根据 dynamicColor 的值决定是否使用动态颜色
            if (globalSetting.dynamicColor == true) {
              lightColorScheme =
                  lightDynamic ??
                  ColorScheme.fromSeed(
                    seedColor: globalSetting.seedColor, // 默认颜色
                    brightness: Brightness.light,
                  );
              darkColorScheme =
                  darkDynamic ??
                  ColorScheme.fromSeed(
                    seedColor: globalSetting.seedColor, // 默认颜色
                    brightness: Brightness.dark,
                  );
            } else {
              // 使用静态颜色方案
              var primary = globalSetting.seedColor;

              lightColorScheme = ColorScheme.fromSeed(
                seedColor: primary,
                brightness: Brightness.light,
              );
              darkColorScheme = ColorScheme.fromSeed(
                seedColor: primary,
                brightness: Brightness.dark,
              );
            }

            // 根据当前主题模式选择对应的 ColorScheme
            globalSetting.themeMode == ThemeMode.dark
                ? darkColorScheme
                : lightColorScheme;

            globalSetting.themeType == true
                ? materialColorScheme = lightColorScheme
                : materialColorScheme = darkColorScheme;
            materialColorSchemeDark = darkColorScheme;

            _updateThemeSettings(context);
            return MaterialApp.router(
              routerConfig: appRouter.config(),
              locale: globalSetting.locale,
              title: appName,
              themeMode: globalSetting.themeMode,
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
                chipTheme: ChipThemeData(
                  backgroundColor: lightColorScheme.surface,
                ),
                canvasColor: lightColorScheme.surfaceContainer,
                dialogTheme: DialogThemeData(
                  backgroundColor: lightColorScheme.surfaceContainer,
                ),
              ),
              darkTheme: ThemeData.dark().copyWith(
                scaffoldBackgroundColor:
                    globalSetting.isAMOLED
                        ? Colors.black
                        : darkColorScheme.surface,
                tabBarTheme: TabBarThemeData(dividerColor: Colors.transparent),
                colorScheme: darkColorScheme,
              ),
            );
          },
        );
      },
    );
  }
}
