import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../../config/global/global.dart';
import '../../../main.dart';
import '../../../mobx/int_select.dart';
import '../../../network/http/bika/http_request.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../../../widgets/toast.dart';
import '../json/comments_children_json.dart' as comments_children_json;

class CommentsChildrenWidget extends StatefulWidget {
  final comments_children_json.Doc doc;

  final int index;

  const CommentsChildrenWidget({
    super.key,
    required this.doc,
    required this.index,
  });

  @override
  State<CommentsChildrenWidget> createState() => _CommentsChildrenWidgetState();
}

class _CommentsChildrenWidgetState extends State<CommentsChildrenWidget>
    with SingleTickerProviderStateMixin {
  comments_children_json.Doc get commentInfo => widget.doc;

  int get index => widget.index;

  final likeCountStore = IntSelectStore();
  bool like = false;

  @override
  void initState() {
    super.initState();
    likeCountStore.setDate(commentInfo.likesCount);
    like = commentInfo.isLiked;
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return Center(
          child: SizedBox(
            width: screenWidth * (48 / 50),
            child: Column(
              children: [
                InkWell(
                  onLongPress: () async {
                    var result = await showConfirmationDialog();
                    logger.d(result.toString());
                    if (result) {
                      try {
                        showInfoToast("正在举报");
                        await reportComments(commentInfo.id);
                        showSuccessToast("举报成功");
                      } catch (e) {
                        showErrorToast(
                          "举报失败：${e.toString()}",
                          duration: const Duration(seconds: 5),
                        );
                        logger.e(e.toString());
                      }
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start, // 横向居左
                        crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
                        children: [
                          Builder(
                            builder: (context) {
                              return ImagerWidget(
                                key: ValueKey(commentInfo.id),
                                pictureInfo: PictureInfo(
                                  url: commentInfo.user.avatar!.fileServer,
                                  path: commentInfo.user.avatar!.path,
                                  cartoonId: commentInfo.user.id,
                                  pictureType: "creator",
                                  chapterId: commentInfo.id,
                                  from: "bika",
                                ),
                                commentId: commentInfo.id,
                              );
                            },
                          ),
                          SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(commentInfo.user.name),
                                Text(
                                  "level:${commentInfo.user.level} (${commentInfo.user.title})",
                                  style: TextStyle(
                                    color:
                                        globalSetting.themeType
                                            ? Colors.red
                                            : Colors.yellow,
                                  ),
                                ),
                                Text(
                                  commentInfo.content,
                                  style: TextStyle(
                                    color: globalSetting.textColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            index.toString(),
                            style: TextStyle(
                              fontFamily: "LeckerliOne-Regular",
                              // fontSize: 14,
                            ),
                          ),
                          Text(" / "),
                          Text(timeDecode(commentInfo.createdAt)),
                          Spacer(),
                          GestureDetector(
                            onTap: () {
                              _likeComment(commentInfo.id);
                            },
                            child: Icon(
                              like ? Icons.favorite : Icons.favorite_border,
                              size: 14,
                              color:
                                  like ? Colors.red : globalSetting.textColor,
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(likeCountStore.date.toString()),
                        ],
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: screenWidth * (48 / 50), // 设置宽度
                    child: Divider(
                      color: materialColorScheme.secondaryFixedDim,
                      thickness: 1,
                      height: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String timeDecode(DateTime originalTime) {
    // 获取当前设备的时区偏移量
    Duration timeZoneOffset = DateTime.now().timeZoneOffset;

    // 根据时区偏移量调整时间
    DateTime newDateTime = originalTime.add(timeZoneOffset);

    // 按照指定格式输出
    String formattedTime =
        '${newDateTime.year}年${newDateTime.month}月${newDateTime.day}日 '
        '${newDateTime.hour.toString().padLeft(2, '0')}:'
        '${newDateTime.minute.toString().padLeft(2, '0')}:'
        '${newDateTime.second.toString().padLeft(2, '0')}';

    return formattedTime;
  }

  Future<bool> showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('选择操作'),
              content: SelectableText(commentInfo.content),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text('举报'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                TextButton(
                  child: Text('复制评论'),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: commentInfo.content));
                    showSuccessToast("复制成功");
                    Navigator.of(context).pop(false);
                  },
                ),
              ],
            );
          },
        ) ??
        false; // 如果用户直接关闭对话框，返回 false
  }

  void _likeComment(String commentId) async {
    try {
      if (like) {
        showInfoToast("正在取消点赞");
      } else {
        showInfoToast("正在点赞");
      }
      await likeComment(commentId);
      like = !like;
      if (like) {
        showSuccessToast("点赞成功");
        likeCountStore.setDate(likeCountStore.date + 1);
      } else {
        showSuccessToast("取消点赞成功");
        likeCountStore.setDate(likeCountStore.date - 1);
      }
    } catch (e) {
      showErrorToast(
        "点赞失败：${e.toString()}",
        duration: const Duration(seconds: 5),
      );
      logger.e(e.toString());
    }
  }
}

class ImagerWidget extends StatelessWidget {
  final PictureInfo pictureInfo;
  final String commentId;

  const ImagerWidget({
    super.key,
    required this.pictureInfo,
    required this.commentId,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 60,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: BlocProvider(
          create: (context) => PictureBloc()..add(GetPicture(pictureInfo)),
          child: BlocBuilder<PictureBloc, PictureLoadState>(
            builder: (context, state) {
              switch (state.status) {
                case PictureLoadStatus.initial:
                  return Center(
                    child: LoadingAnimationWidget.waveDots(
                      color: materialColorScheme.primaryFixedDim,
                      size: 25,
                    ),
                  );
                case PictureLoadStatus.success:
                  return GestureDetector(
                    onTap: () {
                      context.pushRoute(
                        FullRouteImageRoute(imagePath: state.imagePath!),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.file(
                          File(state.imagePath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                case PictureLoadStatus.failure:
                  if (state.result.toString().contains('404')) {
                    // return SizedBox.shrink();
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.asset(
                          'asset/image/error_image/404.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  } else {
                    return InkWell(
                      onTap: () {
                        context.read<PictureBloc>().add(
                          GetPicture(pictureInfo),
                        );
                      },
                      child: Icon(Icons.refresh),
                    );
                  }
              }
            },
          ),
        ),
      ),
    );
  }
}
