import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/bika/http_request.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/type/enum.dart';

import '../../download/json/comic_all_info_json/comic_all_info_json.dart'
    show comicAllInfoJsonFromJson;
import '../json/bika_ep_info_json/page.dart' show Page;
import '../json/common_ep_info_json/common_ep_info_json.dart';

Future<NormalComicEpInfo> getBikaInfo(
  String comicId,
  int epsId,
  ComicEntryType type,
) async {
  final isDownload =
      type == ComicEntryType.download ||
      type == ComicEntryType.historyAndDownload;
  if (isDownload) {
    return await getBikaInfoFromLocal(comicId, epsId);
  } else {
    return await getBikaInfoFromNet(comicId, epsId);
  }
}

Future<NormalComicEpInfo> getBikaInfoFromNet(String comicId, int epsId) async {
  int page = 1, pages = 1;
  List<Doc> docsList = [];
  String epId = '';
  String epName = '';
  do {
    var result = await getPages(comicId, epsId, page);
    var temp = Page.fromJson(result);
    epId = temp.data.ep.id;
    epName = temp.data.ep.title;
    page += 1;
    pages = temp.data.pages.pages;
    for (var doc in temp.data.pages.docs) {
      docsList.add(
        Doc(
          originalName: doc.media.originalName,
          path: doc.media.path,
          fileServer: doc.media.fileServer,
          id: doc.id,
        ),
      );
    }
  } while (page <= pages);

  return NormalComicEpInfo(
    length: docsList.length,
    epPages: docsList.length.toString(),
    docs: docsList,
    epId: epId,
    epName: epName,
  );
}

Future<NormalComicEpInfo> getBikaInfoFromLocal(
  String comicId,
  int epsId,
) async {
  var temp = objectbox.bikaDownloadBox
      .query(BikaComicDownload_.comicId.equals(comicId))
      .build()
      .findFirst()!
      .comicInfoAll;
  final downloadEpsInfo = comicAllInfoJsonFromJson(temp).eps;

  final epInfo = downloadEpsInfo.docs.firstWhere((e) => e.order == epsId);

  return NormalComicEpInfo(
    length: epInfo.pages.docs.length,
    epPages: epInfo.pages.docs.length.toString(),
    docs: epInfo.pages.docs
        .map(
          (e) => Doc(
            originalName: e.media.originalName,
            path: e.media.path,
            fileServer: e.media.fileServer,
            id: epInfo.id,
          ),
        )
        .toList(),
    epId: epInfo.id,
    epName: epInfo.title,
  );
}
