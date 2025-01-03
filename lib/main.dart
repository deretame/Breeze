import 'dart:io';

import 'package:catcher_2/catcher_2.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/manage_cache.dart';
import 'package:zephyr/util/router/router.dart';

import 'config/global.dart';
import 'config/global_setting.dart';
import 'config/theme_mode_adapter.dart';
import 'mobx/fullscreen_store.dart';
import 'network/dio_cache.dart';
import 'object_box/object_box.dart';

final globalSetting = GlobalSetting();
final bikaSetting = BikaSetting();
final fullScreenStore = FullScreenStore();
late final ObjectBox objectbox;

// 定义全局Dio实例
final dio = Dio();
// 定义缓存拦截器
final cacheInterceptor = DioCacheInterceptor(ExpiringMemoryCache());
final appRouter = AppRouter();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 重采样触控刷新率
  GestureBinding.instance.resamplingEnabled = true;

  objectbox = await ObjectBox.create();

  await manageCacheSize();

  // 告诉系统应该用竖屏
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  // 初始化Hive
  await Hive.initFlutter();
  // 注册 Color 适配器
  Hive.registerAdapter(ColorAdapter());
  Hive.registerAdapter(ThemeModeAdapter());
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // 在初始化时不进行基于上下文的设置
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里进行基于上下文的设置
    _updateThemeSettings();
  }

  void _updateThemeSettings() {
    var isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    debugPrint("isDarkMode: $isDarkMode");
    if (globalSetting.themeMode == ThemeMode.dark) {
      isDarkMode = true;
    } else if (globalSetting.themeMode == ThemeMode.light) {
      isDarkMode = false;
    }
    debugPrint("isDarkMode: $isDarkMode");
    var primary = globalSetting.seedColor;

    // 使用种子颜色创建颜色方案
    var lightColorScheme = ColorScheme.fromSeed(
      seedColor: primary,
    );
    var darkColorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    );

    // 根据当前主题模式选择对应的 ColorScheme
    ColorScheme currentColorScheme;
    if (globalSetting.themeMode == ThemeMode.dark) {
      currentColorScheme = darkColorScheme;
    } else if (globalSetting.themeMode == ThemeMode.light) {
      currentColorScheme = lightColorScheme;
    } else {
      // ThemeMode.system
      currentColorScheme = isDarkMode ? darkColorScheme : lightColorScheme;
    }

    // 更新设置
    globalSetting.setThemeType(!isDarkMode);
    globalSetting.setBackgroundColor(currentColorScheme.surface);
    globalSetting.setTextColor(isDarkMode ? Colors.white : Colors.black);

    // Debug 信息
    debugPrint("themeType: ${globalSetting.themeType}");
    debugPrint("backgroundColor: ${globalSetting.backgroundColor}");
    debugPrint("current theme: ${globalSetting.themeMode}");
    debugPrint("textColor: ${globalSetting.textColor}");
  }

  @override
  Widget build(BuildContext context) {
    // 设置这个的目的是为了缓解图片重载
    PaintingBinding.instance.imageCache.maximumSizeBytes = 500 * 1024 * 1024;

    Global(context);
    if (statusBarHeight == 0) {
      statusBarHeight = MediaQuery.of(context).padding.top;
    }
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ));

    return Observer(
      builder: (context) {
        final primary = globalSetting.seedColor;

        // 使用种子颜色创建颜色方案
        final lightColorScheme = ColorScheme.fromSeed(
          seedColor: primary,
        );
        final darkColorScheme = ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        );

        // 根据当前主题模式选择对应的 ColorScheme
        globalSetting.themeMode == ThemeMode.dark
            ? darkColorScheme
            : lightColorScheme;
        _updateThemeSettings();
        return MaterialApp.router(
          routerConfig: appRouter.config(),
          builder: EasyLoading.init(),
          locale: globalSetting.locale,
          title: 'Breeze',
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
            dialogBackgroundColor: lightColorScheme.surfaceContainer,
            chipTheme: ChipThemeData(
              backgroundColor: lightColorScheme.surface,
            ),
            canvasColor: lightColorScheme.surfaceContainer,
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor:
                globalSetting.isAMOLED ? Colors.black : darkColorScheme.surface,
            tabBarTheme: TabBarTheme(dividerColor: Colors.transparent),
            colorScheme: darkColorScheme,
          ),
        );
      },
    );
  }
}
