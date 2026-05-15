import 'dart:convert';

import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;

class PluginComicDetail {
  const PluginComicDetail({required this.normalInfo, required this.source});

  final normal.NormalComicAllInfo normalInfo;
  final PluginComicDetailSource source;
}

class PluginComicDetailSource {
  const PluginComicDetailSource({
    required this.from,
    required this.normalInfo,
    required this.raw,
  });

  final String from;
  final normal.NormalComicAllInfo normalInfo;
  final Map<String, dynamic> raw;

  Map<String, dynamic> get rawComicInfo => asMap(raw['comicInfo']);

  List<normal.Ep> get eps => normalInfo.eps;

  bool get isSeriesEmpty => eps.isEmpty;

  String get comicId => normalInfo.comicInfo.id;

  String get title =>
      rawComicInfo['name']?.toString() ?? normalInfo.comicInfo.title;
}

class UnifiedComicChapterRef {
  const UnifiedComicChapterRef({
    required this.id,
    required this.name,
    required this.order,
    this.requestId = '',
    this.storageChapterId = '',
    this.logicalKey = '',
    this.extern = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final int order;
  final String requestId;
  final String storageChapterId;
  final String logicalKey;
  final Map<String, dynamic> extern;
}

String resolveUnifiedComicChapterKey(UnifiedComicChapterRef chapter) {
  final logicalKey = chapter.logicalKey.trim();
  if (logicalKey.isNotEmpty) {
    return logicalKey;
  }

  final chapterId = chapter.id.trim();
  if (chapterId.isNotEmpty) {
    return chapterId;
  }

  return chapter.order.toString();
}

UnifiedComicChapterRef? resolveUnifiedComicChapterRef(
  dynamic comicInfo,
  String from, {
  String? chapterId,
  int? order,
}) {
  final chapters = resolveUnifiedComicChapters(comicInfo, from);
  if (chapters.isEmpty) {
    return null;
  }

  final normalizedChapterId = (chapterId ?? '').trim();
  if (normalizedChapterId.isNotEmpty) {
    for (final chapter in chapters) {
      if (_matchesChapterRef(chapter, normalizedChapterId)) {
        return chapter;
      }
    }
  }

  if (order != null) {
    for (final chapter in chapters) {
      if (chapter.order == order) {
        return chapter;
      }
    }

    for (final chapter in chapters) {
      if (resolveUnifiedComicChapterKey(chapter) == order.toString()) {
        return chapter;
      }
    }
  }

  return chapters.first;
}

Future<PluginComicDetail> getComicDetailByPlugin(
  String comicId,
  String from, {
  String? pluginId,
}) async {
  final resolvedPluginId =
      (pluginId?.trim().isNotEmpty == true ? pluginId!.trim() : from.trim())
          .trim();
  final resolvedFrom = (resolvedPluginId).trim();
  final payload = {'comicId': comicId};

  final map = await callUnifiedComicPlugin(
    from: resolvedPluginId,
    fnPath: 'getComicDetail',
    core: payload,
    extern: const <String, dynamic>{},
  );
  final detail = UnifiedPluginDetailResponse.fromMap(map);
  final normalInfo = normal.NormalComicAllInfo.fromJson(detail.normal);
  final source = PluginComicDetailSource(
    from: resolvedFrom.isEmpty ? from : resolvedFrom,
    normalInfo: normalInfo,
    raw: detail.raw,
  );

  return PluginComicDetail(normalInfo: normalInfo, source: source);
}

Future<void> preparePluginDownloadRuntime({
  required String from,
  String? pluginId,
  required String runtimeName,
  required String taskGroupKey,
}) async {
  return;
}

Future<UnifiedPluginChapterResponse> getComicChapterByPlugin(
  String comicId,
  String chapterId,
  String from, {
  String? pluginId,
  String? runtimeName,
  Map<String, dynamic> extern = const <String, dynamic>{},
}) async {
  final resolvedPluginId =
      (pluginId?.trim().isNotEmpty == true ? pluginId!.trim() : from.trim())
          .trim();
  final payload = {'comicId': comicId, 'chapterId': chapterId};

  final map = await callUnifiedComicPlugin(
    from: resolvedPluginId,
    fnPath: 'getChapter',
    core: payload,
    extern: extern,
    runtimeName: runtimeName,
  );
  return UnifiedPluginChapterResponse.fromMap(map);
}

List<UnifiedComicChapterRef> resolveUnifiedComicChapters(
  dynamic comicInfo,
  String from,
) {
  if (comicInfo is PluginComicDetailSource) {
    return comicInfo.eps.map((ep) {
      final extern = Map<String, dynamic>.from(ep.extern);
      return UnifiedComicChapterRef(
        id: ep.id,
        name: ep.name,
        order: ep.order,
        requestId: ep.requestId.trim(),
        storageChapterId: ep.storageChapterId.trim(),
        logicalKey: ep.logicalKey.trim(),
        extern: extern,
      );
    }).toList();
  }

  if (comicInfo is UnifiedComicDownload) {
    return _decodeListOfMaps(comicInfo.chapters).map((ep) {
      final storageChapterId =
          ep['storageChapterId']?.toString().trim() ??
          ep['id']?.toString().trim() ??
          '';
      return UnifiedComicChapterRef(
        id: ep['id']?.toString() ?? '',
        name: ep['name']?.toString() ?? '',
        order: _toInt(ep['order'], 0),
        requestId: ep['taskChapterId']?.toString() ?? '',
        storageChapterId: storageChapterId,
        logicalKey: ep['logicalKey']?.toString() ?? '',
        extern: asMap(ep['extern']),
      );
    }).toList();
  }

  return const <UnifiedComicChapterRef>[];
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

int _toInt(Object? value, int fallback) {
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _matchesChapterRef(UnifiedComicChapterRef chapter, String candidate) {
  if (resolveUnifiedComicChapterKey(chapter) == candidate) {
    return true;
  }
  if (chapter.logicalKey.trim() == candidate) {
    return true;
  }
  if (chapter.requestId.trim() == candidate) {
    return true;
  }
  if (chapter.id.trim() == candidate) {
    return true;
  }
  return chapter.order.toString() == candidate;
}
