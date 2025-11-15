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
  final _sizeCache = ImageSizeCache();

  int get index => widget.index;
  bool get isColumn => widget.isColumn;

  /// 生成缓存 key（基于 PictureInfo）
  String get _cacheKey {
    final info = widget.pictureInfo;
    return '${info.cartoonId}_${info.chapterId}_${info.path}';
  }

  /// 计算占位高度
  double _getPlaceholderHeight(BuildContext context) {
    final cachedSize = _sizeCache.getSize(_cacheKey);
    if (cachedSize != null && cachedSize.width > 0) {
      // 根据缓存的尺寸计算高度
      return cachedSize.height * (context.screenWidth / cachedSize.width);
    }

    // 默认使用正方形占位
    return context.screenWidth;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PictureBloc()..add(GetPicture(widget.pictureInfo)),
      child: SizedBox(
        width: context.screenWidth,
        child: BlocBuilder<PictureBloc, PictureLoadState>(
          builder: (context, state) {
            switch (state.status) {
              case PictureLoadStatus.initial:
                // 使用缓存的高度作为占位高度
                final placeholderHeight = _getPlaceholderHeight(context);

                return Container(
                  color: isColumn ? Color(0xFF2D2D2D) : Colors.black,
                  width: context.screenWidth,
                  height: placeholderHeight,
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
                    cacheKey: _cacheKey,
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
