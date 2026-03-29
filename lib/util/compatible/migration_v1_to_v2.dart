import 'dart:convert';
import 'dart:io';

import 'package:objectbox/objectbox.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/jm_url_set.dart';

Future<void> migrateV1ToV2(ObjectBox objectbox) async {
  _migrateLegacySearchHistory(objectbox);
  _debugLogMigrationSnapshot('before', _buildLegacySnapshot(objectbox));
  final proxy = objectbox.userSettingBox.get(1)?.bikaSetting.proxy ?? 3;

  final favorites = _buildFavorites(objectbox);
  final histories = _buildHistories(objectbox, proxy);
  final downloads = await _buildDownloads(objectbox, proxy);

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

  _debugLogMigrationSnapshot('after', _buildUnifiedSnapshot(objectbox));
}

void _migrateLegacySearchHistory(ObjectBox objectbox) {
  final user = objectbox.userSettingBox.get(1);
  if (user == null) {
    return;
  }
  final setting = user.globalSetting;
  final migrated = setting.searchHistory
      .map(_migrateSearchHistoryEntry)
      .where((entry) => entry.trim().isNotEmpty)
      .toList();
  if (_listEquals(setting.searchHistory, migrated)) {
    return;
  }
  user.globalSetting = setting.copyWith(searchHistory: migrated);
  objectbox.userSettingBox.put(user);
}

String _migrateSearchHistoryEntry(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return value;
  }
  final split = value.split('&&');
  if (split.length < 2) {
    return value;
  }
  final keyword = split.first.trim();
  final tail = split.sublist(1).join('&&').trim();
  if (tail.startsWith('{') && tail.endsWith('}')) {
    return value;
  }
  if (keyword.isEmpty || tail.isEmpty) {
    return value;
  }
  final creatorId = _extractCreatorIdFromLegacyUrl(tail);
  if (creatorId.isEmpty) {
    return value;
  }
  return '$keyword&&${jsonEncode({'mode': 'creator', 'creatorId': creatorId, 'url': tail})}';
}

String _extractCreatorIdFromLegacyUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final creatorId = uri.queryParameters['ca']?.trim() ?? '';
    return creatorId;
  } catch (_) {
    return '';
  }
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}

void _debugLogMigrationSnapshot(String stage, Map<String, dynamic> snapshot) {
  final encoder = const JsonEncoder.withIndent('  ');
  stdout.writeln('[migration_v1_to_v2][$stage] snapshot begin');
  stdout.writeln(encoder.convert(snapshot));
  stdout.writeln('[migration_v1_to_v2][$stage] snapshot end');
}

Map<String, dynamic> _buildLegacySnapshot(ObjectBox objectbox) {
  return {
    'jmFavorite': objectbox.jmFavoriteBox
        .getAll()
        .map((e) => e.toJson())
        .toList(),
    'bikaHistory': objectbox.bikaHistoryBox
        .getAll()
        .map((e) => e.toJson())
        .toList(),
    'jmHistory': objectbox.jmHistoryBox
        .getAll()
        .map((e) => e.toJson())
        .toList(),
    'bikaDownload': objectbox.bikaDownloadBox
        .getAll()
        .map((e) => e.toJson())
        .toList(),
    'jmDownload': objectbox.jmDownloadBox
        .getAll()
        .map((e) => e.toJson())
        .toList(),
  };
}

Map<String, dynamic> _buildUnifiedSnapshot(ObjectBox objectbox) {
  return {
    'unifiedFavorite': objectbox.unifiedFavoriteBox
        .getAll()
        .map((e) => e.toJson())
        .toList(),
    'unifiedHistory': objectbox.unifiedHistoryBox
        .getAll()
        .map((e) => e.toJson())
        .toList(),
    'unifiedDownload': objectbox.unifiedDownloadBox
        .getAll()
        .map((e) => e.toJson())
        .toList(),
  };
}

UnifiedComicFavorite buildUnifiedFavoriteFromLegacy(JmFavorite item) =>
    _jmFavoriteToUnified(item);

UnifiedComicHistory buildUnifiedHistoryFromBikaLegacy(BikaComicHistory item) =>
    _bikaHistoryToUnified(item, 3);

UnifiedComicHistory buildUnifiedHistoryFromJmLegacy(JmHistory item) =>
    _jmHistoryToUnified(item);

Future<UnifiedComicDownload> buildUnifiedDownloadFromBikaLegacy(
  BikaComicDownload item,
) async => _bikaDownloadToUnified(item, await getDownloadPath(), 3);

Future<UnifiedComicDownload> buildUnifiedDownloadFromJmLegacy(
  JmDownload item,
) async => _jmDownloadToUnified(item, await getDownloadPath());

List<UnifiedComicFavorite> _buildFavorites(ObjectBox objectbox) {
  final jmFavorites = objectbox.jmFavoriteBox.getAll();
  return jmFavorites.map(_jmFavoriteToUnified).toList();
}

List<UnifiedComicHistory> _buildHistories(ObjectBox objectbox, int proxy) {
  final bikaHistories = objectbox.bikaHistoryBox.getAll().map(
    (item) => _bikaHistoryToUnified(item, proxy),
  );
  final jmHistories = objectbox.jmHistoryBox.getAll().map(_jmHistoryToUnified);
  return [...bikaHistories, ...jmHistories].toList();
}

Future<List<UnifiedComicDownload>> _buildDownloads(
  ObjectBox objectbox,
  int proxy,
) async {
  final downloadRoot = await getDownloadPath();
  final bikaDownloads = <UnifiedComicDownload>[];
  for (final item in objectbox.bikaDownloadBox.getAll()) {
    bikaDownloads.add(await _bikaDownloadToUnified(item, downloadRoot, proxy));
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

UnifiedComicHistory _bikaHistoryToUnified(BikaComicHistory item, int proxy) {
  final coverUrl = _buildLegacyBikaImageUrl(
    item.thumbFileServer,
    item.thumbPath,
    proxy: proxy,
    kind: 'cover',
  );
  final avatarUrl = _buildLegacyBikaImageUrl(
    item.creatorAvatarFileServer,
    item.creatorAvatarPath,
    proxy: proxy,
    kind: 'creator',
  );
  return UnifiedComicHistory(
    uniqueKey: _uniqueKey('bika', item.comicId),
    source: 'bika',
    comicId: item.comicId,
    title: item.title,
    description: item.description,
    cover: _coverMap(
      normal.ComicImage(
        id: item.comicId,
        url: coverUrl,
        name: item.thumbOriginalName,
        extension: {
          'path': _sanitizeLegacyStoredPath(
            item.thumbPath,
            fallbackName: item.thumbOriginalName,
          ),
          'fileServer': item.thumbFileServer,
        },
      ),
    ),
    creator: _creatorMap(
      normal.Creator(
        id: item.creatorId,
        name: item.creatorName,
        avatar: normal.ComicImage(
          id: item.creatorId,
          url: avatarUrl,
          name: item.creatorAvatarOriginalName,
          extension: {
            'path': _sanitizeLegacyStoredPath(
              item.creatorAvatarPath,
              fallbackName: item.creatorAvatarOriginalName,
            ),
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
  int proxy,
) async {
  final coverPath = _sanitizeLegacyStoredPath(
    item.thumbPath,
    fallbackName: item.thumbOriginalName,
  );
  final legacy = jsonDecode(item.comicInfoAll) as Map<String, dynamic>;
  final epsDocs = ((legacy['eps'] as Map?)?['docs'] as List? ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  final storedChapters = epsDocs.map((e) {
    final chapterId = e['_id']?.toString() ?? '';
    final imageDocs = (((e['pages'] as Map?)?['docs'] as List?) ?? const [])
        .whereType<Map>()
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    final images = imageDocs.map((p) {
      final media = Map<String, dynamic>.from(
        (p['media'] as Map?) ?? const <String, dynamic>{},
      );
      final rawPath = media['path']?.toString() ?? '';
      final originalName = media['originalName']?.toString() ?? '';
      final fileServer = media['fileServer']?.toString() ?? '';
      final imageName = _resolveImageDisplayName(originalName, rawPath);
      return UnifiedComicDownloadImage(
        id: p['_id']?.toString() ?? _legacyImageId(rawPath),
        name: imageName,
        path: _sanitizeLegacyStoredPath(rawPath, fallbackName: imageName),
        url: _buildLegacyBikaImageUrl(
          fileServer,
          rawPath,
          proxy: proxy,
          kind: 'comic',
        ),
      );
    }).toList();
    return UnifiedComicDownloadStoredChapter(
      id: chapterId,
      name: e['title']?.toString() ?? '',
      order: _toInt(e['order']),
      images: images,
    );
  }).toList();

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
          url: _buildLegacyBikaImageUrl(
            item.creatorAvatarFileServer,
            item.creatorAvatarPath,
            proxy: proxy,
            kind: 'creator',
          ),
          name: item.creatorAvatarOriginalName,
          extension: {
            'path': _sanitizeLegacyStoredPath(
              item.creatorAvatarPath,
              fallbackName: item.creatorAvatarOriginalName,
            ),
            'fileServer': item.creatorAvatarFileServer,
          },
        ),
        onTap: _bikaCreatorAction(item.creatorId, item.creatorName),
      ),
      description: item.description,
      cover: normal.ComicImage(
        id: item.comicId,
        url: _buildLegacyBikaImageUrl(
          item.thumbFileServer,
          item.thumbPath,
          proxy: proxy,
          kind: 'cover',
        ),
        name: item.thumbOriginalName,
        extension: {
          'path': _sanitizeLegacyStoredPath(
            coverPath,
            fallbackName: item.thumbOriginalName,
          ),
          'fileServer': item.thumbFileServer,
        },
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
    eps: storedChapters
        .map((e) => normal.Ep(id: e.id, name: e.name, order: e.order))
        .toList(),
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
    extension: {
      'downloadChapters': storedChapters
          .map(
            (chapter) => {
              'id': chapter.id,
              'name': chapter.name,
              'order': chapter.order,
              'images': chapter.images.map((image) => image.toMap()).toList(),
            },
          )
          .toList(),
    },
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
    chapters: storedChapters
        .map(
          (chapter) => UnifiedComicDownloadChapter(
            id: chapter.id,
            title: chapter.name,
            order: chapter.order,
            taskChapterId: chapter.order.toString(),
          ).toMap(),
        )
        .toList(),
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
  final coverPath = _sanitizeLegacyStoredPath(
    '${item.comicId}.jpg',
    fallbackName: '${item.comicId}.jpg',
  );
  final info = jsonDecode(item.allInfo) as Map<String, dynamic>;
  final series = (info['series'] as List? ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  final storedChapters = series.map((e) {
    final chapterId = e['id']?.toString() ?? '';
    final images = _toStringList((e['info'] as Map?)?['images']).map((raw) {
      final imageName = _resolveImageDisplayName('', raw);
      return UnifiedComicDownloadImage(
        id: _legacyImageId(raw),
        name: imageName,
        path: _sanitizeLegacyStoredPath(raw, fallbackName: imageName),
        url: getJmImagesUrl(chapterId, raw),
      );
    }).toList();
    return UnifiedComicDownloadStoredChapter(
      id: chapterId,
      name: e['name']?.toString() ?? '',
      order: _toInt(e['sort'], fallback: _toInt(chapterId, fallback: 1)),
      images: images,
    );
  }).toList();
  final normalInfo = _jmDownloadInfoToNormal(info);
  final detail = normalInfo
      .copyWith(
        eps: storedChapters
            .map((e) => normal.Ep(id: e.id, name: e.name, order: e.order))
            .toList(),
        extension: {
          ...normalInfo.extension,
          'downloadChapters': storedChapters
              .map(
                (chapter) => {
                  'id': chapter.id,
                  'name': chapter.name,
                  'order': chapter.order,
                  'images': chapter.images
                      .map((image) => image.toMap())
                      .toList(),
                },
              )
              .toList(),
        },
      )
      .toJson();
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
    chapters: storedChapters
        .map(
          (chapter) => UnifiedComicDownloadChapter(
            id: chapter.id,
            title: chapter.name,
            order: chapter.order,
            taskChapterId: chapter.id,
          ).toMap(),
        )
        .toList(),
    detailJson: jsonEncode(normalizedDetail),
    storageRoot: _downloadStorageRoot(downloadRoot, 'jm', item.comicId),
    createdAt: item.downloadTime,
    updatedAt: item.downloadTime,
    downloadedAt: item.downloadTime,
    deleted: false,
    schemaVersion: 2,
  );
}

normal.NormalComicAllInfo _jmDownloadInfoToNormal(Map<String, dynamic> info) {
  final series = (info['series'] as List? ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  final epsCount = series.isEmpty ? 1 : series.length;
  return normal.NormalComicAllInfo(
    comicInfo: normal.ComicInfo(
      id: info['id']?.toString() ?? '',
      title: info['name']?.toString() ?? '',
      titleMeta: [
        normal.ComicInfoActionItem(
          name: '浏览：${info['total_views']?.toString() ?? '0'}',
        ),
        normal.ComicInfoActionItem(
          name: '更新时间：${_safeTitle(info['addtime']?.toString() ?? '')}',
        ),
        normal.ComicInfoActionItem(name: '章节数：$epsCount'),
        normal.ComicInfoActionItem(
          name: '禁漫车：jm${info['id']?.toString() ?? ''}',
        ),
      ],
      creator: const normal.Creator(
        id: '',
        name: '',
        avatar: normal.ComicImage(id: '', url: '', name: ''),
      ),
      description: info['description']?.toString() ?? '',
      cover: normal.ComicImage(
        id: info['id']?.toString() ?? '',
        url: getJmCoverUrl(info['id']?.toString() ?? ''),
        name: '${info['id']?.toString() ?? ''}.jpg',
        extension: {
          'path': _sanitizeLegacyStoredPath(
            '${info['id']?.toString() ?? ''}.jpg',
            fallbackName: '${info['id']?.toString() ?? ''}.jpg',
          ),
        },
      ),
      metadata: [
        normal.ComicInfoMetadata(
          type: 'author',
          name: '作者',
          value: _toStringList(info['author'])
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
          value: _toStringList(info['tags'])
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
          value: _toStringList(info['works'])
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
          value: _toStringList(info['actors'])
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
    eps: series
        .map(
          (e) => normal.Ep(
            id: e['id']?.toString() ?? '',
            name: e['name']?.toString() ?? '',
            order: _toInt(e['sort'], fallback: _toInt(e['id'], fallback: 1)),
          ),
        )
        .toList(),
    recommend: const [],
    totalViews: _toInt(info['total_views']),
    totalLikes: _toInt(info['likes']),
    totalComments: _toInt(info['comment_total']),
    isFavourite: info['is_favorite'] == true,
    isLiked: info['liked'] == true,
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

int _toInt(Object? value, {int fallback = 0}) {
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<String> _toStringList(Object? value) {
  return (value as List? ?? const [])
      .map((e) => e?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
}

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

String _sanitizeLegacyStoredPath(
  String rawPath, {
  required String fallbackName,
}) {
  final candidate = rawPath.trim().isNotEmpty ? rawPath.trim() : fallbackName;
  final sanitized = candidate.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
  if (sanitized.isNotEmpty) {
    return sanitized;
  }
  final safeFallback = fallbackName.trim().isNotEmpty
      ? fallbackName.trim()
      : 'asset.bin';
  final fallbackSanitized = safeFallback.replaceAll(
    RegExp(r'[^a-zA-Z0-9_\-.]'),
    '_',
  );
  return fallbackSanitized.isNotEmpty ? fallbackSanitized : 'asset.bin';
}

String _resolveImageDisplayName(String originalName, String rawPath) {
  final fromOriginal = originalName.trim();
  if (fromOriginal.isNotEmpty) {
    return fromOriginal;
  }
  final fromPath = _pathFileName(rawPath);
  if (fromPath.isNotEmpty) {
    return fromPath;
  }
  return 'asset.bin';
}

String _legacyImageId(String raw) {
  final base = _pathFileName(raw);
  final dotIndex = base.lastIndexOf('.');
  final withoutExt = dotIndex > 0 ? base.substring(0, dotIndex) : base;
  final value = withoutExt.isNotEmpty ? withoutExt : 'asset';
  return value.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
}

String _pathFileName(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return '';
  }
  final parts = value.split(RegExp(r'[\\/]'));
  return parts.isEmpty ? '' : parts.last.trim();
}

String _buildLegacyBikaImageUrl(
  String fileServer,
  String path, {
  required int proxy,
  required String kind,
}) {
  var url = fileServer.trim();
  var nextPath = path.trim();
  if (url.isEmpty || nextPath.isEmpty) {
    return '';
  }

  if (url == 'https://storage1.picacomic.com') {
    if (kind == 'cover') {
      url = 'https://img.picacomic.com';
    } else {
      url = proxy == 1
          ? 'https://storage.diwodiwo.xyz'
          : 'https://s3.picacomic.com';
    }
  } else if (url == 'https://storage-b.picacomic.com') {
    if (kind == 'creator') {
      url = 'https://storage-b.picacomic.com';
    } else if (kind == 'cover') {
      url = 'https://img.picacomic.com';
    } else {
      url = 'https://storage-b.diwodiwo.xyz';
    }
  }

  if (nextPath.contains('picacomic-paint.jpg') ||
      nextPath.contains('picacomic-gift.jpg')) {
    url = proxy == 1
        ? 'https://storage.diwodiwo.xyz/static'
        : 'https://s3.picacomic.com/static';
  }

  if (nextPath.contains('tobeimg/')) {
    nextPath = nextPath.replaceAll('tobeimg/', '');
  } else if (nextPath.contains('tobs/')) {
    nextPath = 'static/${nextPath.replaceAll('tobs/', '')}';
  } else if (!nextPath.contains('/') && !url.contains('static')) {
    nextPath = 'static/$nextPath';
  }

  return '${url.trim()}/${nextPath.trim()}';
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
      'extern': {
        'categories': [category],
      },
    },
  };
}

Map<String, dynamic> _bikaCreatorAction(String creatorId, String creatorName) {
  return {
    'type': 'openSearch',
    'payload': {
      'source': 'bika',
      'keyword': creatorName,
      'extern': {'mode': 'creator', 'creatorId': creatorId},
      'url': 'https://picaapi.picacomic.com/comics?ca=$creatorId&s=ld&page=1',
    },
  };
}
