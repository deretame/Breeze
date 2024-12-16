import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_info/json/eps/eps.dart' as eps;
import 'package:zephyr/page/comic_read/comic_read.dart';

import '../../../config/global.dart';
import '../../../object_box/model.dart';
import '../../../object_box/objectbox.g.dart';
import '../../../util/router/router.gr.dart';
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
  late BikaComicHistory? comicHistory; // 记录阅读记录
  DateTime? _lastUpdateTime; // 记录上次更新时间
  bool _isInserting = false; // 检测数据插入状态
  int pageIndex = 0; // 当前页数
  String epPages = ""; // 章节总页数
  bool _hasScrolled = false; // 跳转标志
  bool _isVisible = true; // 控制 AppBar 和 BottomAppBar 的可见性
  final Duration _animationDuration = const Duration(milliseconds: 300); // 动画时长
  late int _lastScrollIndex = -1; // 用于记录上次滚动的索引
  final int _bottomWidgetHeight = 100; // 底部悬浮组件高度
  double _currentSliderValue = 0; // 当前滑块的值
  int _totalSlots = 0; // 总槽位数量
  int displayedSlot = 1; // 显示的当前槽位
  Timer? _sliderIsRollingTimer; // 用来控制滚动隐藏组件的操作
  bool _isSliderRolling = false; // 滑块是否在滑动
  Timer? comicRollingTimer; // 漫画本身是否在滚动
  bool _isComicRolling = false; // 漫画本身是否在滚动

  @override
  void initState() {
    super.initState();
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();

    _itemPositionsListener.itemPositions.addListener(() {
      if (_itemPositionsListener.itemPositions.value.isNotEmpty) {
        getTopThirdItemIndex();
        _detectScrollDirection();
      }
    });

    // 首先查询一下有没有记录
    final query =
        objectbox.bikaBox.query(BikaComicHistory_.comicId.equals(comicId));
    comicHistory = query.build().findFirst();
    // 如果没有记录就先插入一条记录
    if (comicHistory == null) {
      comicHistory = comicToBikaComicHistory(comicInfo, doc.order);
      objectbox.bikaBox.put(comicHistory!);
    }
  }

  @override
  void dispose() {
    // 在 dispose 中恢复状态栏可见性
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _itemPositionsListener.itemPositions
        .removeListener(() => getTopThirdItemIndex());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Color(0xFFD3D3D3)),
        child: BlocBuilder<PageBloc, PageState>(
          builder: (context, state) {
            switch (state.status) {
              case PageStatus.initial:
                return const Center(child: CircularProgressIndicator());
              case PageStatus.failure:
                return _failureWidget(state);
              case PageStatus.success:
                return _successWidget(state);
            }
          },
        ),
      ),
    );
  }

  Widget _failureWidget(PageState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${state.result.toString()}\n加载失败',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              context.read<PageBloc>().add(GetPage(comicId, doc.order));
            },
            child: Text('点击重试'),
          ),
        ],
      ),
    );
  }

  Widget _successWidget(PageState state) {
    epPages = state.result!;
    // 在成功加载状态下设置 _totalSlots
    if (_totalSlots == 0) {
      _totalSlots = state.medias!.length;
    }

    // 处理滚动到历史记录
    if (!_hasScrolled &&
        widget.isHistory == true &&
        (comicHistory!.epPageCount - 1 != 0)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _itemScrollController.scrollTo(
          index: comicHistory!.epPageCount - 1,
          alignment: 0.0,
          duration: const Duration(milliseconds: 500),
        );
        _hasScrolled = true;
      });
    }

    // debugPrint('statusBarHeight : $statusBarHeight');
    return Stack(
      children: [
        ScrollablePositionedList.builder(
          itemCount: state.medias!.length + 2,
          itemBuilder: (context, index) {
            // debugPrint('index: $index');
            // debugPrint('itemCount: ${state.medias!.length + 2}');
            if (index == 0) {
              return Container(
                height: statusBarHeight,
                decoration: BoxDecoration(color: Color(0xFF2D2D2D)),
              );
            } else if (index == state.medias!.length + 1) {
              return Container(
                padding: EdgeInsets.all(16.0),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Color(0xFF2D2D2D)),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "章节结束",
                    style: TextStyle(
                      fontSize: 20,
                      color: Color(0xFFCCCCCC),
                    ),
                  ),
                ),
              );
            } else {
              return _ImageWidget(
                media: state.medias![index - 1],
                comicId: comicId,
                epsId: doc.order,
                index: index - 1,
              );
            }
          },
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
        ),
        _appBarWidget(),
        _pageCountWidget(),
        _bottomWidget(),
        _bottomButton(),
      ],
    );
  }

  Widget _appBarWidget() {
    // 顶部悬浮组件
    return AnimatedPositioned(
      duration: _animationDuration,
      top: _isVisible ? 0 : -kToolbarHeight - statusBarHeight,
      // 隐藏时往上移动
      left: 0,
      right: 0,
      child: AppBar(
        title: Text(doc.title),
        backgroundColor: globalSetting.backgroundColor,
        elevation: _isVisible ? 4.0 : 0.0, // 添加阴影效果
        actions: <Widget>[
          Observer(builder: (context) {
            return IconButton(
              icon: globalSetting.themeMode == ThemeMode.system
                  ? Icon(Icons.brightness_auto_rounded)
                  : Icon(Icons.brightness_auto_outlined),
              onPressed: () {
                globalSetting.setThemeMode(0);
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _pageCountWidget() {
    return Positioned(
      bottom: 0, // 离底部的间距
      left: 0, // 离右边的间距
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: globalSetting.backgroundColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0), // 左上角保持直角
            topRight: Radius.circular(10), // 右上角设置圆角
            bottomLeft: Radius.circular(0), // 左下角保持直角
            bottomRight: Radius.circular(0), // 右下角保持直角
          ),
        ),
        child: Text(
          " ${pageIndex - 1}/$epPages", // 显示当前页数
          style: TextStyle(color: globalSetting.textColor),
        ),
      ),
    );
  }

  Widget _bottomWidget() {
    return Observer(builder: (context) {
      return AnimatedPositioned(
        duration: _animationDuration,
        bottom: _isVisible ? 0 : -_bottomWidgetHeight.toDouble(),
        left: 0,
        right: 0,
        child: Container(
          height: _bottomWidgetHeight.toDouble(),
          width: screenWidth,
          color: globalSetting.backgroundColor,
          child: Column(
            children: [
              Row(
                children: [
                  SizedBox(width: 10),
                  GestureDetector(
                    child: Text("上一章"),
                    onTap: () async {
                      if (doc.order == epsInfo[0].order) {
                        EasyLoading.showInfo("已经是第一章了");
                        return;
                      }
                      final result = await _bottomButtonDialog(
                        context,
                        '跳转',
                        '是否要跳转到上一章？',
                        epsInfo[doc.order - 2],
                      );
                      if (result && mounted) {
                        AutoRouter.of(context).popAndPush(
                          ComicReadRoute(
                            comicInfo: comicInfo,
                            epsInfo: epsInfo,
                            doc: epsInfo[doc.order - 2],
                            comicId: comicInfo.id,
                            isHistory: false,
                          ),
                        );
                      }
                    },
                  ),
                  _sliderWidget(),
                  GestureDetector(
                    child: Text("下一章"),
                    onTap: () async {
                      debugPrint('下一章');
                      if (doc.order == epsInfo[epsInfo.length - 1].order) {
                        EasyLoading.showInfo("已经是最后一章了");
                        return;
                      }

                      final result = await _bottomButtonDialog(
                        context,
                        '跳转',
                        '是否要跳转到下一章？',
                        epsInfo[doc.order],
                      );
                      if (result) {
                        if (!mounted) return;
                        AutoRouter.of(context).popAndPush(
                          ComicReadRoute(
                            comicInfo: comicInfo,
                            epsInfo: epsInfo,
                            doc: epsInfo[doc.order],
                            comicId: comicInfo.id,
                            isHistory: false,
                          ),
                        );
                      }
                    },
                  ),
                  SizedBox(width: 10),
                ],
              ),
              Center(
                child: Container(
                  height: 1, // 设置高度为1像素
                  width: screenWidth * 0.8,
                  color: globalSetting.themeType
                      ? Colors.grey.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
              Row(
                children: [
                  Spacer(),
                  Expanded(
                    child: Center(
                      child: IconButton(
                        icon: globalSetting.themeMode == ThemeMode.light
                            ? Icon(Icons.brightness_7)
                            : Icon(Icons.brightness_5_outlined),
                        onPressed: () {
                          globalSetting.setThemeMode(1);
                        },
                      ),
                    ),
                  ),
                  Spacer(),
                  SizedBox(
                    height: 51,
                    child: GestureDetector(
                      onTap: () async {
                        final result = await showDialog<int?>(
                            context: context,
                            barrierDismissible: false, // 不允许点击外部区域关闭对话框
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('选择章节'),
                                content: SingleChildScrollView(
                                  child: ListBody(
                                    children: [
                                      for (final ep in epsInfo)
                                        TextButton(
                                          child: Text(ep.title),
                                          onPressed: () {
                                            Navigator.of(context).pop(ep.order);
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: Text('取消'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            });
                        if (result == null) return;
                        if (mounted) return;
                        AutoRouter.of(context).popAndPush(
                          ComicReadRoute(
                            comicInfo: comicInfo,
                            epsInfo: epsInfo,
                            doc: epsInfo[result - 1],
                            comicId: comicInfo.id,
                            isHistory: false,
                          ),
                        );
                      },
                      child: Center(
                        child: Text(
                          '跳转章节',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: globalSetting.themeMode == ThemeMode.dark
                        ? Icon(Icons.brightness_2_rounded)
                        : Icon(Icons.brightness_2_outlined),
                    onPressed: () {
                      globalSetting.setThemeMode(2);
                    },
                  ),
                  Spacer(),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _sliderWidget() {
    return Expanded(
      // 使 Slider 占用剩余空间
      child: Slider(
        value: _currentSliderValue,
        min: 0,
        max: _totalSlots.toDouble(),
        divisions: _totalSlots,
        label: (_currentSliderValue.toInt() + 1).toString(),
        onChanged: (double newValue) {
          setState(() {
            _currentSliderValue = newValue; // 实时更新滑块值
            _sliderIsRollingTimer?.cancel(); // 取消之前的定时器
            _isSliderRolling = true; // 开始滑动状态
          });

          // 设置新的定时器以防止多次触发
          _sliderIsRollingTimer = Timer(const Duration(milliseconds: 300), () {
            setState(() {
              _isSliderRolling = false; // 停止滑动状态
              // 更新显示的槽位
              displayedSlot = newValue.toInt() + 1;

              _isComicRolling = true; // 开始滚动状态
              _isSliderRolling = true; // 开始滑动状态
              comicRollingTimer = Timer(const Duration(milliseconds: 350), () {
                setState(() {
                  _isComicRolling = false; // 停止滚动状态
                  _isSliderRolling = false;
                });
              });

              // 滚动到指定的索引
              _itemScrollController.scrollTo(
                index: _currentSliderValue.toInt() + 1,
                alignment: 0.0,
                duration: const Duration(milliseconds: 300),
              );
            });

            // 打印调试信息
            debugPrint('滑块值：$newValue , 显示的槽位：$displayedSlot');
          });
        },
      ),
    );
  }

  Future<bool> _bottomButtonDialog(
    BuildContext context,
    String title,
    String content,
    eps.Doc doc,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false, // 不允许点击外部区域关闭对话框
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    Navigator.of(context).pop(true); // 返回 true
                  },
                ),
                TextButton(
                  child: Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // 返回 false
                  },
                ),
              ],
            );
          },
        ) ??
        false; // 处理返回值为空的情况
  }

  Widget _bottomButton() {
    // 底部悬浮按钮
    return AnimatedPositioned(
      duration: _animationDuration,
      bottom: _isVisible ? 10 + _bottomWidgetHeight.toDouble() : 10,
      // 隐藏时位置往上移动底部组件的高度
      right: 10,
      // 调整FloatingActionButton的位置
      child: FloatingActionButton(
        onPressed: toggleVisibility, // 点击时切换可见性
        child: const Icon(Icons.density_medium), // 更改按钮图标
      ),
    );
  }

  // 切换状态栏和AppBar的显示状态
  void toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  Future<void> updateIndex() async {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // final viewportHeight = MediaQuery.of(context).size.height;
    // final topThird = viewportHeight / 3;
    final topThird = 0 + statusBarHeight;

    ItemPosition? closestPosition;
    double minDistance = double.infinity;
    for (final position in positions) {
      final itemMiddle =
          (position.itemLeadingEdge + position.itemTrailingEdge) / 2;
      final distance = (topThird - itemMiddle).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closestPosition = position;
      }
    }

    if (closestPosition != null && mounted && _isSliderRolling == false) {
      if (pageIndex != closestPosition.index) {
        debugPrint('更新索引：$pageIndex');
      }
      setState(() {
        pageIndex = closestPosition!.index;
        if (_isComicRolling == false) {
          _currentSliderValue = pageIndex - 2;
        }
      });
    }
  }

  Future<void> writeToDatabase() async {
    if (_isInserting ||
        _lastUpdateTime != null &&
            DateTime.now().difference(_lastUpdateTime!).inMilliseconds < 100) {
      return;
    }
    // 更新记录
    _isInserting = true;
    comicHistory!.history = DateTime.now().toUtc();
    comicHistory!.order = doc.order;
    comicHistory!.epPageCount = pageIndex;
    comicHistory!.epTitle = doc.title;
    await objectbox.bikaBox.putAsync(comicHistory!);
    if (mounted) {
      // 添加 mounted 检查
      setState(() {
        _isInserting = false;
      });
    }
    _lastUpdateTime = DateTime.now();
  }

  Future<void> getTopThirdItemIndex() async {
    await updateIndex();
    await writeToDatabase();
  }

  void _detectScrollDirection() {
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      // 获取当前滚动的第一个和最后一个索引
      final firstItemIndex = positions.first.index;
      // final lastItemIndex = positions.last.index;

      if (firstItemIndex > _lastScrollIndex && _isSliderRolling == false) {
        // 向下滚动
        debugPrint('向下滚动');
        setState(() {
          _isVisible = false;
        });
      } else if (firstItemIndex < _lastScrollIndex &&
          _isSliderRolling == false) {
        // 向上滚动
        debugPrint('向上滚动');
        setState(() {
          _isVisible = false;
        });
      }

      // 更新记录的滚动索引
      _lastScrollIndex = firstItemIndex;
    }
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

  bool _isMounted = false; // 标志，指示 Widget 是否仍挂载

  @override
  void initState() {
    super.initState();
    _isMounted = true; // Widget 初始化时认为它是挂载的
    _getImageResolution(widget.imagePath);
  }

  Future<void> _getImageResolution(String imagePath) async {
    final Completer<void> completer = Completer();
    final Image image = Image.file(File(imagePath));

    // 监听图片解析完成
    image.image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo imageInfo, _) {
        // 只有在 Widget 仍挂载时才调用 setState
        if (_isMounted) {
          setState(() {
            imageWidth = imageInfo.image.width.toDouble();
            imageHeight = imageInfo.image.height.toDouble();
          });
        }
        completer.complete();
      }),
    );

    await completer.future; // 等待解析完成
  }

  @override
  void dispose() {
    _isMounted = false; // Widget 暴露时，设置为未挂载
    super.dispose();
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
          ? Image.file(
              File(widget.imagePath),
              fit: BoxFit.cover, // 使图片填充整个屏幕
            )
          : Container(color: Colors.grey[300]), // 占位符
    );
  }
}
