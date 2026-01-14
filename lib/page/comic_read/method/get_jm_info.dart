import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart';
import 'package:zephyr/page/comic_read/json/jm_ep_info_json/jm_ep_info_json.dart'
    show JmEpInfoJson;
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/jm/jm_download/json/download_info_json.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/json/json_dispose.dart';

Future<NormalComicEpInfo> fetchJMMedia(
  String comicId,
  String epId,
  ComicEntryType type,
) async {
  if (type == ComicEntryType.download ||
      type == ComicEntryType.historyAndDownload) {
    return await fetchJMMediaFromLocal(comicId, epId);
  } else {
    return await fetchJMMediaFromNet(epId);
  }
}

Future<NormalComicEpInfo> fetchJMMediaFromNet(String epId) async {
  List<Doc> docsList = [];
  var result = CommonEpInfoJson(epId: '', epName: '', series: [], docs: []);
  await getEpInfo(epId).let(replaceNestedNull).let(JmEpInfoJson.fromJson).also((
    d,
  ) {
    for (var doc in d.images) {
      docsList.add(
        Doc(
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
            (s) => Series(
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

  return NormalComicEpInfo(
    length: result.docs.length,
    epPages: result.docs.length.toString(),
    docs: result.docs,
    epId: result.epId,
    epName: result.epName,
  );
}

Future<NormalComicEpInfo> fetchJMMediaFromLocal(
  String comicId,
  String epId,
) async {
  var downloadInfo = objectbox.jmDownloadBox
      .query(JmDownload_.comicId.equals(comicId))
      .build()
      .findFirst()!;

  // 如果在下载列表中没有找到的话
  if (!downloadInfo.epsIds.contains(epId)) {
    throw "No element";
  }

  // 因为在下载的时候是直接获取到了所有的章节信息，所以这个查找是一定能找到的，不论是否下载
  // 所以需要专门存储一个下载了几个章节的操作
  final comicInfo = downloadInfoJsonFromJson(downloadInfo.allInfo);
  final downloadEpsInfo = comicInfo.series;

  final epInfo = downloadEpsInfo.firstWhere((e) => e.id == epId);

  return NormalComicEpInfo(
    length: epInfo.info.images.length,
    epPages: epInfo.info.images.length.toString(),
    docs: epInfo.info.images
        .map(
          (e) => Doc(
            originalName: e,
            path: e,
            fileServer: getJmImagesUrl(epId, e),
            id: epId,
          ),
        )
        .toList(),
    epId: epId,
    epName: epInfo.name,
  );
}
