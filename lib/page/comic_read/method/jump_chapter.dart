import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/type/enum.dart';

class JumpChapter {
  bool haveNext;
  bool havePrev;
  int currentChapterIndex;
  String from;
  List<UnifiedComicChapterRef> chapters;
  int order;
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
    required this.comicInfo,
    required this.comicId,
    required this.tempType,
    required this.epsNumber,
  });

  void jumpToChapter(BuildContext context, bool isPrev) {
    final router = AutoRouter.of(context);
    final index = chapters.indexWhere((chapter) => chapter.order == order);
    if (index < 0) {
      return;
    }
    if (isPrev) {
      if (index == 0) {
        return;
      }
      order = chapters[index - 1].order;
    } else {
      if (index >= chapters.length - 1) {
        return;
      }
      order = chapters[index + 1].order;
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
    String from,
  ) {
    final chapters = resolveUnifiedComicChapters(comicInfo, from);

    var tempType = type;
    if (tempType == ComicEntryType.historyAndDownload) {
      tempType = ComicEntryType.download;
    }
    if (tempType == ComicEntryType.history) {
      tempType = ComicEntryType.normal;
    }

    bool havePrev = true;
    bool haveNext = true;
    if (chapters.isEmpty) {
      havePrev = false;
      haveNext = false;
    } else {
      final chapterIndex = chapters.indexWhere(
        (chapter) => chapter.order == order,
      );
      if (chapterIndex <= 0) {
        havePrev = false;
      }
      if (chapterIndex < 0 || chapterIndex >= chapters.length - 1) {
        haveNext = false;
      }
    }

    return JumpChapter._(
      haveNext: haveNext,
      havePrev: havePrev,
      currentChapterIndex: order,
      from: from,
      chapters: chapters,
      order: order,
      comicInfo: comicInfo,
      comicId: comicId,
      tempType: tempType,
      epsNumber: epsNumber,
    );
  }
}
