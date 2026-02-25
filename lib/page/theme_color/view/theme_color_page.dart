import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/color_theme_types.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/theme_color/theme_color.dart';

@RoutePage()
class ThemeColorPage extends StatefulWidget {
  const ThemeColorPage({super.key});

  @override
  State<ThemeColorPage> createState() => _ThemeColorPageState();
}

class _ThemeColorPageState extends State<ThemeColorPage> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = objectbox.userSettingBox.get(1)!.globalSetting.seedColor;
  }

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
                // 更新本地 UI 状态
                setState(() {
                  _currentColor = color;
                });
                // 更新全局 Cubit 状态
                _setThemeColor(color);
              },
            ),
            // 颜色块网格
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                children: colorThemeList.map((colorInfo) {
                  return ColorThemeItem(
                    colorInfo: colorInfo,
                    currentColor: _currentColor,
                    onColorSelected: (color) {
                      setState(() {
                        _currentColor = color;
                      });
                      _setThemeColor(color);
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
    context.read<GlobalSettingCubit>().updateSeedColor(color);
  }
}
