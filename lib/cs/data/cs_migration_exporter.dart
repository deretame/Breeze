import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';

/// 将本地 ObjectBox 数据整理成 CS 登录后的迁移快照。
///
/// 快照只用于一次性迁移，不会删除或修改本地数据库。设备专属的路径、应用锁、
/// 同步服务和窗口状态不会上传；插件配置和插件脚本会随业务数据一起迁移，
/// 这样服务端可以在迁移完成后直接接管插件运行。
class CsMigrationExporter {
  const CsMigrationExporter(this.objectbox);

  final ObjectBox objectbox;

  /// 枚举已下载漫画目录中的文件。文件按单个请求上传，不会把全部漫画文件
  /// 一次性放进迁移 JSON；本地目录和数据库都只读。
  Stream<CsMigrationAsset> exportDownloadAssets() async* {
    for (final download in objectbox.unifiedDownloadBox.getAll()) {
      final storageRoot = download.storageRoot.trim();
      if (storageRoot.isEmpty) continue;
      final root = Directory(storageRoot);
      if (!await root.exists()) continue;

      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        final relativePath = p.relative(entity.path, from: root.path);
        if (relativePath.startsWith('..') || p.isAbsolute(relativePath)) {
          continue;
        }
        yield CsMigrationAsset(
          comicUniqueKey: download.uniqueKey,
          relativePath: relativePath.replaceAll('\\', '/'),
          mediaType: _mediaType(entity.path),
          readBytes: entity.readAsBytes,
        );
      }
    }
  }

  Map<String, dynamic> exportSnapshot({required bool includeDownloads}) {
    final setting = objectbox.userSettingBox.get(1);
    return {
      'schema_version': 1,
      'generated_at': DateTime.now().toUtc().toIso8601String(),
      'include_downloads': includeDownloads,
      'data': {
        'account_settings': _accountSettings(setting),
        'favorites': _toJsonList(objectbox.unifiedFavoriteBox.getAll()),
        'histories': _toJsonList(objectbox.unifiedHistoryBox.getAll()),
        'follows': _toJsonList(objectbox.comicFollowBox.getAll()),
        'folders': _toJsonList(objectbox.comicFolderBox.getAll()),
        'links': _toJsonList(objectbox.comicLinkBox.getAll()),
        'plugins': _toJsonList(objectbox.pluginInfoBox.getAll()),
        'plugin_configs': _toJsonList(objectbox.pluginConfigBox.getAll()),
        if (includeDownloads) ...{
          'downloads': _toJsonList(objectbox.unifiedDownloadBox.getAll()),
          'download_tasks': _toJsonList(objectbox.downloadTaskBox.getAll()),
          'download_folders': _toJsonList(objectbox.downloadFolderBox.getAll()),
          'download_folder_items': _toJsonList(
            objectbox.downloadFolderItemBox.getAll(),
          ),
        },
      },
    };
  }

  Map<String, dynamic> _accountSettings(UserSetting? setting) {
    if (setting == null) return const <String, dynamic>{};

    final global = _decodeMap(setting.globalSettingData);
    // 这些值绑定当前设备或包含本地凭据，不应作为账号数据上传。
    for (final key in [
      'customExportPath',
      'appLockSetting',
      'syncSetting',
      'proxySetting',
      'windowWidth',
      'windowHeight',
      'windowX',
      'windowY',
    ]) {
      global.remove(key);
    }

    return {
      if (global.isNotEmpty) 'global': global,
      if (setting.bikaSettingData case final value?
          when value.trim().isNotEmpty)
        'bika': _decodeMap(value),
      if (setting.jmSettingData case final value? when value.trim().isNotEmpty)
        'jm': _decodeMap(value),
    };
  }

  Map<String, dynamic> _decodeMap(String? value) {
    if (value == null || value.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(value);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } on Object {
      return <String, dynamic>{};
    }
  }

  List<Map<String, dynamic>> _toJsonList<T>(List<T> values) {
    return values
        .map((value) => (value as dynamic).toJson() as Map<String, dynamic>)
        .toList(growable: false);
  }

  String _mediaType(String path) {
    final extension = p.extension(path).toLowerCase();
    return switch (extension) {
      '.avif' => 'image/avif',
      '.gif' => 'image/gif',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.png' => 'image/png',
      '.webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
  }
}

class CsMigrationAsset {
  const CsMigrationAsset({
    required this.comicUniqueKey,
    required this.relativePath,
    required this.mediaType,
    required this.readBytes,
  });

  final String comicUniqueKey;
  final String relativePath;
  final String mediaType;
  final Future<List<int>> Function() readBytes;
}
