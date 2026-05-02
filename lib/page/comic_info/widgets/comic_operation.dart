import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/bookshelf/service/favorite_folder_service.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/page/comic_info/models/collect_comic.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/error_filter.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../../util/dialog.dart';
import '../../../widgets/toast.dart';

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
        text: '点赞 ${normalInfo.totalLikes}',
        highlighted: isLiked,
        accentColor: Colors.red,
        enabled: normalInfo.allowLike,
        onTap: _toggleCloudLike,
      ),
      _OperationItemData(
        icon: Icons.mode_comment_outlined,
        text: '评论 ${normalInfo.totalComments}',
        enabled: normalInfo.allowComments,
        onTap: _openComments,
      ),
      _OperationItemData(
        icon: isCollected ? Icons.star : Icons.star_border,
        text: isCollected ? '已收藏' : '收藏',
        highlighted: isCollected,
        accentColor: const Color(0xFFE6A700),
        enabled: true,
        onTap: _toggleLocalFavorite,
        onLongPress: _quickFavoriteToFolders,
      ),
      _OperationItemData(
        icon: Icons.cloud_download_outlined,
        text: normalInfo.allowDownload ? '下载' : '禁止下载',
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
      commonDialog(context, '禁止评论', '该漫画禁止评论');
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
      final uniqueKey = '${widget.from.trim()}:${comicInfoView.id}';
      if (next) {
        _showFavoriteSavedSnackbar(uniqueKey);
      } else {
        showSuccessToast('已取消本地收藏');
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(
        '本地收藏失败: ${normalizeSearchErrorMessage(error)}',
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _quickFavoriteToFolders() async {
    try {
      var collected = isCollected;
      if (!collected) {
        collected = await toggleLocalComicFavorite(
          from: widget.from,
          normalInfo: normalInfo,
          showToast: false,
        );
        if (mounted) {
          setState(() {
            isCollected = collected;
          });
        }
      }
      if (!mounted || !collected) {
        return;
      }
      final uniqueKey = '${widget.from.trim()}:${comicInfoView.id}';
      await _showManageFolderDialog(uniqueKey: uniqueKey);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorToast(
        '操作失败: ${normalizeSearchErrorMessage(error)}',
        duration: const Duration(seconds: 5),
      );
    }
  }

  void _showFavoriteSavedSnackbar(String uniqueKey) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('已添加至全部（长按收藏可直接修改文件夹）'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: '修改文件夹',
          onPressed: () => _showManageFolderDialog(uniqueKey: uniqueKey),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
    });
  }

  Future<void> _showManageFolderDialog({required String uniqueKey}) async {
    if (!mounted) return;
    var folders = FavoriteFolderService.listFolders()
        .where((item) => !item.isAll)
        .toList();
    final selected = FavoriteFolderService.folderKeysOfFavorite(uniqueKey);
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> createFolderInDialog() async {
            final name = await _showCreateFolderDialog();
            if (name == null || name.trim().isEmpty) {
              return;
            }
            try {
              final created = FavoriteFolderService.createFolder(name.trim());
              setState(() {
                folders = FavoriteFolderService.listFolders()
                    .where((item) => !item.isAll)
                    .toList();
                selected.add(created.key);
              });
            } catch (e) {
              if (!mounted) return;
              showErrorToast(e.toString());
            }
          }

          return AlertDialog(
            title: const Text('修改收藏夹'),
            content: SizedBox(
              width: 380,
              child: folders.isEmpty
                  ? const Text('暂无自定义收藏夹，请先新建。')
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final folder in folders)
                          CheckboxListTile(
                            value: selected.contains(folder.key),
                            title: Text(folder.name),
                            onChanged: (value) => setState(() {
                              if (value == true) {
                                selected.add(folder.key);
                              } else {
                                selected.remove(folder.key);
                              }
                            }),
                          ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: createFolderInDialog,
                child: const Text('新建文件夹'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context).pop(Set<String>.from(selected)),
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
    if (result == null) {
      return;
    }
    final before = FavoriteFolderService.folderKeysOfFavorite(uniqueKey);
    final toAdd = result.difference(before);
    final toRemove = before.difference(result);
    for (final folderKey in toAdd) {
      FavoriteFolderService.addMembers(folderKey, [uniqueKey]);
    }
    for (final folderKey in toRemove) {
      FavoriteFolderService.removeMembers(folderKey, [uniqueKey]);
    }
    if (!mounted) return;
    showSuccessToast('收藏夹已更新');
  }

  Future<String?> _showCreateFolderDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建收藏夹'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入收藏夹名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
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
        '点赞失败: ${normalizeSearchErrorMessage(error)}',
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
    this.onLongPress,
  });

  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  final bool highlighted;
  final Color? accentColor;
  final VoidCallback? onLongPress;
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
        onLongPress: item.onLongPress,
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
