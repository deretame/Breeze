import 'dart:io';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../../../config/global.dart';
import '../../../../../json/comic/comic_info.dart';
import '../../../../../main.dart';
import '../../../../../network/http/picture.dart';
import '../../../../../type/search_enter.dart';
import '../../../../../util/router.dart';
import '../../../../../widgets/full_screen_image_view.dart';

// 显示上传者信息
class CreatorInfoWidget extends StatefulWidget {
  final ComicInfo comicInfo;

  const CreatorInfoWidget({super.key, required this.comicInfo});

  @override
  State<CreatorInfoWidget> createState() => _CreatorInfoWidgetState();
}

class _CreatorInfoWidgetState extends State<CreatorInfoWidget>
    with AutomaticKeepAliveClientMixin<CreatorInfoWidget> {
  ComicInfo get comicInfo => widget.comicInfo;

  @override
  bool get wantKeepAlive => true; // 这将告诉Flutter保持这个页面状态

  String timeDecode(DateTime originalTime) {
    // 加上8个小时
    DateTime newDateTime = originalTime.add(const Duration(hours: 8));

    // 按照指定格式输出
    String formattedTime =
        '${newDateTime.year}年${newDateTime.month}月${newDateTime.day}日 ${newDateTime.hour.toString().padLeft(2, '0')}:${newDateTime.minute.toString().padLeft(2, '0')}:${newDateTime.second.toString().padLeft(2, '0')}';

    return "$formattedTime 更新";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 确保调用super.build

    return InkWell(
        onTap: () {
          navigateTo(
            context,
            '/search',
            extra: SearchEnter(
                url:
                    "https://picaapi.picacomic.com/comics?ca=58f649a80a48790773c7017c&s=ld&page=1",
                keyword: comicInfo.data.comic.creator.id.toString()),
          );
        },
        child: Container(
          height: 75,
          width: screenWidth * (48 / 50),
          decoration: BoxDecoration(
            color: globalSetting.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: globalSetting.themeType
                    ? Colors.black.withOpacity(0.2)
                    : Colors.white.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ImagerWidget(
                fileServer: comicInfo.data.comic.creator.avatar.fileServer,
                path: comicInfo.data.comic.creator.avatar.path,
                id: comicInfo.data.comic.id,
                pictureType: "creator",
              ),
              const SizedBox(width: 15),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      comicInfo.data.comic.creator.title,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      timeDecode(comicInfo.data.comic.updatedAt),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

class ImagerWidget extends StatefulWidget {
  final String fileServer;
  final String path;
  final String id;
  final String pictureType;

  const ImagerWidget({
    super.key,
    required this.fileServer,
    required this.path,
    required this.id,
    required this.pictureType,
  });

  @override
  State<ImagerWidget> createState() => _ImagerWidgetState();
}

class _ImagerWidgetState extends State<ImagerWidget> {
  get fileServer => widget.fileServer;

  get path => widget.path;

  get id => widget.id;

  get pictureType => widget.pictureType;

  late Future<String> _getCachePicture;

  void _reloadImage() {
    // 重置 Future，以便重新加载图片
    setState(() {
      _getCachePicture = getCachePicture(
        url: widget.fileServer,
        path: widget.path,
        cartoonId: widget.id,
        pictureType: pictureType,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _getCachePicture = getCachePicture(
      url: widget.fileServer,
      path: widget.path,
      cartoonId: widget.id,
      pictureType: pictureType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 75,
      width: 75,
      child: FutureBuilder<String>(
        future: _getCachePicture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              if (snapshot.error.toString().contains('404')) {
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
                // 如果有错误，显示错误信息和一个重新加载的按钮
                return InkWell(
                  onTap: () {
                    _reloadImage(); // 调用 _reloadImage 方法重新加载图片
                  },
                  child: Center(
                    child: Icon(
                      Icons.refresh,
                      size: 25,
                      color: globalSetting.textColor,
                    ),
                  ),
                );
              }
            } else {
              // 没有错误，正常显示图片
              return Center(
                child: InkWell(
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
                      borderRadius: BorderRadius.circular(25),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.file(
                          File(snapshot.data!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          } else {
            // 图片正在加载中
            return Center(
              child: LoadingAnimationWidget.waveDots(
                color: globalSetting.textColor,
                size: 25,
              ),
            );
          }
        },
      ),
    );
  }
}
