import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';

/// 章节下载状态（详情页章节行右侧按钮用）。
enum ChapterDownloadStatus {
  notDownloaded,
  queued,
  downloading,
  failed,
  downloaded,
}

/// 单个章节的未完成任务快照。
class ChapterTaskSnap {
  const ChapterTaskSnap({
    required this.isDownloading,
    required this.isFailed,
    this.progress,
  });

  final bool isDownloading;
  final bool isFailed;
  final double? progress;
}

/// 章节下载状态：已下载 id 集合 + 未完成任务快照表。
///
/// 由 [EpisodeDownloadStatusCubit] 持有，[EpisodeDownloadController]
/// 只读它做查询、不直接改它。行级 UI 用 BlocSelector 只订阅
/// 自己那一章的 `(status, progress)`，进度 tick 不会全列表重建。
class EpisodeDownloadStatusState {
  const EpisodeDownloadStatusState({
    this.downloadedIds = const {},
    this.taskSnaps = const {},
  });

  /// 已下载章节 id（DownloadChapter.id 形式）。
  final Set<String> downloadedIds;

  /// 章节 key -> 任务快照（仅未完成任务）。
  final Map<String, ChapterTaskSnap> taskSnaps;

  EpisodeDownloadStatusState copyWith({
    Set<String>? downloadedIds,
    Map<String, ChapterTaskSnap>? taskSnaps,
  }) {
    return EpisodeDownloadStatusState(
      downloadedIds: downloadedIds ?? this.downloadedIds,
      taskSnaps: taskSnaps ?? this.taskSnaps,
    );
  }

  bool isDownloaded(DownloadChapter chapter) {
    // O(1)：已下载集合里存的就是 DownloadChapter.id，章节的
    // id / requestId / order 字符串任一命中即视为已下载。
    if (downloadedIds.contains(chapter.id)) return true;
    if (downloadedIds.contains(chapter.effectiveRequestId)) return true;
    return downloadedIds.contains(chapter.order.toString());
  }

  /// 章节行按 已下载 > 下载中 > 排队中 > 失败 > 未下载 的优先级显示状态。
  ChapterDownloadStatus statusOf(DownloadChapter chapter) {
    if (isDownloaded(chapter)) {
      return ChapterDownloadStatus.downloaded;
    }
    final snap = taskSnaps[chapter.id] ?? taskSnaps[chapter.effectiveRequestId];
    if (snap == null) return ChapterDownloadStatus.notDownloaded;
    if (snap.isDownloading) return ChapterDownloadStatus.downloading;
    if (snap.isFailed) return ChapterDownloadStatus.failed;
    return ChapterDownloadStatus.queued;
  }

  double? progressOf(DownloadChapter chapter) {
    return (taskSnaps[chapter.id] ?? taskSnaps[chapter.effectiveRequestId])
        ?.progress;
  }
}

class EpisodeDownloadStatusCubit extends Cubit<EpisodeDownloadStatusState> {
  EpisodeDownloadStatusCubit() : super(const EpisodeDownloadStatusState());

  /// 合并更新下载状态（下载记录 / 任务表变化时调用）。
  void update({
    Set<String>? downloadedIds,
    Map<String, ChapterTaskSnap>? taskSnaps,
  }) {
    emit(state.copyWith(downloadedIds: downloadedIds, taskSnaps: taskSnaps));
  }
}
