import 'dart:io';

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
import '../../../widgets/full_screen_image_view.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../../comments/json/comments_json/comments_json.dart' as comments_json;

class FatherCommentsWidget extends StatefulWidget {
  final comments_json.Doc doc;

  const FatherCommentsWidget({super.key, required this.doc});

  @override
  State<FatherCommentsWidget> createState() => _FatherCommentsWidgetState();
}

class _FatherCommentsWidgetState extends State<FatherCommentsWidget>
    with SingleTickerProviderStateMixin {
  comments_json.Doc get commentInfo => widget.doc;

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
            child: InkWell(
              // behavior: HitTestBehavior.opaque, // 使得所有透明区域也可以响应点击
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
                      _ImagerWidget(
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
                            SelectableText(commentInfo.user.name),
                            Text(
                              "level:${commentInfo.user.level} (${commentInfo.user.title})",
                              style: TextStyle(
                                color: materialColorScheme.tertiary,
                              ),
                            ),
                            SelectableText(
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
                  Center(
                    child: Row(
                      children: [
                        Text(
                          "TOP",
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
                            color: like ? Colors.red : globalSetting.textColor,
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
              title: Text('举报评论'),
              content: Text('你确定要举报此评论吗？\n${commentInfo.content}'),
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

  void _likeComment(String commentId) async {
    try {
      if (like) {
        EasyLoading.showSuccess("正在取消点赞");
      } else {
        EasyLoading.showSuccess("正在点赞");
      }
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
}

class _ImagerWidget extends StatelessWidget {
  final PictureInfo pictureInfo;
  final String commentId;

  const _ImagerWidget({
    required this.pictureInfo,
    required this.commentId,
  });

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
                      color: materialColorScheme.primaryFixedDim,
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
                  debugPrint(state.result);
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
