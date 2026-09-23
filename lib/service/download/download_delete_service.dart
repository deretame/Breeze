import 'dart:convert';
import 'dart:io';

import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/bookshelf/service/comic_link_service.dart';
import 'package:zephyr/page/bookshelf/service/download_folder_service.dart';
import 'package:zephyr/service/download/download_queue_manager.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/page/download/adapters/download_chapter_adapter.dart';
import 'package:zephyr/page/download/adapters/download_chapter_matcher.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/service/download/download_asset_store.dart';
import 'package:zephyr/service/download/download_task_repository.dart';
import 'package:zephyr/service/download/models/download_task_json.dart';
import 'package:zephyr/network/http/picture/picture.dart'
    show deleteComicDownloadDirectory;
import 'package:zephyr/type/enum.dart';

/// 单章删除的结果。
enum DeleteDownloadedChapterResult {
  /// 删除了一个章节，漫画还有剩余章节。
  chapterDeleted,

  /// 删除的是最后一个章节，整本下载记录已一并删除。
  wholeComicDeleted,

  /// 本地没有该章节（或没有本漫画），什么都没做。
  notFound,
}

/// 删除本地已下载的单个章节。
///
/// 只删该章的图片文件（共享目录下其他章节的不动），并从 `chapters` 和
/// `detailJson.eps` 里移除该条目。删的是最后一个章节时走整本删除。
/// 章节还有未完成任务时抛 [StateError]，调用方应先取消任务。
Future<DeleteDownloadedChapterResult> deleteDownloadedChapter({
  required String from,
  required String comicId,
  required String chapterKey,
}) async {
  const repository = DownloadTaskRepository();
  final pending = repository.findByChapterKey(
    from: from,
    comicId: comicId,
    chapterKey: chapterKey,
    incompleteOnly: true,
  );
  if (pending != null) {
    throw StateError('章节还有未完成的下载任务，请先取消');
  }

  final record = repository.findDownloadRecord(from, comicId);
  if (record == null) return DeleteDownloadedChapterResult.notFound;

  final storedChapters = resolveStoredDownloadChapters(record).toList();
  if (storedChapters.isEmpty) return DeleteDownloadedChapterResult.notFound;

  const adapter = DownloadChapterAdapter();
  const matcher = DownloadChapterMatcher();
  final index = storedChapters.indexWhere(
    (stored) =>
        matcher.matches(adapter.fromStoredMap(stored.toMap()), chapterKey),
  );
  if (index < 0) return DeleteDownloadedChapterResult.notFound;

  if (storedChapters.length == 1) {
    await deleteWholeComicDownload(from: from, comicId: comicId);
    return DeleteDownloadedChapterResult.wholeComicDeleted;
  }

  final removed = storedChapters.removeAt(index);
  final candidate = adapter.fromStoredMap(removed.toMap());
  for (final image in removed.images) {
    final path = image.path.trim();
    if (path.isEmpty) continue;
    try {
      final store = DownloadAssetStore(
        from: from,
        path: path,
        cartoonId: comicId,
        chapterId: '',
        storageChapterId: candidate.effectiveStorageId,
        pictureType: PictureType.page,
      );
      final found = await store.findCanonicalDownload();
      if (found == null) continue;
      await File(found.path).delete();
    } catch (_) {
      // 单个文件删除失败不影响元数据提交。
    }
  }

  final detail = NormalComicAllInfo.fromJson(
    jsonDecode(record.detailJson) as Map<String, dynamic>,
  );
  final updatedDetail = detail.copyWith(
    eps: buildDownloadEps(storedChapters),
    extern: {
      ...detail.extern,
      'downloadChapters': storedChapters.map((e) => e.toMap()).toList(),
    },
  );
  record
    ..chapters = jsonEncode(storedChapters.map((e) => e.toMap()).toList())
    ..detailJson = jsonEncode(updatedDetail.toJson())
    ..updatedAt = DateTime.now().toUtc();
  objectbox.unifiedDownloadBox.put(record);

  logger.i('已删除下载章节: $from:$comicId chapter=$chapterKey');
  return DeleteDownloadedChapterResult.chapterDeleted;
}

/// 删除整本漫画的下载记录、书架链接与文件，可复用的公共逻辑。
///
/// 与书架“删除下载”、漫画入口“删除下载”行为一致。
Future<void> deleteWholeComicDownload({
  required String from,
  required String comicId,
}) async {
  final uniqueKey = buildDownloadTaskKey(from, comicId);
  // 先取消同漫画的所有排队任务，否则 worker 跑起来会重建下载记录。
  final pending = objectbox.downloadTaskBox
      .query(
        DownloadTask_.isCompleted
            .equals(false)
            .and(DownloadTask_.comicId.equals(comicId.trim())),
      )
      .build()
      .find();
  for (final task in pending) {
    String? chapterKey;
    try {
      final payload = task.taskInfo;
      if (payload != null && payload.from.trim() == from.trim()) {
        chapterKey = payload.chapterKey;
      }
    } catch (_) {
      chapterKey = null;
    }
    if (chapterKey == null || chapterKey.isEmpty) {
      objectbox.downloadTaskBox.remove(task.id);
      continue;
    }
    await DownloadQueueManager.instance.cancelChapterTask(
      from: from,
      comicId: comicId,
      chapterKey: chapterKey,
    );
  }
  final record = const DownloadTaskRepository().findDownloadRecord(
    from,
    comicId,
  );
  if (record != null) {
    objectbox.unifiedDownloadBox.remove(record.id);
  }
  DownloadFolderService.removeMemberFromAllFolders(uniqueKey);
  ComicLinkService.removeComicFromAll(uniqueKey, ComicFolderType.download);
  await deleteComicDownloadDirectory(from, comicId);
  logger.i('已删除整本下载: $uniqueKey');
}
