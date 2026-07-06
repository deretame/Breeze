/// 递归提取一个对象的结构签名，仅保留类型信息，用于调试。
///
/// - Map 保留 key → 类型签名
/// - 空 List 返回 "List"，非空 List 返回 `[首元素类型签名]`
/// - 其他返回 runtimeType 字符串
Object getStructure(dynamic input) {
  if (input is Map) {
    return input.map((key, value) => MapEntry(key, getStructure(value)));
  } else if (input is List) {
    return input.isEmpty ? 'List' : [getStructure(input.first)];
  } else {
    return input.runtimeType.toString();
  }
}
