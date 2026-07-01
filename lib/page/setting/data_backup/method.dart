import 'dart:convert';
import 'dart:io';

import 'package:objectbox/objectbox.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/network/sync/sync_device_id.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/src/rust/api/data_backup.dart';
import 'package:zephyr/util/get_path.dart';

/// 备份包配置信息。
class BackupConfig {
  final String version;
  final bool includeDownloads;
  final String extractDir;

  BackupConfig({
    required this.version,
    required this.includeDownloads,
    required this.extractDir,
  });
}

/// 导出完整数据备份到 [zipPath]。
///
/// 当 [includeDownloads] 为 true 时，会一并打包 `getDownloadPath()` 下的漫画文件。
Future<String> exportBreezeBackup({
  required String zipPath,
  required bool includeDownloads,
}) async {
  final cachePath = await getCachePath();
  final tempDir = await Directory(
    p.join(
      cachePath,
      'breeze_backup',
      DateTime.now().millisecondsSinceEpoch.toString(),
    ),
  ).create(recursive: true);

  try {
    // 1. 写入 config.json
    final packageInfo = await PackageInfo.fromPlatform();
    final config = <String, dynamic>{
      'version': packageInfo.version,
      'includeDownloads': includeDownloads,
      'exportedAt': DateTime.now().toIso8601String(),
    };
    await File(
      p.join(tempDir.path, 'config.json'),
    ).writeAsString(jsonEncode(config));

    // 2. 写入 objectbox.json
    final objectBoxData = await _collectObjectBoxData();
    await File(
      p.join(tempDir.path, 'objectbox.json'),
    ).writeAsString(jsonEncode(objectBoxData));

    // 3. 调用 Rust 流式打包
    await createDataBackupZip(
      zipPath: zipPath,
      dataDir: tempDir.path,
      downloadDir: includeDownloads ? await getDownloadPath() : null,
    );

    return zipPath;
  } finally {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  }
}

/// 读取备份包配置，解压到临时目录并返回配置信息。
///
/// 调用方在确认导入后应使用 [applyBreezeBackupImport]；若取消导入，
/// 请自行删除 [BackupConfig.extractDir]。
Future<BackupConfig> readBackupConfig(String zipPath) async {
  final cachePath = await getCachePath();
  final extractDir = await Directory(
    p.join(
      cachePath,
      'breeze_backup_extract',
      DateTime.now().millisecondsSinceEpoch.toString(),
    ),
  ).create(recursive: true);

  try {
    await extractDataBackupZip(zipPath: zipPath, extractDir: extractDir.path);

    final configFile = File(p.join(extractDir.path, 'config.json'));
    if (!await configFile.exists()) {
      throw StateError('备份包中缺少 config.json');
    }

    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    return BackupConfig(
      version: config['version'] as String? ?? 'Unknown',
      includeDownloads: config['includeDownloads'] as bool? ?? false,
      extractDir: extractDir.path,
    );
  } catch (_) {
    // 失败时清理临时目录，避免残留
    try {
      await extractDir.delete(recursive: true);
    } catch (_) {}
    rethrow;
  }
}

/// 将已解压的备份数据应用到当前应用。
///
/// [extractDir] 应来自 [readBackupConfig] 的返回值。执行完成后会删除该目录。
Future<void> applyBreezeBackupImport(String extractDir) async {
  final extractDirectory = Directory(extractDir);
  try {
    final configFile = File(p.join(extractDir, 'config.json'));
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final includeDownloads = config['includeDownloads'] as bool? ?? false;

    // 1. 清空现有 ObjectBox 数据
    await _clearObjectBoxData();

    // 2. 恢复 ObjectBox 数据
    final objectBoxFile = File(p.join(extractDir, 'objectbox.json'));
    if (await objectBoxFile.exists()) {
      final objectBoxJson =
          jsonDecode(await objectBoxFile.readAsString())
              as Map<String, dynamic>;
      await _restoreObjectBoxData(objectBoxJson);
    }

    // 3. 恢复下载文件
    if (includeDownloads) {
      final exportedDownloadsDir = Directory(p.join(extractDir, 'downloads'));
      if (await exportedDownloadsDir.exists()) {
        final currentDownloadDir = Directory(await getDownloadPath());
        if (await currentDownloadDir.exists()) {
          await currentDownloadDir.delete(recursive: true);
        }
        await _moveDirectory(exportedDownloadsDir, currentDownloadDir);
      }
    }
  } finally {
    try {
      await extractDirectory.delete(recursive: true);
    } catch (_) {}
  }
}

/// 收集所有 ObjectBox 实体数据；导出时移除 ObjectBox 自动分配的 `id` 字段，
/// 避免导入时因携带旧 id 导致异常。
Future<Map<String, dynamic>> _collectObjectBoxData() async {
  List<Map<String, dynamic>> withoutIds(List<Map<String, dynamic>> items) {
    return items
        .map((json) => <String, dynamic>{...json}..remove('id'))
        .toList();
  }

  return <String, dynamic>{
    'bikaComicHistory': withoutIds(
      objectbox.bikaHistoryBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'bikaComicDownload': withoutIds(
      objectbox.bikaDownloadBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'jmFavorite': withoutIds(
      objectbox.jmFavoriteBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'jmHistory': withoutIds(
      objectbox.jmHistoryBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'jmDownload': withoutIds(
      objectbox.jmDownloadBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'unifiedComicFavorite': withoutIds(
      objectbox.unifiedFavoriteBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'unifiedComicHistory': withoutIds(
      objectbox.unifiedHistoryBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'unifiedComicDownload': withoutIds(
      objectbox.unifiedDownloadBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'favoriteFolder': withoutIds(
      objectbox.favoriteFolderBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'favoriteFolderItem': withoutIds(
      objectbox.favoriteFolderItemBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'downloadFolder': withoutIds(
      objectbox.downloadFolderBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'downloadFolderItem': withoutIds(
      objectbox.downloadFolderItemBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'userSetting': withoutIds(
      objectbox.userSettingBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'downloadTask': withoutIds(
      objectbox.downloadTaskBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'pluginConfig': withoutIds(
      objectbox.pluginConfigBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'pluginInfo': withoutIds(
      objectbox.pluginInfoBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'comicFolder': withoutIds(
      objectbox.comicFolderBox.getAll().map((e) => e.toJson()).toList(),
    ),
    'comicLink': withoutIds(
      objectbox.comicLinkBox.getAll().map((e) => e.toJson()).toList(),
    ),
  };
}

/// 清空所有 ObjectBox Box。
Future<void> _clearObjectBoxData() async {
  objectbox.bikaHistoryBox.removeAll();
  objectbox.bikaDownloadBox.removeAll();
  objectbox.jmFavoriteBox.removeAll();
  objectbox.jmHistoryBox.removeAll();
  objectbox.jmDownloadBox.removeAll();
  objectbox.unifiedFavoriteBox.removeAll();
  objectbox.unifiedHistoryBox.removeAll();
  objectbox.unifiedDownloadBox.removeAll();
  objectbox.favoriteFolderBox.removeAll();
  objectbox.favoriteFolderItemBox.removeAll();
  objectbox.downloadFolderBox.removeAll();
  objectbox.downloadFolderItemBox.removeAll();
  // 注意：UserSetting 不在这里清除，而是在 _restoreUserSetting 中直接替换/更新，
  // 因为应用其他位置假设 UserSetting 的 id 始终为 1。
  objectbox.downloadTaskBox.removeAll();
  objectbox.pluginConfigBox.removeAll();
  objectbox.pluginInfoBox.removeAll();
  objectbox.comicFolderBox.removeAll();
  objectbox.comicLinkBox.removeAll();
}

/// 为缺少 `id` 的 JSON 补一个默认 0，避免 json_serializable 生成代码里对 `id` 做非空强制转换时崩溃。
Map<String, dynamic> _withDefaultId(Map<String, dynamic> json) {
  if (!json.containsKey('id') || json['id'] == null) {
    json['id'] = 0;
  }
  return json;
}

/// 从 JSON 恢复所有 ObjectBox 实体；导入时重置 id 让 ObjectBox 重新分配主键。
///
/// 对于 ComicFolder / ComicLink，还会用当前设备的 syncDeviceId 对
/// versionVectorJson 做一次 bump，避免导入后同步时出现设备 ID 不一致的冲突。
Future<void> _restoreObjectBoxData(Map<String, dynamic> json) async {
  final currentDeviceId = await ensureSyncDeviceId();

  String bumpVersionVector(String raw) {
    final map = _parseVersionVector(raw);
    map[currentDeviceId] = (map[currentDeviceId] ?? 0) + 1;
    return jsonEncode(map);
  }

  void putAll<T>(
    Box<T> box,
    List<dynamic>? list,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final items = (list ?? const <dynamic>[])
        .map(
          (e) => fromJson(_withDefaultId(Map<String, dynamic>.from(e as Map))),
        )
        .toList();
    if (items.isNotEmpty) {
      box.putMany(items);
    }
  }

  putAll(
    objectbox.bikaHistoryBox,
    json['bikaComicHistory'] as List?,
    (j) => BikaComicHistory.fromJson(j),
  );
  putAll(
    objectbox.bikaDownloadBox,
    json['bikaComicDownload'] as List?,
    (j) => BikaComicDownload.fromJson(j),
  );
  putAll(
    objectbox.jmFavoriteBox,
    json['jmFavorite'] as List?,
    (j) => JmFavorite.fromJson(j),
  );
  putAll(
    objectbox.jmHistoryBox,
    json['jmHistory'] as List?,
    (j) => JmHistory.fromJson(j),
  );
  putAll(
    objectbox.jmDownloadBox,
    json['jmDownload'] as List?,
    (j) => JmDownload.fromJson(j),
  );
  putAll(
    objectbox.unifiedFavoriteBox,
    json['unifiedComicFavorite'] as List?,
    (j) => UnifiedComicFavorite.fromJson(j),
  );
  putAll(
    objectbox.unifiedHistoryBox,
    json['unifiedComicHistory'] as List?,
    (j) => UnifiedComicHistory.fromJson(j),
  );
  putAll(
    objectbox.unifiedDownloadBox,
    json['unifiedComicDownload'] as List?,
    (j) => UnifiedComicDownload.fromJson(j),
  );
  putAll(
    objectbox.favoriteFolderBox,
    json['favoriteFolder'] as List?,
    (j) => FavoriteFolder.fromJson(j),
  );
  putAll(
    objectbox.favoriteFolderItemBox,
    json['favoriteFolderItem'] as List?,
    (j) => FavoriteFolderItem.fromJson(j),
  );
  putAll(
    objectbox.downloadFolderBox,
    json['downloadFolder'] as List?,
    (j) => DownloadFolder.fromJson(j),
  );
  putAll(
    objectbox.downloadFolderItemBox,
    json['downloadFolderItem'] as List?,
    (j) => DownloadFolderItem.fromJson(j),
  );
  await _restoreUserSetting(json['userSetting'] as List?);
  putAll(
    objectbox.downloadTaskBox,
    json['downloadTask'] as List?,
    (j) => DownloadTask.fromJson(j),
  );
  putAll(
    objectbox.pluginConfigBox,
    json['pluginConfig'] as List?,
    (j) => PluginConfig.fromJson(j),
  );
  putAll(
    objectbox.pluginInfoBox,
    json['pluginInfo'] as List?,
    (j) => PluginInfo.fromJson(j),
  );
  putAll(objectbox.comicFolderBox, json['comicFolder'] as List?, (j) {
    final folder = ComicFolder.fromJson(j);
    folder.versionVectorJson = bumpVersionVector(folder.versionVectorJson);
    return folder;
  });
  putAll(objectbox.comicLinkBox, json['comicLink'] as List?, (j) {
    final link = ComicLink.fromJson(j);
    link.versionVectorJson = bumpVersionVector(link.versionVectorJson);
    return link;
  });
}

/// 恢复 UserSetting。
///
/// 应用大量代码假设 UserSetting 的 ObjectBox id 为 1，因此这里不先清空再插入，
/// 而是直接替换现有 id=1 记录的内容；没有记录时再插入新记录。
Future<void> _restoreUserSetting(List<dynamic>? list) async {
  if (list == null || list.isEmpty) return;

  final backup = UserSetting.fromJson(
    _withDefaultId(Map<String, dynamic>.from(list.first as Map)),
  );

  final current = objectbox.userSettingBox.get(1);
  if (current != null) {
    // 复用现有 id=1 的 slot，直接覆盖设置数据
    if (backup.globalSettingData != null &&
        backup.globalSettingData!.isNotEmpty) {
      current.globalSettingData = backup.globalSettingData;
    }
    if (backup.bikaSettingData != null && backup.bikaSettingData!.isNotEmpty) {
      current.bikaSettingData = backup.bikaSettingData;
    }
    if (backup.jmSettingData != null && backup.jmSettingData!.isNotEmpty) {
      current.jmSettingData = backup.jmSettingData;
    }
    current.jmJwt = backup.jmJwt;
    objectbox.userSettingBox.put(current);
  } else {
    // 没有现有记录时直接插入备份数据，让 ObjectBox 自动分配 id（空盒时通常为 1）
    backup.id = 0;
    objectbox.userSettingBox.put(backup);
  }
}

/// 尽可能使用重命名移动目录；失败时回退到递归复制。
Map<String, int> _parseVersionVector(String raw) {
  if (raw.trim().isEmpty) return <String, int>{};
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as num).toInt()));
  } catch (_) {
    return <String, int>{};
  }
}

Future<void> _moveDirectory(Directory source, Directory target) async {
  try {
    await source.rename(target.path);
  } on FileSystemException catch (_) {
    await target.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      final newPath = p.join(target.path, p.basename(entity.path));
      if (entity is Directory) {
        await _moveDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
    await source.delete(recursive: true);
  }
}
