import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/sync/sync_device_id.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';

const String kComicFolderRootPath = '';

class ComicFolderService {
  static String get _deviceId => syncDeviceId;

  static String get _newSyncId => const Uuid().v4();

  /// 根据路径获取文件夹的 syncId，根目录返回 null。
  ///
  /// [includeDeleted] 为 true 时也会查找已被软删除的文件夹，
  /// 用于在删除后清理其下的链接等场景。
  static String? folderSyncIdByPath(
    String? path,
    ComicFolderType type, {
    bool includeDeleted = false,
  }) {
    if (path == null || path.isEmpty) return null;
    var condition = ComicFolder_.uniqueKey.equals(_uniqueKey(path, type));
    if (!includeDeleted) {
      condition = condition.and(ComicFolder_.deletedAt.isNull());
    }
    final folder = objectbox.comicFolderBox
        .query(condition)
        .build()
        .findFirst();
    return folder?.syncId;
  }

  /// 根据文件夹的 parentSyncId 链计算其显示路径（如 /a/b）。
  static String folderPath(
    ComicFolder folder, {
    Map<String, ComicFolder>? syncIdMap,
  }) {
    final bySyncId = syncIdMap ?? _buildSyncIdMap(folder.type);
    final parts = <String>[];
    final visited = <String>{};
    ComicFolder? current = folder;
    while (current != null) {
      if (current.syncId.isNotEmpty && !visited.add(current.syncId)) break;
      parts.add(current.name);
      final parentId = current.parentSyncId;
      if (parentId == null || parentId.isEmpty) break;
      current = bySyncId[parentId];
    }
    return '/${parts.reversed.join('/')}'; // single folder => /name
  }

  static Map<String, ComicFolder> _buildSyncIdMap(ComicFolderType type) {
    final all = listAllFolders(type);
    return {for (final folder in all) folder.syncId: folder};
  }

  static String _folderPath(String parentPath, String name) {
    final safeName = name.trim();
    if (parentPath == kComicFolderRootPath) {
      return '/$safeName';
    }
    return '$parentPath/$safeName';
  }

  static String _uniqueKey(String path, ComicFolderType type) {
    final parentPath = _parentPath(path);
    final parentSyncId = parentPath == kComicFolderRootPath
        ? ''
        : (folderSyncIdByPath(parentPath, type) ?? '');
    final name = path == kComicFolderRootPath ? '' : path.split('/').last;
    return '$parentSyncId|$name|${type.name}';
  }

  static String? _parentSyncIdByPath(String? parentPath, ComicFolderType type) {
    if (parentPath == null || parentPath.isEmpty) return null;
    return folderSyncIdByPath(parentPath, type);
  }

  static String _parentPath(String path) {
    if (path == kComicFolderRootPath) return kComicFolderRootPath;
    final trimmed = path.endsWith('/')
        ? path.substring(0, path.length - 1)
        : path;
    final index = trimmed.lastIndexOf('/');
    if (index <= 0) return kComicFolderRootPath;
    return trimmed.substring(0, index);
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

  static String _bumpVersionVector(String json) {
    final vector = _parseVersionVector(json);
    vector[_deviceId] = (vector[_deviceId] ?? 0) + 1;
    return _encodeVersionVector(vector);
  }

  static int _now() {
    return DateTime.now().toUtc().millisecondsSinceEpoch;
  }

  /// 列出当前路径下的直接子文件夹
  static List<ComicFolder> listChildFolders(
    String parentPath,
    ComicFolderType type, {
    bool sortAscending = false,
  }) {
    final parentSyncId = _parentSyncIdByPath(parentPath, type);
    final condition = parentSyncId == null
        ? ComicFolder_.parentSyncId.isNull()
        : ComicFolder_.parentSyncId.equals(parentSyncId);
    final query = objectbox.comicFolderBox
        .query(
          ComicFolder_.typeData
              .equals(type.name)
              .and(ComicFolder_.deletedAt.isNull())
              .and(condition),
        )
        .build();
    try {
      final children = query.find();
      children.sort((a, b) {
        return sortAscending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt);
      });
      return children;
    } finally {
      query.close();
    }
  }

  /// 列出该类型下所有未删除的文件夹（不区分层级）
  static List<ComicFolder> listAllFolders(
    ComicFolderType type, {
    bool sortAscending = false,
  }) {
    final query = objectbox.comicFolderBox
        .query(
          ComicFolder_.typeData
              .equals(type.name)
              .and(ComicFolder_.deletedAt.isNull()),
        )
        .build();
    try {
      final all = query.find();
      all.sort((a, b) {
        return sortAscending
            ? a.createdAt.compareTo(b.createdAt)
            : b.createdAt.compareTo(a.createdAt);
      });
      return all;
    } finally {
      query.close();
    }
  }

  /// 获取文件夹名称
  static String? folderName(String path, ComicFolderType type) {
    if (path == kComicFolderRootPath) return null;
    final folder = objectbox.comicFolderBox
        .query(ComicFolder_.uniqueKey.equals(_uniqueKey(path, type)))
        .build()
        .findFirst();
    return folder?.name;
  }

  /// 创建文件夹
  static ComicFolder createFolder(
    String parentPath,
    String name,
    ComicFolderType type,
  ) {
    final safeName = name.trim();
    if (safeName.isEmpty) {
      throw ArgumentError('文件夹名称不能为空');
    }
    if (safeName.contains('/')) {
      throw ArgumentError('文件夹名称不能包含 /');
    }

    final newPath = _folderPath(parentPath, safeName);
    final uniqueKey = _uniqueKey(newPath, type);
    final parentSyncId = _parentSyncIdByPath(parentPath, type);

    final existed = objectbox.comicFolderBox
        .query(ComicFolder_.uniqueKey.equals(uniqueKey))
        .build()
        .findFirst();
    if (existed != null) {
      if (existed.deletedAt != null) {
        //  Tombstone 复活
        final now = _now();
        existed
          ..name = safeName
          ..deletedAt = null
          ..createdAt = now
          ..updatedAt = now
          ..versionVectorJson = _bumpVersionVector(existed.versionVectorJson);
        objectbox.comicFolderBox.put(existed);
        return existed;
      }
      throw StateError('当前路径下已存在同名文件夹');
    }

    final now = _now();
    final folder = ComicFolder(
      syncId: _newSyncId,
      parentSyncId: parentSyncId,
      uniqueKey: uniqueKey,
      name: safeName,
      typeData: type.name,
      versionVectorJson: _encodeVersionVector({_deviceId: 1}),
      createdAt: now,
      updatedAt: now,
    );
    objectbox.comicFolderBox.put(folder);
    return folder;
  }

  /// 软删除文件夹及其下所有子文件夹
  static void deleteFolder(String path, ComicFolderType type) {
    if (path == kComicFolderRootPath) return;
    final now = _now();

    final folder = objectbox.comicFolderBox
        .query(ComicFolder_.uniqueKey.equals(_uniqueKey(path, type)))
        .build()
        .findFirst();
    if (folder == null || folder.deletedAt != null) return;

    folder
      ..deletedAt = now
      ..updatedAt = now
      ..versionVectorJson = _bumpVersionVector(folder.versionVectorJson);
    objectbox.comicFolderBox.put(folder);

    // 级联删除子文件夹（软删除）
    final subtreeSyncIds = _collectSubtreeSyncIds(folder.syncId, type);
    subtreeSyncIds.remove(folder.syncId);
    if (subtreeSyncIds.isEmpty) return;

    final childQuery = objectbox.comicFolderBox
        .query(ComicFolder_.syncId.oneOf(subtreeSyncIds.toList()))
        .build();
    try {
      final children = childQuery.find();
      for (final child in children) {
        if (child.deletedAt != null) continue;
        child
          ..deletedAt = now
          ..updatedAt = now
          ..versionVectorJson = _bumpVersionVector(child.versionVectorJson);
      }
      if (children.isNotEmpty) {
        objectbox.comicFolderBox.putMany(children);
      }
    } finally {
      childQuery.close();
    }
  }

  /// 重命名文件夹
  static void renameFolder(String path, String newName, ComicFolderType type) {
    final safeName = newName.trim();
    if (path == kComicFolderRootPath || safeName.isEmpty) return;
    if (safeName.contains('/')) {
      throw ArgumentError('文件夹名称不能包含 /');
    }

    final folder = objectbox.comicFolderBox
        .query(ComicFolder_.uniqueKey.equals(_uniqueKey(path, type)))
        .build()
        .findFirst();
    if (folder == null || folder.deletedAt != null) return;

    final parentPath = _parentPath(path);
    final newPath = _folderPath(parentPath, safeName);
    final newUniqueKey = _uniqueKey(newPath, type);

    // 检查目标名称是否冲突
    final duplicated = objectbox.comicFolderBox
        .query(ComicFolder_.uniqueKey.equals(newUniqueKey))
        .build()
        .findFirst();
    if (duplicated != null && duplicated.id != folder.id) {
      if (duplicated.deletedAt == null) {
        throw StateError('当前路径下已存在同名文件夹');
      }
      //  Tombstone 冲突：先物理删除旧的 tombstone
      objectbox.comicFolderBox.remove(duplicated.id);
    }

    final now = _now();
    folder
      ..name = safeName
      ..uniqueKey = newUniqueKey
      ..updatedAt = now
      ..versionVectorJson = _bumpVersionVector(folder.versionVectorJson);
    objectbox.comicFolderBox.put(folder);
  }

  // ==================== 批量操作 ====================

  /// 批量移动文件夹到目标路径下。
  /// 会检查：不能移动到自己、不能移动到后代路径下。
  static void batchMoveFolders(
    Set<String> paths,
    String targetPath,
    ComicFolderType type,
  ) {
    for (final path in paths) {
      _validateMoveTarget(path, targetPath);
    }

    final now = _now();
    for (final path in paths) {
      final folder = objectbox.comicFolderBox
          .query(ComicFolder_.uniqueKey.equals(_uniqueKey(path, type)))
          .build()
          .findFirst();
      if (folder == null || folder.deletedAt != null) continue;

      final folderName = folder.name;
      final newPath = _folderPath(targetPath, folderName);
      final newUniqueKey = _uniqueKey(newPath, type);

      // 目标位置若存在 tombstone，先物理清理
      final duplicated = objectbox.comicFolderBox
          .query(ComicFolder_.uniqueKey.equals(newUniqueKey))
          .build()
          .findFirst();
      if (duplicated != null && duplicated.id != folder.id) {
        if (duplicated.deletedAt == null) {
          throw StateError('目标位置已存在同名文件夹：$folderName');
        }
        objectbox.comicFolderBox.remove(duplicated.id);
      }

      _moveFolderInternal(folder, newPath, now, type);
    }
  }

  /// 批量复制文件夹到目标路径下。
  /// 若目标位置已有同名文件夹，会自动重命名（加序号后缀）。
  static void batchCopyFolders(
    Set<String> paths,
    String targetPath,
    ComicFolderType type,
  ) {
    for (final path in paths) {
      if (path == targetPath || targetPath.startsWith('$path/')) {
        throw StateError('不能复制文件夹到自身或其子路径下');
      }
    }

    final now = _now();
    final targetParentSyncId = _parentSyncIdByPath(targetPath, type);
    for (final path in paths) {
      final sourceFolder = objectbox.comicFolderBox
          .query(ComicFolder_.uniqueKey.equals(_uniqueKey(path, type)))
          .build()
          .findFirst();
      if (sourceFolder == null || sourceFolder.deletedAt != null) continue;

      _copyFolderRecursive(sourceFolder, targetParentSyncId, type, now);
    }
  }

  /// 批量删除文件夹（递归软删除）。
  static void batchDeleteFolders(Set<String> paths, ComicFolderType type) {
    for (final path in paths) {
      deleteFolder(path, type);
    }
  }

  static void _validateMoveTarget(String sourcePath, String targetPath) {
    if (sourcePath == targetPath) {
      throw StateError('不能将文件夹移动到自身');
    }
    if (targetPath.startsWith('$sourcePath/')) {
      throw StateError('不能将父文件夹移动到子文件夹中');
    }
  }

  /// 移动单个文件夹的内部实现（不校验，直接执行）。
  static void _moveFolderInternal(
    ComicFolder folder,
    String newPath,
    int now,
    ComicFolderType type,
  ) {
    final newUniqueKey = _uniqueKey(newPath, type);
    final newParentSyncId = _parentSyncIdByPath(_parentPath(newPath), type);

    folder
      ..name = newPath.split('/').last
      ..parentSyncId = newParentSyncId
      ..uniqueKey = newUniqueKey
      ..updatedAt = now
      ..versionVectorJson = _bumpVersionVector(folder.versionVectorJson);
    objectbox.comicFolderBox.put(folder);
  }

  /// 递归复制文件夹。
  static void _copyFolderRecursive(
    ComicFolder sourceFolder,
    String? targetParentSyncId,
    ComicFolderType type,
    int now,
  ) {
    // 确定目标名称，处理重名
    final parentKey = targetParentSyncId ?? '';
    var targetName = sourceFolder.name;
    var suffix = 1;
    while (true) {
      final candidateKey = '$parentKey|$targetName|${type.name}';
      final exists = objectbox.comicFolderBox
          .query(ComicFolder_.uniqueKey.equals(candidateKey))
          .build()
          .findFirst();
      if (exists == null) break;
      suffix++;
      targetName = '${sourceFolder.name} ($suffix)';
    }

    // 创建目标文件夹
    final targetFolder = ComicFolder(
      syncId: _newSyncId,
      parentSyncId: targetParentSyncId,
      uniqueKey: '$parentKey|$targetName|${type.name}',
      name: targetName,
      typeData: type.name,
      versionVectorJson: _encodeVersionVector({_deviceId: 1}),
      createdAt: now,
      updatedAt: now,
    );
    objectbox.comicFolderBox.put(targetFolder);

    // 复制当前文件夹下的链接
    final linkQuery = objectbox.comicLinkBox
        .query(
          ComicLink_.typeData
              .equals(type.name)
              .and(ComicLink_.deletedAt.isNull())
              .and(ComicLink_.folderSyncId.equals(sourceFolder.syncId)),
        )
        .build();
    try {
      final links = linkQuery.find();
      for (final link in links) {
        objectbox.comicLinkBox.put(
          ComicLink(
            uniqueKey:
                '${link.comicUniqueKey}|${targetFolder.syncId}|${type.name}',
            comicUniqueKey: link.comicUniqueKey,
            folderSyncId: targetFolder.syncId,
            typeData: type.name,
            versionVectorJson: _encodeVersionVector({_deviceId: 1}),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    } finally {
      linkQuery.close();
    }

    // 递归复制子文件夹
    final childQuery = objectbox.comicFolderBox
        .query(
          ComicFolder_.typeData
              .equals(type.name)
              .and(ComicFolder_.deletedAt.isNull())
              .and(ComicFolder_.parentSyncId.equals(sourceFolder.syncId)),
        )
        .build();
    try {
      final children = childQuery.find();
      for (final child in children) {
        _copyFolderRecursive(child, targetFolder.syncId, type, now);
      }
    } finally {
      childQuery.close();
    }
  }

  static Set<String> _collectSubtreeSyncIds(
    String rootSyncId,
    ComicFolderType type,
  ) {
    final result = <String>{rootSyncId};
    final queue = [rootSyncId];
    while (queue.isNotEmpty) {
      final parentId = queue.removeLast();
      final query = objectbox.comicFolderBox
          .query(
            ComicFolder_.typeData
                .equals(type.name)
                .and(ComicFolder_.deletedAt.isNull())
                .and(ComicFolder_.parentSyncId.equals(parentId)),
          )
          .build();
      try {
        final children = query.find();
        for (final child in children) {
          if (result.add(child.syncId)) queue.add(child.syncId);
        }
      } finally {
        query.close();
      }
    }
    return result;
  }
}
