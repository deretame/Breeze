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
  String chapterId;
  Map<String, dynamic> chapterExtern;
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
    required this.chapterId,
    required this.chapterExtern,
    required this.comicInfo,
    required this.comicId,
    required this.tempType,
    required this.epsNumber,
  });

  void jumpToChapter(BuildContext context, bool isPrev) {
    final router = AutoRouter.of(context);
    final index = chapters.indexWhere((chapter) => chapter.id == chapterId);
    if (index < 0) {
      return;
    }
    UnifiedComicChapterRef target;
    if (isPrev) {
      if (index == 0) {
        return;
      }
      target = chapters[index - 1];
    } else {
      if (index >= chapters.length - 1) {
        return;
      }
      target = chapters[index + 1];
    }
    order = target.order;
    chapterId = target.id;
    chapterExtern = Map<String, dynamic>.from(target.extern);

    router.replace(
      ComicReadRoute(
        key: Key(Uuid().v4()),
        comicInfo: comicInfo,
        comicId: comicId,
        type: tempType,
        order: order,
        chapterId: chapterId,
        chapterExtern: chapterExtern,
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
    String chapterId,
    Map<String, dynamic> chapterExtern,
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
    final resolvedRef = resolveUnifiedComicChapterRef(
      comicInfo,
      from,
      chapterId: chapterId,
      order: order,
    );
    final currentId = resolvedRef?.id ?? '';
    if (chapters.isEmpty) {
      havePrev = false;
      haveNext = false;
    } else {
      final chapterIndex = chapters.indexWhere(
        (chapter) => chapter.id == currentId,
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
      chapterId: currentId,
      chapterExtern: Map<String, dynamic>.from(
        chapterExtern.isNotEmpty
            ? chapterExtern
            : (resolvedRef?.extern ?? const <String, dynamic>{}),
      ),
      comicInfo: comicInfo,
      comicId: comicId,
      tempType: tempType,
      epsNumber: epsNumber,
    );
  }
}
