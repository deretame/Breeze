import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comic_read/comic_read.dart';

import '../../../config/global.dart';
import '../../../widgets/full_screen_image_view.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';

class ReadImageWidget extends StatefulWidget {
  final String comicId;
  final String epsId;
  final Media media;
  final int index;
  final String chapterId;

  const ReadImageWidget({
    super.key,
    required this.media,
    required this.comicId,
    required this.epsId,
    required this.index,
    required this.chapterId,
  });

  @override
  State<ReadImageWidget> createState() => _ReadImageWidgetState();
}

class _ReadImageWidgetState extends State<ReadImageWidget>
    with AutomaticKeepAliveClientMixin {
  String get comicId => widget.comicId;

  String get epsId => widget.epsId;

  Media get media => widget.media;

  int get index => widget.index;

  String get chapterId => widget.chapterId;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create:
          (context) =>
              PictureBloc()..add(
                GetPicture(
                  PictureInfo(
                    from: "bika",
                    url: media.fileServer,
                    path: media.path,
                    cartoonId: comicId,
                    pictureType: "comic",
                    chapterId: chapterId,
                  ),
                ),
              ),
      child: SizedBox(
        width: screenWidth,
        child: BlocBuilder<PictureBloc, PictureLoadState>(
          builder: (context, state) {
            switch (state.status) {
              case PictureLoadStatus.initial:
                return Container(
                  color: Color(0xFF2D2D2D),
                  width: screenWidth,
                  height: screenWidth,
                  child: Center(
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        fontFamily: 'Pacifico-Regular',
                        color: Color(0xFFCCCCCC),
                        fontSize: 150,
                      ),
                    ),
                  ),
                );
              case PictureLoadStatus.success:
                return GestureDetector(
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => FullScreenImageView(
                              imagePath: state.imagePath!,
                              showShade: true,
                            ),
                      ),
                    );
                  },
                  // child: Hero(
                  //   tag: state.imagePath!,
                  child: ImageDisplay(imagePath: state.imagePath!),
                  // ),
                );
              case PictureLoadStatus.failure:
                if (state.result.toString().contains('404')) {
                  return SizedBox(
                    height: screenWidth,
                    width: screenWidth,
                    child: Image.asset('asset/image/error_image/404.png'),
                  );
                } else {
                  return Container(
                    color: Color(0xFF2D2D2D),
                    height: screenWidth,
                    width: screenWidth,
                    child: InkWell(
                      onTap: () {
                        context.read<PictureBloc>().add(
                          GetPicture(
                            PictureInfo(
                              from: "bika",
                              url: media.fileServer,
                              path: media.path,
                              cartoonId: comicId,
                              pictureType: "comic",
                              chapterId: chapterId,
                            ),
                          ),
                        );
                      },
                      child: Center(
                        child: Text(
                          "${state.result.toString()}\n加载失败，点击重试",
                          style: TextStyle(
                            fontSize: 20,
                            color: Color(0xFFCCCCCC),
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
