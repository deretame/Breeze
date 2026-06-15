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
  String requestId;
  String storageChapterId;
  String logicalKey;
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
    required this.requestId,
    required this.storageChapterId,
    required this.logicalKey,
    required this.chapterExtern,
    required this.comicInfo,
    required this.comicId,
    required this.tempType,
    required this.epsNumber,
  });

  void jumpToChapter(BuildContext context, bool isPrev) {
    final router = AutoRouter.of(context);
    final index = chapters.indexWhere(
      (chapter) => _matchesCurrentChapter(chapter),
    );
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
    chapterId = resolveUnifiedComicChapterKey(target);
    requestId = target.requestId.trim();
    storageChapterId = target.storageChapterId.trim();
    logicalKey = target.logicalKey.trim();
    chapterExtern = Map<String, dynamic>.from(target.extern);

    router.replace(
      ComicReadRoute(
        key: Key(Uuid().v4()),
        comicInfo: comicInfo,
        comicId: comicId,
        type: tempType,
        order: order,
        chapterId: chapterId,
        requestId: requestId,
        storageChapterId: storageChapterId,
        logicalKey: logicalKey,
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
    String requestId,
    String storageChapterId,
    String logicalKey,
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
    final currentId = resolvedRef != null
        ? resolveUnifiedComicChapterKey(resolvedRef)
        : '';
    if (chapters.isEmpty) {
      havePrev = false;
      haveNext = false;
    } else {
      final chapterIndex = chapters.indexWhere(
        (chapter) => resolveUnifiedComicChapterKey(chapter) == currentId,
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
      requestId: resolvedRef?.requestId.trim() ?? requestId,
      storageChapterId:
          resolvedRef?.storageChapterId.trim() ?? storageChapterId,
      logicalKey: resolvedRef?.logicalKey.trim() ?? logicalKey,
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

  bool _matchesCurrentChapter(UnifiedComicChapterRef chapter) {
    if (logicalKey.isNotEmpty && chapter.logicalKey.trim() == logicalKey) {
      return true;
    }

    if (requestId.isNotEmpty && chapter.requestId.trim() == requestId) {
      return true;
    }

    if (chapterId.isNotEmpty) {
      return resolveUnifiedComicChapterKey(chapter) == chapterId ||
          chapter.id == chapterId;
    }

    return false;
  }

  /// 用于章节选择对话框定位初始滚动位置
  int currentChapterIndexIn(List<UnifiedComicChapterRef> refs) =>
      refs.indexWhere(_matchesCurrentChapter);
}
