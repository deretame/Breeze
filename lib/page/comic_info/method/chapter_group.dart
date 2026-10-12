/// 章节视觉分组契约。
///
/// 数据层保持扁平（`List<Ep>` 仍是唯一真相，`order` 全局唯一排序），
/// 分组只做在展示层：
///
/// - `groupTitle` 为空 = 不分组，老数据/单列插件直接走现有扁平路径；
/// - 非空 = 同组章节，组顺序按在列表中首次出现的顺序推导，不另存顺序 key。
library;

/// 插件拼 name 时用的分隔符：`{group}—{bare}`（U+2014 EM DASH，不是半角 `-`）。
const chapterGroupNameSeparator = '—';

/// 解析分组 key，空串表示不分组。
///
/// 只读顶层 `groupTitle`（`name?: string | null`，缺省/null/空白=不分组）。
/// 展示层按此 key 切段，组顺序=在列表中首次出现的顺序。
String resolveChapterGroupTitle({String groupTitle = ''}) {
  return groupTitle.trim();
}

/// 展示用标题：去 `$group—` 前缀。存储的 `name` 不动，只在显示时 strip。
String chapterDisplayName({required String name, required String groupTitle}) {
  final group = groupTitle.trim();
  if (group.isEmpty) return name;
  final prefix = '$group$chapterGroupNameSeparator';
  if (name.startsWith(prefix)) return name.substring(prefix.length);
  return name;
}

/// 追更/通知用的带组消歧义标题：有组时 `组—裸标题`，无组时原样。
String chapterQualifiedName({
  required String name,
  required String groupTitle,
}) {
  final group = groupTitle.trim();
  final bare = chapterDisplayName(name: name, groupTitle: groupTitle);
  if (group.isEmpty) return name;
  if (name.startsWith('$group$chapterGroupNameSeparator')) return name;
  return '$group$chapterGroupNameSeparator$bare';
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
