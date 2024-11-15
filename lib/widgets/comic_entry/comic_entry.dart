import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../config/global.dart';
import '../../main.dart';
import '../full_screen_image_view.dart';
import '../picture_bloc/bloc/picture_bloc.dart';
import '../picture_bloc/models/picture_info.dart';
import 'comic_entry_info.dart';

class ComicEntryWidget extends StatelessWidget {
  final ComicEntryInfo comicEntryInfo;

  const ComicEntryWidget({
    super.key,
    required this.comicEntryInfo,
  });

  String _getCategories(List<String>? categories) {
    int count = 0;
    int mainCount = 8;
    if (categories == null) {
      return "";
    } else {
      String temp = "";
      for (var category in categories) {
        temp += "$category ";
        count++;
        if (count == mainCount) {
          break;
        }
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
    final router = AutoRouter.of(context); // 获取 router 实例
    return InkWell(
      onTap: () {
        // 跳转到漫画详情页
        router.push(ComicInfoRoute(comicId: comicEntryInfo.id));
      },
      child: Column(
        children: <Widget>[
          SizedBox(height: (screenHeight / 10) * 0.1),
          Observer(
            builder: (context) {
              return Container(
                height: 180,
                width: ((screenWidth / 10) * 9.5),
                margin:
                    EdgeInsets.symmetric(horizontal: (screenWidth / 10) * 0.25),
                decoration: BoxDecoration(
                  color: globalSetting.backgroundColor,
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: [
                    BoxShadow(
                      color: globalSetting.themeType
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
                    _ImageWidget(
                      fileServer: comicEntryInfo.thumb.fileServer,
                      path: comicEntryInfo.thumb.path,
                      id: comicEntryInfo.id,
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
                                  text: _getLimitedTitle(
                                      comicEntryInfo.title, 30),
                                  style: TextStyle(
                                    color: globalSetting.textColor,
                                    fontSize: 18,
                                  ),
                                ),
                                TextSpan(
                                  text: comicEntryInfo.finished ? "(完)" : "",
                                  style: TextStyle(
                                    color: globalSetting.themeType
                                        ? Colors.red
                                        : Colors.yellow,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (comicEntryInfo.author.toString() != '') ...[
                            const SizedBox(height: 5),
                            Text(
                              _getLimitedTitle(
                                  comicEntryInfo.author.toString(), 40),
                              style: TextStyle(
                                color: globalSetting.themeType
                                    ? Colors.red
                                    : Colors.yellow,
                              ),
                            ),
                          ],
                          const SizedBox(height: 5),
                          Text(
                            _getCategories(comicEntryInfo.categories),
                            style: TextStyle(
                              color: globalSetting.textColor,
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
                                comicEntryInfo.likesCount.toString(),
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
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ImageWidget extends StatelessWidget {
  final String fileServer;
  final String path;
  final String id;
  final String pictureType;

  const _ImageWidget({
    required this.fileServer,
    required this.path,
    required this.id,
    required this.pictureType,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PictureBloc()
        ..add(
          GetPicture(
            PictureInfo(
              from: "bika",
              url: fileServer,
              path: path,
              cartoonId: id,
              pictureType: pictureType,
            ),
          ),
        ),
      child: BlocBuilder<PictureBloc, PictureLoadState>(
        builder: (context, state) {
          switch (state.status) {
            case PictureLoadStatus.initial:
              return Center(
                child: SizedBox(
                  width: (screenWidth / 10) * 3,
                  child: LoadingAnimationWidget.waveDots(
                    color: globalSetting.textColor,
                    size: 25,
                  ),
                ),
              );
            case PictureLoadStatus.success:
              // 没有错误，正常显示图片
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FullScreenImageView(imagePath: state.imagePath!),
                    ),
                  );
                },
                child: Hero(
                  tag: state.imagePath!,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10.0),
                      bottomLeft: Radius.circular(10.0),
                    ),
                    child: Image.file(
                      File(state.imagePath!),
                      fit: BoxFit.cover,
                      width: (screenWidth / 10) * 3,
                      height: 180,
                    ),
                  ),
                ),
              );
            case PictureLoadStatus.failure:
              if (state.result.toString().contains('404')) {
                return Image.asset('asset/image/error_image/404.png');
              } else {
                return InkWell(
                  onTap: () {
                    context.read<PictureBloc>().add(
                          GetPicture(
                            PictureInfo(
                              from: "bika",
                              url: fileServer,
                              path: path,
                              cartoonId: id,
                              pictureType: pictureType,
                            ),
                          ),
                        );
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
          }
        },
      ),
    );
  }
}
