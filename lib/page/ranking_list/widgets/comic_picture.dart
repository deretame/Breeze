import 'dart:io'; // 必须导入，否则 File 报错

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';

class ComicPictureWidget extends StatelessWidget {
  final String fileServer;
  final String path;
  final String id;
  final String pictureType;
  final double targetWidth;
  final double targetHeight;

  const ComicPictureWidget({
    super.key,
    required this.fileServer,
    required this.path,
    required this.id,
    required this.pictureType,
    this.targetWidth = 100,
    this.targetHeight = 133,
  });

  @override
  Widget build(BuildContext context) {
    final pictureInfo = PictureInfo(
      from: "bika",
      url: fileServer,
      path: path,
      cartoonId: id,
      pictureType: pictureType,
    );

    return BlocProvider(
      create: (context) => PictureBloc()..add(GetPicture(pictureInfo)),
      child: BlocBuilder<PictureBloc, PictureLoadState>(
        builder: (context, state) {
          Widget sizeWrapper(Widget child) {
            return SizedBox(
              width: targetWidth,
              height: targetHeight,
              child: child,
            );
          }

          const borderRadius = BorderRadius.only(
            topLeft: Radius.circular(10.0),
            bottomLeft: Radius.circular(10.0),
          );

          switch (state.status) {
            case PictureLoadStatus.initial:
              return sizeWrapper(
                Center(
                  child: LoadingAnimationWidget.waveDots(
                    color: context.theme.colorScheme.primaryFixedDim,
                    size: 30,
                  ),
                ),
              );

            case PictureLoadStatus.success:
              return InkWell(
                onTap: () {
                  context.pushRoute(
                    FullRouteImageRoute(imagePath: state.imagePath!),
                  );
                },
                child: sizeWrapper(
                  ClipRRect(
                    borderRadius: borderRadius,
                    child: Image.file(
                      File(state.imagePath!),
                      fit: BoxFit.cover,
                      width: targetWidth,
                      height: targetHeight,
                    ),
                  ),
                ),
              );

            case PictureLoadStatus.failure:
              if (state.result.toString().contains('404')) {
                return sizeWrapper(
                  ClipRRect(
                    borderRadius: borderRadius,
                    child: Image.asset(
                      'asset/image/error_image/404.png',
                      fit: BoxFit.cover,
                      width: targetWidth,
                      height: targetHeight,
                    ),
                  ),
                );
              } else {
                return sizeWrapper(
                  InkWell(
                    onTap: () {
                      context.read<PictureBloc>().add(GetPicture(pictureInfo));
                    },
                    child: Center(
                      child: Text(
                        '加载失败\n点击重试',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.textColor,
                          fontSize: 12,
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
