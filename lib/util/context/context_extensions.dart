import 'package:fluent_ui/fluent_ui.dart';

/// A lightweight theme adapter so existing code can keep using
/// `context.theme.colorScheme.xxx` and `context.theme.textTheme.xxx`
/// while we migrate the UI layer from Material to Fluent UI.
///
/// This is intentionally not a 1:1 Material mapping; it only provides the
/// subset of tokens this project currently relies on.
class AppThemeData {
  AppThemeData(this.fluent, {this.dividerColor});

  final FluentThemeData fluent;
  final Color? dividerColor;

  Brightness get brightness => fluent.brightness;

  AppColorScheme get colorScheme => AppColorScheme(fluent);

  AppTextTheme get textTheme => AppTextTheme(fluent);

  Color get scaffoldBackgroundColor => fluent.scaffoldBackgroundColor;

  AppThemeData copyWith({Color? dividerColor}) {
    return AppThemeData(
      fluent,
      dividerColor: dividerColor ?? this.dividerColor,
    );
  }
}

class AppTextTheme {
  AppTextTheme(this._theme);

  final FluentThemeData _theme;

  Typography get _typo => _theme.typography;

  TextStyle? get titleLarge => _typo.title;

  TextStyle? get titleMedium => _typo.subtitle;

  TextStyle? get titleSmall => _typo.bodyStrong;

  TextStyle? get labelLarge => _typo.bodyStrong;

  TextStyle? get bodyMedium => _typo.body;

  TextStyle? get bodySmall => _typo.caption;
}

class AppColorScheme {
  AppColorScheme(this._theme);

  final FluentThemeData _theme;

  AccentColor get _accent => _theme.accentColor;
  Brightness get _brightness => _theme.brightness;
  ResourceDictionary get _res => _theme.resources;

  // Accent colors
  Color get primary => _accent.defaultBrushFor(_brightness);
  Color get primaryFixedDim => _accent.secondaryBrushFor(_brightness);
  Color get primaryContainer => _accent.tertiaryBrushFor(_brightness);

  Color get secondaryFixed => _accent.secondaryBrushFor(_brightness);
  Color get secondaryFixedDim => _accent.tertiaryBrushFor(_brightness);
  Color get secondaryContainer => _res.cardBackgroundFillColorDefault;

  Color get tertiary => _accent.normal;

  // Surfaces
  Color get surface => _theme.scaffoldBackgroundColor;
  Color get surfaceBright => _res.solidBackgroundFillColorBase;
  Color get surfaceTint => primary.withValues(alpha: 0.20);

  Color get surfaceContainerLow => _res.cardBackgroundFillColorSecondary;
  Color get surfaceContainerHigh => _res.cardBackgroundFillColorDefault;
  Color get surfaceContainerHighest => _res.cardBackgroundFillColorTertiary;

  // Outlines
  Color get outline => _res.controlStrokeColorDefault;
  Color get outlineVariant =>
      _res.controlStrokeColorDefault.withValues(alpha: 0.6);

  // "On" colors
  Color get onSurface => _res.textFillColorPrimary;
  Color get onSurfaceVariant => _res.textFillColorSecondary;
  Color get onInverseSurface => _res.textFillColorInverse;

  Color get onPrimary => _res.textOnAccentFillColorPrimary;
  Color get onPrimaryContainer => _res.textOnAccentFillColorPrimary;
  Color get onSecondaryContainer => _res.textOnAccentFillColorPrimary;

  // Misc
  Color get error => Colors.errorPrimaryColor;

  // Additional Material colors compatibility
  Color get pink => const Color(0xFFE91E63);
  Color get black54 => const Color(0x8A000000);
  Color get errorContainer => const Color(0xFFF9DEDC);
  Color get onErrorContainer => const Color(0xFF410E0B);
}

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

  // 获取主题（Fluent 适配层）
  AppThemeData get theme => AppThemeData(FluentTheme.of(this));

  /// 获取当前是否为亮色模式 (true: 亮色, false: 暗色)
  bool get isLightMode => theme.brightness == Brightness.light;

  /// 获取当前主题的背景颜色 (通常是页面背景色)
  Color get backgroundColor => theme.scaffoldBackgroundColor;

  /// 获取当前主题的主要文字颜色
  Color get textColor => theme.colorScheme.onSurface;
}
