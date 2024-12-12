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
import '../json/comments_json/comments_json.dart';

class CommentsWidget extends StatefulWidget {
  final Doc doc;
  final int index;

  const CommentsWidget({super.key, required this.doc, required this.index});

  @override
  State<CommentsWidget> createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  Doc get commentInfo => widget.doc;

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
    return InkWell(
      // onTap: () {
      //   AutoRouter.of(context).push(
      //     SearchResultRoute(
      //       searchEnterConst: SearchEnterConst(
      //         from: "bika",
      //         url:
      //             "https://picaapi.picacomic.com/comics?ca=${comicInfo.creator.id}&s=ld&page=1",
      //         type: "creator",
      //         keyword: comicInfo.creator.name,
      //       ),
      //     ),
      //   );
      // },
      child: Observer(
        builder: (context) {
          return Center(
            child: SizedBox(
              width: screenWidth * (48 / 50),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
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
                      Flexible(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(commentInfo.user.name),
                            Text(
                              "level:${commentInfo.user.level} (${commentInfo.user.title})",
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
                          child: Icon(
                            like ? Icons.favorite : Icons.favorite_border,
                            size: 14,
                            color: like ? Colors.red : globalSetting.textColor,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(likeCountStore.date.toString()),
                        SizedBox(width: 10),
                        Icon(
                          Icons.comment_sharp,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(commentInfo.totalComments.toString())
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: screenWidth * (48 / 50), // 设置宽度
                      child: Divider(
                        color: globalSetting.themeType
                            ? Colors.grey.withOpacity(0.5)
                            : Colors.white.withOpacity(0.5),
                        thickness: 1,
                        height: 10,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
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
      height: 75,
      width: 75,
      child: Padding(
        padding: const EdgeInsets.all(10),
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
                  if (state.imagePath.toString().contains('404')) {
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
                  }
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
