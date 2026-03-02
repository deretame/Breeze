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
    final time = DateTime.now().toUtc().millisecondsSinceEpoch;
    return '${appName}_${time}_$syncDataVersion.gz';
  }

  static String? pickLatestRemoteDataFile(List<String> remotePaths) {
    var latestPath = '';
    var latestTimestamp = -1;
    final regex = RegExp(
      '${RegExp.escape(appName)}_(\\d+)_${RegExp.escape(syncDataVersion)}\\.gz\$',
    );

    for (final remotePath in remotePaths) {
      final fileName = _extractFileName(remotePath);
      if (fileName.isEmpty) {
        continue;
      }

      final match = regex.firstMatch(fileName);
      if (match == null) {
        continue;
      }

      final timestamp = int.tryParse(match.group(1) ?? '');
      if (timestamp == null) {
        continue;
      }

      if (timestamp > latestTimestamp) {
        latestTimestamp = timestamp;
        latestPath = remotePath;
      }
    }

    return latestPath.isEmpty ? null : latestPath;
  }

  static bool isSyncDataFileName(String fileName) {
    final regex = RegExp(
      '^${RegExp.escape(appName)}_(\\d+)_${RegExp.escape(syncDataVersion)}\\.gz\$',
    );
    return regex.hasMatch(fileName);
  }

  static String calculateMd5(List<int> data) {
    return md5.convert(data).toString();
  }

  static String get localMd5 {
    return objectbox.userSettingBox.get(1)!.globalSetting.md5;
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

  final remoteFiles = await adapter.listRemoteDataFiles();
  final latestRemoteFile = ComicSyncCore.pickLatestRemoteDataFile(remoteFiles);

  if (latestRemoteFile != null) {
    final remoteBytes = await adapter.downloadRemoteFile(latestRemoteFile);
    final cloudData = await ComicSyncCore.decodeCompressedPayload(remoteBytes);
    await ComicSyncCore.mergeHistory(cloudData);
  }

  final currentPayload = await ComicSyncCore.buildCompressedPayload();
  final currentMd5 = ComicSyncCore.calculateMd5(currentPayload);

  if (remoteMd5.isNotEmpty && remoteMd5 == currentMd5) {
    logger.d('云端数据已是最新，仅更新本地 md5');
    ComicSyncCore.updateLocalMd5(currentMd5);

    final staleFiles = remoteFiles
        .where((item) => item != latestRemoteFile)
        .toList();
    if (staleFiles.isNotEmpty) {
      await adapter.deleteRemoteFiles(staleFiles);
    }
    return;
  }

  final uploadFile = ComicSyncCore.buildDataFileName();
  await adapter.uploadRemoteFile(uploadFile, currentPayload);
  await adapter.uploadRemoteMd5(currentMd5);
  ComicSyncCore.updateLocalMd5(currentMd5);

  if (remoteFiles.isNotEmpty) {
    await adapter.deleteRemoteFiles(remoteFiles);
  }
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
