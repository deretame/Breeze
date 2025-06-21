/// 递归替换所有 null 为空字符串，但保留字符串 "null"
dynamic _replaceNestedNull(dynamic value) {
  // 1. 处理 Map 类型
  if (value is Map<String, dynamic>) {
    Map<String, dynamic> result = {};
    value.forEach((key, val) {
      result[key] = _replaceNestedNull(val); // 递归处理每个值
    });
    return result;
  }
  // 2. 处理 List 类型
  else if (value is List) {
    return value.map((item) => _replaceNestedNull(item)).toList(); // 递归处理每个元素
  }
  // 3. 处理 null 值
  else if (value == null) {
    return ""; // 替换 null 为空字符串
  }
  // 4. 其他类型直接返回原值
  else {
    return value;
  }
}

Map<String, dynamic> replaceNestedNull(Map<String, dynamic> json) {
  return _replaceNestedNull(json) as Map<String, dynamic>;
}

dynamic replaceNestedNullList(dynamic json) {
  return _replaceNestedNull(json) as dynamic;
}
