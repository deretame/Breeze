import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/plugin/plugin_constants.dart';

void initHistory(
  BuildContext context,
  String comicId,
  String from,
  String pluginId,
) {
  final resolvedPluginId = sanitizePluginId(
    pluginId.trim().isNotEmpty ? pluginId : sanitizePluginId(from),
  );
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
      : (resolvedPluginId == kJmPluginUuid ? '第1话' : '');

  stringSelectCubit.setDate(
    '历史：'
    '$chapterTitle / '
    '${history.pageIndex - 1} / '
    '${history.lastReadAt.toLocal().toString().substring(0, 19)}',
  );
}
