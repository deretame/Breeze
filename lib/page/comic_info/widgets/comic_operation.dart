import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../../config/global.dart';
import '../../../main.dart';
import '../../../network/http/http_request.dart';
import '../../../util/dialog.dart';
import '../../main.dart';
import '../json/comic_info/comic_info.dart';
import '../json/eps/eps.dart';

class ComicOperationWidget extends StatefulWidget {
  final Comic comicInfo;
  final List<Doc> epsInfo;

  const ComicOperationWidget({
    super.key,
    required this.comicInfo,
    required this.epsInfo,
  });

  @override
  State<ComicOperationWidget> createState() => _ComicOperationWidgetState();
}

class _ComicOperationWidgetState extends State<ComicOperationWidget> {
  Comic get comicInfo => widget.comicInfo;
  bool isCollected = false;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    isCollected = comicInfo.isFavourite;
    isLiked = comicInfo.isLiked;
  }

  @override
  Widget build(BuildContext context) {
    return LimitedBox(
      maxWidth: screenWidth * (48 / 50),
      maxHeight: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Column(
            children: <Widget>[
              const Icon(
                Icons.remove_red_eye,
                // color: Colors.red,
                size: 24.0, // 设置图标大小
              ),
              const SizedBox(height: 2),
              Text(
                '${comicInfo.viewsCount}',
              ),
            ],
          ),
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  toggleAction('like');
                },
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : globalSetting.textColor,
                  size: 24.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${comicInfo.totalLikes}',
              ),
            ],
          ),
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  if (comicInfo.allowComment) {
                    AutoRouter.of(context).push(
                      CommentsRoute(
                        comicId: comicInfo.id,
                        comicTitle: comicInfo.title,
                      ),
                    );
                  } else {
                    commonDialog(context, '禁止评论', '该漫画禁止评论');
                  }
                },
                child: const Icon(
                  Icons.comment_sharp,
                  // color: Colors.red,
                  size: 24.0, // 设置图标大小
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${comicInfo.commentsCount}',
                // style: TextStyle(color: textColor),
              ),
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
                  color: isCollected ? Colors.yellow : globalSetting.textColor,
                  size: 24.0, // 设置图标大小
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '收藏',
                // style: TextStyle(color: textColor),
              ),
            ],
          ),
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  if (widget.epsInfo.isNotEmpty) {
                    AutoRouter.of(context).push(
                      DownloadRoute(
                        comicInfo: comicInfo,
                        epsInfo: widget.epsInfo,
                      ),
                    );
                  } else {
                    commonDialog(context, '暂无章节信息', '请等待章节信息加载完成后再试');
                  }
                },
                child: const Icon(
                  Icons.cloud_download_outlined,
                  // color: Colors.red,
                  size: 24.0, // 设置图标大小
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                '下载',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void toggleAction(String actionType) {
    late Future<Map<String, dynamic>> result;
    late bool isCurrentlyActive;
    late String actionVerb;
    late String successMessage;
    late String failureMessage;

    switch (actionType) {
      case 'like':
        result = likeComic(comicInfo.id);
        isCurrentlyActive = isLiked;
        actionVerb = '点赞';
        break;
      case 'favorite':
        result = favouriteComic(comicInfo.id);
        isCurrentlyActive = isCollected;
        actionVerb = '收藏';
        break;
      default:
        throw ArgumentError('Invalid action type: $actionType');
    }

    eventBus.fire(ToastMessage(ToastType.info, "请求中..."));

    result.then((Map<String, dynamic> data) {
      if (data["error"] != null) {
        debugPrint('$actionVerb失败: $data');
        if (!mounted) return;
        failureMessage = actionType == 'like'
            ? "请求失败: ${data["error"]}"
            : (isCurrentlyActive ? '取消$actionVerb失败' : '$actionVerb失败');
        eventBus.fire(ToastMessage(ToastType.error, failureMessage));
      } else {
        debugPrint('$actionVerb成功: $data');
        setState(() {
          if (actionType == 'like') {
            isLiked = !isLiked;
          } else {
            isCollected = !isCollected;
          }
        });

        if (!mounted) return;
        successMessage =
            isCurrentlyActive ? '取消$actionVerb成功' : '$actionVerb成功';
        eventBus.fire(ToastMessage(ToastType.success, successMessage));
      }
    }).catchError((error) {
      if (!mounted) return;
      eventBus.fire(
        ToastMessage(ToastType.error, "请求过程中发生错误\n${error.toString()}"),
      );
    });
  }
}
