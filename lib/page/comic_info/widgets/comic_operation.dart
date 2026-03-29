import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/page/comic_info/models/collect_comic.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/page/download/view/download.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../../util/dialog.dart';
import '../../../widgets/toast.dart';

class ComicOperationWidget extends StatefulWidget {
  final NormalComicAllInfo normalInfo;
  final From from;
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

  @override
  void initState() {
    super.initState();
    _syncLocalCollectStatus();
    isLiked = normalInfo.isLiked;
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
    final actions = [
      _OperationItemData(
        icon: isLiked ? Icons.favorite : Icons.favorite_border,
        label: '点赞',
        value: '${normalInfo.totalLikes}',
        highlighted: isLiked,
        accentColor: Colors.red,
        enabled: normalInfo.allowLike,
        onTap: _toggleCloudLike,
      ),
      _OperationItemData(
        icon: Icons.mode_comment_outlined,
        label: '评论',
        value: '${normalInfo.totalComments}',
        enabled: normalInfo.allowComment || widget.from == From.jm,
        onTap: _openComments,
      ),
      _OperationItemData(
        icon: isCollected ? Icons.star : Icons.star_border,
        label: '收藏',
        value: isCollected ? '本地已收藏' : '收藏到本地',
        highlighted: isCollected,
        accentColor: const Color(0xFFE6A700),
        enabled: true,
        onTap: _toggleLocalFavorite,
      ),
      _OperationItemData(
        icon: Icons.cloud_download_outlined,
        label: '下载',
        value: normalInfo.allowDownload ? '离线' : '关闭',
        enabled: normalInfo.allowDownload,
        onTap: _openDownload,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.theme.colorScheme.outlineVariant.withValues(
            alpha: 0.4,
          ),
        ),
      ),
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
    if (widget.from == From.bika) {
      if (normalInfo.allowComment) {
        AutoRouter.of(context).push(
          CommentsRoute(
            comicId: comicInfoView.id,
            comicTitle: comicInfoView.title,
          ),
        );
      } else {
        commonDialog(context, '禁止评论', '该漫画禁止评论');
      }
      return;
    }

    context.pushRoute(
      JmCommentsRoute(
        comicId: comicInfoView.id.toString(),
        comicTitle: comicInfoView.title,
      ),
    );
  }

  void _openDownload() {
    if (!normalInfo.allowDownload) return;
    final info = resolveUnifiedDownloadInfo(comicInfo, widget.from);
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => DownloadPage(downloadInfo: info)),
    );
  }

  Future<void> _toggleLocalFavorite() async {
    try {
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
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(
        '本地收藏失败: ${error.toString()}',
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _toggleCloudLike() async {
    if (!normalInfo.allowLike) {
      return;
    }
    try {
      showInfoToast(isLiked ? '取消点赞中...' : '点赞中...');
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
      showSuccessToast(next ? '点赞成功' : '已取消点赞');
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(
        '点赞失败: ${error.toString()}',
        duration: const Duration(seconds: 5),
      );
    }
  }
}

class _OperationItemData {
  const _OperationItemData({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.enabled = true,
    this.highlighted = false,
    this.accentColor,
  });

  final IconData icon;
  final String label;
  final String value;
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
            border: Border.all(
              color: item.highlighted
                  ? accent.withValues(alpha: 0.28)
                  : context.theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.35,
                    ),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 10 : 11,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: compact ? 20 : 22, color: foreground),
              SizedBox(height: compact ? 6 : 8),
              Text(
                item.label,
                style: context.theme.textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 13 : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.theme.textTheme.bodySmall?.copyWith(
                  color: foreground.withValues(
                    alpha: item.enabled ? 0.82 : 0.6,
                  ),
                  fontSize: compact ? 11.5 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
