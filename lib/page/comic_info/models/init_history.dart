import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/objectbox.g.dart';

void initHistory(
  BuildContext context,
  String comicId,
  String from,
  String pluginId,
) {
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

  stringSelectCubit.setDate(
    '历史：'
    '$chapterTitle / '
    '${history.pageIndex - 1} / '
    '${history.lastReadAt.toLocal().toString().substring(0, 19)}',
  );
}
