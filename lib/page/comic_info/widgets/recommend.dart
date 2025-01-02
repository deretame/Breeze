import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../main.dart';
import '../../../util/router/router.gr.dart';
import '../../../widgets/comic_entry/comic_entry.dart';
import '../../../widgets/error_view.dart';
import '../../../widgets/full_screen_image_view.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../bloc/recommend/recommend_bloc.dart';

class RecommendWidget extends StatelessWidget {
  final String comicId;

  final ComicEntryType type;

  const RecommendWidget({
    super.key,
    required this.comicId,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RecommendBloc()
        ..add(RecommendEvent(comicId, RecommendStatus.initial)),
      child: _RecommendWidget(
        comicId: comicId,
        type: type,
      ),
    );
  }
}

class _RecommendWidget extends StatelessWidget {
  final String comicId;
  final ComicEntryType type;

  const _RecommendWidget({
    required this.comicId,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecommendBloc, RecommendState>(
      builder: (context, state) {
        switch (state.status) {
          case RecommendStatus.initial:
            return Center(child: CircularProgressIndicator());
          case RecommendStatus.failure:
            return type == ComicEntryType.download
                ? SizedBox.shrink()
                : ErrorView(
                    errorMessage: '${state.result.toString()}\n加载失败，请重试。',
                    onRetry: () {
                      context.read<RecommendBloc>().add(
                          RecommendEvent(comicId, RecommendStatus.initial));
                    },
                  );
          case RecommendStatus.success:
            return successWidget(state);
        }
      },
    );
  }

  Widget successWidget(RecommendState state) {
    if (state.comicList == null) {
      return SizedBox.shrink();
    }
    return Observer(
      builder: (context) {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: globalSetting.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: globalSetting.themeType
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.2),
                spreadRadius: 2,
                blurRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            // 使用ClipRRect来裁剪子组件
            borderRadius: BorderRadius.circular(10),
            // 设置与外层Container相同的圆角
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  state.comicList!.length,
                  (index) {
                    return SizedBox(
                      width: 100,
                      height: 200,
                      child: Column(
                        children: [
                          _Cover(
                            pictureInfo: PictureInfo(
                              from: "bika",
                              url: state.comicList![index].thumb.fileServer,
                              path: state.comicList![index].thumb.path,
                              chapterId: state.comicList![index].id,
                              pictureType: "cover",
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              // 跳转到漫画详情页
                              AutoRouter.of(context).push(
                                ComicInfoRoute(
                                  comicId: state.comicList![index].id,
                                ),
                              );
                            },
                            child: SizedBox(
                              width: 100,
                              height: 50,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Text(
                                  state.comicList![index].title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: globalSetting.textColor,
                                  ),
                                  softWrap: true, // 允许换行
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Cover extends StatelessWidget {
  final PictureInfo pictureInfo;

  const _Cover({
    required this.pictureInfo,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 150,
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
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LoadingAnimationWidget.waveDots(
                    color: Colors.blue,
                    size: 50,
                  ),
                );
              case PictureLoadStatus.success:
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
                    child: Image.file(
                      File(state.imagePath!),
                      fit: BoxFit.cover,
                      width: 100,
                      height: 150,
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
    );
  }
}
