import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart'
    show Doc;
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/download/adapters/download_chapter_matcher.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';

void _logLocalInfo(
  int epsId,
  DownloadChapter chapter,
  List<DownloadImage> images,
) {
  logger.d(
    'getPluginInfoFromLocal: epsId=$epsId, '
    'chapter.id=${chapter.id}, order=${chapter.order}, '
    'requestId=${chapter.effectiveRequestId}, '
    'storageId=${chapter.effectiveStorageId}, '
    'imageCount=${images.length}, '
    'firstPath=${images.isNotEmpty ? images.first.path : ''}',
  );
}

Future<NormalComicEpInfo> getPluginInfoFromLocal(
  String pluginId,
  String comicId,
  int epsId,
) async {
  final resolvedPluginId = pluginId.trim();
  if (resolvedPluginId.isEmpty) {
    throw StateError('pluginId 不能为空');
  }

  final download = objectbox.unifiedDownloadBox
      .query(
        UnifiedComicDownload_.uniqueKey.equals('$resolvedPluginId:$comicId'),
      )
      .build()
      .findFirst();
  if (download == null) {
    throw StateError('本地下载信息不存在: $resolvedPluginId:$comicId');
  }

  final chapters = resolveDownloadChapters(download);
  if (chapters.isEmpty) {
    throw StateError('本地下载没有章节数据: $resolvedPluginId:$comicId');
  }

  const matcher = DownloadChapterMatcher();
  final targetId = epsId.toString();

  // 优先按 order 查找；再按 id / requestId 查找；最后 fallback 到第一章。
  final chapter =
      matcher.findByOrder(chapters, epsId) ??
      matcher.find(chapters, targetId) ??
      chapters.first;

  final orderedDocs = chapter.images
      .map(
        (image) => Doc(
          originalName: image.name,
          path: image.path,
          fileServer: image.url,
          id: image.id.isNotEmpty ? image.id : chapter.id,
          storageChapterId: chapter.effectiveStorageId,
          extern: Map<String, dynamic>.from(image.extern),
        ),
      )
      .toList();

  _logLocalInfo(epsId, chapter, chapter.images);

  return NormalComicEpInfo(
    length: orderedDocs.length,
    epPages: orderedDocs.length.toString(),
    docs: orderedDocs,
    epId: chapter.id,
    epName: chapter.displayName,
  );
}
