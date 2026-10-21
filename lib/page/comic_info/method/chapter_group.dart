/// 章节视觉分组契约。
///
/// 数据层保持扁平（`List<Ep>` 仍是唯一真相，`order` 全局唯一排序），
/// 分组只做在展示层：
///
/// - `groupTitle` 为空 = 不分组，老数据/单列插件直接走现有扁平路径；
/// - 非空 = 同组章节，组顺序按在列表中首次出现的顺序推导，不另存顺序 key。
library;

/// 解析分组 key，空串表示不分组。
///
/// 只读顶层 `groupTitle`（缺省/null/空白=不分组）。
/// 展示层按此 key 切段，组顺序=在列表中首次出现的顺序。
String resolveChapterGroupTitle({String groupTitle = ''}) {
  return groupTitle.trim();
}

/// 组标题展示文案：空组显示“未分组”。
String chapterGroupDisplayTitle(String title, String untitledLabel) {
  final trimmed = title.trim();
  return trimmed.isEmpty ? untitledLabel : trimmed;
}

class ChapterGroup<T> {
  ChapterGroup({required this.title, required this.items});

  /// 分组标题，`''` 表示未分组。
  final String title;
  final List<T> items;
}

/// 有序分组：元素保持输入相对顺序，组按首次出现排序。
List<ChapterGroup<T>> groupChaptersByTitle<T>(
  List<T> items,
  String Function(T item) groupOf,
) {
  final groups = <ChapterGroup<T>>[];
  final indexByTitle = <String, int>{};
  for (final item in items) {
    final title = groupOf(item);
    final existing = indexByTitle[title];
    if (existing == null) {
      indexByTitle[title] = groups.length;
      groups.add(ChapterGroup(title: title, items: [item]));
    } else {
      groups[existing].items.add(item);
    }
  }
  return groups;
}

/// 下标分组：与 [groupChaptersByTitle] 同样的首次出现顺序，但直接按下标循环，
/// 避免调用方 `List.generate(N)` 的中间分配。详情页章节列表用它（`displayEps`
/// 已全局排序，组顺序即首次出现顺序）。
List<ChapterGroup<int>> groupIndicesByTitle(
  int length,
  String Function(int index) groupOf,
) {
  final groups = <ChapterGroup<int>>[];
  final indexByTitle = <String, int>{};
  for (var i = 0; i < length; i++) {
    final title = groupOf(i);
    final existing = indexByTitle[title];
    if (existing == null) {
      indexByTitle[title] = groups.length;
      groups.add(ChapterGroup<int>(title: title, items: [i]));
    } else {
      groups[existing].items.add(i);
    }
  }
  return groups;
}
