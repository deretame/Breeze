import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';

import '../../../util/router/router.gr.dart';
import '../../../util/webdav.dart';
import 'global/widgets.dart';

@RoutePage()
class GlobalSettingPage extends StatefulWidget {
  const GlobalSettingPage({super.key});

  @override
  State<GlobalSettingPage> createState() => _GlobalSettingPageState();
}

class _GlobalSettingPageState extends State<GlobalSettingPage> {
  late final List<String> systemThemeList = ["跟随系统", "浅色模式", "深色模式"];
  late final Map<String, int> systemTheme = {
    "跟随系统": 0,
    "浅色模式": 1,
    "深色模式": 2,
  };

  bool _dynamicColorValue = globalSetting.dynamicColor;
  bool _isAMOLEDValue = globalSetting.isAMOLED;
  bool _autoSyncValue = globalSetting.autoSync;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('全局设置'),
      ),
      body: Observer(
        builder: (context) => Column(
          children: [
            _systemTheme(),
            _dynamicColor(),
            if (!globalSetting.dynamicColor) ...[
              SizedBox(height: 11),
              changeThemeColor(context),
              SizedBox(height: 11),
            ],
            _isAMOLED(),
            // divider(),
            // SizedBox(height: 10),
            // webdavSync(context),
            // SizedBox(height: 10),
            // if (globalSetting.webdavHost.isNotEmpty) ...[
            //   _autoSync(),
            // ],
            if (kDebugMode) ...[
              ElevatedButton(
                onPressed: () {
                  AutoRouter.of(context).push(ShowColorRoute());
                },
                child: Text("整点颜色看看"),
              ),
            ],
            if (kDebugMode) ...[
              ElevatedButton(
                onPressed: () async {
                  var temp = await getLastModifiedTime("/Breeze/history.zst");
                  debugPrint("temp: ${temp.toString()}");
                },
                child: Text("测试用的玩意儿"),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _systemTheme() {
    String currentTheme = "";

    // 通过 int 类型的主题模式获取对应的字符串
    switch (globalSetting.getThemeMode()) {
      case ThemeMode.system:
        currentTheme = "跟随系统";
        break;
      case ThemeMode.light:
        currentTheme = "浅色模式";
        break;
      case ThemeMode.dark:
        currentTheme = "深色模式";
        break;
    }

    return Row(
      children: [
        SizedBox(width: 10),
        Text(
          "主题模式",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        Expanded(child: Container()),
        Observer(builder: (context) {
          return DropdownButton<String>(
            value: currentTheme,
            // 根据获取的主题设置当前值
            icon: const Icon(Icons.expand_more),
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  // 根据选择的主题更新设置
                  globalSetting.setThemeMode(systemTheme[value]!);
                });
              }
            },
            items: systemThemeList.map<DropdownMenuItem<String>>(
              (String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              },
            ).toList(),
            style: TextStyle(
              color: globalSetting.textColor,
              fontSize: 18,
            ),
          );
        }),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _dynamicColor() {
    return Row(
      children: [
        SizedBox(width: 10),
        Text(
          "动态取色",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        SizedBox(width: 5), // 添加间距
        Tooltip(
          message: "动态取色是一种根据图片或内容自动调整界面主题颜色的功能。\n"
              "启用后，系统会分析当前页面的主要颜色，并自动调整界面元素的颜色以匹配整体风格，提供更一致的视觉体验。",
          triggerMode: TooltipTriggerMode.tap, // 点击触发
          child: Icon(
            Icons.help_outline, // 问号图标
            size: 20,
            color: materialColorScheme.outlineVariant,
          ),
        ),
        Spacer(),
        Switch(value: _dynamicColorValue, onChanged: changeDynamicColor),
        SizedBox(width: 10),
      ],
    );
  }

  void changeDynamicColor(bool value) {
    setState(() {
      _dynamicColorValue = !_dynamicColorValue;
    });
    globalSetting.setDynamicColor(_dynamicColorValue);
  }

  Widget _isAMOLED() {
    return Row(
      children: [
        SizedBox(width: 10),
        Text(
          "纯黑模式",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        SizedBox(width: 5), // 添加间距
        Tooltip(
          message: "纯黑模式专为 AMOLED 屏幕设计。\n"
              "由于 AMOLED 屏幕的像素点可以单独发光，显示纯黑色时像素点会完全关闭，从而达到省电的效果。\n"
              "如果您的设备不是 AMOLED 屏幕，开启此模式将不会有明显的省电效果。",
          triggerMode: TooltipTriggerMode.tap, // 点击触发
          child: Icon(
            Icons.help_outline, // 问号图标
            size: 20,
            color: materialColorScheme.outlineVariant,
          ),
        ),
        Spacer(),
        Switch(value: _isAMOLEDValue, onChanged: changeIsAMOLED),
        SizedBox(width: 10),
      ],
    );
  }

  void changeIsAMOLED(bool value) {
    setState(() {
      _isAMOLEDValue = !_isAMOLEDValue;
    });
    globalSetting.setIsAMOLED(_isAMOLEDValue);
  }

  Widget _autoSync() {
    return Row(
      children: [
        SizedBox(width: 10),
        Text(
          "自动同步",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        Spacer(),
        Switch(value: _autoSyncValue, onChanged: changeAutoSync),
        SizedBox(width: 10),
      ],
    );
  }

  void changeAutoSync(bool value) {
    setState(() {
      _autoSyncValue = !_autoSyncValue;
    });
    globalSetting.setAutoSync(_autoSyncValue);
  }
}
