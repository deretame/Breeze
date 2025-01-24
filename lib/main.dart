import 'package:catcher_2/catcher_2.dart';
import 'package:dio/dio.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:event_bus/event_bus.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 重采样触控刷新率
  GestureBinding.instance.resamplingEnabled = true;

  objectbox = await ObjectBox.create();

  await manageCacheSize();

  // 告诉系统应该用竖屏
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );

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

    globalSetting.setThemeType(!isDarkMode);
    globalSetting.setBackgroundColor(materialColorScheme.surfaceBright);
    globalSetting.setTextColor(materialColorScheme.onSurface);

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
              lightColorScheme = lightDynamic ??
                  ColorScheme.fromSeed(
                    seedColor: globalSetting.seedColor, // 默认颜色
                    brightness: Brightness.light,
                  );
              darkColorScheme = darkDynamic ??
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
                scaffoldBackgroundColor: globalSetting.isAMOLED
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
