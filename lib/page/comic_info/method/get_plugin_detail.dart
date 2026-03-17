import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_info/json/bika/comic_info/comic_info.dart'
    as bika_comic;
import 'package:zephyr/page/comic_info/json/bika/eps/eps.dart' as bika_eps;
import 'package:zephyr/page/comic_info/json/bika/recommend/recommend_json.dart'
    as bika_recommend;
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart' as jm;
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart'
    as normal;
import 'package:zephyr/page/comic_info/models/all_info.dart';
import 'package:zephyr/type/enum.dart';

class PluginComicDetail {
  const PluginComicDetail({required this.normalInfo, required this.sourceInfo});

  final normal.NormalComicAllInfo normalInfo;
  final dynamic sourceInfo;
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

  if (from == From.bika) {
    final sourceInfo = _decodeBikaSourceInfo(detail.raw);
    return PluginComicDetail(normalInfo: normalInfo, sourceInfo: sourceInfo);
  }

  final sourceInfo = _decodeJmSourceInfo(detail.raw);
  return PluginComicDetail(normalInfo: normalInfo, sourceInfo: sourceInfo);
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

AllInfo _decodeBikaSourceInfo(Map<String, dynamic> raw) {
  final comic = bika_comic.Comic.fromJson(asMap(raw['comicInfo']));
  final eps = asList(raw['eps']).map((item) {
    return bika_eps.Doc.fromJson(asMap(item));
  }).toList();
  final recommend = asList(raw['recommend']).map((item) {
    return bika_recommend.Comic.fromJson(asMap(item));
  }).toList();

  return AllInfo(comicInfo: comic, eps: eps, recommendJson: recommend);
}

jm.JmComicInfoJson _decodeJmSourceInfo(Map<String, dynamic> raw) {
  final comic = jm.JmComicInfoJson.fromJson(asMap(raw['comicInfo']));
  if (comic.series.isNotEmpty) {
    return comic;
  }
  return comic.copyWith(
    series: [jm.Series(id: comic.id.toString(), name: '第1话', sort: 'null')],
  );
}
