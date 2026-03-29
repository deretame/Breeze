import 'package:zephyr/model/unified_comic_list_item.dart';
import 'package:zephyr/type/pipe.dart';

import 'comic_simplify_entry_info.dart';

List<ComicSimplifyEntryInfo> mapToUnifiedComicSimplifyEntryInfoList(
  Iterable<dynamic> items,
) {
  return items.map((item) {
    final comic = item is UnifiedComicListItem
        ? item
        : (item as Map)
              .map((key, value) => MapEntry('$key', value))
              .let(Map<String, dynamic>.from)
              .debug((d) => d['cover'])
              .let(UnifiedComicListItem.fromJson);
    return comic.toSimplifyEntryInfo();
  }).toList();
}
