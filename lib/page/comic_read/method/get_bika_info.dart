import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/type/enum.dart';

import '../../download/json/comic_all_info_json/comic_all_info_json.dart'
    show comicAllInfoJsonFromJson;
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
  final response = await callUnifiedComicPlugin(
    from: From.bika,
    fnPath: 'getChapter',
    core: {'comicId': comicId, 'chapterId': epsId},
    extern: {'source': 'bika'},
  );
  final chapter = UnifiedPluginChapterResponse.fromMap(response).chapter;
  final docs = chapter.docs
      .map(
        (doc) => Doc(
          originalName: doc.originalName,
          path: doc.path,
          fileServer: doc.fileServer,
          id: doc.id,
        ),
      )
      .toList();

  return NormalComicEpInfo(
    length: chapter.length,
    epPages: chapter.epPages,
    docs: docs,
    epId: chapter.epId,
    epName: chapter.epName,
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
