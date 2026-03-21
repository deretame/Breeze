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
