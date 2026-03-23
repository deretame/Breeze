import 'dart:convert';
import 'dart:io';

import 'package:objectbox/objectbox.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/download/json/comic_all_info_json/comic_all_info_json.dart'
    as bika_download;
import 'package:zephyr/page/jm/jm_download/json/download_info_json.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/jm_url_set.dart';

Future<void> migrateV1ToV2(ObjectBox objectbox) async {
  final favorites = _buildFavorites(objectbox);
  final histories = _buildHistories(objectbox);
  final downloads = await _buildDownloads(objectbox);

  objectbox.store.runInTransaction(TxMode.write, () {
    objectbox.unifiedFavoriteBox.removeAll();
    objectbox.unifiedHistoryBox.removeAll();
    objectbox.unifiedDownloadBox.removeAll();

    if (favorites.isNotEmpty) {
      objectbox.unifiedFavoriteBox.putMany(favorites);
    }
    if (histories.isNotEmpty) {
      objectbox.unifiedHistoryBox.putMany(histories);
    }
    if (downloads.isNotEmpty) {
      objectbox.unifiedDownloadBox.putMany(downloads);
    }
  });
}

UnifiedComicFavorite buildUnifiedFavoriteFromLegacy(JmFavorite item) =>
    _jmFavoriteToUnified(item);

UnifiedComicHistory buildUnifiedHistoryFromBikaLegacy(BikaComicHistory item) =>
    _bikaHistoryToUnified(item);

UnifiedComicHistory buildUnifiedHistoryFromJmLegacy(JmHistory item) =>
    _jmHistoryToUnified(item);

Future<UnifiedComicDownload> buildUnifiedDownloadFromBikaLegacy(
  BikaComicDownload item,
) async => _bikaDownloadToUnified(item, await getDownloadPath());

Future<UnifiedComicDownload> buildUnifiedDownloadFromJmLegacy(
  JmDownload item,
) async => _jmDownloadToUnified(item, await getDownloadPath());

List<UnifiedComicFavorite> _buildFavorites(ObjectBox objectbox) {
  final jmFavorites = objectbox.jmFavoriteBox.getAll();
  return jmFavorites.map(_jmFavoriteToUnified).toList();
}

List<UnifiedComicHistory> _buildHistories(ObjectBox objectbox) {
  final bikaHistories = objectbox.bikaHistoryBox.getAll().map(
    _bikaHistoryToUnified,
  );
  final jmHistories = objectbox.jmHistoryBox.getAll().map(_jmHistoryToUnified);
  return [...bikaHistories, ...jmHistories].toList();
}

Future<List<UnifiedComicDownload>> _buildDownloads(ObjectBox objectbox) async {
  final downloadRoot = await getDownloadPath();
  final bikaDownloads = <UnifiedComicDownload>[];
  for (final item in objectbox.bikaDownloadBox.getAll()) {
    bikaDownloads.add(await _bikaDownloadToUnified(item, downloadRoot));
  }
  final jmDownloads = <UnifiedComicDownload>[];
  for (final item in objectbox.jmDownloadBox.getAll()) {
    jmDownloads.add(await _jmDownloadToUnified(item, downloadRoot));
  }
  return [...bikaDownloads, ...jmDownloads];
}

UnifiedComicFavorite _jmFavoriteToUnified(JmFavorite item) {
  return UnifiedComicFavorite(
    uniqueKey: _uniqueKey('jm', item.comicId),
    source: 'jm',
    comicId: item.comicId,
    title: item.name,
    description: item.description,
    cover: _coverMap(
      normal.ComicImage(
        id: item.comicId,
        url: getJmCoverUrl(item.comicId),
        name: '${item.comicId}.jpg',
        extension: {'path': '${item.comicId}.jpg'},
      ),
    ),
    creator: _creatorMap(
      normal.Creator(
        id: '',
        name: '',
        avatar: const normal.ComicImage(id: '', url: '', name: ''),
      ),
    ),
    titleMeta: _titleMetaList([
      normal.ComicInfoActionItem(name: '浏览：${item.totalViews}'),
      normal.ComicInfoActionItem(name: '更新时间：${_safeTitle(item.addtime)}'),
    ]),
    metadata: _metadataList([
      normal.ComicInfoMetadata(
        type: 'author',
        name: '作者',
        value: item.author
            .map((e) => normal.ComicInfoActionItem(name: e))
            .toList(),
      ),
      normal.ComicInfoMetadata(
        type: 'tags',
        name: '标签',
        value: item.tags
            .map((e) => normal.ComicInfoActionItem(name: e))
            .toList(),
      ),
      normal.ComicInfoMetadata(
        type: 'works',
        name: '作品',
        value: item.works
            .map((e) => normal.ComicInfoActionItem(name: e))
            .toList(),
      ),
      normal.ComicInfoMetadata(
        type: 'actors',
        name: '角色',
        value: item.actors
            .map((e) => normal.ComicInfoActionItem(name: e))
            .toList(),
      ),
    ]),
    createdAt: item.history,
    updatedAt: item.history,
    deleted: item.deleted,
    schemaVersion: 2,
  );
}

UnifiedComicHistory _bikaHistoryToUnified(BikaComicHistory item) {
  return UnifiedComicHistory(
    uniqueKey: _uniqueKey('bika', item.comicId),
    source: 'bika',
    comicId: item.comicId,
    title: item.title,
    description: item.description,
    cover: _coverMap(
      normal.ComicImage(
        id: item.comicId,
        url: item.thumbFileServer,
        name: item.thumbOriginalName,
        extension: {'path': item.thumbPath, 'fileServer': item.thumbFileServer},
      ),
    ),
    creator: _creatorMap(
      normal.Creator(
        id: item.creatorId,
        name: item.creatorName,
        avatar: normal.ComicImage(
          id: item.creatorId,
          url: item.creatorAvatarFileServer,
          name: item.creatorAvatarOriginalName,
          extension: {
            'path': item.creatorAvatarPath,
            'fileServer': item.creatorAvatarFileServer,
          },
        ),
      ),
    ),
    titleMeta: _titleMetaList([
      normal.ComicInfoActionItem(name: '浏览：${item.totalViews}'),
      normal.ComicInfoActionItem(name: '更新时间：${item.updatedAt.toLocal()}'),
      if (item.pagesCount > 0)
        normal.ComicInfoActionItem(name: '页数：${item.pagesCount}'),
      normal.ComicInfoActionItem(name: '章节数：${item.epsCount}'),
    ]),
    metadata: _metadataList([
      normal.ComicInfoMetadata(
        type: 'author',
        name: '作者',
        value: [
          if (item.author.trim().isNotEmpty)
            normal.ComicInfoActionItem(name: item.author),
        ],
      ),
      normal.ComicInfoMetadata(
        type: 'chineseTeam',
        name: '汉化',
        value: [
          if (item.chineseTeam.trim().isNotEmpty)
            normal.ComicInfoActionItem(name: item.chineseTeam),
        ],
      ),
      normal.ComicInfoMetadata(
        type: 'categories',
        name: '分类',
        value: item.categories
            .map((e) => normal.ComicInfoActionItem(name: e))
            .toList(),
      ),
      normal.ComicInfoMetadata(
        type: 'tags',
        name: '标签',
        value: item.tags
            .map((e) => normal.ComicInfoActionItem(name: e))
            .toList(),
      ),
    ]),
    chapterId: item.epId,
    chapterTitle: item.epTitle,
    chapterOrder: item.order,
    pageIndex: item.epPageCount,
    createdAt: item.history,
    lastReadAt: item.history,
    updatedAt: item.history,
    deleted: item.deleted,
    schemaVersion: 2,
  );
}

UnifiedComicHistory _jmHistoryToUnified(JmHistory item) {
  return UnifiedComicHistory(
    uniqueKey: _uniqueKey('jm', item.comicId),
    source: 'jm',
    comicId: item.comicId,
    title: item.name,
    description: item.description,
    cover: _coverMap(
      normal.ComicImage(
        id: item.comicId,
        url: getJmCoverUrl(item.comicId),
        name: '${item.comicId}.jpg',
        extension: {'path': '${item.comicId}.jpg'},
      ),
    ),
    creator: _creatorMap(
      normal.Creator(
        id: '',
        name: '',
        avatar: const normal.ComicImage(id: '', url: '', name: ''),
      ),
    ),
    titleMeta: _titleMetaList([
      normal.ComicInfoActionItem(name: '浏览：${item.totalViews}'),
      normal.ComicInfoActionItem(name: '更新时间：${_safeTitle(item.addtime)}'),
    ]),
    metadata: _metadataList([
      normal.ComicInfoMetadata(
        type: 'author',
        name: '作者',
        value: item.author
            .map((e) => normal.ComicInfoActionItem(name: e))
            .toList(),
      ),
      normal.ComicInfoMetadata(
        type: 'tags',
        name: '标签',
        value: item.tags
            .map((e) => normal.ComicInfoActionItem(name: e))
            .toList(),
      ),
      normal.ComicInfoMetadata(
        type: 'works',
        name: '作品',
        value: item.works
            .map((e) => normal.ComicInfoActionItem(name: e))
            .toList(),
      ),
      normal.ComicInfoMetadata(
        type: 'actors',
        name: '角色',
        value: item.actors
            .map((e) => normal.ComicInfoActionItem(name: e))
            .toList(),
      ),
    ]),
    chapterId: item.epId,
    chapterTitle: item.epTitle,
    chapterOrder: item.order,
    pageIndex: item.epPageCount,
    createdAt: item.history,
    lastReadAt: item.history,
    updatedAt: item.history,
    deleted: item.deleted,
    schemaVersion: 2,
  );
}

Future<UnifiedComicDownload> _bikaDownloadToUnified(
  BikaComicDownload item,
  String downloadRoot,
) async {
  final coverPath = await _resolveLegacyCoverPath(
    downloadRoot: downloadRoot,
    source: 'bika',
    comicId: item.comicId,
    fallback: item.thumbPath,
  );
  final legacy = bika_download.comicAllInfoJsonFromJson(item.comicInfoAll);
  await _normalizeLegacyChapterFiles(
    root: _downloadStorageRoot(downloadRoot, 'bika', item.comicId),
    chapters: legacy.eps.docs
        .map(
          (e) => _LegacyChapterFiles(
            id: e.id,
            files: e.pages.docs.map((p) => p.media.path).toList(),
          ),
        )
        .toList(),
  );
  final chapters = legacy.eps.docs
      .map(
        (e) => normal.Ep(
          id: e.id,
          name: e.title,
          order: e.order,
          extension: {'docId': e.docId},
        ).toJson(),
      )
      .toList();

  final detail = normal.NormalComicAllInfo(
    comicInfo: normal.ComicInfo(
      id: item.comicId,
      title: item.title,
      titleMeta: [
        normal.ComicInfoActionItem(name: '浏览：${item.totalViews}'),
        normal.ComicInfoActionItem(name: '更新时间：${item.updatedAt.toLocal()}'),
        if (item.pagesCount > 0)
          normal.ComicInfoActionItem(name: '页数：${item.pagesCount}'),
        normal.ComicInfoActionItem(name: '章节数：${item.epsCount}'),
      ],
      creator: normal.Creator(
        id: item.creatorId,
        name: item.creatorName,
        avatar: normal.ComicImage(
          id: item.creatorId,
          url: item.creatorAvatarFileServer,
          name: item.creatorAvatarOriginalName,
          extension: {
            'path': item.creatorAvatarPath,
            'fileServer': item.creatorAvatarFileServer,
          },
        ),
        onTap: _bikaCreatorAction(item.creatorId, item.creatorName),
      ),
      description: item.description,
      cover: normal.ComicImage(
        id: item.comicId,
        url: item.thumbFileServer,
        name: item.thumbOriginalName,
        extension: {'path': coverPath, 'fileServer': item.thumbFileServer},
      ),
      metadata: [
        normal.ComicInfoMetadata(
          type: 'author',
          name: '作者',
          value: [
            if (item.author.trim().isNotEmpty)
              normal.ComicInfoActionItem(
                name: item.author,
                onTap: _bikaSearchAction(keyword: item.author),
              ),
          ],
        ),
        normal.ComicInfoMetadata(
          type: 'chineseTeam',
          name: '汉化',
          value: [
            if (item.chineseTeam.trim().isNotEmpty)
              normal.ComicInfoActionItem(
                name: item.chineseTeam,
                onTap: _bikaSearchAction(keyword: item.chineseTeam),
              ),
          ],
        ),
        normal.ComicInfoMetadata(
          type: 'categories',
          name: '分类',
          value: item.categories
              .map(
                (e) => normal.ComicInfoActionItem(
                  name: e,
                  onTap: _bikaCategoryAction(e),
                ),
              )
              .toList(),
        ),
        normal.ComicInfoMetadata(
          type: 'tags',
          name: '标签',
          value: item.tags
              .map(
                (e) => normal.ComicInfoActionItem(
                  name: e,
                  onTap: _bikaSearchAction(keyword: e),
                ),
              )
              .toList(),
        ),
      ],
    ),
    eps: chapters.map(normal.Ep.fromJson).toList(),
    recommend: const [],
    totalViews: item.totalViews,
    totalLikes: item.totalLikes,
    totalComments: item.totalComments,
    isFavourite: item.isFavourite,
    isLiked: item.isLiked,
    allowComment: item.allowComment,
    allowLike: true,
    allowFavorite: true,
    allowDownload: item.allowDownload,
  ).toJson();
  final normalizedDetail = _normalizeFlexValue(detail) as Map<String, dynamic>;
  final comicInfoMap = Map<String, dynamic>.from(
    normalizedDetail['comicInfo'] as Map,
  );

  return UnifiedComicDownload(
    uniqueKey: _uniqueKey('bika', item.comicId),
    source: 'bika',
    comicId: item.comicId,
    title: item.title,
    description: item.description,
    cover: _coverMap(comicInfoMap['cover']),
    creator: _creatorMap(comicInfoMap['creator']),
    titleMeta: _mapList(comicInfoMap['titleMeta']),
    metadata: _mapList(comicInfoMap['metadata']),
    totalViews: item.totalViews,
    totalLikes: item.totalLikes,
    totalComments: item.totalComments,
    isFavourite: item.isFavourite,
    isLiked: item.isLiked,
    allowComment: item.allowComment,
    allowLike: true,
    allowFavorite: true,
    allowDownload: item.allowDownload,
    chapters: _mapList(normalizedDetail['eps']),
    detailJson: jsonEncode(normalizedDetail),
    storageRoot: _downloadStorageRoot(downloadRoot, 'bika', item.comicId),
    createdAt: item.downloadTime,
    updatedAt: item.downloadTime,
    downloadedAt: item.downloadTime,
    deleted: false,
    schemaVersion: 2,
  );
}

Future<UnifiedComicDownload> _jmDownloadToUnified(
  JmDownload item,
  String downloadRoot,
) async {
  final coverPath = await _resolveLegacyCoverPath(
    downloadRoot: downloadRoot,
    source: 'jm',
    comicId: item.comicId,
    fallback: '${item.comicId}.jpg',
  );
  final info = downloadInfoJsonFromJson(item.allInfo);
  await _normalizeLegacyChapterFiles(
    root: _downloadStorageRoot(downloadRoot, 'jm', item.comicId),
    chapters: info.series
        .map(
          (e) => _LegacyChapterFiles(id: e.id, files: e.info.images.toList()),
        )
        .toList(),
  );
  final normalInfo = _jmDownloadInfoToNormal(info);
  final detail = normalInfo.toJson();
  final normalizedDetail = _normalizeFlexValue(detail) as Map<String, dynamic>;
  final comicInfoMap = Map<String, dynamic>.from(
    normalizedDetail['comicInfo'] as Map,
  );
  final cover = _coverMap(comicInfoMap['cover']);
  final extension = Map<String, dynamic>.from(
    (cover['extension'] as Map?) ?? const <String, dynamic>{},
  )..['path'] = coverPath;
  cover['extension'] = extension;

  return UnifiedComicDownload(
    uniqueKey: _uniqueKey('jm', item.comicId),
    source: 'jm',
    comicId: item.comicId,
    title: item.name,
    description: item.description,
    cover: cover,
    creator: _creatorMap(comicInfoMap['creator']),
    titleMeta: _mapList(comicInfoMap['titleMeta']),
    metadata: _mapList(comicInfoMap['metadata']),
    totalViews: normalInfo.totalViews,
    totalLikes: normalInfo.totalLikes,
    totalComments: normalInfo.totalComments,
    isFavourite: normalInfo.isFavourite,
    isLiked: normalInfo.isLiked,
    allowComment: normalInfo.allowComment,
    allowLike: normalInfo.allowLike,
    allowFavorite: normalInfo.allowFavorite,
    allowDownload: normalInfo.allowDownload,
    chapters: _mapList(normalizedDetail['eps']),
    detailJson: jsonEncode(normalizedDetail),
    storageRoot: _downloadStorageRoot(downloadRoot, 'jm', item.comicId),
    createdAt: item.downloadTime,
    updatedAt: item.downloadTime,
    downloadedAt: item.downloadTime,
    deleted: false,
    schemaVersion: 2,
  );
}

normal.NormalComicAllInfo _jmDownloadInfoToNormal(DownloadInfoJson info) {
  final epsCount = info.series.isEmpty ? 1 : info.series.length;
  return normal.NormalComicAllInfo(
    comicInfo: normal.ComicInfo(
      id: info.id.toString(),
      title: info.name,
      titleMeta: [
        normal.ComicInfoActionItem(name: '浏览：${info.totalViews}'),
        normal.ComicInfoActionItem(name: '更新时间：${_safeTitle(info.addtime)}'),
        normal.ComicInfoActionItem(name: '章节数：$epsCount'),
        normal.ComicInfoActionItem(name: '禁漫车：jm${info.id}'),
      ],
      creator: const normal.Creator(
        id: '',
        name: '',
        avatar: normal.ComicImage(id: '', url: '', name: ''),
      ),
      description: info.description,
      cover: normal.ComicImage(
        id: info.id.toString(),
        url: getJmCoverUrl(info.id.toString()),
        name: '${info.id}.jpg',
        extension: {'path': '${info.id}.jpg'},
      ),
      metadata: [
        normal.ComicInfoMetadata(
          type: 'author',
          name: '作者',
          value: info.author
              .map(
                (e) => normal.ComicInfoActionItem(
                  name: e,
                  onTap: _jmSearchAction(e),
                ),
              )
              .toList(),
        ),
        normal.ComicInfoMetadata(
          type: 'tags',
          name: '标签',
          value: info.tags
              .map(
                (e) => normal.ComicInfoActionItem(
                  name: e,
                  onTap: _jmSearchAction(e),
                ),
              )
              .toList(),
        ),
        normal.ComicInfoMetadata(
          type: 'works',
          name: '作品',
          value: info.works
              .map(
                (e) => normal.ComicInfoActionItem(
                  name: e,
                  onTap: _jmSearchAction(e),
                ),
              )
              .toList(),
        ),
        normal.ComicInfoMetadata(
          type: 'actors',
          name: '角色',
          value: info.actors
              .map(
                (e) => normal.ComicInfoActionItem(
                  name: e,
                  onTap: _jmSearchAction(e),
                ),
              )
              .toList(),
        ),
      ],
    ),
    eps: info.series
        .map(
          (e) => normal.Ep(
            id: e.id,
            name: e.name,
            order: int.tryParse(e.sort) ?? int.tryParse(e.id) ?? 1,
          ),
        )
        .toList(),
    recommend: const [],
    totalViews: int.tryParse(info.totalViews) ?? 0,
    totalLikes: int.tryParse(info.likes) ?? 0,
    totalComments: int.tryParse(info.commentTotal) ?? 0,
    isFavourite: info.isFavorite,
    isLiked: info.liked,
    allowComment: true,
    allowLike: true,
    allowFavorite: true,
    allowDownload: true,
  );
}

String _uniqueKey(String source, String comicId) => '$source:$comicId';

String _downloadStorageRoot(
  String downloadRoot,
  String source,
  String comicId,
) {
  return '$downloadRoot${Platform.pathSeparator}$source${Platform.pathSeparator}original${Platform.pathSeparator}$comicId';
}

Future<String> _resolveLegacyCoverPath({
  required String downloadRoot,
  required String source,
  required String comicId,
  required String fallback,
}) async {
  if (source != 'bika') {
    return fallback;
  }

  final coverDir = Directory(
    '${_downloadStorageRoot(downloadRoot, source, comicId)}${Platform.pathSeparator}cover',
  );
  if (!await coverDir.exists()) {
    return fallback;
  }
  final files = await coverDir
      .list()
      .where((e) => e is File)
      .cast<File>()
      .toList();
  if (files.isEmpty) {
    return fallback;
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  final file = files.first;
  final extension = p.extension(file.path);
  final normalizedName = '$comicId${extension.isEmpty ? '.jpg' : extension}';
  final normalizedPath = p.join(coverDir.path, normalizedName);

  if (p.basename(file.path) != normalizedName) {
    final normalizedFile = File(normalizedPath);
    if (await normalizedFile.exists()) {
      await normalizedFile.delete();
    }
    await file.rename(normalizedPath);
  }

  return normalizedName;
}

Map<String, dynamic> _coverMap(dynamic value) {
  value = _normalizeFlexValue(value);
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is normal.ComicImage) {
    return value.toJson();
  }
  return <String, dynamic>{};
}

Map<String, dynamic> _creatorMap(dynamic value) {
  value = _normalizeFlexValue(value);
  if (value is Map<String, dynamic>) {
    return Map<String, dynamic>.from(value);
  }
  if (value is normal.Creator) {
    return value.toJson();
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _titleMetaList(
  List<normal.ComicInfoActionItem> items,
) {
  return items
      .map((item) => _normalizeFlexValue(item.toJson()))
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<Map<String, dynamic>> _metadataList(List<normal.ComicInfoMetadata> items) {
  return items
      .where((item) => item.value.isNotEmpty)
      .map((item) => _normalizeFlexValue(item.toJson()))
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  value = _normalizeFlexValue(value);
  if (value is List) {
    return value
        .map((item) {
          if (item is Map<String, dynamic>) {
            return Map<String, dynamic>.from(item);
          }
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          if (item is normal.Ep) {
            return item.toJson();
          }
          if (item is normal.ComicInfoActionItem) {
            return item.toJson();
          }
          if (item is normal.ComicInfoMetadata) {
            return item.toJson();
          }
          return <String, dynamic>{};
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return <Map<String, dynamic>>[];
}

String _safeTitle(String value) => value.trim().isEmpty ? '未知' : value;

dynamic _normalizeFlexValue(dynamic value) {
  if (value == null || value is String || value is num || value is bool) {
    return value;
  }
  if (value is normal.NormalComicAllInfo) {
    return _normalizeFlexValue(value.toJson());
  }
  if (value is normal.ComicInfo) {
    return _normalizeFlexValue(value.toJson());
  }
  if (value is normal.Creator) {
    return _normalizeFlexValue(value.toJson());
  }
  if (value is normal.ComicImage) {
    return _normalizeFlexValue(value.toJson());
  }
  if (value is normal.ComicInfoActionItem) {
    return _normalizeFlexValue(value.toJson());
  }
  if (value is normal.ComicInfoMetadata) {
    return _normalizeFlexValue(value.toJson());
  }
  if (value is normal.Ep) {
    return _normalizeFlexValue(value.toJson());
  }
  if (value is normal.Recommend) {
    return _normalizeFlexValue(value.toJson());
  }
  if (value is Map<String, dynamic>) {
    return value.map((key, val) => MapEntry(key, _normalizeFlexValue(val)));
  }
  if (value is Map) {
    return value.map(
      (key, val) => MapEntry(key.toString(), _normalizeFlexValue(val)),
    );
  }
  if (value is List) {
    return value.map(_normalizeFlexValue).toList();
  }
  throw UnsupportedError('Unsupported flex value: ${value.runtimeType}');
}

class _LegacyChapterFiles {
  const _LegacyChapterFiles({required this.id, required this.files});

  final String id;
  final List<String> files;
}

Future<void> _normalizeLegacyChapterFiles({
  required String root,
  required List<_LegacyChapterFiles> chapters,
}) async {
  for (final chapter in chapters) {
    final chapterDir = Directory(p.join(root, 'comic', chapter.id));
    if (!await chapterDir.exists()) {
      continue;
    }

    for (var index = 0; index < chapter.files.length; index++) {
      final raw = chapter.files[index];
      final oldName = _sanitizeLegacyName(raw);
      final oldPath = p.join(chapterDir.path, oldName);
      final file = File(oldPath);
      if (!await file.exists()) {
        continue;
      }

      final newName = _orderedImageFileName(index, raw);
      final newPath = p.join(chapterDir.path, newName);
      if (oldPath == newPath) {
        continue;
      }

      final target = File(newPath);
      if (await target.exists()) {
        await target.delete();
      }
      await file.rename(newPath);
    }
  }
}

String _sanitizeLegacyName(String raw) {
  final name = raw.split(RegExp(r'[\\/]')).last.trim();
  return name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
}

String _orderedImageFileName(int index, String raw) {
  final base = raw.split(RegExp(r'[\\/]')).last.trim();
  final ext = p.extension(base);
  return '${(index + 1).toString().padLeft(4, '0')}${ext.isEmpty ? '.bin' : ext}';
}

Map<String, dynamic> _jmSearchAction(String keyword) {
  return {
    'type': 'openSearch',
    'payload': {'source': 'jm', 'keyword': keyword},
  };
}

Map<String, dynamic> _bikaSearchAction({required String keyword}) {
  return {
    'type': 'openSearch',
    'payload': {'source': 'bika', 'keyword': keyword},
  };
}

Map<String, dynamic> _bikaCategoryAction(String category) {
  return {
    'type': 'openSearch',
    'payload': {
      'source': 'bika',
      'categories': [category],
    },
  };
}

Map<String, dynamic> _bikaCreatorAction(String creatorId, String creatorName) {
  return {
    'type': 'openSearch',
    'payload': {
      'source': 'bika',
      'keyword': creatorName,
      'url': 'https://picaapi.picacomic.com/comics?ca=$creatorId&s=ld&page=1',
    },
  };
}
