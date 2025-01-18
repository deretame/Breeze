import 'package:flutter/material.dart';

class ColorThemeInfo {
  Color color;
  String label;
  int index;

  ColorThemeInfo(this.color, this.label, this.index);

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
