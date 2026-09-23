import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/download/adapters/download_chapter_adapter.dart';
import 'package:zephyr/page/download/adapters/download_chapter_matcher.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/service/download/download_delete_service.dart';
import 'package:zephyr/service/download/download_queue_manager.dart';
import 'package:zephyr/service/download/download_task_repository.dart';
import 'package:zephyr/service/download/models/download_task_json.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/toast.dart';

/// 章节下载状态（详情页章节行右侧按钮用）。
enum ChapterDownloadStatus {
  notDownloaded,
  queued,
  downloading,
  failed,
  downloaded,
}

class _ChapterTaskSnap {
  const _ChapterTaskSnap({
    required this.isDownloading,
    required this.isFailed,
    this.progress,
  });

  final bool isDownloading;
  final bool isFailed;
  final double? progress;
}

/// 漫画详情页章节下载状态 + 长按多选控制器。
///
/// 订阅本地下载记录和下载任务表，章节行按
/// 已下载 > 下载中 > 排队中 > 失败 > 未下载的优先级显示状态。
class EpisodeDownloadController extends ChangeNotifier {
  EpisodeDownloadController();

  static const _repository = DownloadTaskRepository();
  static const _adapter = DownloadChapterAdapter();
  static const _matcher = DownloadChapterMatcher();

  String _from = '';
  String _comicId = '';
  String _comicTitle = '';
  bool _allowDownload = true;

  StreamSubscription? _recordSubscription;
  StreamSubscription? _taskSubscription;

  /// 已下载章节 id（DownloadChapter.id 形式）。
  Set<String> downloadedIds = {};

  /// 章节 key -> 任务快照（仅未完成任务）。
  final Map<String, _ChapterTaskSnap> _taskSnaps = {};

  bool selectionMode = false;
  final Set<String> selectedIds = {};

  String get _recordKey => buildDownloadTaskKey(_from, _comicId);

  bool get downloadUiEnabled => _from.isNotEmpty && _comicId.isNotEmpty;

  /// 详情数据加载完成后调用；key 不变时无动作。
  void attach({
    required String from,
    required String comicId,
    required String comicTitle,
    required bool allowDownload,
  }) {
    if (_from == from.trim() &&
        _comicId == comicId.trim() &&
        _comicTitle == comicTitle &&
        _allowDownload == allowDownload) {
      return;
    }
    _from = from.trim();
    _comicId = comicId.trim();
    _comicTitle = comicTitle;
    _allowDownload = allowDownload;
    // attach 在 build 期间调用，这里只同步算初值、不 notify；
    // 后续变化由订阅回调异步 notify。
    _resubscribe(notify: false);
    _loadInitial();
  }

  void _resubscribe({bool notify = true}) {
    unawaited(_recordSubscription?.cancel());
    unawaited(_taskSubscription?.cancel());
    _recordSubscription = null;
    _taskSubscription = null;
    if (!downloadUiEnabled) return;

    final recordQuery = objectbox.unifiedDownloadBox
        .query(UnifiedComicDownload_.uniqueKey.equals(_recordKey))
        .watch();
    _recordSubscription = recordQuery.listen((query) {
      final record = query.findFirst();
      downloadedIds = record == null
          ? <String>{}
          : resolveDownloadChapters(record).map((c) => c.id).toSet();
      notifyListeners();
    });

    final taskQuery = objectbox.downloadTaskBox
        .query(DownloadTask_.comicId.equals(_comicId))
        .watch();
    _taskSubscription = taskQuery.listen((query) {
      _readTaskSnaps(query.find());
      notifyListeners();
    });
    if (notify) notifyListeners();
  }

  void _loadInitial() {
    final record = _repository.findDownloadRecord(_from, _comicId);
    downloadedIds = record == null
        ? <String>{}
        : resolveDownloadChapters(record).map((c) => c.id).toSet();
    final tasks = objectbox.downloadTaskBox
        .query(DownloadTask_.comicId.equals(_comicId))
        .build()
        .find();
    _readTaskSnaps(tasks);
  }

  void _readTaskSnaps(List<DownloadTask> tasks) {
    final snaps = <String, _ChapterTaskSnap>{};
    for (final task in tasks) {
      if (task.isCompleted) continue;
      DownloadTaskJson? payload;
      try {
        payload = task.taskInfo;
      } catch (_) {
        continue;
      }
      if (payload == null || payload.from.trim() != _from) continue;
      final key = payload.chapterKey;
      if (key.isEmpty || snaps.containsKey(key)) continue;
      double? progress;
      if (payload.totalImages > 0) {
        progress =
            (payload.completedImages.clamp(0, payload.totalImages) /
                    payload.totalImages)
                .clamp(0.0, 1.0)
                .toDouble();
      }
      snaps[key] = _ChapterTaskSnap(
        isDownloading: task.isDownloading,
        isFailed: payload.stateCode == 'failed',
        progress: progress,
      );
    }
    _taskSnaps
      ..clear()
      ..addAll(snaps);
  }

  bool isDownloaded(DownloadChapter chapter) {
    if (downloadedIds.contains(chapter.id)) return true;
    for (final storedId in downloadedIds) {
      if (_matcher.matches(chapter, storedId)) return true;
    }
    return false;
  }

  ChapterDownloadStatus statusOf(DownloadChapter chapter) {
    if (isDownloaded(chapter)) {
      return ChapterDownloadStatus.downloaded;
    }
    final snap =
        _taskSnaps[chapter.id] ?? _taskSnaps[chapter.effectiveRequestId];
    if (snap == null) return ChapterDownloadStatus.notDownloaded;
    if (snap.isDownloading) return ChapterDownloadStatus.downloading;
    if (snap.isFailed) return ChapterDownloadStatus.failed;
    return ChapterDownloadStatus.queued;
  }

  double? progressOf(DownloadChapter chapter) {
    return (_taskSnaps[chapter.id] ?? _taskSnaps[chapter.effectiveRequestId])
        ?.progress;
  }

  // ---------- 多选 ----------

  void enterSelection(String chapterId) {
    selectionMode = true;
    selectedIds
      ..clear()
      ..add(chapterId);
    notifyListeners();
  }

  void toggleSelect(String chapterId) {
    if (selectedIds.contains(chapterId)) {
      selectedIds.remove(chapterId);
      if (selectedIds.isEmpty) {
        selectionMode = false;
      }
    } else {
      selectedIds.add(chapterId);
    }
    notifyListeners();
  }

  void selectAll(Iterable<String> chapterIds) {
    selectedIds
      ..clear()
      ..addAll(chapterIds);
    notifyListeners();
  }

  void clearSelection() {
    selectedIds.clear();
    notifyListeners();
  }

  void exitSelection() {
    selectionMode = false;
    selectedIds.clear();
    notifyListeners();
  }

  // ---------- 动作 ----------

  DownloadTaskJson _buildTask(DownloadChapter chapter) {
    return DownloadTaskJson(
      from: _from,
      comicId: _comicId,
      comicName: _comicTitle,
      chapterRef: DownloadChapterTaskRef(
        chapterId: chapter.id,
        requestId: chapter.effectiveRequestId,
        storageChapterId: chapter.effectiveStorageId,
        logicalKey: chapter.id,
        title: chapter.displayName,
        order: chapter.order,
        extern: Map<String, dynamic>.from(chapter.extern),
      ),
    );
  }

  /// 选中的可下载章节（未下载且无未完成任务）。
  List<DownloadChapter> downloadableOf(List<DownloadChapter> chapters) {
    return chapters.where((chapter) {
      if (statusOf(chapter) == ChapterDownloadStatus.downloaded) return false;
      if (statusOf(chapter) != ChapterDownloadStatus.notDownloaded &&
          statusOf(chapter) != ChapterDownloadStatus.failed) {
        return false;
      }
      return true;
    }).toList();
  }

  /// 选中的已下载章节。
  List<DownloadChapter> downloadedOf(List<DownloadChapter> chapters) {
    return chapters
        .where(
          (chapter) => statusOf(chapter) == ChapterDownloadStatus.downloaded,
        )
        .toList();
  }

  Future<void> downloadSingle(
    BuildContext context,
    DownloadChapter chapter,
  ) async {
    final status = statusOf(chapter);
    if (status == ChapterDownloadStatus.downloaded) return;
    if (status != ChapterDownloadStatus.notDownloaded &&
        status != ChapterDownloadStatus.failed) {
      return;
    }
    try {
      await startDownloadTask(_buildTask(chapter));
      if (context.mounted) showInfoToast(t.download.taskStarted);
    } catch (e) {
      logger.e('单章下载启动失败', error: e);
    }
  }

  Future<void> downloadChapters(
    BuildContext context,
    List<DownloadChapter> chapters,
  ) async {
    final targets = downloadableOf(chapters);
    if (targets.isEmpty) {
      showInfoToast(t.download.selectChaptersPrompt);
      return;
    }
    try {
      await startDownloadTasks(targets.map(_buildTask).toList());
      if (context.mounted) {
        showInfoToast(t.download.taskStarted);
      }
    } catch (e) {
      logger.e('多选下载启动失败', error: e);
    }
  }

  Future<void> cancelChapter(
    BuildContext context,
    DownloadChapter chapter,
  ) async {
    final confirmed = await _confirm(
      context,
      t.download.cancelTask,
      t.download.cancelTaskConfirm(comicName: _chapterLabel(chapter)),
    );
    if (!confirmed) return;
    await DownloadQueueManager.instance.cancelChapterTask(
      from: _from,
      comicId: _comicId,
      chapterKey: chapter.id,
    );
  }

  /// 删除单个已下载章节。返回 true 表示整本记录被删（调用方需 pop 页面）。
  ///
  /// 删的是最后一章时弹两次确认：先确认删章节，再确认连整本下载记录一起删。
  Future<bool> deleteSingle(
    BuildContext context,
    DownloadChapter chapter,
  ) async {
    final confirmed = await _confirm(
      context,
      t.comicEntry.deleteDownload,
      t.comicEntry.deleteDownloadConfirm(title: _chapterLabel(chapter)),
    );
    if (!confirmed) return false;
    if (!context.mounted) return false;
    if (isDownloaded(chapter) && downloadedIds.length <= 1) {
      final confirmedWhole = await _confirm(
        context,
        t.comicEntry.deleteDownload,
        t.download.deleteLastChapterContent,
      );
      if (!confirmedWhole) return false;
    }
    final result = await deleteDownloadedChapter(
      from: _from,
      comicId: _comicId,
      chapterKey: chapter.id,
    );
    return result == DeleteDownloadedChapterResult.wholeComicDeleted;
  }

  /// 删除多个已下载章节。返回 true 表示整本记录被删（调用方需 pop 页面）。
  Future<bool> deleteChapters(
    BuildContext context,
    List<DownloadChapter> chapters,
  ) async {
    final targets = downloadedOf(chapters);
    if (targets.isEmpty) return false;
    final isWhole =
        targets.length >= downloadedIds.length && downloadedIds.isNotEmpty;
    final confirmed = await _confirm(
      context,
      t.comicEntry.deleteDownload,
      isWhole
          ? t.comicEntry.deleteDownloadConfirm(title: _comicTitle)
          : t.comicEntry.deleteDownloadConfirm(
              title: targets.length == 1
                  ? _chapterLabel(targets.first)
                  : t.download.pending(count: targets.length),
            ),
    );
    if (!confirmed) return false;
    if (isWhole) {
      await deleteWholeComicDownload(from: _from, comicId: _comicId);
      return true;
    }
    for (final chapter in targets) {
      try {
        await deleteDownloadedChapter(
          from: _from,
          comicId: _comicId,
          chapterKey: chapter.id,
        );
      } catch (e) {
        logger.w('删除下载章节失败: ${chapter.id}', error: e);
      }
    }
    return false;
  }

  String _chapterLabel(DownloadChapter chapter) {
    final name = chapter.displayName.trim();
    return name.isEmpty ? _comicTitle : '$_comicTitle $name';
  }

  Future<bool> _confirm(
    BuildContext context,
    String title,
    String content,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.common.ok),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// 最近一次适配的章节列表（底栏全选等用，与列表显示顺序一致）。
  List<DownloadChapter> lastChapters = const [];

  /// 从在线章节列表构建 DownloadChapter（供 UI 层调用）。
  List<DownloadChapter> adaptEps(List<dynamic> eps) {
    lastChapters = eps.map((e) => _adapter.fromEp(e)).toList();
    return lastChapters;
  }

  @override
  void dispose() {
    unawaited(_recordSubscription?.cancel());
    unawaited(_taskSubscription?.cancel());
    super.dispose();
  }
}
