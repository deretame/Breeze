import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../main.dart';
import '../../../cubit/bool_select.dart';
import '../../../cubit/int_select.dart';
import '../../../network/http/bika/http_request.dart';
import '../../../util/router/router.gr.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../../../widgets/toast.dart';
import '../json/comments_json/comments_json.dart';

class CommentsWidget extends StatefulWidget {
  final Doc doc;
  final int index;

  const CommentsWidget({super.key, required this.doc, required this.index});

  @override
  State<CommentsWidget> createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget>
    with SingleTickerProviderStateMixin {
  Doc get commentInfo => widget.doc;
  int get index => widget.index;

  final IntSelectCubit likeCountCubit = IntSelectCubit();
  final BoolSelectCubit likeCubit = BoolSelectCubit();

  @override
  void initState() {
    super.initState();
    likeCountCubit.setDate(commentInfo.likesCount);
    likeCubit.setDate(commentInfo.isLiked);
  }

  @override
  void dispose() {
    likeCountCubit.close();
    likeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: likeCubit),
        BlocProvider.value(value: likeCountCubit),
      ],
      child: Builder(
        builder: (context) {
          return Center(
            child: SizedBox(
              width: context.screenWidth * (48 / 50),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      AutoRouter.of(context).push(
                        CommentsChildrenRoute(
                          fatherDoc: commentInfo,
                          boolSelectCubit: likeCubit,
                          intSelectCubit: likeCountCubit,
                        ),
                      );
                    },
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
                            ImagerWidget(
                              key: ValueKey(commentInfo.toString()),
                              pictureInfo: PictureInfo(
                                url: commentInfo.user.avatar!.fileServer,
                                path: commentInfo.user.avatar!.path,
                                cartoonId: commentInfo.user.id,
                                pictureType: "creator",
                                chapterId: commentInfo.id,
                                from: "bika",
                              ),
                              commentId: commentInfo.id,
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
                                      color: theme.colorScheme.tertiary,
                                    ),
                                  ),
                                  Text(
                                    commentInfo.content,
                                    style: TextStyle(color: context.textColor),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Center(
                          child: Row(
                            children: [
                              if (commentInfo.isTop) ...[
                                Text(
                                  "TOP",
                                  style: TextStyle(
                                    fontFamily: "LeckerliOne-Regular",
                                    // fontSize: 14,
                                  ),
                                ),
                              ],
                              if (!commentInfo.isTop) ...[
                                Text(
                                  index.toString(),
                                  style: TextStyle(
                                    fontFamily: "Courgette-Regular",
                                    // fontStyle: FontStyle.italic,
                                    // fontSize: 16,
                                  ),
                                ),
                              ],
                              Text(" / "),
                              Text(timeDecode(commentInfo.createdAt)),
                              Spacer(),
                              GestureDetector(
                                onTap: () {
                                  _likeComment(commentInfo.id);
                                },
                                child: BlocBuilder<BoolSelectCubit, bool>(
                                  builder: (context, isLiked) {
                                    return Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      size: 14,
                                      color: isLiked
                                          ? Colors.red
                                          : context.textColor,
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: 5),
                              BlocBuilder<IntSelectCubit, int>(
                                builder: (context, likeCount) {
                                  return Text(likeCount.toString());
                                },
                              ),
                              SizedBox(width: 5),
                              Icon(Icons.comment, size: 14),
                              SizedBox(width: 5),
                              Text(commentInfo.commentsCount.toString()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: context.screenWidth * (48 / 50), // 设置宽度
                      child: Divider(
                        color: theme.colorScheme.secondaryFixedDim,
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
      ),
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
    // 从 Cubit 中获取当前状态
    final bool currentLikeState = likeCubit.state;

    try {
      if (currentLikeState) {
        showInfoToast("正在取消点赞");
      } else {
        showInfoToast("正在点赞");
      }

      await likeComment(commentId);

      if (currentLikeState) {
        // 之前是点赞，现在取消点赞
        showSuccessToast("取消点赞成功");
        likeCountCubit.setDate(likeCountCubit.state - 1);
        likeCubit.setDate(false);
      } else {
        // 之前未点赞，现在点赞
        showSuccessToast("点赞成功");
        likeCountCubit.setDate(likeCountCubit.state + 1);
        likeCubit.setDate(true);
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

class ImagerWidget extends StatefulWidget {
  final PictureInfo pictureInfo;
  final String commentId;

  const ImagerWidget({
    super.key,
    required this.pictureInfo,
    required this.commentId,
  });

  @override
  State<ImagerWidget> createState() => _ImagerWidgetState();
}

class _ImagerWidgetState extends State<ImagerWidget> {
  PictureInfo get pictureInfo => widget.pictureInfo;

  String get commentId => widget.commentId;

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
                      color: context.theme.colorScheme.primaryFixedDim,
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
                          'asset/image/assets/default_cover.png',
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
