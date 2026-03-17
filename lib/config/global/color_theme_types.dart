import 'package:zephyr/util/ui/fluent_compat.dart';

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
  ColorThemeInfo(Colors.magenta, '洋红', 1),
  ColorThemeInfo(Colors.purple, '紫色', 2),
  ColorThemeInfo(Colors.blue, '蓝色', 3),
  ColorThemeInfo(Colors.teal, '青色', 4),
  ColorThemeInfo(Colors.green, '绿色', 5),
  ColorThemeInfo(Colors.orange, '橙色', 6),
  ColorThemeInfo(Colors.yellow, '黄色', 7),
  ColorThemeInfo(Colors.grey[130], '灰色', 8),
];
