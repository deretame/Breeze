import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
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

  final candidates = <String>[];
  final preferComicIdFirst =
      chapterId == order.toString() && chapterId != comicId;
  if (preferComicIdFirst) {
    candidates.add(comicId);
  }
  candidates.add(chapterId);
  if (comicId != chapterId) {
    candidates.add(comicId);
  }
  candidates.add('');

  ComicReadSnapshot? snapshot;
  for (final candidate in candidates) {
    final current = await _fetchSnapshot(
      from: from,
      comicId: comicId,
      order: order,
      chapterId: candidate,
      extern: extern,
    );
    snapshot = current;
    if (current.chapter.pages.isNotEmpty) {
      break;
    }
  }

  snapshot ??= const ComicReadSnapshot(
    source: '',
    comic: ComicReadSnapshotComic(id: '', source: '', title: ''),
    chapter: ComicReadSnapshotChapter(id: '', name: '', order: 0, pages: []),
    chapters: [],
  );

  final fallbackChapterId = snapshot.chapter.id.isNotEmpty
      ? snapshot.chapter.id
      : chapterId;
  return snapshot.toNormalEpInfo(fallbackChapterId: fallbackChapterId);
}

Future<ComicReadSnapshot> _fetchSnapshot({
  required String from,
  required String comicId,
  required int order,
  required String chapterId,
  required Map<String, dynamic> extern,
}) async {
  final core = <String, dynamic>{'comicId': comicId};
  if (chapterId.trim().isNotEmpty) {
    core['chapterId'] = chapterId;
  }

  final response = await callUnifiedComicPlugin(
    from: from,
    fnPath: 'getReadSnapshot',
    core: core,
    extern: extern,
  );
  return ComicReadSnapshot.fromMap(response);
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

  for (final chapter in chapters) {
    if (chapter.id == order.toString()) {
      return chapter;
    }
  }

  return null;
}
