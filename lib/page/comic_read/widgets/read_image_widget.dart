import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comic_read/comic_read.dart';
import 'package:zephyr/util/context/context_extensions.dart';

import '../../../util/router/router.gr.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';

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
  int get index => widget.index;

  bool get isColumn => widget.isColumn;

  // @override
  // bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // super.build(context);
    return BlocProvider(
      create: (context) => PictureBloc()..add(GetPicture(widget.pictureInfo)),
      child: SizedBox(
        width: context.screenWidth,
        child: BlocBuilder<PictureBloc, PictureLoadState>(
          builder: (context, state) {
            switch (state.status) {
              case PictureLoadStatus.initial:
                return Container(
                  color: isColumn ? Color(0xFF2D2D2D) : Colors.black,
                  width: context.screenWidth,
                  height: context.screenWidth,
                  child: Center(
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        fontFamily: 'Pacifico-Regular',
                        color: isColumn ? Color(0xFFCCCCCC) : Colors.white,
                        fontSize: 150,
                      ),
                    ),
                  ),
                );
              case PictureLoadStatus.success:
                return GestureDetector(
                  onLongPress: () {
                    context.pushRoute(
                      FullRouteImageRoute(imagePath: state.imagePath!),
                    );
                  },
                  child: ImageDisplay(
                    imagePath: state.imagePath!,
                    isColumn: isColumn,
                  ),
                );
              case PictureLoadStatus.failure:
                if (state.result.toString().contains('404')) {
                  return SizedBox(
                    height: context.screenWidth,
                    width: context.screenWidth,
                    child: Image.asset(
                      'asset/image/error_image/404.png',
                      fit: BoxFit.fill,
                    ),
                  );
                } else {
                  return Container(
                    color: isColumn ? Color(0xFF2D2D2D) : Colors.black,
                    height: context.screenWidth,
                    width: context.screenWidth,
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
}
