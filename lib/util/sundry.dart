// 一些工具函数
import 'package:zephyr/src/rust/api/simple.dart';

// 用来简化调用，将繁体中文转换为简体中文
String t2s(String text) {
  return traditionalToSimplified(text: text);
}
