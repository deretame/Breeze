import 'package:flutter/material.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../../config/global/global.dart';
import '../../../../main.dart';
import '../json/jm_comic_info/jm_comic_info_json.dart';

class ComicOperationWidget extends StatefulWidget {
  final JmComicInfoJson comicInfo;

  const ComicOperationWidget({super.key, required this.comicInfo});

  @override
  State<ComicOperationWidget> createState() => _ComicOperationWidgetState();
}

class _ComicOperationWidgetState extends State<ComicOperationWidget> {
  JmComicInfoJson get comicInfo => widget.comicInfo;
  bool isCollected = false;
  bool isLiked = false;

  @override
  void initState() {
    super.initState();
    isCollected = comicInfo.isFavorite;
    isLiked = comicInfo.liked;
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
              Text(comicInfo.totalViews),
            ],
          ),
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: () async {
                  showErrorToast('暂不支持');
                  return;
                  toggleAction('like');
                },
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : globalSetting.textColor,
                  size: 24.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(comicInfo.likes),
            ],
          ),
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  showErrorToast('暂不支持');
                  return;
                },
                child: const Icon(
                  Icons.comment_sharp,
                  // color: Colors.red,
                  size: 24.0, // 设置图标大小
                ),
              ),
              const SizedBox(height: 2),
              Text(
                comicInfo.commentTotal,
                // style: TextStyle(color: textColor),
              ),
            ],
          ),
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: () {
                  showErrorToast('暂不支持');
                  return;
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
                  showErrorToast('暂不支持');
                  return;
                },
                child: const Icon(
                  Icons.cloud_download_outlined,
                  // color: Colors.red,
                  size: 24.0, // 设置图标大小
                ),
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
    // late Future<Map<String, dynamic>> result;
    // late bool isCurrentlyActive;
    // late String actionVerb;
    // late String successMessage;
    // late String failureMessage;
    //
    // switch (actionType) {
    //   case 'like':
    //     result = likeComic(comicInfo.id);
    //     isCurrentlyActive = isLiked;
    //     actionVerb = '点赞';
    //     break;
    //   case 'favorite':
    //     result = favouriteComic(comicInfo.id);
    //     isCurrentlyActive = isCollected;
    //     actionVerb = '收藏';
    //     break;
    //   default:
    //     throw ArgumentError('Invalid action type: $actionType');
    // }
    //
    // showInfoToast("请求中...");
    //
    // try {
    //   final data = await result;
    //
    //   if (data["error"] != null) {
    //     logger.d('$actionVerb失败: $data');
    //     if (!mounted) return;
    //     failureMessage =
    //         actionType == 'like'
    //             ? "请求失败: ${data["error"]}"
    //             : (isCurrentlyActive ? '取消$actionVerb失败' : '$actionVerb失败');
    //     showErrorToast(failureMessage, duration: const Duration(seconds: 5));
    //   } else {
    //     logger.d('$actionVerb成功: $data');
    //     if (mounted) {
    //       setState(() {
    //         if (actionType == 'like') {
    //           isLiked = !isLiked;
    //         } else {
    //           isCollected = !isCollected;
    //         }
    //       });
    //     }
    //
    //     if (!mounted) return;
    //     successMessage =
    //         isCurrentlyActive ? '取消$actionVerb成功' : '$actionVerb成功';
    //     showSuccessToast(successMessage);
    //   }
    // } catch (error) {
    //   if (!mounted) return;
    //   showErrorToast(
    //     "请求过程中发生错误: ${error.toString()}",
    //     duration: const Duration(seconds: 5),
    //   );
    // }
  }
}
