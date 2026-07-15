import 'package:zephyr/widgets/comic_entry/models/models.dart';
import 'package:zephyr/type/pipe.dart';

import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

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
