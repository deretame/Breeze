import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_follow/cubit/comic_follow_cubit.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/comic_entry/models/models.dart';
import 'package:zephyr/widgets/comic_simplify_entry/cover.dart';
import 'package:zephyr/widgets/error_view.dart';
import 'package:zephyr/widgets/toast.dart';

@RoutePage()
class ComicFollowPage extends StatelessWidget {
  const ComicFollowPage({super.key});

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
        title: const Text('追更'),
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
                errorMessage: '加载失败：${state.result}',
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
            '暂无追更漫画',
            style: context.theme.textTheme.titleMedium?.copyWith(
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '在漫画详情页点击追更按钮即可加入',
            style: context.theme.textTheme.bodySmall?.copyWith(
              color: context.theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, ComicFollowState state) {
    return LayoutBuilder(
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
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final follow = state.items[index];
          return _ComicFollowListItem(
            follow: follow,
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
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final follow = state.items[index];
          return _ComicFollowGridItem(
            follow: follow,
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

  void _openComicDetail(BuildContext context, ComicFollow follow) {
    context.pushRoute(
      ComicInfoRoute(
        comicId: follow.comicId,
        from: follow.source,
        pluginId: follow.source,
        type: ComicEntryType.normal,
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, ComicFollow follow) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('取消追更'),
        content: Text('确定不再追更《${follow.title}》吗？'),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => dialogContext.pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<ComicFollowCubit>().removeFollow(
        follow.source,
        follow.comicId,
      );
      showSuccessToast('已取消追更');
    }
  }
}

class _ComicFollowListItem extends StatelessWidget {
  const _ComicFollowListItem({
    required this.follow,
    required this.onTap,
    required this.onLongPress,
    required this.onRetry,
  });

  final ComicFollow follow;
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
            color: follow.hasUpdate
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (follow.hasUpdate)
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
                topLeft: follow.hasUpdate
                    ? Radius.zero
                    : const Radius.circular(12),
                bottomLeft: follow.hasUpdate
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
                              if (follow.hasUpdate) ...[
                                const SizedBox(width: 8),
                                _UpdateBadge(
                                  count:
                                      follow.detectedChapterCount -
                                      follow.lastChapterCount,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildStatusLine(theme),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatUpdateTime(follow.updateTime),
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
              '最新章节获取失败',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    if (follow.hasUpdate) {
      final diff = follow.detectedChapterCount - follow.lastChapterCount;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '新增 $diff 话，共 ${follow.detectedChapterCount} 话',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Text(
      '最新 ${follow.detectedChapterCount} 话',
      style: theme.textTheme.bodyMedium?.copyWith(
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

  String _formatUpdateTime(DateTime time) {
    final local = time.toLocal();
    return '${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

class _ComicFollowGridItem extends StatelessWidget {
  const _ComicFollowGridItem({
    required this.follow,
    required this.onTap,
    required this.onLongPress,
    required this.onRetry,
  });

  final ComicFollow follow;
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
            color: follow.hasUpdate
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
                    if (follow.hasUpdate)
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
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _formatUpdateTime(follow.updateTime),
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
              '获取失败',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    if (follow.hasUpdate) {
      final diff = follow.detectedChapterCount - follow.lastChapterCount;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '新增 $diff 话',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Text(
      '最新 ${follow.detectedChapterCount} 话',
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

  String _formatUpdateTime(DateTime time) {
    final local = time.toLocal();
    return '${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}

class _UpdateBadge extends StatelessWidget {
  const _UpdateBadge({this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = count != null && count! > 0 ? '+$count' : '更新';
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
      label: Text('重试', style: TextStyle(color: theme.colorScheme.error)),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
