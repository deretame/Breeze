import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import '../../../config/global.dart';
import '../../../main.dart';
import '../../../network/http/http_request.dart';
import '../../../util/dialog.dart';
import '../json/comic_info/comic_info.dart';

class ComicOperationWidget extends StatefulWidget {
  final Comic comicInfo;

  const ComicOperationWidget({super.key, required this.comicInfo});

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
      child: Observer(
        builder: (context) {
          return Row(
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
                      color:
                          isCollected ? Colors.yellow : globalSetting.textColor,
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
          );
        },
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
        result = like(comicInfo.id);
        isCurrentlyActive = isLiked;
        actionVerb = '点赞';
        break;
      case 'favorite':
        result = collect(comicInfo.id);
        isCurrentlyActive = isCollected;
        actionVerb = '收藏';
        break;
      default:
        throw ArgumentError('Invalid action type: $actionType');
    }

    EasyLoading.showInfo("正在$actionVerb...");

    result.then((Map<String, dynamic> data) {
      if (data["error"] != null) {
        debugPrint('$actionVerb失败: $data');
        if (!mounted) return;
        failureMessage = actionType == 'like'
            ? "请求失败: ${data["error"]}"
            : (isCurrentlyActive ? '取消$actionVerb失败' : '$actionVerb失败');
        EasyLoading.showError(failureMessage);
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
        EasyLoading.showSuccess(successMessage);
      }
    }).catchError((error) {
      if (!mounted) return;
      EasyLoading.showError("请求过程中发生错误: $error");
    });
  }
}
