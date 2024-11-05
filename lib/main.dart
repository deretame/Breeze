import 'dart:io';

import 'package:catcher_2/catcher_2.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/util/constants.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/router.dart';

import 'config/global.dart';
import 'config/global_setting.dart';
import 'mobx/fullscreen_store.dart';

final globalSetting = GlobalSetting();
final bikaSetting = BikaSetting();
final fullScreenStore = FullScreenStore();
final getIt = GetIt.instance;

// 定义全局Dio实例
final dio = Dio();
// 定义缓存拦截器
final cacheInterceptor = DioCacheInterceptor(
  options: CacheOptions(
    store: MemCacheStore(), // 使用内存缓存
    policy: CachePolicy.forceCache, // 根据请求决定是否使用缓存
    maxStale: const Duration(minutes: 5), // 设置缓存最大有效时长为5分钟
  ),
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 告诉系统应该用竖屏
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // 初始化Hive
  await Hive.initFlutter();
  // 注册 Color 适配器
  Hive.registerAdapter(ColorAdapter());
  await globalSetting.initBox();
  await bikaSetting.initBox();

  // 异常捕获 logo记录
  final Catcher2Options releaseConfig = Catcher2Options(
    SilentReportMode(),
    [FileHandler(await getLogPath())],
  );

  // 小白条、导航栏沉浸设置，仅当平台为Android时
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 29) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ));
  }

  // 初始化Catcher2并运行应用
  Catcher2(
    releaseConfig: releaseConfig,
    runAppFunction: () {
      runApp(const MyApp());
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Global(context);
    return Constants.isFluent
        ? buildFluentUI(context)
        : _buildMaterial(context);
  }

  Widget _buildMaterial(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ));

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return Observer(
          builder: (context) {
            ColorScheme lightColorScheme;
            ColorScheme darkColorScheme;

            // 首先确定当前使用的 ColorScheme
            if (globalSetting.dynamicColor &&
                lightDynamic != null &&
                darkDynamic != null) {
              lightColorScheme = lightDynamic.harmonized();
              darkColorScheme = darkDynamic.harmonized();
            } else {
              Color primary = globalSetting.seedColor;
              lightColorScheme = ColorScheme.fromSeed(
                seedColor: primary,
              );
              darkColorScheme = ColorScheme.fromSeed(
                seedColor: primary,
                brightness: Brightness.dark,
              );
            }

            // 根据当前主题模式选择对应的 ColorScheme
            final currentColorScheme = globalSetting.themeMode == ThemeMode.dark
                ? darkColorScheme
                : lightColorScheme;

            // 更新设置时使用确定的 ColorScheme
            bool isDarkMode =
                MediaQuery.of(context).platformBrightness == Brightness.dark;
            Color textColor = isDarkMode ? Colors.white : Colors.black;
            globalSetting.setThemeType(isDarkMode ? false : true);
            globalSetting.setBackgroundColor(currentColorScheme.surface);
            globalSetting.setTextColor(textColor);

            debugPrint("isDynamic: ${globalSetting.dynamicColor}");
            debugPrint("lightDynamic: $lightDynamic");
            debugPrint("darkDynamic: $darkDynamic");
            debugPrint("backgroundColor: ${globalSetting.backgroundColor}");
            debugPrint("current theme: ${globalSetting.themeMode}");

            return MaterialApp.router(
              routerConfig: goRouter,
              locale: globalSetting.locale,
              title: 'Breeze',
              themeMode: globalSetting.themeMode,
              theme: ThemeData.light().copyWith(
                  primaryColor: lightColorScheme.primary,
                  colorScheme: lightColorScheme,
                  scaffoldBackgroundColor: lightColorScheme.surface,
                  cardColor: lightColorScheme.surfaceContainer,
                  dialogBackgroundColor: lightColorScheme.surfaceContainer,
                  chipTheme: ChipThemeData(
                    backgroundColor: lightColorScheme.surface,
                  ),
                  canvasColor: lightColorScheme.surfaceContainer),
              darkTheme: ThemeData.dark().copyWith(
                  scaffoldBackgroundColor: globalSetting.isAMOLED
                      ? Colors.black
                      : darkColorScheme.surface,
                  tabBarTheme: TabBarTheme(dividerColor: Colors.transparent),
                  colorScheme: darkColorScheme),
            );
          },
        );
      },
    );
  }

  // Leave for future implementation
  buildFluentUI(BuildContext context) {}

  void updateSettings(BuildContext context) {
    bool isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    globalSetting.setThemeType(isDarkMode ? false : true);
    globalSetting.setBackgroundColor(Theme.of(context).scaffoldBackgroundColor);
    globalSetting.setTextColor(textColor);
    debugPrint("backgroundColor: ${globalSetting.backgroundColor}");
  }
}
