import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart'
    show Doc;
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/jm_url_set.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

Future<NormalComicEpInfo> fetchJMMedia(
  String comicId,
  String epId,
  ComicEntryType type,
) async {
  if (type == ComicEntryType.download ||
      type == ComicEntryType.historyAndDownload) {
    return await fetchJMMediaFromLocal(comicId, epId);
  } else {
    return await fetchJMMediaFromNet(epId);
  }
}

Future<NormalComicEpInfo> fetchJMMediaFromNet(String epId) async {
  final response = await callUnifiedComicPlugin(
    from: From.jm,
    fnPath: 'getChapter',
    core: {'chapterId': epId},
    extern: const <String, dynamic>{},
  );
  final chapter = UnifiedPluginChapterResponse.fromMap(response).chapter;
  final docs = chapter.docs.map((doc) {
    final path = doc.path;
    final fileServer = doc.url;
    return Doc(
      originalName: doc.name.isEmpty ? path : doc.name,
      path: path,
      fileServer: fileServer,
      id: doc.id.isEmpty ? epId : doc.id,
    );
  }).toList();

  return NormalComicEpInfo(
    length: chapter.length,
    epPages: chapter.epPages,
    docs: docs,
    epId: chapter.epId.isEmpty ? epId : chapter.epId,
    epName: chapter.epName,
  );
}

Future<NormalComicEpInfo> fetchJMMediaFromLocal(
  String comicId,
  String epId,
) async {
  final downloadInfo = objectbox.unifiedDownloadBox
      .query(UnifiedComicDownload_.uniqueKey.equals('jm:$comicId'))
      .build()
      .findFirst()!;
  final epInfo = (downloadInfo.chapters ?? const <Map<String, dynamic>>[])
      .firstWhere((e) => e['id']?.toString() == epId);
  final epName = epInfo['name']?.toString() ?? '';
  final storedChapters = resolveStoredDownloadChapters(downloadInfo);
  final storedChapter = storedChapters.firstWhere(
    (e) => e.id == epId,
    orElse: () => UnifiedComicDownloadStoredChapter(
      id: epId,
      name: epName,
      order: 1,
      images: const [],
    ),
  );
  final orderedDocs = storedChapter.images
      .map(
        (image) => Doc(
          originalName: image.name,
          path: image.path,
          fileServer: image.url.isNotEmpty
              ? image.url
              : getJmImagesUrl(epId, image.name),
          id: image.id.isNotEmpty ? image.id : epId,
        ),
      )
      .toList();
  if (orderedDocs.isNotEmpty) {
    return NormalComicEpInfo(
      length: orderedDocs.length,
      epPages: orderedDocs.length.toString(),
      docs: orderedDocs,
      epId: epId,
      epName: epName,
    );
  }

  final downloadRoot = await getDownloadPath();
  final chapterDirs = <Directory>[
    Directory(p.join(downloadRoot, 'jm', 'original', comicId, epId)),
    Directory(p.join(downloadRoot, 'jm', 'original', comicId, 'comic', epId)),
  ];
  final images = storedChapter.images;
  final imageIds = images.map((e) => e.id).where((e) => e.isNotEmpty).toList();
  final imageNames = {for (final image in images) image.id: image.name};
  final files = await _resolveOrderedFiles(
    comicId: comicId,
    epId: epId,
    imageIds: imageIds,
    imageNames: imageNames,
    fallbackDirs: chapterDirs,
  );

  return NormalComicEpInfo(
    length: files.length,
    epPages: files.length.toString(),
    docs: files.map((e) {
      final fileName = p.basename(e.path);
      return Doc(
        originalName: fileName,
        path: fileName,
        fileServer: getJmImagesUrl(epId, fileName),
        id: epId,
      );
    }).toList(),
    epId: epId,
    epName: epName,
  );
}

Future<List<File>> _resolveOrderedFiles({
  required String comicId,
  required String epId,
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
      from: From.jm,
      cartoonId: comicId,
      chapterId: epId,
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
