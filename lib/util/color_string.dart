import 'dart:ui';

String colorToRgbaString(Color color) {
  // 获取颜色的 RGBA 值
  int red = (color.r * 255).toInt();
  int green = (color.g.toInt() * 255).toInt();
  int blue = (color.b.toInt() * 255).toInt();
  double alpha = color.a;

  // 返回格式为 "R,G,B,A" 的字符串
  return '$red,$green,$blue,$alpha';
}

Color rgbaStringToColor(String rgbaString) {
  // 将字符串按逗号分割为四个部分
  List<String> parts = rgbaString.split(',');

  // 解析 RGBA 值
  int red = int.parse(parts[0]);
  int green = int.parse(parts[1]);
  int blue = int.parse(parts[2]);
  double alpha = double.parse(parts[3]);

  // 返回 Color 对象
  return Color.fromRGBO(red, green, blue, alpha);
}
