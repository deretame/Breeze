import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/download/adapters/download_chapter_adapter.dart';
import 'package:zephyr/page/download/adapters/download_chapter_matcher.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/page/comic_read/type/chapter_extern.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/config/router/router.gr.dart' show ComicReadRoute;

import 'read_launch_adapter.dart';

void goToComicRead(
  BuildContext context,
  String comicId,
  ComicEntryType type,
  dynamic allInfo,
  String from,
) {
  final isDownload =
      type == ComicEntryType.download ||
      type == ComicEntryType.historyAndDownload;
  final epsCount = resolveReadEpsCount(allInfo, from, isDownload: isDownload);
  final resolvedComicId = resolveReadComicId(
    allInfo,
    from,
    isDownload: isDownload,
  );
  final hasHistory = context.read<StringSelectCubit>().state.isNotEmpty;
  final history = objectbox.unifiedHistoryBox
      .query(UnifiedComicHistory_.uniqueKey.equals('$from:$comicId'))
      .build()
      .findFirst();

  final typeVal = hasHistory
      ? (isDownload
            ? ComicEntryType.historyAndDownload
            : ComicEntryType.history)
      : (isDownload ? ComicEntryType.download : ComicEntryType.normal);
  final chapter = _resolveChapter(allInfo, from, history);
  final orderVal = chapter?.order ?? _resolveInitialOrder(allInfo, from);

  context.pushRoute(
    ComicReadRoute(
      comicId: resolvedComicId,
      order: orderVal,
      chapterId: chapter?.id ?? '',
      requestId: chapter?.effectiveRequestId ?? '',
      storageChapterId: chapter?.storageId ?? '',
      logicalKey: chapter?.id ?? '',
      chapterExtern: ChapterExtern.from(
        chapter?.extern ?? const <String, dynamic>{},
      ),
      epsNumber: epsCount,
      from: from,
      type: typeVal,
      comicInfo: allInfo,
      stringSelectCubit: context.read<StringSelectCubit>(),
    ),
  );
}

DownloadChapter? _resolveChapter(
  dynamic allInfo,
  String from,
  UnifiedComicHistory? history,
) {
  final chapterRefs = resolveUnifiedComicChapters(allInfo, from);
  if (chapterRefs.isEmpty) {
    return null;
  }

  const adapter = DownloadChapterAdapter();
  const matcher = DownloadChapterMatcher();
  final chapters = chapterRefs.map(adapter.fromChapterRef).toList();

  if (history != null) {
    // 优先按 history.chapterId 匹配（可能是 logicalKey / id / requestId）。
    final chapterId = (history.chapterId).trim();
    if (chapterId.isNotEmpty) {
      final matched = matcher.find(chapters, chapterId);
      if (matched != null) {
        return matched;
      }
    }

    // 再按 history.chapterOrder 匹配。
    if (history.chapterOrder > 0) {
      final matched = matcher.findByOrder(chapters, history.chapterOrder);
      if (matched != null) {
        return matched;
      }
    }

    // 兼容老数据：chapterOrder 曾经被当 chapterId 用。
    final matched = matcher.find(chapters, history.chapterOrder.toString());
    if (matched != null) {
      return matched;
    }
  }

  return chapters.first;
}

int _resolveInitialOrder(dynamic allInfo, String from) {
  final chapters = resolveUnifiedComicChapters(allInfo, from);
  if (chapters.isEmpty) {
    return 1;
  }
  return chapters.first.order;
}
