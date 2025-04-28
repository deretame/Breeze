import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/config/global/color_theme_types.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/theme_color/theme_color.dart';

@RoutePage()
class ThemeColorPage extends StatefulWidget {
  const ThemeColorPage({super.key});

  @override
  State<ThemeColorPage> createState() => _ThemeColorPageState();
}

class _ThemeColorPageState extends State<ThemeColorPage> {
  Color _currentColor = globalSetting.seedColor; // 当前选择的颜色

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('主题颜色')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 颜色选择器
            ColorPickerPage(
              currentColor: _currentColor,
              onColorChanged: (color) {
                setState(() {
                  _currentColor = color; // 更新颜色状态
                });
                _setThemeColor(color); // 更新全局主题颜色
              },
            ),
            // 颜色块网格
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 16.0, // 水平间距
                runSpacing: 16.0, // 垂直间距
                children:
                    colorThemeList.map((colorInfo) {
                      return ColorThemeItem(
                        colorInfo: colorInfo,
                        currentColor: _currentColor,
                        onColorSelected: (color) {
                          setState(() {
                            _currentColor = color; // 更新颜色状态
                          });
                          _setThemeColor(color); // 更新全局主题颜色
                        },
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setThemeColor(Color color) {
    globalSetting.setSeedColor(color);
  }
}
