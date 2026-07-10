import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';

void initHistory(
  BuildContext context,
  String comicId,
  String from,
  String pluginId, {
  List<Ep>? chapters,
}) {
  final resolvedPluginId = (pluginId.trim().isNotEmpty ? pluginId : from.trim())
      .trim();
  final history =
      objectbox.unifiedHistoryBox
          .query(
            UnifiedComicHistory_.uniqueKey.equals('$resolvedPluginId:$comicId'),
          )
          .build()
          .findFirst() ??
      objectbox.unifiedHistoryBox
          .query(UnifiedComicHistory_.uniqueKey.equals('$from:$comicId'))
          .build()
          .findFirst();

  if (history?.deleted == true || history == null) {
    return;
  }

  final stringSelectCubit = context.read<StringSelectCubit>();
  final chapterTitle = history.chapterTitle.isNotEmpty
      ? history.chapterTitle
      : '';

  int? order;
  if (chapters != null && history.chapterId.isNotEmpty) {
    final matched = chapters.cast<Ep?>().firstWhere(
      (ep) => ep?.id == history.chapterId,
      orElse: () => null,
    );
    order = matched?.order;
  }

  final prefix = (order != null && order > 0) ? '$order-' : '';

  stringSelectCubit.setDate(
    '$prefix${chapterTitle.isNotEmpty ? chapterTitle : ''} / '
    '${history.pageIndex - 1} / '
    '${history.lastReadAt.toLocal().toString().substring(0, 19)}',
  );
}
