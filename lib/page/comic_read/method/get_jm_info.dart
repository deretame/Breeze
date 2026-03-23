import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart'
    show Doc;
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/jm_url_set.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

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
    extern: {'source': 'jm', 'path': '$currentJmBaseUrl/chapter'},
  );
  final chapter = UnifiedPluginChapterResponse.fromMap(response).chapter;
  final docs = chapter.docs.map((doc) {
    final path = doc.fileName;
    final fileServer = doc.url;
    return Doc(
      originalName: doc.name.isEmpty ? path : doc.name,
      path: path,
      fileServer: fileServer,
      id: doc.id.isEmpty ? epId : doc.id,
    );
  }).toList();

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
  final downloadInfo = objectbox.unifiedDownloadBox
      .query(UnifiedComicDownload_.uniqueKey.equals('jm:$comicId'))
      .build()
      .findFirst()!;
  final epInfo = (downloadInfo.chapters ?? const <Map<String, dynamic>>[])
      .firstWhere((e) => e['id']?.toString() == epId);
  final epName = epInfo['name']?.toString() ?? '';
  final downloadRoot = await getDownloadPath();
  final chapterDir = Directory(
    p.join(downloadRoot, 'jm', 'original', comicId, 'comic', epId),
  );
  final files =
      await chapterDir.list().where((e) => e is File).cast<File>().toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  return NormalComicEpInfo(
    length: files.length,
    epPages: files.length.toString(),
    docs: files
        .map(
          (e) => Doc(
            originalName: p.basename(e.path),
            path: e.path,
            fileServer: getJmImagesUrl(epId, p.basename(e.path)),
            id: epId,
          ),
        )
        .toList(),
    epId: epId,
    epName: epName,
  );
}
