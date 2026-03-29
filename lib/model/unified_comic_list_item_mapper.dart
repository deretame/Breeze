import 'package:zephyr/model/unified_comic_list_item.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/util/jm_url_set.dart';

UnifiedComicListItem unifiedComicFromPluginSearchItem(
  UnifiedPluginSearchItem item,
  String source,
) {
  final raw = item.raw;
  final data = item.data;
  if (data['cover'] is Map && data['metadata'] is List) {
    return UnifiedComicListItem.fromJson(data);
  }

  if (source == 'bika') {
    final thumb = asMap(raw['thumb']);
    final path = thumb['path']?.toString() ?? '';
    final fileServer = thumb['fileServer']?.toString() ?? '';
    return UnifiedComicListItem(
      source: 'bika',
      id: raw['_id']?.toString() ?? raw['id']?.toString() ?? '',
      title: raw['title']?.toString() ?? item.title,
      subtitle: '',
      finished: raw['finished'] == true,
      likesCount: _toInt(raw['likesCount']),
      viewsCount: _toInt(raw['totalViews'] ?? raw['viewsCount']),
      updatedAt: raw['updated_at']?.toString() ?? '',
      cover: UnifiedComicCover(
        id: raw['_id']?.toString() ?? raw['id']?.toString() ?? '',
        url: fileServer,
        extra: {
          'path': path,
          'name': thumb['originalName']?.toString() ?? '',
          'fileServer': fileServer,
        },
      ),
      metadata: [
        _metadata(type: 'author', name: '作者', values: [raw['author']]),
        _metadata(type: 'team', name: '汉化组', values: [raw['chineseTeam']]),
        _metadata(
          type: 'categories',
          name: '分类',
          values: asList(raw['categories']),
        ),
        _metadata(type: 'tags', name: '标签', values: asList(raw['tags'])),
      ].whereType<UnifiedComicMetadata>().toList(),
      raw: raw,
      extra: const <String, dynamic>{},
    );
  }

  final category = asMap(raw['category']);
  final categorySub = asMap(raw['category_sub']);
  final id = raw['id']?.toString() ?? item.id;
  final imageUrl = _resolveJmImageUrl(raw['image']?.toString() ?? '', id);
  return UnifiedComicListItem(
    source: 'jm',
    id: id,
    title: raw['name']?.toString() ?? item.title,
    subtitle: '',
    finished: false,
    likesCount: _toInt(raw['likes']),
    viewsCount: _toInt(raw['total_views'] ?? raw['totalViews']),
    updatedAt: raw['update_at']?.toString() ?? '',
    cover: UnifiedComicCover(id: id, url: imageUrl, extra: {'path': '$id.jpg'}),
    metadata: [
      _metadata(type: 'author', name: '作者', values: [raw['author']]),
      _metadata(
        type: 'categories',
        name: '分类',
        values: [category['title'], categorySub['title']],
      ),
      _metadata(type: 'tags', name: '标签', values: asList(raw['tags'])),
    ].whereType<UnifiedComicMetadata>().toList(),
    raw: raw,
    extra: const <String, dynamic>{},
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
    extra: {'description': comic.description},
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
    extra: {
      'description': comic.description,
      'epId': comic.chapterId,
      'epPageCount': comic.pageIndex,
      'order': comic.chapterOrder,
    },
  );
}

UnifiedComicListItem unifiedComicFromUnifiedDownload(
  UnifiedComicDownload comic,
) {
  final cover = _coverFromFlex(comic.source, comic.comicId, comic.cover);
  final extra = Map<String, dynamic>.from(cover.extra);
  final storedPath = extra['path']?.toString() ?? '';
  if (storedPath.isNotEmpty) {
    extra['path'] = p.join(comic.storageRoot, 'cover', storedPath);
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
    cover: UnifiedComicCover(id: cover.id, url: '', extra: extra),
    metadata: _metadataFromFlex(comic.metadata),
    raw: comic.toJson(),
    extra: {'description': comic.description},
  );
}

UnifiedComicListItem unifiedComicFromPluginListMap(
  Map<String, dynamic> item, {
  required String source,
}) {
  if (item['cover'] is Map && item['metadata'] is List) {
    return UnifiedComicListItem.fromJson(item);
  }

  final raw = asMap(item['raw']);
  return unifiedComicFromPluginSearchItem(
    UnifiedPluginSearchItem(
      id: item['id']?.toString() ?? item['_id']?.toString() ?? '',
      title: item['title']?.toString() ?? item['name']?.toString() ?? '',
      data: item,
      raw: raw.isNotEmpty ? raw : item,
    ),
    source,
  );
}

UnifiedComicMetadata? _metadata({
  required String type,
  required String name,
  required List<dynamic> values,
}) {
  final list = values
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList();
  if (list.isEmpty) {
    return null;
  }
  return UnifiedComicMetadata(type: type, name: name, value: list);
}

int _toInt(dynamic value) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

UnifiedComicCover _coverFromFlex(
  String source,
  String comicId,
  Map<String, dynamic>? cover,
) {
  final data = Map<String, dynamic>.from(cover ?? const <String, dynamic>{});
  final extension = asMap(data['extension']);
  final url = data['url']?.toString() ?? '';
  final path = extension['path']?.toString() ?? data['name']?.toString() ?? '';
  return UnifiedComicCover(
    id: data['id']?.toString() ?? comicId,
    url: url.isNotEmpty ? url : (source == 'jm' ? getJmCoverUrl(comicId) : ''),
    extra: {
      'path': path,
      'name': data['name']?.toString() ?? '',
      'fileServer': extension['fileServer']?.toString() ?? url,
    },
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
      return _toInt(name.substring(3));
    }
  }
  return 0;
}

String _resolveJmImageUrl(String imageUrl, String id) {
  final normalized = imageUrl.trim();
  if (normalized.isEmpty) {
    return getJmCoverUrl(id);
  }

  final uri = Uri.tryParse(normalized);
  if (uri != null && uri.hasScheme) {
    return normalized;
  }

  final base = currentJmImageBaseUrl.trim();
  if (base.isEmpty) {
    return normalized;
  }

  if (normalized.startsWith('/')) {
    return '$base$normalized';
  }

  if (normalized.startsWith('media/')) {
    return '$base/$normalized';
  }

  return normalized;
}
