import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/plugin/plugin_constants.dart';

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

  bool get isBika => from == kBikaPluginUuid;

  bool get isJm => from == kJmPluginUuid;

  Map<String, dynamic> get rawComicInfo => asMap(raw['comicInfo']);

  List<normal.Ep> get eps => normalInfo.eps;

  bool get isJmSeriesEmpty => isJm && eps.isEmpty;

  String get comicId => normalInfo.comicInfo.id;

  String get title =>
      rawComicInfo['name']?.toString() ?? normalInfo.comicInfo.title;
}

class UnifiedComicChapterRef {
  const UnifiedComicChapterRef({
    required this.id,
    required this.name,
    required this.order,
  });

  final String id;
  final String name;
  final int order;
}

Future<PluginComicDetail> getComicDetailByPlugin(
  String comicId,
  String from, {
  String? pluginId,
}) async {
  final resolvedPluginId = sanitizePluginId(
    pluginId?.trim().isNotEmpty == true
        ? pluginId!.trim()
        : sanitizePluginId(from),
  );
  final resolvedFrom = sanitizePluginId(resolvedPluginId);
  final payload = from == kBikaPluginUuid
      ? _buildBikaPayload(comicId)
      : _buildJmPayload(comicId);

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
}) async {
  final resolvedPluginId = sanitizePluginId(
    pluginId?.trim().isNotEmpty == true
        ? pluginId!.trim()
        : sanitizePluginId(from),
  );
  final payload = from == kBikaPluginUuid
      ? _buildBikaChapterPayload(comicId, chapterId)
      : _buildJmChapterPayload(comicId, chapterId);

  final map = await callUnifiedComicPlugin(
    from: resolvedPluginId,
    fnPath: 'getChapter',
    core: payload,
    extern: const <String, dynamic>{},
    runtimeName: runtimeName,
  );
  return UnifiedPluginChapterResponse.fromMap(map);
}

Map<String, dynamic> _buildBikaPayload(String comicId) {
  final settings = objectbox.userSettingBox.get(1)!.bikaSetting;
  return {
    'comicId': comicId,
    'settings': {
      'proxy': settings.proxy,
      'imageQuality': settings.imageQuality,
    },
  };
}

Map<String, dynamic> _buildJmPayload(String comicId) {
  return {'comicId': comicId, 'useJwt': true};
}

Map<String, dynamic> _buildBikaChapterPayload(
  String comicId,
  String chapterId,
) {
  return {
    'comicId': comicId,
    'chapterId': chapterId,
    'settings': {
      'proxy': objectbox.userSettingBox.get(1)!.bikaSetting.proxy,
      'imageQuality': 'original',
    },
  };
}

Map<String, dynamic> _buildJmChapterPayload(String comicId, String chapterId) {
  return {'comicId': comicId, 'chapterId': chapterId, 'useJwt': true};
}

List<UnifiedComicChapterRef> resolveUnifiedComicChapters(
  dynamic comicInfo,
  String from,
) {
  if (comicInfo is PluginComicDetailSource) {
    return comicInfo.eps
        .map(
          (ep) =>
              UnifiedComicChapterRef(id: ep.id, name: ep.name, order: ep.order),
        )
        .toList();
  }

  if (comicInfo is UnifiedComicDownload) {
    return (comicInfo.chapters ?? const <Map<String, dynamic>>[])
        .map(
          (ep) => UnifiedComicChapterRef(
            id: ep['id']?.toString() ?? '',
            name: ep['name']?.toString() ?? '',
            order: _toInt(ep['order'], 0),
          ),
        )
        .toList();
  }

  return const <UnifiedComicChapterRef>[];
}

int _toInt(Object? value, int fallback) {
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
