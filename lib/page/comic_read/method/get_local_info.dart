import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart'
    show Doc;
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';

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

  final rawChapters = _decodeListOfMaps(download.chapters);
  final epInfo = rawChapters.firstWhere(
    (e) =>
        (e['order'] as num?)?.toInt() == epsId ||
        e['logicalKey']?.toString() == '$epsId' ||
        e['taskChapterId']?.toString() == '$epsId',
    orElse: () =>
        rawChapters.isNotEmpty ? rawChapters.first : <String, dynamic>{},
  );

  final logicalKey = epInfo['logicalKey']?.toString().trim() ?? '';
  final chapterName = epInfo['name']?.toString() ?? '';
  final taskChapterId = epInfo['taskChapterId']?.toString().trim() ?? '';
  final chapterId = logicalKey.isNotEmpty
      ? logicalKey
      : (epInfo['id']?.toString().trim().isNotEmpty == true
            ? epInfo['id']!.toString().trim()
            : '$epsId');

  final storedChapters = resolveStoredDownloadChapters(download);
  final storedChapter = storedChapters.firstWhere(
    (e) =>
        (logicalKey.isNotEmpty && e.logicalKey == logicalKey) ||
        (taskChapterId.isNotEmpty && e.taskChapterId == taskChapterId) ||
        e.id == chapterId ||
        e.order == epsId,
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
          storageChapterId: storedChapter.id.trim().isNotEmpty
              ? storedChapter.id
              : '',
          extern: Map<String, dynamic>.from(image.extern),
        ),
      )
      .toList();

  return NormalComicEpInfo(
    length: orderedDocs.length,
    epPages: orderedDocs.length.toString(),
    docs: orderedDocs,
    epId: chapterId,
    epName: chapterName,
  );
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
