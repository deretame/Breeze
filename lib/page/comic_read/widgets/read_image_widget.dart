import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comic_read/comic_read.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../util/router/router.gr.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';

class ReadImageWidget extends StatefulWidget {
  final bool isVisible;
  final PictureInfo pictureInfo;
  final int index;
  final bool isColumn;

  const ReadImageWidget({
    super.key,
    required this.isVisible,
    required this.pictureInfo,
    required this.index,
    required this.isColumn,
  });

  @override
  State<ReadImageWidget> createState() => _ReadImageWidgetState();
}

class _ReadImageWidgetState extends State<ReadImageWidget>
    with AutomaticKeepAliveClientMixin {
  int get index => widget.index + 1;
  bool get isColumn => widget.isColumn;

  @override
  bool get wantKeepAlive => !isColumn;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider(
      create: (context) => PictureBloc()..add(GetPicture(widget.pictureInfo)),
      child: SizedBox(
        width: context.screenWidth,
        child: BlocBuilder<PictureBloc, PictureLoadState>(
          builder: (context, state) {
            switch (state.status) {
              case PictureLoadStatus.initial:
                return placeholder();
              case PictureLoadStatus.success:
                if (widget.isVisible) {
                  return GestureDetector(
                    onLongPress: () {
                      context.pushRoute(
                        FullRouteImageRoute(imagePath: state.imagePath!),
                      );
                    },
                    child: ImageDisplay(
                      imagePath: state.imagePath!,
                      isColumn: isColumn,
                      index: index,
                    ),
                  );
                } else {
                  return placeholder();
                }
              case PictureLoadStatus.failure:
                if (state.result.toString().contains('404')) {
                  return Image.asset(
                    'asset/image/error_image/404.png',
                    fit: BoxFit.fill,
                  );
                } else {
                  return Container(
                    color: isColumn ? Color(0xFF2D2D2D) : Colors.black,
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
                            color: isColumn ? Color(0xFFCCCCCC) : Colors.white,
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

  Widget placeholder() => Container(
    color: isColumn ? Color(0xFF2D2D2D) : Colors.black,
    child: Center(
      child: Text(
        index.toString(),
        style: TextStyle(
          fontFamily: 'Pacifico-Regular',
          color: isColumn ? Color(0xFFCCCCCC) : Colors.white,
          fontSize: 150,
        ),
      ),
    ),
  );
}
