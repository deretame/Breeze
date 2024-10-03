import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mmkv/mmkv.dart';
import 'package:system_theme/system_theme.dart';
import 'package:zephyr/util/router.dart';

import 'config/global.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // must wait for MMKV to finish initialization
  if (kDebugMode) {
    await MMKV.initialize();
  } else {
    await MMKV.initialize(logLevel: MMKVLogLevel.None);
  }
  SystemTheme.fallbackColor = const Color(0xFF64B5F6);
  await SystemTheme.accentColor.load();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  // 默认主题色种子
  static const _defaultColorSeed = Colors.blueAccent;

  // 根组件
  @override
  Widget build(BuildContext context) {
    // 初始化全局变量
    Global(context);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // 亮色模式 Monet 取色
          lightColorScheme = lightDynamic.harmonized();
          // 暗色模式 Monet 取色
          darkColorScheme = darkDynamic.harmonized();
        } else {
          // Fallback 颜色，当不支持 Monet 取色的时候使用
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: _defaultColorSeed,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: _defaultColorSeed,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp.router(
          locale: Locale('zh'),
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            //此处设置
            const Locale('zh', 'CH'),
            const Locale('en', 'US'),
          ],
          routerConfig: goRouter,
          // 亮色模式主题，直接调用获取到的 ColorScheme
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightColorScheme,
            // ...
          ),
          // 暗色模式主题，同上
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: darkColorScheme,
            // ...
          ),
          // 设置主题跟随系统
          themeMode: ThemeMode.system,
          // ...
        );
      },
    );
  }
}
