import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/util/json/json_sanitize.dart';
import 'package:zephyr/util/json/json_value.dart';
import 'package:zephyr/util/path_util.dart';

import 'unified_comic_list_item.dart';

UnifiedComicListItem unifiedComicFromPluginSearchItem(
  UnifiedPluginSearchItem item,
  String source,
) {
  return _requireUnifiedPluginItem(
    item.data,
    context: 'search:$source:${item.id}',
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
    cover: _coverFromStored(comic.source, comic.comicId, comic.cover),
    metadata: _metadataFromString(comic.metadata),
    raw: _buildFavoriteRaw(comic),
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
    cover: _coverFromStored(comic.source, comic.comicId, comic.cover),
    metadata: _metadataFromString(comic.metadata),
    raw: _buildHistoryRaw(comic),
    extern: const <String, dynamic>{},
  );
}

UnifiedComicListItem unifiedComicFromUnifiedDownload(
  UnifiedComicDownload comic,
) {
  final cover = _coverFromStored(comic.source, comic.comicId, comic.cover);
  final extern = Map<String, dynamic>.from(cover.extern);
  return UnifiedComicListItem(
    source: comic.source,
    id: comic.comicId,
    title: comic.title,
    subtitle: '',
    finished: false,
    likesCount: comic.totalLikes,
    viewsCount: comic.totalViews,
    updatedAt: comic.updatedAt.toIso8601String(),
    cover: UnifiedComicCover(
      id: cover.id,
      url: cover.url,
      path: cover.path,
      extern: extern,
    ),
    metadata: _metadataFromString(comic.metadata),
    raw: _buildDownloadRaw(comic),
    extern: const <String, dynamic>{},
  );
}

Map<String, dynamic> _buildFavoriteRaw(UnifiedComicFavorite comic) {
  return _buildBaseRaw(
    source: comic.source,
    comicId: comic.comicId,
    title: comic.title,
    description: comic.description,
    cover: comic.cover,
    creator: comic.creator,
    titleMeta: comic.titleMeta,
    metadata: comic.metadata,
    updatedAt: comic.updatedAt,
  );
}

Map<String, dynamic> _buildHistoryRaw(UnifiedComicHistory comic) {
  return {
    ..._buildBaseRaw(
      source: comic.source,
      comicId: comic.comicId,
      title: comic.title,
      description: comic.description,
      cover: comic.cover,
      creator: comic.creator,
      titleMeta: comic.titleMeta,
      metadata: comic.metadata,
      updatedAt: comic.updatedAt,
    ),
    'chapterId': comic.chapterId,
    'chapterTitle': comic.chapterTitle,
    'chapterOrder': comic.chapterOrder,
    'pageIndex': comic.pageIndex,
  };
}

Map<String, dynamic> _buildDownloadRaw(UnifiedComicDownload comic) {
  return {
    ..._buildBaseRaw(
      source: comic.source,
      comicId: comic.comicId,
      title: comic.title,
      description: comic.description,
      cover: comic.cover,
      creator: comic.creator,
      titleMeta: comic.titleMeta,
      metadata: comic.metadata,
      updatedAt: comic.updatedAt,
    ),
    'chapters': sanitizeDynamic(comic.chapters),
    'storageRoot': comic.storageRoot,
  };
}

Map<String, dynamic> _buildBaseRaw({
  required String source,
  required String comicId,
  required String title,
  required String description,
  required String cover,
  required String creator,
  required String titleMeta,
  required String metadata,
  required DateTime updatedAt,
}) {
  return {
    'source': source,
    'comicId': comicId,
    'title': title,
    'description': description,
    'cover': sanitizeDynamic(decodeJsonMap(cover)),
    'creator': sanitizeDynamic(creator),
    'titleMeta': sanitizeDynamic(titleMeta),
    'metadata': sanitizeDynamic(_decodeMetadataString(metadata)),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

UnifiedComicCover _coverFromStored(
  String source,
  String comicId,
  String cover,
) {
  final data = decodeJsonMap(cover);
  final coverId = data['id']?.toString() ?? comicId;
  final url = data['url']?.toString() ?? '';
  final coverExtern = asJsonMap(data['extern']);
  final rawPath = data['path']?.toString().trim() ?? '';
  final resolvedPath = rawPath.isNotEmpty
      ? rawPath
      : _buildFallbackCoverPath(coverId, url);
  return UnifiedComicCover(
    id: coverId,
    url: url,
    path: resolvedPath,
    extern: coverExtern,
  );
}

String _buildFallbackCoverPath(String id, String url) {
  final safeId = sanitizePathSegment(id.trim().isEmpty ? 'cover' : id);
  final extension = extractImageExtension(url);
  return '$safeId.$extension';
}

List<UnifiedComicMetadata> _metadataFromString(String metadataJson) {
  return _metadataFromFlex(decodeJsonListOfMaps(metadataJson));
}

List<UnifiedComicMetadata> _metadataFromFlex(
  List<Map<String, dynamic>> metadata,
) {
  return metadata
      .map((item) {
        final value = asJsonList(item['value'])
            .map((e) {
              if (e is Map) {
                return (e['name'] ?? e.toString()).toString().trim();
              }
              return e.toString().trim();
            })
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

List<Map<String, dynamic>> _decodeMetadataString(String metadataJson) {
  return decodeJsonListOfMaps(metadataJson);
}

int _viewCountFromTitleMeta(String titleMetaJson) {
  for (final item in decodeJsonListOfMaps(titleMetaJson)) {
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
