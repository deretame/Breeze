import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/network/http/jm/http_request.dart' as jm;
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/comic_info/comic_info.dart';
import 'package:zephyr/page/comic_info/json/jm/jm_comic_info_json.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
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
        result = jm.like(normalComicInfo.id.toString());
        isCurrentlyActive = isLiked;
        actionVerb = '点赞';
        break;
      case 'favorite':
        result = jmCollect(comicInfo as JmComicInfoJson, isCollected);
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

  Future<Map<String, dynamic>> jmCollect(
    JmComicInfoJson comicInfo,
    bool isCollected,
  ) async {
    // 避免数据冲突
    var data = objectbox.jmFavoriteBox
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
