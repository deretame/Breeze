import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  // 获取屏幕尺寸
  Size get screenSize => MediaQuery.of(this).size;

  // 获取屏幕宽度
  double get screenWidth => MediaQuery.of(this).size.width;

  // 获取屏幕高度
  double get screenHeight => MediaQuery.of(this).size.height;

  // 获取状态栏高度
  double get statusBarHeight => MediaQuery.of(this).padding.top;

  // 获取主题
  ThemeData get theme => Theme.of(this);
}
