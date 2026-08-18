import 'dart:io';
import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/config/bika/bika_setting.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/util/get_path.dart';

typedef CsMigrationAssetReader = Future<Uint8List> Function(String assetId);

/// 将服务端导出的迁移快照覆盖到本地 ObjectBox。
///
/// JSON 和所有下载文件都会先解析/下载到临时目录，之后才替换本地数据。
/// 下载目录替换失败或 ObjectBox 事务失败时，会尝试恢复旧下载目录。
class CsMigrationImporter {
  const CsMigrationImporter(this.objectbox);

  final ObjectBox objectbox;

  Future<void> importSnapshot(
    Map<String, dynamic> snapshot, {
    required bool includeDownloads,
    required CsMigrationAssetReader readAsset,
  }) async {
    if (snapshot['schema_version'] != 1) {
      throw const FormatException('不支持的 CS 迁移快照版本');
    }
    if (snapshot['include_downloads'] != includeDownloads) {
      throw const FormatException('CS 迁移快照的下载范围与当前操作不一致');
    }
    final data = _map(snapshot['data']) ?? snapshot;
    final localDownloadRoot = includeDownloads ? await getDownloadPath() : null;
    final parsed = _parseData(
      data,
      includeDownloads: includeDownloads,
      downloadRoot: localDownloadRoot,
    );
    final staging = Directory(
      p.join(
        await getCachePath(),
        'breeze_cs_migration',
        DateTime.now().microsecondsSinceEpoch.toString(),
      ),
    );
    await staging.create(recursive: true);

    final stagedAssets = <_StagedAsset>[];
    Directory? oldDownloadDirectory;
    try {
      for (var index = 0; index < parsed.assets.length; index++) {
        final asset = parsed.assets[index];
        final relativePath = _safeRelativePath(asset.relativePath);
        final bytes = await readAsset(asset.assetId);
        final stagedPath = p.join(staging.path, '$index.bin');
        await File(stagedPath).writeAsBytes(bytes, flush: true);
        stagedAssets.add(
          _StagedAsset(
            sourcePath: stagedPath,
            comicKey: asset.comicKey,
            relativePath: relativePath,
          ),
        );
      }

      if (includeDownloads) {
        try {
          final downloadRoot = Directory(await getDownloadPath());
          final backupPath = p.join(
            downloadRoot.parent.path,
            '.breeze_cs_previous_downloads_${DateTime.now().microsecondsSinceEpoch}',
          );
          if (await downloadRoot.exists()) {
            oldDownloadDirectory = await downloadRoot.rename(backupPath);
          }
          await downloadRoot.create(recursive: true);
          await _restoreAssets(
            root: downloadRoot,
            assets: stagedAssets,
            downloads: parsed.downloads,
          );
        } catch (_) {
          await _restorePreviousDownloadDirectory(
            Directory(await getDownloadPath()),
            oldDownloadDirectory,
          );
          oldDownloadDirectory = null;
          rethrow;
        }
      }

      try {
        objectbox.store.runInTransaction(TxMode.write, () {
          _clearBusinessData(includeDownloads: includeDownloads);
          _putAll(objectbox.unifiedFavoriteBox, parsed.favorites);
          _putAll(objectbox.unifiedHistoryBox, parsed.histories);
          _putAll(objectbox.comicFollowBox, parsed.follows);
          _putAll(objectbox.comicFolderBox, parsed.folders);
          _putAll(objectbox.comicLinkBox, parsed.links);
          _putAll(objectbox.favoriteFolderBox, parsed.favoriteFolders);
          _putAll(objectbox.favoriteFolderItemBox, parsed.favoriteFolderItems);
          _putAll(objectbox.pluginConfigBox, parsed.pluginConfigs);
          _putAll(objectbox.pluginInfoBox, parsed.plugins);
          if (includeDownloads) {
            _putAll(objectbox.unifiedDownloadBox, parsed.downloads);
            _putAll(objectbox.downloadTaskBox, parsed.downloadTasks);
            _putAll(objectbox.downloadFolderBox, parsed.downloadFolders);
            _putAll(
              objectbox.downloadFolderItemBox,
              parsed.downloadFolderItems,
            );
          }
          _putAccountSettings(parsed.accountSettings);
        });
      } catch (_) {
        if (includeDownloads) {
          await _restorePreviousDownloadDirectory(
            Directory(await getDownloadPath()),
            oldDownloadDirectory,
          );
          oldDownloadDirectory = null;
        }
        rethrow;
      }

      if (oldDownloadDirectory case final old?) {
        oldDownloadDirectory = null;
        try {
          await old.delete(recursive: true);
        } catch (_) {}
      }
    } finally {
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }

  _ParsedMigrationData _parseData(
    Map<String, dynamic> data, {
    required bool includeDownloads,
    required String? downloadRoot,
  }) {
    final account = _map(data['account_settings']) ?? const {};
    final parsed = _ParsedMigrationData(
      accountSettings: account,
      favorites: _parseList(data['favorites'], UnifiedComicFavorite.fromJson),
      histories: _parseList(data['histories'], UnifiedComicHistory.fromJson),
      follows: _parseList(data['follows'], ComicFollow.fromJson),
      folders: _parseList(data['folders'], ComicFolder.fromJson),
      links: _parseList(data['links'], ComicLink.fromJson),
      favoriteFolders: _parseList(
        data['favorite_folders'],
        FavoriteFolder.fromJson,
      ),
      favoriteFolderItems: _parseList(
        data['favorite_folder_items'],
        FavoriteFolderItem.fromJson,
      ),
      pluginConfigs: _parseList(data['plugin_configs'], PluginConfig.fromJson),
      plugins: _parsePlugins(data['plugins']),
      downloads: includeDownloads
          ? _parseDownloads(data['downloads'], downloadRoot: downloadRoot!)
          : const <UnifiedComicDownload>[],
      downloadTasks: includeDownloads
          ? _parseList(data['download_tasks'], DownloadTask.fromJson)
          : const <DownloadTask>[],
      downloadFolders: includeDownloads
          ? _parseList(data['download_folders'], DownloadFolder.fromJson)
          : const <DownloadFolder>[],
      downloadFolderItems: includeDownloads
          ? _parseList(
              data['download_folder_items'],
              DownloadFolderItem.fromJson,
            )
          : const <DownloadFolderItem>[],
    );
    final assets = includeDownloads
        ? _parseAssets(data['download_assets'])
        : const <_MigrationAsset>[];
    return parsed.copyWith(assets: assets);
  }

  List<UnifiedComicDownload> _parseDownloads(
    Object? raw, {
    required String downloadRoot,
  }) {
    final values = _maps(raw);
    return values
        .map((json) {
          final source = json['source']?.toString() ?? '';
          final comicId = json['comicId']?.toString() ?? '';
          if (source.isEmpty || comicId.isEmpty) {
            throw const FormatException('CS 下载记录缺少来源或漫画 ID');
          }
          final updated = Map<String, dynamic>.from(json)
            ..['id'] = 0
            ..['storageRoot'] = p.join(
              downloadRoot,
              _safeSegment(source),
              'original',
              encodePath(path: _safeSegment(comicId)),
            );
          return UnifiedComicDownload.fromJson(updated);
        })
        .toList(growable: false);
  }

  List<PluginInfo> _parsePlugins(Object? raw) {
    return _maps(raw)
        .map((json) {
          json['id'] = 0;
          json['insertedAt'] = _normalizeDate(json['insertedAt']);
          json['updatedAt'] = _normalizeDate(json['updatedAt']);
          return PluginInfo.fromJson(json);
        })
        .toList(growable: false);
  }

  String _normalizeDate(Object? value) {
    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return DateTime.now().toUtc().toIso8601String();
    final millis = int.tryParse(raw);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(
        millis,
        isUtc: true,
      ).toIso8601String();
    }
    return raw;
  }

  List<_MigrationAsset> _parseAssets(Object? raw) {
    return _maps(raw)
        .map((json) {
          final assetId = json['asset_id']?.toString().trim() ?? '';
          final comicKey = json['comic_key']?.toString().trim() ?? '';
          final path = json['relative_path']?.toString() ?? '';
          if (assetId.isEmpty || comicKey.isEmpty) {
            throw const FormatException('CS 下载资源缺少资源 ID 或漫画唯一键');
          }
          return _MigrationAsset(
            assetId: assetId,
            comicKey: comicKey,
            relativePath: _safeRelativePath(path),
            kind: json['kind']?.toString().trim() == 'cover' ? 'cover' : 'page',
            chapterId: json['chapter_id']?.toString().trim().isNotEmpty == true
                ? json['chapter_id']!.toString().trim()
                : null,
          );
        })
        .toList(growable: false);
  }

  void _clearBusinessData({required bool includeDownloads}) {
    objectbox.unifiedFavoriteBox.removeAll();
    objectbox.unifiedHistoryBox.removeAll();
    objectbox.comicFollowBox.removeAll();
    objectbox.comicFolderBox.removeAll();
    objectbox.comicLinkBox.removeAll();
    objectbox.favoriteFolderBox.removeAll();
    objectbox.favoriteFolderItemBox.removeAll();
    objectbox.pluginConfigBox.removeAll();
    objectbox.pluginInfoBox.removeAll();
    if (includeDownloads) {
      objectbox.unifiedDownloadBox.removeAll();
      objectbox.downloadTaskBox.removeAll();
      objectbox.downloadFolderBox.removeAll();
      objectbox.downloadFolderItemBox.removeAll();
    }
  }

  void _putAccountSettings(Map<String, dynamic> account) {
    final setting = objectbox.userSettingBox.get(1) ?? UserSetting(id: 1);
    final remoteGlobal = _map(account['global']);
    if (remoteGlobal != null && remoteGlobal.isNotEmpty) {
      final local = setting.globalSetting;
      final merged =
          GlobalSettingState.fromJson({
            ...local.toJson(),
            ...remoteGlobal,
          }).copyWith(
            syncSetting: local.syncSetting,
            customExportPath: local.customExportPath,
            appLockSetting: local.appLockSetting,
            cacheSetting: local.cacheSetting,
            enableMemoryDebug: local.enableMemoryDebug,
            logAddress: local.logAddress,
          );
      setting.globalSetting = merged;
    }
    final remoteBika = _map(account['bika']);
    if (remoteBika != null && remoteBika.isNotEmpty) {
      setting.bikaSetting = BikaSettingState.fromJson(remoteBika);
    }
    final remoteJm = _map(account['jm']);
    if (remoteJm != null && remoteJm.isNotEmpty) {
      setting.jmSetting = JmSettingState.fromJson(remoteJm);
    }
    objectbox.userSettingBox.put(setting);
  }

  Future<void> _restoreAssets({
    required Directory root,
    required List<_StagedAsset> assets,
    required List<UnifiedComicDownload> downloads,
  }) async {
    final downloadByKey = <String, UnifiedComicDownload>{
      for (final download in downloads) download.uniqueKey: download,
    };
    for (final asset in assets) {
      final download = downloadByKey[asset.comicKey];
      if (download == null) {
        throw StateError('下载资源对应的漫画不存在：${asset.comicKey}');
      }
      final targetRoot = p.join(
        root.path,
        _safeSegment(download.source),
        'original',
        encodePath(path: _safeSegment(download.comicId)),
      );
      final target = p.join(targetRoot, asset.relativePath);
      if (!_isInside(targetRoot, target)) {
        throw const FormatException('下载资源路径越界');
      }
      await File(target).parent.create(recursive: true);
      await File(asset.sourcePath).copy(target);
    }
  }

  Future<void> _restorePreviousDownloadDirectory(
    Directory current,
    Directory? previous,
  ) async {
    if (await current.exists()) await current.delete(recursive: true);
    if (previous != null && await previous.exists()) {
      await previous.rename(current.path);
    }
  }

  List<T> _parseList<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
    return _maps(raw)
        .map((json) {
          json['id'] = 0;
          return parse(json);
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _maps(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((value) => Map<String, dynamic>.from(value))
        .toList(growable: false);
  }

  Map<String, dynamic>? _map(Object? raw) {
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  String _safeSegment(String value) {
    final segment = value.trim();
    if (segment.isEmpty || segment == '.' || segment == '..') {
      throw const FormatException('下载路径片段为空或不合法');
    }
    if (p.isAbsolute(segment) ||
        segment.contains('/') ||
        segment.contains('\\') ||
        segment.contains(':')) {
      throw const FormatException('下载路径片段不能包含目录分隔符');
    }
    return segment;
  }

  String _safeRelativePath(String value) {
    final normalized = value.replaceAll('\\', '/');
    final segments = normalized.split('/');
    if (normalized.isEmpty ||
        normalized.startsWith('/') ||
        segments.any(
          (segment) => segment.isEmpty || segment == '.' || segment == '..',
        )) {
      throw const FormatException('下载资源相对路径不合法');
    }
    return normalized;
  }

  bool _isInside(String root, String target) {
    final relative = p.relative(target, from: root);
    return relative != '..' &&
        !relative.startsWith('..${p.separator}') &&
        !p.isAbsolute(relative);
  }
}

void _putAll<T>(Box<T> box, List<T> values) {
  if (values.isNotEmpty) box.putMany(values);
}

class _ParsedMigrationData {
  const _ParsedMigrationData({
    required this.accountSettings,
    required this.favorites,
    required this.histories,
    required this.follows,
    required this.folders,
    required this.links,
    required this.favoriteFolders,
    required this.favoriteFolderItems,
    required this.pluginConfigs,
    required this.plugins,
    required this.downloads,
    required this.downloadTasks,
    required this.downloadFolders,
    required this.downloadFolderItems,
    this.assets = const <_MigrationAsset>[],
  });

  final Map<String, dynamic> accountSettings;
  final List<UnifiedComicFavorite> favorites;
  final List<UnifiedComicHistory> histories;
  final List<ComicFollow> follows;
  final List<ComicFolder> folders;
  final List<ComicLink> links;
  final List<FavoriteFolder> favoriteFolders;
  final List<FavoriteFolderItem> favoriteFolderItems;
  final List<PluginConfig> pluginConfigs;
  final List<PluginInfo> plugins;
  final List<UnifiedComicDownload> downloads;
  final List<DownloadTask> downloadTasks;
  final List<DownloadFolder> downloadFolders;
  final List<DownloadFolderItem> downloadFolderItems;
  final List<_MigrationAsset> assets;

  _ParsedMigrationData copyWith({List<_MigrationAsset>? assets}) {
    return _ParsedMigrationData(
      accountSettings: accountSettings,
      favorites: favorites,
      histories: histories,
      follows: follows,
      folders: folders,
      links: links,
      favoriteFolders: favoriteFolders,
      favoriteFolderItems: favoriteFolderItems,
      pluginConfigs: pluginConfigs,
      plugins: plugins,
      downloads: downloads,
      downloadTasks: downloadTasks,
      downloadFolders: downloadFolders,
      downloadFolderItems: downloadFolderItems,
      assets: assets ?? this.assets,
    );
  }
}

class _MigrationAsset {
  const _MigrationAsset({
    required this.assetId,
    required this.comicKey,
    required this.relativePath,
    required this.kind,
    required this.chapterId,
  });

  final String assetId;
  final String comicKey;
  final String relativePath;
  final String kind;
  final String? chapterId;
}

class _StagedAsset {
  const _StagedAsset({
    required this.sourcePath,
    required this.comicKey,
    required this.relativePath,
  });

  final String sourcePath;
  final String comicKey;
  final String relativePath;
}
