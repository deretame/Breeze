import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/widgets/picture_bloc/models/picture_info.dart';

import '../../../config/global.dart';
import '../../../widgets/full_screen_image_view.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';

class Cover extends StatelessWidget {
  final PictureInfo pictureInfo;

  const Cover({
    super.key,
    required this.pictureInfo,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: (screenWidth / 10) * 3,
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
                return LoadingAnimationWidget.waveDots(
                  color: Colors.blue,
                  size: 50,
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
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