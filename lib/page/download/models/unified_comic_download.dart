import 'dart:convert';

import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/type/enum.dart';

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
      url:
          map['url']?.toString() ??
          ((map['extern'] as Map?)?['url']?.toString() ?? ''),
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
    this.images = const [],
  });

  final String id;
  final String name;
  final int order;
  final List<UnifiedComicDownloadImage> images;

  factory UnifiedComicDownloadStoredChapter.fromMap(Map<String, dynamic> map) {
    final rawImages =
        (map['images'] as List?) ??
        (((map['extension'] as Map?)?['images']) as List?) ??
        const [];
    return UnifiedComicDownloadStoredChapter(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      order: _toInt(map['order']?.toString() ?? '', 1),
      images: rawImages
          .whereType<Map>()
          .map(
            (e) =>
                UnifiedComicDownloadImage.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

class UnifiedComicDownloadChapter {
  const UnifiedComicDownloadChapter({
    required this.id,
    required this.title,
    required this.order,
    required this.taskChapterId,
    this.images = const [],
  });

  final String id;
  final String title;
  final int order;
  final String taskChapterId;
  final List<UnifiedComicDownloadImage> images;

  factory UnifiedComicDownloadChapter.fromMap(Map<String, dynamic> map) {
    return UnifiedComicDownloadChapter(
      id: map['id']?.toString() ?? '',
      title: map['name']?.toString() ?? map['title']?.toString() ?? '',
      order: _toInt(map['order']?.toString() ?? '', 1),
      taskChapterId:
          map['taskChapterId']?.toString() ?? map['id']?.toString() ?? '',
      images: ((map['images'] as List?) ?? const [])
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
    'name': title,
    'order': order,
    'taskChapterId': taskChapterId,
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

  factory UnifiedComicDownloadInfo.fromPluginSource(
    PluginComicDetailSource source,
  ) {
    final chapters = resolveUnifiedComicChapters(source, source.from)
        .map(
          (chapter) => UnifiedComicDownloadChapter(
            id: chapter.id,
            title: chapter.name,
            order: chapter.order,
            taskChapterId: source.isBika
                ? chapter.order.toString()
                : chapter.id,
            images: const [],
          ),
        )
        .toList();

    if (source.isJm && chapters.isEmpty) {
      return UnifiedComicDownloadInfo(
        source: 'jm',
        comicId: source.comicId,
        title: source.title,
        chapters: [
          UnifiedComicDownloadChapter(
            id: source.comicId,
            title: source.title,
            order: _toInt(source.comicId, 1),
            taskChapterId: source.comicId,
            images: const [],
          ),
        ],
      );
    }

    return UnifiedComicDownloadInfo(
      source: source.from.name,
      comicId: source.comicId,
      title: source.normalInfo.comicInfo.title,
      chapters: chapters,
    );
  }
}

UnifiedComicDownloadInfo resolveUnifiedDownloadInfo(
  dynamic comicInfo,
  From from,
) {
  if (comicInfo is PluginComicDetailSource) {
    return UnifiedComicDownloadInfo.fromPluginSource(comicInfo);
  }

  if (comicInfo is UnifiedComicDownload) {
    final chapters = (comicInfo.chapters ?? const <Map<String, dynamic>>[])
        .map((chapter) => UnifiedComicDownloadChapter.fromMap(chapter))
        .toList();
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
  final detail = comic.detailJson.trim();
  if (detail.isNotEmpty) {
    try {
      final map = jsonDecode(detail) as Map<String, dynamic>;
      final chapterPayload =
          ((map['extension'] as Map?)?['downloadChapters'] as List?) ??
          const [];
      final eps = chapterPayload
          .whereType<Map>()
          .map(
            (e) => UnifiedComicDownloadStoredChapter.fromMap(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
      if (eps.isNotEmpty) {
        return eps;
      }
    } catch (_) {}
  }

  return (comic.chapters ?? const <Map<String, dynamic>>[])
      .map((e) => UnifiedComicDownloadStoredChapter.fromMap(e))
      .toList();
}
