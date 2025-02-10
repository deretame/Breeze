import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/page/bookshelf/json/favorite/favourite_json.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../../../config/global.dart';
import '../../../../main.dart';
import '../../../../widgets/full_screen_image_view.dart';
import '../../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../../widgets/picture_bloc/models/picture_info.dart';

class FavoriteComicEntryWidget extends StatelessWidget {
  final Doc comicEntryInfo;

  const FavoriteComicEntryWidget({
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

  @override
  Widget build(BuildContext context) {
    final router = AutoRouter.of(context); // 获取 router 实例
    return GestureDetector(
      onTap: () {
        // 跳转到漫画详情页
        router.push(ComicInfoRoute(
          comicId: comicEntryInfo.id,
        ));
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
                      color: materialColorScheme.secondaryFixedDim,
                      spreadRadius: 0,
                      blurRadius: 2,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    _ImageWidget(
                      key: Key(comicEntryInfo.toString()),
                      fileServer: comicEntryInfo.thumb.fileServer,
                      path: comicEntryInfo.thumb.path,
                      id: comicEntryInfo.id,
                      pictureType: "favourite",
                    ),
                    SizedBox(width: screenWidth / 60),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: screenWidth / 200),
                          Text(
                            comicEntryInfo.title,
                            style: TextStyle(
                              color: globalSetting.textColor,
                              fontSize: 18,
                            ),
                            maxLines: 3, // 最大行数
                            overflow: TextOverflow.ellipsis, // 超出时使用省略号
                          ),
                          if (comicEntryInfo.author.toString() != '') ...[
                            const SizedBox(height: 4),
                            Text(
                              comicEntryInfo.author.toString(),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: materialColorScheme.primary,
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
                              SizedBox(width: 10.0),
                              Text(
                                comicEntryInfo.finished ? "完结" : "",
                                style: TextStyle(
                                  color: materialColorScheme.tertiary,
                                ),
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
    super.key,
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
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: LoadingAnimationWidget.waveDots(
                      color: materialColorScheme.primaryFixedDim,
                      size: 25,
                    ),
                  ),
                ),
              );
            case PictureLoadStatus.success:
              final uuid = Uuid().v4();
              // 没有错误，正常显示图片
              return InkWell(
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
              debugPrint(state.result.toString());
              if (state.result.toString().contains('404')) {
                return SizedBox(
                  width: (screenWidth / 10) * 3,
                  child: Image.asset('asset/image/error_image/404.png'),
                );
              } else {
                return SizedBox(
                  width: (screenWidth / 10) * 3,
                  child: InkWell(
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
                  ),
                );
              }
          }
        },
      ),
    );
  }
}
