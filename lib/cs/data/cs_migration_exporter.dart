import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/util/get_path.dart';

/// 将本地 ObjectBox 数据整理成 CS 登录后的迁移快照。
///
/// 快照只用于一次性迁移，不会删除或修改本地数据库。设备专属的路径、应用锁、
/// 同步服务和窗口状态不会上传；插件配置和插件脚本会随业务数据一起迁移，
/// 这样服务端可以在迁移完成后直接接管插件运行。
class CsMigrationExporter {
  const CsMigrationExporter(this.objectbox);

  final ObjectBox objectbox;

  /// 在上传前检查所有下载记录对应的本地文件是否能找到。
  ///
  /// 旧版本曾把 [UnifiedComicDownload.storageRoot] 保存成未编码的漫画 ID，
  /// 而实际文件系统使用 `f_<xxh3>` 目录名。迁移不能把这种情况静默当成
  /// “没有文件”，否则服务端只会留下下载记录而没有任何资产。
  Future<int> validateDownloadAssets() async {
    var count = 0;
    for (final download in objectbox.unifiedDownloadBox.getAll()) {
      final root = await _resolveDownloadRoot(download);
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) count++;
      }
    }
    return count;
  }

  /// 枚举已下载漫画目录中的文件。文件按单个请求上传，不会把全部漫画文件
  /// 一次性放进迁移 JSON；本地目录和数据库都只读。
  Stream<CsMigrationAsset> exportDownloadAssets() async* {
    for (final download in objectbox.unifiedDownloadBox.getAll()) {
      final root = await _resolveDownloadRoot(download);

      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) continue;
        final relativePath = p.relative(entity.path, from: root.path);
        if (relativePath.startsWith('..') || p.isAbsolute(relativePath)) {
          continue;
        }
        final normalizedRelativePath = relativePath.replaceAll('\\', '/');
        final pathSegments = normalizedRelativePath.split('/');
        final isCover = pathSegments.length == 1;
        yield CsMigrationAsset(
          pluginId: download.source,
          comicId: download.comicId,
          comicUniqueKey: download.uniqueKey,
          relativePath: normalizedRelativePath,
          kind: isCover ? 'cover' : 'page',
          chapterId: isCover
              ? null
              : _resolveChapterId(download, pathSegments.first),
          mediaType: _mediaType(entity.path),
          readBytes: entity.readAsBytes,
        );
      }
    }
  }

  /// 解析下载记录对应的实际目录。
  ///
  /// 当前文件存储使用编码后的漫画 ID（例如 `f_...`），但旧记录里的
  /// `storageRoot` 可能仍然是原始漫画 ID。因此先使用记录路径，再尝试同一
  /// `original` 目录下的编码/原始目录，并最后使用当前下载根目录兜底。
  Future<Directory> _resolveDownloadRoot(UnifiedComicDownload download) async {
    final storageRoot = download.storageRoot.trim();
    final encodedComicId = encodePath(path: download.comicId.trim());
    final candidates = <String>[
      if (storageRoot.isNotEmpty) storageRoot,
      if (storageRoot.isNotEmpty) ...[
        p.join(p.dirname(storageRoot), encodedComicId),
        p.join(p.dirname(storageRoot), download.comicId.trim()),
      ],
    ];

    final downloadRoot = await getDownloadPath();
    candidates.addAll([
      p.join(downloadRoot, download.source, 'original', encodedComicId),
      p.join(downloadRoot, download.source, 'original', download.comicId),
    ]);

    final seen = <String>{};
    for (final candidate in candidates) {
      final normalized = p.normalize(candidate);
      if (!seen.add(normalized)) continue;
      final root = Directory(normalized);
      if (!await root.exists()) continue;

      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) return root;
      }
    }

    throw StateError(
      '无法找到下载文件目录：${download.title} (${download.uniqueKey})，'
      '已检查 ${candidates.join('、')}',
    );
  }

  String _resolveChapterId(
    UnifiedComicDownload download,
    String storageDirectory,
  ) {
    for (final chapter in resolveStoredDownloadChapters(download)) {
      final candidates = <String>{
        chapter.id,
        chapter.logicalKey,
        chapter.taskChapterId,
        chapter.storageChapterId,
      }..removeWhere((value) => value.trim().isEmpty);
      for (final candidate in candidates) {
        if (candidate == storageDirectory ||
            encodePath(path: candidate) == storageDirectory) {
          return chapter.logicalKey.trim().isNotEmpty
              ? chapter.logicalKey
              : chapter.id;
        }
      }
    }
    // 旧数据可能没有保存章节的逻辑 ID，至少保留实际存储目录名，保证
    // 两个章节中同名图片不会被服务端视为同一个资源。
    return storageDirectory;
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
        'favorite_folders': _toJsonList(objectbox.favoriteFolderBox.getAll()),
        'favorite_folder_items': _toJsonList(
          objectbox.favoriteFolderItemBox.getAll(),
        ),
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
    required this.pluginId,
    required this.comicId,
    required this.comicUniqueKey,
    required this.relativePath,
    required this.kind,
    required this.chapterId,
    required this.mediaType,
    required this.readBytes,
  });

  final String pluginId;
  final String comicId;
  final String comicUniqueKey;
  final String relativePath;
  final String kind;
  final String? chapterId;
  final String mediaType;
  final Future<List<int>> Function() readBytes;
}
