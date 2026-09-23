import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/page/comic_read/type/chapter_extern.dart';
import 'package:zephyr/page/download/adapters/download_chapter_adapter.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/page/comic_info/widgets/episode_download_controller.dart';
import 'package:zephyr/service/download/download_task_repository.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/text/chinese_convert.dart';
import 'package:zephyr/i18n/strings.g.dart';

import 'package:zephyr/config/router/router.gr.dart';

class EpButtonWidget extends StatelessWidget {
  static const double fixedHeight = 56;

  final Ep doc;
  final DownloadChapter chapter;
  final dynamic allInfo;
  final int epsLength;
  final ComicEntryType type;
  final String comicId;
  final String from;
  final int index;
  final bool isReversed;

  /// 章节下载状态；为 null 时不显示下载按钮（沿用旧箭头）。
  final ChapterDownloadStatus? downloadStatus;
  final double? downloadProgress;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onAction;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onEnterSelect;

  const EpButtonWidget({
    super.key,
    required this.doc,
    required this.chapter,
    required this.allInfo,
    required this.epsLength,
    required this.type,
    required this.comicId,
    required this.from,
    required this.index,
    required this.isReversed,
    this.downloadStatus,
    this.downloadProgress,
    this.selectionMode = false,
    this.selected = false,
    this.onAction,
    this.onToggleSelect,
    this.onEnterSelect,
  });

  @override
  Widget build(BuildContext context) {
    // 不依赖插件返回的 order，按当前显示位置自主计算序号：
    // 正序从上到下 1..N，倒序从下到上 N..1。
    final displayNumber = isReversed ? epsLength - index : index + 1;
    final title = doc.name.trim().isEmpty
        ? t.comicInfo.episodeFallback(index: displayNumber)
        : doc.name.trim();
    final colorScheme = context.theme.colorScheme;
    return InkWell(
      onTap: selectionMode ? onToggleSelect : () => _openRead(context),
      onLongPress: onEnterSelect,
      child: Container(
        width: double.infinity,
        height: fixedHeight,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer.withValues(alpha: 0.35)
              : context.theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.6),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            if (selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected
                      ? colorScheme.primary
                      : context.textColor.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
            Text(
              t.comicInfo.episodeLabel(index: displayNumber),
              style: context.theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title.let(convertChineseForDisplay),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: context.textColor,
                ),
              ),
            ),
            _buildTrailing(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final status = downloadStatus;
    if (status == null) {
      return Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: context.textColor.withValues(alpha: 0.5),
      );
    }
    // 行内容高度只有 32（56-上下 padding），IconButton 默认最小 40 会被纵向
    // 挤压，里面的进度圈会被压成椭圆。这里统一用 32x32 正方形槽位，保证不变形。
    Widget slot(Widget child) {
      return InkWell(
        onTap: onAction,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox.square(dimension: 32, child: Center(child: child)),
      );
    }

    switch (status) {
      case ChapterDownloadStatus.notDownloaded:
        return slot(const Icon(Icons.download_outlined, size: 20));
      case ChapterDownloadStatus.queued:
        return slot(const Icon(Icons.hourglass_empty, size: 20));
      case ChapterDownloadStatus.downloading:
        return slot(
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: downloadProgress,
            ),
          ),
        );
      case ChapterDownloadStatus.failed:
        return slot(
          Icon(
            Icons.error_outline,
            size: 20,
            color: context.theme.colorScheme.error,
          ),
        );
      case ChapterDownloadStatus.downloaded:
        return slot(
          Icon(
            Icons.check_circle,
            size: 20,
            color: context.theme.colorScheme.primary,
          ),
        );
    }
  }

  void _openRead(BuildContext context) {
    final chapter = const DownloadChapterAdapter().fromEp(doc);
    // 在线入口统一查库：该章已下载则直接读本地，不再看来源 type。
    if (type == ComicEntryType.normal || type == ComicEntryType.history) {
      final local = const DownloadTaskRepository().findDownloadedChapter(
        from: from,
        comicId: comicId,
        chapterKey: chapter.id,
      );
      final record = local == null
          ? null
          : const DownloadTaskRepository().findDownloadRecord(from, comicId);
      if (local != null && record != null) {
        context.pushRoute(
          ComicReadRoute(
            comicInfo: record,
            comicId: record.comicId,
            type: type == ComicEntryType.history
                ? ComicEntryType.historyAndDownload
                : ComicEntryType.download,
            order: local.order,
            chapterId: local.id,
            requestId: local.effectiveRequestId,
            storageChapterId: local.storageId ?? '',
            logicalKey: local.id,
            chapterExtern: ChapterExtern.from(local.extern),
            epsNumber: resolveStoredDownloadChapters(record).length,
            from: from,
            stringSelectCubit: context.read<StringSelectCubit>(),
          ),
        );
        return;
      }
    }
    final resolvedType = type == ComicEntryType.history
        ? ComicEntryType.normal
        : type;
    final chapterExtern = Map<String, dynamic>.from(doc.extern);
    context.pushRoute(
      ComicReadRoute(
        comicInfo: allInfo,
        comicId: comicId,
        type: resolvedType,
        order: chapter.order,
        chapterId: chapter.id,
        requestId: chapter.effectiveRequestId,
        storageChapterId: chapter.storageId ?? '',
        logicalKey: chapter.id,
        chapterExtern: enrichEpisodeChapterExtern(doc, chapterExtern),
        epsNumber: epsLength,
        from: from,
        stringSelectCubit: context.read<StringSelectCubit>(),
      ),
    );
  }

  ChapterExtern enrichEpisodeChapterExtern(
    Ep episode,
    ChapterExtern chapterExtern,
  ) {
    return chapterExtern;
  }
}
