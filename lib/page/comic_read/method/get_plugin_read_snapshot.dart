import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/comic_read/model/comic_read_snapshot.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';

Future<NormalComicEpInfo> getPluginReadSnapshot(
  String comicId,
  int order,
  String from,
  dynamic comicInfo,
  String? selectedChapterId,
  Map<String, dynamic> chapterExtern,
) async {
  final chapterRef = chapterExtern.isNotEmpty
      ? null
      : resolveUnifiedComicChapterRef(
          comicInfo,
          from,
          chapterId: selectedChapterId,
          order: order,
        );
  final resolvedChapterId = _resolveReadSnapshotChapterId(
    chapterRef,
    selectedChapterId,
    order,
  );

  final extern = <String, dynamic>{
    ...chapterExtern,
    ...?chapterRef?.extern,
    if (resolvedChapterId.trim().isNotEmpty) 'chapterId': resolvedChapterId,
    'order': order,
  };

  final candidates = <String>[];
  final preferComicIdFirst =
      resolvedChapterId == order.toString() && resolvedChapterId != comicId;
  if (preferComicIdFirst) {
    candidates.add(comicId);
  }
  candidates.add(resolvedChapterId);
  if (comicId != resolvedChapterId) {
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
      : resolvedChapterId;
  return snapshot.toNormalEpInfo(fallbackChapterId: fallbackChapterId);
}

String _resolveReadSnapshotChapterId(
  UnifiedComicChapterRef? chapterRef,
  String? selectedChapterId,
  int order,
) {
  final explicitRequestId = chapterRef?.requestId.trim() ?? '';
  if (explicitRequestId.isNotEmpty) {
    return explicitRequestId;
  }

  return order.toString();
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
