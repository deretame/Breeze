import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/global.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';

class CoverWidget extends StatelessWidget {
  final String fileServer;
  final String path;
  final String id;
  final String pictureType;
  final String from;

  const CoverWidget({
    super.key,
    required this.fileServer,
    required this.path,
    required this.id,
    required this.pictureType,
    required this.from,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              PictureBloc()..add(
                GetPicture(
                  PictureInfo(
                    from: from,
                    url: fileServer,
                    path: path,
                    cartoonId: id,
                    pictureType: pictureType,
                  ),
                ),
              ),
      child: SizedBox(
        width: screenWidth * 0.3,
        height: (screenWidth * 0.3) / 0.75,
        child: BlocBuilder<PictureBloc, PictureLoadState>(
          builder: (context, state) {
            switch (state.status) {
              case PictureLoadStatus.initial:
                return Center(child: CircularProgressIndicator());
              case PictureLoadStatus.success:
                return ClipRRect(
                  borderRadius: BorderRadius.circular(5.0),
                  child: Image.file(File(state.imagePath!), fit: BoxFit.cover),
                );
              case PictureLoadStatus.failure:
                if (state.result.toString().contains('404')) {
                  return Center(child: Icon(Icons.error));
                } else {
                  return InkWell(
                    onTap: () {
                      context.read<PictureBloc>().add(
                        GetPicture(
                          PictureInfo(
                            from: from,
                            url: fileServer,
                            path: path,
                            cartoonId: id,
                            pictureType: pictureType,
                          ),
                        ),
                      );
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
