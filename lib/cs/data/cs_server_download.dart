import 'dart:convert';

import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';

/// 服务端下载资源在客户端缓存目录中的逻辑路径前缀。
///
/// 这不是本地文件路径。图片层遇到该前缀时，会从 CS 服务端读取资源，
/// 读取成功后仍然落入现有缓存目录，因此书架、封面和阅读器都可以复用
/// 原有的图片组件。
const csServerAssetPathPrefix = 'cs-asset:';

String csServerAssetPath(String assetId) =>
    '$csServerAssetPathPrefix${assetId.trim()}';

String? csServerAssetId(String path) {
  final value = path.trim();
  if (!value.startsWith(csServerAssetPathPrefix)) return null;
  final assetId = value.substring(csServerAssetPathPrefix.length).trim();
  return assetId.isEmpty ? null : assetId;
}

/// 将服务端下载 manifest 转换成现有下载数据模型。
///
/// 服务端只保存漫画和章节图片资源，客户端仍使用 [UnifiedComicDownload]
/// 作为书架/文件夹/阅读器的统一输入。图片的 [path] 使用服务端 asset id，
/// 因此同名图片不会在不同章节之间发生覆盖。
class CsServerDownloadManifest {
  CsServerDownloadManifest({
    required this.pluginId,
    required this.comicId,
    required this.title,
    required this.updatedAt,
    required this.chapters,
    this.coverAssetId = '',
    this.coverUrl = '',
    this.description = '',
    this.creator = '',
    this.titleMeta = '',
    this.metadata = '',
    this.totalViews = 0,
    this.totalLikes = 0,
    this.totalComments = 0,
  });

  final String pluginId;
  final String comicId;
  final String title;
  final DateTime updatedAt;
  final List<UnifiedComicDownloadChapter> chapters;
  final String coverAssetId;
  final String coverUrl;
  final String description;
  final String creator;
  final String titleMeta;
  final String metadata;
  final int totalViews;
  final int totalLikes;
  final int totalComments;

  factory CsServerDownloadManifest.fromJson(Map<String, dynamic> json) {
    final options = _asMap(json['options']);
    final rawRefs =
        (options['chapter_refs'] as List?) ??
        (options['chapters'] as List?) ??
        const <dynamic>[];
    final refs = <String, Map<String, dynamic>>{};
    for (final raw in rawRefs.whereType<Map>()) {
      final ref = Map<String, dynamic>.from(raw);
      final id = _firstNonEmpty([
        ref['chapterId'],
        ref['chapter_id'],
        ref['id'],
      ]);
      if (id.isNotEmpty) refs[id] = ref;
    }

    final groups = <String, List<Map<String, dynamic>>>{};
    final rawPages = (json['pages'] as List?) ?? const <dynamic>[];
    for (final raw in rawPages.whereType<Map>()) {
      final page = Map<String, dynamic>.from(raw);
      final chapterId = _firstNonEmpty([page['chapter_id'], page['chapterId']]);
      if (chapterId.isEmpty) continue;
      groups.putIfAbsent(chapterId, () => <Map<String, dynamic>>[]).add(page);
    }

    final chapterIds = groups.keys.toList();
    chapterIds.sort((left, right) {
      final leftOrder = _toInt(refs[left]?['order'], 1 << 30);
      final rightOrder = _toInt(refs[right]?['order'], 1 << 30);
      final order = leftOrder.compareTo(rightOrder);
      return order == 0 ? left.compareTo(right) : order;
    });

    final chapters = <UnifiedComicDownloadChapter>[];
    for (var index = 0; index < chapterIds.length; index++) {
      final chapterId = chapterIds[index];
      final ref = refs[chapterId] ?? const <String, dynamic>{};
      final pages = groups[chapterId] ?? const <Map<String, dynamic>>[];
      final images = pages
          .map((page) {
            final assetId = _firstNonEmpty([page['asset_id'], page['assetId']]);
            if (assetId.isEmpty) return null;
            return UnifiedComicDownloadImage(
              id: assetId,
              name: _firstNonEmpty([page['name'], page['originalName']]),
              path: csServerAssetPath(assetId),
              // 服务端资源已经下载完成，不再回退到插件 URL。
              url: '',
              extern: const <String, dynamic>{},
            );
          })
          .whereType<UnifiedComicDownloadImage>()
          .toList();
      if (images.isEmpty) continue;
      final order = _toInt(ref['order'], index + 1);
      chapters.add(
        UnifiedComicDownloadChapter(
          id: chapterId,
          title: _firstNonEmpty([ref['title'], ref['name'], chapterId]),
          order: order,
          requestId: _firstNonEmpty([ref['requestId'], ref['request_id']]),
          storageChapterId: _firstNonEmpty([
            ref['storageChapterId'],
            ref['storage_chapter_id'],
          ]),
          logicalKey: _firstNonEmpty([ref['logicalKey'], ref['logical_key']]),
          images: images,
          extern: _asMap(ref['extern']),
        ),
      );
    }

    final cover = _asMap(json['cover_asset']);
    final comicInfo = _asMap(options['comic_info']);
    final metadata = _jsonStringOrEmpty(options['metadata']);
    final titleMeta = _jsonStringOrEmpty(options['title_meta']);
    return CsServerDownloadManifest(
      pluginId: _firstNonEmpty([json['plugin_id'], json['pluginId']]),
      comicId: _firstNonEmpty([json['comic_id'], json['comicId']]),
      title: _firstNonEmpty([
        options['title'],
        comicInfo['title'],
        json['comic_id'],
      ]),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      chapters: chapters,
      coverAssetId: _firstNonEmpty([cover['asset_id'], cover['assetId']]),
      coverUrl: _firstNonEmpty([cover['url'], options['cover_url']]),
      description: comicInfo['description']?.toString() ?? '',
      creator: _jsonStringOrEmpty(comicInfo['creator']),
      titleMeta: titleMeta,
      metadata: metadata,
      totalViews: _toInt(comicInfo['totalViews'], 0),
      totalLikes: _toInt(comicInfo['totalLikes'], 0),
      totalComments: _toInt(comicInfo['totalComments'], 0),
    );
  }

  UnifiedComicDownload toUnifiedComicDownload() {
    final cover = coverAssetId.isEmpty
        ? <String, dynamic>{'id': comicId, 'url': coverUrl, 'path': ''}
        : <String, dynamic>{
            'id': '$comicId:cover',
            'url': coverUrl,
            'path': csServerAssetPath(coverAssetId),
          };
    final now = updatedAt.toUtc();
    return UnifiedComicDownload(
      uniqueKey: '$pluginId:$comicId',
      source: pluginId,
      comicId: comicId,
      title: title,
      description: description,
      cover: jsonEncode(cover),
      creator: creator,
      titleMeta: titleMeta,
      metadata: metadata,
      totalViews: totalViews,
      totalLikes: totalLikes,
      totalComments: totalComments,
      isFavourite: false,
      isLiked: false,
      allowComment: false,
      allowLike: false,
      allowFavorite: false,
      allowDownload: true,
      chapters: jsonEncode(chapters.map((chapter) => chapter.toMap()).toList()),
      detailJson: jsonEncode({
        'comicId': comicId,
        'title': title,
        'extern': {
          'downloadChapters': chapters
              .map(
                (chapter) => {
                  'id': chapter.id,
                  'name': chapter.title,
                  'order': chapter.order,
                  'requestId': chapter.requestId,
                  'storageChapterId': chapter.storageChapterId,
                  'logicalKey': chapter.logicalKey,
                  'extern': chapter.extern,
                },
              )
              .toList(),
        },
      }),
      storageRoot: 'cs-server:$pluginId:$comicId',
      createdAt: now,
      updatedAt: now,
      downloadedAt: now,
      deleted: false,
      schemaVersion: 1,
    );
  }
}

String _firstNonEmpty(Iterable<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return '';
}

Map<String, dynamic> _asMap(dynamic value) {
  return value is Map
      ? Map<String, dynamic>.from(value)
      : const <String, dynamic>{};
}

int _toInt(dynamic value, int fallback) {
  return value is num
      ? value.toInt()
      : int.tryParse(value?.toString() ?? '') ?? fallback;
}

String _jsonStringOrEmpty(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  try {
    return jsonEncode(value);
  } catch (_) {
    return '';
  }
}
