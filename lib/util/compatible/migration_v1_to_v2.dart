import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/src/rust/api/qjs.dart';
import 'package:zephyr/util/get_path.dart';

const _legacyJmImageBaseUrl = 'https://cdn-msp12.jmdanjonproxy.xyz';

const String _kBikaPluginUuid = '0a0e5858-a467-4702-994a-79e608a4589d';
const String _kJmPluginUuid = 'bf99008d-010b-4f17-ac7c-61a9b57dc3d9';
const String _kLegacyBikaSource = 'bika';
const String _kLegacyJmSource = 'jm';

String _legacyJmCoverUrl(String id) {
  return '$_legacyJmImageBaseUrl/media/albums/${id}_3x4.jpg';
}

String _legacyJmImageUrl(String chapterId, String imageName) {
  return '$_legacyJmImageBaseUrl/media/photos/$chapterId/$imageName';
}

Future<void> migrateV1ToV2(ObjectBox objectbox) async {
  _migrateLegacySearchHistory(objectbox);
  _migrateLegacyPluginSettings(objectbox);
  _debugLogMigrationSnapshot('before', _buildLegacySnapshot(objectbox));
  final proxy = objectbox.userSettingBox.get(1)?.bikaSetting.proxy ?? 3;

  final favorites = _buildFavorites(objectbox);
  final histories = _buildHistories(objectbox, proxy);
  final downloads = await _buildDownloads(objectbox, proxy);
  await _seedBuiltinPlugins(objectbox);

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

void _migrateLegacyPluginSettings(ObjectBox objectbox) {
  final user = objectbox.userSettingBox.get(1);
  if (user == null) {
    return;
  }

  final bika = user.bikaSetting;
  final jm = user.jmSetting;

  final bikaConfig = _upsertPluginConfigData(
    objectbox,
    pluginUuid: _kBikaPluginUuid,
    patches: {
      'auth.account': bika.account,
      'auth.password': bika.password,
      'auth.authorization': bika.authorization,
      'network.proxy': bika.proxy.toString(),
      'image.quality': bika.imageQuality,
      'search.blockedCategories': _selectedKeysFromBoolMap(
        bika.shieldCategoryMap,
      ),
      'home.blockedCategories': _selectedKeysFromBoolMap(
        bika.shieldHomePageCategoriesMap,
      ),
    },
  );
  if (bikaConfig) {
    logger.d('[migration_v1_to_v2][settings] migrated bika plugin settings');
  }

  final jmConfig = _upsertPluginConfigData(
    objectbox,
    pluginUuid: _kJmPluginUuid,
    patches: {
      'auth.account': jm.account,
      'auth.password': jm.password,
      'auth.jwt': user.jmJwt,
      'auth.userInfo': _parseLegacyUserInfo(jm.userInfo),
    },
  );
  if (jmConfig) {
    logger.d('[migration_v1_to_v2][settings] migrated jm plugin settings');
  }
}

bool _upsertPluginConfigData(
  ObjectBox objectbox, {
  required String pluginUuid,
  required Map<String, dynamic> patches,
}) {
  final box = objectbox.pluginConfigBox;
  final found = box.query(PluginConfig_.name.equals(pluginUuid)).build().find();
  final existing = found.isNotEmpty ? found.first : null;
  final data = _decodeJsonObject(existing?.config);

  var changed = false;
  for (final entry in patches.entries) {
    final key = entry.key;
    final next = entry.value;
    if (!_shouldWriteLegacyValue(next)) {
      continue;
    }
    final current = data[key];
    if (_hasMeaningfulValue(current)) {
      continue;
    }
    data[key] = next;
    changed = true;
  }

  if (pluginUuid == _kBikaPluginUuid && data.containsKey('download.slow')) {
    data.remove('download.slow');
    changed = true;
  }

  if (!changed) {
    return false;
  }

  if (existing == null) {
    box.put(PluginConfig(name: pluginUuid, config: jsonEncode(data)));
  } else {
    existing.config = jsonEncode(data);
    box.put(existing);
  }
  return true;
}

List<String> _selectedKeysFromBoolMap(Map<String, bool> raw) {
  return raw.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key.trim())
      .where((value) => value.isNotEmpty)
      .toList();
}

Map<String, dynamic> _parseLegacyUserInfo(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return const <String, dynamic>{};
  }
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {}
  return const <String, dynamic>{};
}

bool _shouldWriteLegacyValue(dynamic value) {
  if (value == null) {
    return false;
  }
  if (value is String) {
    return value.trim().isNotEmpty;
  }
  if (value is List) {
    return value.isNotEmpty;
  }
  if (value is Map) {
    return value.isNotEmpty;
  }
  return true;
}

bool _hasMeaningfulValue(dynamic value) {
  if (value == null) {
    return false;
  }
  if (value is String) {
    return value.trim().isNotEmpty;
  }
  if (value is List) {
    return value.isNotEmpty;
  }
  if (value is Map) {
    return value.isNotEmpty;
  }
  return true;
}

Future<void> migrateLegacyDownloadFilesToPluginUuidLayout() async {
  final downloadRoot = await getDownloadPath();
  logger.d('[migration_v1_to_v2][files] start migrate root=$downloadRoot');
  await _migrateLegacyDownloadRoot(
    downloadRoot: downloadRoot,
    legacySource: _kLegacyBikaSource,
    targetPluginUuid: _kBikaPluginUuid,
    includeLegacyRootWithoutOriginal: false,
  );
  await _migrateLegacyDownloadRoot(
    downloadRoot: downloadRoot,
    legacySource: _kLegacyJmSource,
    targetPluginUuid: _kJmPluginUuid,
    includeLegacyRootWithoutOriginal: true,
  );
  logger.d('[migration_v1_to_v2][files] done');
}

Future<void> _seedBuiltinPlugins(ObjectBox objectbox) async {
  final now = DateTime.now().toUtc();

  final existing = objectbox.pluginInfoBox
      .query(
        PluginInfo_.uuid
            .equals(_kBikaPluginUuid)
            .or(PluginInfo_.uuid.equals(_kJmPluginUuid)),
      )
      .build()
      .find();
  final existingByUuid = {for (final item in existing) item.uuid: item};

  final upserts = <PluginInfo>[
    _buildBuiltinPluginInfo(
      existingByUuid[_kBikaPluginUuid],
      uuid: _kBikaPluginUuid,
      builtinBundle: getJsBundle(name: _kBikaPluginUuid),
      now: now,
    ),
    _buildBuiltinPluginInfo(
      existingByUuid[_kJmPluginUuid],
      uuid: _kJmPluginUuid,
      builtinBundle: getJsBundle(name: _kJmPluginUuid),
      now: now,
    ),
  ];
  objectbox.pluginInfoBox.putMany(upserts);
}

PluginInfo _buildBuiltinPluginInfo(
  PluginInfo? existing, {
  required String uuid,
  required String builtinBundle,
  required DateTime now,
}) {
  final normalizedBuiltinBundle = builtinBundle.trim();
  if (normalizedBuiltinBundle.isEmpty) {
    throw StateError('builtin plugin bundle missing: $uuid');
  }
  return PluginInfo(
    id: existing?.id ?? 0,
    uuid: uuid,
    version: existing?.version ?? '0.0.0',
    originScript: builtinBundle,
    insertedAt: existing?.insertedAt ?? now,
    updatedAt: now,
    isEnabled: existing?.isEnabled ?? true,
    isDeleted: false,
    deletedAt: null,
    lastLoadSuccess: existing?.lastLoadSuccess ?? false,
    lastLoadError: existing?.lastLoadError,
    debug: existing?.debug ?? false,
    debugUrl: existing?.debugUrl,
  );
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
  logger.d('[migration_v1_to_v2][$stage] snapshot begin');

  if (snapshot.isEmpty) {
    logger.w('Snapshot is empty!');
  }

  snapshot.forEach((key, value) {
    if (value is List) {
      logger.d('Table: $key, Count: ${value.length}');
    } else {
      logger.e('Data for $key is not a List');
    }
  });

  logger.d('[migration_v1_to_v2][$stage] snapshot end');
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
    uniqueKey: _uniqueKey(_kJmPluginUuid, item.comicId),
    source: _kJmPluginUuid,
    comicId: item.comicId,
    title: item.name,
    description: item.description,
    cover: jsonEncode(
      _coverMap(
        normal.ComicImage(
          id: item.comicId,
          url: _legacyJmCoverUrl(item.comicId),
          name: '${item.comicId}.jpg',
          extension: {'path': '${item.comicId}.jpg'},
        ),
      ),
    ),
    creator: jsonEncode(
      _creatorMap(
        normal.Creator(
          id: '',
          name: '',
          avatar: const normal.ComicImage(id: '', url: '', name: ''),
        ),
      ),
    ),
    titleMeta: jsonEncode(
      _titleMetaList([
        normal.ComicInfoActionItem(name: '浏览：${item.totalViews}'),
        normal.ComicInfoActionItem(name: '更新时间：${_safeTitle(item.addtime)}'),
      ]),
    ),
    metadata: _metadataAsStringFromItems([
      normal.ComicInfoMetadata(
        type: 'author',
        name: '作者',
        value: _actionItemsFromStrings(item.author),
      ),
      normal.ComicInfoMetadata(
        type: 'tags',
        name: '标签',
        value: _actionItemsFromStrings(item.tags),
      ),
      normal.ComicInfoMetadata(
        type: 'works',
        name: '作品',
        value: _actionItemsFromStrings(item.works),
      ),
      normal.ComicInfoMetadata(
        type: 'actors',
        name: '角色',
        value: _actionItemsFromStrings(item.actors),
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
    uniqueKey: _uniqueKey(_kBikaPluginUuid, item.comicId),
    source: _kBikaPluginUuid,
    comicId: item.comicId,
    title: item.title,
    description: item.description,
    cover: jsonEncode(
      _coverMap(
        normal.ComicImage(
          id: item.comicId,
          url: coverUrl,
          name: item.thumbOriginalName,
          extension: {
            'path': _sanitizeLegacyStoredPath(item.thumbPath, allowEmpty: true),
            'fileServer': item.thumbFileServer,
          },
        ),
      ),
    ),
    creator: jsonEncode(
      _creatorMap(
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
                allowEmpty: true,
              ),
              'fileServer': item.creatorAvatarFileServer,
            },
          ),
        ),
      ),
    ),
    titleMeta: jsonEncode(
      _titleMetaList([
        normal.ComicInfoActionItem(name: '浏览：${item.totalViews}'),
        normal.ComicInfoActionItem(name: '更新时间：${item.updatedAt.toLocal()}'),
        if (item.pagesCount > 0)
          normal.ComicInfoActionItem(name: '页数：${item.pagesCount}'),
        normal.ComicInfoActionItem(name: '章节数：${item.epsCount}'),
      ]),
    ),
    metadata: _metadataAsStringFromItems([
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
        value: _actionItemsFromStrings(item.categories),
      ),
      normal.ComicInfoMetadata(
        type: 'tags',
        name: '标签',
        value: _actionItemsFromStrings(item.tags),
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
    uniqueKey: _uniqueKey(_kJmPluginUuid, item.comicId),
    source: _kJmPluginUuid,
    comicId: item.comicId,
    title: item.name,
    description: item.description,
    cover: jsonEncode(
      _coverMap(
        normal.ComicImage(
          id: item.comicId,
          url: _legacyJmCoverUrl(item.comicId),
          name: '${item.comicId}.jpg',
          extension: {'path': '${item.comicId}.jpg'},
        ),
      ),
    ),
    creator: jsonEncode(
      _creatorMap(
        normal.Creator(
          id: '',
          name: '',
          avatar: const normal.ComicImage(id: '', url: '', name: ''),
        ),
      ),
    ),
    titleMeta: jsonEncode(
      _titleMetaList([
        normal.ComicInfoActionItem(name: '浏览：${item.totalViews}'),
        normal.ComicInfoActionItem(name: '更新时间：${_safeTitle(item.addtime)}'),
      ]),
    ),
    metadata: _metadataAsStringFromItems([
      normal.ComicInfoMetadata(
        type: 'author',
        name: '作者',
        value: _actionItemsFromStrings(item.author),
      ),
      normal.ComicInfoMetadata(
        type: 'tags',
        name: '标签',
        value: _actionItemsFromStrings(item.tags),
      ),
      normal.ComicInfoMetadata(
        type: 'works',
        name: '作品',
        value: _actionItemsFromStrings(item.works),
      ),
      normal.ComicInfoMetadata(
        type: 'actors',
        name: '角色',
        value: _actionItemsFromStrings(item.actors),
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
  final coverPath = _sanitizeLegacyStoredPath(item.thumbPath, allowEmpty: true);
  final legacy = jsonDecode(item.comicInfoAll) as Map<String, dynamic>;
  final epsDocs = ((legacy['eps'] as Map?)?['docs'] as List? ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  final storedChapters = _withSequentialChapterOrders(
    epsDocs.map((e) {
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
          path: _sanitizeLegacyStoredPath(rawPath, allowEmpty: true),
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
    }).toList(),
  );

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
              allowEmpty: true,
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
          'path': _sanitizeLegacyStoredPath(coverPath, allowEmpty: true),
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
          value: _actionItemsFromStrings(
            item.categories,
            onTapBuilder: (e) => _bikaCategoryAction(e),
          ),
        ),
        normal.ComicInfoMetadata(
          type: 'tags',
          name: '标签',
          value: _actionItemsFromStrings(
            item.tags,
            onTapBuilder: (e) => _bikaSearchAction(keyword: e),
          ),
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
    allowComments: item.allowComment,
    allowLike: true,
    allowCollected: true,
    allowDownload: item.allowDownload,
    extension: {
      'version': 'v2',
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
    uniqueKey: _uniqueKey(_kBikaPluginUuid, item.comicId),
    source: _kBikaPluginUuid,
    comicId: item.comicId,
    title: item.title,
    description: item.description,
    cover: jsonEncode(_coverMap(comicInfoMap['cover'])),
    creator: jsonEncode(_creatorMap(comicInfoMap['creator'])),
    titleMeta: jsonEncode(_mapList(comicInfoMap['titleMeta'])),
    metadata: _metadataAsString(comicInfoMap['metadata']),
    totalViews: item.totalViews,
    totalLikes: item.totalLikes,
    totalComments: item.totalComments,
    isFavourite: item.isFavourite,
    isLiked: item.isLiked,
    allowComment: item.allowComment,
    allowLike: true,
    allowFavorite: true,
    allowDownload: item.allowDownload,
    chapters: jsonEncode(
      storedChapters
          .map(
            (chapter) => UnifiedComicDownloadChapter(
              id: chapter.id,
              title: chapter.name,
              order: chapter.order,
            ).toMap(),
          )
          .toList(),
    ),
    detailJson: jsonEncode(normalizedDetail),
    storageRoot: _downloadStorageRoot(
      downloadRoot,
      _kBikaPluginUuid,
      item.comicId,
    ),
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
  final coverPath = _sanitizeLegacyStoredPath('${item.comicId}.jpg');
  final info = jsonDecode(item.allInfo) as Map<String, dynamic>;
  final series = (info['series'] as List? ?? const [])
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  final storedChapters = _withSequentialChapterOrders(
    series.map((e) {
      final chapterId = e['id']?.toString() ?? '';
      final images = _toStringList((e['info'] as Map?)?['images']).map((raw) {
        final imageName = _resolveImageDisplayName('', raw);
        return UnifiedComicDownloadImage(
          id: _legacyImageId(raw),
          name: imageName,
          path: _sanitizeLegacyStoredPath(raw, allowEmpty: true),
          url: _legacyJmImageUrl(chapterId, raw),
        );
      }).toList();
      return UnifiedComicDownloadStoredChapter(
        id: chapterId,
        name: e['name']?.toString() ?? '',
        order: _toInt(e['sort'], fallback: _toInt(chapterId, fallback: 1)),
        images: images,
      );
    }).toList(),
  );
  final normalInfo = _jmDownloadInfoToNormal(info);
  final detail = normalInfo
      .copyWith(
        eps: storedChapters
            .map((e) => normal.Ep(id: e.id, name: e.name, order: e.order))
            .toList(),
        extension: {
          ...normalInfo.extension,
          'version': 'v2',
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
    uniqueKey: _uniqueKey(_kJmPluginUuid, item.comicId),
    source: _kJmPluginUuid,
    comicId: item.comicId,
    title: item.name,
    description: item.description,
    cover: jsonEncode(cover),
    creator: jsonEncode(_creatorMap(comicInfoMap['creator'])),
    titleMeta: jsonEncode(_mapList(comicInfoMap['titleMeta'])),
    metadata: _metadataAsString(comicInfoMap['metadata']),
    totalViews: normalInfo.totalViews,
    totalLikes: normalInfo.totalLikes,
    totalComments: normalInfo.totalComments,
    isFavourite: normalInfo.isFavourite,
    isLiked: normalInfo.isLiked,
    allowComment: normalInfo.allowComments,
    allowLike: normalInfo.allowLike,
    allowFavorite: normalInfo.allowCollected,
    allowDownload: normalInfo.allowDownload,
    chapters: jsonEncode(
      storedChapters
          .map(
            (chapter) => UnifiedComicDownloadChapter(
              id: chapter.id,
              title: chapter.name,
              order: chapter.order,
            ).toMap(),
          )
          .toList(),
    ),
    detailJson: jsonEncode(normalizedDetail),
    storageRoot: _downloadStorageRoot(
      downloadRoot,
      _kJmPluginUuid,
      item.comicId,
    ),
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
        url: _legacyJmCoverUrl(info['id']?.toString() ?? ''),
        name: '${info['id']?.toString() ?? ''}.jpg',
        extension: {
          'path': _sanitizeLegacyStoredPath(
            '${info['id']?.toString() ?? ''}.jpg',
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
    allowComments: true,
    allowLike: true,
    allowCollected: true,
    allowDownload: true,
  );
}

String _uniqueKey(String source, String comicId) => '$source:$comicId';

List<UnifiedComicDownloadStoredChapter> _withSequentialChapterOrders(
  List<UnifiedComicDownloadStoredChapter> chapters,
) {
  final normalized = <UnifiedComicDownloadStoredChapter>[];
  for (var i = 0; i < chapters.length; i++) {
    final chapter = chapters[i];
    normalized.add(
      UnifiedComicDownloadStoredChapter(
        id: chapter.id,
        name: chapter.name,
        order: i + 1,
        images: chapter.images,
      ),
    );
  }
  return normalized;
}

Future<void> _migrateLegacyDownloadRoot({
  required String downloadRoot,
  required String legacySource,
  required String targetPluginUuid,
  required bool includeLegacyRootWithoutOriginal,
}) async {
  final targetRoot = Directory(
    p.join(downloadRoot, targetPluginUuid, 'original'),
  );
  await targetRoot.create(recursive: true);

  final legacyOriginalDir = Directory(
    p.join(downloadRoot, legacySource, 'original'),
  );
  await _moveLegacyComicDirsToTarget(
    sourceRoot: legacyOriginalDir,
    targetRoot: targetRoot,
    skipOriginalDirectory: false,
  );

  if (!includeLegacyRootWithoutOriginal) {
    await _normalizeTargetPluginDownloadLayout(
      targetRoot: targetRoot,
      targetPluginUuid: targetPluginUuid,
    );
    return;
  }

  final legacyRoot = Directory(p.join(downloadRoot, legacySource));
  await _moveLegacyComicDirsToTarget(
    sourceRoot: legacyRoot,
    targetRoot: targetRoot,
    skipOriginalDirectory: true,
  );
  await _normalizeTargetPluginDownloadLayout(
    targetRoot: targetRoot,
    targetPluginUuid: targetPluginUuid,
  );
}

Future<void> _normalizeTargetPluginDownloadLayout({
  required Directory targetRoot,
  required String targetPluginUuid,
}) async {
  if (targetPluginUuid != _kBikaPluginUuid &&
      targetPluginUuid != _kJmPluginUuid) {
    return;
  }
  if (!await targetRoot.exists()) {
    return;
  }
  final entities = await targetRoot.list().toList();
  for (final entity in entities) {
    if (entity is! Directory) {
      continue;
    }
    await _normalizeLegacyComicDirectory(entity);
  }
}

Future<void> _normalizeLegacyComicDirectory(Directory comicDir) async {
  final coverDir = Directory(p.join(comicDir.path, 'cover'));
  if (await coverDir.exists()) {
    final entities = await coverDir.list().toList();
    for (final entity in entities) {
      final name = p.basename(entity.path);
      if (name.trim().isEmpty) {
        continue;
      }
      final safeName = _sanitizeLegacyStoredPath(name);
      if (entity is File) {
        await _renameOrCopyFile(entity, File(p.join(comicDir.path, safeName)));
      } else if (entity is Directory) {
        await _moveOrMergeDirectory(
          source: entity,
          target: Directory(p.join(comicDir.path, safeName)),
        );
      }
    }
    await _deleteDirectoryIfEmpty(coverDir);
  }

  final comicSubDir = Directory(p.join(comicDir.path, 'comic'));
  if (await comicSubDir.exists()) {
    final entities = await comicSubDir.list().toList();
    for (final entity in entities) {
      if (entity is! Directory) {
        continue;
      }
      final chapterId = p.basename(entity.path).trim();
      if (chapterId.isEmpty) {
        continue;
      }
      await _moveOrMergeDirectory(
        source: entity,
        target: Directory(p.join(comicDir.path, chapterId)),
      );
    }
    await _deleteDirectoryIfEmpty(comicSubDir);
  }
}

Future<void> _moveLegacyComicDirsToTarget({
  required Directory sourceRoot,
  required Directory targetRoot,
  required bool skipOriginalDirectory,
}) async {
  if (!await sourceRoot.exists()) {
    return;
  }

  final entities = await sourceRoot.list().toList();
  for (final entity in entities) {
    if (entity is! Directory) {
      continue;
    }
    final comicId = p.basename(entity.path).trim();
    if (comicId.isEmpty) {
      continue;
    }
    if (skipOriginalDirectory && comicId.toLowerCase() == 'original') {
      continue;
    }
    final targetDir = Directory(p.join(targetRoot.path, comicId));
    await _moveOrMergeDirectory(source: entity, target: targetDir);
  }
}

Future<void> _moveOrMergeDirectory({
  required Directory source,
  required Directory target,
}) async {
  if (!await source.exists()) {
    return;
  }
  if (!await target.exists()) {
    await _renameOrCopyDirectory(source, target);
    return;
  }

  final entities = await source.list().toList();
  for (final entity in entities) {
    final name = p.basename(entity.path);
    if (entity is File) {
      final targetFile = File(p.join(target.path, name));
      if (await targetFile.exists()) {
        await entity.delete();
      } else {
        await _renameOrCopyFile(entity, targetFile);
      }
      continue;
    }
    if (entity is Directory) {
      final targetChild = Directory(p.join(target.path, name));
      await _moveOrMergeDirectory(source: entity, target: targetChild);
    }
  }

  await _deleteDirectoryIfEmpty(source);
}

Future<void> _renameOrCopyDirectory(Directory source, Directory target) async {
  await target.parent.create(recursive: true);
  try {
    await source.rename(target.path);
    return;
  } catch (_) {
    await target.create(recursive: true);
    final entities = await source.list(recursive: true).toList();
    for (final entity in entities) {
      if (entity is! File) {
        continue;
      }
      final relative = p.relative(entity.path, from: source.path);
      final targetFile = File(p.join(target.path, relative));
      await targetFile.parent.create(recursive: true);
      await entity.copy(targetFile.path);
    }
    await source.delete(recursive: true);
  }
}

Future<void> _renameOrCopyFile(File source, File target) async {
  await target.parent.create(recursive: true);
  try {
    await source.rename(target.path);
    return;
  } catch (_) {
    await source.copy(target.path);
    await source.delete();
  }
}

Future<void> _deleteDirectoryIfEmpty(Directory directory) async {
  if (!await directory.exists()) {
    return;
  }
  final remaining = await directory.list().toList();
  if (remaining.isEmpty) {
    await directory.delete();
  }
}

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

String _metadataAsStringFromItems(List<normal.ComicInfoMetadata> items) {
  return _metadataAsString(_metadataList(items));
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

String _metadataAsString(dynamic value) {
  final raw = _mapList(value);
  if (raw.isEmpty) {
    return '[]';
  }

  final normalized = <Map<String, dynamic>>[];
  for (final item in raw) {
    final values = _asDynamicList(item['value'])
        .map((entry) {
          final name = _asDynamicMap(entry)['name']?.toString().trim() ?? '';
          if (name.isEmpty) {
            return null;
          }
          return {'name': name};
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    if (values.isEmpty) {
      continue;
    }
    normalized.add({
      'type': item['type']?.toString() ?? '',
      'name': item['name']?.toString() ?? '',
      'value': values,
    });
  }

  return jsonEncode(normalized);
}

List<dynamic> _asDynamicList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

Map<String, dynamic> _asDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

Map<String, dynamic> _decodeJsonObject(String? raw) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) {
    return <String, dynamic>{};
  }
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {}
  return <String, dynamic>{};
}

String _safeTitle(String value) => value.trim().isEmpty ? '未知' : value;

int _toInt(Object? value, {int fallback = 0}) {
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<normal.ComicInfoActionItem> _actionItemsFromStrings(
  Iterable<dynamic> rawValues, {
  Map<String, dynamic> Function(String value)? onTapBuilder,
}) {
  final values = rawValues
      .map((e) => e?.toString().trim() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
  return values
      .map(
        (value) => normal.ComicInfoActionItem(
          name: value,
          onTap: onTapBuilder == null ? const {} : onTapBuilder(value),
        ),
      )
      .toList();
}

List<String> _toStringList(Object? value) {
  return (value as List? ?? const [])
      .map((e) => e?.toString().trim() ?? '')
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

String _sanitizeLegacyStoredPath(String rawPath, {bool allowEmpty = false}) {
  final candidate = rawPath.trim();
  if (candidate.isEmpty) {
    if (allowEmpty) {
      return '';
    }
    throw StateError('_sanitizeLegacyStoredPath requires non-empty path');
  }
  final sanitized = candidate.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
  if (sanitized.isNotEmpty) {
    return sanitized;
  }
  throw StateError('invalid legacy stored path: $rawPath');
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
    'payload': {'source': _kJmPluginUuid, 'keyword': keyword},
  };
}

Map<String, dynamic> _bikaSearchAction({required String keyword}) {
  return {
    'type': 'openSearch',
    'payload': {'source': _kBikaPluginUuid, 'keyword': keyword},
  };
}

Map<String, dynamic> _bikaCategoryAction(String category) {
  return {
    'type': 'openSearch',
    'payload': {
      'source': _kBikaPluginUuid,
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
      'source': _kBikaPluginUuid,
      'keyword': creatorName,
      'extern': {'mode': 'creator', 'creatorId': creatorId},
      'url': 'https://picaapi.picacomic.com/comics?ca=$creatorId&s=ld&page=1',
    },
  };
}
