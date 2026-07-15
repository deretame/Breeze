import 'dart:ui';

import 'package:zephyr/src/rust/api/qjs.dart';

import 'package:zephyr/i18n/strings.g.dart';

/// i18n 辅助函数：locale 映射、时区格式化、Rust 错误语言联动。
class I18nHelper {
  I18nHelper._();

  /// [AppLocale] 到 Flutter [Locale] 的映射。
  ///
  /// 新增语言时在这里补充对应的国家/地区代码；未补充时回退到只有 languageCode。
  static const Map<AppLocale, Locale> _flutterLocaleMap = {
    AppLocale.zhCn: Locale('zh', 'CN'),
    AppLocale.enUs: Locale('en', 'US'),
  };

  /// 将 [AppLocale] 映射为带国家/地区代码的 Flutter [Locale]。
  static Locale toFlutterLocale(AppLocale locale) {
    return _flutterLocaleMap[locale] ?? Locale(locale.languageCode);
  }

  /// 将 Flutter [Locale] 匹配为 [AppLocale]，不匹配时返回 null。
  ///
  /// 通过遍历 [AppLocale.values] 实现，新增语言后无需修改此处。
  static AppLocale? toAppLocale(Locale locale) {
    final code = locale.languageCode.toLowerCase();
    for (final appLocale in AppLocale.values) {
      if (appLocale.languageCode.toLowerCase() == code) {
        return appLocale;
      }
    }
    return null;
  }

  /// 尝试从任意 locale 字符串匹配 [AppLocale]。
  ///
  /// 新增语言后无需修改此处。
  static AppLocale? parseAppLocale(String? value) {
    if (value == null || value.isEmpty) return null;
    final languageCode = value.split(RegExp(r'[-_]')).first.toLowerCase();
    for (final appLocale in AppLocale.values) {
      if (appLocale.languageCode.toLowerCase() == languageCode) {
        return appLocale;
      }
    }
    return null;
  }

  /// 返回 [AppLocale] 在用户界面中的显示名称。
  ///
  /// 新增语言时需要在这里和翻译文件中补充对应的显示名称。
  static String displayName(AppLocale locale) {
    return switch (locale) {
      AppLocale.zhCn => t.settings.languageZhCn,
      AppLocale.enUs => t.settings.languageEnUs,
    };
  }

  /// 将 [Locale] 格式化为统一的 `languageCode_COUNTRYCODE` 字符串。
  static String formatLocaleString(Locale locale) {
    if (locale.countryCode != null && locale.countryCode!.isNotEmpty) {
      return '${locale.languageCode}_${locale.countryCode!.toUpperCase()}';
    }
    return locale.languageCode;
  }

  /// 将时区偏移格式化为 `+HH:mm` / `-HH:mm`。
  static String formatTimeZoneOffset(Duration offset) {
    final totalMinutes = offset.inMinutes.abs();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final sign = offset.inMinutes >= 0 ? '+' : '-';
    return '$sign${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// 将 `+HH:mm` / `-HH:mm` 解析为 [Duration]。
  static Duration parseTimeZoneOffset(String formatted) {
    final sign = formatted.startsWith('-') ? -1 : 1;
    final parts = formatted.substring(1).split(':');
    if (parts.length != 2) return Duration.zero;
    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    return Duration(minutes: sign * (hours * 60 + minutes));
  }

  /// 将 BCP-47 语言标签解析为 Flutter [Locale]。
  static Locale localeFromBcp47(String tag) {
    final parts = tag.split('-');
    var language = parts.first.toLowerCase();
    String? script;
    String? region;
    for (var i = 1; i < parts.length; i++) {
      final part = parts[i];
      if (part.length == 4 && _isAlpha(part)) {
        script = part;
      } else if ((part.length == 2 || part.length == 3) && _isAlpha(part)) {
        region = part.toUpperCase();
      }
    }
    return Locale.fromSubtags(
      languageCode: language,
      scriptCode: script,
      countryCode: region,
    );
  }

  static bool _isAlpha(String s) =>
      s.codeUnits.every((c) => (c >= 65 && c <= 90) || (c >= 97 && c <= 122));

  /// 同步 Rust 侧 QuickJS 错误消息语言。
  ///
  /// 传递 BCP-47 语言标签（如 `zh-CN`、`en-US`）。
  static void setRustErrorLanguage(AppLocale locale) {
    final flutterLocale = toFlutterLocale(locale);
    setQjsErrorMessageLanguage(lang: flutterLocale.toLanguageTag());
  }
}
