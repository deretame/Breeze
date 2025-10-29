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

  // 获取底部安全区域高度
  double get bottomSafeHeight => MediaQuery.of(this).padding.bottom;
  double get devicePixelRatio => MediaQuery.of(this).devicePixelRatio;

  // 获取主题
  ThemeData get theme => Theme.of(this);

  /// 获取当前是否为亮色模式 (true: 亮色, false: 暗色)
  bool get isLightMode => theme.brightness == Brightness.light;

  /// 获取当前主题的背景颜色 (通常是 Scaffold 或页面的背景色)
  Color get backgroundColor => theme.scaffoldBackgroundColor;

  /// 获取当前主题的主要文字颜色 (在背景色 `onSurface` 上显示的颜色)
  Color get textColor => theme.colorScheme.onSurface;
}
