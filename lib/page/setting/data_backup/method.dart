import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:objectbox/objectbox.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/sync/sync_device_id.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/src/rust/api/data_backup.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/widgets/toast.dart';

/// 备份包配置信息。
class BackupConfig {
  final String version;
  final bool includeDownloads;

  /// 本次导入使用的临时根目录，包含 zip 缓存副本与解压目录。
  final String cacheDir;

  /// 解压目录路径。
  final String extractDir;

  /// 缓存目录中的 zip 副本路径。
  final String zipPath;

  BackupConfig({
    required this.version,
    required this.includeDownloads,
    required this.cacheDir,
    required this.extractDir,
    required this.zipPath,
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

/// 读取备份包中的 config.json，并把 zip 复制到应用缓存目录后返回配置信息。
///
/// 先把源 zip 复制到私有缓存，再读取 config.json，避免在确认导入前因权限
/// 回收或源文件变动导致第二次读取失败。本函数不会解压整个 zip。
/// 调用方在确认导入后应使用 [applyBreezeBackupImport]；若取消导入，
/// 请自行删除 [BackupConfig.cacheDir]。
///
/// 当 [skipCopy] 为 true 时，[sourceZipPath] 应已是私有缓存中的路径，
/// 不再重复复制（用于 Android 原生选择器直接拷贝到目标位置的场景）。
Future<BackupConfig> readBackupConfig(
  String sourceZipPath, {
  bool skipCopy = false,
}) async {
  final cachePath = await getCachePath();
  // Android 原生选择器已经直接拷贝到私有缓存，复用该目录避免重复拷贝和路径不一致
  final cacheDir = skipCopy
      ? Directory(p.dirname(p.dirname(sourceZipPath)))
      : Directory(
          p.join(
            cachePath,
            'breeze_backup_import',
            DateTime.now().millisecondsSinceEpoch.toString(),
          ),
        );
  final extractDir = Directory(p.join(cacheDir.path, 'extract'));
  final cacheZipFile = File(p.join(cacheDir.path, 'zip', 'backup.zip'));

  try {
    await extractDir.create(recursive: true);
    await cacheZipFile.parent.create(recursive: true);
    if (!skipCopy) {
      await File(sourceZipPath).copy(cacheZipFile.path);
    }

    final configJson = await readDataBackupConfig(zipPath: cacheZipFile.path);
    final config = jsonDecode(configJson) as Map<String, dynamic>;
    return BackupConfig(
      version: config['version'] as String? ?? 'Unknown',
      includeDownloads: config['includeDownloads'] as bool? ?? false,
      cacheDir: cacheDir.path,
      extractDir: extractDir.path,
      zipPath: cacheZipFile.path,
    );
  } catch (e) {
    showErrorToast('导入失败：$e');
    // 失败时清理全部临时目录，避免残留
    try {
      await cacheDir.delete(recursive: true);
    } catch (_) {}
    rethrow;
  }
}

const _filePickerChannel = MethodChannel('com.zephyr.breeze/file_picker');

/// Android 原生选择 zip 文件并直接拷贝到应用缓存目录。
///
/// 返回缓存中的 zip 路径；用户取消时返回 null。该路径可直接交给
/// [readBackupConfig] 且应设置 [skipCopy] 为 true，避免重复拷贝。
Future<String?> pickBackupZipAndroid() async {
  final cachePath = await getCachePath();
  final cacheDir = Directory(
    p.join(
      cachePath,
      'breeze_backup_import',
      DateTime.now().millisecondsSinceEpoch.toString(),
    ),
  );
  final cacheZipFile = File(p.join(cacheDir.path, 'zip', 'backup.zip'));
  await cacheZipFile.parent.create(recursive: true);

  logger.i('调用 Android 原生选择器，目标路径：${cacheZipFile.path}');
  final result = await _filePickerChannel.invokeMethod<String>(
    'pickBackupZip',
    {'destPath': cacheZipFile.path},
  );
  logger.i('Android 原生选择器返回：$result');
  if (result == null) {
    // 用户取消选择，清理已创建的临时目录
    try {
      await cacheDir.delete(recursive: true);
    } catch (_) {}
  }
  return result;
}

/// 将备份数据解压并应用到当前应用。
///
/// [config] 应来自 [readBackupConfig] 的返回值。执行完成后会删除
/// [BackupConfig.cacheDir] 下的缓存副本与解压目录。
Future<void> applyBreezeBackupImport(BackupConfig config) async {
  final cacheDirectory = Directory(config.cacheDir);
  try {
    // 1. 解压完整备份包
    await extractDataBackupZip(
      zipPath: config.zipPath,
      extractDir: config.extractDir,
    );

    // 解压完成后即可删除缓存的 zip 副本，减少磁盘占用
    try {
      await File(config.zipPath).delete();
    } catch (_) {}

    final configFile = File(p.join(config.extractDir, 'config.json'));
    final backupConfig =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    final includeDownloads = backupConfig['includeDownloads'] as bool? ?? false;

    // 2. 清空现有 ObjectBox 数据
    // 若备份不包含下载文件，则保留本机下载相关记录，避免下载记录被清空后
    // 已下载文件变成“孤儿文件”。
    await _clearObjectBoxData(preserveDownloads: !includeDownloads);

    // 3. 恢复 ObjectBox 数据
    final objectBoxFile = File(p.join(config.extractDir, 'objectbox.json'));
    if (await objectBoxFile.exists()) {
      final objectBoxJson =
          jsonDecode(await objectBoxFile.readAsString())
              as Map<String, dynamic>;
      await _restoreObjectBoxData(objectBoxJson);
    }

    // 4. 恢复下载文件
    if (includeDownloads) {
      final exportedDownloadsDir = Directory(
        p.join(config.extractDir, 'downloads'),
      );
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
      await cacheDirectory.delete(recursive: true);
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
///
/// 当 [preserveDownloads] 为 true 时，保留下载记录与下载文件夹，用于导入
/// 不含下载文件的备份，避免本机已下载文件变成无记录的孤儿文件。
///
/// 下载任务在任何情况下都不会被导入，因此 [downloadTaskBox] 总是被清空。
Future<void> _clearObjectBoxData({bool preserveDownloads = false}) async {
  objectbox.bikaHistoryBox.removeAll();
  if (!preserveDownloads) objectbox.bikaDownloadBox.removeAll();
  objectbox.jmFavoriteBox.removeAll();
  objectbox.jmHistoryBox.removeAll();
  if (!preserveDownloads) objectbox.jmDownloadBox.removeAll();
  objectbox.unifiedFavoriteBox.removeAll();
  objectbox.unifiedHistoryBox.removeAll();
  if (!preserveDownloads) objectbox.unifiedDownloadBox.removeAll();
  objectbox.favoriteFolderBox.removeAll();
  objectbox.favoriteFolderItemBox.removeAll();
  if (!preserveDownloads) {
    objectbox.downloadFolderBox.removeAll();
    objectbox.downloadFolderItemBox.removeAll();
  }
  // 注意：UserSetting 不在这里清除，而是在 _restoreUserSetting 中直接替换/更新，
  // 因为应用其他位置假设 UserSetting 的 id 始终为 1。
  // 下载任务在任何情况下都不导入，所以这里总是先清空本地下载任务。
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
  // 下载任务不导入，避免恢复后继续执行已过期的下载任务。
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
///
/// 导入时会保留当前设备上的平台相关/本地-only 设置，避免被备份覆盖：
/// 自定义导出目录、代理、应用锁（手势密码/PIN）、语言、窗口几何、日志地址、
/// Impeller 强制启用标志等。
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
      current.globalSetting = _mergeGlobalSettingForImport(
        backup.globalSetting,
        current.globalSetting,
      );
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
    if (backup.globalSettingData != null &&
        backup.globalSettingData!.isNotEmpty) {
      backup.globalSetting = _mergeGlobalSettingForImport(
        backup.globalSetting,
        const GlobalSettingState(),
      );
    }
    objectbox.userSettingBox.put(backup);
  }
}

/// 合并备份的 [GlobalSettingState] 与当前设备的本地设置。
///
/// 备份中的通用偏好设置会被采用，但跟平台强相关或不应跨设备同步的字段
/// 会被 [current] 的值覆盖：
/// - 自定义导出目录（[customExportPath]）
/// - SOCKS5 代理（[socks5Proxy]）
/// - 应用锁（[appLockSetting]，含手势密码哈希与 PIN 重置哈希）
/// - 语言（[locale]）
/// - 桌面端窗口位置与大小（[windowWidth]/[windowHeight]/[windowX]/[windowY]）
/// - 日志保存地址（[logAddress]）
/// - iOS Impeller 强制启用标志（[forceEnableImpeller]）
GlobalSettingState _mergeGlobalSettingForImport(
  GlobalSettingState backup,
  GlobalSettingState current,
) {
  return backup.copyWith(
    customExportPath: current.customExportPath,
    socks5Proxy: current.socks5Proxy,
    appLockSetting: current.appLockSetting,
    locale: current.locale,
    windowWidth: current.windowWidth,
    windowHeight: current.windowHeight,
    windowX: current.windowX,
    windowY: current.windowY,
    logAddress: current.logAddress,
    forceEnableImpeller: current.forceEnableImpeller,
  );
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
