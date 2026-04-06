// --- Json Converters ---

import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';

/// 将 Color 转换为 int (color.value) 以便存入 JSON，反之亦然。
class ColorConverter implements JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) => Color(json);

  @override
  int toJson(Color object) => object.toARGB32();
}

/// 将 Locale 转换为 String (例如 "zh_CN") 以便存入 JSON，反之亦然。
class LocaleConverter implements JsonConverter<Locale, String> {
  const LocaleConverter();

  @override
  Locale fromJson(String json) {
    final parts = json.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    return Locale(parts[0]);
  }

  @override
  String toJson(Locale object) {
    if (object.countryCode != null) {
      return '${object.languageCode}_${object.countryCode}';
    }
    return object.languageCode;
  }
}

// 将 DateTime 转换为 String (ISO 8601) 以便存入 JSON，反之亦然。
class DateTimeConverter implements JsonConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime object) => object.toIso8601String();
}
