import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/src/rust/compressed/compressed.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/widgets/toast.dart';

Future<void> jmExportComicAsFolder(String comicId, {String? exportPath}) async {
  final download = _getDownload(comicId, kJmPluginUuid);
  final detail = _exportDetail(download);
  final title = download.title;
  final root = exportPath ?? await createDownloadDir();
  final comicDir = p.join(root, title);

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
  ).writeAsString(jsonEncode(detail));

  await _exportCover(download, comicDir, comicId);
  await _copyEpisodeFiles(download, comicDir, comicId);

  showSuccessToast('漫画$title导出为文件夹完成');
}

Future<void> jmExportComicAsZip(String comicId, {String? exportPath}) async {
  final download = _getDownload(comicId, kJmPluginUuid);
  final detail = _exportDetail(download);
  final title = download.title;
  final finalZipPath =
      exportPath ??
      '${p.join(await createDownloadDir(), title.substring(0, min(title.length, 90)))}.zip';

  final packInfo = PackInfo(
    comicInfoString: jsonEncode(detail),
    processedComicInfoString: jsonEncode(detail),
    originalImagePaths: [],
    packImagePaths: [],
  );

  final coverPath = await _tryDownloadCover(download, comicId);
  if (coverPath != null) {
    packInfo.originalImagePaths.add(coverPath);
    packInfo.packImagePaths.add('cover/cover.jpg');
  }

  final chapterRoot = await _chapterRoot(download);
  for (final chapter in download.chapters ?? const <Map<String, dynamic>>[]) {
    final chapterId = chapter['id']?.toString() ?? '';
    final chapterName = chapter['name']?.toString() ?? chapterId;
    final dir = Directory(p.join(chapterRoot, chapterId));
    if (!await dir.exists()) continue;
    final files = await dir.list().where((e) => e is File).cast<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      packInfo.originalImagePaths.add(file.path);
      packInfo.packImagePaths.add(
        p.join('eps', chapterName, p.basename(file.path)),
      );
    }
  }

  await packFolderZip(destPath: finalZipPath, packInfo: packInfo);
  showSuccessToast('漫画$title导出为 zip 完成');
}

UnifiedComicDownload _getDownload(String comicId, String source) {
  return objectbox.unifiedDownloadBox
      .query(UnifiedComicDownload_.uniqueKey.equals('$source:$comicId'))
      .build()
      .findFirst()!;
}

Map<String, dynamic> _exportDetail(UnifiedComicDownload download) {
  final detail = Map<String, dynamic>.from(
    jsonDecode(download.detailJson) as Map<String, dynamic>,
  );
  final extension = Map<String, dynamic>.from(
    detail['extension'] as Map? ?? const {},
  );
  extension['version'] = 'v2';
  detail['extension'] = extension;
  return detail;
}

Future<void> _exportCover(
  UnifiedComicDownload download,
  String comicDir,
  String comicId,
) async {
  final path = await _tryDownloadCover(download, comicId);
  if (path == null) return;
  final coverFile = File(p.join(comicDir, 'cover', 'cover.jpg'));
  await coverFile.create(recursive: true);
  await File(path).copy(coverFile.path);
}

Future<String?> _tryDownloadCover(
  UnifiedComicDownload download,
  String comicId,
) async {
  final cover = Map<String, dynamic>.from(
    download.cover ?? const <String, dynamic>{},
  );
  final ext = Map<String, dynamic>.from(cover['extension'] as Map? ?? const {});
  final url = cover['url']?.toString() ?? '';
  final path = ext['path']?.toString() ?? '$comicId.jpg';
  if (url.isEmpty && path.isEmpty) return null;
  try {
    return await downloadPicture(
      from: kJmPluginUuid,
      url: url,
      path: path,
      cartoonId: comicId,
    );
  } catch (_) {
    return null;
  }
}

Future<void> _copyEpisodeFiles(
  UnifiedComicDownload download,
  String comicDir,
  String comicId,
) async {
  final chapterRoot = await _chapterRoot(download);
  for (final chapter in download.chapters ?? const <Map<String, dynamic>>[]) {
    final chapterId = chapter['id']?.toString() ?? '';
    final chapterName = chapter['name']?.toString() ?? chapterId;
    final dir = Directory(p.join(chapterRoot, chapterId));
    if (!await dir.exists()) continue;
    final files = await dir.list().where((e) => e is File).cast<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final target = File(
        p.join(comicDir, 'eps', chapterName, p.basename(file.path)),
      );
      await target.create(recursive: true);
      await file.copy(target.path);
    }
  }
}

Future<String> _chapterRoot(UnifiedComicDownload download) async {
  final base = await getDownloadPath();
  return p.join(base, download.source, 'original', download.comicId, 'comic');
}
