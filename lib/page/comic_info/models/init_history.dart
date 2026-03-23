import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/type/enum.dart';

void initHistory(BuildContext context, String comicId, From from) {
  if (from == From.bika) {
    _initBikaHistory(context, comicId);
  } else {
    _initJmHistory(context, comicId);
  }
}

void _initBikaHistory(BuildContext context, String comicId) {
  final comicHistory = objectbox.unifiedHistoryBox
      .query(UnifiedComicHistory_.uniqueKey.equals('bika:$comicId'))
      .build()
      .findFirst();

  if (comicHistory?.deleted == true || comicHistory == null) {
    return;
  }

  final stringSelectCubit = context.read<StringSelectCubit>();

  stringSelectCubit.setDate(
    '历史：'
    '${comicHistory.chapterTitle} / '
    '${comicHistory.pageIndex - 1} / '
    '${comicHistory.lastReadAt.toLocal().toString().substring(0, 19)}',
  );
}

void _initJmHistory(BuildContext context, String comicId) {
  final jmHistory = objectbox.unifiedHistoryBox
      .query(UnifiedComicHistory_.uniqueKey.equals('jm:$comicId'))
      .build()
      .findFirst();

  if (jmHistory?.deleted == true || jmHistory == null) {
    return;
  }

  final stringSelectCubit = context.read<StringSelectCubit>();

  stringSelectCubit.setDate(
    '历史：'
    '${jmHistory.chapterTitle.isNotEmpty ? jmHistory.chapterTitle : "第1话"} / '
    '${jmHistory.pageIndex - 1} / '
    '${jmHistory.lastReadAt.toLocal().toString().substring(0, 19)}',
  );
}
