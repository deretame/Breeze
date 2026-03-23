import 'package:zephyr/model/unified_comic_list_item.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/page/bookshelf/json/favorite/favourite_json.dart'
    as favorite_json;
import 'package:zephyr/page/bookshelf/json/jm_cloud_favorite/jm_cloud_favorite_json.dart'
    as jm_cloud;
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal_info;
import 'package:zephyr/util/jm_url_set.dart';

UnifiedComicListItem unifiedComicFromPluginSearchItem(
  UnifiedPluginSearchItem item,
  String source,
) {
  final raw = item.raw;
  final data = item.data;
  if (data['cover'] is Map && data['metadata'] is List) {
    final comic = UnifiedComicListItem.fromJson(data);
    if (source != 'bika') {
      return comic;
    }

    final extra = Map<String, dynamic>.from(comic.cover.extra);
    final fileServer = extra['fileServer']?.toString().trim() ?? '';
    if (fileServer.isEmpty) {
      return comic;
    }

    return UnifiedComicListItem(
      source: comic.source,
      id: comic.id,
      title: comic.title,
      subtitle: comic.subtitle,
      finished: comic.finished,
      likesCount: comic.likesCount,
      viewsCount: comic.viewsCount,
      updatedAt: comic.updatedAt,
      cover: UnifiedComicCover(id: comic.cover.id, url: fileServer, extra: extra),
      metadata: comic.metadata,
      raw: comic.raw,
      extra: comic.extra,
    );
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

UnifiedComicListItem unifiedComicFromBikaFavoriteDoc(favorite_json.Doc doc) {
  return UnifiedComicListItem(
    source: 'bika',
    id: doc.id,
    title: doc.title,
    subtitle: '',
    finished: doc.finished,
    likesCount: doc.likesCount,
    viewsCount: doc.totalViews,
    updatedAt: '',
    cover: UnifiedComicCover(
      id: doc.id,
        url: doc.thumb.fileServer,
      extra: {
        'path': doc.thumb.path,
        'name': doc.thumb.originalName,
        'fileServer': doc.thumb.fileServer,
      },
    ),
    metadata: [
      _metadata(type: 'author', name: '作者', values: [doc.author]),
      _metadata(type: 'categories', name: '分类', values: doc.categories),
    ].whereType<UnifiedComicMetadata>().toList(),
    raw: doc.toJson(),
    extra: const <String, dynamic>{},
  );
}

UnifiedComicListItem unifiedComicFromBikaHistory(BikaComicHistory comic) {
  return UnifiedComicListItem(
    source: 'bika',
    id: comic.comicId,
    title: comic.title,
    subtitle: comic.epTitle,
    finished: comic.finished,
    likesCount: comic.likesCount,
    viewsCount: comic.viewsCount,
    updatedAt: comic.updatedAt.toIso8601String(),
    cover: UnifiedComicCover(
      id: comic.comicId,
        url: comic.thumbFileServer,
      extra: {
        'path': comic.thumbPath,
        'name': comic.thumbOriginalName,
        'fileServer': comic.thumbFileServer,
      },
    ),
    metadata: [
      _metadata(type: 'author', name: '作者', values: [comic.author]),
      _metadata(type: 'team', name: '汉化组', values: [comic.chineseTeam]),
      _metadata(type: 'categories', name: '分类', values: comic.categories),
      _metadata(type: 'tags', name: '标签', values: comic.tags),
    ].whereType<UnifiedComicMetadata>().toList(),
    raw: comic.toJson(),
    extra: {
      'epId': comic.epId,
      'epPageCount': comic.epPageCount,
      'order': comic.order,
    },
  );
}

UnifiedComicListItem unifiedComicFromBikaDownload(BikaComicDownload comic) {
  return UnifiedComicListItem(
    source: 'bika',
    id: comic.comicId,
    title: comic.title,
    subtitle: '',
    finished: comic.finished,
    likesCount: comic.likesCount,
    viewsCount: comic.viewsCount,
    updatedAt: comic.updatedAt.toIso8601String(),
    cover: UnifiedComicCover(
      id: comic.comicId,
        url: comic.thumbFileServer,
      extra: {
        'path': comic.thumbPath,
        'name': comic.thumbOriginalName,
        'fileServer': comic.thumbFileServer,
      },
    ),
    metadata: [
      _metadata(type: 'author', name: '作者', values: [comic.author]),
      _metadata(type: 'team', name: '汉化组', values: [comic.chineseTeam]),
      _metadata(type: 'categories', name: '分类', values: comic.categories),
      _metadata(type: 'tags', name: '标签', values: comic.tags),
    ].whereType<UnifiedComicMetadata>().toList(),
    raw: comic.toJson(),
    extra: {'epsTitle': comic.epsTitle},
  );
}

UnifiedComicListItem unifiedComicFromJmFavorite(JmFavorite comic) {
  return UnifiedComicListItem(
    source: 'jm',
    id: comic.comicId,
    title: comic.name,
    subtitle: '',
    finished: false,
    likesCount: _toInt(comic.likes),
    viewsCount: _toInt(comic.totalViews),
    updatedAt: comic.addtime,
    cover: UnifiedComicCover(
      id: comic.comicId,
      url: getJmCoverUrl(comic.comicId),
      extra: {'path': '${comic.comicId}.jpg'},
    ),
    metadata: [
      _metadata(type: 'author', name: '作者', values: comic.author),
      _metadata(type: 'tags', name: '标签', values: comic.tags),
      _metadata(type: 'works', name: '作品', values: comic.works),
      _metadata(type: 'actors', name: '角色', values: comic.actors),
    ].whereType<UnifiedComicMetadata>().toList(),
    raw: comic.toJson(),
    extra: {
      'description': comic.description,
      'commentTotal': comic.commentTotal,
    },
  );
}

UnifiedComicListItem unifiedComicFromJmHistory(JmHistory comic) {
  return UnifiedComicListItem(
    source: 'jm',
    id: comic.comicId,
    title: comic.name,
    subtitle: comic.epTitle,
    finished: false,
    likesCount: _toInt(comic.likes),
    viewsCount: _toInt(comic.totalViews),
    updatedAt: comic.addtime,
    cover: UnifiedComicCover(
      id: comic.comicId,
      url: getJmCoverUrl(comic.comicId),
      extra: {'path': '${comic.comicId}.jpg'},
    ),
    metadata: [
      _metadata(type: 'author', name: '作者', values: comic.author),
      _metadata(type: 'tags', name: '标签', values: comic.tags),
      _metadata(type: 'works', name: '作品', values: comic.works),
      _metadata(type: 'actors', name: '角色', values: comic.actors),
    ].whereType<UnifiedComicMetadata>().toList(),
    raw: comic.toJson(),
    extra: {
      'description': comic.description,
      'commentTotal': comic.commentTotal,
      'epId': comic.epId,
      'epPageCount': comic.epPageCount,
      'order': comic.order,
    },
  );
}

UnifiedComicListItem unifiedComicFromJmDownload(JmDownload comic) {
  return UnifiedComicListItem(
    source: 'jm',
    id: comic.comicId,
    title: comic.name,
    subtitle: '',
    finished: false,
    likesCount: _toInt(comic.likes),
    viewsCount: _toInt(comic.totalViews),
    updatedAt: comic.addtime,
    cover: UnifiedComicCover(
      id: comic.comicId,
      url: getJmCoverUrl(comic.comicId),
      extra: {'path': '${comic.comicId}.jpg'},
    ),
    metadata: [
      _metadata(type: 'author', name: '作者', values: comic.author),
      _metadata(type: 'tags', name: '标签', values: comic.tags),
      _metadata(type: 'works', name: '作品', values: comic.works),
      _metadata(type: 'actors', name: '角色', values: comic.actors),
    ].whereType<UnifiedComicMetadata>().toList(),
    raw: comic.toJson(),
    extra: {
      'description': comic.description,
      'commentTotal': comic.commentTotal,
      'epsIds': comic.epsIds,
    },
  );
}

UnifiedComicListItem unifiedComicFromUnifiedFavorite(UnifiedComicFavorite comic) {
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

UnifiedComicListItem unifiedComicFromUnifiedDownload(UnifiedComicDownload comic) {
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

UnifiedComicListItem unifiedComicFromRecommend(
  normal_info.Recommend comic,
) {
  final source = comic.source.trim().isEmpty ? 'bika' : comic.source.trim();
  final coverExtra = comic.cover.extension;

  if (source == 'bika') {
    return UnifiedComicListItem(
      source: 'bika',
      id: comic.id,
      title: comic.title,
      subtitle: '',
      finished: false,
      likesCount: 0,
      viewsCount: 0,
      updatedAt: '',
      cover: UnifiedComicCover(
        id: comic.id,
        url: comic.cover.url,
        extra: {
          'path': coverExtra['path']?.toString() ?? comic.cover.name,
          'name': comic.cover.name,
          'fileServer': coverExtra['fileServer']?.toString() ?? comic.cover.url,
        },
      ),
      metadata: const <UnifiedComicMetadata>[],
      raw: {
        'id': comic.id,
        'title': comic.title,
        'cover': {
          'url': comic.cover.url,
          'extension': comic.cover.extension,
          'name': comic.cover.name,
        },
      },
      extra: const <String, dynamic>{},
    );
  }

  return _buildJmComicItem(
    id: comic.id,
    title: comic.title,
    authorValues: const <String>[],
    categoryValues: const <String>[],
    tagValues: const <String>[],
    workValues: const <String>[],
    actorValues: const <String>[],
    likesCount: 0,
    viewsCount: 0,
    updatedAt: '',
    description: '',
    imageUrl: comic.cover.url.isNotEmpty ? comic.cover.url : getJmCoverUrl(comic.id),
    raw: {
      'id': comic.id,
      'name': comic.title,
      'image': comic.cover.url.isNotEmpty ? comic.cover.url : getJmCoverUrl(comic.id),
    },
  );
}

UnifiedComicListItem unifiedComicFromJmCloudFavorite(
  jm_cloud.ListElement comic,
) {
  return _buildJmComicItem(
    id: comic.id,
    title: comic.name,
    authorValues: [comic.author],
    categoryValues: [comic.category.title, comic.categorySub.title],
    tagValues: const <String>[],
    workValues: const <String>[],
    actorValues: const <String>[],
    likesCount: 0,
    viewsCount: 0,
    updatedAt: '',
    description: comic.description,
    imageUrl: comic.image,
    raw: comic.toJson(),
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

List<UnifiedComicMetadata> _metadataFromFlex(List<Map<String, dynamic>>? metadata) {
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

UnifiedComicListItem _buildJmComicItem({
  required String id,
  required String title,
  required List<dynamic> authorValues,
  required List<dynamic> categoryValues,
  required List<dynamic> tagValues,
  required List<dynamic> workValues,
  required List<dynamic> actorValues,
  required int likesCount,
  required int viewsCount,
  required String updatedAt,
  required String description,
  required String imageUrl,
  required Map<String, dynamic> raw,
}) {
  final finalImageUrl = imageUrl.trim().isNotEmpty
      ? _resolveJmImageUrl(imageUrl, id)
      : getJmCoverUrl(id);
  return UnifiedComicListItem(
    source: 'jm',
    id: id,
    title: title,
    subtitle: '',
    finished: false,
    likesCount: likesCount,
    viewsCount: viewsCount,
    updatedAt: updatedAt,
    cover: UnifiedComicCover(
      id: id,
      url: finalImageUrl,
      extra: {'path': '$id.jpg'},
    ),
    metadata: [
      _metadata(type: 'author', name: '作者', values: authorValues),
      _metadata(type: 'categories', name: '分类', values: categoryValues),
      _metadata(type: 'tags', name: '标签', values: tagValues),
      _metadata(type: 'works', name: '作品', values: workValues),
      _metadata(type: 'actors', name: '角色', values: actorValues),
    ].whereType<UnifiedComicMetadata>().toList(),
    raw: raw,
    extra: {if (description.trim().isNotEmpty) 'description': description},
  );
}

UnifiedComicListItem unifiedComicFromLeaderboardComic(
  Map<String, dynamic> raw,
) {
  final thumb = asMap(raw['thumb']);
  final path = thumb['path']?.toString() ?? '';
  final fileServer = thumb['fileServer']?.toString() ?? '';
  final categories =
      (raw['categories'] as List?)?.map((e) => e.toString()).toList() ?? [];
  return UnifiedComicListItem(
    source: 'bika',
    id: raw['_id']?.toString() ?? '',
    title: raw['title']?.toString() ?? '',
    subtitle: raw['author']?.toString() ?? '',
    finished: raw['finished'] == true,
    likesCount: _toInt(raw['totalLikes'] ?? raw['likesCount']),
    viewsCount: _toInt(raw['totalViews'] ?? raw['viewsCount']),
    updatedAt: '',
    cover: UnifiedComicCover(
      id: raw['_id']?.toString() ?? '',
      url: fileServer,
      extra: {
        'path': path,
        'name': thumb['originalName']?.toString() ?? '',
        'fileServer': fileServer,
      },
    ),
    metadata: [
      _metadata(type: 'categories', name: '分类', values: categories),
    ].whereType<UnifiedComicMetadata>().toList(),
    raw: raw,
    extra: {},
  );
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
