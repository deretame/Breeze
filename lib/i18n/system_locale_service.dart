import 'dart:ui';

import 'package:zephyr/src/rust/api/localization.dart' as rust_localization;

import 'package:zephyr/i18n/i18n_helper.dart';

/// 系统语言、地区、时区统一信息。
class SystemLocaleInfo {
  /// 解析后的 Flutter Locale。
  final Locale locale;

  /// 经 Rust 侧 ICU4X 规范化后的 BCP-47 locale 字符串，如 `zh-CN`、`en-US`。)
  final String rawLocale;

  /// 统一格式后的 locale 字符串，如 `zh_CN`、`en_US`。
  final String normalizedLocale;

  /// 当前时区与 UTC 的偏移量。
  final Duration timeZoneOffset;

  /// 格式化后的时区偏移，如 `+08:00`、`-05:00`。
  final String formattedTimeZone;

  /// 当前时区 IANA 名称（已规范化）。
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
/// 语言/时区均通过 Rust 侧 `sys-locale` / `iana-time-zone` / `tz-rs` / ICU4X 获取，
/// 不再依赖 Flutter [PlatformDispatcher]，因此行为在各平台更一致。
class SystemLocaleService {
  SystemLocaleService._();

  /// 获取当前系统语言/地区/时区信息。
  static Future<SystemLocaleInfo> getInfo() async {
    // 优先从 Rust 侧获取系统语言列表。
    final languages = _getSystemLanguages();

    // 挑选应用支持的第一个语言；如果没有匹配项，则回退到列表第一个。
    final raw = languages.firstWhere(
      (tag) => I18nHelper.toAppLocale(I18nHelper.localeFromBcp47(tag)) != null,
      orElse: () => languages.first,
    );

    final locale = I18nHelper.localeFromBcp47(raw);

    // 时区信息优先从 Rust 侧获取，失败时回退到 Flutter 内置值。
    final timeZoneName =
        _try(() => rust_localization.getSystemTimezone()) ??
        DateTime.now().timeZoneName;
    final formattedTimeZone =
        _try(() => rust_localization.getSystemTimezoneOffset()) ??
        I18nHelper.formatTimeZoneOffset(DateTime.now().timeZoneOffset);

    return SystemLocaleInfo(
      locale: locale,
      rawLocale: raw,
      normalizedLocale: I18nHelper.formatLocaleString(locale),
      timeZoneOffset: I18nHelper.parseTimeZoneOffset(formattedTimeZone),
      formattedTimeZone: formattedTimeZone,
      timeZoneName: timeZoneName,
    );
  }

  /// 获取系统偏好 locale 字符串列表（按优先级排序）。
  static Future<List<String>> getPreferredLanguages() async {
    return _getSystemLanguages();
  }

  static List<String> _getSystemLanguages() {
    return _try(() => rust_localization.getSystemLanguages()) ??
        PlatformDispatcher.instance.locales
            .map((locale) => locale.toLanguageTag())
            .toList();
  }

  static T? _try<T>(T Function() fn) {
    try {
      return fn();
    } catch (_) {
      return null;
    }
  }
}
