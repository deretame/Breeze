import 'dart:io';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/comic_info/json/eps/eps.dart' as eps;
import 'package:zephyr/page/comic_read/comic_read.dart';

import '../../../config/global.dart';
import '../../../widgets/full_screen_image_view.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';

@RoutePage()
class ComicReadPage extends StatelessWidget {
  final List<eps.Doc> epsInfo;
  final int epsId;
  final String comicId;

  const ComicReadPage({
    super.key,
    required this.epsInfo,
    required this.epsId,
    required this.comicId,
  });

  @override
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PageBloc()..add(GetPage(comicId, epsId)),
      child: _ComicReadPage(
        epsInfo: epsInfo,
        epsId: epsId,
        comicId: comicId,
      ),
    );
  }
}

class _ComicReadPage extends StatefulWidget {
  final List<eps.Doc> epsInfo;
  final int epsId;
  final String comicId;

  const _ComicReadPage({
    required this.epsInfo,
    required this.epsId,
    required this.comicId,
  });

  @override
  State<_ComicReadPage> createState() => _ComicReadPageState();
}

class _ComicReadPageState extends State<_ComicReadPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<eps.Doc> get epsInfo => widget.epsInfo;

  int get epsId => widget.epsId;

  String get comicId => widget.comicId;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: BlocBuilder<PageBloc, PageState>(
        builder: (context, state) {
          switch (state.status) {
            case PageStatus.initial:
              return const Center(child: CircularProgressIndicator());
            case PageStatus.failure:
              // 使用 addPostFrameCallback 确保在构建完成后再显示对话框
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showErrorDialog(context, state.result.toString());
              });
              return const SizedBox.shrink();
            case PageStatus.success:
              return ListView.builder(
                itemCount: state.medias!.length + 1, // 增加 1 以显示额外的 Container
                itemBuilder: (context, index) {
                  if (index < state.medias!.length) {
                    // 返回正常的 _ImageWidget
                    return _ImageWidget(
                      media: state.medias![index],
                      comicId: comicId,
                      epsId: epsId,
                      index: index,
                    );
                  } else {
                    // 返回加载完毕后的 Container
                    return Container(
                      padding: EdgeInsets.all(16.0),
                      alignment: Alignment.center,
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          "章节结束",
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    );
                  }
                },
              );
          }
        },
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('加载失败'),
          content: SingleChildScrollView(
            child: Text(errorMessage),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('重新加载'),
              onPressed: () {
                context.read<PageBloc>().add(GetPage(comicId, epsId));
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class _ImageWidget extends StatefulWidget {
  final String comicId;
  final int epsId;
  final Media media;
  final int index;

  const _ImageWidget({
    required this.media,
    required this.comicId,
    required this.epsId,
    required this.index,
  });

  @override
  State<_ImageWidget> createState() => _ImageWidgetState();
}

class _ImageWidgetState extends State<_ImageWidget>
    with AutomaticKeepAliveClientMixin {
  String get comicId => widget.comicId;

  int get epsId => widget.epsId;

  Media get media => widget.media;

  int get index => widget.index;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (context) => PictureBloc()
        ..add(
          GetPicture(
            PictureInfo(
              from: "bika",
              url: media.fileServer,
              path: media.path,
              cartoonId: comicId,
              pictureType: "comic",
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
                      index.toString(),
                      style: TextStyle(
                        fontFamily: 'Pacifico-Regular',
                        color: Color(0xFFCCCCCC),
                        fontSize: 150,
                      ),
                    ),
                  ),
                );
              case PictureLoadStatus.success:
                return SizedBox(
                  width: screenWidth,
                  child: InkWell(
                    onLongPress: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              FullScreenImageView(imagePath: state.imagePath!),
                        ),
                      );
                    },
                    child: Hero(
                      tag: state.imagePath!,
                      child: ClipRRect(
                        child: Image.file(
                          File(state.imagePath!),
                        ),
                      ),
                    ),
                  ),
                );
              case PictureLoadStatus.failure:
                if (state.result.toString().contains('404')) {
                  return SizedBox(
                    height: screenWidth,
                    width: screenWidth,
                    child: Image.asset('asset/image/error_image/404.png'),
                  );
                } else {
                  return SizedBox(
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
                                ),
                              ),
                            );
                      },
                      child: Center(
                        child: SizedBox(
                          height: screenWidth, // 或者使用具体的高度
                          width: screenWidth, // 或者使用具体的宽度
                          child: Center(
                            child: Text(
                              "${state.result.toString()}\n加载失败，点击重试",
                              style: TextStyle(fontSize: 20),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
