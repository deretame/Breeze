import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/src/rust/compressed/compressed.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/widgets/toast.dart';

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

Future<String> exportComic(
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

Future<String> _exportComicAsFolder(
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
  return comicDir;
}

Future<String> _exportComicAsZip(
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
    final coverExt = await detectImageExtension(File(coverPath));
    packInfo.originalImagePaths.add(coverPath);
    packInfo.packImagePaths.add('cover$coverExt');
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
  return finalZipPath;
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
  final extern = Map<String, dynamic>.from(
    detail['extern'] as Map? ?? const {},
  );
  extern['version'] = mainVersion;
  detail['extern'] = extern;
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
  final srcFile = File(path);
  final ext = await detectImageExtension(srcFile);
  final destFile = File(p.join(comicDir, 'cover$ext'));
  await destFile.create(recursive: true);
  await srcFile.copy(destFile.path);
}

Future<String?> _tryDownloadCover(
  UnifiedComicDownload download,
  String comicId, {
  required String from,
}) async {
  final cover = _decodeMap(download.cover);
  final ext = Map<String, dynamic>.from(cover['extern'] as Map? ?? const {});
  final url = cover['url']?.toString() ?? '';
  final path = ext['path']?.toString() ?? '$comicId.jpg';
  if (url.isEmpty && path.isEmpty) {
    return null;
  }
  try {
    final temp = await getCachePicture(
      from: from,
      url: url,
      path: path,
      cartoonId: comicId,
      pictureType: PictureType.cover,
    );

    await downloadPicture(
      from: from,
      url: url,
      path: path,
      cartoonId: comicId,
      pictureType: PictureType.cover,
    );

    return temp;
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
  var chapters = _decodeStoredChaptersFromDetailJson(download.detailJson);
  if (chapters.isEmpty) {
    chapters = resolveStoredDownloadChapters(download);
  }
  if (chapters.isEmpty) {
    chapters = _decodeListOfMaps(download.chapters)
        .map((chapter) => UnifiedComicDownloadStoredChapter.fromMap(chapter))
        .toList();
  }
  // Keep persisted chapter order exactly as stored.
  // Do not reorder by name/order here, otherwise exported page sequence may drift.

  final usedFolderNames = <String>{};
  final result = <_ExportChapterEntry>[];
  final hasMultipleChapters = chapters.length > 1;

  for (var chapterIndex = 0; chapterIndex < chapters.length; chapterIndex++) {
    final chapter = chapters[chapterIndex];
    final chapterId = chapter.id.trim();
    final taskChapterId = chapter.taskChapterId.trim();
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
      taskChapterId: taskChapterId,
      images: chapter.images,
    );
    final numberedImages = <_ExportImageEntry>[];
    final numberWidth = files.length.toString().length;
    for (var imageIndex = 0; imageIndex < files.length; imageIndex++) {
      final file = files[imageIndex];
      final indexLabel = (imageIndex + 1).toString().padLeft(numberWidth, '0');
      final extension = await detectImageExtension(file);
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
  required String taskChapterId,
  required List<UnifiedComicDownloadImage> images,
}) async {
  final futures = images.map((image) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final cachedPath = await getCachePicture(
          from: pluginId,
          url: image.url,
          path: image.path,
          cartoonId: comicId,
          chapterId: chapterId,
        );
        final file = File(cachedPath);
        if (await file.exists()) {
          await downloadPicture(
            from: pluginId,
            url: image.url,
            path: image.path,
            cartoonId: comicId,
            chapterId: chapterId,
          );
          return file;
        }
      } catch (_) {}
    }
    return null;
  });

  final results = await Future.wait(futures);
  return results.whereType<File>().toList();
}

List<UnifiedComicDownloadStoredChapter> _decodeStoredChaptersFromDetailJson(
  String rawDetailJson,
) {
  if (rawDetailJson.trim().isEmpty) {
    return const <UnifiedComicDownloadStoredChapter>[];
  }
  try {
    final decoded = jsonDecode(rawDetailJson);
    if (decoded is! Map) {
      return const <UnifiedComicDownloadStoredChapter>[];
    }
    final detail = Map<String, dynamic>.from(decoded);
    final extern = Map<String, dynamic>.from(
      detail['extern'] as Map? ?? const {},
    );
    final rawDownloadChapters =
        (extern['downloadChapters'] as List?) ?? const <dynamic>[];
    return rawDownloadChapters
        .whereType<Map>()
        .map(
          (entry) => UnifiedComicDownloadStoredChapter.fromMap(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();
  } catch (_) {
    return const <UnifiedComicDownloadStoredChapter>[];
  }
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

  final extern = Map<String, dynamic>.from(
    processed['extern'] as Map? ?? const {},
  );
  final rawDownloadChapters =
      ((extern['downloadChapters'] as List?) ?? const [])
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
      imageBase['path'] = image.exportFileName;
      updatedImages.add(imageBase);
    }

    base['name'] = chapter.folderName;
    base['order'] = chapterIndex + 1;
    base['images'] = updatedImages;
    updatedDownloadChapters.add(base);
  }

  extern['downloadChapters'] = updatedDownloadChapters;
  processed['extern'] = extern;
  return processed;
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

Future<String> detectImageExtension(File file) async {
  try {
    final raf = await file.open(mode: FileMode.read);
    final header = await raf.read(16);
    await raf.close();
    final mimeType = lookupMimeType(file.path, headerBytes: header);
    if (mimeType != null) {
      switch (mimeType) {
        // 现代图片格式
        case 'image/jpeg':
          return '.jpg';
        case 'image/png':
          return '.png';
        case 'image/gif':
          return '.gif';
        case 'image/webp':
          return '.webp';
        case 'image/avif':
          return '.avif';
        case 'image/jxl':
          return '.jxl';
        case 'image/heif':
        case 'image/heic':
          return '.heic';
        case 'image/jp2':
          return '.jp2';
        case 'image/bmp':
          return '.bmp';
        case 'image/tiff':
          return '.tiff';
        case 'image/x-icon':
        case 'image/vnd.microsoft.icon':
          return '.ico';
        case 'image/svg+xml':
          return '.svg';
        case 'image/x-tga':
          return '.tga';
        case 'image/x-pcx':
          return '.pcx';
        case 'image/x-portable-anymap':
          return '.pnm';
        case 'image/x-portable-bitmap':
          return '.pbm';
        case 'image/x-portable-graymap':
          return '.pgm';
        case 'image/x-portable-pixmap':
          return '.ppm';
        case 'image/x-xbitmap':
          return '.xbm';
        case 'image/x-xpixmap':
          return '.xpm';
        case 'image/x-photoshop':
        case 'image/vnd.adobe.photoshop':
          return '.psd';
        case 'image/x-cmu-raster':
          return '.ras';
        case 'image/x-dcx':
          return '.dcx';
        case 'image/x-wmf':
          return '.wmf';
        case 'image/x-rgb':
          return '.rgb';

        // 视频格式
        case 'video/webm':
          return '.webm';
        case 'video/mp4':
          return '.mp4';
        case 'video/ogg':
          return '.ogv';
        case 'video/quicktime':
          return '.mov';
        case 'video/x-msvideo':
          return '.avi';
        case 'video/x-matroska':
          return '.mkv';
        case 'video/mpeg':
          return '.mpeg';
        case 'video/3gpp':
          return '.3gp';
        case 'video/x-flv':
          return '.flv';
        case 'video/x-ms-wmv':
          return '.wmv';
        case 'video/x-m4v':
          return '.m4v';
        case 'video/x-ms-asf':
          return '.asf';
        case 'video/x-ms-asx':
          return '.asx';
        case 'video/x-ms-wmx':
          return '.wmx';
        case 'video/avi':
          return '.avi';
        case 'video/x-ms-dvr':
          return '.dvr-ms';
        default:
          break;
      }
    }
  } catch (_) {}
  return _safeExportExtension(file.path);
}
