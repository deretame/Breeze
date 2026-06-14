import 'dart:convert';

import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';

class UnifiedComicDownloadImage {
  const UnifiedComicDownloadImage({
    required this.id,
    required this.name,
    required this.path,
    this.url = '',
    this.extern = const {},
  });

  final String id;
  final String name;
  final String path;
  final String url;
  final Map<String, dynamic> extern;

  factory UnifiedComicDownloadImage.fromMap(Map<String, dynamic> map) {
    return UnifiedComicDownloadImage(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      path: map['path']?.toString() ?? '',
      url: map['url']?.toString() ?? '',
      extern: Map<String, dynamic>.from(
        map['extern'] as Map? ?? const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'path': path,
    'url': url,
    'extern': extern,
  };
}

class UnifiedComicDownloadStoredChapter {
  const UnifiedComicDownloadStoredChapter({
    required this.id,
    required this.name,
    required this.order,
    this.logicalKey = '',
    this.taskChapterId = '',
    this.images = const [],
  });

  final String id;
  final String name;
  final int order;
  final String logicalKey;
  final String taskChapterId;
  final List<UnifiedComicDownloadImage> images;

  factory UnifiedComicDownloadStoredChapter.fromMap(Map<String, dynamic> map) {
    final rawImages = (map['images'] as List?) ?? const [];
    return UnifiedComicDownloadStoredChapter(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      order: _toInt(map['order']?.toString() ?? '', 1),
      logicalKey: map['logicalKey']?.toString() ?? '',
      taskChapterId: map['taskChapterId']?.toString() ?? '',
      images: rawImages
          .whereType<Map>()
          .map(
            (e) =>
                UnifiedComicDownloadImage.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'order': order,
    'logicalKey': logicalKey,
    'taskChapterId': taskChapterId,
    'images': images.map((image) => image.toMap()).toList(),
  };
}

class UnifiedComicDownloadChapter {
  const UnifiedComicDownloadChapter({
    required this.id,
    required this.title,
    required this.order,
    this.requestId = '',
    this.storageChapterId = '',
    this.logicalKey = '',
    this.images = const [],
    this.extern = const <String, dynamic>{},
  });

  final String id;
  final String title;
  final int order;
  final String requestId;
  final String storageChapterId;
  final String logicalKey;
  final List<UnifiedComicDownloadImage> images;
  final Map<String, dynamic> extern;

  factory UnifiedComicDownloadChapter.fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString().trim().isNotEmpty == true
        ? map['id']!.toString().trim()
        : (map['taskChapterId']?.toString().trim() ?? '');
    final order = _toInt(map['order']?.toString() ?? '', 1);
    return UnifiedComicDownloadChapter(
      id: id,
      title: map['name']?.toString() ?? map['title']?.toString() ?? '',
      order: order,
      requestId: map['requestId']?.toString() ?? '',
      storageChapterId: map['storageChapterId']?.toString() ?? '',
      logicalKey: map['logicalKey']?.toString() ?? '',
      images: ((map['images'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (e) =>
                UnifiedComicDownloadImage.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
      extern: Map<String, dynamic>.from(map['extern'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': title,
    'order': order,
    'requestId': requestId,
    'storageChapterId': storageChapterId,
    'logicalKey': logicalKey,
    'extern': extern,
  };
}

class UnifiedComicDownloadInfo {
  const UnifiedComicDownloadInfo({
    required this.source,
    required this.comicId,
    required this.title,
    required this.chapters,
  });

  final String source;
  final String comicId;
  final String title;
  final List<UnifiedComicDownloadChapter> chapters;

  factory UnifiedComicDownloadInfo.fromString(PluginComicDetailSource source) {
    final chapters = resolveUnifiedComicChapters(source, source.from).map((
      chapter,
    ) {
      final id = chapter.id.trim();
      final order = chapter.order;
      final extern = Map<String, dynamic>.from(chapter.extern);
      return UnifiedComicDownloadChapter(
        id: id.isNotEmpty ? id : source.comicId,
        title: chapter.name,
        order: order,
        requestId: chapter.requestId.trim(),
        storageChapterId: chapter.storageChapterId.trim(),
        logicalKey: chapter.logicalKey.trim(),
        images: const [],
        extern: extern,
      );
    }).toList();

    if (chapters.isEmpty) {
      return UnifiedComicDownloadInfo(
        source: source.from.trim(),
        comicId: source.comicId,
        title: source.title,
        chapters: [
          UnifiedComicDownloadChapter(
            id: source.comicId,
            title: source.title,
            order: _toInt(source.comicId, 1),
            images: const [],
          ),
        ],
      );
    }

    return UnifiedComicDownloadInfo(
      source: (source.from).trim(),
      comicId: source.comicId,
      title: source.normalInfo.comicInfo.title,
      chapters: chapters,
    );
  }
}

UnifiedComicDownloadInfo resolveUnifiedDownloadInfo(
  dynamic comicInfo,
  String from,
) {
  if (comicInfo is PluginComicDetailSource) {
    return UnifiedComicDownloadInfo.fromString(comicInfo);
  }

  if (comicInfo is UnifiedComicDownload) {
    final chapters = _decodeListOfMaps(
      comicInfo.chapters,
    ).map((chapter) => UnifiedComicDownloadChapter.fromMap(chapter)).toList();
    return UnifiedComicDownloadInfo(
      source: comicInfo.source,
      comicId: comicInfo.comicId,
      title: comicInfo.title,
      chapters: chapters,
    );
  }

  throw StateError('无法解析下载信息: ${comicInfo.runtimeType}');
}

int _toInt(String value, int fallback) {
  return int.tryParse(value) ?? fallback;
}

List<UnifiedComicDownloadStoredChapter> resolveStoredDownloadChapters(
  UnifiedComicDownload comic,
) {
  final chaptersFromMain = _decodeListOfMaps(
    comic.chapters,
  ).map((e) => UnifiedComicDownloadStoredChapter.fromMap(e)).toList();
  if (chaptersFromMain.any((chapter) => chapter.images.isNotEmpty)) {
    return chaptersFromMain;
  }

  final chaptersFromDetail = _decodeStoredChaptersFromDetailJson(
    comic.detailJson,
  );
  if (chaptersFromDetail.isNotEmpty) {
    return chaptersFromDetail;
  }

  return chaptersFromMain;
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
    final extension = Map<String, dynamic>.from(
      detail['extern'] as Map? ?? const {},
    );
    final rawDownloadChapters =
        (extension['downloadChapters'] as List?) ?? const [];

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
