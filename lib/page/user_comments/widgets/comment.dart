import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/toast.dart';

import '../../../config/global/global.dart';
import '../../../main.dart';
import '../../../cubit/bool_select.dart';
import '../../../cubit/int_select.dart';
import '../../../network/http/bika/http_request.dart';
import '../../../type/enum.dart';
import '../../../util/router/router.gr.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../../comments/json/comments_json/comments_json.dart' as comments_json;
import '../json/user_comments_json.dart';

class CommentsWidget extends StatelessWidget {
  final Doc doc;
  final int index;

  const CommentsWidget({super.key, required this.doc, required this.index});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => IntSelectCubit()..setDate(doc.likesCount)),
        BlocProvider(create: (_) => BoolSelectCubit()..setDate(doc.isLiked)),
      ],
      child: _CommentsWidgetContent(doc: doc, index: index),
    );
  }
}

class _CommentsWidgetContent extends StatelessWidget {
  final Doc doc;
  final int index;

  const _CommentsWidgetContent({required this.doc, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final isLiked = context.watch<BoolSelectCubit>().state;
    final likeCount = context.watch<IntSelectCubit>().state;
    final userInfo = globalBikaProfile.data.user;

    return Center(
      child: SizedBox(
        width: context.screenWidth * (48 / 50),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                _goToComment(context);
              },
              onLongPress: () async {
                var result = await showConfirmationDialog(context, doc: doc);
                logger.d(result.toString());
                if (result) {
                  try {
                    await reportComments(doc.id);
                    showSuccessToast("举报成功");
                  } catch (e) {
                    showErrorToast(
                      "举报失败：${e.toString()}",
                      duration: Duration(seconds: 5),
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
                        key: ValueKey(doc.toString()),
                        pictureInfo: PictureInfo(
                          url: userInfo.avatar.fileServer,
                          path: userInfo.avatar.path,
                          cartoonId: userInfo.id,
                          pictureType: "creator",
                          chapterId: doc.id,
                          from: "bika",
                        ),
                      ),
                      SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(userInfo.name),
                            Text(
                              "level:${userInfo.level} (${userInfo.title})",
                              style: TextStyle(
                                color: theme.colorScheme.tertiary,
                              ),
                            ),
                            SelectableText(
                              doc.content,
                              style: TextStyle(color: context.textColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3),
                  Row(
                    children: [
                      SizedBox(width: 70),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            context.pushRoute(
                              ComicInfoRoute(
                                comicId: doc.comic.id,
                                type: ComicEntryType.normal,
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onInverseSurface,
                              // 背景颜色
                              borderRadius: BorderRadius.circular(5.0), // 圆角
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(
                                doc.comic.title.toString(),
                                style: TextStyle(
                                  color: theme.colorScheme.surfaceTint,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Center(
                    child: Row(
                      children: [
                        Text(
                          index.toString(),
                          style: TextStyle(
                            fontFamily: "Courgette-Regular",
                            // fontStyle: FontStyle.italic,
                            // fontSize: 16,
                          ),
                        ),
                        Text(" / "),
                        Text(timeDecode(doc.createdAt)),
                        Spacer(),
                        GestureDetector(
                          onTap: () {
                            _likeComment(context, doc.id);
                          },
                          child: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: isLiked ? Colors.red : context.textColor,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(likeCount.toString()),
                        SizedBox(width: 5),
                        Icon(Icons.comment, size: 14),
                        SizedBox(width: 5),
                        Text(doc.commentsCount.toString()),
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

  Future<bool> showConfirmationDialog(
    BuildContext context, {
    required Doc doc,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('举报评论'),
              content: Text('你确定要举报此评论吗？\n${doc.content}'),
              actions: <Widget>[
                TextButton(
                  child: Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false; // 如果用户直接关闭对话框，返回 false
  }

  void _likeComment(BuildContext context, String commentId) async {
    // 7. 使用 context.read 获取局部的 Cubits
    final likeCubit = context.read<BoolSelectCubit>();
    final likeCountCubit = context.read<IntSelectCubit>();
    // 获取当前状态
    final bool currentLike = likeCubit.state;
    final int currentCount = likeCountCubit.state;

    try {
      if (currentLike) {
        showSuccessToast("正在取消点赞");
      } else {
        showSuccessToast("正在点赞");
      }
      await likeComment(commentId);

      // 计算新状态
      final bool newLike = !currentLike;
      final int newCount = currentLike ? currentCount - 1 : currentCount + 1;

      // 更新状态
      likeCubit.setDate(newLike);
      likeCountCubit.setDate(newCount);

      if (newLike) {
        showSuccessToast("点赞成功");
      } else {
        showSuccessToast("取消点赞成功");
      }
    } catch (e) {
      showErrorToast("点赞/取消失败：${e.toString()}", duration: Duration(seconds: 5));
      logger.e(e.toString());
      // 失败时回滚状态
      likeCubit.setDate(currentLike);
      likeCountCubit.setDate(currentCount);
    }
  }

  void _goToComment(BuildContext context) {
    final userInfo = globalBikaProfile.data.user;
    AutoRouter.of(context).push(
      CommentsChildrenRoute(
        fatherDoc: comments_json.Doc(
          id: doc.id,
          content: doc.content,
          user: comments_json.User(
            id: userInfo.id,
            name: userInfo.name,
            level: userInfo.level,
            title: userInfo.title,
            avatar: comments_json.Avatar(
              fileServer: userInfo.avatar.fileServer,
              path: userInfo.avatar.path,
              originalName: userInfo.avatar.originalName,
            ),
            character: userInfo.character,
            gender: userInfo.gender,
            verified: userInfo.verified,
            exp: userInfo.exp,
            role: userInfo.role,
            characters: userInfo.characters,
          ),
          comic: doc.comic.id,
          totalComments: doc.totalComments,
          isTop: false,
          hide: doc.hide,
          createdAt: doc.createdAt,
          docId: doc.id,
          likesCount: doc.likesCount,
          commentsCount: doc.commentsCount,
          isLiked: doc.isLiked,
        ),
        boolSelectCubit: context.read<BoolSelectCubit>(),
        intSelectCubit: context.read<IntSelectCubit>(),
      ),
    );
  }
}

class ImagerWidget extends StatefulWidget {
  final PictureInfo pictureInfo;

  const ImagerWidget({super.key, required this.pictureInfo});

  @override
  State<ImagerWidget> createState() => _ImagerWidgetState();
}

class _ImagerWidgetState extends State<ImagerWidget> {
  PictureInfo get pictureInfo => widget.pictureInfo;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    var uuid = Uuid().v4();
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
                      color: theme.colorScheme.primaryFixedDim,
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
                    child: Hero(
                      tag: state.imagePath! + uuid,
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
