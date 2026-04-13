import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';

class ComicReadSnapshot {
  const ComicReadSnapshot({
    required this.source,
    required this.comic,
    required this.chapter,
    required this.chapters,
    this.extern = const {},
  });

  final String source;
  final ComicReadSnapshotComic comic;
  final ComicReadSnapshotChapter chapter;
  final List<ComicReadSnapshotChapterRef> chapters;
  final Map<String, dynamic> extern;

  factory ComicReadSnapshot.fromMap(Map<String, dynamic> map) {
    final data = _asMap(map['data']);
    final snapshot = data.isNotEmpty ? data : map;

    return ComicReadSnapshot(
      source: map['source']?.toString() ?? '',
      comic: ComicReadSnapshotComic.fromMap(_asMap(snapshot['comic'])),
      chapter: ComicReadSnapshotChapter.fromMap(_asMap(snapshot['chapter'])),
      chapters: _asList(snapshot['chapters'])
          .map((item) => ComicReadSnapshotChapterRef.fromMap(_asMap(item)))
          .toList(),
      extern: _asMap(map['extern']),
    );
  }

  NormalComicEpInfo toNormalEpInfo({required String fallbackChapterId}) {
    final docs = chapter.pages
        .map(
          (page) => Doc(
            originalName: page.name,
            path: page.path,
            fileServer: page.url,
            id: page.id.isNotEmpty ? page.id : fallbackChapterId,
            extern: page.extern,
          ),
        )
        .toList();

    final chapterId = chapter.id.isNotEmpty ? chapter.id : fallbackChapterId;
    final epName = chapter.name.trim().isNotEmpty ? chapter.name : comic.title;

    return NormalComicEpInfo(
      length: docs.length,
      epPages: docs.length.toString(),
      docs: docs,
      epId: chapterId,
      epName: epName,
    );
  }
}

class ComicReadSnapshotComic {
  const ComicReadSnapshotComic({
    required this.id,
    required this.source,
    required this.title,
    this.extern = const {},
  });

  final String id;
  final String source;
  final String title;
  final Map<String, dynamic> extern;

  factory ComicReadSnapshotComic.fromMap(Map<String, dynamic> map) {
    return ComicReadSnapshotComic(
      id: map['id']?.toString() ?? '',
      source: map['source']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      extern: _externMap(map),
    );
  }
}

class ComicReadSnapshotChapter {
  const ComicReadSnapshotChapter({
    required this.id,
    required this.name,
    required this.order,
    required this.pages,
    this.extern = const {},
  });

  final String id;
  final String name;
  final int order;
  final List<ComicReadSnapshotPage> pages;
  final Map<String, dynamic> extern;

  factory ComicReadSnapshotChapter.fromMap(Map<String, dynamic> map) {
    return ComicReadSnapshotChapter(
      id: map['id']?.toString() ?? map['epId']?.toString() ?? '',
      name: map['name']?.toString() ?? map['epName']?.toString() ?? '',
      order: _toInt(map['order'], 0),
      pages: _resolvePages(
        map,
      ).map((item) => ComicReadSnapshotPage.fromMap(_asMap(item))).toList(),
      extern: _externMap(map),
    );
  }
}

class ComicReadSnapshotChapterRef {
  const ComicReadSnapshotChapterRef({
    required this.id,
    required this.name,
    required this.order,
    this.extern = const {},
  });

  final String id;
  final String name;
  final int order;
  final Map<String, dynamic> extern;

  factory ComicReadSnapshotChapterRef.fromMap(Map<String, dynamic> map) {
    return ComicReadSnapshotChapterRef(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      order: _toInt(map['order'], 0),
      extern: _externMap(map),
    );
  }
}

class ComicReadSnapshotPage {
  const ComicReadSnapshotPage({
    required this.id,
    required this.name,
    required this.path,
    required this.url,
    this.extern = const {},
  });

  final String id;
  final String name;
  final String path;
  final String url;
  final Map<String, dynamic> extern;

  factory ComicReadSnapshotPage.fromMap(Map<String, dynamic> map) {
    return ComicReadSnapshotPage(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? map['originalName']?.toString() ?? '',
      path: map['path']?.toString() ?? '',
      url: map['url']?.toString() ?? map['fileServer']?.toString() ?? '',
      extern: _externMap(map),
    );
  }
}

List<dynamic> _resolvePages(Map<String, dynamic> map) {
  final pages = _asList(map['pages']);
  if (pages.isNotEmpty) {
    return pages;
  }
  return _asList(map['docs']);
}

Map<String, dynamic> _externMap(Map<String, dynamic> map) {
  final extern = _asMap(map['extern']);
  if (extern.isNotEmpty) {
    return extern;
  }
  return _asMap(map['extension']);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

int _toInt(dynamic value, int fallback) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
