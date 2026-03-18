import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart'
    show Series;
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/router/router.gr.dart';

class JumpChapter {
  bool haveNext;
  bool havePrev;
  int currentChapterIndex;
  From from;
  List<UnifiedComicChapterRef> chapters;
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
    required this.chapters,
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
      final index = chapters.indexWhere((chapter) => chapter.routeOrder == order);
      logger.d(index);
      if (isPrev) {
        order = chapters[index - 1].routeOrder;
      } else {
        order = chapters[index + 1].routeOrder;
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

    router.replace(
      ComicReadRoute(
        key: Key(Uuid().v4()),
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

    final chapters = resolveUnifiedComicChapters(comicInfo, from);

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
          if (chapters.isNotEmpty && chapters.first.routeOrder == order) {
            havePrev = false;
          }
          if (chapters.isNotEmpty && chapters.last.routeOrder == order) {
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
    int sort = 0;
    if (from == From.jm) {
      seriesList = chapters
          .map(
            (chapter) => Series(
              id: chapter.id,
              name: chapter.name,
              sort: chapter.sort.toString(),
            ),
          )
          .toList();
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
        try {
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
        } catch (e) {
          logger.d(e);
        }
      }
    }

    return JumpChapter._(
      haveNext: haveNext,
      havePrev: havePrev,
      currentChapterIndex: order,
      from: from,
      chapters: chapters,
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
