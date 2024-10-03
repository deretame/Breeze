import 'dart:io';

import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../../../config/global.dart';
import '../../../../../json/comic/comic_info.dart';
import '../../../../../network/http/picture.dart';
import '../../../../../util/dialog.dart';
import '../../../../../util/state_management.dart';
import '../../../../../widgets/full_screen_image_view.dart';

// 显示漫画的一些信息
// 封面，名字，作家，汉化组，收藏人数，章节信息
class ComicParticularsWidget extends ConsumerStatefulWidget {
  final ComicInfo comicInfo;

  const ComicParticularsWidget({super.key, required this.comicInfo});

  @override
  ConsumerState<ComicParticularsWidget> createState() =>
      _ComicParticularsWidgetState();
}

class _ComicParticularsWidgetState extends ConsumerState<ComicParticularsWidget>
    with AutomaticKeepAliveClientMixin<ComicParticularsWidget> {
  ComicInfo get comicInfo => widget.comicInfo;
  late Future<String> _getCachePicture;

  @override
  bool get wantKeepAlive => true; // 这将告诉Flutter保持这个页面状态

  @override
  void initState() {
    super.initState();
    _getCachePicture = getCachePicture(
      comicInfo.comic.thumb.fileServer,
      comicInfo.comic.thumb.path,
      comicInfo.comic.id,
      pictureType: "cover",
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 确保调用super.build
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context);

    return SizedBox(
      width: screenWidth * (48 / 50),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: (screenWidth / 10) * 3,
            height: 180,
            child: FutureBuilder<String>(
              future: _getCachePicture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError) {
                    // 如果有错误，显示错误信息和一个重新加载的按钮
                    return InkWell(
                      onTap: () {
                        _getCachePicture.then((value) {
                          setState(() {
                            // 更新UI
                          });
                        });
                      },
                      child: Center(
                        child: Text(
                          '加载失败，点击重新加载',
                          style: TextStyle(
                            color: colorNotifier.defaultTextColor,
                          ),
                        ),
                      ),
                    );
                  } else {
                    // 没有错误，正常显示图片
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                FullScreenImageView(imagePath: snapshot.data!),
                          ),
                        );
                      },
                      child: Hero(
                        tag: snapshot.data!,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.file(
                            File(snapshot.data!),
                            fit: BoxFit.cover,
                            width: (screenWidth / 10) * 3,
                            height: 180,
                          ),
                        ),
                      ),
                    );
                  }
                } else {
                  // 图片正在加载中
                  return Center(
                    child: LoadingAnimationWidget.waveDots(
                      color: Colors.black,
                      size: 50,
                    ),
                  );
                }
              },
            ),
          ),
          SizedBox(width: screenWidth / 60),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SelectableText(
                  comicInfo.comic.title,
                  style: TextStyle(
                    color: colorNotifier.defaultTextColor,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () {
                    // 点击时触发的事件
                    nothingDialog(context);
                  },
                  onLongPress: () {
                    // 长按时触发的事件
                    Clipboard.setData(
                        ClipboardData(text: comicInfo.comic.author));
                    CherryToast.success(
                      description: Text(
                        "已将${comicInfo.comic.author}复制到剪贴板",
                        style: TextStyle(color: colorNotifier.defaultTextColor),
                      ),
                      animationType: AnimationType.fromTop,
                      animationDuration: const Duration(milliseconds: 3000),
                      autoDismiss: true,
                      backgroundColor: colorNotifier.defaultBackgroundColor,
                    ).show(context);
                  },
                  child: Text(
                    '作者：${comicInfo.comic.author}',
                    style: TextStyle(
                      color:
                          colorNotifier.themeType ? Colors.red : Colors.yellow,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                if (comicInfo.comic.chineseTeam != "") ...[
                  InkWell(
                    onTap: () {
                      // 点击时触发的事件
                      nothingDialog(context);
                    },
                    onLongPress: () {
                      // 长按时触发的事件
                      Clipboard.setData(
                          ClipboardData(text: comicInfo.comic.chineseTeam));
                      CherryToast.success(
                        description: Text(
                          "已将${comicInfo.comic.chineseTeam}复制到剪贴板",
                          style:
                              TextStyle(color: colorNotifier.defaultTextColor),
                        ),
                        animationType: AnimationType.fromTop,
                        animationDuration: const Duration(milliseconds: 3000),
                        autoDismiss: true,
                        backgroundColor: colorNotifier.defaultBackgroundColor,
                      ).show(context);
                    },
                    child: Text(
                      '汉化组：${comicInfo.comic.chineseTeam}',
                      style: TextStyle(
                        color: colorNotifier.themeType
                            ? Colors.blue.shade300
                            : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
                Text("页数：${comicInfo.comic.pagesCount}"),
                const SizedBox(height: 2),
                Text("章节数：${comicInfo.comic.epsCount}"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
