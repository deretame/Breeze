import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/network/http/jm/http_request.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/event/event.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../../config/global/global.dart';
import '../../../../main.dart';
import '../json/jm_comic_info_json.dart';

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

    var data =
        objectbox.jmFavoriteBox
            .query(JmFavorite_.comicId.equals(comicInfo.id.toString()))
            .build()
            .findFirst();
    isCollected = data?.deleted == false;
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
                  if (isLiked) {
                    showInfoToast("已点赞");
                    return;
                  }
                  if (jmSetting.userInfo.isEmpty) {
                    if (jmSetting.account.isEmpty) {
                      showInfoToast("请先登录");
                      eventBus.fire(NeedLogin(from: From.jm));
                      return;
                    }
                    showInfoToast("请等待登录完毕");
                    return;
                  }
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
                  context.pushRoute(
                    JmCommentsRoute(
                      comicId: comicInfo.id.toString(),
                      comicTitle: comicInfo.name,
                    ),
                  );
                },
                child: const Icon(
                  Icons.comment_sharp,
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
                  context.pushRoute(
                    JmDownloadRoute(jmComicInfoJson: comicInfo),
                  );
                },
                child: const Icon(
                  Icons.cloud_download_outlined,
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
    late Future<Map<String, dynamic>> result;
    late bool isCurrentlyActive;
    late String actionVerb;
    late String successMessage;
    late String failureMessage;

    switch (actionType) {
      case 'like':
        result = like(comicInfo.id.toString());
        isCurrentlyActive = isLiked;
        actionVerb = '点赞';
        break;
      case 'favorite':
        result = collect(comicInfo, isCollected);
        isCurrentlyActive = isCollected;
        actionVerb = '收藏';
        break;
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
        failureMessage =
            actionType == 'like'
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
        successMessage =
            isCurrentlyActive ? '取消$actionVerb成功' : '$actionVerb成功';
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

  Future<Map<String, dynamic>> collect(
    JmComicInfoJson comicInfo,
    bool isCollected,
  ) async {
    // 避免数据冲突
    var data =
        objectbox.jmFavoriteBox
            .query(JmFavorite_.comicId.equals(comicInfo.id.toString()))
            .build()
            .find();

    for (var item in data) {
      objectbox.jmFavoriteBox.remove(item.id);
    }

    objectbox.jmFavoriteBox.put(
      JmFavorite(
        comicId: comicInfo.id.toString(),
        name: comicInfo.name,
        addtime: comicInfo.addtime,
        description: comicInfo.description,
        totalViews: comicInfo.totalViews,
        likes: comicInfo.likes,
        seriesId: comicInfo.seriesId,
        commentTotal: comicInfo.commentTotal,
        author: comicInfo.author,
        tags: comicInfo.tags,
        works: comicInfo.works,
        actors: comicInfo.actors,
        liked: comicInfo.liked,
        isFavorite: comicInfo.isFavorite,
        isAids: comicInfo.isAids,
        price: comicInfo.price,
        purchased: comicInfo.purchased,
        deleted: isCollected,
        history: DateTime.now().toUtc(),
      ),
    );

    return {"error": null, "message": "收藏成功"};
  }
}
