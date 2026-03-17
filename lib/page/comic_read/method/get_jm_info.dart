import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart'
    show Doc;
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/jm/jm_download/json/download_info_json.dart';
import 'package:zephyr/type/enum.dart';

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
  final response = await callUnifiedComicPlugin(
    from: From.jm,
    fnPath: 'getChapter',
    core: {'chapterId': epId},
    extern: {'source': 'jm', 'path': '${JmConfig.baseUrl}/chapter'},
  );
  final chapter = UnifiedPluginChapterResponse.fromMap(response).chapter;
  final docs = chapter.docs
      .map((doc) {
        final path = doc.path;
        final fileServer = doc.fileServer;
        return Doc(
          originalName: doc.originalName.isEmpty ? path : doc.originalName,
          path: path,
          fileServer: fileServer.isEmpty ? getJmImagesUrl(epId, path) : fileServer,
          id: doc.id.isEmpty ? epId : doc.id,
        );
      })
      .toList();

  return NormalComicEpInfo(
    length: chapter.length,
    epPages: chapter.epPages,
    docs: docs,
    epId: chapter.epId.isEmpty ? epId : chapter.epId,
    epName: chapter.epName,
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
