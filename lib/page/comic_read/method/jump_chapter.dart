import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/models/all_info.dart';
import 'package:zephyr/page/jm/jm_comic_info/json/jm_comic_info_json.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/router/router.gr.dart';

class JumpChapter {
  bool haveNext;
  bool havePrev;
  int currentChapterIndex;
  From from;
  AllInfo? allInfo;
  int order;
  int? sort;
  List<Series> seriesList;
  dynamic comicInfo;
  String comicId;
  ComicEntryType tempType;
  int epsNumber;

  JumpChapter._({
    required this.haveNext,
    required this.havePrev,
    required this.currentChapterIndex,
    required this.from,
    required this.allInfo,
    required this.order,
    required this.sort,
    required this.comicInfo,
    required this.comicId,
    required this.tempType,
    required this.seriesList,
    required this.epsNumber,
  });

  void jumpToChapter(BuildContext context, bool isPrev) {
    final router = AutoRouter.of(context);
    if (from == From.bika) {
      final index = allInfo!.eps.indexOf(
        allInfo!.eps.firstWhere((ep) => ep.order == order),
      );
      logger.d(index);
      if (isPrev) {
        order = allInfo!.eps[index - 1].order;
      } else {
        order = allInfo!.eps[index + 1].order;
      }
    } else {
      if (sort != null) {
        if (haveNext && !isPrev) {
          order = findNeighborOrder(false, seriesList, order);
        } else if (havePrev && isPrev) {
          order = findNeighborOrder(true, seriesList, order);
        }
      }
    }

    router.popAndPush(
      ComicReadRoute(
        comicInfo: comicInfo,
        comicId: comicId,
        type: tempType,
        order: order,
        epsNumber: epsNumber,
        from: from,
        stringSelectCubit: context.read<StringSelectCubit>(),
      ),
    );
  }

  factory JumpChapter.create(
    ComicEntryType type,
    bool isVisible,
    dynamic comicInfo,
    int order,
    int epsNumber,
    String comicId,
    From from,
  ) {
    final isDownload =
        type == ComicEntryType.download ||
        type == ComicEntryType.historyAndDownload;

    AllInfo? allInfo;
    if (from == From.bika) {
      allInfo = comicInfo as AllInfo;
    }

    var tempType = type;
    comicId = comicId;
    if (tempType == ComicEntryType.historyAndDownload) {
      tempType = ComicEntryType.download;
    }
    if (tempType == ComicEntryType.history) {
      tempType = ComicEntryType.normal;
    }

    BikaComicDownload? bikaComicDownload;
    bool havePrev = true;
    bool haveNext = true;
    if (from == From.bika) {
      if (isDownload) {
        bikaComicDownload = objectbox.bikaDownloadBox
            .query(BikaComicDownload_.comicId.equals(comicId))
            .build()
            .findFirst();

        if (bikaComicDownload?.epsTitle.length == 1) {
          havePrev = false;
          haveNext = false;
        } else {
          if (allInfo!.eps.first.order == order) {
            havePrev = false;
          }
          if (allInfo.eps.last.order == order) {
            haveNext = false;
          }
        }
      } else {
        if (order == 1) {
          havePrev = false;
        }
        if (order == epsNumber) {
          haveNext = false;
        }
      }
    }

    List<Series> seriesList = [];
    int? sort;
    if (from == From.jm) {
      seriesList = (comicInfo as JmComicInfoJson).series;
      if (isDownload) {
        final epsIds = objectbox.jmDownloadBox
            .query(JmDownload_.comicId.equals(comicId))
            .build()
            .findFirst()!
            .epsIds;
        seriesList = seriesList.toList()
          ..removeWhere((series) => !epsIds.contains(series.id));
      }
      if (seriesList.isEmpty) {
        havePrev = false;
        haveNext = false;
      } else {
        sort = seriesList
            .firstWhere((series) => series.id == order.toString())
            .sort
            .let(toInt);
        if (sort == seriesList.first.sort.let(toInt)) {
          havePrev = false;
        }
        if (sort == seriesList.last.sort.let(toInt)) {
          haveNext = false;
        }
      }
    }

    return JumpChapter._(
      haveNext: haveNext,
      havePrev: havePrev,
      currentChapterIndex: order,
      from: from,
      allInfo: allInfo,
      order: order,
      sort: sort,
      comicInfo: comicInfo,
      comicId: comicId,
      tempType: tempType,
      seriesList: seriesList,
      epsNumber: epsNumber,
    );
  }

  int findNeighborOrder(bool isPrev, List<Series> seriesList, int currentSort) {
    int neighborOrder = 0;
    int currentIndex = 0;

    // 首先找到当前项的索引
    for (int i = 0; i < seriesList.length; i++) {
      if (seriesList[i].id.let(toInt) == currentSort) {
        currentIndex = i;
        break;
      }
    }

    if (isPrev) {
      // 查找上一个项
      if (currentIndex > 0) {
        neighborOrder = seriesList[currentIndex - 1].id.let(toInt);
      }
    } else {
      // 查找下一个项
      if (currentIndex < seriesList.length - 1) {
        neighborOrder = seriesList[currentIndex + 1].id.let(toInt);
      }
    }

    return neighborOrder;
  }
}
