import 'dart:collection';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypter_plus/encrypter_plus.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';

const String syncDataVersion = '2.3.0';

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
  static String get md5FileName => '$appName.md5';

  static String buildDataFileName() {
    final time = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return '${appName}_${time}_$syncDataVersion.gz';
  }

  static String? pickLatestRemoteDataFile(List<String> remotePaths) {
    final sorted = sortRemoteDataFilesByTimestampDesc(remotePaths);
    if (sorted.isEmpty) {
      return null;
    }
    return sorted.first;
  }

  static List<String> sortRemoteDataFilesByTimestampDesc(
    List<String> remotePaths,
  ) {
    final sorted = remotePaths.where((remotePath) {
      final fileName = _extractFileName(remotePath);
      return isSyncDataFileName(fileName);
    }).toList();
    sorted.sort((a, b) {
      final aTs = extractTimestampFromRemotePath(a) ?? -1;
      final bTs = extractTimestampFromRemotePath(b) ?? -1;
      if (aTs == bTs) {
        return b.compareTo(a);
      }
      return bTs.compareTo(aTs);
    });
    return sorted;
  }

  static int? extractTimestampFromRemotePath(String remotePath) {
    final fileName = _extractFileName(remotePath);
    if (fileName.isEmpty) {
      return null;
    }
    final match = _syncDataRegex.firstMatch(fileName);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1) ?? '');
  }

  static bool isSyncDataFileName(String fileName) {
    return _syncDataRegex.hasMatch(fileName);
  }

  static final RegExp _syncDataRegex = RegExp(
    '^${RegExp.escape(appName)}_(\\d+)_${RegExp.escape(syncDataVersion)}\\.gz\$',
  );

  static String calculateMd5(List<int> data) {
    return md5.convert(data).toString();
  }

  static String get localMd5 {
    return objectbox.userSettingBox.get(1)?.globalSetting.md5 ?? '';
  }

  static void updateLocalMd5(String value) {
    final userSettings = objectbox.userSettingBox.get(1);
    if (userSettings == null || userSettings.globalSetting.md5 == value) {
      return;
    }

    userSettings.globalSetting = userSettings.globalSetting.copyWith(
      md5: value,
    );
    objectbox.userSettingBox.put(userSettings);
  }

  static Future<List<int>> buildCompressedPayload() async {
    final allHistory = await objectbox.bikaHistoryBox.getAllAsync();
    allHistory.sort((a, b) => b.history.compareTo(a.history));

    final comicHistoriesJson = allHistory
        .map((comic) => comic.toJson())
        .toList();

    final jmFavorite = await objectbox.jmFavoriteBox.getAllAsync();
    final jmFavoritesJson = jmFavorite.map((item) => item.toJson()).toList();

    final jmHistory = await objectbox.jmHistoryBox.getAllAsync();
    final jmHistoriesJson = jmHistory.map((item) => item.toJson()).toList();

    final data = {
      'comicHistories': comicHistoriesJson,
      'jmFavorites': jmFavoritesJson,
      'jmHistories': jmHistoriesJson,
    };

    final compressedBytes = await compute(
      _encryptAndCompress,
      jsonEncode(data),
    );

    if (compressedBytes == null) {
      throw Exception('加密压缩失败');
    }

    return compressedBytes;
  }

  static Future<Map<String, dynamic>> decodeCompressedPayload(
    List<int> compressedBytes,
  ) async {
    final jsonString = await compute(_decompressAndDecrypt, compressedBytes);
    if (jsonString.isEmpty) {
      throw Exception('下载数据为空');
    }

    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  static Future<void> mergeHistory(Map<String, dynamic> data) async {
    final localHistories = await objectbox.bikaHistoryBox.getAllAsync();
    final cloudHistories = (data['comicHistories'] as List<dynamic>)
        .map((comic) => BikaComicHistory.fromJson(comic))
        .toList();

    final combined = [...cloudHistories, ...localHistories];
    combined.sort((a, b) => b.history.compareTo(a.history));

    final uniqueMap = LinkedHashMap<String, BikaComicHistory>(
      equals: (a, b) => a == b,
      hashCode: (e) => e.hashCode,
    );
    for (final item in combined) {
      uniqueMap.putIfAbsent(item.comicId, () => item);
    }

    final finalList = uniqueMap.values.toList();
    for (final item in finalList) {
      item.id = 0;
    }

    await objectbox.bikaHistoryBox.removeAllAsync();
    await objectbox.bikaHistoryBox.putManyAsync(finalList);

    final jmLocalFavorites = await objectbox.jmFavoriteBox.getAllAsync();
    final jmCloudFavorites = (data['jmFavorites'] as List<dynamic>)
        .map((item) => JmFavorite.fromJson(item))
        .toList();
    final jmCombinedFavorites = [...jmCloudFavorites, ...jmLocalFavorites];
    jmCombinedFavorites.sort((a, b) => b.history.compareTo(a.history));

    final jmFavoriteUniqueMap = LinkedHashMap<String, JmFavorite>(
      equals: (a, b) => a == b,
      hashCode: (e) => e.hashCode,
    );
    for (final item in jmCombinedFavorites) {
      jmFavoriteUniqueMap.putIfAbsent(item.comicId, () => item);
    }

    final jmFavoriteFinalList = jmFavoriteUniqueMap.values.toList();
    for (final item in jmFavoriteFinalList) {
      item.id = 0;
    }

    await objectbox.jmFavoriteBox.removeAllAsync();
    await objectbox.jmFavoriteBox.putManyAsync(jmFavoriteFinalList);

    final jmLocalHistories = await objectbox.jmHistoryBox.getAllAsync();
    final jmCloudHistories = (data['jmHistories'] as List<dynamic>)
        .map((item) => JmHistory.fromJson(item))
        .toList();
    final jmCombinedHistories = [...jmCloudHistories, ...jmLocalHistories];
    jmCombinedHistories.sort((a, b) => b.history.compareTo(a.history));

    final jmHistoryUniqueMap = LinkedHashMap<String, JmHistory>(
      equals: (a, b) => a == b,
      hashCode: (e) => e.hashCode,
    );
    for (final item in jmCombinedHistories) {
      jmHistoryUniqueMap.putIfAbsent(item.comicId, () => item);
    }

    final jmHistoryFinalList = jmHistoryUniqueMap.values.toList();
    for (final item in jmHistoryFinalList) {
      item.id = 0;
    }

    await objectbox.jmHistoryBox.removeAllAsync();
    await objectbox.jmHistoryBox.putManyAsync(jmHistoryFinalList);

    logger.d(
      '更新历史记录成功，共 ${finalList.length + jmFavoriteFinalList.length + jmHistoryFinalList.length} 条记录',
    );
  }

  static String _extractFileName(String remotePath) {
    final normalized = remotePath.replaceAll('\\', '/');
    final segments = normalized.split('/').where((item) => item.isNotEmpty);
    if (segments.isEmpty) {
      return '';
    }
    return segments.last;
  }
}

Future<void> runComicSync(ComicSyncRemoteAdapter adapter) async {
  await adapter.testConnection();
  await adapter.ensureRemoteReady();

  final remoteMd5 = await adapter.downloadRemoteMd5();
  final localMd5 = ComicSyncCore.localMd5;

  if (remoteMd5.isNotEmpty && remoteMd5 == localMd5) {
    logger.d('云端与本地 md5 一致，跳过同步');
    return;
  }

  final remotePaths = await adapter.listRemoteDataFiles();
  final remoteData = await _selectRemoteDataForSync(
    adapter,
    remotePaths,
    remoteMd5,
  );

  if (remoteData != null) {
    final cloudData = await ComicSyncCore.decodeCompressedPayload(
      remoteData.bytes,
    );
    await ComicSyncCore.mergeHistory(cloudData);
  }

  final currentPayload = await ComicSyncCore.buildCompressedPayload();
  final currentMd5 = ComicSyncCore.calculateMd5(currentPayload);

  final uploadFile = ComicSyncCore.buildDataFileName();
  await adapter.uploadRemoteFile(uploadFile, currentPayload);
  await adapter.uploadRemoteMd5(currentMd5);
  ComicSyncCore.updateLocalMd5(currentMd5);

  await _cleanupRemoteFiles(
    adapter,
    keepRemotePaths: [
      '$appName/$uploadFile',
      '$appName/${ComicSyncCore.md5FileName}',
    ],
  );
}

Future<void> _cleanupRemoteFiles(
  ComicSyncRemoteAdapter adapter, {
  required List<String> keepRemotePaths,
}) async {
  final allRemoteFiles = await adapter.listRemoteDataFiles();
  if (allRemoteFiles.isEmpty) {
    return;
  }

  final keepNormalizedPaths = keepRemotePaths
      .map(_normalizeRemotePath)
      .where((item) => item.isNotEmpty)
      .toSet();

  final staleFiles = allRemoteFiles.where((remotePath) {
    final normalized = _normalizeRemotePath(remotePath);
    return !keepNormalizedPaths.contains(normalized);
  }).toList();

  if (staleFiles.isNotEmpty) {
    await adapter.deleteRemoteFiles(staleFiles);
  }
}

Future<_RemoteFileData?> _selectRemoteDataForSync(
  ComicSyncRemoteAdapter adapter,
  List<String> remotePaths,
  String remoteMd5,
) async {
  final sortedFiles = ComicSyncCore.sortRemoteDataFilesByTimestampDesc(
    remotePaths,
  );
  if (sortedFiles.isEmpty) {
    return null;
  }

  if (remoteMd5.isEmpty) {
    logger.w('远端 md5 文件不存在，将按无云端文件处理');
    return null;
  }

  for (final remotePath in sortedFiles) {
    try {
      final remoteBytes = await adapter.downloadRemoteFile(remotePath);
      final fileMd5 = ComicSyncCore.calculateMd5(remoteBytes);
      if (fileMd5 == remoteMd5) {
        return _RemoteFileData(path: remotePath, bytes: remoteBytes);
      }

      logger.w(
        '远端文件 md5 不匹配，尝试更旧版本: '
        '$remotePath, expect: $remoteMd5, actual: $fileMd5',
      );
    } catch (e) {
      logger.w('远端文件下载或校验失败，尝试更旧版本: $remotePath, error: $e');
    }
  }

  logger.w('远端所有同步文件均与 md5 不匹配，将按无云端文件处理');
  return null;
}

class _RemoteFileData {
  const _RemoteFileData({required this.path, required this.bytes});

  final String path;
  final List<int> bytes;
}

String _normalizeRemotePath(String path) {
  final normalized = path.replaceAll('\\', '/').trim();
  return normalized.replaceFirst(RegExp(r'^/+'), '');
}

List<int>? _encryptAndCompress(String data) {
  try {
    final key = Key.fromUtf8('XY!Ex3j3hP^BGPFanYEjBA!L!oD2kkCN');
    final iv = IV.fromUtf8('7qFwTxwH&iyuw35f');
    final encrypter = Encrypter(AES(key, mode: AESMode.ctr));
    final encrypted = encrypter.encrypt(data, iv: iv);
    final jsonBytes = utf8.encode(encrypted.base64);
    return GZipEncoder().encode(jsonBytes);
  } catch (_) {
    return null;
  }
}

String _decompressAndDecrypt(List<int> compressedBytes) {
  try {
    final jsonBytes = GZipDecoder().decodeBytes(compressedBytes);
    final encryptedBase64 = utf8.decode(jsonBytes);
    final key = Key.fromUtf8('XY!Ex3j3hP^BGPFanYEjBA!L!oD2kkCN');
    final iv = IV.fromUtf8('7qFwTxwH&iyuw35f');
    final encrypter = Encrypter(AES(key, mode: AESMode.ctr));
    final encrypted = Encrypted.fromBase64(encryptedBase64);
    return encrypter.decrypt(encrypted, iv: iv);
  } catch (e) {
    logger.d('解压或解密失败: $e');
    return '';
  }
}
