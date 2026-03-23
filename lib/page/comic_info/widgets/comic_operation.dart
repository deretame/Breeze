import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/network/http/jm/http_request.dart' as jm;
import 'package:zephyr/page/bookshelf/json/jm_cloud_favorite/jm_cloud_favorite_json.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/page/download/view/download.dart';
import 'package:zephyr/page/jm/jm_download/view/view.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/json/json_dispose.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../../main.dart';
import '../../../network/http/bika/http_request.dart';
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
    isCollected = normalInfo.isFavourite;
    isLiked = normalInfo.isLiked;
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
        onTap: () {
          if (!normalInfo.allowLike) return;
          toggleAction('like');
        },
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
        value: isCollected ? '已收藏' : '收藏',
        highlighted: isCollected,
        accentColor: const Color(0xFFE6A700),
        enabled: normalInfo.allowFavorite,
        onTap: () {
          if (!normalInfo.allowFavorite) return;
          toggleAction('favorite');
        },
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
          color: context.theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
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
                      child: _OperationCard(
                        item: item,
                        compact: isDesktop,
                      ),
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
    if (widget.from == From.bika) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DownloadPage(downloadInfo: info),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => JmDownloadPage(downloadInfo: info),
        ),
      );
    }
  }

  void toggleAction(String actionType) async {
    if (widget.from == From.jm) {
      await jmToggleAction(actionType);
      return;
    }

    late Future<Map<String, dynamic>> result;
    late bool isCurrentlyActive;
    late String actionVerb;
    late String successMessage;
    late String failureMessage;

    switch (actionType) {
      case 'like':
        result = likeComic(comicInfoView.id);
        isCurrentlyActive = isLiked;
        actionVerb = '点赞';
        break;
      case 'favorite':
        result = favouriteComic(comicInfoView.id);
        isCurrentlyActive = isCollected;
        actionVerb = '收藏';
        break;
      default:
        throw ArgumentError('Invalid action type: $actionType');
    }

    showInfoToast("请求中...");

    try {
      final data = await result;

      if (data["error"] != null) {
        logger.d('$actionVerb失败: $data');
        if (!mounted) return;
        failureMessage = actionType == 'like'
            ? "请求失败: ${data["error"]}"
            : (isCurrentlyActive ? '取消$actionVerb失败' : '$actionVerb失败');
        showErrorToast(failureMessage, duration: const Duration(seconds: 5));
      } else {
        logger.d('$actionVerb成功: $data');
        if (mounted) {
          setState(() {
            if (actionType == 'like') {
              isLiked = !isLiked;
            } else {
              isCollected = !isCollected;
            }
          });
        }

        if (!mounted) return;
        successMessage = isCurrentlyActive
            ? '取消$actionVerb成功'
            : '$actionVerb成功';
        showSuccessToast(successMessage);
      }
    } catch (error) {
      if (!mounted) return;
      showErrorToast(
        "请求过程中发生错误: ${error.toString()}",
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> jmToggleAction(String actionType) async {
    late Future<Map<String, dynamic>> result;
    late bool isCurrentlyActive;
    late String actionVerb;
    late String successMessage;
    late String failureMessage;

    switch (actionType) {
      case 'like':
        if (isLiked) {
          showInfoToast("无法取消点赞");
          return;
        }
        result = jm.like(comicInfoView.id.toString());
        isCurrentlyActive = isLiked;
        actionVerb = '点赞';
        break;
      case 'favorite':
        final text = isCollected ? '取消收藏' : '收藏';
        showInfoToast("$text中...");
        await handleCollectLogic(
          context,
          comicInfoView.id.toString(),
          isCollected,
        );
        return;
      default:
        throw ArgumentError('Invalid action type: $actionType');
    }

    // 因为收藏只是往数据库里面写一下，速度很快，所以不需要显示请求中
    if (actionType == 'like') {
      showInfoToast("请求中...");
    }

    try {
      final data = await result;

      if (data["error"] != null) {
        logger.d('$actionVerb失败: $data');
        if (!mounted) return;
        failureMessage = actionType == 'like'
            ? "请求失败: ${data["error"]}"
            : (isCurrentlyActive ? '取消$actionVerb失败' : '$actionVerb失败');
        showErrorToast(failureMessage, duration: const Duration(seconds: 5));
      } else {
        logger.d('$actionVerb成功: $data');
        if (mounted) {
          setState(() {
            if (actionType == 'like') {
              isLiked = !isLiked;
            } else {
              isCollected = !isCollected;
            }
          });
        }

        if (!mounted) return;
        successMessage = isCurrentlyActive
            ? '取消$actionVerb成功'
            : '$actionVerb成功';
        showSuccessToast(successMessage);
      }
    } catch (error) {
      if (!mounted) return;
      logger.e(error);
      showErrorToast(
        "请求过程中发生错误: ${error.toString()}",
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<String> jmCollect(String comicId) async {
    final data = await jm.favorite(comicId);
    if (mounted) {
      setState(() => isCollected = !isCollected);
    }
    return data['msg'] ?? "操作成功";
  }

  Future<List<FolderList>> getFolderList() async {
    return await jm
        .getFavoriteList(page: 1, id: '', order: 'mr')
        .let(replaceNestedNullList)
        .let(jsonEncode)
        .let(jmCloudFavoriteJsonFromJson)
        .let((data) => data.folderList);
  }

  Future<String> addFolder(
    String comicId,
    FolderList folderList,
  ) async {
    final data = await jm.favoriteMoveFolder(
      comicId,
      folderList.fid.toString(),
      folderList.name,
    );
    return data['msg'];
  }

  Future<void> handleCollectLogic(
    BuildContext context,
    String comicId,
    bool currentStatus,
  ) async {
    // 1. 如果已经收藏，执行“取消收藏”
    if (currentStatus) {
      final msg = await _safeExecute(
        context,
        () => jmCollect(comicId),
        title: "取消收藏",
      );
      if (msg != null) {
        showSuccessToast("取消收藏成功");
      }
      return;
    }

    // 2. 如果未收藏，并行执行：收藏接口 + 获取收藏夹列表
    String? collectMsg;
    List<FolderList>? folders;

    final collectFuture =
        _safeExecute(context, () => jmCollect(comicId), title: "收藏操作").then((
          val,
        ) {
          collectMsg = val;
          if (val != null) showSuccessToast("收藏成功"); // 基础收藏成功提示
        });

    final folderFuture = _safeExecute(
      context,
      () => getFolderList(),
      title: "获取收藏夹列表",
      canSkip: true,
    ).then((val) => folders = val);

    await Future.wait([collectFuture, folderFuture]);

    // 3. 收藏成功后，如果有自定义收藏夹，弹出选择框
    if (collectMsg != null && folders != null && folders!.isNotEmpty) {
      if (!context.mounted) return;
      final selectedFolder = await showFolderSelectionDialog(context, folders!);

      if (selectedFolder != null && context.mounted) {
        // 4. 执行移动到特定收藏夹
        final moveMsg = await _safeExecute(
          context,
          () => addFolder(comicId, selectedFolder),
          title: "移动到收藏夹",
        );

        if (moveMsg != null) {
          showSuccessToast("已添加到收藏夹: ${selectedFolder.name}");
        }
      }
    }
  }

  /// 通用的重试执行器
  Future<T?> _safeExecute<T>(
    BuildContext context,
    Future<T> Function() task, {
    required String title,
    bool canSkip = false,
  }) async {
    while (true) {
      try {
        return await task();
      } catch (e) {
        logger.e(e);
        if (!context.mounted) return null;

        final retry = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('$title失败'),
            content: Text('错误信息: $e\n是否重试？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('重试'),
              ),
            ],
          ),
        );

        if (retry != true) {
          return null;
        }
      }
    }
  }

  Future<FolderList?> showFolderSelectionDialog(
    BuildContext context,
    List<FolderList> folders,
  ) {
    FolderList? tempSelected;

    return showDialog<FolderList>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('添加到自定义收藏夹'),
              // 限制高度，防止列表太长超出屏幕
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: folders.length,
                    itemBuilder: (ctx, index) {
                      final folder = folders[index];
                      return RadioListTile<String>(
                        title: Text(folder.name),
                        subtitle: Text("ID: ${folder.fid}"),
                        value: folder.fid,
                        // ignore: deprecated_member_use
                        groupValue: tempSelected?.fid,
                        // ignore: deprecated_member_use
                        onChanged: (val) {
                          setState(() => tempSelected = folder);
                        },
                      );
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('跳过/不添加'),
                ),
                ElevatedButton(
                  // 只有选中了才能点击确定
                  onPressed: tempSelected == null
                      ? null
                      : () => Navigator.pop(dialogContext, tempSelected),
                  child: const Text('确定添加'),
                ),
              ],
            );
          },
        );
      },
    );
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
                  : context.theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
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
                  color: foreground.withValues(alpha: item.enabled ? 0.82 : 0.6),
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
