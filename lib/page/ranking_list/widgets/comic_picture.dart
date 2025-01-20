import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:uuid/uuid.dart';

import '../../../config/global.dart';
import '../../../main.dart';
import '../../../widgets/full_screen_image_view.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';

class ComicPictureWidget extends StatelessWidget {
  final String fileServer;
  final String path;
  final String id;
  final String pictureType;

  const ComicPictureWidget({
    super.key,
    required this.fileServer,
    required this.path,
    required this.id,
    required this.pictureType,
  });

  @override
  Widget build(BuildContext context) {
    final uuid = Uuid().v4();
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
                    padding: const EdgeInsets.all(16.0),
                    child: LoadingAnimationWidget.waveDots(
                      color: materialColorScheme.primaryFixedDim,
                      size: 50,
                    ),
                  ),
                ),
              );
            case PictureLoadStatus.success:
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
