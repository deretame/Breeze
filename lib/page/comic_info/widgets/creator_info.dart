import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../config/global/global.dart';
import '../../../main.dart';
import '../../../util/router/router.gr.dart';
import '../../../widgets/full_screen_image_view.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../../search_result/models/search_enter.dart';
import '../json/comic_info/comic_info.dart';

// 显示上传者信息
class CreatorInfoWidget extends StatelessWidget {
  final Comic comicInfo;

  const CreatorInfoWidget({super.key, required this.comicInfo});

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

    return "$formattedTime 更新";
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AutoRouter.of(context).push(
          SearchResultRoute(
            searchEnterConst: SearchEnterConst(
              from: "bika",
              url:
                  "https://picaapi.picacomic.com/comics?ca=${comicInfo.creator.id}&s=ld&page=1",
              type: "creator",
              keyword: comicInfo.creator.name,
            ),
          ),
        );
      },
      child: Observer(
        builder: (context) {
          return Container(
            height: 75,
            width: screenWidth * (48 / 50),
            decoration: BoxDecoration(
              color: globalSetting.backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color:
                      globalSetting.themeType
                          ? materialColorScheme.secondaryFixedDim
                          : materialColorScheme.secondaryFixedDim,
                  spreadRadius: 0,
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _ImagerWidget(
                  pictureInfo: PictureInfo(
                    url: comicInfo.creator.avatar.fileServer,
                    path: comicInfo.creator.avatar.path,
                    cartoonId: comicInfo.id,
                    pictureType: "creator",
                    chapterId: comicInfo.id,
                    from: "bika",
                  ),
                ),
                const SizedBox(width: 15),
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        comicInfo.creator.name,
                        style: TextStyle(
                          color:
                              globalSetting.themeType
                                  ? materialColorScheme.tertiary
                                  : materialColorScheme.tertiary,
                        ),
                      ),
                      Text(timeDecode(comicInfo.updatedAt)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ImagerWidget extends StatelessWidget {
  final PictureInfo pictureInfo;

  const _ImagerWidget({required this.pictureInfo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 75,
      width: 75,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: BlocProvider(
          create:
              (context) =>
                  PictureBloc()..add(
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
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => FullScreenImageView(
                                imagePath: state.imagePath!,
                              ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: state.imagePath!,
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
                  if (state.result.toString().contains('404')) {
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
