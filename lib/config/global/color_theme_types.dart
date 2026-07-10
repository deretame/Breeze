import 'package:flutter/material.dart';
import 'package:zephyr/i18n/strings.g.dart';

class ColorThemeInfo {
  Color color;
  String label;
  int index;

  ColorThemeInfo(this.color, this.label, this.index);

  /// 用户界面显示的本地化颜色名称。
  String get localizedLabel {
    return switch (index) {
      0 => t.settings.colorRed,
      1 => t.settings.colorPink,
      2 => t.settings.colorPurple,
      3 => t.settings.colorDeepPurple,
      4 => t.settings.colorIndigo,
      5 => t.settings.colorBlue,
      6 => t.settings.colorLightBlue,
      7 => t.settings.colorCyan,
      8 => t.settings.colorTeal,
      9 => t.settings.colorGreen,
      10 => t.settings.colorLightGreen,
      11 => t.settings.colorLime,
      12 => t.settings.colorYellow,
      13 => t.settings.colorAmber,
      14 => t.settings.colorOrange,
      15 => t.settings.colorDeepOrange,
      16 => t.settings.colorBrown,
      17 => t.settings.colorGrey,
      18 => t.settings.colorBlueGrey,
      _ => label,
    };
  }

  @override
  String toString() {
    return 'ColorThemeInfo(color: $color, label: $label, index: $index)';
  }
}

final List<ColorThemeInfo> colorThemeList = [
  ColorThemeInfo(Colors.red, '红色', 0),
  ColorThemeInfo(Colors.pink, '粉色', 1),
  ColorThemeInfo(Colors.purple, '紫色', 2),
  ColorThemeInfo(Colors.deepPurple, '深紫色', 3),
  ColorThemeInfo(Colors.indigo, '靛蓝色', 4),
  ColorThemeInfo(Colors.blue, '蓝色', 5),
  ColorThemeInfo(Colors.lightBlue, '浅蓝色', 6),
  ColorThemeInfo(Colors.cyan, '青色', 7),
  ColorThemeInfo(Colors.teal, '水鸭色', 8),
  ColorThemeInfo(Colors.green, '绿色', 9),
  ColorThemeInfo(Colors.lightGreen, '浅绿色', 10),
  ColorThemeInfo(Colors.lime, '酸橙色', 11),
  ColorThemeInfo(Colors.yellow, '黄色', 12),
  ColorThemeInfo(Colors.amber, '琥珀色', 13),
  ColorThemeInfo(Colors.orange, '橙色', 14),
  ColorThemeInfo(Colors.deepOrange, '深橙色', 15),
  ColorThemeInfo(Colors.brown, '棕色', 16),
  ColorThemeInfo(Colors.grey, '灰色', 17),
  ColorThemeInfo(Colors.blueGrey, '蓝灰色', 18),
];
