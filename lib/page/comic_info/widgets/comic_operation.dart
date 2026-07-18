import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/page/comic_info/models/collect_comic.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/config/router/router.gr.dart';
import 'package:zephyr/i18n/strings.g.dart';

import 'package:zephyr/widgets/dialog.dart';
import 'package:zephyr/widgets/toast.dart';

class ComicOperationWidget extends StatefulWidget {
  final NormalComicAllInfo normalInfo;
  final String from;
  final dynamic comicInfo;

  const ComicOperationWidget({
    super.key,
    required this.normalInfo,
    required this.from,
    required this.comicInfo,
  });

  @override
  State<ComicOperationWidget> createState() => _ComicOperationWidgetState();
}

class _ComicOperationWidgetState extends State<ComicOperationWidget> {
  dynamic get comicInfo => widget.comicInfo;
  NormalComicAllInfo get normalInfo => widget.normalInfo;
  ComicInfo get comicInfoView => normalInfo.comicInfo;
  bool isCollected = false;
  bool isLiked = false;
  bool isCloudCollected = false;

  @override
  void initState() {
    super.initState();
    _syncLocalCollectStatus();
    isLiked = normalInfo.isLiked;
    isCloudCollected = normalInfo.isFavourite;
  }

  Future<void> _syncLocalCollectStatus() async {
    final localCollected = await isLocalComicCollected(
      from: widget.from,
      comicId: comicInfoView.id,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      isCollected = localCollected;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 开启「优先云端收藏」后，收藏按钮执行云端收藏，原逻辑与菜单项互换
    final cloudFavoritePreferred = context
        .watch<GlobalSettingCubit>()
        .state
        .cloudFavoritePreferred;
    final collectItem = cloudFavoritePreferred
        ? _OperationItemData(
            icon: isCloudCollected
                ? Icons.cloud_done_outlined
                : Icons.cloud_outlined,
            text: isCloudCollected
                ? t.comicInfo.collected
                : t.comicInfo.collectToCloud,
            highlighted: isCloudCollected,
            accentColor: const Color(0xFFE6A700),
            enabled: normalInfo.allowCollected,
            onTap: _toggleCloudFavorite,
          )
        : _OperationItemData(
            icon: isCollected ? Icons.star : Icons.star_border,
            text: isCollected ? t.comicInfo.collected : t.comicInfo.collect,
            highlighted: isCollected,
            accentColor: const Color(0xFFE6A700),
            enabled: true,
            onTap: _toggleLocalFavorite,
          );
    final actions = [
      _OperationItemData(
        icon: isLiked ? Icons.favorite : Icons.favorite_border,
        text: t.comicInfo.likes(count: normalInfo.totalLikes),
        highlighted: isLiked,
        accentColor: Colors.red,
        enabled: normalInfo.allowLike,
        onTap: _toggleCloudLike,
      ),
      _OperationItemData(
        icon: Icons.mode_comment_outlined,
        text: t.comicInfo.comments(count: normalInfo.totalComments),
        enabled: normalInfo.allowComments,
        onTap: _openComments,
      ),
      collectItem,
      _OperationItemData(
        icon: Icons.cloud_download_outlined,
        text: normalInfo.allowDownload
            ? t.comicInfo.download
            : t.comicInfo.downloadForbidden,
        enabled: normalInfo.allowDownload,
        onTap: _openDownload,
      ),
    ];

    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final itemWidth = switch (constraints.maxWidth) {
            < 420 => (constraints.maxWidth - 10) / 2,
            < 720 => (constraints.maxWidth - 20) / 3,
            < 900 => (constraints.maxWidth - 30) / 4,
            _ => 136.0,
          };

          return Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: actions
                  .map(
                    (item) => SizedBox(
                      width: itemWidth,
                      child: _OperationCard(item: item, compact: isDesktop),
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  void _openComments() {
    if (!normalInfo.allowComments) {
      commonDialog(
        context,
        t.comicInfo.commentForbiddenTitle,
        t.comicInfo.commentForbidden,
      );
      return;
    }

    context.pushRoute(
      PluginCommentsScaffoldRoute(
        from: widget.from,
        comicId: comicInfoView.id.toString(),
        comicTitle: comicInfoView.title,
      ),
    );
  }

  void _openDownload() {
    if (!normalInfo.allowDownload) return;
    final info = resolveUnifiedDownloadInfo(comicInfo, widget.from);
    context.pushRoute(DownloadRoute(downloadInfo: info));
  }

  Future<void> _toggleLocalFavorite() async {
    try {
      // 取消收藏需要确认，因为会删除所有文件夹中的记录
      if (isCollected) {
        final confirmed = await _showUncollectConfirmDialog();
        if (!confirmed) {
          return;
        }
      }

      final next = await toggleLocalComicFavorite(
        from: widget.from,
        normalInfo: normalInfo,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        isCollected = next;
      });
      if (next) {
        showSuccessToast(t.comicInfo.addedToCollection);
      } else {
        showSuccessToast(t.comicInfo.removedFromCollection);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(
        t.comicInfo.localCollectFailed(
          error: normalizeSearchErrorMessage(error),
        ),
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _toggleCloudFavorite() async {
    // 云端收藏被图源关闭时，沿用菜单的禁用提示
    if (!normalInfo.allowCollected) {
      showInfoToast(t.comicInfo.cloudCollectDisabled);
      return;
    }
    try {
      showInfoToast(
        isCloudCollected
            ? t.comicInfo.removingCloudCollection
            : t.comicInfo.collectingToCloud,
      );
      final next = await toggleCloudComicFavorite(
        context: context,
        from: widget.from,
        comicId: comicInfoView.id,
        currentStatus: isCloudCollected,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        isCloudCollected = next;
      });
      showSuccessToast(
        next
            ? t.comicInfo.cloudCollectSuccess
            : t.comicInfo.cloudUncollectSuccess,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(t.error.operationFailed);
    }
  }

  Future<bool> _showUncollectConfirmDialog() async {    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.comicInfo.confirmUncollectTitle),
          content: Text(t.comicInfo.confirmUncollectContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.common.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.common.confirm),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  Future<void> _toggleCloudLike() async {
    if (!normalInfo.allowLike) {
      return;
    }
    try {
      showInfoToast(isLiked ? t.comicInfo.unliking : t.comicInfo.liking);
      final next = await toggleCloudComicLike(
        from: widget.from,
        comicId: comicInfoView.id,
        currentStatus: isLiked,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        isLiked = next;
      });
      showSuccessToast(
        next ? t.comicInfo.likeSuccess : t.comicInfo.unlikeSuccess,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(
        t.comicInfo.likeFailed(error: normalizeSearchErrorMessage(error)),
        duration: const Duration(seconds: 5),
      );
    }
  }
}

class _OperationItemData {
  const _OperationItemData({
    required this.icon,
    required this.text,
    this.onTap,
    this.enabled = true,
    this.highlighted = false,
    this.accentColor,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  final bool highlighted;
  final Color? accentColor;
}

class _OperationCard extends StatelessWidget {
  const _OperationCard({required this.item, this.compact = false});

  final _OperationItemData item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = item.accentColor ?? context.theme.colorScheme.primary;
    final background = item.highlighted
        ? accent.withValues(alpha: 0.14)
        : context.theme.colorScheme.surfaceContainerLowest;
    final foreground = !item.enabled
        ? context.theme.colorScheme.onSurface.withValues(alpha: 0.38)
        : item.highlighted
        ? accent
        : context.textColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: item.onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 10 : 11,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: compact ? 18 : 20, color: foreground),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  item.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 13 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
