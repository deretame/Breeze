import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 用来统一管理应用的默认颜色和主题类型
class DefaultColorNotifier extends ChangeNotifier {
  late Color? _defaultTextColor;
  late Color _defaultBackgroundColor;
  late Brightness _brightness;
  late bool _themeType;
  late double _screenWidth;

  BuildContext? context;

  void initialize(BuildContext context) {
    _defaultTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    _defaultBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    _brightness = MediaQuery.of(context).platformBrightness;
    _themeType = _brightness == Brightness.light;
    _screenWidth = MediaQuery.of(context).size.width;
  }

  Color? get defaultTextColor => _defaultTextColor;

  Color get defaultBackgroundColor => _defaultBackgroundColor;

  bool get themeType => _themeType;

  double get screenWidth => _screenWidth;

  void updateScreenWidth(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    notifyListeners();
  }

  void updateDefaultTextColor(BuildContext context) {
    _defaultTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    notifyListeners();
  }

  void updateDefaultBackgroundColor(BuildContext context) {
    _defaultBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    notifyListeners();
  }

  void updateBrightness(Brightness brightness, BuildContext context) {
    _brightness = brightness;
    _themeType = _brightness == Brightness.light;
    _defaultBackgroundColor = _themeType ? Colors.white : Colors.black;
    notifyListeners();
  }

  void updateThemeType(BuildContext context) {
    _themeType = _brightness == Brightness.light;
    _defaultBackgroundColor = _themeType ? Colors.white : Colors.black;
    notifyListeners();
  }
}

final defaultColorProvider = ChangeNotifierProvider<DefaultColorNotifier>(
  (ref) {
    final notifier = DefaultColorNotifier();
    return notifier;
  },
);
