import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/router/router.gr.dart' show ComicReadRoute;

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
  final orderVal = hasHistory
      ? _resolveHistoryOrder(allInfo, from, history)
      : _resolveInitialOrder(allInfo, from);
  final chapterRef = resolveUnifiedComicChapterRef(
    allInfo,
    from,
    chapterId: history?.chapterId,
    order: orderVal,
  );

  context.pushRoute(
    ComicReadRoute(
      comicId: resolvedComicId,
      order: orderVal,
      chapterId: chapterRef != null
          ? resolveUnifiedComicChapterKey(chapterRef)
          : '',
      requestId: chapterRef?.requestId.trim() ?? '',
      storageChapterId: chapterRef?.storageChapterId.trim() ?? '',
      logicalKey: chapterRef?.logicalKey.trim() ?? '',
      chapterExtern: Map<String, dynamic>.from(
        chapterRef?.extern ?? const <String, dynamic>{},
      ),
      epsNumber: epsCount,
      from: from,
      type: typeVal,
      comicInfo: allInfo,
      stringSelectCubit: context.read<StringSelectCubit>(),
    ),
  );
}

int _resolveInitialOrder(dynamic allInfo, String from) {
  final chapters = resolveUnifiedComicChapters(allInfo, from);
  if (chapters.isEmpty) {
    return 1;
  }
  return chapters.first.order;
}

int _resolveHistoryOrder(
  dynamic allInfo,
  String from,
  UnifiedComicHistory? history,
) {
  if (history == null) {
    return _resolveInitialOrder(allInfo, from);
  }
  final chapters = resolveUnifiedComicChapters(allInfo, from);
  if (chapters.isEmpty) {
    return history.chapterOrder > 0 ? history.chapterOrder : 1;
  }

  final byChapterId = chapters
      .where(
        (chapter) =>
            resolveUnifiedComicChapterKey(chapter) == history.chapterId ||
            chapter.requestId.trim() == history.chapterId ||
            chapter.logicalKey.trim() == history.chapterId ||
            chapter.id == history.chapterId,
      )
      .toList();
  if (byChapterId.isNotEmpty) {
    return byChapterId.first.order;
  }

  final byOrder = chapters
      .where((chapter) => chapter.order == history.chapterOrder)
      .toList();
  if (byOrder.isNotEmpty) {
    return byOrder.first.order;
  }

  final byLegacyOrderAsChapterId = chapters
      .where(
        (chapter) =>
            resolveUnifiedComicChapterKey(chapter) ==
            history.chapterOrder.toString(),
      )
      .toList();
  if (byLegacyOrderAsChapterId.isNotEmpty) {
    return byLegacyOrderAsChapterId.first.order;
  }

  return chapters.first.order;
}
