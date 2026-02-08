import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/network/http/jm/http_request.dart' as jm;
import 'package:zephyr/page/bookshelf/json/jm_cloud_favorite/jm_cloud_favorite_json.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
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
  final ComicInfo normalComicInfo;
  final From from;
  final dynamic comicInfo;

  const ComicOperationWidget({
    super.key,
    required this.normalComicInfo,
    required this.from,
    required this.comicInfo,
  });

  @override
  State<ComicOperationWidget> createState() => _ComicOperationWidgetState();
}

class _ComicOperationWidgetState extends State<ComicOperationWidget> {
  dynamic get comicInfo => widget.comicInfo;
  ComicInfo get normalComicInfo => widget.normalComicInfo;
  bool isCollected = false;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    isCollected = normalComicInfo.isFavourite;
    isLiked = normalComicInfo.isLiked;
  }

  @override
  Widget build(BuildContext context) {
    return LimitedBox(
      maxWidth: context.screenWidth * (48 / 50),
      maxHeight: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Column(
            children: <Widget>[
              const Icon(Icons.remove_red_eye, size: 24.0),
              const SizedBox(height: 2),
              Text('${normalComicInfo.totalViews}'),
            ],
          ),
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: () async {
                  toggleAction('like');
                },
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : context.textColor,
                  size: 24.0,
                ),
              ),
              const SizedBox(height: 2),
              Text('${normalComicInfo.totalLikes}'),
            ],
          ),
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  if (widget.from == From.bika) {
                    if (normalComicInfo.allowComment) {
                      AutoRouter.of(context).push(
                        CommentsRoute(
                          comicId: normalComicInfo.id,
                          comicTitle: normalComicInfo.title,
                        ),
                      );
                    } else {
                      commonDialog(context, '禁止评论', '该漫画禁止评论');
                    }
                  } else {
                    var temp = comicInfo as JmComicInfoJson;
                    context.pushRoute(
                      JmCommentsRoute(
                        comicId: temp.id.toString(),
                        comicTitle: temp.name,
                      ),
                    );
                  }
                },
                child: const Icon(Icons.comment_sharp, size: 24.0),
              ),
              const SizedBox(height: 2),
              Text('${normalComicInfo.totalComments}'),
            ],
          ),
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  toggleAction('favorite');
                },
                child: Icon(
                  isCollected ? Icons.star : Icons.star_border,
                  color: isCollected ? Colors.yellow : context.textColor,
                  size: 24.0,
                ),
              ),
              const SizedBox(height: 2),
              const Text('收藏'),
            ],
          ),
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  if (widget.from == From.bika) {
                    var temp = comicInfo as AllInfo;
                    context.pushRoute(
                      DownloadRoute(
                        comicInfo: temp.comicInfo,
                        epsInfo: temp.eps,
                      ),
                    );
                  } else {
                    var temp = comicInfo as JmComicInfoJson;
                    context.pushRoute(JmDownloadRoute(jmComicInfoJson: temp));
                  }
                },
                child: const Icon(Icons.cloud_download_outlined, size: 24.0),
              ),
              const SizedBox(height: 2),
              const Text('下载'),
            ],
          ),
        ],
      ),
    );
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
        result = likeComic(normalComicInfo.id);
        isCurrentlyActive = isLiked;
        actionVerb = '点赞';
        break;
      case 'favorite':
        result = favouriteComic(normalComicInfo.id);
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
        result = jm.like(normalComicInfo.id.toString());
        isCurrentlyActive = isLiked;
        actionVerb = '点赞';
        break;
      case 'favorite':
        final text = isCollected ? '取消收藏' : '收藏';
        showInfoToast("$text中...");
        await handleCollectLogic(
          context,
          comicInfo as JmComicInfoJson,
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

  Future<String> jmCollect(JmComicInfoJson comicInfo) async {
    final data = await jm.favorite(comicInfo.id.toString());
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
    JmComicInfoJson comicInfo,
    FolderList folderList,
  ) async {
    final data = await jm.favoriteMoveFolder(
      comicInfo.id.toString(),
      folderList.fid.toString(),
      folderList.name,
    );
    return data['msg'];
  }

  Future<void> handleCollectLogic(
    BuildContext context,
    JmComicInfoJson comicInfo,
    bool currentStatus,
  ) async {
    // 1. 如果已经收藏，执行“取消收藏”
    if (currentStatus) {
      final msg = await _safeExecute(
        context,
        () => jmCollect(comicInfo),
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
        _safeExecute(context, () => jmCollect(comicInfo), title: "收藏操作").then((
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
          () => addFolder(comicInfo, selectedFolder),
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
