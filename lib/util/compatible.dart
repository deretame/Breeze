// 用来提供兼容操作的

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/get_path.dart';

Future<void> compatibleInit() async {
  final basePath = await getFilePath();
  final compatiblePath = p.join(basePath, 'compatible');
  // 检查目录是否存在，如果不存在则创建
  if (!await Directory(compatiblePath).exists()) {
    await Directory(compatiblePath).create(recursive: true);
  }
  final data = {"compatible_version": "v1"}.let(jsonEncode);
  final compatibleFile = File(p.join(compatiblePath, 'compatible.json'));
  await compatibleFile.writeAsString(data);

  // 兼容历史目录结构：jm/<comicId> -> jm/original/<comicId>
  await _migrateLegacyJmDownloadPath();
}

/// 迁移旧版 JM 下载目录到新版目录结构。
///
/// 旧版: `downloads/jm/<comicId>`
/// 新版: `downloads/jm/original/<comicId>`
Future<void> _migrateLegacyJmDownloadPath() async {
  final downloadPath = await getDownloadPath();
  final jmPath = p.join(downloadPath, 'jm');
  final jmDir = Directory(jmPath);
  if (!await jmDir.exists()) {
    return;
  }

  final originalDir = Directory(p.join(jmPath, 'original'));
  if (!await originalDir.exists()) {
    await originalDir.create(recursive: true);
  }

  final entities = await jmDir.list(followLinks: false).toList();
  for (final entity in entities) {
    if (entity is! Directory) {
      continue;
    }

    final name = p.basename(entity.path);
    if (name == 'original') {
      continue;
    }

    // 只迁移纯数字目录，避免误处理非漫画目录。
    if (!_isLegacyComicIdDir(name)) {
      continue;
    }

    final targetPath = p.join(originalDir.path, name);
    await _moveDirectory(entity, Directory(targetPath));
  }
}

bool _isLegacyComicIdDir(String name) {
  return RegExp(r'^\d+$').hasMatch(name);
}

/// 将 source 目录移动到 target。
///
/// - target 不存在：直接 rename（最快）
/// - target 已存在：递归合并，避免覆盖目标已存在文件
Future<void> _moveDirectory(Directory source, Directory target) async {
  if (!await source.exists()) {
    return;
  }

  if (!await target.exists()) {
    await source.rename(target.path);
    return;
  }

  final entities = await source.list(followLinks: false).toList();
  for (final entity in entities) {
    final entityName = p.basename(entity.path);
    final targetEntityPath = p.join(target.path, entityName);

    if (entity is Directory) {
      await _moveDirectory(entity, Directory(targetEntityPath));
    } else if (entity is File) {
      final targetFile = File(targetEntityPath);
      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }
      if (!await targetFile.exists()) {
        await entity.rename(targetEntityPath);
      } else {
        // 目标已有同名文件，保留目标文件，删除旧文件。
        await entity.delete();
      }
    }
  }

  // 合并后如果源目录为空，清理空目录。
  if ((await source.list(followLinks: false).toList()).isEmpty) {
    await source.delete(recursive: true);
  }
}
