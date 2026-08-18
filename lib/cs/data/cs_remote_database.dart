import 'dart:async';

import 'package:zephyr/cs/data/cs_api_client.dart';
import 'package:zephyr/cs/data/cs_server_download.dart';
import 'package:zephyr/cs/domain/cs_library_record.dart';
import 'package:zephyr/object_box/model.dart';

/// CS 模式下业务数据的进程内镜像。
///
/// ObjectBox 仍然保留给纯本地模式和“客户端下载”模式使用；CS 模式的
/// 文件夹、链接及追更数据先加载到这里，后续读写只更新这个镜像并异步写回
/// 服务端 SQLite。这样可以保留现有同步服务的同步 API，同时避免把远端数据
/// 误写入本地 ObjectBox。
class CsRemoteDatabase {
  CsRemoteDatabase(this.client);

  final CsApiClient client;

  bool _loaded = false;
  Future<void>? _loading;
  bool _drainingWrites = false;
  Timer? _retryTimer;
  final _pendingWrites = <String, _PendingRemoteWrite>{};

  final favorites = <String, UnifiedComicFavorite>{};
  final histories = <String, UnifiedComicHistory>{};
  final follows = <String, ComicFollow>{};
  final folders = <String, ComicFolder>{};
  final links = <String, ComicLink>{};
  final favoriteFolders = <String, FavoriteFolder>{};
  final favoriteFolderItems = <String, FavoriteFolderItem>{};
  final downloadFolders = <String, DownloadFolder>{};
  final downloadFolderItems = <String, DownloadFolderItem>{};
  final serverDownloads = <String, UnifiedComicDownload>{};
  bool _serverDownloadsLoaded = false;
  Future<void>? _serverDownloadsLoading;

  bool get isLoaded => _loaded;

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _pendingWrites.clear();
    serverDownloads.clear();
    _serverDownloadsLoaded = false;
    _serverDownloadsLoading = null;
  }

  Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      client.listLibrary('favorites', includeDeleted: true),
      client.listLibrary('history', includeDeleted: true),
      client.listLibrary('follows', includeDeleted: true),
      client.listLibrary('folders', includeDeleted: true),
      client.listLibrary('links', includeDeleted: true),
      client.listLibrary('favorite-folders', includeDeleted: true),
      client.listLibrary('favorite-folder-items', includeDeleted: true),
      client.listLibrary('download-folders', includeDeleted: true),
      client.listLibrary('download-folder-items', includeDeleted: true),
    ]);

    _putAll(favorites, results[0], UnifiedComicFavorite.fromJson);
    _putAll(histories, results[1], UnifiedComicHistory.fromJson);
    _putAll(follows, results[2], ComicFollow.fromJson);
    _putAll(
      folders,
      results[3],
      ComicFolder.fromJson,
      key: (value) => value.syncId,
    );
    _putAll(links, results[4], ComicLink.fromJson);
    _putAll(
      favoriteFolders,
      results[5],
      FavoriteFolder.fromJson,
      key: (value) => value.folderKey,
    );
    _putAll(favoriteFolderItems, results[6], FavoriteFolderItem.fromJson);
    _putAll(
      downloadFolders,
      results[7],
      DownloadFolder.fromJson,
      key: (value) => value.folderKey,
    );
    _putAll(downloadFolderItems, results[8], DownloadFolderItem.fromJson);
    _loaded = true;
  }

  /// 加载服务端下载 manifest，并转换成现有下载书架使用的模型。
  ///
  /// 服务端下载不写入本地 ObjectBox；这里的 map 只是一份当前进程镜像，
  /// 资源本身仍由服务端保存。显式 refresh 可以在下载任务完成后更新书架。
  Future<void> loadServerDownloads({bool force = false}) {
    if (_serverDownloadsLoaded && !force) return Future.value();
    return _serverDownloadsLoading ??= _loadServerDownloads(force: force);
  }

  Future<void> _loadServerDownloads({required bool force}) async {
    try {
      final tasks = await client.listServerDownloads();
      final candidates = <String, CsDownloadTask>{};
      for (final task in tasks) {
        if (task.status != 'completed') continue;
        final pluginId = task.payload['plugin_id']?.toString().trim() ?? '';
        final comicId = task.payload['comic_id']?.toString().trim() ?? '';
        if (pluginId.isEmpty || comicId.isEmpty) continue;
        final key = '$pluginId:$comicId';
        candidates[key] = task;
      }

      final resolved = await Future.wait(
        candidates.entries.map((entry) async {
          try {
            final response = await client.serverDownloadManifest(entry.key);
            final rawManifest = response['manifest'];
            if (rawManifest is! Map) return null;
            final manifest = Map<String, dynamic>.from(rawManifest);
            manifest['updated_at'] ??= entry.value.updatedAt;
            return CsServerDownloadManifest.fromJson(
              manifest,
            ).toUnifiedComicDownload();
          } catch (_) {
            // 任务列表可能短暂领先于 manifest 写入，下一次 refresh 再补齐。
            return null;
          }
        }),
      );

      serverDownloads
        ..clear()
        ..addEntries(
          resolved.whereType<UnifiedComicDownload>().map(
            (item) => MapEntry(item.uniqueKey, item),
          ),
        );
      _serverDownloadsLoaded = true;
    } finally {
      _serverDownloadsLoading = null;
    }
  }

  UnifiedComicDownload? findServerDownload(String uniqueKey) =>
      serverDownloads[uniqueKey];

  Future<UnifiedComicDownload?> findServerDownloadAsync(
    String pluginId,
    String comicId,
  ) async {
    await loadServerDownloads();
    return findServerDownload('${pluginId.trim()}:$comicId');
  }

  Future<void> removeServerDownload(String uniqueKey) async {
    await client.deleteServerDownload(uniqueKey);
    serverDownloads.remove(uniqueKey);
  }

  List<ComicFolder> listFolders(
    ComicFolderType type, {
    bool includeDeleted = false,
  }) {
    return folders.values
        .where(
          (item) =>
              item.typeData == type.name &&
              (includeDeleted || item.deletedAt == null),
        )
        .toList(growable: false);
  }

  ComicFolder? findFolderByUniqueKey(String uniqueKey) {
    for (final folder in folders.values) {
      if (folder.uniqueKey == uniqueKey) return folder;
    }
    return null;
  }

  ComicFolder? findFolderBySyncId(String syncId) => folders[syncId];

  void saveFolder(ComicFolder folder) {
    folders[folder.syncId] = folder;
    _save('folders', folder.syncId, folder.toJson());
  }

  List<ComicLink> listLinks(
    ComicFolderType type, {
    bool includeDeleted = false,
  }) {
    return links.values
        .where(
          (item) =>
              item.typeData == type.name &&
              (includeDeleted || item.deletedAt == null),
        )
        .toList(growable: false);
  }

  ComicLink? findLink(String uniqueKey) => links[uniqueKey];

  void saveLink(ComicLink link) {
    links[link.uniqueKey] = link;
    _save('links', link.uniqueKey, link.toJson());
  }

  void removeLink(ComicLink link) {
    link.deletedAt ??= DateTime.now().toUtc().millisecondsSinceEpoch;
    link.updatedAt = DateTime.now().toUtc().millisecondsSinceEpoch;
    saveLink(link);
  }

  List<ComicFollow> listFollows({bool includeDeleted = false}) {
    return follows.values
        .where((item) => includeDeleted || !item.deleted)
        .toList(growable: false);
  }

  ComicFollow? findFollow(String uniqueKey) => follows[uniqueKey];

  void saveFollow(ComicFollow follow) {
    follows[follow.uniqueKey] = follow;
    _save('follows', follow.uniqueKey, follow.toJson());
  }

  UnifiedComicFavorite? findFavorite(String uniqueKey) => favorites[uniqueKey];

  void saveFavorite(UnifiedComicFavorite favorite) {
    favorites[favorite.uniqueKey] = favorite;
    _save('favorites', favorite.uniqueKey, favorite.toJson());
  }

  UnifiedComicHistory? findHistory(String uniqueKey) => histories[uniqueKey];

  void saveHistory(UnifiedComicHistory history) {
    histories[history.uniqueKey] = history;
    _save('history', history.uniqueKey, history.toJson());
  }

  List<FavoriteFolder> listFavoriteFolders({bool includeDeleted = false}) {
    return favoriteFolders.values
        .where((item) => includeDeleted || !item.deleted)
        .toList(growable: false);
  }

  FavoriteFolder? findFavoriteFolder(String folderKey) =>
      favoriteFolders[folderKey];

  void saveFavoriteFolder(FavoriteFolder folder) {
    favoriteFolders[folder.folderKey] = folder;
    _save('favorite-folders', folder.folderKey, folder.toJson());
  }

  List<FavoriteFolderItem> listFavoriteFolderItems({
    bool includeDeleted = false,
  }) {
    return favoriteFolderItems.values
        .where((item) => includeDeleted || !item.deleted)
        .toList(growable: false);
  }

  FavoriteFolderItem? findFavoriteFolderItem(String uniqueKey) =>
      favoriteFolderItems[uniqueKey];

  void saveFavoriteFolderItem(FavoriteFolderItem item) {
    favoriteFolderItems[item.uniqueKey] = item;
    _save('favorite-folder-items', item.uniqueKey, item.toJson());
  }

  List<DownloadFolder> listDownloadFolders({bool includeDeleted = false}) {
    return downloadFolders.values
        .where((item) => includeDeleted || !item.deleted)
        .toList(growable: false);
  }

  DownloadFolder? findDownloadFolder(String folderKey) =>
      downloadFolders[folderKey];

  void saveDownloadFolder(DownloadFolder folder) {
    downloadFolders[folder.folderKey] = folder;
    _save('download-folders', folder.folderKey, folder.toJson());
  }

  List<DownloadFolderItem> listDownloadFolderItems({
    bool includeDeleted = false,
  }) {
    return downloadFolderItems.values
        .where((item) => includeDeleted || !item.deleted)
        .toList(growable: false);
  }

  DownloadFolderItem? findDownloadFolderItem(String uniqueKey) =>
      downloadFolderItems[uniqueKey];

  void saveDownloadFolderItem(DownloadFolderItem item) {
    downloadFolderItems[item.uniqueKey] = item;
    _save('download-folder-items', item.uniqueKey, item.toJson());
  }

  void _save(String kind, String uniqueKey, Map<String, dynamic> payload) {
    final pendingKey = '$kind\n$uniqueKey';
    _pendingWrites[pendingKey] = _PendingRemoteWrite(
      kind: kind,
      uniqueKey: uniqueKey,
      payload: Map<String, dynamic>.from(payload),
    );
    unawaited(_drainWrites());
  }

  Future<void> _drainWrites() async {
    if (_drainingWrites) return;
    _drainingWrites = true;
    try {
      while (_pendingWrites.isNotEmpty) {
        final entry = _pendingWrites.entries.first;
        final write = entry.value;
        try {
          await client.saveLibrary(
            write.kind,
            CsLibraryRecord(
              uniqueKey: write.uniqueKey,
              source: '',
              comicId: '',
              payload: write.payload,
              updatedAt: DateTime.now().toUtc().toIso8601String(),
            ),
          );
        } on Object {
          _retryTimer ??= Timer(const Duration(seconds: 5), () {
            _retryTimer = null;
            unawaited(_drainWrites());
          });
          return;
        }
        if (identical(_pendingWrites[entry.key], write)) {
          _pendingWrites.remove(entry.key);
        }
      }
    } finally {
      _drainingWrites = false;
    }
  }

  void _putAll<T>(
    Map<String, T> target,
    Object raw,
    T Function(Map<String, dynamic>) parse, {
    String Function(T value)? key,
  }) {
    if (raw is! List<CsLibraryRecord>) return;
    for (final record in raw) {
      try {
        final value = parse(record.payload);
        target[key?.call(value) ?? record.uniqueKey] = value;
      } on Object {
        // 单条脏数据不能阻塞其他业务数据加载。
      }
    }
  }
}

class _PendingRemoteWrite {
  const _PendingRemoteWrite({
    required this.kind,
    required this.uniqueKey,
    required this.payload,
  });

  final String kind;
  final String uniqueKey;
  final Map<String, dynamic> payload;
}
