import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/src/rust/api/simple.dart';

const String syncDataVersion = 'v1';

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

    final data = {
      'version': syncDataVersion,
      'favorites': favorites.map((e) => e.toJson()).toList(),
      'histories': histories.map((e) => e.toJson()).toList(),
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

  static int mergeUnifiedData(Store store, Map<String, dynamic> data) {
    final favoriteBox = store.box<UnifiedComicFavorite>();
    final historyBox = store.box<UnifiedComicHistory>();

    final localFavorites = favoriteBox.getAll();
    final localHistories = historyBox.getAll();

    final cloudFavorites = _parseJsonList(
      data['favorites'],
    ).map(UnifiedComicFavorite.fromJson).toList();
    final cloudHistories = _parseJsonList(
      data['histories'],
    ).map(UnifiedComicHistory.fromJson).toList();

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

    for (final item in mergedFavorites) {
      item.id = 0;
    }
    for (final item in mergedHistories) {
      item.id = 0;
    }

    favoriteBox.removeAll();
    historyBox.removeAll();
    if (mergedFavorites.isNotEmpty) {
      favoriteBox.putMany(mergedFavorites);
    }
    if (mergedHistories.isNotEmpty) {
      historyBox.putMany(mergedHistories);
    }

    return mergedFavorites.length + mergedHistories.length;
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
    final count = await objectbox.store
        .runInTransactionAsync<int, Map<String, dynamic>>(
          TxMode.write,
          ComicSyncCore.mergeUnifiedData,
          cloudData,
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
