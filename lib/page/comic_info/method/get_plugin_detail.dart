import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart' as jm;
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/comic_info/models/all_info.dart';
import 'package:zephyr/type/enum.dart';

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

  final From from;
  final normal.NormalComicAllInfo normalInfo;
  final Map<String, dynamic> raw;

  bool get isBika => from == From.bika;

  bool get isJm => from == From.jm;

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
    required this.sort,
    required this.routeOrder,
  });

  final String id;
  final String name;
  final int sort;
  final int routeOrder;
}

Future<PluginComicDetail> getComicDetailByPlugin(
  String comicId,
  From from,
) async {
  final payload = from == From.bika
      ? _buildBikaPayload(comicId)
      : _buildJmPayload(comicId);

  final map = await callUnifiedComicPlugin(
    from: from,
    fnPath: 'getComicDetail',
    core: payload,
    extern: {'source': from.name, 'comicId': comicId},
  );
  final detail = UnifiedPluginDetailResponse.fromMap(map);
  final normalInfo = normal.NormalComicAllInfo.fromJson(detail.normal);
  final source = PluginComicDetailSource(
    from: from,
    normalInfo: normalInfo,
    raw: detail.raw,
  );

  return PluginComicDetail(normalInfo: normalInfo, source: source);
}

Map<String, dynamic> _buildBikaPayload(String comicId) {
  final settings = objectbox.userSettingBox.get(1)!.bikaSetting;
  return {
    'comicId': comicId,
    'authorization': settings.authorization,
    'settings': {
      'proxy': settings.proxy,
      'imageQuality': settings.imageQuality,
      'authorization': settings.authorization,
    },
  };
}

Map<String, dynamic> _buildJmPayload(String comicId) {
  return {
    'comicId': comicId,
    'path': '${JmConfig.baseUrl}/album',
    'useJwt': true,
    'jwtToken': JmConfig.jwt,
  };
}

List<UnifiedComicChapterRef> resolveUnifiedComicChapters(
  dynamic comicInfo,
  From from,
) {
  if (comicInfo is PluginComicDetailSource) {
    if (from == From.jm) {
      return comicInfo.eps
          .map(
            (ep) => UnifiedComicChapterRef(
              id: ep.id,
              name: ep.name,
              sort: ep.order,
              routeOrder: _toInt(ep.id, ep.order),
            ),
          )
          .toList();
    }
    return comicInfo.eps
        .map(
          (ep) => UnifiedComicChapterRef(
            id: ep.id,
            name: ep.name,
            sort: ep.order,
            routeOrder: ep.order,
          ),
        )
        .toList();
  }

  if (from == From.bika && comicInfo is AllInfo) {
    return comicInfo.eps
        .map(
          (ep) => UnifiedComicChapterRef(
            id: ep.id,
            name: ep.title,
            sort: ep.order,
            routeOrder: ep.order,
          ),
        )
        .toList();
  }

  if (from == From.jm && comicInfo is jm.JmComicInfoJson) {
    return comicInfo.series
        .map(
          (series) => UnifiedComicChapterRef(
            id: series.id,
            name: series.name,
            sort: _toInt(series.sort, 0),
            routeOrder: _toInt(series.id, 0),
          ),
        )
        .toList();
  }

  return const <UnifiedComicChapterRef>[];
}

int _toInt(Object? value, int fallback) {
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
