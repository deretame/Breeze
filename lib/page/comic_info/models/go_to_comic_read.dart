import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/jm/jm_download/json/download_info_json.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/router/router.gr.dart' show ComicReadRoute;

import 'read_launch_adapter.dart';

void goToComicRead(
  BuildContext context,
  String comicId,
  ComicEntryType type,
  dynamic allInfo,
  From from,
) {
  if (from == From.bika) {
    goToBikaRead(context, comicId, type, allInfo);
  } else {
    goToJmRead(context, comicId, type, allInfo);
  }
}

void goToBikaRead(
  BuildContext context,
  String comicId,
  ComicEntryType type,
  dynamic allInfo,
) {
  final isDownload =
      type == ComicEntryType.download ||
      type == ComicEntryType.historyAndDownload;
  final epsCount = resolveReadEpsCount(
    allInfo,
    From.bika,
    isDownload: isDownload,
  );
  final resolvedComicId = resolveReadComicId(
    allInfo,
    From.bika,
    isDownload: isDownload,
  );
  final stringSelectDate = context.read<StringSelectCubit>().state;
  if (stringSelectDate.isNotEmpty) {
    var comicHistory = objectbox.bikaHistoryBox
        .query(BikaComicHistory_.comicId.equals(comicId))
        .build()
        .findFirst();
    context.pushRoute(
      ComicReadRoute(
        comicInfo: allInfo,
        comicId: comicId,
        type: type == ComicEntryType.download
            ? ComicEntryType.historyAndDownload
            : ComicEntryType.history,
        order: comicHistory!.order,
        epsNumber: epsCount,
        from: From.bika,
        stringSelectCubit: context.read<StringSelectCubit>(),
      ),
    );
  } else {
    context.pushRoute(
      ComicReadRoute(
        comicInfo: allInfo,
        comicId: resolvedComicId,
        type: type,
        order: 1,
        epsNumber: epsCount,
        from: From.bika,
        stringSelectCubit: context.read<StringSelectCubit>(),
      ),
    );
  }
}

void goToJmRead(
  BuildContext context,
  String comicId,
  ComicEntryType type,
  dynamic allInfo,
) {
  final String storeDate = context.read<StringSelectCubit>().state;

  String comicIdVal;
  int orderVal;
  int epsNumberVal;
  From fromVal = From.jm;
  ComicEntryType typeVal = type;

  if (typeVal == ComicEntryType.download) {
    var jmDownload = objectbox.jmDownloadBox
        .query(JmDownload_.comicId.equals(comicId))
        .build()
        .findFirst()!;
    comicIdVal = jmDownload.comicId;
    epsNumberVal = jmDownload.allInfo
        .let(downloadInfoJsonFromJson)
        .series
        .first
        .info
        .series
        .length;

    if (storeDate.isNotEmpty) {
      typeVal = ComicEntryType.historyAndDownload;
    }
  } else {
    comicIdVal = comicId;
    epsNumberVal = resolveReadEpsCount(
      allInfo,
      From.jm,
      isDownload: false,
    );
    typeVal = storeDate.isNotEmpty
        ? ComicEntryType.history
        : ComicEntryType.normal;
  }

  var jmHistory = objectbox.jmHistoryBox
      .query(JmHistory_.comicId.equals(comicId))
      .build()
      .findFirst();

  orderVal = storeDate.isNotEmpty ? jmHistory!.order : comicId.let(toInt);

  context.pushRoute(
    ComicReadRoute(
      comicId: comicIdVal,
      order: orderVal,
      epsNumber: epsNumberVal,
      from: fromVal,
      type: typeVal,
      comicInfo: allInfo,
      stringSelectCubit: context.read<StringSelectCubit>(),
    ),
  );
}
