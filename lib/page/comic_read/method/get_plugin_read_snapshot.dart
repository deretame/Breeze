import 'package:zephyr/network/http/plugin/unified_comic_plugin.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/download/adapters/download_chapter_adapter.dart';
import 'package:zephyr/page/download/adapters/download_chapter_matcher.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/page/comic_read/model/comic_read_snapshot.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/comic_read/type/chapter_extern.dart';

Future<NormalComicEpInfo> getPluginReadSnapshot(
  String comicId,
  int order,
  String from,
  dynamic comicInfo,
  String? selectedChapterId,
  String requestId,
  String logicalKey,
  ChapterExtern chapterExtern,
) async {
  const adapter = DownloadChapterAdapter();
  const matcher = DownloadChapterMatcher();
  DownloadChapter? chapter;
  if (requestId.trim().isEmpty && logicalKey.trim().isEmpty) {
    final chapterRefs = resolveUnifiedComicChapters(comicInfo, from);
    final chapters = chapterRefs.map(adapter.fromChapterRef).toList();
    final normalizedChapterId = (selectedChapterId ?? '').trim();
    if (normalizedChapterId.isNotEmpty) {
      chapter = matcher.find(chapters, normalizedChapterId);
    }
    chapter ??= matcher.findByOrder(chapters, order);
    chapter ??= (chapters.isNotEmpty ? chapters.first : null);
  }

  final resolvedChapterId = _resolveReadSnapshotChapterId(
    chapter,
    requestId,
    order,
  );

  final extern = <String, dynamic>{
    ...chapterExtern,
    ...?chapter?.extern,
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
  final logicalChapterId = _resolveLogicalChapterId(
    chapter,
    selectedChapterId,
    logicalKey,
    order,
    fallbackChapterId,
  );
  return snapshot.toNormalEpInfo(logicalChapterId: logicalChapterId);
}

String _resolveReadSnapshotChapterId(
  DownloadChapter? chapter,
  String requestId,
  int order,
) {
  final explicitRequestId = requestId.trim();
  if (explicitRequestId.isNotEmpty) {
    return explicitRequestId;
  }

  final requestIdFromChapter = chapter?.effectiveRequestId ?? '';
  if (requestIdFromChapter.isNotEmpty) {
    return requestIdFromChapter;
  }

  return order.toString();
}

String _resolveLogicalChapterId(
  DownloadChapter? chapter,
  String? selectedChapterId,
  String logicalKey,
  int order,
  String fallbackChapterId,
) {
  final explicitLogicalKey = logicalKey.trim();
  if (explicitLogicalKey.isNotEmpty) {
    return explicitLogicalKey;
  }

  final logicalKeyFromChapter = chapter?.id ?? '';
  if (logicalKeyFromChapter.isNotEmpty) {
    return logicalKeyFromChapter;
  }

  final explicitSelectedChapterId = (selectedChapterId ?? '').trim();
  if (explicitSelectedChapterId.isNotEmpty) {
    return explicitSelectedChapterId;
  }

  if (fallbackChapterId.trim().isNotEmpty) {
    return fallbackChapterId.trim();
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
