import 'dart:io';

import 'package:cherry_toast/cherry_toast.dart';
import 'package:cherry_toast/resources/arrays.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/main.dart';

import '../../../../../config/global.dart';
import '../../../../../json/comic/comic_info.dart';
import '../../../../../network/http/picture.dart';
import '../../../../../type/search_enter.dart';
import '../../../../../util/router.dart';
import '../../../../../widgets/full_screen_image_view.dart';

// 显示漫画的一些信息
// 封面，名字，作家，汉化组，收藏人数，章节信息
class ComicParticularsWidget extends StatefulWidget {
  final ComicInfo comicInfo;

  const ComicParticularsWidget({super.key, required this.comicInfo});

  @override
  State<ComicParticularsWidget> createState() => _ComicParticularsWidgetState();
}

class _ComicParticularsWidgetState extends State<ComicParticularsWidget>
    with AutomaticKeepAliveClientMixin<ComicParticularsWidget> {
  ComicInfo get comicInfo => widget.comicInfo;

  @override
  bool get wantKeepAlive => true; // 这将告诉Flutter保持这个页面状态

  // @override
  // void initState() {
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 确保调用super.build

    return SizedBox(
      width: screenWidth * (48 / 50),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ImageWidget(
            fileServer: comicInfo.data.comic.thumb.fileServer,
            path: comicInfo.data.comic.thumb.path,
            id: comicInfo.data.comic.id,
            pictureType: "cover",
          ),
          SizedBox(width: screenWidth / 60),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SelectableText(
                  comicInfo.data.comic.title,
                  style: TextStyle(
                    color: globalSetting.textColor,
                    fontSize: 18,
                  ),
                ),
                if (comicInfo.data.comic.author != '') ...[
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () {
                      // 点击时触发的事件
                      var enter = SearchEnter();
                      enter.keyword = comicInfo.data.comic.author;
                      navigateTo(context, '/search', extra: enter);
                    },
                    onLongPress: () {
                      // 长按时触发的事件
                      Clipboard.setData(
                          ClipboardData(text: comicInfo.data.comic.author));
                      CherryToast.success(
                        description: Text(
                          "已将${comicInfo.data.comic.author}复制到剪贴板",
                          style: TextStyle(color: globalSetting.textColor),
                        ),
                        animationType: AnimationType.fromTop,
                        toastDuration: const Duration(seconds: 2),
                        autoDismiss: true,
                        backgroundColor: globalSetting.backgroundColor,
                      ).show(context);
                    },
                    child: Text(
                      '作者：${comicInfo.data.comic.author}',
                      style: TextStyle(
                        color: globalSetting.themeType
                            ? Colors.red
                            : Colors.yellow,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                if (comicInfo.data.comic.chineseTeam != "") ...[
                  InkWell(
                    onTap: () {
                      // 点击时触发的事件
                      var enter = SearchEnter();
                      enter.keyword = comicInfo.data.comic.chineseTeam;
                      navigateTo(context, '/search', extra: enter);
                    },
                    onLongPress: () {
                      // 长按时触发的事件
                      Clipboard.setData(ClipboardData(
                          text: comicInfo.data.comic.chineseTeam));
                      CherryToast.success(
                        description: Text(
                          "已将${comicInfo.data.comic.chineseTeam}复制到剪贴板",
                          style: TextStyle(color: globalSetting.textColor),
                        ),
                        animationType: AnimationType.fromTop,
                        toastDuration: const Duration(seconds: 2),
                        autoDismiss: true,
                        backgroundColor: globalSetting.backgroundColor,
                      ).show(context);
                    },
                    child: Text(
                      '汉化组：${comicInfo.data.comic.chineseTeam}',
                      style: TextStyle(
                        color: globalSetting.themeType
                            ? Colors.blue.shade300
                            : Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
                Text("页数：${comicInfo.data.comic.pagesCount}"),
                const SizedBox(height: 2),
                Text("章节数：${comicInfo.data.comic.epsCount}"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ImageWidget extends StatefulWidget {
  final String fileServer;
  final String path;
  final String id;
  final String pictureType;

  const ImageWidget({
    super.key,
    required this.fileServer,
    required this.path,
    required this.id,
    required this.pictureType,
  });

  @override
  State<ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<ImageWidget> {
  late Future<String> _getCachePicture;

  @override
  void initState() {
    super.initState();
    _refreshCachePicture();
  }

  void _refreshCachePicture() {
    _getCachePicture = getCachePicture(
      url: widget.fileServer,
      path: widget.path,
      cartoonId: widget.id,
      pictureType: widget.pictureType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (screenWidth / 10) * 3,
      height: 180,
      child: FutureBuilder<String>(
        future: _getCachePicture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // 部分图片在服务器上可能已经不存在，所以显示一个404图片
            if (snapshot.hasError) {
              // 如果有错误，显示错误信息和一个重新加载的按钮
              if (snapshot.error.toString().contains('404')) {
                return Image.asset('asset/image/error_image/404.png');
              } else {
                return InkWell(
                  onTap: () {
                    _refreshCachePicture(); // 重新初始化图片加载
                    setState(() {}); // 触发重新构建
                  },
                  child: Center(
                    child: Text(
                      '加载图片失败\n点击重新加载',
                      style: TextStyle(
                        color: globalSetting.textColor,
                      ),
                    ),
                  ),
                );
              }
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
    );
  }
}
