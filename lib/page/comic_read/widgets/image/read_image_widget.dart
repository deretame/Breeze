import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/comic_read.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/picture_bloc/bloc/picture_bloc.dart';
import 'package:zephyr/widgets/picture_bloc/models/picture_info.dart';

class ReadImageWidget extends StatefulWidget {
  final PictureInfo pictureInfo;
  final int index;
  final bool isColumn;

  const ReadImageWidget({
    super.key,
    required this.pictureInfo,
    required this.index,
    required this.isColumn,
  });

  @override
  State<ReadImageWidget> createState() => _ReadImageWidgetState();
}

class _ReadImageWidgetState extends State<ReadImageWidget> {
  int get index => widget.index + 1;
  bool get isColumn => widget.isColumn;

  @override
  Widget build(BuildContext context) {
    final readSetting = context.select(
      (GlobalSettingCubit c) => c.state.readSetting,
    );
    final brightness = Theme.of(context).brightness;
    final backgroundColor = readSetting.resolveReaderBackgroundColor(
      brightness,
    );
    final foregroundColor = readSetting.resolveReaderForegroundColor(
      brightness,
    );

    return BlocProvider(
      create: (context) => PictureBloc()..add(GetPicture(widget.pictureInfo)),
      child: SizedBox(
        width: context.screenWidth,
        child: BlocBuilder<PictureBloc, PictureLoadState>(
          builder: (context, state) {
            switch (state.status) {
              case PictureLoadStatus.initial:
                return placeholder(
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                );
              case PictureLoadStatus.success:
                return GestureDetector(
                  onLongPress: () {
                    context.pushRoute(
                      FullRouteImageRoute(imagePath: state.imagePath!),
                    );
                  },
                  child: Container(
                    color: backgroundColor,
                    child: ImageDisplay(
                      imagePath: state.imagePath!,
                      isColumn: isColumn,
                      index: index,
                    ),
                  ),
                );
              case PictureLoadStatus.failure:
                if (state.result.toString().contains('404')) {
                  return Image.asset(
                    'asset/image/error_image/404.png',
                    fit: BoxFit.fill,
                  );
                } else {
                  return Container(
                    color: backgroundColor,
                    child: InkWell(
                      onTap: () {
                        context.read<PictureBloc>().add(
                          GetPicture(widget.pictureInfo),
                        );
                      },
                      child: Center(
                        child: Text(
                          "${state.result.toString()}\n加载失败，点击重试",
                          style: TextStyle(
                            fontSize: 20,
                            color: foregroundColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }
            }
          },
        ),
      ),
    );
  }

  Widget placeholder({
    required Color backgroundColor,
    required Color foregroundColor,
  }) => Container(
    color: backgroundColor,
    child: Center(
      child: Text(
        index.toString(),
        style: TextStyle(
          fontFamily: 'Pacifico-Regular',
          color: foregroundColor,
          fontSize: 150,
        ),
      ),
    ),
  );
}
