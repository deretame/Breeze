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

  // 用于触发重新加载图片的方法
  Future<String> _reloadPicture() async {
    return getCachePicture(
      doc.thumb.fileServer,
      doc.thumb.path,
      doc.id,
      pictureType: "cover",
    );
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
                SizedBox(
                  width: (screenWidth / 10) * 3,
                  height: 180,
                  child: FutureBuilder<String>(
                    future: _reloadPicture(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasError) {
                          // 显示错误信息并提供重新加载的选项
                          return InkWell(
                            onTap: () {
                              // 重新加载图片
                              setState(() {
                                _reloadPicture().then((value) {
                                  setState(() {
                                    // 更新UI
                                  });
                                });
                              });
                            },
                            child: Center(
                              child: Text(
                                '点击重新加载图片',
                                style: TextStyle(
                                  color: colorNotifier.defaultTextColor,
                                ),
                              ),
                            ),
                          );
                        } else {
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImageView(
                                    imagePath: snapshot.data!,
                                  ),
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
                                ),
                              ),
                            ),
                          );
                        }
                      } else {
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
