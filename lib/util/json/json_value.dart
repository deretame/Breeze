import 'dart:convert';

Map<String, dynamic> asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map((entry) => MapEntry(entry.key.toString(), entry.value)),
    );
  }
  return const <String, dynamic>{};
}

List<dynamic> asJsonList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

List<Map<String, dynamic>> asJsonListOfMaps(dynamic value) {
  return asJsonList(
    value,
  ).whereType<Map>().map((item) => asJsonMap(item)).toList();
}

Map<String, dynamic> requireJsonMap(
  dynamic value, {
  String message = 'JSON map expected',
}) {
  final map = asJsonMap(value);
  if (map.isNotEmpty || value is Map) {
    return map;
  }
  throw FormatException('$message: ${value.runtimeType}');
}

Map<String, dynamic> decodeJsonMap(String raw) {
  if (raw.trim().isEmpty) {
    return const <String, dynamic>{};
  }
  try {
    final decoded = jsonDecode(raw);
    return asJsonMap(decoded);
  } catch (_) {
    return const <String, dynamic>{};
  }
}

List<dynamic> decodeJsonList(String raw) {
  if (raw.trim().isEmpty) {
    return const <dynamic>[];
  }
  try {
    final decoded = jsonDecode(raw);
    return asJsonList(decoded);
  } catch (_) {
    return const <dynamic>[];
  }
}

List<Map<String, dynamic>> decodeJsonListOfMaps(String raw) {
  return decodeJsonList(
    raw,
  ).whereType<Map>().map((item) => asJsonMap(item)).toList();
}

/// 将任意值安全转换为 int。无法转换时返回 0。
int intFromDynamic(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

/// 将任意值安全转换为 String。null 返回空字符串。
String stringFromDynamic(dynamic value) => value?.toString() ?? '';

/// 将任意值转换为 bool。仅当值严格等于 true 时返回 true。
bool boolFromDynamic(dynamic value) => value == true;

/// 将任意值安全转换为 `Map<String, dynamic>`。
Map<String, dynamic> mapFromDynamic(dynamic value) => asJsonMap(value);
