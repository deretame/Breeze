import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart' as jm;
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json/json_dispose.dart';

Future<jm.JmComicInfoJson> getJmComicAllInfo(
  String comicId,
  ComicEntryType type,
) async {
  if (type == ComicEntryType.download) {
    return getJmComicAllInfoFromLocal(comicId, type);
  }

  return await getComicInfo(comicId)
      .let(replaceNestedNull)
      .let((d) {
        d['price'] = d['price'].toString();
        d['purchased'] = d['purchased'].toString();
        return d;
      })
      .let(jm.JmComicInfoJson.fromJson)
      .let((d) {
        var series = d.series.toList();
        series.removeWhere((s) => s.sort == '0');
        final newSeries = series
            .map((s) => s.copyWith(name: '第${s.sort}话 ${s.name}'))
            .toList();
        return d.copyWith(series: newSeries);
      })
      .let((d) => _prepareComicInfo(d, type));
}

Future<jm.JmComicInfoJson> getJmComicAllInfoFromLocal(
  String comicId,
  ComicEntryType type,
) async {
  var jmDownload = objectbox.unifiedDownloadBox
      .query(UnifiedComicDownload_.uniqueKey.equals('jm:$comicId'))
      .build()
      .findFirst();
  final detail = jsonDecode(jmDownload!.detailJson) as Map<String, dynamic>;
  final comic = detail['comicInfo'] as Map<String, dynamic>? ?? const {};
  final metadata = (comic['metadata'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final series = (detail['eps'] as List?)?.map((e) {
        final ep = (e as Map).cast<String, dynamic>();
        return jm.Series(
          id: ep['id']?.toString() ?? '',
          name: ep['name']?.toString() ?? '',
          sort: ep['order']?.toString() ?? '1',
        );
      }).toList() ??
      const <jm.Series>[];
  final comicInfo = jm.JmComicInfoJson(
    id: int.tryParse(comicId) ?? 0,
    name: comic['title']?.toString() ?? jmDownload.title,
    images: const [],
    addtime: '0',
    description: comic['description']?.toString() ?? jmDownload.description,
    totalViews: jmDownload.totalViews.toString(),
    likes: jmDownload.totalLikes.toString(),
    series: series,
    seriesId: '',
    commentTotal: jmDownload.totalComments.toString(),
    author: _metadataValues(metadata, 'author'),
    tags: _metadataValues(metadata, 'tags'),
    works: _metadataValues(metadata, 'works'),
    actors: _metadataValues(metadata, 'actors'),
    relatedList: const [],
    liked: jmDownload.isLiked,
    isFavorite: jmDownload.isFavourite,
    isAids: false,
    price: '0',
    purchased: '0',
  );
  return _prepareComicInfo(comicInfo, type);
}

jm.JmComicInfoJson _prepareComicInfo(
  jm.JmComicInfoJson comicInfo,
  ComicEntryType type, {
  JmDownload? jmDownload,
}) {
  jm.JmComicInfoJson temp = comicInfo;
  if (type != ComicEntryType.download) {
    if (comicInfo.series.isEmpty) {
      temp = comicInfo.copyWith(
        series: [
          jm.Series(id: comicInfo.id.toString(), name: "第1话", sort: 'null'),
        ],
      );
    }
  } else {
    final epsIds = jmDownload!.epsIds;
    final series = comicInfo.series;
    final newSeries = series
        .where((s) => epsIds.contains(s.id.toString()))
        .toList();
    temp = comicInfo.copyWith(series: newSeries);
  }
  return temp;
}

List<String> _metadataValues(List<Map<String, dynamic>> metadata, String type) {
  final target = metadata.where((e) => e['type']?.toString() == type);
  return target
      .expand((e) => (e['value'] as List?) ?? const [])
      .map((e) => (e as Map)['name']?.toString() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
}
