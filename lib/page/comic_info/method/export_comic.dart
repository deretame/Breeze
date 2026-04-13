import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

import 'package:path/path.dart' as p;
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/src/rust/compressed/compressed.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/widgets/toast.dart';
import 'package:zephyr/type/enum.dart';

const Set<String> _kWindowsReservedNames = {
  'CON',
  'PRN',
  'AUX',
  'NUL',
  'COM1',
  'COM2',
  'COM3',
  'COM4',
  'COM5',
  'COM6',
  'COM7',
  'COM8',
  'COM9',
  'LPT1',
  'LPT2',
  'LPT3',
  'LPT4',
  'LPT5',
  'LPT6',
  'LPT7',
  'LPT8',
  'LPT9',
};

Future<void> exportComic(
  String comicId,
  ExportType type,
  String from, {
  String? path,
}) {
  if (type == ExportType.folder) {
    return _exportComicAsFolder(comicId, from: from, exportPath: path);
  }
  return _exportComicAsZip(comicId, from: from, exportPath: path);
}

Future<void> _exportComicAsFolder(
  String comicId, {
  required String from,
  String? exportPath,
}) async {
  final download = _getDownload(comicId, from: from);
  final detail = _exportDetail(download);
  final chapterEntries = await _collectChapterEntries(download);
  final processedDetail = _buildProcessedDetail(detail, chapterEntries);
  final title = download.title;
  final safeTitle = _sanitizeFolderName(title, fallback: comicId);
  final root = exportPath ?? await createDownloadDir();
  final comicDir = p.join(root, safeTitle);

  final dir = Directory(comicDir);
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
  await dir.create(recursive: true);

  await File(
    p.join(comicDir, 'original_comic_info.json'),
  ).writeAsString(jsonEncode(detail));
  await File(
    p.join(comicDir, 'processed_comic_info.json'),
  ).writeAsString(jsonEncode(processedDetail));

  await _exportCover(download, comicDir, comicId, from: from);
  await _copyEpisodeFiles(chapterEntries, comicDir);

  showSuccessToast('漫画$title导出为文件夹完成');
}

Future<void> _exportComicAsZip(
  String comicId, {
  required String from,
  String? exportPath,
}) async {
  final download = _getDownload(comicId, from: from);
  final detail = _exportDetail(download);
  final chapterEntries = await _collectChapterEntries(download);
  final processedDetail = _buildProcessedDetail(detail, chapterEntries);
  final title = download.title;
  final safeTitle = _sanitizeFolderName(title, fallback: comicId);
  final finalZipPath =
      exportPath ??
      '${p.join(await createDownloadDir(), safeTitle.substring(0, min(safeTitle.length, 90)))}.zip';

  final packInfo = PackInfo(
    comicInfoString: jsonEncode(detail),
    processedComicInfoString: jsonEncode(processedDetail),
    originalImagePaths: [],
    packImagePaths: [],
  );

  final coverPath = await _tryDownloadCover(download, comicId, from: from);
  if (coverPath != null) {
    packInfo.originalImagePaths.add(coverPath);
    packInfo.packImagePaths.add('cover.jpg');
  }

  for (final chapter in chapterEntries) {
    for (final image in chapter.images) {
      packInfo.originalImagePaths.add(image.source.path);
      packInfo.packImagePaths.add(
        p.join(chapter.folderName, image.exportFileName),
      );
    }
  }

  await packFolderZip(destPath: finalZipPath, packInfo: packInfo);
  showSuccessToast('漫画$title导出为 zip 完成');
}

UnifiedComicDownload _getDownload(String comicId, {required String from}) {
  final exact = objectbox.unifiedDownloadBox
      .query(UnifiedComicDownload_.uniqueKey.equals('$from:$comicId'))
      .build()
      .findFirst();
  if (exact != null) {
    return exact;
  }

  final fallback = objectbox.unifiedDownloadBox
      .query(UnifiedComicDownload_.comicId.equals(comicId))
      .build()
      .findFirst();
  if (fallback != null) {
    return fallback;
  }
  throw StateError('未找到可导出的下载漫画: $comicId');
}

Map<String, dynamic> _exportDetail(UnifiedComicDownload download) {
  final detail = Map<String, dynamic>.from(
    jsonDecode(download.detailJson) as Map<String, dynamic>,
  );
  final extension = Map<String, dynamic>.from(
    detail['extension'] as Map? ?? const <String, dynamic>{},
  );
  extension['version'] = mainVersion;
  detail['extension'] = extension;
  return detail;
}

Future<void> _exportCover(
  UnifiedComicDownload download,
  String comicDir,
  String comicId, {
  required String from,
}) async {
  final path = await _tryDownloadCover(download, comicId, from: from);
  if (path == null) {
    return;
  }
  final coverFile = File(p.join(comicDir, 'cover.jpg'));
  await coverFile.create(recursive: true);
  await File(path).copy(coverFile.path);
}

Future<String?> _tryDownloadCover(
  UnifiedComicDownload download,
  String comicId, {
  required String from,
}) async {
  final cover = _decodeMap(download.cover);
  final ext = Map<String, dynamic>.from(
    cover['extension'] as Map? ?? const <String, dynamic>{},
  );
  final url = cover['url']?.toString() ?? '';
  final path = ext['path']?.toString() ?? '$comicId.jpg';
  if (url.isEmpty && path.isEmpty) {
    return null;
  }
  try {
    return await downloadPicture(
      from: from,
      url: url,
      path: path,
      cartoonId: comicId,
      pictureType: PictureType.cover,
    );
  } catch (_) {
    return null;
  }
}

Future<void> _copyEpisodeFiles(
  List<_ExportChapterEntry> chapterEntries,
  String comicDir,
) async {
  for (final chapter in chapterEntries) {
    final chapterDir = Directory(p.join(comicDir, chapter.folderName));
    await chapterDir.create(recursive: true);
    for (final image in chapter.images) {
      final target = File(p.join(chapterDir.path, image.exportFileName));
      await target.create(recursive: true);
      await image.source.copy(target.path);
    }
  }
}

Future<List<_ExportChapterEntry>> _collectChapterEntries(
  UnifiedComicDownload download,
) async {
  var chapters = resolveStoredDownloadChapters(download);
  if (chapters.isEmpty) {
    chapters = _decodeListOfMaps(download.chapters)
        .map((chapter) => UnifiedComicDownloadStoredChapter.fromMap(chapter))
        .toList();
  }
  chapters.sort((a, b) {
    final orderCompare = a.order.compareTo(b.order);
    if (orderCompare != 0) {
      return orderCompare;
    }
    final nameCompare = _naturalCompareString(a.name, b.name);
    if (nameCompare != 0) {
      return nameCompare;
    }
    return _naturalCompareString(a.id, b.id);
  });

  final chapterRoot = await _chapterRoot(download);
  final chapterRootLegacy = await _chapterRootLegacy(download);
  final usedFolderNames = <String>{};
  final result = <_ExportChapterEntry>[];
  final hasMultipleChapters = chapters.length > 1;

  for (var chapterIndex = 0; chapterIndex < chapters.length; chapterIndex++) {
    final chapter = chapters[chapterIndex];
    final chapterId = chapter.id.trim();
    final rawName = chapter.name.trim();
    final fallbackName = chapterId.isNotEmpty
        ? chapterId
        : chapter.order.toString();
    final chapterPrefix = hasMultipleChapters ? '${chapterIndex + 1}.' : '';
    final folderName = _uniqueFolderName(
      '$chapterPrefix${_sanitizeFolderName(rawName.isNotEmpty ? rawName : fallbackName)}',
      usedFolderNames,
    );
    usedFolderNames.add(folderName);

    final files = await _resolveChapterFiles(
      pluginId: download.source,
      comicId: download.comicId,
      chapterId: chapterId,
      chapterRoot: chapterRoot,
      chapterRootLegacy: chapterRootLegacy,
      images: chapter.images,
    );
    final numberedImages = <_ExportImageEntry>[];
    final numberWidth = files.length.toString().length;
    for (var imageIndex = 0; imageIndex < files.length; imageIndex++) {
      final file = files[imageIndex];
      final indexLabel = (imageIndex + 1).toString().padLeft(numberWidth, '0');
      final extension = _safeExportExtension(file.path);
      numberedImages.add(
        _ExportImageEntry(
          source: file,
          exportFileName: '$indexLabel$extension',
        ),
      );
    }
    result.add(
      _ExportChapterEntry(folderName: folderName, images: numberedImages),
    );
  }

  return result;
}

Future<List<File>> _resolveChapterFiles({
  required String pluginId,
  required String comicId,
  required String chapterId,
  required String chapterRoot,
  required String chapterRootLegacy,
  required List<UnifiedComicDownloadImage> images,
}) async {
  final ordered = <File>[];
  for (final image in images) {
    if (image.id.trim().isEmpty) {
      continue;
    }
    final path = await getStoredPicturePathById(
      from: pluginId,
      cartoonId: comicId,
      chapterId: chapterId,
      imageId: image.id,
    );
    if (path != null) {
      ordered.add(File(path));
    }
  }
  if (ordered.isNotEmpty) {
    return ordered;
  }

  final candidateDirs = <Directory>[];
  if (chapterId.trim().isNotEmpty) {
    candidateDirs.add(Directory(p.join(chapterRoot, chapterId)));
    candidateDirs.add(Directory(p.join(chapterRootLegacy, chapterId)));
  }

  for (final dir in candidateDirs) {
    if (!await dir.exists()) {
      continue;
    }
    final files = await dir
        .list()
        .where((e) => e is File)
        .cast<File>()
        .toList();
    if (files.isNotEmpty) {
      return files;
    }
  }

  return const <File>[];
}

Map<String, dynamic> _buildProcessedDetail(
  Map<String, dynamic> detail,
  List<_ExportChapterEntry> chapterEntries,
) {
  final processed = Map<String, dynamic>.from(
    jsonDecode(jsonEncode(detail)) as Map<String, dynamic>,
  );

  final eps = ((processed['eps'] as List?) ?? const [])
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();

  final updatedEps = <Map<String, dynamic>>[];
  for (var i = 0; i < chapterEntries.length; i++) {
    final base = i < eps.length
        ? Map<String, dynamic>.from(eps[i])
        : <String, dynamic>{};
    base['name'] = chapterEntries[i].folderName;
    base['order'] = i + 1;
    updatedEps.add(base);
  }
  if (updatedEps.isNotEmpty) {
    processed['eps'] = updatedEps;
  }

  final extension = Map<String, dynamic>.from(
    processed['extension'] as Map? ?? const <String, dynamic>{},
  );
  final rawDownloadChapters =
      ((extension['downloadChapters'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

  final updatedDownloadChapters = <Map<String, dynamic>>[];
  for (
    var chapterIndex = 0;
    chapterIndex < chapterEntries.length;
    chapterIndex++
  ) {
    final chapter = chapterEntries[chapterIndex];
    final base = chapterIndex < rawDownloadChapters.length
        ? Map<String, dynamic>.from(rawDownloadChapters[chapterIndex])
        : <String, dynamic>{};

    final rawImages = ((base['images'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final updatedImages = <Map<String, dynamic>>[];
    for (var imageIndex = 0; imageIndex < chapter.images.length; imageIndex++) {
      final image = chapter.images[imageIndex];
      final imageBase = imageIndex < rawImages.length
          ? Map<String, dynamic>.from(rawImages[imageIndex])
          : <String, dynamic>{};
      imageBase['name'] = image.exportFileName;
      imageBase['path'] = p.join(chapter.folderName, image.exportFileName);
      updatedImages.add(imageBase);
    }

    base['name'] = chapter.folderName;
    base['order'] = chapterIndex + 1;
    base['images'] = updatedImages;
    updatedDownloadChapters.add(base);
  }

  extension['downloadChapters'] = updatedDownloadChapters;
  processed['extension'] = extension;
  return processed;
}

int _naturalCompareString(String a, String b) {
  final left = a.trim().toLowerCase();
  final right = b.trim().toLowerCase();
  if (left == right) {
    return 0;
  }

  final exp = RegExp(r'(\d+)|(\D+)');
  final leftParts = exp.allMatches(left).map((m) => m.group(0)!).toList();
  final rightParts = exp.allMatches(right).map((m) => m.group(0)!).toList();
  final partCount = min(leftParts.length, rightParts.length);

  for (var i = 0; i < partCount; i++) {
    final l = leftParts[i];
    final r = rightParts[i];
    final lNum = int.tryParse(l);
    final rNum = int.tryParse(r);
    if (lNum != null && rNum != null) {
      final compared = lNum.compareTo(rNum);
      if (compared != 0) {
        return compared;
      }
      continue;
    }
    final compared = l.compareTo(r);
    if (compared != 0) {
      return compared;
    }
  }

  return leftParts.length.compareTo(rightParts.length);
}

String _sanitizeFolderName(String value, {String fallback = 'chapter'}) {
  final fallbackNameRaw = _sanitizePathSegment(fallback);
  final fallbackName = _avoidReservedName(
    fallbackNameRaw.isEmpty ? 'chapter' : fallbackNameRaw,
    'chapter',
  );
  final sanitized = _sanitizePathSegment(value);
  if (sanitized.isEmpty) {
    return fallbackName;
  }
  return _avoidReservedName(sanitized, fallbackName);
}

String _sanitizePathSegment(String value) {
  return value
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'[\x00-\x1F]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'[\.\s]+$'), '');
}

String _avoidReservedName(String value, String fallback) {
  if (value.isEmpty) {
    return fallback;
  }
  if (_kWindowsReservedNames.contains(value.toUpperCase())) {
    return '${value}_';
  }
  return value;
}

String _safeExportExtension(String filePath) {
  final raw = p.extension(filePath).toLowerCase();
  if (raw.isEmpty) {
    return '.img';
  }
  final normalized = raw.replaceAll(RegExp(r'[^a-z0-9.]'), '');
  if (RegExp(r'^\.[a-z0-9]{1,10}$').hasMatch(normalized)) {
    return normalized;
  }
  return '.img';
}

String _uniqueFolderName(String baseName, Set<String> usedNames) {
  if (!usedNames.contains(baseName)) {
    return baseName;
  }
  var index = 2;
  while (usedNames.contains('$baseName ($index)')) {
    index++;
  }
  return '$baseName ($index)';
}

Map<String, dynamic> _decodeMap(String raw) {
  if (raw.trim().isEmpty) {
    return const <String, dynamic>{};
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {}
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _decodeListOfMaps(String raw) {
  if (raw.trim().isEmpty) {
    return const <Map<String, dynamic>>[];
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <Map<String, dynamic>>[];
    }
    return decoded
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  } catch (_) {
    return const <Map<String, dynamic>>[];
  }
}

Future<String> _chapterRoot(UnifiedComicDownload download) async {
  final base = await getDownloadPath();
  return p.join(base, download.source, 'original', download.comicId, 'comic');
}

Future<String> _chapterRootLegacy(UnifiedComicDownload download) async {
  final base = await getDownloadPath();
  return p.join(base, download.source, 'original', download.comicId);
}

class _ExportChapterEntry {
  const _ExportChapterEntry({required this.folderName, required this.images});

  final String folderName;
  final List<_ExportImageEntry> images;
}

class _ExportImageEntry {
  const _ExportImageEntry({required this.source, required this.exportFileName});

  final File source;
  final String exportFileName;
}
