import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';

import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';

class CreatorPictureWidget extends StatelessWidget {
  final String fileServer;
  final String path;
  final String pictureType;

  const CreatorPictureWidget({
    super.key,
    required this.fileServer,
    required this.path,
    required this.pictureType,
  });

  @override
  Widget build(BuildContext context) {
    final materialColorScheme = context.theme.colorScheme;

    return BlocProvider(
      create: (context) => PictureBloc()
        ..add(
          GetPicture(
            PictureInfo(
              from: "bika",
              url: fileServer,
              path: path,
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
                  width: 50,
                  height: 50,
                  child: LoadingAnimationWidget.waveDots(
                    color: materialColorScheme.primaryFixedDim,
                    size: 25,
                  ),
                ),
              );
            case PictureLoadStatus.success:
              return Center(
                child: InkWell(
                  onTap: () {
                    context.pushRoute(
                      FullRouteImageRoute(imagePath: state.imagePath!),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
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
                          url: fileServer,
                          path: path,
                          pictureType: pictureType,
                        ),
                      ),
                    );
                  },
                  child: Center(
                    child: Icon(
                      Icons.refresh,
                      size: 25,
                      color: context.textColor,
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
