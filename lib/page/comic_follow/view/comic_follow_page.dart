import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_follow/cubit/comic_follow_cubit.dart';
import 'package:zephyr/page/comic_follow/view/follow_display.dart';
import 'package:zephyr/plugin/plugin_registry_service.dart';
import 'package:zephyr/type/enum.dart';
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

/// 追更列表页：顶部摘要条（更新数 + 检测 + 全部已读）+ 筛选行 + 单列列表。
class _ComicFollowPageContent extends StatelessWidget {
  const _ComicFollowPageContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.comicFollow.title)),
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
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_outlined,
                size: 44,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t.comicFollow.empty,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              t.comicFollow.emptyHint,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ComicFollowState state) {
    final visibleItems = state.visibleItems;
    // 桌面端窄栏居中：与 more/plugin_store 等页一致，Align + 768 上限，
    // 摘要条/筛选行/列表整体收进同一栏，不再全宽拉伸。
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 768),
        child: Column(
          children: [
            _SummaryBar(state: state),
            _FilterRow(state: state),
            Expanded(
              child:
                  visibleItems.isEmpty &&
                      state.filter == ComicFollowFilter.unread
                  ? _buildFilteredEmptyView(context)
                  : _FollowList(items: visibleItems),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyView(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 56,
            color: scheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            t.comicFollow.noUnread,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
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
}

/// 顶部摘要条：更新计数 + 检测按钮 + 全部已读。
class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.state});

  final ComicFollowState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final unread = state.updateCount;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: unread > 0
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              unread > 0
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none_outlined,
              size: 20,
              color: unread > 0 ? scheme.onPrimary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unread > 0
                      ? t.comicFollow.unreadCountBadge(count: unread)
                      : t.comicFollow.noUnread,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  state.isCheckingUpdates
                      ? t.common.loading
                      : t.comicFollow.checkTime(
                          time: formatFollowCheckTime(_latestCheck(state)),
                        ),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (!state.isCheckingUpdates && unread > 0)
            IconButton(
              tooltip: t.comicFollow.markAllReadHint,
              icon: const Icon(Icons.done_all_outlined),
              onPressed: () async {
                await context.read<ComicFollowCubit>().markAllAsRead();
                if (context.mounted) {
                  showSuccessToast(t.comicFollow.markAllReadDone);
                }
              },
            ),
          IconButton(
            tooltip: t.common.refresh,
            onPressed: state.isCheckingUpdates
                ? null
                : () => context.read<ComicFollowCubit>().checkUpdates(),
            icon: state.isCheckingUpdates
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }

  DateTime _latestCheck(ComicFollowState state) {
    var latest = state.items.first.updateTime;
    for (final item in state.items) {
      if (item.updateTime.isAfter(latest)) {
        latest = item.updateTime;
      }
    }
    return latest;
  }
}

/// 筛选行：全部 / 未读 SegmentedButton + 排序菜单。
class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.state});

  final ComicFollowState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ComicFollowCubit>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
      child: Row(
        children: [
          SegmentedButton<ComicFollowFilter>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            segments: [
              ButtonSegment(
                value: ComicFollowFilter.all,
                label: Text(t.comicFollow.all),
              ),
              ButtonSegment(
                value: ComicFollowFilter.unread,
                label: Text(t.comicFollow.unread),
              ),
            ],
            selected: {state.filter},
            onSelectionChanged: (selected) => cubit.setFilter(selected.first),
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
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.sort == ComicFollowSort.lastRead
                        ? t.comicFollow.lastRead
                        : t.comicFollow.lastUpdate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.sort, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单列列表：最大宽度约束居中，下拉刷新。
class _FollowList extends StatelessWidget {
  const _FollowList({required this.items});

  final List<ComicFollow> items;

  @override
  Widget build(BuildContext context) {
    // 外层已用 ConstrainedBox(768) 居中，这里只留固定边距。
    return RefreshIndicator(
      onRefresh: () => context.read<ComicFollowCubit>().checkUpdates(),
      child: BlocBuilder<ComicFollowCubit, ComicFollowState>(
        builder: (context, state) {
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final follow = items[index];
              return _FollowCard(
                key: ValueKey(follow.uniqueKey),
                follow: follow,
                history: state.historyFor(follow),
                hasUnreadUpdate: state.hasUnreadUpdate(follow),
                unreadChapterCount: state.unreadChapterCount(follow),
              );
            },
          );
        },
      ),
    );
  }
}

/// 新版列表卡片：封面 + 标题 + 来源/作者 + 进度条 + 最新/在读 + 底行时间。
class _FollowCard extends StatelessWidget {
  const _FollowCard({
    super.key,
    required this.follow,
    required this.history,
    required this.hasUnreadUpdate,
    required this.unreadChapterCount,
  });

  final ComicFollow follow;
  final UnifiedComicHistory? history;
  final bool hasUnreadUpdate;
  final int unreadChapterCount;

  static const _coverWidth = 84.0;
  static const _coverHeight = 112.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cover = resolveFollowCover(follow);

    return Dismissible(
      key: ValueKey('dismiss-${follow.uniqueKey}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
      ),
      confirmDismiss: (_) => _askUnfollow(context),
      onDismissed: (_) => _removeFollow(context),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openDetail(context),
        onLongPress: () => _onLongPress(context),
        child: Container(
          decoration: BoxDecoration(
            color: hasUnreadUpdate
                ? scheme.primaryContainer.withValues(alpha: 0.35)
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUnreadUpdate
                  ? scheme.primary.withValues(alpha: 0.5)
                  : scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCover(cover),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleRow(theme),
                      const SizedBox(height: 4),
                      _buildSourceLine(theme),
                      const SizedBox(height: 8),
                      _buildProgress(theme),
                      const SizedBox(height: 8),
                      _buildLatestLine(context, theme),
                      const SizedBox(height: 2),
                      _buildReadingLine(theme),
                      const SizedBox(height: 6),
                      _buildBottomRow(context, theme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 长按走“菜单式”二次确认：先弹取消追更确认框，确认后真正移除并 toast。
  Future<void> _onLongPress(BuildContext context) async {
    final confirmed = await _askUnfollow(context);
    if (confirmed == true && context.mounted) {
      await _removeFollow(context);
    }
  }

  Widget _buildCover(UnifiedComicCover cover) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CoverWidget(
          fileServer: cover.url,
          path: cover.cachePath,
          id: follow.comicId,
          pictureType: PictureType.cover,
          from: follow.source,
          roundedCorner: false,
          width: _coverWidth,
          height: _coverHeight,
        ),
      ),
    );
  }

  Widget _buildTitleRow(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            follow.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (hasUnreadUpdate) ...[
          const SizedBox(width: 8),
          _UnreadPill(count: unreadChapterCount),
        ] else if (follow.hasUpdate && follow.detectedChapterCount > 0) ...[
          // 已读完最新：小圆点表示“刚更新过”，不抢视觉。
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 来源插件名 + 作者，插件名走 getCachedPluginInfo（含 DB 兜底）。
  Widget _buildSourceLine(ThemeData theme) {
    final scheme = theme.colorScheme;
    return BlocSelector<
      PluginRegistryCubit,
      Map<String, PluginRuntimeState>,
      String
    >(
      selector: (_) => _pluginLabel(),
      builder: (context, pluginLabel) {
        final parts = [
          if (pluginLabel.isNotEmpty) pluginLabel,
          ?parseFollowCreatorName(follow.creator),
        ];
        if (parts.isEmpty) {
          return const SizedBox.shrink();
        }
        return Row(
          children: [
            Icon(Icons.source_outlined, size: 13, color: scheme.outline),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                parts.join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _pluginLabel() {
    final info = PluginRegistryService.I.getCachedPluginInfo(follow.source);
    final name = info?['name']?.toString().trim() ?? '';
    return name.isNotEmpty ? name : follow.source;
  }

  /// 阅读进度条：读到 order / 最新总数。
  Widget _buildProgress(ThemeData theme) {
    final scheme = theme.colorScheme;
    final readOrder = history?.chapterOrder ?? 0;
    final total = follow.detectedChapterCount;
    final progress = followReadProgress(
      readOrder: readOrder,
      detectedTotal: total,
    );
    final label = readOrder > 0
        ? t.comicFollow.readProgress(read: readOrder, total: total)
        : t.comicFollow.readProgressUnknown(total: total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: total > 0 ? progress : null,
            minHeight: 4,
            backgroundColor: scheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(
              hasUnreadUpdate ? scheme.primary : scheme.outline,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLatestLine(BuildContext context, ThemeData theme) {
    final scheme = theme.colorScheme;
    if (follow.lastCheckFailed) {
      return GestureDetector(
        onTap: () => _retry(context),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 14, color: scheme.error),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                t.comicFollow.checkFailedTapRetry,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    final title = follow.detectedChapterTitle.trim();
    final latest = title.isEmpty
        ? t.comicFollow.latestCount(count: follow.detectedChapterCount)
        : t.comicFollow.latestChapter(
            count: follow.detectedChapterCount,
            chapter: title,
          );
    return Row(
      children: [
        Icon(
          hasUnreadUpdate
              ? Icons.fiber_new_outlined
              : Icons.check_circle_outline,
          size: 14,
          color: hasUnreadUpdate ? scheme.primary : scheme.outline,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            latest,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: hasUnreadUpdate
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant,
              fontWeight: hasUnreadUpdate ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadingLine(ThemeData theme) {
    final scheme = theme.colorScheme;
    final chapter = history?.chapterTitle.trim() ?? '';
    final label = chapter.isEmpty
        ? t.comicFollow.notRead
        : t.comicFollow.lastReadChapter(chapter: chapter);
    return Row(
      children: [
        Icon(Icons.history_outlined, size: 14, color: scheme.outline),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  /// 底行：相对更新时间 + 相对上次阅读；失败时重试按钮。
  /// 需要 context 触发 cubit 单项检测：旧 _retry 是无 context 的空实现。
  Widget _buildBottomRow(BuildContext context, ThemeData theme) {
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            _relativeUpdate(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        if (history?.chapterTitle.trim().isNotEmpty == true)
          Text(
            _relativeRead(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        if (follow.lastCheckFailed) ...[
          const SizedBox(width: 4),
          _RetryChip(onTap: () => _retry(context)),
        ],
      ],
    );
  }

  String _relativeUpdate() {
    final diff = DateTime.now().toLocal().difference(
      follow.updateTime.toLocal(),
    );
    if (diff.inMinutes < 1) {
      return t.comicFollow.updatedJustNow;
    }
    if (diff.inHours < 1) {
      return t.comicFollow.updatedMinutesAgo(minutes: diff.inMinutes);
    }
    if (diff.inDays < 1) {
      return t.comicFollow.updatedHoursAgo(hours: diff.inHours);
    }
    return t.comicFollow.updatedDaysAgo(days: diff.inDays);
  }

  String _relativeRead() {
    final lastRead = history?.lastReadAt;
    if (lastRead == null) {
      return '';
    }
    final diff = DateTime.now().toLocal().difference(lastRead.toLocal());
    if (diff.inMinutes < 1) {
      return t.comicFollow.updatedJustNow;
    }
    if (diff.inHours < 1) {
      return t.comicFollow.lastReadMinutesAgo(minutes: diff.inMinutes);
    }
    if (diff.inDays < 1) {
      return t.comicFollow.lastReadHoursAgo(hours: diff.inHours);
    }
    return t.comicFollow.lastReadDaysAgo(days: diff.inDays);
  }

  Future<void> _openDetail(BuildContext context) async {
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

  /// 单项重试：需要 context 拿 cubit；失败由 cubit 写回 lastCheckFailed。
  Future<void> _retry(BuildContext context) {
    return context.read<ComicFollowCubit>().checkUpdateForItem(follow);
  }

  Future<bool?> _askUnfollow(BuildContext context) {
    return showDialog<bool>(
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
  }

  Future<void> _removeFollow(BuildContext context) async {
    await context.read<ComicFollowCubit>().removeFollow(
      follow.source,
      follow.comicId,
    );
    showSuccessToast(t.comicFollow.unfollowed);
  }
}

class _UnreadPill extends StatelessWidget {
  const _UnreadPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        t.comicFollow.unreadCountBadge(count: count),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RetryChip extends StatelessWidget {
  const _RetryChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, size: 13, color: scheme.onErrorContainer),
            const SizedBox(width: 2),
            Text(
              t.comicFollow.retry,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
