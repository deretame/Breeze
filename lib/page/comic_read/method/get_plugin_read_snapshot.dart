import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/plugin/plugin_constants.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/comic_read/model/comic_read_snapshot.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';

Future<NormalComicEpInfo> getPluginReadSnapshot(
  String comicId,
  int order,
  String from,
  dynamic comicInfo,
) async {
  final chapterRef = _resolveChapterRef(comicInfo, from, order);
  final chapterId = chapterRef?.id.isNotEmpty == true
      ? chapterRef!.id
      : order.toString();

  final extern = <String, dynamic>{'order': order};
  final core = <String, dynamic>{'comicId': comicId, 'chapterId': chapterId};

  final response = await callUnifiedComicPlugin(
    from: from,
    fnPath: 'getReadSnapshot',
    core: core,
    extern: extern,
  );
  final snapshot = ComicReadSnapshot.fromMap(response);
  return snapshot.toNormalEpInfo(fallbackChapterId: chapterId);
}

UnifiedComicChapterRef? _resolveChapterRef(
  dynamic comicInfo,
  String from,
  int order,
) {
  final chapters = resolveUnifiedComicChapters(comicInfo, from);
  if (chapters.isEmpty) {
    return null;
  }
  for (final chapter in chapters) {
    if (chapter.order == order) {
      return chapter;
    }
  }

  if (from == kJmPluginUuid) {
    for (final chapter in chapters) {
      if (chapter.id == order.toString()) {
        return chapter;
      }
    }
  }

  return null;
}
