import 'package:material_ui/material_ui.dart';

extension ContextExtensions on BuildContext {
  // 获取屏幕尺寸（只订阅 size，键盘弹起不触发 rebuild，见 flutter/flutter#163516）
  Size get screenSize => MediaQuery.sizeOf(this);

  // 获取屏幕宽度
  double get screenWidth => MediaQuery.sizeOf(this).width;

  // 获取屏幕高度
  double get screenHeight => MediaQuery.sizeOf(this).height;

  // 获取状态栏高度
  double get statusBarHeight => MediaQuery.paddingOf(this).top;

  // 获取底部安全区域高度
  double get bottomSafeHeight => MediaQuery.paddingOf(this).bottom;
  double get devicePixelRatio => MediaQuery.devicePixelRatioOf(this);

  // 获取主题
  ThemeData get theme => Theme.of(this);

  /// 获取当前是否为亮色模式 (true: 亮色, false: 暗色)
  bool get isLightMode => theme.brightness == Brightness.light;

  /// 获取当前主题的背景颜色 (通常是 Scaffold 或页面的背景色)
  Color get backgroundColor => theme.scaffoldBackgroundColor;

  /// 获取当前主题的主要文字颜色 (在背景色 `onSurface` 上显示的颜色)
  Color get textColor => theme.colorScheme.onSurface;
}
