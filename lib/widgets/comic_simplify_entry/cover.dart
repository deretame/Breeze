import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';

class CoverWidget extends StatelessWidget {
  final String fileServer;
  final String path;
  final String id;
  final String pictureType;
  final String from;
  final bool roundedCorner;
  final double? width;
  final double? height;

  const CoverWidget({
    super.key,
    required this.fileServer,
    required this.path,
    required this.id,
    required this.pictureType,
    required this.from,
    this.roundedCorner = true,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final pictureInfo = PictureInfo(
      from: from,
      url: fileServer,
      path: path,
      cartoonId: id,
      pictureType: pictureType,
    );

    final width = this.width ?? context.screenWidth * 0.3;
    final height = this.height ?? (context.screenWidth * 0.3) / 0.75;

    return BlocProvider(
      create: (context) => PictureBloc()..add(GetPicture(pictureInfo)),
      child: SizedBox(
        width: width,
        height: height,
        child: BlocBuilder<PictureBloc, PictureLoadState>(
          builder: (context, state) {
            switch (state.status) {
              case PictureLoadStatus.initial:
                return Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(
                      roundedCorner ? 5.0 : 0.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.image, color: Colors.grey[300], size: 30),
                  ),
                );
              case PictureLoadStatus.success:
                return ClipRRect(
                  borderRadius: BorderRadius.circular(
                    roundedCorner ? 5.0 : 0.0,
                  ),
                  child: Image.file(
                    File(state.imagePath!),
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(
                            roundedCorner ? 5.0 : 0.0,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.grey[600],
                          ),
                        ),
                      );
                    },
                  ),
                );
              case PictureLoadStatus.failure:
                if (state.result.toString().contains('404')) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(5.0),
                    child: Image.asset(
                      'asset/image/error_image/404.png',
                      fit: BoxFit.cover,
                    ),
                  );
                } else {
                  return InkWell(
                    onTap: () {
                      context.read<PictureBloc>().add(GetPicture(pictureInfo));
                    },
                    child: Center(child: Icon(Icons.refresh)),
                  );
                }
            }
          },
        ),
      ),
    );
  }
}
