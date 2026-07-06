/// 递归将非 JSON 友好的 Dart 对象转换为可序列化的基础类型。
///
/// - null / String / num / bool 直接返回
/// - DateTime 转为 ISO 8601 字符串
/// - Map / List 递归处理
/// - 其他对象优先调用 toJson()，失败则转为 toString()
dynamic sanitizeDynamic(dynamic value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }

  if (value is DateTime) {
    return value.toIso8601String();
  }

  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), sanitizeDynamic(item)),
    );
  }

  if (value is List) {
    return value.map(sanitizeDynamic).toList();
  }

  try {
    final json = (value as dynamic).toJson();
    return sanitizeDynamic(json);
  } catch (_) {
    return value.toString();
  }
}
