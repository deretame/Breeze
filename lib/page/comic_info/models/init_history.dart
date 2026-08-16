import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cs/cs.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';

Future<void> initHistory(
  BuildContext context,
  String comicId,
  String from,
  String pluginId, {
  List<Ep>? chapters,
}) async {
  final resolvedPluginId = (pluginId.trim().isNotEmpty ? pluginId : from.trim())
      .trim();
  if (CsRuntimeContext.I.isCsMode) {
    final client = CsRuntimeContext.I.client;
    if (client == null) throw StateError('CS 会话未登录');
    final records = await client.listLibrary('history', includeDeleted: true);
    final key = '$resolvedPluginId:$comicId';
    final record = records.where((item) => item.uniqueKey == key).firstOrNull;
    if (record == null || record.isDeleted) return;
    final payload = record.payload;
    if (!context.mounted) return;
    _setHistoryText(
      context,
      chapterId: payload['chapterId']?.toString() ?? '',
      chapterTitle: payload['chapterTitle']?.toString() ?? '',
      pageIndex: (payload['pageIndex'] as num?)?.toInt() ?? 0,
      lastReadAt: _remoteDateTime(record.updatedAt),
      chapters: chapters,
    );
    return;
  }

  final history = objectbox.unifiedHistoryBox
      .query(
        UnifiedComicHistory_.uniqueKey.equals('$resolvedPluginId:$comicId'),
      )
      .build()
      .findFirst();
  final fallbackHistory = history == null && from != resolvedPluginId
      ? objectbox.unifiedHistoryBox
            .query(UnifiedComicHistory_.uniqueKey.equals('$from:$comicId'))
            .build()
            .findFirst()
      : null;
  final resolvedHistory = history ?? fallbackHistory;
  if (resolvedHistory?.deleted == true || resolvedHistory == null) return;
  _setHistoryText(
    context,
    chapterId: resolvedHistory.chapterId,
    chapterTitle: resolvedHistory.chapterTitle,
    pageIndex: resolvedHistory.pageIndex,
    lastReadAt: resolvedHistory.lastReadAt,
    chapters: chapters,
  );
}

DateTime _remoteDateTime(String value) {
  final millis = int.tryParse(value);
  return millis == null
      ? DateTime.now()
      : DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
}

void _setHistoryText(
  BuildContext context, {
  required String chapterId,
  required String chapterTitle,
  required int pageIndex,
  required DateTime lastReadAt,
  required List<Ep>? chapters,
}) {
  final stringSelectCubit = context.read<StringSelectCubit>();
  final resolvedChapterTitle = chapterTitle.isNotEmpty ? chapterTitle : '';

  int? order;
  if (chapters != null && chapterId.isNotEmpty) {
    final matched = chapters.cast<Ep?>().firstWhere(
      (ep) => ep?.id == chapterId,
      orElse: () => null,
    );
    order = matched?.order;
  }

  final prefix = (order != null && order > 0) ? '$order-' : '';

  stringSelectCubit.setDate(
    '$prefix${resolvedChapterTitle.isNotEmpty ? resolvedChapterTitle : ''} / '
    '${pageIndex - 1} / '
    '${lastReadAt.toLocal().toString().substring(0, 19)}',
  );
}
