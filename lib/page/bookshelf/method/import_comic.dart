import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/bookshelf/service/comic_link_service.dart';
import 'package:zephyr/src/rust/api/data_backup.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/util/get_path.dart';

const String _kProcessedComicInfoFile = 'processed_comic_info.json';
const String _kVersionValue = 'v2';
const List<String> _kOriginalInfoFileCandidates = [
  'original_comic_info.json',
  'comic_info.json',
];

/// 导入漫画的结果。
class ComicImportResult {
  const ComicImportResult({
    required this.comicId,
    required this.title,
    required this.source,
  });

  final String comicId;
  final String title;
  final String source;
}

/// 漫画导入被用户取消（例如已存在且用户选择不覆盖）。
class ComicImportCancelledException implements Exception {
  ComicImportCancelledException([String? message])
    : message = message ?? t.bookshelf.importCancelled;

  final String message;

  @override
  String toString() => message;
}

/// 从文件夹导入漫画。
///
/// 文件夹内必须包含原始漫画信息 JSON（[original_comic_info.json] 或旧版的
/// [comic_info.json]）以及 [processed_comic_info.json]。
///
/// 当目标漫画已存在时，会调用 [onConfirmOverwrite] 询问用户是否覆盖。
/// 若用户取消或回调返回 false，则抛出 [ComicImportCancelledException]。
Future<ComicImportResult> importComicFromDirectory(
  String importDir, {
  Future<bool> Function(String title)? onConfirmOverwrite,
}) async {
  final originalFile = await _resolveOriginalInfoFile(importDir);
  final processedFile = File(p.join(importDir, _kProcessedComicInfoFile));

  if (originalFile == null || !await processedFile.exists()) {
    throw StateError(t.bookshelf.importMissingJson);
  }

  final originalJson =
      jsonDecode(await originalFile.readAsString()) as Map<String, dynamic>;
  final processedJson =
      jsonDecode(await processedFile.readAsString()) as Map<String, dynamic>;

  return _importComic(
    originalJson,
    processedJson,
    importDir,
    onConfirmOverwrite: onConfirmOverwrite,
  );
}

/// 查找原始漫画信息 JSON 文件。
///
/// 优先 [original_comic_info.json]，兼容旧版 zip 导出的 [comic_info.json]。
Future<File?> _resolveOriginalInfoFile(String importDir) async {
  for (final name in _kOriginalInfoFileCandidates) {
    final file = File(p.join(importDir, name));
    if (await file.exists()) {
      return file;
    }
  }
  return null;
}

/// 从 zip 压缩包导入漫画。
///
/// 会先解压到临时目录，导入完成后删除临时目录。
///
/// [cleanupDir] 可选，导入完成后会一并删除该目录，用于清理 Android
/// 原生选择器拷贝到缓存的 zip 目录。
///
/// 当目标漫画已存在时，会调用 [onConfirmOverwrite] 询问用户是否覆盖。
Future<ComicImportResult> importComicFromZip(
  String zipPath, {
  String? cleanupDir,
  Future<bool> Function(String title)? onConfirmOverwrite,
}) async {
  final tempDir = await Directory.systemTemp.createTemp('comic_import_');
  try {
    await extractDataBackupZip(zipPath: zipPath, extractDir: tempDir.path);

    // zip 可能直接包含两个 JSON 文件，也可能再包一层漫画目录。
    final comicDir = await _resolveComicImportRoot(tempDir.path);
    return await importComicFromDirectory(
      comicDir,
      onConfirmOverwrite: onConfirmOverwrite,
    );
  } finally {
    try {
      await tempDir.delete(recursive: true);
      if (cleanupDir != null && cleanupDir.isNotEmpty) {
        await Directory(cleanupDir).delete(recursive: true);
      }
    } catch (e) {
      logger.w('删除导入临时目录失败: $e');
    }
  }
}

const _filePickerChannel = MethodChannel('com.zephyr.breeze/file_picker');

/// Android 原生选择 zip 文件并直接拷贝到应用缓存目录。
///
/// 返回缓存中的 zip 路径；用户取消时返回 null。
Future<String?> pickComicZipAndroid() async {
  final cachePath = await getCachePath();
  final cacheDir = Directory(
    p.join(
      cachePath,
      'comic_import',
      DateTime.now().millisecondsSinceEpoch.toString(),
    ),
  );
  final cacheZipFile = File(p.join(cacheDir.path, 'zip', 'comic.zip'));
  await cacheZipFile.parent.create(recursive: true);

  final result = await _filePickerChannel.invokeMethod<String>(
    'pickBackupZip',
    {'destPath': cacheZipFile.path},
  );
  if (result == null) {
    try {
      await cacheDir.delete(recursive: true);
    } catch (_) {}
  }
  return result;
}

/// 在解压目录中定位漫画根目录。
///
/// 如果根目录下已有必要的 JSON 文件，则直接返回；否则查找唯一一个同时包含
/// 原始信息 JSON 与 processed JSON 的子目录。
Future<String> _resolveComicImportRoot(String extractDir) async {
  final root = Directory(extractDir);
  if (await _containsImportJson(root.path)) {
    return root.path;
  }

  final candidates = <String>[];
  await for (final entry in root.list()) {
    if (entry is Directory && await _containsImportJson(entry.path)) {
      candidates.add(entry.path);
    }
  }

  if (candidates.isEmpty) {
    throw StateError(t.bookshelf.importNoComicDir);
  }
  if (candidates.length > 1) {
    throw StateError(t.bookshelf.importMultipleComicDirs);
  }
  return candidates.first;
}

Future<bool> _containsImportJson(String dir) async {
  final originalFile = await _resolveOriginalInfoFile(dir);
  if (originalFile == null) return false;
  return await File(p.join(dir, _kProcessedComicInfoFile)).exists();
}

Future<ComicImportResult> _importComic(
  Map<String, dynamic> originalJson,
  Map<String, dynamic> processedJson,
  String importDir, {
  Future<bool> Function(String title)? onConfirmOverwrite,
}) async {
  final version = _readVersion(originalJson);
  if (version != _kVersionValue) {
    throw StateError(t.bookshelf.importVersionUnsupported);
  }

  final source = _readSource(originalJson);
  processedJson = await _normalizeProcessedJson(
    originalJson: originalJson,
    processedJson: processedJson,
    importDir: importDir,
  );

  final comicInfo = Map<String, dynamic>.from(
    originalJson['comicInfo'] as Map? ?? const <String, dynamic>{},
  );
  final comicId = comicInfo['id']?.toString() ?? '';

  if (source.isEmpty) {
    throw StateError(t.bookshelf.importMissingSource);
  }
  if (comicId.isEmpty) {
    throw StateError(t.bookshelf.importMissingComicId);
  }

  final from = source;
  final uniqueKey = '$from:$comicId';
  final title = comicInfo['title']?.toString() ?? '';

  final downloadPath = await getDownloadPath();
  final storageRoot = p.join(downloadPath, from, 'original', comicId);
  final targetComicDir = p.join(
    downloadPath,
    from,
    'original',
    encodePath(path: comicId),
  );

  // 先检查是否已存在，让用户决定是否覆盖，避免先把图片复制到磁盘后再取消。
  final existing = objectbox.unifiedDownloadBox
      .query(UnifiedComicDownload_.uniqueKey.equals(uniqueKey))
      .build()
      .find();
  if (existing.isNotEmpty) {
    final shouldOverwrite = await onConfirmOverwrite?.call(title) ?? false;
    if (!shouldOverwrite) {
      throw ComicImportCancelledException(
        t.bookshelf.importComicExistsUncovered(title: title),
      );
    }
  }

  // 复制封面与章节图片。
  await _importCover(
    originalJson: originalJson,
    importDir: importDir,
    targetComicDir: targetComicDir,
  );
  await _importChapters(
    originalJson: originalJson,
    processedJson: processedJson,
    importDir: importDir,
    targetComicDir: targetComicDir,
  );

  // 重建 chapters 与 detailJson。
  final newChapters = _buildChapters(
    originalJson: originalJson,
    processedJson: processedJson,
  );
  final newDetailJson = _buildDetailJson(
    originalJson: originalJson,
    processedJson: processedJson,
  );

  // 写入数据库。
  final now = DateTime.now().toUtc();
  final entity = UnifiedComicDownload(
    uniqueKey: uniqueKey,
    source: from,
    comicId: comicId,
    title: title,
    description: comicInfo['description']?.toString() ?? '',
    cover: jsonEncode(comicInfo['cover'] ?? const <String, dynamic>{}),
    creator: jsonEncode(comicInfo['creator'] ?? const <String, dynamic>{}),
    titleMeta: jsonEncode(comicInfo['titleMeta'] ?? const <dynamic>[]),
    metadata: jsonEncode(comicInfo['metadata'] ?? const <dynamic>[]),
    totalViews: _toInt(comicInfo['totalViews']),
    totalLikes: _toInt(comicInfo['totalLikes']),
    totalComments: _toInt(comicInfo['totalComments']),
    isFavourite: comicInfo['isFavourite'] ?? false,
    isLiked: comicInfo['isLiked'] ?? false,
    allowComment: comicInfo['allowComments'] ?? true,
    allowLike: comicInfo['allowLike'] ?? true,
    allowFavorite: comicInfo['allowCollected'] ?? true,
    allowDownload: comicInfo['allowDownload'] ?? true,
    chapters: jsonEncode(newChapters),
    detailJson: jsonEncode(newDetailJson),
    storageRoot: storageRoot,
    createdAt: now,
    updatedAt: now,
    downloadedAt: now,
    deleted: false,
    schemaVersion: 2,
  );

  if (existing.isNotEmpty) {
    objectbox.unifiedDownloadBox.removeMany(existing.map((e) => e.id).toList());
  }

  objectbox.unifiedDownloadBox.put(entity);
  ComicLinkService.addComic(uniqueKey, null, ComicFolderType.download);

  // 导入/覆盖导入后更新 ComicLink 的创建/更新时间，使漫画在书架排序中体现为最新。
  final nowMillis = DateTime.now().toUtc().millisecondsSinceEpoch;
  final links = ComicLinkService.linksOfComic(
    uniqueKey,
    ComicFolderType.download,
  );
  for (final link in links) {
    link
      ..createdAt = nowMillis
      ..updatedAt = nowMillis;
    objectbox.comicLinkBox.put(link);
  }

  return ComicImportResult(comicId: comicId, title: title, source: source);
}

String _readVersion(Map<String, dynamic> json) {
  final extern = Map<String, dynamic>.from(json['extern'] as Map? ?? const {});
  return extern['version']?.toString() ?? '';
}

String _readSource(Map<String, dynamic> json) {
  final extern = Map<String, dynamic>.from(json['extern'] as Map? ?? const {});
  return extern['source']?.toString() ?? '';
}

Future<void> _importCover({
  required Map<String, dynamic> originalJson,
  required String importDir,
  required String targetComicDir,
}) async {
  final originalCover = _readCover(originalJson);
  if (originalCover == null) return;

  final originalCoverPath = originalCover['path']?.toString() ?? '';
  if (originalCoverPath.isEmpty) return;

  final coverExt = await _detectCoverExtension(importDir);
  if (coverExt == null) {
    logger.w('导入漫画时未找到封面文件');
    return;
  }

  final sourceCoverPath = p.join(importDir, 'cover$coverExt');
  final sourceFile = File(sourceCoverPath);
  if (!await sourceFile.exists()) {
    logger.w('导入漫画时封面文件不存在: $sourceCoverPath');
    return;
  }

  final targetCoverFileName = encodePath(path: originalCoverPath);
  final targetCoverPath = p.join(targetComicDir, targetCoverFileName);

  await Directory(targetComicDir).create(recursive: true);
  await sourceFile.copy(targetCoverPath);
}

Future<String?> _detectCoverExtension(String importDir) async {
  final dir = Directory(importDir);
  await for (final entry in dir.list()) {
    if (entry is File) {
      final name = p.basename(entry.path).toLowerCase();
      if (name.startsWith('cover.')) {
        return p.extension(entry.path);
      }
    }
  }
  return null;
}

Future<void> _importChapters({
  required Map<String, dynamic> originalJson,
  required Map<String, dynamic> processedJson,
  required String importDir,
  required String targetComicDir,
}) async {
  final originalChapters = _readDownloadChapters(originalJson);
  final processedChapters = _readDownloadChapters(processedJson);
  final processedEps = _readEps(processedJson);

  final count = processedChapters.length;
  for (var i = 0; i < count; i++) {
    final originalChapter = i < originalChapters.length
        ? originalChapters[i]
        : const <String, dynamic>{};
    final processedChapter = processedChapters[i];
    final processedEp = i < processedEps.length
        ? processedEps[i]
        : const <String, dynamic>{};

    final storageKey = _chapterStorageKey(originalChapter);
    final targetChapterDirName = encodePath(path: storageKey);
    final targetChapterDir = p.join(targetComicDir, targetChapterDirName);

    final exportFolderName =
        processedEp['name']?.toString() ??
        processedChapter['name']?.toString() ??
        '';
    if (exportFolderName.isEmpty) {
      logger.w('导入漫画时第 $i 个章节缺少导出文件夹名，跳过');
      continue;
    }

    final originalImages = _readImages(originalChapter);
    final processedImages = _readImages(processedChapter);

    final imageCount = processedImages.length;
    for (var j = 0; j < imageCount; j++) {
      final originalImage = j < originalImages.length
          ? originalImages[j]
          : const <String, dynamic>{};
      final processedImage = processedImages[j];

      final originalImagePath =
          originalImage['path']?.toString() ??
          processedImage['path']?.toString() ??
          '';
      if (originalImagePath.isEmpty) {
        logger.w('导入漫画时第 $i 章第 $j 张图缺少原始 path，跳过');
        continue;
      }

      final exportFileName =
          processedImage['name']?.toString() ??
          processedImage['path']?.toString() ??
          '';
      if (exportFileName.isEmpty) {
        logger.w('导入漫画时第 $i 章第 $j 张图缺少导出文件名，跳过');
        continue;
      }

      final sourceImagePath = exportFolderName.isEmpty
          ? p.join(importDir, exportFileName)
          : p.join(importDir, exportFolderName, exportFileName);
      final sourceFile = File(sourceImagePath);
      if (!await sourceFile.exists()) {
        logger.w('导入漫画时源图片不存在: $sourceImagePath');
        continue;
      }

      final targetImageFileName = encodePath(path: originalImagePath);
      final targetImagePath = p.join(targetChapterDir, targetImageFileName);

      await Directory(targetChapterDir).create(recursive: true);
      await sourceFile.copy(targetImagePath);
    }
  }
}

List<Map<String, dynamic>> _buildChapters({
  required Map<String, dynamic> originalJson,
  required Map<String, dynamic> processedJson,
}) {
  final result = <Map<String, dynamic>>[];
  final originalChapters = _readDownloadChapters(originalJson);
  final processedChapters = _readDownloadChapters(processedJson);

  final count = processedChapters.length;
  for (var i = 0; i < count; i++) {
    final originalChapter = i < originalChapters.length
        ? originalChapters[i]
        : const <String, dynamic>{};
    final processedChapter = processedChapters[i];

    final storageKey = _chapterStorageKey(originalChapter);
    final originalImages = _readImages(originalChapter);
    final processedImages = _readImages(processedChapter);

    final images = <Map<String, dynamic>>[];
    final imageCount = processedImages.length;
    for (var j = 0; j < imageCount; j++) {
      final originalImage = j < originalImages.length
          ? originalImages[j]
          : const <String, dynamic>{};
      final processedImage = processedImages[j];

      final originalImagePath =
          originalImage['path']?.toString() ??
          processedImage['path']?.toString() ??
          '';
      if (originalImagePath.isEmpty) continue;

      images.add({
        ...originalImage,
        'name':
            processedImage['name']?.toString() ??
            processedImage['path']?.toString() ??
            originalImage['name']?.toString() ??
            '',
        'path': originalImagePath,
      });
    }

    result.add({
      ...originalChapter,
      'name':
          processedChapter['name']?.toString() ??
          originalChapter['name']?.toString() ??
          '',
      'order': processedChapter['order'] ?? originalChapter['order'] ?? (i + 1),
      'id': storageKey,
      'storageChapterId': storageKey,
      'images': images,
    });
  }

  return result;
}

Map<String, dynamic> _buildDetailJson({
  required Map<String, dynamic> originalJson,
  required Map<String, dynamic> processedJson,
}) {
  final detail = _deepCopyMap(originalJson);

  // 更新 eps 的 name/order。
  final originalEps = _readEps(detail);
  final processedEps = _readEps(processedJson);
  final newEps = <Map<String, dynamic>>[];
  for (var i = 0; i < processedEps.length; i++) {
    final originalEp = i < originalEps.length
        ? originalEps[i]
        : const <String, dynamic>{};
    final processedEp = processedEps[i];
    newEps.add({
      ...originalEp,
      'name':
          processedEp['name']?.toString() ??
          originalEp['name']?.toString() ??
          '',
      'order': processedEp['order'] ?? originalEp['order'] ?? (i + 1),
    });
  }
  detail['eps'] = newEps;

  // 更新 extern.downloadChapters。
  final originalExtern = Map<String, dynamic>.from(
    detail['extern'] as Map? ?? const <String, dynamic>{},
  );
  final originalDownloadChapters = _readDownloadChapters(detail);
  final processedDownloadChapters = _readDownloadChapters(processedJson);
  final newDownloadChapters = <Map<String, dynamic>>[];

  for (var i = 0; i < processedDownloadChapters.length; i++) {
    final originalChapter = i < originalDownloadChapters.length
        ? originalDownloadChapters[i]
        : const <String, dynamic>{};
    final processedChapter = processedDownloadChapters[i];

    final originalImages = _readImages(originalChapter);
    final processedImages = _readImages(processedChapter);
    final newImages = <Map<String, dynamic>>[];

    for (var j = 0; j < processedImages.length; j++) {
      final originalImage = j < originalImages.length
          ? originalImages[j]
          : const <String, dynamic>{};
      final processedImage = processedImages[j];

      final originalImagePath =
          originalImage['path']?.toString() ??
          processedImage['path']?.toString() ??
          '';
      if (originalImagePath.isEmpty) continue;

      newImages.add({
        ...originalImage,
        'name':
            processedImage['name']?.toString() ??
            processedImage['path']?.toString() ??
            originalImage['name']?.toString() ??
            '',
        'path': originalImagePath,
      });
    }

    newDownloadChapters.add({
      ...originalChapter,
      'name':
          processedChapter['name']?.toString() ??
          originalChapter['name']?.toString() ??
          '',
      'order': processedChapter['order'] ?? originalChapter['order'] ?? (i + 1),
      'images': newImages,
    });
  }

  originalExtern['downloadChapters'] = newDownloadChapters;
  detail['extern'] = originalExtern;

  return detail;
}

String _chapterStorageKey(Map<String, dynamic> chapter) {
  final storageChapterId = chapter['storageChapterId']?.toString() ?? '';
  if (storageChapterId.isNotEmpty) return storageChapterId;
  final id = chapter['id']?.toString() ?? '';
  if (id.isNotEmpty) return id;
  final logicalKey = chapter['logicalKey']?.toString() ?? '';
  if (logicalKey.isNotEmpty) return logicalKey;
  return chapter['taskChapterId']?.toString() ?? '';
}

Map<String, dynamic>? _readCover(Map<String, dynamic> json) {
  final comicInfo = json['comicInfo'] as Map?;
  if (comicInfo == null) return null;
  final cover = comicInfo['cover'] as Map?;
  if (cover == null) return null;
  return Map<String, dynamic>.from(cover);
}

List<Map<String, dynamic>> _readEps(Map<String, dynamic> json) {
  final list = (json['eps'] as List?) ?? const [];
  return list
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

List<Map<String, dynamic>> _readDownloadChapters(Map<String, dynamic> json) {
  final extern = Map<String, dynamic>.from(json['extern'] as Map? ?? const {});
  final list = (extern['downloadChapters'] as List?) ?? const [];
  return list
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

List<Map<String, dynamic>> _readImages(Map<String, dynamic> chapter) {
  final list = (chapter['images'] as List?) ?? const [];
  return list
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

/// 规范化 [processedJson]，确保 [extern.downloadChapters] 包含可用的图片信息。
///
/// 某些导出包（或旧版本导出）中 [processed_comic_info.json] 的
/// [downloadChapters] 可能为空或缺少 [images]。此时尝试：
/// 1. 从 [originalJson] 复制 downloadChapters；
/// 2. 扫描 [importDir] 中的子目录/图片文件补全。
Future<Map<String, dynamic>> _normalizeProcessedJson({
  required Map<String, dynamic> originalJson,
  required Map<String, dynamic> processedJson,
  required String importDir,
}) async {
  final processedExtern = Map<String, dynamic>.from(
    processedJson['extern'] as Map? ?? const <String, dynamic>{},
  );

  var downloadChapters = _readDownloadChapters(processedJson);

  // 1. 如果 processed 没有章节信息，尝试从 original 复制。
  if (downloadChapters.isEmpty) {
    downloadChapters = _readDownloadChapters(originalJson);
  }

  // 2. 仍然为空则扫描磁盘目录结构。
  if (downloadChapters.isEmpty) {
    downloadChapters = await _scanDirectoryChapters(importDir);
  }

  // 3. 确保每个章节都有图片列表；缺失时扫描对应文件夹。
  final eps = _readEps(processedJson).isNotEmpty
      ? _readEps(processedJson)
      : _readEps(originalJson);
  final chapterDirNames = await _listChapterDirNames(importDir);
  final normalizedChapters = <Map<String, dynamic>>[];

  for (var i = 0; i < downloadChapters.length; i++) {
    final chapter = downloadChapters[i];
    var images = _readImages(chapter);
    var folderName = chapter['name']?.toString() ?? '';

    if (images.isEmpty) {
      // 依次尝试：chapter 自身 name、eps 对应 name、实际扫描到的第 i 个目录。
      final candidateNames = <String>[
        if (folderName.isNotEmpty) folderName,
        if (i < eps.length && eps[i]['name']?.toString().isNotEmpty == true)
          eps[i]['name']!.toString(),
        if (i < chapterDirNames.length) chapterDirNames[i],
      ];

      for (final name in candidateNames) {
        images = await _scanImageEntries(p.join(importDir, name));
        if (images.isNotEmpty) {
          folderName = name;
          break;
        }
      }

      // 单章且没有子目录时，退一步扫描漫画根目录。
      if (images.isEmpty && downloadChapters.length == 1) {
        images = await _scanImageEntries(importDir);
      }
    }

    final ep = i < eps.length ? eps[i] : null;
    normalizedChapters.add({
      ...chapter,
      'name': folderName.isNotEmpty
          ? folderName
          : ep?['name']?.toString() ??
                t.bookshelf.importEpisodeFallback(index: i + 1),
      'order': chapter['order'] ?? ep?['order'] ?? (i + 1),
      'images': images,
    });
  }

  processedExtern['downloadChapters'] = normalizedChapters;
  final result = Map<String, dynamic>.from(processedJson);
  result['extern'] = processedExtern;
  return result;
}

/// 扫描 [importDir] 中的子目录，将每个子目录视为一个章节。
///
/// 若没有子目录（除封面文件外），返回一个代表根目录的单章。
Future<List<Map<String, dynamic>>> _scanDirectoryChapters(
  String importDir,
) async {
  final dir = Directory(importDir);
  if (!await dir.exists()) return const [];

  final entries = await dir.list().toList();
  final chapterDirs = entries.whereType<Directory>().where((d) {
    final name = p.basename(d.path);
    return name != '__MACOSX' && !name.startsWith('.');
  }).toList();

  chapterDirs.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

  if (chapterDirs.isEmpty) {
    return [
      {'name': '', 'order': 1, 'images': <Map<String, dynamic>>[]},
    ];
  }

  return chapterDirs
      .asMap()
      .entries
      .map(
        (e) => {
          'name': p.basename(e.value.path),
          'order': e.key + 1,
          'images': <Map<String, dynamic>>[],
        },
      )
      .toList();
}

/// 扫描 [dir] 中的图片文件，返回按文件名排序的图片元数据列表。
/// 列出 [importDir] 下可作为章节目录的子目录名（按字典序）。
Future<List<String>> _listChapterDirNames(String importDir) async {
  final dir = Directory(importDir);
  if (!await dir.exists()) return const [];

  final entries = await dir.list().toList();
  final names = entries
      .whereType<Directory>()
      .where((d) {
        final name = p.basename(d.path);
        return name != '__MACOSX' && !name.startsWith('.');
      })
      .map((d) => p.basename(d.path))
      .toList();

  names.sort();
  return names;
}

Future<List<Map<String, dynamic>>> _scanImageEntries(String dir) async {
  final directory = Directory(dir);
  if (!await directory.exists()) return const [];

  final entries = await directory.list().toList();
  final imageFiles = entries.whereType<File>().where((f) {
    final ext = p.extension(f.path).toLowerCase();
    return ext == '.jpg' ||
        ext == '.jpeg' ||
        ext == '.png' ||
        ext == '.webp' ||
        ext == '.gif' ||
        ext == '.bmp';
  }).toList();

  imageFiles.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));

  return imageFiles
      .map((f) => {'name': p.basename(f.path), 'path': p.basename(f.path)})
      .toList();
}

Map<String, dynamic> _deepCopyMap(Map<String, dynamic> map) {
  return jsonDecode(jsonEncode(map)) as Map<String, dynamic>;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
