import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/cubit/episode_download_status_cubit.dart';
import 'package:zephyr/page/comic_info/cubit/episode_selection_cubit.dart';
import 'package:zephyr/page/download/adapters/download_chapter_adapter.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/service/download/download_delete_service.dart';
import 'package:zephyr/service/download/download_queue_manager.dart';
import 'package:zephyr/service/download/download_task_repository.dart';
import 'package:zephyr/service/download/models/download_task_json.dart';
import 'package:zephyr/widgets/toast.dart';

/// 漫画详情页章节下载状态 + 长按多选控制器。
///
/// 下载状态由 [statusCubit] 持有，多选态由 [selectionCubit] 持有，
/// 行级 UI 各自订阅。
/// 订阅本地下载记录和下载任务表，章节行按
/// 已下载 > 下载中 > 排队中 > 失败 > 未下载的优先级显示状态。
class EpisodeDownloadController {
  EpisodeDownloadController();

  static const _repository = DownloadTaskRepository();
  static const _adapter = DownloadChapterAdapter();

  /// 多选态版本号 cubit：只在进入/切换/全选/清空/退出选择时 bump。
  /// 章节行用它做行级监听，下载进度 tick 只走 [statusCubit]，
  /// 不会触发选中 UI 的全列表重建。
  final EpisodeSelectionCubit selectionCubit = EpisodeSelectionCubit();

  /// 下载状态 cubit：下载记录 / 任务表变化时 emit，章节角标订阅它。
  final EpisodeDownloadStatusCubit statusCubit = EpisodeDownloadStatusCubit();

  String _from = '';
  String _comicId = '';
  String _comicTitle = '';
  bool _allowDownload = true;

  StreamSubscription? _recordSubscription;
  StreamSubscription? _taskSubscription;

  /// 已下载章节 id（DownloadChapter.id 形式），只读 [statusCubit] 的状态。
  Set<String> get downloadedIds => statusCubit.state.downloadedIds;

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
    // attach 在 _EpisodeBoard 的 initState/didUpdateWidget 里调用，
    // 这里同步算初值后 emit 一次；后续变化由订阅回调异步 emit。
    _resubscribe();
    _loadInitial();
  }

  void _updateStatus({
    Set<String>? downloadedIds,
    Map<String, ChapterTaskSnap>? taskSnaps,
  }) {
    if (statusCubit.isClosed) return;
    statusCubit.update(downloadedIds: downloadedIds, taskSnaps: taskSnaps);
  }

  static Set<String> _resolveDownloadedIds(UnifiedComicDownload? record) {
    return record == null
        ? <String>{}
        : resolveDownloadChapters(record).map((c) => c.id).toSet();
  }

  void _resubscribe() {
    unawaited(_recordSubscription?.cancel());
    unawaited(_taskSubscription?.cancel());
    _recordSubscription = null;
    _taskSubscription = null;
    if (!downloadUiEnabled) return;

    final recordQuery = objectbox.unifiedDownloadBox
        .query(UnifiedComicDownload_.uniqueKey.equals(_recordKey))
        .watch();
    _recordSubscription = recordQuery.listen((query) {
      _updateStatus(downloadedIds: _resolveDownloadedIds(query.findFirst()));
    });

    final taskQuery = objectbox.downloadTaskBox
        .query(DownloadTask_.comicId.equals(_comicId))
        .watch();
    _taskSubscription = taskQuery.listen((query) {
      _updateStatus(taskSnaps: _buildTaskSnaps(query.find()));
    });
  }

  void _loadInitial() {
    final record = _repository.findDownloadRecord(_from, _comicId);
    final tasks = objectbox.downloadTaskBox
        .query(DownloadTask_.comicId.equals(_comicId))
        .build()
        .find();
    _updateStatus(
      downloadedIds: _resolveDownloadedIds(record),
      taskSnaps: _buildTaskSnaps(tasks),
    );
  }

  Map<String, ChapterTaskSnap> _buildTaskSnaps(List<DownloadTask> tasks) {
    final snaps = <String, ChapterTaskSnap>{};
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
      snaps[key] = ChapterTaskSnap(
        isDownloading: task.isDownloading,
        isFailed: payload.stateCode == 'failed',
        progress: progress,
      );
    }
    return snaps;
  }

  bool isDownloaded(DownloadChapter chapter) =>
      statusCubit.state.isDownloaded(chapter);

  ChapterDownloadStatus statusOf(DownloadChapter chapter) =>
      statusCubit.state.statusOf(chapter);

  double? progressOf(DownloadChapter chapter) =>
      statusCubit.state.progressOf(chapter);

  // ---------- 多选 ----------

  void _notifySelection() {
    // 选中变化只 bump 版本号：行级选中 UI 订阅 selectionCubit，
    // 下载角标订阅 statusCubit，互不影响。
    selectionCubit.bump();
  }

  void enterSelection(String chapterId) {
    selectionMode = true;
    selectedIds
      ..clear()
      ..add(chapterId);
    _notifySelection();
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
    _notifySelection();
  }

  void selectAll(Iterable<String> chapterIds) {
    selectedIds
      ..clear()
      ..addAll(chapterIds);
    _notifySelection();
  }

  void clearSelection() {
    selectedIds.clear();
    _notifySelection();
  }

  void exitSelection() {
    selectionMode = false;
    selectedIds.clear();
    _notifySelection();
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
      final status = statusOf(chapter);
      return status == ChapterDownloadStatus.notDownloaded ||
          status == ChapterDownloadStatus.failed;
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
  List<dynamic> _lastEpsRefs = const [];

  /// 从在线章节列表构建 DownloadChapter（供 UI 层调用）。
  ///
  /// 带元素级缓存：displayEps 每次 build 都是新 List，但里面 Ep 实例
  /// 不变时（下载进度 tick 触发的重建）直接复用上次结果，避免
  /// O(N) 的 fromEp + extern Map 拷贝。倒序切换会改变元素顺序，
  /// 自然 miss 并按新顺序重建。
  List<DownloadChapter> adaptEps(List<dynamic> eps) {
    if (_lastEpsRefs.length == eps.length && eps.isNotEmpty) {
      var same = true;
      for (var i = 0; i < eps.length; i++) {
        if (!identical(_lastEpsRefs[i], eps[i])) {
          same = false;
          break;
        }
      }
      if (same) return lastChapters;
    }
    lastChapters = eps.map((e) => _adapter.fromEp(e)).toList();
    _lastEpsRefs = List<dynamic>.from(eps, growable: false);
    return lastChapters;
  }

  void dispose() {
    unawaited(_recordSubscription?.cancel());
    unawaited(_taskSubscription?.cancel());
    unawaited(selectionCubit.close());
    unawaited(statusCubit.close());
  }
}
