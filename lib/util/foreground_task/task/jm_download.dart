import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/bookshelf/json/download/comic_all_info_json.dart';
import 'package:zephyr/page/jm/download/json/download_info_json.dart';
import 'package:zephyr/page/jm/jm_comic_info/json/jm_comic_info_json.dart'
    as base_info;
import 'package:zephyr/src/rust/frb_generated.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/foreground_task/data/download_task_json.dart';
import 'package:zephyr/util/foreground_task/task/bika_download.dart';
import 'package:zephyr/util/json_dispose.dart';

Future<void> jmDownloadTask(DownloadTaskJson task) async {
  // 先获取一下基本的信息
  final comicInfo = await getJmComicInfo(task.comicId);
  List<String> epIds = task.selectedChapters.map((e) => e.toString()).toList();
  if (epIds.isEmpty) epIds = [comicInfo.id.toString()];

  final epsList = await fetchJMMedia(epIds);

  final downloadInfoJson = comicInfo2DownloadInfoJson(comicInfo);

  final updatedSeries =
      downloadInfoJson.series.map((series) {
        return series.copyWith(
          info: epsList.firstWhere((e) => e.id.toString() == series.id),
        );
      }).toList();

  final updatedDownloadInfo = downloadInfoJson.copyWith(series: updatedSeries);

  final temp = downloadInfoJsonToJson(updatedDownloadInfo);

  logger.d("updatedDownloadInfo: $temp");

  List<String> epsTitle = [];

  for (var series in updatedDownloadInfo.series) {
    if (task.selectedChapters.contains(series.id)) {
      epsTitle.add(series.info.name);
    }
  }

  logger.d("epsTitle: $epsTitle");

  await downloadComic(updatedDownloadInfo, task.selectedChapters);

  await sendSystemNotification("下载完成", "${updatedDownloadInfo.name}下载完成");

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
    } catch (e) {
      logger.e(e);
    }
  }
  return comicInfo!;
}

Future<List<Info>> fetchJMMedia(List<String> epIds) async {
  final List<Future<Info>> fetchTasks =
      epIds.map((epId) async {
        while (true) {
          try {
            final rawInfo = await getEpInfo(epId);
            final cleanedInfo = replaceNestedNull(rawInfo);
            final infoObject = Info.fromJson(cleanedInfo);

            var series = infoObject.series.toList();
            series.removeWhere((s) => s.sort == '0');
            final newSeries =
                series
                    .map((s) => s.copyWith(name: '第${s.sort}话 ${s.name}'))
                    .toList();

            return infoObject.copyWith(series: newSeries);
          } catch (e) {
            logger.e(e);
          }
        }
      }).toList();
  final List<Info> docsList = await Future.wait(fetchTasks);

  docsList.sort((a, b) => a.id.compareTo(b.id));

  return docsList;
}

DownloadInfoJson comicInfo2DownloadInfoJson(
  base_info.JmComicInfoJson comicInfo,
) {
  var result = DownloadInfoJson(
    id: comicInfo.id,
    name: comicInfo.name,
    images: comicInfo.images,
    addtime: comicInfo.addtime,
    description: comicInfo.description,
    totalViews: comicInfo.totalViews,
    likes: comicInfo.likes,
    series: [],
    seriesId: comicInfo.seriesId,
    commentTotal: comicInfo.commentTotal,
    author: comicInfo.author,
    tags: comicInfo.tags,
    works: comicInfo.works,
    actors: comicInfo.actors,
    liked: comicInfo.liked,
    isFavorite: comicInfo.isFavorite,
    isAids: comicInfo.isAids,
    price: comicInfo.price,
    purchased: comicInfo.purchased,
    relatedList: [],
  );

  List<DownloadInfoJsonSeries> seriesList = [];

  if (comicInfo.series.isEmpty) {
    seriesList.add(
      DownloadInfoJsonSeries(
        id: comicInfo.id.toString(),
        name: comicInfo.name,
        sort: 'null',
        info: Info(
          id: 0,
          series: [],
          tags: '',
          name: '',
          images: [],
          addtime: '',
          seriesId: '',
          isFavorite: false,
          liked: false,
        ),
      ),
    );
  }

  for (var series in comicInfo.series) {
    seriesList.add(
      DownloadInfoJsonSeries(
        id: series.id,
        name: series.name,
        sort: series.sort,
        info: Info(
          id: 0,
          series: [],
          tags: '',
          name: '',
          images: [],
          addtime: '',
          seriesId: '',
          isFavorite: false,
          liked: false,
        ),
      ),
    );
  }

  return result.copyWith(series: seriesList);
}

Future<void> downloadComic(
  DownloadInfoJson downloadInfoJson,
  List<String> selectedChapters,
) async {
  await RustLib.init();
  final selectedEps =
      downloadInfoJson.series
          .where((e) => selectedChapters.contains(e.id))
          .toList();

  final List<PagesDoc> docsList = [];

  for (var series in selectedEps) {
    for (var image in series.info.images) {
      docsList.add(
        PagesDoc(
          id: series.id.toString(),
          media: Thumb(
            originalName: image,
            path: image,
            fileServer: getJmImagesUrl(series.id.toString(), image),
          ),
          docId: series.id.toString(),
        ),
      );
    }
  }

  final List<Future<void>> downloadTasks =
      docsList.map((doc) async {
        await downloadPicture(
          from: 'jm',
          url: doc.media.fileServer,
          path: doc.media.path,
          cartoonId: downloadInfoJson.id.toString(),
          pictureType: 'comic',
          chapterId: doc.docId,
        );
      }).toList();

  await Future.wait(downloadTasks);
}
