import 'dart:convert';

import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/object_box/model.dart';

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
    this.extern = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final int order;
  final Map<String, dynamic> extern;
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
    return comicInfo.eps
        .map(
          (ep) => UnifiedComicChapterRef(
            id: ep.id,
            name: ep.name,
            order: ep.order,
            extern: Map<String, dynamic>.from(ep.extern),
          ),
        )
        .toList();
  }

  if (comicInfo is UnifiedComicDownload) {
    return _decodeListOfMaps(comicInfo.chapters)
        .map(
          (ep) => UnifiedComicChapterRef(
            id: ep['id']?.toString() ?? '',
            name: ep['name']?.toString() ?? '',
            order: _toInt(ep['order'], 0),
            extern: asMap(ep['extern']),
          ),
        )
        .toList();
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
