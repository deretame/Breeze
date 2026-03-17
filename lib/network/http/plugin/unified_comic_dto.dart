class UnifiedPluginSearchPaging {
  const UnifiedPluginSearchPaging({
    required this.page,
    required this.pages,
    required this.total,
    required this.hasReachedMax,
  });

  final int page;
  final int pages;
  final int total;
  final bool hasReachedMax;

  factory UnifiedPluginSearchPaging.fromMap(Map<String, dynamic> map) {
    return UnifiedPluginSearchPaging(
      page: _toInt(map['page'], 1),
      pages: _toInt(map['pages'], 1),
      total: _toInt(map['total'], 0),
      hasReachedMax: map['hasReachedMax'] == true,
    );
  }
}

class UnifiedPluginSearchItem {
  const UnifiedPluginSearchItem({
    required this.id,
    required this.title,
    required this.raw,
  });

  final String id;
  final String title;
  final Map<String, dynamic> raw;

  factory UnifiedPluginSearchItem.fromMap(Map<String, dynamic> map) {
    return UnifiedPluginSearchItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      raw: asMap(map['raw']),
    );
  }
}

class UnifiedPluginSearchResponse {
  const UnifiedPluginSearchResponse({
    required this.source,
    required this.extern,
    required this.paging,
    required this.items,
  });

  final String source;
  final Map<String, dynamic> extern;
  final UnifiedPluginSearchPaging paging;
  final List<UnifiedPluginSearchItem> items;

  factory UnifiedPluginSearchResponse.fromMap(Map<String, dynamic> map) {
    final data = asMap(map['data']);
    final pagingMap = data.isNotEmpty ? asMap(data['paging']) : asMap(map['paging']);
    final itemsRaw = data.isNotEmpty ? asList(data['items']) : asList(map['items']);

    final itemList = itemsRaw
        .map((item) => UnifiedPluginSearchItem.fromMap(asMap(item)))
        .toList();

    return UnifiedPluginSearchResponse(
      source: map['source']?.toString() ?? '',
      extern: asMap(map['extern']),
      paging: UnifiedPluginSearchPaging.fromMap(pagingMap),
      items: itemList,
    );
  }
}

class UnifiedPluginChapterDoc {
  const UnifiedPluginChapterDoc({
    required this.originalName,
    required this.path,
    required this.fileServer,
    required this.id,
  });

  final String originalName;
  final String path;
  final String fileServer;
  final String id;

  factory UnifiedPluginChapterDoc.fromMap(Map<String, dynamic> map) {
    return UnifiedPluginChapterDoc(
      originalName: map['originalName']?.toString() ?? '',
      path: map['path']?.toString() ?? '',
      fileServer: map['fileServer']?.toString() ?? '',
      id: map['id']?.toString() ?? '',
    );
  }
}

class UnifiedPluginChapter {
  const UnifiedPluginChapter({
    required this.epId,
    required this.epName,
    required this.length,
    required this.epPages,
    required this.docs,
  });

  final String epId;
  final String epName;
  final int length;
  final String epPages;
  final List<UnifiedPluginChapterDoc> docs;

  factory UnifiedPluginChapter.fromMap(Map<String, dynamic> map) {
    final docs = asList(map['docs'])
        .map((item) => UnifiedPluginChapterDoc.fromMap(asMap(item)))
        .toList();
    return UnifiedPluginChapter(
      epId: map['epId']?.toString() ?? '',
      epName: map['epName']?.toString() ?? '',
      length: _toInt(map['length'], docs.length),
      epPages: map['epPages']?.toString() ?? docs.length.toString(),
      docs: docs,
    );
  }
}

class UnifiedPluginChapterResponse {
  const UnifiedPluginChapterResponse({
    required this.source,
    required this.comicId,
    required this.chapterId,
    required this.extern,
    required this.chapter,
  });

  final String source;
  final String comicId;
  final String chapterId;
  final Map<String, dynamic> extern;
  final UnifiedPluginChapter chapter;

  factory UnifiedPluginChapterResponse.fromMap(Map<String, dynamic> map) {
    return UnifiedPluginChapterResponse(
      source: map['source']?.toString() ?? '',
      comicId: map['comicId']?.toString() ?? '',
      chapterId: map['chapterId']?.toString() ?? '',
      extern: asMap(map['extern']),
      chapter: UnifiedPluginChapter.fromMap(asMap(map['chapter'])),
    );
  }
}

class UnifiedPluginDetailResponse {
  const UnifiedPluginDetailResponse({
    required this.source,
    required this.comicId,
    required this.extern,
    required this.normal,
    required this.raw,
  });

  final String source;
  final String comicId;
  final Map<String, dynamic> extern;
  final Map<String, dynamic> normal;
  final Map<String, dynamic> raw;

  factory UnifiedPluginDetailResponse.fromMap(Map<String, dynamic> map) {
    final data = asMap(map['data']);
    final normal = data.isNotEmpty ? asMap(data['normal']) : asMap(map['normal']);
    final raw = data.isNotEmpty ? asMap(data['raw']) : asMap(map['raw']);

    return UnifiedPluginDetailResponse(
      source: map['source']?.toString() ?? '',
      comicId: map['comicId']?.toString() ?? '',
      extern: asMap(map['extern']),
      normal: normal,
      raw: raw,
    );
  }
}

class UnifiedPluginEnvelope {
  const UnifiedPluginEnvelope({
    required this.source,
    required this.scheme,
    required this.data,
    required this.extern,
  });

  final String source;
  final Map<String, dynamic> scheme;
  final Map<String, dynamic> data;
  final Map<String, dynamic> extern;

  factory UnifiedPluginEnvelope.fromMap(Map<String, dynamic> map) {
    return UnifiedPluginEnvelope(
      source: map['source']?.toString() ?? '',
      scheme: asMap(map['scheme']),
      data: asMap(map['data']),
      extern: asMap(map['extern']),
    );
  }
}

Map<String, dynamic> asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map((entry) => MapEntry(entry.key.toString(), entry.value)),
    );
  }
  return const <String, dynamic>{};
}

List<dynamic> asList(dynamic value) {
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
