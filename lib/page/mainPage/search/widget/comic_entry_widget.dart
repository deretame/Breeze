import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/config/global.dart';
import 'package:zephyr/json/search_bar/search_result.dart';
import 'package:zephyr/util/router.dart';

import '../../../../network/http/picture.dart';
import '../../../../util/state_management.dart';
import '../../../../widgets/full_screen_image_view.dart';

class ComicEntryWidget extends ConsumerStatefulWidget {
  final Doc doc;

  const ComicEntryWidget({
    super.key,
    required this.doc,
  });

  @override
  ConsumerState<ComicEntryWidget> createState() => _ComicEntryWidgetState();
}

class _ComicEntryWidgetState extends ConsumerState<ComicEntryWidget> {
  Doc get doc => widget.doc;

  String _getCategories(List<String>? categories) {
    if (categories == null) {
      return "";
    } else {
      String temp = "";
      for (var category in categories) {
        temp += "$category ";
      }
      return "分类: $temp";
    }
  }

  // 截断过长的标题
  String _getLimitedTitle(String title, int maxLength) {
    if (title.length > maxLength) {
      return '${title.substring(0, maxLength)}...';
    }
    return title;
  }

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context);

    return InkWell(
      onTap: () {
        // 跳转到漫画详情页
        navigateTo(context, '/comicInfo', extra: doc.id);
      },
      child: Column(
        children: <Widget>[
          SizedBox(height: (screenHeight / 10) * 0.1),
          Container(
            height: 180,
            width: ((screenWidth / 10) * 9.5),
            margin: EdgeInsets.symmetric(horizontal: (screenWidth / 10) * 0.25),
            decoration: BoxDecoration(
              color: colorNotifier.defaultBackgroundColor,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: colorNotifier.themeType
                      ? Colors.black.withOpacity(0.2)
                      : Colors.white.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                ImageWidget(
                  fileServer: doc.thumb.fileServer,
                  path: doc.thumb.path,
                  id: doc.id,
                  pictureType: "cover",
                ),
                SizedBox(width: screenWidth / 60),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(height: screenWidth / 200),
                      RichText(
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                              text: _getLimitedTitle(doc.title, 30),
                              style: TextStyle(
                                color: colorNotifier.defaultTextColor,
                                fontSize: 18,
                              ),
                            ),
                            TextSpan(
                              text: doc.finished ? "(完)" : "",
                              style: TextStyle(
                                color: colorNotifier.themeType
                                    ? Colors.red
                                    : Colors.yellow,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        doc.author.toString(),
                        style: TextStyle(
                          color: colorNotifier.themeType
                              ? Colors.red
                              : Colors.yellow,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _getCategories(doc.categories),
                        style: TextStyle(
                          color: colorNotifier.defaultTextColor,
                        ),
                      ),
                      Spacer(),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 24.0,
                          ),
                          const SizedBox(width: 10.0),
                          Text(
                            doc.likesCount.toString(),
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth / 200),
                    ],
                  ),
                ),
                SizedBox(width: screenWidth / 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ImageWidget extends ConsumerStatefulWidget {
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
  ConsumerState<ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends ConsumerState<ImageWidget> {
  late Future<String> _getCachePicture;

  @override
  void initState() {
    super.initState();
    _refreshCachePicture();
  }

  void _refreshCachePicture() {
    // 重新初始化 _getCachePicture，以触发 FutureBuilder 重建
    setState(() {
      _getCachePicture = getCachePicture(
        widget.fileServer,
        widget.path,
        widget.id,
        pictureType: widget.pictureType,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorNotifier = ref.watch(defaultColorProvider);
    colorNotifier.initialize(context);

    return SizedBox(
      width: (screenWidth / 10) * 3,
      height: 180,
      child: FutureBuilder<String>(
        future: _getCachePicture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              // 如果有错误，显示错误信息和一个重新加载的按钮
              // 部分图片在服务器上可能已经不存在，所以显示一个404图片
              if (snapshot.error.toString().contains('404')) {
                return Image.asset('asset/image/error_image/404.png');
              } else {
                return InkWell(
                  onTap: _refreshCachePicture, // 直接调用 _refreshCachePicture
                  child: Center(
                    child: Text(
                      '加载图片失败\n点击重新加载',
                      style: TextStyle(
                        color: colorNotifier.defaultTextColor,
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
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      bottomLeft: Radius.circular(10.0),
                    ),
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
