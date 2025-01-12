import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:uuid/uuid.dart';

import '../../../config/global.dart';
import '../../../main.dart';
import '../../../mobx/int_select.dart';
import '../../../network/http/http_request.dart';
import '../../../util/router/router.gr.dart';
import '../../../widgets/full_screen_image_view.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../../comments/json/comments_json/comments_json.dart' as comments_json;
import '../json/user_comments_json.dart';

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
  final likeCountStore = IntSelectStore();
  bool like = false;
  var userInfo = globalBikaProfile.data.user;

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
                  onTap: () {
                    _goToComment();
                  },
                  onLongPress: () async {
                    var result = await showConfirmationDialog();
                    debugPrint(result.toString());
                    if (result) {
                      try {
                        await reportComments(commentInfo.id);
                        EasyLoading.showSuccess("举报成功");
                      } catch (e) {
                        EasyLoading.showError("举报失败：${e.toString()}");
                        debugPrint(e.toString());
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
                              url: userInfo.avatar.fileServer,
                              path: userInfo.avatar.path,
                              cartoonId: userInfo.id,
                              pictureType: "creator",
                              chapterId: commentInfo.id,
                              from: "bika",
                            ),
                          ),
                          SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(userInfo.name),
                                Text(
                                  "level:${userInfo.level} (${userInfo.title})",
                                  style: TextStyle(
                                    color: globalSetting.themeType
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
                      SizedBox(height: 3),
                      Row(
                        children: [
                          SizedBox(width: 70),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                AutoRouter.of(context).push(
                                  ComicInfoRoute(
                                    comicId: commentInfo.comic.id,
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: primaryColor, // 背景颜色
                                  borderRadius:
                                      BorderRadius.circular(5.0), // 圆角
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(5),
                                  child: Text(
                                    commentInfo.comic.title.toString(),
                                    style: TextStyle(color: primaryTextStyle),
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
                    width: screenWidth * (48 / 50), // 设置宽度
                    child: Divider(
                      color: globalSetting.themeType
                          ? Colors.grey.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.5),
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
    // 加上8个小时
    DateTime newDateTime = originalTime.add(const Duration(hours: 8));

    // 按照指定格式输出
    String formattedTime =
        '${newDateTime.year}年${newDateTime.month}月${newDateTime.day}日 ${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}:${newDateTime.second.toString().padLeft(2, '0')}';

    return formattedTime;
  }

  Future<bool> showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('举报评论'),
              content: Text('你确定要举报此评论吗？\n${commentInfo.content}'),
              actions: <Widget>[
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
                TextButton(
                  child: Text('取消'),
                  onPressed: () {
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
      await likeComment(commentId);
      like = !like;
      if (like) {
        EasyLoading.showSuccess("点赞成功");
        likeCountStore.setDate(likeCountStore.date + 1);
      } else {
        EasyLoading.showSuccess("取消点赞成功");
        likeCountStore.setDate(likeCountStore.date - 1);
      }
    } catch (e) {
      EasyLoading.showError("点赞失败：${e.toString()}");
      debugPrint(e.toString());
    }
  }

  void _goToComment() {
    AutoRouter.of(context).push(
      CommentsChildrenRoute(
        fatherDoc: comments_json.Doc(
          id: commentInfo.id,
          content: commentInfo.content,
          user: comments_json.User(
              id: userInfo.id,
              name: userInfo.name,
              level: userInfo.level,
              title: userInfo.title,
              avatar: comments_json.Avatar(
                  fileServer: userInfo.avatar.fileServer,
                  path: userInfo.avatar.path,
                  originalName: userInfo.avatar.originalName),
              character: userInfo.character,
              gender: userInfo.gender,
              verified: userInfo.verified,
              exp: userInfo.exp,
              role: userInfo.role,
              characters: userInfo.characters),
          comic: commentInfo.comic.id,
          totalComments: commentInfo.totalComments,
          isTop: false,
          hide: commentInfo.hide,
          createdAt: commentInfo.createdAt,
          docId: commentInfo.id,
          likesCount: commentInfo.likesCount,
          commentsCount: commentInfo.commentsCount,
          isLiked: commentInfo.isLiked,
        ),
      ),
    );
  }
}

class ImagerWidget extends StatefulWidget {
  final PictureInfo pictureInfo;

  const ImagerWidget({
    super.key,
    required this.pictureInfo,
  });

  @override
  State<ImagerWidget> createState() => _ImagerWidgetState();
}

class _ImagerWidgetState extends State<ImagerWidget> {
  PictureInfo get pictureInfo => widget.pictureInfo;

  @override
  Widget build(BuildContext context) {
    var uuid = Uuid().v4();
    return SizedBox(
      height: 60,
      width: 60,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: BlocProvider(
          create: (context) => PictureBloc()
            ..add(
              GetPicture(
                PictureInfo(
                  from: "bika",
                  url: pictureInfo.url,
                  path: pictureInfo.path,
                  cartoonId: pictureInfo.cartoonId,
                  pictureType: pictureInfo.pictureType,
                ),
              ),
            ),
          child: BlocBuilder<PictureBloc, PictureLoadState>(
            builder: (context, state) {
              switch (state.status) {
                case PictureLoadStatus.initial:
                  return Center(
                    child: LoadingAnimationWidget.waveDots(
                      color: globalSetting.textColor,
                      size: 25,
                    ),
                  );
                case PictureLoadStatus.success:
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImageView(
                            imagePath: state.imagePath!,
                            uuid: uuid,
                          ),
                        ),
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
                              GetPicture(
                                PictureInfo(
                                  from: "bika",
                                  url: pictureInfo.url,
                                  path: pictureInfo.path,
                                  cartoonId: pictureInfo.cartoonId,
                                  pictureType: pictureInfo.pictureType,
                                ),
                              ),
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
