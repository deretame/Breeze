import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/picture_bloc/bloc/picture_bloc.dart';
import 'package:zephyr/widgets/picture_bloc/models/picture_info.dart';

class CreatorLinkCard extends StatelessWidget {
  const CreatorLinkCard({
    super.key,
    required this.creatorName,
    required this.avatarUrl,
    required this.avatarPath,
    required this.infoChildren,
    this.onTap,
    this.from = From.bika,
    this.pictureType = PictureType.creator,
    this.imageKey = '',
    this.errorAssetPath = 'asset/image/assets/default_cover.png',
    this.padding = const EdgeInsets.symmetric(horizontal: 5.0),
  });

  final String creatorName;
  final String avatarUrl;
  final String avatarPath;
  final List<Widget> infoChildren;
  final VoidCallback? onTap;
  final From from;
  final PictureType pictureType;
  final String imageKey;
  final String errorAssetPath;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final materialColorScheme = context.theme.colorScheme;
    final pictureInfo = PictureInfo(
      from: from,
      url: avatarUrl,
      path: avatarPath,
      cartoonId: imageKey,
      chapterId: imageKey,
      pictureType: pictureType,
    );

    return Padding(
      padding: padding,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 75,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.backgroundColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: materialColorScheme.secondaryFixedDim,
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
              _CreatorAvatarImage(
                pictureInfo: pictureInfo,
                errorAssetPath: errorAssetPath,
              ),
              const SizedBox(width: 15),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      creatorName,
                      style: TextStyle(color: materialColorScheme.tertiary),
                    ),
                    ...infoChildren,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatorAvatarImage extends StatelessWidget {
  const _CreatorAvatarImage({
    required this.pictureInfo,
    required this.errorAssetPath,
  });

  final PictureInfo pictureInfo;
  final String errorAssetPath;

  @override
  Widget build(BuildContext context) {
    final hasRemoteOrLocalSource =
        pictureInfo.url.trim().isNotEmpty || pictureInfo.path.trim().isNotEmpty;

    if (!hasRemoteOrLocalSource) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Image.asset(errorAssetPath, fit: BoxFit.cover),
        ),
      );
    }

    return SizedBox(
      height: 75,
      width: 75,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: BlocProvider(
          create: (context) => PictureBloc()..add(GetPicture(pictureInfo)),
          child: BlocBuilder<PictureBloc, PictureLoadState>(
            builder: (context, state) {
              switch (state.status) {
                case PictureLoadStatus.initial:
                  return Center(
                    child: LoadingAnimationWidget.waveDots(
                      color: context.textColor,
                      size: 25,
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
                  );
                case PictureLoadStatus.failure:
                  if (state.result.toString().contains('404')) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: Image.asset(errorAssetPath, fit: BoxFit.cover),
                      ),
                    );
                  }

                  return InkWell(
                    onTap: () {
                      context.read<PictureBloc>().add(GetPicture(pictureInfo));
                    },
                    child: const Icon(Icons.refresh),
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}
