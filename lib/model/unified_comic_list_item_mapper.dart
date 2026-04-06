import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:zephyr/model/unified_comic_list_item.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/object_box/model.dart';

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
  var storedPath = cover.path;
  if (storedPath.isNotEmpty) {
    storedPath = p.join(comic.storageRoot, storedPath);
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
    cover: UnifiedComicCover(
      id: cover.id,
      url: '',
      path: storedPath,
      extern: extern,
    ),
    metadata: _metadataFromString(comic.metadata),
    raw: _buildDownloadRaw(comic),
    extern: const <String, dynamic>{},
  );
}

Map<String, dynamic> _buildFavoriteRaw(UnifiedComicFavorite comic) {
  return {
    'source': comic.source,
    'comicId': comic.comicId,
    'title': comic.title,
    'description': comic.description,
    'cover': _sanitizeDynamic(comic.cover),
    'creator': _sanitizeDynamic(comic.creator),
    'titleMeta': _sanitizeDynamic(comic.titleMeta),
    'metadata': _sanitizeDynamic(_decodeMetadataString(comic.metadata)),
    'updatedAt': comic.updatedAt.toIso8601String(),
  };
}

Map<String, dynamic> _buildHistoryRaw(UnifiedComicHistory comic) {
  return {
    'source': comic.source,
    'comicId': comic.comicId,
    'title': comic.title,
    'description': comic.description,
    'cover': _sanitizeDynamic(comic.cover),
    'creator': _sanitizeDynamic(comic.creator),
    'titleMeta': _sanitizeDynamic(comic.titleMeta),
    'metadata': _sanitizeDynamic(_decodeMetadataString(comic.metadata)),
    'chapterId': comic.chapterId,
    'chapterTitle': comic.chapterTitle,
    'chapterOrder': comic.chapterOrder,
    'pageIndex': comic.pageIndex,
    'updatedAt': comic.updatedAt.toIso8601String(),
  };
}

Map<String, dynamic> _buildDownloadRaw(UnifiedComicDownload comic) {
  return {
    'source': comic.source,
    'comicId': comic.comicId,
    'title': comic.title,
    'description': comic.description,
    'cover': _sanitizeDynamic(comic.cover),
    'creator': _sanitizeDynamic(comic.creator),
    'titleMeta': _sanitizeDynamic(comic.titleMeta),
    'metadata': _sanitizeDynamic(_decodeMetadataString(comic.metadata)),
    'chapters': _sanitizeDynamic(comic.chapters),
    'storageRoot': comic.storageRoot,
    'updatedAt': comic.updatedAt.toIso8601String(),
  };
}

dynamic _sanitizeDynamic(dynamic value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }

  if (value is DateTime) {
    return value.toIso8601String();
  }

  if (value is Map) {
    return value.map(
      (key, item) => MapEntry(key.toString(), _sanitizeDynamic(item)),
    );
  }

  if (value is List) {
    return value.map(_sanitizeDynamic).toList();
  }

  try {
    final json = (value as dynamic).toJson();
    return _sanitizeDynamic(json);
  } catch (_) {
    return value.toString();
  }
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

UnifiedComicCover _coverFromStored(
  String source,
  String comicId,
  String cover,
) {
  final data = _decodeMapString(cover);
  final url = data['url']?.toString() ?? '';
  final extern = asMap(data['extern']);
  final extension = asMap(data['extension']);
  final coverExtern = extern.isNotEmpty ? extern : extension;
  final resolvedPath = data['path']?.toString().trim() ?? '';
  return UnifiedComicCover(
    id: data['id']?.toString() ?? comicId,
    url: url,
    path: resolvedPath,
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

List<UnifiedComicMetadata> _metadataFromString(String metadataJson) {
  final mapped = _decodeMetadataString(metadataJson);
  if (mapped.isEmpty) {
    return const <UnifiedComicMetadata>[];
  }
  return _metadataFromFlex(mapped);
}

List<Map<String, dynamic>> _decodeMetadataString(String metadataJson) {
  if (metadataJson.trim().isEmpty) {
    return const <Map<String, dynamic>>[];
  }
  try {
    final decoded = jsonDecode(metadataJson);
    if (decoded is! List) {
      return const <Map<String, dynamic>>[];
    }
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  } catch (_) {
    return const <Map<String, dynamic>>[];
  }
}

int _viewCountFromTitleMeta(String titleMetaJson) {
  for (final item in _decodeListOfMapsString(titleMetaJson)) {
    final name = item['name']?.toString() ?? '';
    if (name.startsWith('浏览：')) {
      return int.tryParse(name.substring(3)) ?? 0;
    }
  }
  return 0;
}

Map<String, dynamic> _decodeMapString(String raw) {
  if (raw.trim().isEmpty) {
    return const <String, dynamic>{};
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {}
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _decodeListOfMapsString(String raw) {
  if (raw.trim().isEmpty) {
    return const <Map<String, dynamic>>[];
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <Map<String, dynamic>>[];
    }
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  } catch (_) {
    return const <Map<String, dynamic>>[];
  }
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

Object getStructure(dynamic input) {
  if (input is Map) {
    return input.map((key, value) => MapEntry(key, getStructure(value)));
  } else if (input is List) {
    return input.isEmpty ? "List" : [getStructure(input.first)];
  } else {
    return input.runtimeType.toString(); // 只保留类型名
  }
}
