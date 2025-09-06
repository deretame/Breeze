import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/jm/jm_comments/json/comments_json.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/picture_bloc/models/picture_info.dart';
import 'cover.dart';

class CommentsWidget extends StatelessWidget {
  final ListElement element;

  const CommentsWidget({super.key, required this.element});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return Center(
          child: SizedBox(
            width: context.screenWidth * (48 / 50),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    // TODO: 添加发送评论功能
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
                            pictureInfo: PictureInfo(
                              from: 'jm',
                              url: getUserCover(element.photo),
                              path: '${element.uid}.jpg',
                              cartoonId: '',
                              chapterId: '',
                              pictureType: 'user',
                            ),
                          ),
                          SizedBox(width: 10),
                          Flexible(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(element.nickname),
                                Text(
                                  "level:${element.expinfo.level} (${element.expinfo.levelName})",
                                  style: TextStyle(
                                    color: materialColorScheme.tertiary,
                                  ),
                                ),
                                SelectableText(
                                  element.content.let(stripAllHtmlTags),
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
                            Text(element.name),
                            Spacer(),
                            Text(element.addtime),
                            SizedBox(width: 5),
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
                      color: materialColorScheme.secondaryFixedDim,
                      thickness: 1,
                      height: 10,
                    ),
                  ),
                ),
                if (element.replys != null && element.replys!.isNotEmpty) ...[
                  for (var reply in element.replys!)
                    _CommentsWidget(reply: reply),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String stripAllHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

class _CommentsWidget extends StatelessWidget {
  final Reply reply;

  const _CommentsWidget({required this.reply});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return Center(
          child: SizedBox(
            width: context.screenWidth * (48 / 50),
            child: Column(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start, // 横向居左
                      crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐
                      children: [
                        SizedBox(width: 30),
                        ImagerWidget(
                          pictureInfo: PictureInfo(
                            from: 'jm',
                            url: getUserCover(reply.photo),
                            path: '${reply.uid}.jpg',
                            cartoonId: '',
                            chapterId: '',
                            pictureType: 'user',
                          ),
                        ),
                        SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SelectableText(
                                "${reply.nickname} (${reply.addtime})",
                              ),
                              Text(
                                "level:${reply.expinfo.level} (${reply.expinfo.levelName})",
                                style: TextStyle(
                                  color: materialColorScheme.tertiary,
                                ),
                              ),
                              Text(
                                reply.content.let(stripAllHtmlTags),
                                style: TextStyle(
                                  color: globalSetting.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: context.screenWidth * (48 / 50), // 设置宽度
                    child: Divider(
                      color:
                          globalSetting.themeType
                              ? materialColorScheme.secondaryFixedDim
                              : materialColorScheme.secondaryFixedDim,
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

  String stripAllHtmlTags(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}
