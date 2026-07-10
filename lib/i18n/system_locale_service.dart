import 'dart:ui';

import 'i18n_helper.dart';

/// 系统语言、地区、时区统一信息。
class SystemLocaleInfo {
  /// 解析后的 Flutter Locale。
  final Locale locale;

  /// 原始系统 locale 字符串，如 `zh-CN`、`en-US`、`zh-Hans-CN`。
  final String rawLocale;

  /// 统一格式后的 locale 字符串，如 `zh_CN`、`en_US`。
  final String normalizedLocale;

  /// 当前时区与 UTC 的偏移量。
  final Duration timeZoneOffset;

  /// 格式化后的时区偏移，如 `+08:00`、`-05:00`。
  final String formattedTimeZone;

  /// 当前时区名称（平台相关，不建议用于逻辑判断）。
  final String timeZoneName;

  const SystemLocaleInfo({
    required this.locale,
    required this.rawLocale,
    required this.normalizedLocale,
    required this.timeZoneOffset,
    required this.formattedTimeZone,
    required this.timeZoneName,
  });
}

/// 获取并统一输出系统 locale、地区、时区信息。
///
/// 完全基于 Flutter 内置 [PlatformDispatcher]，不依赖任何原生插件，
/// 因此同时支持 Android / iOS / Windows / macOS / Linux。
///
/// 为了避免不同系统对同一语言的表达差异（如 Android 的 `zh_CN`、iOS 的
/// `zh-Hans-CN`、Windows 的 `zh-Hans-CN`），[locale] 会优先从应用支持的
/// 语言中挑选：遍历系统偏好 locale 列表，返回第一个语言代码为 `zh` 或
/// `en` 的 locale；如果都不支持，则回退到系统主 locale。
class SystemLocaleService {
  SystemLocaleService._();

  /// 获取当前系统语言/地区/时区信息。
  static Future<SystemLocaleInfo> getInfo() async {
    final systemLocales = PlatformDispatcher.instance.locales;
    final locale = systemLocales.firstWhere(
      (l) => I18nHelper.toAppLocale(l) != null,
      orElse: () => PlatformDispatcher.instance.locale,
    );
    final raw = locale.toLanguageTag();
    final offset = DateTime.now().timeZoneOffset;

    return SystemLocaleInfo(
      locale: locale,
      rawLocale: raw,
      normalizedLocale: I18nHelper.formatLocaleString(locale),
      timeZoneOffset: offset,
      formattedTimeZone: I18nHelper.formatTimeZoneOffset(offset),
      timeZoneName: DateTime.now().timeZoneName,
    );
  }

  /// 获取系统偏好 locale 字符串列表（按优先级排序）。
  static Future<List<String>> getPreferredLanguages() async {
    return PlatformDispatcher.instance.locales
        .map((locale) => locale.toLanguageTag())
        .toList();
  }
}
