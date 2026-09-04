import 'package:zephyr/util/json/json_value.dart';

class UnifiedPluginChapterDoc {
  const UnifiedPluginChapterDoc({
    required this.name,
    required this.path,
    required this.url,
    required this.id,
    required this.extern,
  });

  final String name;
  final String path;
  final String url;
  final String id;
  final Map<String, dynamic> extern;

  factory UnifiedPluginChapterDoc.fromMap(Map<String, dynamic> map) {
    return UnifiedPluginChapterDoc(
      name: map['name']?.toString() ?? map['originalName']?.toString() ?? '',
      path: map['path']?.toString() ?? '',
      url: map['url']?.toString() ?? map['fileServer']?.toString() ?? '',
      id: map['id']?.toString() ?? '',
      extern: asJsonMap(map['extern']),
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'path': path, 'url': url, 'id': id, 'extern': extern};
  }
}

class UnifiedPluginChapter {
  const UnifiedPluginChapter({
    required this.epId,
    required this.epName,
    required this.order,
    required this.length,
    required this.epPages,
    required this.docs,
    required this.extern,
  });

  final String epId;
  final String epName;
  final int order;
  final int length;
  final String epPages;
  final List<UnifiedPluginChapterDoc> docs;
  final Map<String, dynamic> extern;

  factory UnifiedPluginChapter.fromMap(Map<String, dynamic> map) {
    final rawDocs = asJsonList(map['docs']);
    final rawPages = asJsonList(map['pages']);
    final docsSource = rawPages.isNotEmpty ? rawPages : rawDocs;
    final docs = docsSource
        .map((item) => UnifiedPluginChapterDoc.fromMap(asJsonMap(item)))
        .toList();
    return UnifiedPluginChapter(
      epId: map['id']?.toString() ?? map['epId']?.toString() ?? '',
      epName: map['name']?.toString() ?? map['epName']?.toString() ?? '',
      order: _toInt(map['order'], 0),
      length: _toInt(map['length'], docs.length),
      epPages: map['epPages']?.toString() ?? docs.length.toString(),
      docs: docs,
      extern: asJsonMap(map['extern']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'epId': epId,
      'epName': epName,
      'order': order,
      'length': length,
      'epPages': epPages,
      'docs': docs.map((doc) => doc.toMap()).toList(),
      'extern': extern,
    };
  }
}

class UnifiedPluginChapterResponse {
  const UnifiedPluginChapterResponse({
    required this.source,
    required this.comicId,
    required this.chapterId,
    required this.extern,
    required this.scheme,
    required this.chapter,
  });

  final String source;
  final String comicId;
  final String chapterId;
  final Map<String, dynamic> extern;
  final Map<String, dynamic> scheme;
  final UnifiedPluginChapter chapter;

  factory UnifiedPluginChapterResponse.fromMap(Map<String, dynamic> map) {
    final data = asJsonMap(map['data']);
    final chapterMap = data.isNotEmpty
        ? asJsonMap(data['chapter'])
        : asJsonMap(map['chapter']);
    return UnifiedPluginChapterResponse(
      source: map['source']?.toString() ?? '',
      comicId: map['comicId']?.toString() ?? '',
      chapterId: map['chapterId']?.toString() ?? '',
      extern: asJsonMap(map['extern']),
      scheme: asJsonMap(map['scheme']),
      chapter: UnifiedPluginChapter.fromMap(chapterMap),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'comicId': comicId,
      'chapterId': chapterId,
      'extern': extern,
      'scheme': scheme,
      'chapter': chapter.toMap(),
    };
  }
}

int _toInt(dynamic value, int fallback) {
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
