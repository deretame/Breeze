import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:logger/logger.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/util/manage_cache.dart';
import 'package:zephyr/util/pretty_log.dart';
import 'package:zephyr/util/router/router.dart';

import 'config/global.dart';
import 'config/global_setting.dart';
import 'config/theme_mode_adapter.dart';
import 'network/dio_cache.dart';
import 'object_box/object_box.dart';

final globalSetting = GlobalSetting();
final bikaSetting = BikaSetting();
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

var logger = Logger(printer: CustomPrinter());

Future<void> main() async {
  // 捕获Dart异常
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // 重采样触控刷新率
      GestureBinding.instance.resamplingEnabled = false;

      const skia = String.fromEnvironment('use_skia', defaultValue: 'false');
      if (skia == 'true') {
        useSkia = true;
      } else {
        useSkia = false;
      }

      objectbox = await ObjectBox.create();

      await manageCacheSize();

      // 告诉系统应该用竖屏
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // 初始化Hive
      await Hive.initFlutter();
      // 注册 Color 适配器
      // Hive.registerAdapter(ColorAdapter());
      Hive.registerAdapter(ThemeModeAdapter());
      await globalSetting.initBox();
      await bikaSetting.initBox();

      // 捕获Flutter框架异常
      FlutterError.onError = (FlutterErrorDetails details) {
        logger.e(details, error: details.exception, stackTrace: details.stack);
      };

      runApp(MyApp());
    },
    (error, stackTrace) {
      logger.e(error, stackTrace: stackTrace);
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void _updateThemeSettings() {
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
    logger.d(
      "dynamicColor: ${globalSetting.dynamicColor}\n"
      "themeType: ${globalSetting.themeType}\n"
      "backgroundColor: ${globalSetting.backgroundColor}\n"
      "current theme: ${globalSetting.themeMode}\n"
      "textColor: ${globalSetting.textColor}",
    );
  }

  @override
  Widget build(BuildContext context) {
    // 设置这个的目的是为了缓解图片重载
    // PaintingBinding.instance.imageCache.maximumSizeBytes = 500 * 1024 * 1024;

    Global(context);
    if (statusBarHeight == 0) {
      statusBarHeight = MediaQuery.of(context).padding.top;
    }
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

            _updateThemeSettings();
            return MaterialApp.router(
              routerConfig: appRouter.config(),
              locale: globalSetting.locale,
              title: 'BK comic',
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
                tabBarTheme: TabBarTheme(dividerColor: Colors.transparent),
                colorScheme: darkColorScheme,
              ),
            );
          },
        );
      },
    );
  }
}
