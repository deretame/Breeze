import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/config/global.dart';
import 'package:zephyr/main.dart';

import '../../../../../json/comic/comic_info.dart';
import '../../../../../network/http/http_request.dart';
import '../../../../../util/dialog.dart';

class ComicOperationWidget extends StatefulWidget {
  final ComicInfo comicInfo;

  const ComicOperationWidget({super.key, required this.comicInfo});

  @override
  State<ComicOperationWidget> createState() => _ComicOperationWidgetState();
}

class _ComicOperationWidgetState extends State<ComicOperationWidget> {
  ComicInfo get comicInfo => widget.comicInfo;
  bool isCollected = false;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    isCollected = comicInfo.comic.isFavourite;
    isLiked = comicInfo.comic.isLiked;
  }

  void toggleAction(String actionType) {
    late Future<Map<String, dynamic>> result;
    late bool isCurrentlyActive;
    late String actionVerb;
    late String successMessage;
    late String failureMessage;

    switch (actionType) {
      case 'like':
        result = like(comicInfo.comic.id);
        isCurrentlyActive = isLiked;
        actionVerb = '点赞';
        break;
      case 'favorite':
        result = collect(comicInfo.comic.id);
        isCurrentlyActive = isCollected;
        actionVerb = '收藏';
        break;
      default:
        throw ArgumentError('Invalid action type: $actionType');
    }

    CherryToast.info(
      description: Text(
          isCurrentlyActive ? '正在取消$actionVerb...' : '正在$actionVerb...',
          style: TextStyle(color: globalSetting.textColor)),
      animationType: AnimationType.fromTop,
      animationDuration: const Duration(milliseconds: 3000),
      autoDismiss: true,
      backgroundColor: globalSetting.backgroundColor,
    ).show(context);

    result.then((Map<String, dynamic> data) {
      if (data["error"] != null) {
        debugPrint('$actionVerb失败: $data');
        if (!mounted) return;
        failureMessage = actionType == 'like'
            ? "请求失败: ${data["error"]}"
            : (isCurrentlyActive ? '取消$actionVerb失败' : '$actionVerb失败');
        CherryToast.error(
          description: Text(failureMessage,
              style: TextStyle(color: globalSetting.textColor)),
          animationType: AnimationType.fromTop,
          animationDuration: const Duration(milliseconds: 3000),
          autoDismiss: true,
          backgroundColor: globalSetting.backgroundColor,
        ).show(context);
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
        CherryToast.success(
          description: Text(successMessage,
              style: TextStyle(color: globalSetting.textColor)),
          animationType: AnimationType.fromTop,
          animationDuration: const Duration(milliseconds: 3000),
          autoDismiss: true,
          backgroundColor: globalSetting.backgroundColor,
        ).show(context);
      }
    }).catchError((error) {
      if (!mounted) return;
      CherryToast.error(
        description:
            Text('请求过程中发生错误', style: TextStyle(color: globalSetting.textColor)),
        animationType: AnimationType.fromTop,
        animationDuration: const Duration(milliseconds: 3000),
        autoDismiss: true,
        backgroundColor: globalSetting.backgroundColor,
      ).show(context);
    });
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
                '${comicInfo.comic.viewsCount}',
              ),
            ],
          ),
          Column(
            children: <Widget>[
              InkWell(
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
                '${comicInfo.comic.totalLikes}',
              ),
            ],
          ),
          Column(
            children: <Widget>[
              InkWell(
                onTap: () {
                  nothingDialog(context);
                },
                child: const Icon(
                  Icons.comment_sharp,
                  // color: Colors.red,
                  size: 24.0, // 设置图标大小
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${comicInfo.comic.commentsCount}',
                // style: TextStyle(color: textColor),
              ),
            ],
          ),
          Column(
            children: <Widget>[
              InkWell(
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
              InkWell(
                onTap: () {
                  nothingDialog(context);
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
}
