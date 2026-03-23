import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/unified_comic_dto.dart';
import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/get_path.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
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
          originalName: doc.name,
          path: doc.fileName,
          fileServer: doc.url,
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
  final download = objectbox.unifiedDownloadBox
      .query(UnifiedComicDownload_.uniqueKey.equals('bika:$comicId'))
      .build()
      .findFirst()!;
  final epInfo = (download.chapters ?? const <Map<String, dynamic>>[])
      .firstWhere((e) => (e['order'] as num?)?.toInt() == epsId);
  final chapterId = epInfo['id']?.toString() ?? '';
  final chapterName = epInfo['name']?.toString() ?? '';
  final downloadRoot = await getDownloadPath();
  final chapterDir = Directory(
    p.join(downloadRoot, 'bika', 'original', comicId, 'comic', chapterId),
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
            fileServer: '',
            id: chapterId,
          ),
        )
        .toList(),
    epId: chapterId,
    epName: chapterName,
  );
}
