import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_follow/cubit/comic_follow_cubit.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/comic_entry/models/models.dart';
import 'package:zephyr/widgets/comic_simplify_entry/cover.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/widgets/error_view.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class ComicFollowPage extends StatefulWidget {
  const ComicFollowPage({super.key});

  @override
  State<ComicFollowPage> createState() => _ComicFollowPageState();
}

class _ComicFollowPageState extends State<ComicFollowPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ComicFollowCubit>().refreshHistories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _ComicFollowPageContent();
  }
}

class _ComicFollowPageContent extends StatelessWidget {
  const _ComicFollowPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t.comicFollow.title),
        actions: [
          BlocBuilder<ComicFollowCubit, ComicFollowState>(
            buildWhen: (previous, current) =>
                previous.isCheckingUpdates != current.isCheckingUpdates,
            builder: (context, state) {
              return IconButton(
                icon: state.isCheckingUpdates
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: state.isCheckingUpdates
                    ? null
                    : () => context.read<ComicFollowCubit>().checkUpdates(),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ComicFollowCubit, ComicFollowState>(
        builder: (context, state) {
          switch (state.status) {
            case ComicFollowStatus.initial:
            case ComicFollowStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case ComicFollowStatus.failure:
              return ErrorView(
                errorMessage: t.comicFollow.loadFailed(result: state.result),
                onRetry: () =>
                    context.read<ComicFollowCubit>().loadFromDatabase(),
              );
            case ComicFollowStatus.success:
              if (state.items.isEmpty) {
                return _buildEmptyView(context);
              }
              return _buildContent(context, state);
          }
        },
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 64,
            color: context.theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            t.comicFollow.empty,
            style: context.theme.textTheme.titleMedium?.copyWith(
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(t.comicFollow.emptyHint, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ComicFollowState state) {
    final visibleItems = state.visibleItems;
    if (visibleItems.isEmpty && state.filter == ComicFollowFilter.unread) {
      return Column(
        children: [
          _buildToolbar(context, state),
          Expanded(child: _buildFilteredEmptyView(context)),
        ],
      );
    }

    return Column(
      children: [
        _buildToolbar(context, state),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxContentWidth = constraints.maxWidth > 1400
                  ? 1400.0
                  : (constraints.maxWidth > 900 ? 1100.0 : double.infinity);
              final horizontalPadding = maxContentWidth == double.infinity
                  ? 16.0
                  : (constraints.maxWidth - maxContentWidth) / 2;

              if (constraints.maxWidth >= 720) {
                return _buildGrid(context, state, horizontalPadding);
              }
              return _buildList(context, state, horizontalPadding);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar(BuildContext context, ComicFollowState state) {
    final cubit = context.read<ComicFollowCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          ChoiceChip(
            label: Text(t.comicFollow.all),
            selected: state.filter == ComicFollowFilter.all,
            onSelected: (_) => cubit.setFilter(ComicFollowFilter.all),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: Text(t.comicFollow.unread),
            selected: state.filter == ComicFollowFilter.unread,
            onSelected: (_) => cubit.setFilter(ComicFollowFilter.unread),
          ),
          const Spacer(),
          PopupMenuButton<ComicFollowSort>(
            tooltip: t.comicFollow.sort,
            initialValue: state.sort,
            onSelected: cubit.setSort,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ComicFollowSort.lastRead,
                child: Text(t.comicFollow.lastRead),
              ),
              PopupMenuItem(
                value: ComicFollowSort.update,
                child: Text(t.comicFollow.lastUpdate),
              ),
            ],
            child: const Icon(Icons.sort),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: context.theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            t.comicFollow.noUnread,
            style: context.theme.textTheme.titleMedium?.copyWith(
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => context.read<ComicFollowCubit>().setFilter(
              ComicFollowFilter.all,
            ),
            child: Text(t.comicFollow.showAll),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    ComicFollowState state,
    double horizontalPadding,
  ) {
    return RefreshIndicator(
      onRefresh: () => context.read<ComicFollowCubit>().checkUpdates(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          12,
          horizontalPadding,
          88,
        ),
        itemCount: state.visibleItems.length,
        itemBuilder: (context, index) {
          final follow = state.visibleItems[index];
          return _ComicFollowListItem(
            key: ValueKey(follow.uniqueKey),
            follow: follow,
            history: state.historyFor(follow),
            hasUnreadUpdate: state.hasUnreadUpdate(follow),
            unreadChapterCount: state.unreadChapterCount(follow),
            onTap: () => _openComicDetail(context, follow),
            onLongPress: () => _confirmRemove(context, follow),
            onRetry: follow.lastCheckFailed
                ? () => context.read<ComicFollowCubit>().checkUpdateForItem(
                    follow,
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    ComicFollowState state,
    double horizontalPadding,
  ) {
    final crossAxisCount = MediaQuery.of(context).size.width >= 1200 ? 3 : 2;

    return RefreshIndicator(
      onRefresh: () => context.read<ComicFollowCubit>().checkUpdates(),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          12,
          horizontalPadding,
          88,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.72,
        ),
        itemCount: state.visibleItems.length,
        itemBuilder: (context, index) {
          final follow = state.visibleItems[index];
          return _ComicFollowGridItem(
            key: ValueKey(follow.uniqueKey),
            follow: follow,
            history: state.historyFor(follow),
            hasUnreadUpdate: state.hasUnreadUpdate(follow),
            unreadChapterCount: state.unreadChapterCount(follow),
            onTap: () => _openComicDetail(context, follow),
            onLongPress: () => _confirmRemove(context, follow),
            onRetry: follow.lastCheckFailed
                ? () => context.read<ComicFollowCubit>().checkUpdateForItem(
                    follow,
                  )
                : null,
          );
        },
      ),
    );
  }

  Future<void> _openComicDetail(
    BuildContext context,
    ComicFollow follow,
  ) async {
    await context.pushRoute(
      ComicInfoRoute(
        comicId: follow.comicId,
        from: follow.source,
        type: ComicEntryType.normal,
      ),
    );
    if (context.mounted) {
      await context.read<ComicFollowCubit>().refreshHistories();
    }
  }

  Future<void> _confirmRemove(BuildContext context, ComicFollow follow) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.comicFollow.unfollow),
        content: Text(t.comicFollow.unfollowConfirm(title: follow.title)),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: Text(t.common.cancel),
          ),
          TextButton(
            onPressed: () => dialogContext.pop(true),
            child: Text(t.common.ok),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ComicFollowCubit>().removeFollow(
        follow.source,
        follow.comicId,
      );
      showSuccessToast(t.comicFollow.unfollowed);
    }
  }
}

class _ComicFollowListItem extends StatelessWidget {
  const _ComicFollowListItem({
    super.key,
    required this.follow,
    required this.history,
    required this.hasUnreadUpdate,
    required this.unreadChapterCount,
    required this.onTap,
    required this.onLongPress,
    required this.onRetry,
  });

  final ComicFollow follow;
  final UnifiedComicHistory? history;
  final bool hasUnreadUpdate;
  final int unreadChapterCount;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const coverWidth = 100.0;
    const coverHeight = 133.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasUnreadUpdate
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasUnreadUpdate)
              Container(
                width: 4,
                height: coverHeight,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: hasUnreadUpdate
                    ? Radius.zero
                    : const Radius.circular(12),
                bottomLeft: hasUnreadUpdate
                    ? Radius.zero
                    : const Radius.circular(12),
              ),
              child: _buildCover(coverWidth, coverHeight),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: coverHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  follow.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (hasUnreadUpdate) ...[
                                const SizedBox(width: 8),
                                _UpdateBadge(count: unreadChapterCount),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildStatusLine(theme),
                          if (hasUnreadUpdate &&
                              follow.detectedChapterTitle
                                  .trim()
                                  .isNotEmpty) ...[
                            const SizedBox(height: 6),
                            _buildLatestChapterLine(theme),
                          ],
                          const SizedBox(height: 6),
                          _buildReadingLine(theme),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            t.comicFollow.checkTime(
                              time: _formatCheckTime(follow.updateTime),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (onRetry != null) _RetryButton(onTap: onRetry!),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLine(ThemeData theme) {
    if (follow.lastCheckFailed) {
      return Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              t.comicFollow.latestChapterFailed,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    if (hasUnreadUpdate) {
      final diff = unreadChapterCount;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          t.comicFollow.newUnreadChapters(
            diff: diff,
            total: follow.detectedChapterCount,
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (follow.detectedChapterTitle.trim().isNotEmpty) {
      return _buildLatestChapterLine(theme);
    }

    return Text(
      t.comicFollow.latestCount(count: follow.detectedChapterCount),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildReadingLine(ThemeData theme) {
    final label = history == null || history!.chapterTitle.trim().isEmpty
        ? t.comicFollow.notRead
        : t.comicFollow.lastReadChapter(chapter: history!.chapterTitle);
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildLatestChapterLine(ThemeData theme) {
    final title = follow.detectedChapterTitle.trim();
    if (title.isEmpty) return const SizedBox.shrink();
    return Text(
      t.comicFollow.latestChapter(
        count: follow.detectedChapterCount,
        chapter: title,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildCover(double width, double height) {
    final cover = _resolveCover();
    return CoverWidget(
      fileServer: cover.url,
      path: cover.cachePath,
      id: follow.comicId,
      pictureType: PictureType.cover,
      from: follow.source,
      roundedCorner: false,
      width: width,
      height: height,
    );
  }

  UnifiedComicCover _resolveCover() {
    try {
      final map = _decodeJsonMap(follow.cover);
      if (map.isNotEmpty) {
        return UnifiedComicCover.fromJson(map);
      }
    } catch (_) {}
    return UnifiedComicCover(
      id: follow.comicId,
      url: '',
      path: '',
      extern: const <String, dynamic>{},
    );
  }

  Map<String, dynamic> _decodeJsonMap(String raw) {
    if (raw.trim().isEmpty) {
      return const <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return const <String, dynamic>{};
  }

  String _formatCheckTime(DateTime time) {
    final local = time.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }
}

class _ComicFollowGridItem extends StatelessWidget {
  const _ComicFollowGridItem({
    super.key,
    required this.follow,
    required this.history,
    required this.hasUnreadUpdate,
    required this.unreadChapterCount,
    required this.onTap,
    required this.onLongPress,
    required this.onRetry,
  });

  final ComicFollow follow;
  final UnifiedComicHistory? history;
  final bool hasUnreadUpdate;
  final int unreadChapterCount;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasUnreadUpdate
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCover(),
                    if (hasUnreadUpdate)
                      Positioned(top: 8, right: 8, child: _UpdateBadge()),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    follow.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildStatusLine(theme),
                  if (hasUnreadUpdate &&
                      follow.detectedChapterTitle.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _buildLatestChapterLine(theme),
                  ],
                  const SizedBox(height: 4),
                  _buildReadingLine(theme),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          t.comicFollow.checkTime(
                            time: _formatCheckTime(follow.updateTime),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (onRetry != null) _RetryButton(onTap: onRetry!),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLine(ThemeData theme) {
    if (follow.lastCheckFailed) {
      return Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: theme.colorScheme.error),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              t.comicFollow.fetchFailed,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    if (hasUnreadUpdate) {
      final diff = unreadChapterCount;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          t.comicFollow.newUnreadChaptersShort(diff: diff),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (follow.detectedChapterTitle.trim().isNotEmpty) {
      return _buildLatestChapterLine(theme);
    }

    return Text(
      t.comicFollow.latestCount(count: follow.detectedChapterCount),
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildReadingLine(ThemeData theme) {
    final label = history == null || history!.chapterTitle.trim().isEmpty
        ? t.comicFollow.notRead
        : t.comicFollow.lastReadChapter(chapter: history!.chapterTitle);
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildLatestChapterLine(ThemeData theme) {
    final title = follow.detectedChapterTitle.trim();
    if (title.isEmpty) return const SizedBox.shrink();
    return Text(
      t.comicFollow.latestChapter(
        count: follow.detectedChapterCount,
        chapter: title,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildCover() {
    final cover = _resolveCover();
    return CoverWidget(
      fileServer: cover.url,
      path: cover.cachePath,
      id: follow.comicId,
      pictureType: PictureType.cover,
      from: follow.source,
      roundedCorner: false,
    );
  }

  UnifiedComicCover _resolveCover() {
    try {
      final map = _decodeJsonMap(follow.cover);
      if (map.isNotEmpty) {
        return UnifiedComicCover.fromJson(map);
      }
    } catch (_) {}
    return UnifiedComicCover(
      id: follow.comicId,
      url: '',
      path: '',
      extern: const <String, dynamic>{},
    );
  }

  Map<String, dynamic> _decodeJsonMap(String raw) {
    if (raw.trim().isEmpty) {
      return const <String, dynamic>{};
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return const <String, dynamic>{};
  }

  String _formatCheckTime(DateTime time) {
    final local = time.toLocal();
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }
}

class _UpdateBadge extends StatelessWidget {
  const _UpdateBadge({this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count != null && count! > 0
        ? '+$count'
        : t.comicFollow.update;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(Icons.refresh, size: 16, color: theme.colorScheme.error),
      label: Text(
        t.comicFollow.retry,
        style: TextStyle(color: theme.colorScheme.error),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
