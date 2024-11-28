import 'dart:async';
import 'dart:io';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_info/json/eps/eps.dart' as eps;
import 'package:zephyr/page/comic_read/comic_read.dart';

import '../../../config/global.dart';
import '../../../object_box/model.dart';
import '../../../object_box/objectbox.g.dart';
import '../../../widgets/full_screen_image_view.dart';
import '../../../widgets/picture_bloc/bloc/picture_bloc.dart';
import '../../../widgets/picture_bloc/models/picture_info.dart';
import '../../comic_info/json/comic_info/comic_info.dart';

@RoutePage()
class ComicReadPage extends StatelessWidget {
  final Comic comicInfo;
  final List<eps.Doc> epsInfo;
  final eps.Doc doc;
  final String comicId;
  final bool? isHistory;

  const ComicReadPage({
    super.key,
    required this.comicInfo,
    required this.epsInfo,
    required this.doc,
    required this.comicId,
    required this.isHistory,
  });

  @override
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PageBloc()..add(GetPage(comicId, doc.order)),
      child: _ComicReadPage(
        comicInfo: comicInfo,
        epsInfo: epsInfo,
        doc: doc,
        comicId: comicId,
        isHistory: isHistory,
      ),
    );
  }
}

class _ComicReadPage extends StatefulWidget {
  final Comic comicInfo;
  final List<eps.Doc> epsInfo;
  final eps.Doc doc;
  final String comicId;
  final bool? isHistory;

  const _ComicReadPage({
    required this.comicInfo,
    required this.epsInfo,
    required this.doc,
    required this.comicId,
    required this.isHistory,
  });

  @override
  State<_ComicReadPage> createState() => _ComicReadPageState();
}

class _ComicReadPageState extends State<_ComicReadPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Comic get comicInfo => widget.comicInfo;

  List<eps.Doc> get epsInfo => widget.epsInfo;

  eps.Doc get doc => widget.doc;

  String get comicId => widget.comicId;

  late final ItemScrollController _itemScrollController;
  late final ItemPositionsListener _itemPositionsListener;
  late BikaComicHistory? comicHistory;
  late final int? comicHistoryId;
  DateTime? _lastUpdateTime; // 记录上次更新时间
  bool _isInserting = false; // 检测数据插入状态
  int index = 0;
  bool _hasScrolled = false; // 跳转标志
  late Timer _timer; // 定时器
  bool _isTimerFinished = false; // 定时器是否完成的标志

  @override
  void initState() {
    super.initState();
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();

    _itemPositionsListener.itemPositions.addListener(() {
      if (_itemPositionsListener.itemPositions.value.isNotEmpty) {
        getTopThirdItemIndex();
      }
    });

    // 首先查询一下有没有记录
    final query =
        objectbox.bikaBox.query(BikaComicHistory_.comicId.equals(comicId));
    comicHistory = query.build().findFirst();
    // 如果没有记录就先插入一条记录
    if (comicHistory == null) {
      comicHistory = comicToBikaComicHistory(comicInfo, doc.order);
      // 获取到数据库的唯一id
      comicHistoryId = objectbox.bikaBox.put(comicHistory!);
    } else {
      // 获取id
      comicHistoryId = comicHistory!.id;
    }
    debugPrint('comicHistoryId: $comicHistoryId');

    // final temp = objectbox.bikaBox.getAll();
    // for (final item in temp) {
    //   debugPrint('item: ${item.toString()}');
    // }
  }

  @override
  void dispose() {
    _timer.cancel(); // 确保在 dispose 时取消定时器
    _itemPositionsListener.itemPositions
        .removeListener(() => getTopThirdItemIndex());
    super.dispose();
  }

  Future<void> getTopThirdItemIndex() async {
    // 如果定时器还没完成，直接返回
    if (!_isTimerFinished) {
      return;
    }

    // 检查时间间隔
    if (_lastUpdateTime != null &&
        DateTime.now().difference(_lastUpdateTime!).inMilliseconds < 100) {
      return; // 如果还没到100毫秒，直接返回
    }
    if (_isInserting) {
      return; // 如果正在插入数据，直接返回
    }

    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final viewportHeight = MediaQuery.of(context).size.height;
    final topThird = viewportHeight / 3;

    ItemPosition? closestPosition;
    double minDistance = double.infinity;
    for (final position in positions) {
      final itemMiddle =
          (position.itemLeadingEdge + position.itemTrailingEdge) / 2;
      final distance = (topThird - itemMiddle).abs(); // 使用 bottomThird
      if (distance < minDistance) {
        minDistance = distance;
        closestPosition = position;
      }
    }

    debugPrint('Top third item index: ${closestPosition?.index}');

    if (closestPosition != null) {
      // 更新记录
      index = closestPosition.index;
      // 检查数据插入是否完成
      _isInserting = true; // 开始插入
      comicHistory!.history = DateTime.now().toUtc();
      comicHistory!.order = doc.order;
      comicHistory!.epPageCount = closestPosition.index;
      comicHistory!.epTitle = doc.title;
      await objectbox.bikaBox.putAsync(comicHistory!); // 异步写入

      // 设置状态为插入完成
      _isInserting = false;
      _lastUpdateTime = DateTime.now(); // 更新最后更新时间
    }
  }

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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showErrorDialog(context, state.result.toString());
              });
              return const SizedBox.shrink();
            case PageStatus.success: // 确保只执行一次跳转
              // 启动定时器，1秒后设置 _isTimerFinished 为 true
              _timer = Timer(const Duration(seconds: 1), () {
                setState(() {
                  _isTimerFinished = true; // 设置定时器完成
                });
              });
              if (!_hasScrolled &&
                  widget.isHistory == true &&
                  (comicHistory!.epPageCount - 1 != 0)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _itemScrollController.scrollTo(
                    index: comicHistory!.epPageCount - 1,
                    alignment: 0.0,
                    duration: const Duration(milliseconds: 500),
                  );
                  _hasScrolled = true; // 设置标志为已跳转
                });
              }
              return InteractiveViewer(
                minScale: 1.0,
                maxScale: 3.0,
                child: ScrollablePositionedList.builder(
                  itemCount: state.medias!.length + 1,
                  itemBuilder: (context, index) {
                    if (index < state.medias!.length) {
                      return _ImageWidget(
                        media: state.medias![index],
                        comicId: comicId,
                        epsId: doc.order,
                        index: index,
                      );
                    } else {
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
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                ),
              );
          }
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: const Icon(Icons.arrow_upward),
      //   onPressed: () {
      //     _itemScrollController.scrollTo(
      //       index: 300,
      //       alignment: 0.0,
      //       duration: const Duration(milliseconds: 500),
      //     );
      //   },
      // ),
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
                context.read<PageBloc>().add(GetPage(comicId, doc.order));
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
                return GestureDetector(
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
                    child: _ImageDisplay(imagePath: state.imagePath!),
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
                          height: screenWidth,
                          width: screenWidth,
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

class _ImageDisplay extends StatefulWidget {
  final String imagePath;

  const _ImageDisplay({required this.imagePath});

  @override
  State<_ImageDisplay> createState() => _ImageDisplayState();
}

class _ImageDisplayState extends State<_ImageDisplay> {
  double? imageWidth;
  double? imageHeight;

  @override
  void initState() {
    super.initState();
    _getImageResolution(widget.imagePath);
  }

  Future<void> _getImageResolution(String imagePath) async {
    final Completer<void> completer = Completer();
    final Image image = Image.file(File(imagePath));

    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo imageInfo, _) {
        setState(() {
          imageWidth = imageInfo.image.width.toDouble();
          imageHeight = imageInfo.image.height.toDouble();
        });
        completer.complete();
      }),
    );

    await completer.future; // 等待解析完成
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth,
      height: imageHeight != null
          ? (imageHeight! * (screenWidth / imageWidth!))
          : null, // 动态计算高度
      child: imageWidth != null && imageHeight != null
          ? Image.file(File(widget.imagePath))
          : Container(color: Colors.grey[300]), // 占位符
    );
  }
}
