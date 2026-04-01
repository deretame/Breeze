import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/util/get_path.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../json/common_ep_info_json/common_ep_info_json.dart';
import 'package:zephyr/type/enum.dart';

Future<NormalComicEpInfo> getBikaInfo(
  String comicId,
  int epsId,
  ComicEntryType type,
) async {
  final isDownload =
      type == ComicEntryType.download ||
      type == ComicEntryType.historyAndDownload;
  if (isDownload) {
    return await getBikaInfoFromLocal(comicId, epsId);
  } else {
    return await getBikaInfoFromNet(comicId, epsId);
  }
}

Future<NormalComicEpInfo> getBikaInfoFromNet(String comicId, int epsId) async {
  final response = await callUnifiedComicPlugin(
    from: kBikaPluginUuid,
    fnPath: 'getChapter',
    core: {'comicId': comicId, 'chapterId': epsId},
    extern: const <String, dynamic>{},
  );
  final chapter = UnifiedPluginChapterResponse.fromMap(response).chapter;
  final docs = chapter.docs
      .map(
        (doc) => Doc(
          originalName: doc.name,
          path: doc.path,
          fileServer: doc.url,
          id: doc.id,
        ),
      )
      .toList();

  return NormalComicEpInfo(
    length: chapter.length,
    epPages: chapter.epPages,
    docs: docs,
    epId: chapter.epId,
    epName: chapter.epName,
  );
}

Future<NormalComicEpInfo> getBikaInfoFromLocal(
  String comicId,
  int epsId,
) async {
  final download =
      objectbox.unifiedDownloadBox
          .query(
            UnifiedComicDownload_.uniqueKey.equals('$kBikaPluginUuid:$comicId'),
          )
          .build()
          .findFirst() ??
      objectbox.unifiedDownloadBox
          .query(
            UnifiedComicDownload_.uniqueKey.equals('$kBikaPluginUuid:$comicId'),
          )
          .build()
          .findFirst()!;
  final epInfo = (download.chapters ?? const <Map<String, dynamic>>[])
      .firstWhere((e) => (e['order'] as num?)?.toInt() == epsId);
  final chapterId = epInfo['id']?.toString() ?? '';
  final chapterName = epInfo['name']?.toString() ?? '';
  final storedChapters = resolveStoredDownloadChapters(download);
  final storedChapter = storedChapters.firstWhere(
    (e) => e.order == epsId,
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
      p.join(downloadRoot, kBikaPluginUuid, 'original', comicId, chapterId),
    ),
    Directory(
      p.join(
        downloadRoot,
        kBikaPluginUuid,
        'original',
        comicId,
        'comic',
        chapterId,
      ),
    ),
    Directory(
      p.join(downloadRoot, kBikaPluginUuid, 'original', comicId, chapterId),
    ),
    Directory(
      p.join(
        downloadRoot,
        kBikaPluginUuid,
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
    from: kBikaPluginUuid,
    comicId: comicId,
    chapterId: chapterId,
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
        fileServer: '',
        id: chapterId,
      );
    }).toList(),
    epId: chapterId,
    epName: chapterName,
  );
}

Future<List<File>> _resolveOrderedFiles({
  required String from,
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
      from: from,
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
