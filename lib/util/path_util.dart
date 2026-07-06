import 'package:path/path.dart' as p;

/// 将任意字符串清理为可作为文件/路径段的安全名称。
///
/// 只保留字母、数字、下划线、连字符和点号，其余字符替换为下划线，
/// 并压缩连续下划线、去除首尾下划线。若结果为空则返回 [fallback]。
String sanitizePathSegment(String input, {String fallback = 'cover'}) {
  final sanitized = input
      .replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return sanitized.isEmpty ? fallback : sanitized;
}

/// 从图片 URL 中提取扩展名。
///
/// 只返回由字母数字组成、长度 1-8 的扩展名，否则返回 'jpg'。
String extractImageExtension(String url) {
  try {
    final uri = Uri.parse(url);
    final ext = p.extension(uri.path).replaceFirst('.', '').toLowerCase();
    if (RegExp(r'^[a-z0-9]{1,8}$').hasMatch(ext)) {
      return ext;
    }
  } catch (_) {}
  return 'jpg';
}
