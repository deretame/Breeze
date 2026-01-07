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
  var jmDownload = objectbox.jmDownloadBox
      .query(JmDownload_.comicId.equals(comicId))
      .build()
      .findFirst();
  var comicInfo = jmDownload!.allInfo.let(jm.jmComicInfoJsonFromJson);
  return _prepareComicInfo(comicInfo, type, jmDownload: jmDownload);
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
