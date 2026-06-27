import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/sync/sync_device_id.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/src/rust/api/simple.dart';

const String syncDataVersion = 'v1';

enum _VectorRelation { equal, leftDominates, rightDominates, conflict }

abstract class ComicSyncRemoteAdapter {
  Future<void> testConnection();

  Future<void> ensureRemoteReady();

  Future<String> downloadRemoteMd5();

  Future<void> uploadRemoteMd5(String value);

  Future<List<String>> listRemoteDataFiles();

  Future<List<int>> downloadRemoteFile(String remotePath);

  Future<void> uploadRemoteFile(
    String remotePath,
    List<int> data, {
    String contentType,
  });

  Future<void> deleteRemoteFiles(List<String> remotePaths);
}

class ComicSyncCore {
  static String get syncRemoteRootName => '${appName}_$syncVersion';

  static String get legacyDataRootName => appName;

  static String get legacySettingsRootName => '${appName}_setting';

  static String get comicMd5FileName => 'comic.md5';

  static String get settingsMd5FileName => 'settings.md5';

  static String buildComicDataFileName([int? timestamp]) {
    final ts = timestamp ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    return 'comic_$ts.bin';
  }

  static String buildSettingsDataFileName([int? timestamp]) {
    final ts = timestamp ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    return 'settings_$ts.bin';
  }

  static bool isComicDataFileName(String fileName) {
    return _comicDataRegex.hasMatch(fileName);
  }

  static bool isSettingsDataFileName(String fileName) {
    return _settingsDataRegex.hasMatch(fileName);
  }

  static int? extractComicTimestampFromRemotePath(String remotePath) {
    final fileName = extractFileName(remotePath);
    final match = _comicDataRegex.firstMatch(fileName);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
  }

  static int? extractSettingsTimestampFromRemotePath(String remotePath) {
    final fileName = extractFileName(remotePath);
    final match = _settingsDataRegex.firstMatch(fileName);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
  }

  static List<String> sortComicFilesByTimestampDesc(List<String> remotePaths) {
    final candidates = remotePaths.where((remotePath) {
      return isComicDataFileName(extractFileName(remotePath));
    }).toList();
    candidates.sort((a, b) {
      final aTs = extractComicTimestampFromRemotePath(a) ?? -1;
      final bTs = extractComicTimestampFromRemotePath(b) ?? -1;
      if (aTs == bTs) {
        return b.compareTo(a);
      }
      return bTs.compareTo(aTs);
    });
    return candidates;
  }

  static List<String> sortSettingsFilesByTimestampDesc(
    List<String> remotePaths,
  ) {
    final candidates = remotePaths.where((remotePath) {
      return isSettingsDataFileName(extractFileName(remotePath));
    }).toList();
    candidates.sort((a, b) {
      final aTs = extractSettingsTimestampFromRemotePath(a) ?? -1;
      final bTs = extractSettingsTimestampFromRemotePath(b) ?? -1;
      if (aTs == bTs) {
        return b.compareTo(a);
      }
      return bTs.compareTo(aTs);
    });
    return candidates;
  }

  static String calculateMd5(List<int> data) {
    return md5.convert(data).toString();
  }

  static Future<List<int>> buildCompressedPayload() async {
    final favorites = objectbox.unifiedFavoriteBox.getAll();
    favorites.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final histories = objectbox.unifiedHistoryBox.getAll();
    histories.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final folders = objectbox.comicFolderBox
        .getAll()
        .where(
          (f) =>
              f.type == ComicFolderType.favorite ||
              f.type == ComicFolderType.history,
        )
        .toList();
    final links = objectbox.comicLinkBox
        .getAll()
        .where(
          (l) =>
              l.type == ComicFolderType.favorite ||
              l.type == ComicFolderType.history,
        )
        .toList();

    final data = {
      'version': syncDataVersion,
      'favorites': favorites.map((e) => _stripLocalId(e.toJson())).toList(),
      'histories': histories.map((e) => _stripLocalId(e.toJson())).toList(),
      'folders': folders.map((e) => _stripLocalId(e.toJson())).toList(),
      'links': links.map((e) => _stripLocalId(e.toJson())).toList(),
    };

    final raw = utf8.encode(jsonEncode(data));
    return encodeEncryptedPayload(raw);
  }

  static Future<Map<String, dynamic>> decodeCompressedPayload(
    List<int> encryptedCompressedBytes,
  ) async {
    final raw = await decodeEncryptedPayload(encryptedCompressedBytes);
    final jsonString = utf8.decode(raw);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  static Future<List<int>> encodeEncryptedPayload(List<int> raw) async {
    final compressed = await compressExtreme(data: raw);
    final encrypted = _encryptBytes(compressed);
    return encrypted;
  }

  static Future<List<int>> decodeEncryptedPayload(
    List<int> encryptedCompressedBytes,
  ) async {
    final compressed = _decryptBytes(encryptedCompressedBytes);
    final raw = await decompressExtreme(data: compressed);
    return raw;
  }

  static int mergeUnifiedDataInIsolate(Store store, Map<String, dynamic> arg) {
    syncDeviceId = arg['_deviceId'] as String;
    return mergeUnifiedData(store, arg['_data'] as Map<String, dynamic>);
  }

  static int mergeUnifiedData(Store store, Map<String, dynamic> data) {
    final favoriteBox = store.box<UnifiedComicFavorite>();
    final historyBox = store.box<UnifiedComicHistory>();
    final folderBox = store.box<ComicFolder>();
    final linkBox = store.box<ComicLink>();

    final localFavorites = favoriteBox.getAll();
    final localHistories = historyBox.getAll();
    var localFolders = folderBox.getAll();
    var localLinks = linkBox.getAll();

    final cloudFavorites = _parseJsonList(
      data['favorites'],
    ).map(UnifiedComicFavorite.fromJson).toList();
    final cloudHistories = _parseJsonList(
      data['histories'],
    ).map(UnifiedComicHistory.fromJson).toList();
    var cloudFolders = _parseJsonList(
      data['folders'],
    ).map(ComicFolder.fromJson).toList();
    var cloudLinks = _parseJsonList(
      data['links'],
    ).map(ComicLink.fromJson).toList();

    // 旧数据可能没有 syncId，先兜底补一遍，确保后续按 syncId 合并能正常进行。
    for (final folder in [...localFolders, ...cloudFolders]) {
      if (folder.syncId.isEmpty) {
        folder.syncId = const Uuid().v4();
      }
    }

    final mergedFavorites = _mergeByUniqueKey(
      localFavorites,
      cloudFavorites,
      keyOf: (item) => item.uniqueKey,
      updatedAtOf: (item) => item.updatedAt,
    );
    final mergedHistories = _mergeByUniqueKey(
      localHistories,
      cloudHistories,
      keyOf: (item) => item.uniqueKey,
      updatedAtOf: (item) => item.updatedAt,
    );
    var mergedFolders = _mergeByVersionVector<ComicFolder>(
      localFolders,
      cloudFolders,
      keyOf: (item) => item.syncId,
      vectorJsonOf: (item) => item.versionVectorJson,
      updatedAtMsOf: (item) => item.updatedAt,
      deterministicTieBreakerOf: (item) =>
          jsonEncode(_stripLocalId(item.toJson())),
      updateOf: (item, vector, updatedAt) {
        item.versionVectorJson = vector;
        item.updatedAt = updatedAt;
      },
    );

    // 先把 folder 的 uniqueKey 索引建起来，给 link 补 folderSyncId 用。
    var folderByUniqueKey = <String, ComicFolder>{
      for (final folder in mergedFolders) folder.uniqueKey: folder,
    };

    // 补齐旧版 folder 的 parentSyncId（旧版 uniqueKey 为 path|type）。
    for (final folder in mergedFolders) {
      _ensureFolderParentSyncId(folder, folder.typeData, folderByUniqueKey);
    }
    // parentSyncId 可能已更新，重建索引。
    folderByUniqueKey = {
      for (final folder in mergedFolders) folder.uniqueKey: folder,
    };

    for (final link in [...localLinks, ...cloudLinks]) {
      _ensureLinkFolderSyncId(link, folderByUniqueKey);
    }

    var mergedLinks = _mergeByVersionVector<ComicLink>(
      localLinks,
      cloudLinks,
      keyOf: (item) =>
          '${item.comicUniqueKey}|${item.folderSyncId ?? ''}|${item.typeData}',
      vectorJsonOf: (item) => item.versionVectorJson,
      updatedAtMsOf: (item) => item.updatedAt,
      deterministicTieBreakerOf: (item) =>
          jsonEncode(_stripLocalId(item.toJson())),
      updateOf: (item, vector, updatedAt) {
        item.versionVectorJson = vector;
        item.updatedAt = updatedAt;
      },
    );

    // 将旧版 path|type 格式的 folder uniqueKey 规范化为
    // parentSyncId|name|type，保证后续本地查询/冲突处理一致。
    _normalizeFolderUniqueKeys(mergedFolders);

    // 处理相同 uniqueKey 但不同 syncId 的文件夹冲突：选一个 winner，
    // 内容合并进去，输家从列表中移除。
    _resolveFolderUniqueKeyConflicts(mergedFolders, mergedLinks);

    // 先修复链接指向：可能复活被 tombstone 的父文件夹，或补全旧版路径链。
    _repairOrphanLinks(mergedFolders, mergedLinks);

    // 再处理仍孤儿的 active folder：把 parent 已删除/不存在的子树 tombstone，
    // 同时清理指向这些文件夹的 active link。
    _repairOrphanFolders(mergedFolders, mergedLinks);

    // 兜底：从旧版本同步过来的记录可能没有 syncId，在这里补齐。
    for (final folder in mergedFolders) {
      if (folder.syncId.isEmpty) {
        folder.syncId = const Uuid().v4();
      }
    }

    for (final item in mergedFavorites) {
      item.id = 0;
    }
    for (final item in mergedHistories) {
      item.id = 0;
    }
    for (final item in mergedFolders) {
      item.id = 0;
    }
    for (final item in mergedLinks) {
      item.id = 0;
    }

    favoriteBox.removeAll();
    historyBox.removeAll();
    folderBox.removeAll();
    linkBox.removeAll();

    if (mergedFavorites.isNotEmpty) {
      favoriteBox.putMany(mergedFavorites);
    }
    if (mergedHistories.isNotEmpty) {
      historyBox.putMany(mergedHistories);
    }
    if (mergedFolders.isNotEmpty) {
      folderBox.putMany(mergedFolders);
    }
    if (mergedLinks.isNotEmpty) {
      linkBox.putMany(mergedLinks);
    }

    return mergedFavorites.length +
        mergedHistories.length +
        mergedFolders.length +
        mergedLinks.length;
  }

  static String extractFileName(String remotePath) {
    final normalized = remotePath.replaceAll('\\', '/');
    final segments = normalized.split('/').where((item) => item.isNotEmpty);
    if (segments.isEmpty) {
      return '';
    }
    return segments.last;
  }

  static String normalizeRemotePathNoLeadingSlash(String path) {
    final normalized = path.replaceAll('\\', '/').trim();
    return normalized.replaceFirst(RegExp(r'^/+'), '');
  }

  static bool isLegacyRemotePath(String path) {
    final normalized = normalizeRemotePathNoLeadingSlash(path);
    return normalized == legacyDataRootName ||
        normalized.startsWith('$legacyDataRootName/') ||
        normalized == legacySettingsRootName ||
        normalized.startsWith('$legacySettingsRootName/');
  }

  static bool isSyncRootPath(String path) {
    final normalized = normalizeRemotePathNoLeadingSlash(path);
    return normalized == syncRemoteRootName ||
        normalized.startsWith('$syncRemoteRootName/');
  }

  static List<Map<String, dynamic>> _parseJsonList(Object? value) {
    final list = (value as List? ?? const []);
    return list
        .map((item) {
          if (item is Map<String, dynamic>) {
            return Map<String, dynamic>.from(item);
          }
          if (item is Map) {
            return item.map((key, val) => MapEntry(key.toString(), val));
          }
          return <String, dynamic>{};
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<T> _mergeByUniqueKey<T>(
    List<T> local,
    List<T> cloud, {
    required String Function(T item) keyOf,
    required DateTime Function(T item) updatedAtOf,
  }) {
    final merged = <String, T>{for (final item in local) keyOf(item): item};
    for (final cloudItem in cloud) {
      final key = keyOf(cloudItem);
      final localItem = merged[key];
      if (localItem == null ||
          updatedAtOf(cloudItem).isAfter(updatedAtOf(localItem))) {
        merged[key] = cloudItem;
      }
    }
    return merged.values.toList();
  }

  // ==================== 版本向量合并（ComicFolder / ComicLink） ====================

  static List<T> _mergeByVersionVector<T extends Object>(
    List<T> local,
    List<T> cloud, {
    required String Function(T item) keyOf,
    required String Function(T item) vectorJsonOf,
    required int Function(T item) updatedAtMsOf,
    required String Function(T item) deterministicTieBreakerOf,
    required void Function(T item, String newVectorJson, int newUpdatedAtMs)
    updateOf,
  }) {
    final localMap = {for (final item in local) keyOf(item): item};
    final cloudMap = {for (final item in cloud) keyOf(item): item};
    final merged = <T>[];
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    for (final key in {...localMap.keys, ...cloudMap.keys}) {
      final localItem = localMap[key];
      final cloudItem = cloudMap[key];
      if (localItem == null) {
        merged.add(cloudItem!);
        continue;
      }
      if (cloudItem == null) {
        merged.add(localItem);
        continue;
      }

      final localVector = _parseVersionVector(vectorJsonOf(localItem));
      final cloudVector = _parseVersionVector(vectorJsonOf(cloudItem));
      final relation = _compareVersionVectors(localVector, cloudVector);

      switch (relation) {
        case _VectorRelation.equal:
          // 向量相等但内容可能不同（例如旧数据默认向量、并发巧合）。
          // 用 updatedAt + 确定性内容 tie-breaker 选出唯一 winner，
          // 并提升版本向量，确保两端收敛到同一结果。
          final localUpdatedAt = updatedAtMsOf(localItem);
          final cloudUpdatedAt = updatedAtMsOf(cloudItem);
          if (localUpdatedAt == cloudUpdatedAt &&
              deterministicTieBreakerOf(localItem) ==
                  deterministicTieBreakerOf(cloudItem)) {
            // 内容和 updatedAt 都完全相同：真正的 identical，无需 bump。
            merged.add(localItem);
            break;
          }
          final winner = _resolveEqualVectorConflict(
            localItem,
            cloudItem,
            updatedAtMsOf: updatedAtMsOf,
            deterministicTieBreakerOf: deterministicTieBreakerOf,
          );
          final loser = identical(winner, localItem) ? cloudItem : localItem;
          final winnerVector = _parseVersionVector(vectorJsonOf(winner));
          final loserVector = _parseVersionVector(vectorJsonOf(loser));
          final mergedVector = _mergeVectors(winnerVector, loserVector);
          final bumpedVector = _bumpVector(mergedVector);
          updateOf(winner, _encodeVersionVector(bumpedVector), now);
          merged.add(winner);
        case _VectorRelation.leftDominates:
          merged.add(localItem);
        case _VectorRelation.rightDominates:
          merged.add(cloudItem);
        case _VectorRelation.conflict:
          final localUpdatedAt = updatedAtMsOf(localItem);
          final cloudUpdatedAt = updatedAtMsOf(cloudItem);
          final T winner;
          if (localUpdatedAt == cloudUpdatedAt) {
            final localTie = deterministicTieBreakerOf(localItem);
            final cloudTie = deterministicTieBreakerOf(cloudItem);
            winner = localTie.compareTo(cloudTie) >= 0 ? localItem : cloudItem;
          } else {
            winner = localUpdatedAt > cloudUpdatedAt ? localItem : cloudItem;
          }
          final loser = identical(winner, localItem) ? cloudItem : localItem;
          final winnerVector = _parseVersionVector(vectorJsonOf(winner));
          final loserVector = _parseVersionVector(vectorJsonOf(loser));
          final mergedVector = _mergeVectors(winnerVector, loserVector);
          final bumpedVector = _bumpVector(mergedVector);
          updateOf(winner, _encodeVersionVector(bumpedVector), now);
          merged.add(winner);
      }
    }
    return merged;
  }

  static T _resolveEqualVectorConflict<T>(
    T localItem,
    T cloudItem, {
    required int Function(T item) updatedAtMsOf,
    required String Function(T item) deterministicTieBreakerOf,
  }) {
    final localUpdatedAt = updatedAtMsOf(localItem);
    final cloudUpdatedAt = updatedAtMsOf(cloudItem);
    if (localUpdatedAt != cloudUpdatedAt) {
      return localUpdatedAt > cloudUpdatedAt ? localItem : cloudItem;
    }
    // updatedAt 也相同：用内容的确定性序作为最终 tie-breaker。
    final localTie = deterministicTieBreakerOf(localItem);
    final cloudTie = deterministicTieBreakerOf(cloudItem);
    return localTie.compareTo(cloudTie) >= 0 ? localItem : cloudItem;
  }

  static Map<String, int> _parseVersionVector(String json) {
    if (json.trim().isEmpty) return <String, int>{};
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return <String, int>{};
    }
  }

  static String _encodeVersionVector(Map<String, int> vector) {
    return jsonEncode(vector);
  }

  static _VectorRelation _compareVersionVectors(
    Map<String, int> a,
    Map<String, int> b,
  ) {
    final keys = {...a.keys, ...b.keys};
    var leftGreater = false;
    var rightGreater = false;
    for (final key in keys) {
      final av = a[key] ?? 0;
      final bv = b[key] ?? 0;
      if (av > bv) leftGreater = true;
      if (bv > av) rightGreater = true;
    }
    if (!leftGreater && !rightGreater) return _VectorRelation.equal;
    if (leftGreater && !rightGreater) return _VectorRelation.leftDominates;
    if (rightGreater && !leftGreater) return _VectorRelation.rightDominates;
    return _VectorRelation.conflict;
  }

  static Map<String, int> _mergeVectors(
    Map<String, int> a,
    Map<String, int> b,
  ) {
    final keys = {...a.keys, ...b.keys};
    return {for (final key in keys) key: max(a[key] ?? 0, b[key] ?? 0)};
  }

  static Map<String, int> _bumpVector(Map<String, int> vector) {
    final copy = Map<String, int>.from(vector);
    copy[syncDeviceId] = (copy[syncDeviceId] ?? 0) + 1;
    return copy;
  }

  static String _parentFolderPath(String path) {
    final trimmed = path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;
    final index = trimmed.lastIndexOf('/');
    if (index <= 0) return '';
    return trimmed.substring(0, index);
  }

  static String _linkUniqueKey(
    String comicUniqueKey,
    String? folderSyncId,
    String typeData,
  ) {
    return '$comicUniqueKey|${folderSyncId ?? ''}|$typeData';
  }

  /// 从旧版 folder uniqueKey（path|type）中解析 path。
  static String? _folderPathFromUniqueKey(String uniqueKey, String typeData) {
    final suffix = '|$typeData';
    if (!uniqueKey.endsWith(suffix)) return null;
    return uniqueKey.substring(0, uniqueKey.length - suffix.length);
  }

  /// 从旧版 link uniqueKey（comic|folderPath|type）中解析 folderPath。
  /// 若无法解析或不是旧格式，返回 null。
  static String? _folderPathFromLinkUniqueKey(String uniqueKey) {
    final lastPipe = uniqueKey.lastIndexOf('|');
    if (lastPipe <= 0) return null;
    final secondLastPipe = uniqueKey.lastIndexOf('|', lastPipe - 1);
    if (secondLastPipe < 0) return null;
    final folderPath = uniqueKey.substring(secondLastPipe + 1, lastPipe);
    // 旧格式 folderPath 以 '/' 开头；新格式为 syncId（UUID），不用于路径。
    return folderPath.startsWith('/') ? folderPath : null;
  }

  /// 收集 [rootSyncId] 下所有后代文件夹的 syncId（包含自身）。
  static Set<String> _collectSubtreeSyncIds(
    String rootSyncId,
    List<ComicFolder> folders,
    String typeData,
  ) {
    final childrenByParent = <String, List<ComicFolder>>{};
    for (final folder in folders) {
      if (folder.typeData != typeData) continue;
      childrenByParent
          .putIfAbsent(folder.parentSyncId ?? '', () => [])
          .add(folder);
    }
    final result = <String>{rootSyncId};
    final queue = [rootSyncId];
    while (queue.isNotEmpty) {
      final parentId = queue.removeLast();
      for (final child in childrenByParent[parentId] ?? const []) {
        if (result.add(child.syncId)) queue.add(child.syncId);
      }
    }
    return result;
  }

  /// 将 folder uniqueKey 规范化为 parentSyncId|name|type。
  static void _normalizeFolderUniqueKeys(List<ComicFolder> folders) {
    for (final folder in folders) {
      folder.uniqueKey =
          '${folder.parentSyncId ?? ''}|${folder.name}|${folder.typeData}';
    }
  }

  static void _ensureFolderParentSyncId(
    ComicFolder folder,
    String typeData,
    Map<String, ComicFolder> folderByUniqueKey,
  ) {
    if (folder.parentSyncId != null && folder.parentSyncId!.isNotEmpty) return;
    // 旧版数据 uniqueKey 为 path|type，可从中反推出 parentSyncId。
    if (!folder.uniqueKey.startsWith('/')) return;
    final path = _folderPathFromUniqueKey(folder.uniqueKey, typeData);
    if (path == null || path.isEmpty) return;
    final parentPath = _parentFolderPath(path);
    if (parentPath.isEmpty) return;
    final parent = folderByUniqueKey['$parentPath|$typeData'];
    if (parent != null && parent.deletedAt == null) {
      folder.parentSyncId = parent.syncId;
    }
  }

  static void _ensureLinkFolderSyncId(
    ComicLink link,
    Map<String, ComicFolder> folderByUniqueKey,
  ) {
    if (link.folderSyncId != null && link.folderSyncId!.isNotEmpty) return;
    final folderPath = _folderPathFromLinkUniqueKey(link.uniqueKey);
    if (folderPath == null || folderPath.isEmpty) return;
    final folder = folderByUniqueKey['$folderPath|${link.typeData}'];
    if (folder != null) {
      link.folderSyncId = folder.syncId;
    }
  }

  /// 处理同一个 parentSyncId|name|type（或旧版 path|type）下存在多个 syncId
  /// 的文件夹冲突。
  ///
  /// 对每一组 uniqueKey 相同的文件夹（无论 active 还是 tombstone），
  /// 按版本向量 / LWW 选一个 winner：
  /// - winner 是 active：把输家的直接链接迁到 winner，输家从列表中移除。
  /// - winner 是 tombstone：把输家（及其子树）tombstone，并清理对应链接。
  static void _resolveFolderUniqueKeyConflicts(
    List<ComicFolder> folders,
    List<ComicLink> links,
  ) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final keyMap = <String, List<ComicFolder>>{};
    for (final folder in folders) {
      keyMap.putIfAbsent(folder.uniqueKey, () => []).add(folder);
    }

    final conflicts = keyMap.values.where((group) => group.length > 1).toList();

    for (final group in conflicts) {
      if (group.length < 2) continue;

      var winner = group.first;
      for (final candidate in group.skip(1)) {
        winner = _resolveFolderConflict(winner, candidate);
      }

      if (winner.deletedAt != null) {
        // winner 是 tombstone：整棵子树都应该被清理。
        _tombstoneFolderSubtree(winner, folders, links, now);
      }

      for (final loser in group) {
        if (identical(loser, winner)) continue;
        if (winner.deletedAt != null) {
          _tombstoneFolderSubtree(loser, folders, links, now);
        } else {
          _mergeFolderLinks(loser, winner, folders, links, now);
        }
        folders.remove(loser);
      }
    }
  }

  static ComicFolder _resolveFolderConflict(ComicFolder a, ComicFolder b) {
    final aVector = _parseVersionVector(a.versionVectorJson);
    final bVector = _parseVersionVector(b.versionVectorJson);
    final relation = _compareVersionVectors(aVector, bVector);
    return switch (relation) {
      _VectorRelation.leftDominates => a,
      _VectorRelation.rightDominates => b,
      _VectorRelation.equal ||
      _VectorRelation.conflict => _resolveEqualVectorConflict(
        a,
        b,
        updatedAtMsOf: (folder) => folder.updatedAt,
        deterministicTieBreakerOf: (folder) => folder.syncId,
      ),
    };
  }

  /// 把 [loser] 文件夹下的直接子文件夹和链接合并到 [winner]，并提升 winner 的版本向量。
  static void _mergeFolderLinks(
    ComicFolder loser,
    ComicFolder winner,
    List<ComicFolder> folders,
    List<ComicLink> links,
    int now,
  ) {
    winner
      ..versionVectorJson = _encodeVersionVector(
        _bumpVector(
          _mergeVectors(
            _parseVersionVector(winner.versionVectorJson),
            _parseVersionVector(loser.versionVectorJson),
          ),
        ),
      )
      ..updatedAt = now;

    // 把 loser 的直接子文件夹挂到 winner 下。
    for (final child in folders) {
      if (child.deletedAt != null) continue;
      if (child.typeData != loser.typeData) continue;
      if (child.parentSyncId != loser.syncId) continue;
      child
        ..parentSyncId = winner.syncId
        ..updatedAt = now;
    }

    for (var i = links.length - 1; i >= 0; i--) {
      final link = links[i];
      if (link.deletedAt != null) continue;
      if (link.folderSyncId != loser.syncId) continue;

      final existingWinnerLink = links.firstWhereOrNull(
        (l) =>
            l.deletedAt == null &&
            l.folderSyncId == winner.syncId &&
            l.comicUniqueKey == link.comicUniqueKey &&
            l.typeData == link.typeData,
      );
      if (existingWinnerLink != null) {
        final kept = _resolveLinkConflict(existingWinnerLink, link, now);
        final removed = identical(kept, existingWinnerLink)
            ? link
            : existingWinnerLink;
        links.remove(removed);
        // 保留的 link 必须指向 winner 文件夹。
        if (kept.folderSyncId != winner.syncId) {
          kept
            ..folderSyncId = winner.syncId
            ..uniqueKey =
                '${kept.comicUniqueKey}|${winner.syncId}|${kept.typeData}';
        }
      } else {
        link
          ..folderSyncId = winner.syncId
          ..uniqueKey =
              '${link.comicUniqueKey}|${winner.syncId}|${link.typeData}'
          ..versionVectorJson = _encodeVersionVector(
            _bumpVector(_parseVersionVector(link.versionVectorJson)),
          )
          ..updatedAt = now;
      }
    }
  }

  /// 比较两个指向同一文件夹的 link，返回应该保留的那个，并提升其版本向量。
  /// 另一个 link 会被调用方从列表中移除，因此这里不设置 deletedAt。
  ///
  /// 向量相等或冲突且 updatedAt 相同时，使用内容 JSON 的确定性序作为
  /// tie-breaker，保证不同客户端对同一对记录能选出同一个 winner。
  static ComicLink _resolveLinkConflict(ComicLink a, ComicLink b, int now) {
    final aVector = _parseVersionVector(a.versionVectorJson);
    final bVector = _parseVersionVector(b.versionVectorJson);
    final relation = _compareVersionVectors(aVector, bVector);

    final ComicLink winner;
    final ComicLink loser;
    switch (relation) {
      case _VectorRelation.leftDominates:
        winner = a;
        loser = b;
      case _VectorRelation.rightDominates:
        winner = b;
        loser = a;
      case _VectorRelation.equal:
      case _VectorRelation.conflict:
        winner = _resolveEqualVectorConflict(
          a,
          b,
          updatedAtMsOf: (link) => link.updatedAt,
          deterministicTieBreakerOf: (link) =>
              jsonEncode(_stripLocalId(link.toJson())),
        );
        loser = identical(winner, a) ? b : a;
    }

    final mergedVector = _mergeVectors(
      _parseVersionVector(winner.versionVectorJson),
      _parseVersionVector(loser.versionVectorJson),
    );
    winner
      ..versionVectorJson = _encodeVersionVector(_bumpVector(mergedVector))
      ..updatedAt = now;
    return winner;
  }

  /// 把 [root] 文件夹及其子树全部 tombstone，并清理指向它们的 active link。
  static void _tombstoneFolderSubtree(
    ComicFolder root,
    List<ComicFolder> folders,
    List<ComicLink> links,
    int now,
  ) {
    final type = root.typeData;
    final subtreeSyncIds = _collectSubtreeSyncIds(root.syncId, folders, type);

    for (final folder in folders) {
      if (folder.typeData != type) continue;
      if (folder.deletedAt != null) continue;
      if (!subtreeSyncIds.contains(folder.syncId)) continue;
      folder
        ..deletedAt = now
        ..updatedAt = now
        ..versionVectorJson = _encodeVersionVector(
          _bumpVector(_parseVersionVector(folder.versionVectorJson)),
        );
    }

    for (final link in links) {
      if (link.deletedAt != null) continue;
      if (link.typeData != type) continue;
      if (link.folderSyncId != null &&
          subtreeSyncIds.contains(link.folderSyncId)) {
        link
          ..deletedAt = now
          ..updatedAt = now
          ..versionVectorJson = _encodeVersionVector(
            _bumpVector(_parseVersionVector(link.versionVectorJson)),
          );
      }
    }
  }

  /// 修复 active Folder 的 parentSyncId 指向已删除/不存在文件夹的孤儿问题。
  ///
  /// 父文件夹已不存在时，该子文件夹在 UI 上已不可达，直接 tombstone，并清理
  /// 指向这些文件夹的 active link。
  /// 递归处理，直到没有新的孤儿 folder 产生。
  static void _repairOrphanFolders(
    List<ComicFolder> folders,
    List<ComicLink> links,
  ) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final activeBySyncId = <String, ComicFolder>{};
    for (final folder in folders) {
      if (folder.syncId.isNotEmpty && folder.deletedAt == null) {
        activeBySyncId[folder.syncId] = folder;
      }
    }

    final newlyTombstoned = <String>{};
    while (true) {
      var changed = false;
      for (final folder in folders) {
        if (folder.deletedAt != null) continue;
        final parentId = folder.parentSyncId;
        if (parentId == null || parentId.isEmpty) continue;
        final parent = activeBySyncId[parentId];
        if (parent == null) {
          folder
            ..deletedAt = now
            ..updatedAt = now
            ..versionVectorJson = _encodeVersionVector(
              _bumpVector(_parseVersionVector(folder.versionVectorJson)),
            );
          activeBySyncId.remove(folder.syncId);
          newlyTombstoned.add(folder.syncId);
          changed = true;
        }
      }
      if (!changed) break;
    }

    // 同步清理指向刚被 tombstone 的文件夹的 active link。
    if (newlyTombstoned.isNotEmpty) {
      for (final link in links) {
        if (link.deletedAt != null) continue;
        final folderSyncId = link.folderSyncId;
        if (folderSyncId != null &&
            folderSyncId.isNotEmpty &&
            newlyTombstoned.contains(folderSyncId)) {
          link
            ..deletedAt = now
            ..updatedAt = now
            ..versionVectorJson = _encodeVersionVector(
              _bumpVector(_parseVersionVector(link.versionVectorJson)),
            );
        }
      }
    }
  }

  /// 修复 active Link 指向已删除/不存在文件夹的孤儿问题。
  ///
  /// 先按 folderSyncId 处理，再按路径补全祖先文件夹，最后补齐 link 的指向。
  static void _repairOrphanLinks(
    List<ComicFolder> folders,
    List<ComicLink> links,
  ) {
    final folderBySyncId = <String, ComicFolder>{};
    final childrenByParentSyncId = <String, List<ComicFolder>>{};
    for (final folder in folders) {
      if (folder.syncId.isNotEmpty) folderBySyncId[folder.syncId] = folder;
      childrenByParentSyncId
          .putIfAbsent(folder.parentSyncId ?? '', () => [])
          .add(folder);
    }
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;

    for (final link in links) {
      if (link.deletedAt != null) continue;

      // 1) 如果 link 有 folderSyncId，先按 syncId 处理 tombstone 冲突。
      final folderSyncId = link.folderSyncId;
      if (folderSyncId != null && folderSyncId.isNotEmpty) {
        final folder = folderBySyncId[folderSyncId];
        if (folder != null) {
          if (folder.deletedAt != null) {
            final linkVector = _parseVersionVector(link.versionVectorJson);
            final folderVector = _parseVersionVector(folder.versionVectorJson);
            final relation = _compareVersionVectors(linkVector, folderVector);
            final shouldResurrect = switch (relation) {
              _VectorRelation.leftDominates => true,
              _VectorRelation.conflict => link.updatedAt >= folder.updatedAt,
              _VectorRelation.equal => link.updatedAt >= folder.updatedAt,
              _VectorRelation.rightDominates => false,
            };
            if (shouldResurrect) {
              folder
                ..deletedAt = null
                ..versionVectorJson = _encodeVersionVector(
                  _bumpVector(_mergeVectors(linkVector, folderVector)),
                )
                ..updatedAt = now;
            } else {
              link
                ..deletedAt = now
                ..versionVectorJson = _encodeVersionVector(
                  _bumpVector(_mergeVectors(linkVector, folderVector)),
                )
                ..updatedAt = now;
              continue;
            }
          }
          link.uniqueKey = _linkUniqueKey(
            link.comicUniqueKey,
            folder.syncId,
            link.typeData,
          );
          continue;
        }
      }

      // 2) 从旧版 uniqueKey 中解析目标路径，并按路径补全祖先文件夹。
      final targetPath = _folderPathFromLinkUniqueKey(link.uniqueKey);
      if (targetPath == null || targetPath.isEmpty) {
        link
          ..folderSyncId = null
          ..uniqueKey = _linkUniqueKey(
            link.comicUniqueKey,
            null,
            link.typeData,
          );
        continue;
      }

      final segments = targetPath
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .toList();
      String? currentParentSyncId;
      ComicFolder? deepestFolder;

      for (final segment in segments) {
        final siblings =
            childrenByParentSyncId[currentParentSyncId ?? ''] ?? const [];
        var folder = siblings.firstWhereOrNull(
          (f) => f.name == segment && f.typeData == link.typeData,
        );

        if (folder == null) {
          final linkVector = _parseVersionVector(link.versionVectorJson);
          final newSyncId = const Uuid().v4();
          folder = ComicFolder(
            syncId: newSyncId,
            parentSyncId: currentParentSyncId,
            uniqueKey: '${currentParentSyncId ?? ''}|$segment|${link.typeData}',
            name: segment,
            typeData: link.typeData,
            versionVectorJson: _encodeVersionVector(_bumpVector(linkVector)),
            createdAt: now,
            updatedAt: now,
          );
          folders.add(folder);
          folderBySyncId[newSyncId] = folder;
          childrenByParentSyncId
              .putIfAbsent(currentParentSyncId ?? '', () => [])
              .add(folder);
        } else if (folder.deletedAt != null) {
          final linkVector = _parseVersionVector(link.versionVectorJson);
          final folderVector = _parseVersionVector(folder.versionVectorJson);
          final relation = _compareVersionVectors(linkVector, folderVector);
          final shouldResurrect = switch (relation) {
            _VectorRelation.leftDominates => true,
            _VectorRelation.conflict => link.updatedAt >= folder.updatedAt,
            _VectorRelation.equal => link.updatedAt >= folder.updatedAt,
            _VectorRelation.rightDominates => false,
          };
          if (shouldResurrect) {
            folder
              ..deletedAt = null
              ..versionVectorJson = _encodeVersionVector(
                _bumpVector(_mergeVectors(linkVector, folderVector)),
              )
              ..updatedAt = now;
          } else {
            link
              ..deletedAt = now
              ..versionVectorJson = _encodeVersionVector(
                _bumpVector(_mergeVectors(linkVector, folderVector)),
              )
              ..updatedAt = now;
            break;
          }
        }
        currentParentSyncId = folder.syncId;
        deepestFolder = folder;
      }

      // 3) 最终补齐 link 的 folderSyncId 和 uniqueKey。
      if (link.deletedAt == null && deepestFolder != null) {
        link
          ..folderSyncId = deepestFolder.syncId
          ..uniqueKey = _linkUniqueKey(
            link.comicUniqueKey,
            deepestFolder.syncId,
            link.typeData,
          );
      }
    }
  }

  static List<int> _encryptBytes(List<int> bytes) {
    final key = Key.fromUtf8('XY!Ex3j3hP^BGPFanYEjBA!L!oD2kkCN');
    final iv = IV.fromUtf8('7qFwTxwH&iyuw35f');
    final encrypter = Encrypter(AES(key, mode: AESMode.ctr));
    return encrypter.encryptBytes(bytes, iv: iv).bytes;
  }

  static List<int> _decryptBytes(List<int> bytes) {
    final key = Key.fromUtf8('XY!Ex3j3hP^BGPFanYEjBA!L!oD2kkCN');
    final iv = IV.fromUtf8('7qFwTxwH&iyuw35f');
    final encrypter = Encrypter(AES(key, mode: AESMode.ctr));
    return encrypter.decryptBytes(Encrypted(Uint8List.fromList(bytes)), iv: iv);
  }

  static Map<String, dynamic> _stripLocalId(Map<String, dynamic> json) {
    json.remove('id');
    return json;
  }

  static final RegExp _comicDataRegex = RegExp(r'^comic_(\d+)\.bin$');
  static final RegExp _settingsDataRegex = RegExp(r'^settings_(\d+)\.bin$');
}

Future<void> runComicSync(ComicSyncRemoteAdapter adapter) async {
  await adapter.testConnection();
  await adapter.ensureRemoteReady();

  final localPayload = await ComicSyncCore.buildCompressedPayload();
  final localMd5 = ComicSyncCore.calculateMd5(localPayload);

  final allRemoteFiles = await adapter.listRemoteDataFiles();
  final legacyFiles = allRemoteFiles
      .where(ComicSyncCore.isLegacyRemotePath)
      .toList();
  if (legacyFiles.isNotEmpty) {
    await adapter.deleteRemoteFiles(legacyFiles);
  }

  final syncRootFiles = allRemoteFiles
      .where(ComicSyncCore.isSyncRootPath)
      .toList();
  final remoteMd5 = await adapter.downloadRemoteMd5();

  logger.d(
    '[sync][comic] precheck localMd5=$localMd5 remoteMd5=$remoteMd5 remoteFiles=${syncRootFiles.length}',
  );

  if (remoteMd5.isNotEmpty && remoteMd5 == localMd5) {
    logger.d('[sync][comic] decision=skip reason=md5_equal');
    await _cleanupRemoteComicFiles(
      adapter,
      allSyncRootFiles: allRemoteFiles,
      keepComicPath:
          '${ComicSyncCore.syncRemoteRootName}/${ComicSyncCore.buildComicDataFileName()}',
    );
    return;
  }

  final remoteData = await _selectLatestRemoteComicData(
    adapter,
    syncRootFiles,
    remoteMd5,
  );

  if (remoteData != null) {
    final cloudData = await ComicSyncCore.decodeCompressedPayload(
      remoteData.bytes,
    );
    final mergeArg = <String, dynamic>{
      '_data': cloudData,
      '_deviceId': syncDeviceId,
    };
    final count = await objectbox.store
        .runInTransactionAsync<int, Map<String, dynamic>>(
          TxMode.write,
          ComicSyncCore.mergeUnifiedDataInIsolate,
          mergeArg,
        );
    logger.d(
      '[sync][comic] decision=apply_remote remoteFile=${remoteData.path} mergedCount=$count',
    );
  }

  final currentPayload = await ComicSyncCore.buildCompressedPayload();
  final currentMd5 = ComicSyncCore.calculateMd5(currentPayload);
  if (currentMd5 == remoteMd5 && remoteData != null) {
    logger.d('[sync][comic] decision=skip_upload reason=post_merge_md5_equal');
    return;
  }

  final uploadFile = ComicSyncCore.buildComicDataFileName();
  final keepComicPath = '${ComicSyncCore.syncRemoteRootName}/$uploadFile';
  await adapter.uploadRemoteFile(uploadFile, currentPayload);
  await adapter.uploadRemoteMd5(currentMd5);
  logger.d('[sync][comic] decision=upload file=$uploadFile md5=$currentMd5');

  await _cleanupRemoteComicFiles(
    adapter,
    allSyncRootFiles: await adapter.listRemoteDataFiles(),
    keepComicPath: keepComicPath,
  );
}

Future<void> _cleanupRemoteComicFiles(
  ComicSyncRemoteAdapter adapter, {
  required List<String> allSyncRootFiles,
  required String keepComicPath,
}) async {
  final syncRootFiles = allSyncRootFiles
      .where(ComicSyncCore.isSyncRootPath)
      .toList();
  final comicCandidates = syncRootFiles.where((path) {
    final fileName = ComicSyncCore.extractFileName(path);
    return ComicSyncCore.isComicDataFileName(fileName);
  }).toList();

  final sortedComic = ComicSyncCore.sortComicFilesByTimestampDesc(
    comicCandidates,
  );
  final keep = <String>{
    ComicSyncCore.normalizeRemotePathNoLeadingSlash(keepComicPath),
    '${ComicSyncCore.syncRemoteRootName}/${ComicSyncCore.comicMd5FileName}',
  };

  for (var i = 0; i < sortedComic.length; i++) {
    if (i < 3) {
      keep.add(ComicSyncCore.normalizeRemotePathNoLeadingSlash(sortedComic[i]));
    }
  }

  final stale = syncRootFiles.where((path) {
    final normalized = ComicSyncCore.normalizeRemotePathNoLeadingSlash(path);
    return !keep.contains(normalized) &&
        ComicSyncCore.isComicDataFileName(ComicSyncCore.extractFileName(path));
  }).toList();

  if (stale.isNotEmpty) {
    await adapter.deleteRemoteFiles(stale);
  }
}

Future<_RemoteFileData?> _selectLatestRemoteComicData(
  ComicSyncRemoteAdapter adapter,
  List<String> remotePaths,
  String remoteMd5,
) async {
  final sortedFiles = ComicSyncCore.sortComicFilesByTimestampDesc(remotePaths);
  if (sortedFiles.isEmpty || remoteMd5.isEmpty) {
    return null;
  }

  for (final remotePath in sortedFiles) {
    try {
      final remoteBytes = await adapter.downloadRemoteFile(remotePath);
      final fileMd5 = ComicSyncCore.calculateMd5(remoteBytes);
      if (fileMd5 == remoteMd5) {
        return _RemoteFileData(path: remotePath, bytes: remoteBytes);
      }
      logger.w('远端漫画文件 md5 不匹配，尝试更旧版本: $remotePath');
    } catch (e) {
      logger.w('远端漫画文件下载失败，尝试更旧版本: $remotePath, error: $e');
    }
  }

  return null;
}

class _RemoteFileData {
  const _RemoteFileData({required this.path, required this.bytes});

  final String path;
  final List<int> bytes;
}
