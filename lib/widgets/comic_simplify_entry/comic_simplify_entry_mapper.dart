import 'package:zephyr/model/unified_comic_list_item.dart';

import 'comic_simplify_entry_info.dart';

List<ComicSimplifyEntryInfo> mapToUnifiedComicSimplifyEntryInfoList(
  Iterable<dynamic> items,
) {
  return items.map((item) {
    final comic = item is UnifiedComicListItem
        ? item
        : UnifiedComicListItem.fromJson(
            Map<String, dynamic>.from(
              (item as Map).map((key, value) => MapEntry('$key', value)),
            ),
          );
    return comic.toSimplifyEntryInfo();
  }).toList();
}
