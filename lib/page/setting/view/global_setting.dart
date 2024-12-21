import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';

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

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('全局设置'),
      ),
      body: Column(
        children: [
          Row(
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
                        child: Text(
                            value), // 或者使用 systemTheme[value]!.toString()，但直接使用字符串更简单
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
          ),
        ],
      ),
    );
  }
}
