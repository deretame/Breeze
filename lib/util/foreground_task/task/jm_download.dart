import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart'
    as c;
import 'package:zephyr/page/comic_read/json/jm_ep_info_json/jm_ep_info_json.dart';
import 'package:zephyr/page/jm/download/json/download_info_json.dart';
import 'package:zephyr/page/jm/jm_comic_info/json/jm_comic_info_json.dart'
    as base_info;
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/task/bika_download.dart';
import 'package:zephyr/util/json_dispose.dart';

Future<void> jmDownloadTask(DownloadTaskJson task) async {
  // 先获取一下基本的信息
  final comicInfo = await getJmComicInfo(task.comicId);
  final epsList = await fetchJMMedia(
    comicInfo.series.map((s) => s.id).toList(),
  );

  if (comicInfo.series.isEmpty) {
    final data = DownloadInfoJsonSeries(
      id: '',
      name: '',
      sort: '',
      info: Info(
        epId: comicInfo.id.toString(),
        epName: comicInfo.name,
        series: [],
        docs:
            epsList.first.docs
                .map(
                  (d) => Doc(
                    originalName: d.originalName,
                    path: d.path,
                    fileServer: d.fileServer,
                    id: d.id,
                  ),
                )
                .toList(),
      ),
    );
  }

  List<String> epsTitle = [];

  // var comicAllInfoJson = DownloadInfoJson(
  //   comic: comicInfo,
  //   eps: Eps(docs: epsDocs),
  // );

  // final coverPath = await downloadPicture(
  //   from: 'bika',
  //   url: comicInfo.thumb.fileServer,
  //   path: comicInfo.thumb.path,
  //   cartoonId: comicInfo.id,
  //   pictureType: 'cover',
  //   chapterId: comicInfo.id,
  // );

  // if (coverPath.contains('404')) {
  //   comicAllInfoJson = comicAllInfoJson.copyWith(
  //     comic: comicAllInfoJson.comic.copyWith(
  //       thumb: comicAllInfoJson.comic.thumb.copyWith(fileServer: ""),
  //     ),
  //   );
  // }

  // List<PagesDoc> pagesDocs = [];

  // for (var media in imageData) {
  //   for (var doc in media.docs) {
  //     pagesDocs.add(doc);
  //   }
  // }

  // final List<Future<void>> downloadTasks =
  //     pagesDocs.map((doc) async {
  //       await downloadPicture(
  //         from: 'bika',
  //         url: doc.media.fileServer,
  //         path: doc.media.path,
  //         cartoonId: comicInfo.id,
  //         pictureType: 'comic',
  //         chapterId: doc.docId,
  //       );
  //     }).toList();

  // await Future.wait(downloadTasks);

  await sendSystemNotification("下载完成", "${comicInfo.name}下载完成");

  FlutterForegroundTask.stopService();
}

Future<base_info.JmComicInfoJson> getJmComicInfo(String comicId) async {
  base_info.JmComicInfoJson? comicInfo;
  while (true) {
    try {
      comicInfo = await getComicInfo(
        comicId,
      ).let(replaceNestedNull).let(base_info.JmComicInfoJson.fromJson).let((d) {
        var series = d.series.toList();
        series.removeWhere((s) => s.sort == '0');
        final newSeries =
            series
                .map((s) => s.copyWith(name: '第${s.sort}话 ${s.name}'))
                .toList();
        return d.copyWith(series: newSeries);
      });
      break;
    } catch (_) {}
  }
  return comicInfo!;
}

Future<List<c.CommonEpInfoJson>> fetchJMMedia(List<String> epIds) async {
  List<c.Doc> docsList = [];
  List<c.CommonEpInfoJson> results = [];
  for (var epId in epIds) {
    var result = c.CommonEpInfoJson(epId: '', epName: '', series: [], docs: []);
    while (true) {
      try {
        await getEpInfo(
          epId,
        ).let(replaceNestedNull).let(JmEpInfoJson.fromJson).also((d) {
          for (var doc in d.images) {
            docsList.add(
              c.Doc(
                originalName: doc,
                path: doc,
                fileServer: getJmImagesUrl(epId, doc),
                id: d.id.let(toString),
              ),
            );
          }
          result = result.copyWith(
            epId: d.id.let(toString),
            epName: d.name,
            series: d.series
                .map(
                  (s) => c.Series(
                    id: s.id.let(toString),
                    name: "第${s.sort}话 ${s.name}",
                    sort: s.sort,
                  ),
                )
                .toList()
                .let((d) => d..removeWhere((e) => e.sort == '0')),
            docs: docsList,
          );
        });
        break;
      } catch (_) {}
    }
    results.add(result);
  }

  return results;
}
