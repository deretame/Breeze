import 'dart:convert';

import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/download/adapters/download_chapter_adapter.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';

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
    this.storageChapterId = '',
    this.images = const [],
  });

  final String id;
  final String name;
  final int order;
  final String logicalKey;
  final String taskChapterId;
  final String storageChapterId;
  final List<UnifiedComicDownloadImage> images;

  factory UnifiedComicDownloadStoredChapter.fromMap(Map<String, dynamic> map) {
    final rawImages = (map['images'] as List?) ?? const [];
    return UnifiedComicDownloadStoredChapter(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      order: _toInt(map['order']?.toString() ?? '', 1),
      logicalKey: map['logicalKey']?.toString() ?? '',
      taskChapterId: map['taskChapterId']?.toString() ?? '',
      storageChapterId: map['storageChapterId']?.toString() ?? '',
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
    'storageChapterId': storageChapterId,
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
  return resolveStoredDownloadChaptersFromJson(
    chaptersJson: comic.chapters,
    detailJson: comic.detailJson,
  );
}

/// 纯 JSON 入口（可在后台 isolate 里调用）。
List<UnifiedComicDownloadStoredChapter> resolveStoredDownloadChaptersFromJson({
  required String chaptersJson,
  required String detailJson,
}) {
  final chaptersFromMain = _decodeListOfMaps(
    chaptersJson,
  ).map((e) => UnifiedComicDownloadStoredChapter.fromMap(e)).toList();
  if (chaptersFromMain.any((chapter) => chapter.images.isNotEmpty)) {
    return chaptersFromMain;
  }

  final chaptersFromDetail = _decodeStoredChaptersFromDetailJson(detailJson);
  if (chaptersFromDetail.isNotEmpty) {
    return chaptersFromDetail;
  }

  return chaptersFromMain;
}

/// 统一的下载章节读取入口。
///
/// 优先从 `comic.chapters` 读取，若为空则从 `detailJson.extern.downloadChapters`
/// fallback。返回的 [DownloadChapter] 已经把各种 legacy 字段（`logicalKey` /
/// `taskChapterId` / `storageChapterId` 等）统一成语义清晰的内部模型。
List<DownloadChapter> resolveDownloadChapters(UnifiedComicDownload comic) {
  const adapter = DownloadChapterAdapter();

  final mainChapters = _decodeListOfMaps(
    comic.chapters,
  ).map(adapter.fromStoredMap).toList();

  if (mainChapters.any((chapter) => chapter.images.isNotEmpty)) {
    return mainChapters;
  }

  final detailChapters = _decodeStoredChaptersFromDetailJson(
    comic.detailJson,
  ).map((chapter) => adapter.fromStoredMap(chapter.toMap())).toList();

  if (detailChapters.isNotEmpty) {
    return detailChapters;
  }

  return mainChapters;
}

/// 从在线详情构建全量章节目录快照（只含身份 + 顺序，不含图片）。
///
/// 下载入口用它给已下载章节排序；下载时用它校验章节是否在目录里。
/// 存放在 `detailJson.extern['chapterCatalog']`，不动数据库结构。
List<Map<String, dynamic>> buildChapterCatalog(List<Ep> eps) {
  return eps
      .map(
        (ep) => {
          'id': ep.id,
          'logicalKey': ep.logicalKey,
          'requestId': ep.requestId,
          'order': ep.order,
          'name': ep.name,
        },
      )
      .toList();
}

/// 读取记录里的目录快照原始数据，没有返回空数组。
List<Map<String, dynamic>> readChapterCatalogMaps(UnifiedComicDownload record) {
  try {
    final detail = jsonDecode(record.detailJson);
    if (detail is! Map) return const [];
    final extern = Map<String, dynamic>.from(
      detail['extern'] as Map? ?? const {},
    );
    final raw = extern['chapterCatalog'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  } catch (_) {
    return const [];
  }
}

/// 读取记录里的目录快照（身份视图），没有返回空数组。
List<DownloadChapter> readChapterCatalog(UnifiedComicDownload record) {
  try {
    return readChapterCatalogMaps(record).map((map) {
      final logicalKey = map['logicalKey']?.toString().trim() ?? '';
      final id = map['id']?.toString().trim() ?? '';
      final requestId = map['requestId']?.toString().trim() ?? '';
      final resolvedId = logicalKey.isNotEmpty
          ? logicalKey
          : (id.isNotEmpty ? id : requestId);
      return DownloadChapter(
        id: resolvedId,
        displayName: map['name']?.toString() ?? '',
        order: int.tryParse(map['order']?.toString() ?? '') ?? 0,
        requestId: requestId.isNotEmpty ? requestId : null,
        extern: const {},
        images: const [],
      );
    }).toList();
  } catch (_) {
    return const [];
  }
}

/// 按目录快照顺序排列已下载章节，快照里没有的缀在最后（保持原相对顺序）。
///
/// 只比身份，不碰 order。详情页显示与导出共用。
List<DownloadChapter> sortDownloadChaptersByCatalog(
  List<DownloadChapter> chapters,
  List<DownloadChapter> catalog,
) {
  if (chapters.isEmpty || catalog.isEmpty) return chapters;
  final remaining = List<DownloadChapter>.from(chapters);
  final ordered = <DownloadChapter>[];
  for (final entry in catalog) {
    final index = remaining.indexWhere(
      (c) => downloadChapterIdentityMatches(c, entry),
    );
    if (index >= 0) ordered.add(remaining.removeAt(index));
  }
  if (ordered.length == chapters.length) {
    var same = true;
    for (var i = 0; i < ordered.length; i++) {
      if (!identical(ordered[i], chapters[i])) {
        same = false;
        break;
      }
    }
    if (same) return chapters;
  }
  return ordered..addAll(remaining);
}

/// 在章节 map 列表里按身份找下标，找不到返回 -1（调用方回退下标）。
///
/// 先比 logicalKey / taskChapterId / requestId；双方都没有这些强身份 key
/// 时（如纯老数据/裸包）才按 id 比对。storage 系 id 可能多章共享，
/// 绝不单独作为判同依据。
int matchDownloadChapterIndex(
  List<Map<String, dynamic>> candidates,
  Map<String, dynamic> target,
) {
  bool hasStrongKeys(Map m) =>
      (m['logicalKey']?.toString().trim().isNotEmpty ?? false) ||
      (m['taskChapterId']?.toString().trim().isNotEmpty ?? false) ||
      (m['requestId']?.toString().trim().isNotEmpty ?? false);

  Set<String> strongKeysOf(Map m) => {
    m['logicalKey']?.toString().trim() ?? '',
    m['taskChapterId']?.toString().trim() ?? '',
    m['requestId']?.toString().trim() ?? '',
  }..remove('');

  if (hasStrongKeys(target)) {
    final targetKeys = strongKeysOf(target);
    for (var i = 0; i < candidates.length; i++) {
      final candidate = candidates[i];
      if (!hasStrongKeys(candidate)) continue;
      if (targetKeys.intersection(strongKeysOf(candidate)).isNotEmpty) {
        return i;
      }
    }
    return -1;
  }

  final id = target['id']?.toString().trim() ?? '';
  if (id.isEmpty) return -1;
  for (var i = 0; i < candidates.length; i++) {
    if (candidates[i]['id']?.toString().trim() == id) return i;
  }
  return -1;
}

/// 两个章节身份是否相同（只比 logical / request 系，不碰 order）。
bool downloadChapterIdentityMatches(DownloadChapter a, DownloadChapter b) {
  final aKeys = {a.id.trim(), a.effectiveRequestId.trim()}..remove('');
  final bKeys = {b.id.trim(), b.effectiveRequestId.trim()}..remove('');
  if (aKeys.isEmpty || bKeys.isEmpty) return false;
  return aKeys.intersection(bKeys).isNotEmpty;
}

/// 把已存储章节重建为详情 `eps`（`Ep.id` 取宿主匹配 key，而非 storage key）。
///
/// 下载提交与单章删除共用，保持两处写入的 `detailJson.eps` 结构一致。
List<Ep> buildDownloadEps(
  List<UnifiedComicDownloadStoredChapter> storedChapters,
) {
  return storedChapters
      .map(
        (chapter) => Ep(
          id: chapter.logicalKey,
          name: chapter.name,
          order: chapter.order,
          requestId: chapter.taskChapterId,
          storageChapterId: chapter.storageChapterId.isNotEmpty
              ? chapter.storageChapterId
              : chapter.id,
          logicalKey: chapter.logicalKey,
        ),
      )
      .toList();
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
