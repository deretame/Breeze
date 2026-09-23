import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/download/adapters/download_chapter_adapter.dart';
import 'package:zephyr/page/download/adapters/download_chapter_matcher.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/service/download/download_task_repository.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/page/comic_read/type/chapter_extern.dart';
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
  ChapterExtern chapterExtern;
  dynamic comicInfo;
  String comicId;
  ComicEntryType resolvedEntryType;
  int totalChapterCount;

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
    required this.resolvedEntryType,
    required this.totalChapterCount,
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
    const adapter = DownloadChapterAdapter();
    final chapter = adapter.fromChapterRef(target);
    // 在线阅读中切章时统一查库：目标章已下载则切到本地，不再看当前来源。
    dynamic useComicInfo = comicInfo;
    var useType = resolvedEntryType;
    var useEpsNumber = totalChapterCount;
    DownloadChapter useChapter = chapter;
    if (resolvedEntryType == ComicEntryType.normal ||
        resolvedEntryType == ComicEntryType.history) {
      const repository = DownloadTaskRepository();
      final local =
          repository.findDownloadedChapter(
            from: from,
            comicId: comicId,
            chapterKey: chapter.id,
          ) ??
          repository.findDownloadedChapter(
            from: from,
            comicId: comicId,
            chapterKey: chapter.effectiveRequestId,
          );
      final record = local == null
          ? null
          : repository.findDownloadRecord(from, comicId);
      if (local != null && record != null) {
        useComicInfo = record;
        useType = resolvedEntryType == ComicEntryType.history
            ? ComicEntryType.historyAndDownload
            : ComicEntryType.download;
        useEpsNumber = resolveStoredDownloadChapters(record).length;
        useChapter = local;
      }
    }
    order = useChapter.order;
    chapterId = useChapter.id;
    requestId = useChapter.effectiveRequestId;
    storageChapterId = useChapter.storageId ?? '';
    logicalKey = useChapter.id;
    chapterExtern = ChapterExtern.from(useChapter.extern);

    router.replace(
      ComicReadRoute(
        key: Key(Uuid().v4()),
        comicInfo: useComicInfo,
        comicId: comicId,
        type: useType,
        order: order,
        chapterId: chapterId,
        requestId: requestId,
        storageChapterId: storageChapterId,
        logicalKey: logicalKey,
        chapterExtern: chapterExtern,
        epsNumber: useEpsNumber,
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
    ChapterExtern chapterExtern,
    int totalChapterCount,
    String comicId,
    String from,
  ) {
    final chapters = resolveUnifiedComicChapters(comicInfo, from);

    var resolvedEntryType = type;
    if (resolvedEntryType == ComicEntryType.historyAndDownload) {
      resolvedEntryType = ComicEntryType.download;
    }
    if (resolvedEntryType == ComicEntryType.history) {
      resolvedEntryType = ComicEntryType.normal;
    }

    const adapter = DownloadChapterAdapter();
    const matcher = DownloadChapterMatcher();
    final downloadChapters = chapters.map(adapter.fromChapterRef).toList();

    // 定位当前章节：优先用 chapterId / logicalKey / requestId，再按 order。
    final target = _firstNonEmpty([logicalKey, chapterId, requestId]);
    DownloadChapter? current;
    if (target != null && target.isNotEmpty) {
      current = matcher.find(downloadChapters, target);
    }
    current ??= matcher.findByOrder(downloadChapters, order);

    bool havePrev = true;
    bool haveNext = true;
    if (chapters.isEmpty || current == null) {
      havePrev = false;
      haveNext = false;
    } else {
      final chapterIndex = downloadChapters.indexWhere(
        (chapter) => chapter.id == current!.id,
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
      currentChapterIndex: current?.order ?? order,
      from: from,
      chapters: chapters,
      order: current?.order ?? order,
      chapterId: current?.id ?? chapterId,
      requestId: current?.effectiveRequestId ?? requestId,
      storageChapterId: current?.storageId ?? storageChapterId,
      logicalKey: current?.id ?? logicalKey,
      chapterExtern: ChapterExtern.from(
        chapterExtern.isNotEmpty
            ? chapterExtern
            : (current?.extern ?? const <String, dynamic>{}),
      ),
      comicInfo: comicInfo,
      comicId: comicId,
      resolvedEntryType: resolvedEntryType,
      totalChapterCount: totalChapterCount,
    );
  }

  bool _matchesCurrentChapter(UnifiedComicChapterRef chapter) {
    const adapter = DownloadChapterAdapter();
    const matcher = DownloadChapterMatcher();
    final candidate = adapter.fromChapterRef(chapter);
    // 当前章节标识可能来自 logicalKey / chapterId / requestId，
    // 取最可靠的一个作为匹配 target。
    final target = _firstNonEmpty([logicalKey, chapterId, requestId]);
    if (target == null || target.isEmpty) {
      return false;
    }
    return matcher.matches(candidate, target);
  }

  static String? _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// 用于章节选择对话框定位初始滚动位置
  int currentChapterIndexIn(List<UnifiedComicChapterRef> refs) =>
      refs.indexWhere(_matchesCurrentChapter);
}
