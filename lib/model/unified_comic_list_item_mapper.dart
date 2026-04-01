import 'package:zephyr/model/unified_comic_list_item.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:path/path.dart' as p;

UnifiedComicListItem unifiedComicFromPluginSearchItem(
  UnifiedPluginSearchItem item,
  String source,
) {
  return _requireUnifiedPluginItem(
    item.data,
    context: 'search:$source:${item.id}',
  );
}

UnifiedComicListItem unifiedComicFromUnifiedFavorite(
  UnifiedComicFavorite comic,
) {
  return UnifiedComicListItem(
    source: comic.source,
    id: comic.comicId,
    title: comic.title,
    subtitle: '',
    finished: false,
    likesCount: 0,
    viewsCount: _viewCountFromTitleMeta(comic.titleMeta),
    updatedAt: comic.updatedAt.toIso8601String(),
    cover: _coverFromFlex(comic.source, comic.comicId, comic.cover),
    metadata: _metadataFromFlex(comic.metadata),
    raw: comic.toJson(),
    extern: const <String, dynamic>{},
  );
}

UnifiedComicListItem unifiedComicFromUnifiedHistory(UnifiedComicHistory comic) {
  return UnifiedComicListItem(
    source: comic.source,
    id: comic.comicId,
    title: comic.title,
    subtitle: comic.chapterTitle,
    finished: false,
    likesCount: 0,
    viewsCount: _viewCountFromTitleMeta(comic.titleMeta),
    updatedAt: comic.updatedAt.toIso8601String(),
    cover: _coverFromFlex(comic.source, comic.comicId, comic.cover),
    metadata: _metadataFromFlex(comic.metadata),
    raw: comic.toJson(),
    extern: const <String, dynamic>{},
  );
}

UnifiedComicListItem unifiedComicFromUnifiedDownload(
  UnifiedComicDownload comic,
) {
  final cover = _coverFromFlex(comic.source, comic.comicId, comic.cover);
  final extern = Map<String, dynamic>.from(cover.extern);
  final storedPath = extern['path']?.toString() ?? '';
  if (storedPath.isNotEmpty) {
    extern['path'] = p.join(comic.storageRoot, 'cover', storedPath);
  }
  return UnifiedComicListItem(
    source: comic.source,
    id: comic.comicId,
    title: comic.title,
    subtitle: '',
    finished: false,
    likesCount: comic.totalLikes,
    viewsCount: comic.totalViews,
    updatedAt: comic.updatedAt.toIso8601String(),
    cover: UnifiedComicCover(id: cover.id, url: '', extern: extern),
    metadata: _metadataFromFlex(comic.metadata),
    raw: comic.toJson(),
    extern: const <String, dynamic>{},
  );
}

UnifiedComicListItem unifiedComicFromPluginListMap(
  Map<String, dynamic> item, {
  required String source,
}) {
  return _requireUnifiedPluginItem(
    item,
    context: 'list:$source:${item['id']?.toString() ?? ''}',
  );
}

UnifiedComicCover _coverFromFlex(
  String source,
  String comicId,
  Map<String, dynamic>? cover,
) {
  final data = Map<String, dynamic>.from(cover ?? const <String, dynamic>{});
  final url = data['url']?.toString() ?? '';
  final extern = asMap(data['extern']);
  final extension = asMap(data['extension']);
  final coverExtern = extern.isNotEmpty ? extern : extension;
  return UnifiedComicCover(
    id: data['id']?.toString() ?? comicId,
    url: url,
    extern: coverExtern,
  );
}

List<UnifiedComicMetadata> _metadataFromFlex(
  List<Map<String, dynamic>>? metadata,
) {
  return (metadata ?? const <Map<String, dynamic>>[])
      .map((item) {
        final value = asList(item['value'])
            .map((e) => asMap(e)['name']?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
        if (value.isEmpty) {
          return null;
        }
        return UnifiedComicMetadata(
          type: item['type']?.toString() ?? '',
          name: item['name']?.toString() ?? '',
          value: value,
        );
      })
      .whereType<UnifiedComicMetadata>()
      .toList();
}

int _viewCountFromTitleMeta(List<Map<String, dynamic>>? titleMeta) {
  for (final item in titleMeta ?? const <Map<String, dynamic>>[]) {
    final name = item['name']?.toString() ?? '';
    if (name.startsWith('浏览：')) {
      return int.tryParse(name.substring(3)) ?? 0;
    }
  }
  return 0;
}

UnifiedComicListItem _requireUnifiedPluginItem(
  Map<String, dynamic> item, {
  required String context,
}) {
  if (item['cover'] is! Map || item['metadata'] is! List) {
    throw StateError('插件返回非统一漫画结构: $context');
  }
  return UnifiedComicListItem.fromJson(item);
}
