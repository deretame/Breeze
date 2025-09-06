import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/widgets/picture_bloc/models/picture_info.dart';

import '../../../../main.dart';
import '../../../../util/router/router.gr.dart';
import '../../../../widgets/picture_bloc/bloc/picture_bloc.dart';

class Cover extends StatelessWidget {
  final PictureInfo pictureInfo;

  const Cover({super.key, required this.pictureInfo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      width: 180 / 4 * 3,
      child: BlocProvider(
        create: (context) => PictureBloc()..add(GetPicture(pictureInfo)),
        child: BlocBuilder<PictureBloc, PictureLoadState>(
          builder: (context, state) {
            switch (state.status) {
              case PictureLoadStatus.initial:
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LoadingAnimationWidget.waveDots(
                    color: materialColorScheme.primaryFixedDim,
                    size: 50,
                  ),
                );
              case PictureLoadStatus.success:
                return InkWell(
                  onTap: () {
                    context.pushRoute(
                      FullRouteImageRoute(imagePath: state.imagePath!),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.file(
                      File(state.imagePath!),
                      fit: BoxFit.cover,
                      width: 180 / 4 * 3,
                      height: 180,
                    ),
                  ),
                );
              case PictureLoadStatus.failure:
                if (state.result.toString().contains('404')) {
                  return Image.asset('asset/image/error_image/404.png');
                } else {
                  return InkWell(
                    onTap: () {
                      context.read<PictureBloc>().add(GetPicture(pictureInfo));
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
