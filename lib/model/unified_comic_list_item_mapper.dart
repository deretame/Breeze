import 'package:zephyr/model/unified_comic_list_item.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/json/favorite/favourite_json.dart'
    as favorite_json;
import 'package:zephyr/page/bookshelf/json/jm_cloud_favorite/jm_cloud_favorite_json.dart'
    as jm_cloud;
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal_info;
import 'package:zephyr/type/enum.dart';
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
        url: buildImageUrl(fileServer, path, PictureType.cover, 'original', 3),
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
    cover: UnifiedComicCover(
      id: id,
      url: imageUrl,
      extra: {'path': '$id.jpg'},
    ),
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
  final coverUrl = buildImageUrl(
    doc.thumb.fileServer,
    doc.thumb.path,
    PictureType.favourite,
    'original',
    3,
  );
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
      url: coverUrl,
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
  final coverUrl = buildImageUrl(
    comic.thumbFileServer,
    comic.thumbPath,
    PictureType.cover,
    'original',
    3,
  );
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
      url: coverUrl,
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
  final coverUrl = buildImageUrl(
    comic.thumbFileServer,
    comic.thumbPath,
    PictureType.cover,
    'original',
    3,
  );
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
      url: coverUrl,
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

UnifiedComicListItem unifiedComicFromRecommend(
  normal_info.Recommend comic, {
  required From from,
}) {
  if (from == From.bika) {
    final coverUrl = buildImageUrl(
      comic.cover.url,
      comic.cover.path,
      PictureType.cover,
      'original',
      3,
    );
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
        url: coverUrl,
        extra: {
          'path': comic.cover.path,
          'name': comic.cover.name,
          'fileServer': comic.cover.url,
        },
      ),
      metadata: const <UnifiedComicMetadata>[],
      raw: {
        'id': comic.id,
        'title': comic.title,
        'cover': {
          'url': comic.cover.url,
          'path': comic.cover.path,
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
    imageUrl: getJmCoverUrl(comic.id),
    raw: {
      'id': comic.id,
      'name': comic.title,
      'image': getJmCoverUrl(comic.id),
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

UnifiedComicListItem unifiedComicFromMap(Map<String, dynamic> comic) {
  return UnifiedComicListItem.fromJson(comic);
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
