import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart'
    show Doc;
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/util/get_path.dart';

Future<NormalComicEpInfo> getPluginInfoFromLocal(
  String pluginId,
  String comicId,
  int epsId,
) async {
  final resolvedPluginId = pluginId.trim();
  if (resolvedPluginId.isEmpty) {
    throw StateError('pluginId 不能为空');
  }

  final download = objectbox.unifiedDownloadBox
      .query(
        UnifiedComicDownload_.uniqueKey.equals('$resolvedPluginId:$comicId'),
      )
      .build()
      .findFirst();
  if (download == null) {
    throw StateError('本地下载信息不存在: $resolvedPluginId:$comicId');
  }

  final rawChapters = (download.chapters ?? const <Map<String, dynamic>>[]);
  final epInfo = rawChapters.firstWhere(
    (e) =>
        (e['order'] as num?)?.toInt() == epsId ||
        e['id']?.toString() == '$epsId',
    orElse: () =>
        rawChapters.isNotEmpty ? rawChapters.first : <String, dynamic>{},
  );

  final chapterId = epInfo['id']?.toString().trim().isNotEmpty == true
      ? epInfo['id'].toString().trim()
      : '$epsId';
  final chapterName = epInfo['name']?.toString() ?? '';

  final storedChapters = resolveStoredDownloadChapters(download);
  final storedChapter = storedChapters.firstWhere(
    (e) => e.id == chapterId || e.order == epsId,
    orElse: () => UnifiedComicDownloadStoredChapter(
      id: chapterId,
      name: chapterName,
      order: epsId,
      images: const [],
    ),
  );

  final orderedDocs = storedChapter.images
      .map(
        (image) => Doc(
          originalName: image.name,
          path: image.path,
          fileServer: image.url,
          id: image.id.isNotEmpty ? image.id : chapterId,
        ),
      )
      .toList();

  if (orderedDocs.isNotEmpty) {
    return NormalComicEpInfo(
      length: orderedDocs.length,
      epPages: orderedDocs.length.toString(),
      docs: orderedDocs,
      epId: chapterId,
      epName: chapterName,
    );
  }

  final downloadRoot = await getDownloadPath();
  final chapterDirs = <Directory>[
    Directory(
      p.join(downloadRoot, resolvedPluginId, 'original', comicId, chapterId),
    ),
    Directory(
      p.join(
        downloadRoot,
        resolvedPluginId,
        'original',
        comicId,
        'comic',
        chapterId,
      ),
    ),
  ];

  final images = storedChapter.images;
  final imageIds = images.map((e) => e.id).where((e) => e.isNotEmpty).toList();
  final imageNames = {for (final image in images) image.id: image.name};
  final files = await _resolveOrderedFiles(
    pluginId: resolvedPluginId,
    comicId: comicId,
    chapterId: chapterId,
    imageIds: imageIds,
    imageNames: imageNames,
    fallbackDirs: chapterDirs,
  );

  return NormalComicEpInfo(
    length: files.length,
    epPages: files.length.toString(),
    docs: files.map((file) {
      final fileName = p.basename(file.path);
      return Doc(
        originalName: fileName,
        path: fileName,
        fileServer: '',
        id: chapterId,
      );
    }).toList(),
    epId: chapterId,
    epName: chapterName,
  );
}

Future<List<File>> _resolveOrderedFiles({
  required String pluginId,
  required String comicId,
  required String chapterId,
  required List<String> imageIds,
  required Map<String, String> imageNames,
  required List<Directory> fallbackDirs,
}) async {
  final ordered = <File>[];
  final existingFallbackDirs = <Directory>[];
  for (final dir in fallbackDirs) {
    if (await dir.exists()) {
      existingFallbackDirs.add(dir);
    }
  }

  for (final imageId in imageIds) {
    final path = await getStoredPicturePathById(
      from: pluginId,
      cartoonId: comicId,
      chapterId: chapterId,
      imageId: imageId,
    );
    if (path != null) {
      ordered.add(File(path));
      continue;
    }

    final fallbackName = imageNames[imageId];
    if (fallbackName != null && fallbackName.isNotEmpty) {
      for (final dir in existingFallbackDirs) {
        final file = File(p.join(dir.path, p.basename(fallbackName)));
        if (await file.exists()) {
          ordered.add(file);
          break;
        }
      }
    }
  }

  if (ordered.isNotEmpty) {
    return ordered;
  }

  for (final dir in existingFallbackDirs) {
    final files = await dir.list().where((e) => e is File).cast<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    if (files.isNotEmpty) {
      return files;
    }
  }

  return const <File>[];
}
