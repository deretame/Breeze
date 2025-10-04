import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/picture_bloc/bloc/picture_bloc.dart';
import 'package:zephyr/widgets/picture_bloc/models/picture_info.dart';

class UserAvatar extends StatelessWidget {
  final PictureInfo pictureInfo;

  const UserAvatar({super.key, required this.pictureInfo});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 75,
      width: 75,
      child: BlocProvider(
        create: (context) => PictureBloc()..add(GetPicture(pictureInfo)),
        child: BlocBuilder<PictureBloc, PictureLoadState>(
          builder: (context, state) {
            switch (state.status) {
              case PictureLoadStatus.initial:
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: CircularProgressIndicator(),
                );
              case PictureLoadStatus.success:
                return GestureDetector(
                  onTap: () {
                    context.pushRoute(
                      FullRouteImageRoute(imagePath: state.imagePath!),
                    );
                  },
                  child: SizedBox(
                    height: 75,
                    width: 75,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50.0),
                      child:
                          pictureInfo.url.contains("nopic-Male.gif")
                              ? Image.asset(
                                'asset/image/assets/default_cover.png',
                                fit: BoxFit.cover,
                              )
                              : Image.file(
                                File(state.imagePath!),
                                fit: BoxFit.cover,
                              ),
                    ),
                  ),
                );
              case PictureLoadStatus.failure:
                if (state.result.toString().contains('404')) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(50.0),
                    child: Image.asset(
                      'asset/image/assets/default_cover.png',
                      fit: BoxFit.cover,
                    ),
                  );
                }
                return InkWell(
                  onTap: () {
                    context.read<PictureBloc>().add(GetPicture(pictureInfo));
                  },
                  child: Icon(Icons.refresh),
                );
            }
          },
        ),
      ),
    );
  }
}
