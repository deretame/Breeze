import 'dart:async';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../widgets/comic_entry/comic_entry.dart';
import '../../comic_info/json/comic_info/comic_info.dart';
import '../../download/json/comic_all_info_json/comic_all_info_json.dart'
    as comic_all_info_json;

@RoutePage()
class ComicReadPage extends StatelessWidget {
  final Comic comicInfo;
  final List<eps.Doc> epsInfo;
  final eps.Doc doc;
  final String comicId;
  final ComicEntryType? type;

  const ComicReadPage({
    super.key,
    required this.comicInfo,
    required this.epsInfo,
    required this.doc,
    required this.comicId,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PageBloc()..add(GetPage(comicId, doc.order)),
      child: _ComicReadPage(
        comicInfo: comicInfo,
        epsInfo: epsInfo,
        doc: doc,
        comicId: comicId,
        type: type,
      ),
    );
  }
}

class _ComicReadPage extends StatefulWidget {
  final Comic comicInfo;
  final List<eps.Doc> epsInfo;
  final eps.Doc doc;
  final String comicId;
  final ComicEntryType? type;

  const _ComicReadPage({
    required this.comicInfo,
    required this.epsInfo,
    required this.doc,
    required this.comicId,
    this.type,
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

  ComicEntryType? get type => widget.type;
  late final ComicEntryType _type;
  late final comic_all_info_json.Eps _downloadEpsInfo;
  late eps.Doc _doc;
  late bool isSkipped = false; // 是否跳转过
  late final ItemScrollController _itemScrollController;
  late final ItemPositionsListener _itemPositionsListener;
  late BikaComicHistory? comicHistory; // 记录阅读记录
  DateTime? _lastUpdateTime; // 记录上次更新时间
  bool _isInserting = false; // 检测数据插入状态
  int pageIndex = 0; // 当前页数
  String epPages = ""; // 章节总页数
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
  OverlayEntry? _overlayEntry; // 用于存储 OverlayEntry

  @override
  void initState() {
    super.initState();
    _currentSliderValue = 0;
    _type = type ?? ComicEntryType.normal;
    _doc = doc;
    // 隐藏状态栏
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();

    _itemPositionsListener.itemPositions.addListener(() {
      if (_itemPositionsListener.itemPositions.value.isNotEmpty) {
        final positions = _itemPositionsListener.itemPositions.value;
        getTopThirdItemIndex(positions);
        _detectScrollDirection(positions);
      }
    });

    // 首先查询一下有没有记录
    final query = objectbox.bikaHistoryBox
        .query(BikaComicHistory_.comicId.equals(comicId));
    comicHistory = query.build().findFirst();
    // 如果没有记录就先插入一条记录
    if (comicHistory == null) {
      comicHistory = comicToBikaComicHistory(comicInfo, _doc.order);
      objectbox.bikaHistoryBox.put(comicHistory!);
    }

    if (_type == ComicEntryType.download ||
        _type == ComicEntryType.historyAndDownload) {
      // 首先查询一下有没有记录
      var temp = objectbox.bikaDownloadBox
          .query(BikaComicDownload_.comicId.equals(comicId))
          .build()
          .findFirst()!
          .comicInfoAll;
      var temp2 = comic_all_info_json.comicAllInfoJsonFromJson(temp);
      _downloadEpsInfo = temp2.eps;
    }

    debugPrint(_type.toString().split('.').last);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _overlayEntry?.remove(); // 移除 Overlay
    _sliderIsRollingTimer?.cancel(); // 取消定时器
    comicRollingTimer?.cancel(); // 取消滚动定时器
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: _type == ComicEntryType.download ||
              _type == ComicEntryType.historyAndDownload
          ? SafeArea(
              top: false,
              bottom: false,
              child: _successWidget(null),
            )
          : BlocBuilder<PageBloc, PageState>(
              builder: (context, state) {
                switch (state.status) {
                  case PageStatus.initial:
                    return const Center(child: CircularProgressIndicator());
                  case PageStatus.failure:
                    return _failureWidget(state);
                  case PageStatus.success:
                    // return _successWidget(state);
                    return SafeArea(
                      top: false,
                      bottom: false,
                      child: _successWidget(state),
                    );
                }
              },
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
              context.read<PageBloc>().add(GetPage(comicId, _doc.order));
            },
            child: Text('点击重试'),
          ),
        ],
      ),
    );
  }

  Widget _successWidget(PageState? state) {
    // debugPrint(_currentSliderValue.toString());
    if (_isVisible == false) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
    var length = 0;
    List<Media> medias = [];
    if (state != null) {
      length = state.medias!.length;
      epPages = state.result!;
      medias = state.medias!;
    } else {
      try {
        var temp =
            _downloadEpsInfo.docs.firstWhere((e) => e.order == _doc.order);
        _doc = eps.Doc(
          id: temp.id,
          title: temp.title,
          order: temp.order,
          updatedAt: temp.updatedAt,
          docId: temp.docId,
        );
        medias = temp.pages.docs.map((e) {
          return Media(
            originalName: e.media.originalName,
            path: e.media.path,
            fileServer: e.media.fileServer,
          );
        }).toList();
        length = temp.pages.docs.length;
        epPages = temp.pages.docs.length.toString();
      } catch (e) {
        return Center(
          child: Text(
            '章节未下载',
            style: TextStyle(fontSize: 20),
          ),
        );
      }
    }
    // 在成功加载状态下设置 _totalSlots
    if (_totalSlots == 0) {
      _totalSlots = length;
    }

    // 处理滚动到历史记录
    if ((_type == ComicEntryType.history ||
            _type == ComicEntryType.historyAndDownload) &&
        (comicHistory!.epPageCount - 1 != 0) &&
        isSkipped == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _itemScrollController.scrollTo(
          index: comicHistory!.epPageCount - 1,
          alignment: 0.0,
          duration: const Duration(milliseconds: 500),
        );
      });
    }
    isSkipped = true;

    // debugPrint('statusBarHeight : $statusBarHeight');
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isVisible = !_isVisible;
              debugPrint('状态栏可见性：$_isVisible');
              if (_isVisible) {
                SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              }
            });
          },
          child: InteractiveViewer(
            boundaryMargin: EdgeInsets.zero,
            minScale: 1.0,
            maxScale: 4.0,
            child: ScrollablePositionedList.builder(
              itemCount: length + 2,
              itemBuilder: (context, index) {
                // debugPrint('index: $index');
                // debugPrint('itemCount: ${state.medias!.length + 2}');
                if (index == 0) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: screenWidth,
                    ),
                    child: Container(
                      height: statusBarHeight,
                      decoration: BoxDecoration(color: Color(0xFF2D2D2D)),
                    ),
                  );
                } else if (index == length + 1) {
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: screenWidth,
                    ),
                    child: Container(
                      height: 75,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Color(0xFF2D2D2D)),
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
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: screenWidth,
                    ),
                    child: ReadImageWidget(
                      media: medias[index - 1],
                      comicId: comicId,
                      epsId: _doc.id,
                      index: index - 1,
                      chapterId: _doc.docId,
                    ),
                  );
                }
              },
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
            ),
          ),
        ),
        ComicReadAppBar(
          title: _doc.title,
          isVisible: _isVisible,
          onThemeModeChanged: () {
            globalSetting.setThemeMode(0);
          },
        ),
        // _pageCountWidget(),
        PageCountWidget(
          pageIndex: pageIndex,
          epPages: epPages,
        ),
        _bottomWidget(),
        // _bottomButton(),
      ],
    );
  }

  Widget _bottomWidget() {
    final router = AutoRouter.of(context);
    ComicEntryType tempType = _type;
    if (_type == ComicEntryType.historyAndDownload) {
      tempType = ComicEntryType.download;
    }
    if (_type == ComicEntryType.history) {
      tempType = ComicEntryType.normal;
    }
    return Observer(builder: (context) {
      return AnimatedPositioned(
        duration: _animationDuration,
        bottom: _isVisible ? 0 : -_bottomWidgetHeight.toDouble(),
        left: 0,
        right: 0,
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // 高斯模糊强度
            child: Container(
              height: _bottomWidgetHeight.toDouble(),
              width: screenWidth,
              color: globalSetting.backgroundColor.withValues(alpha: 0.5),
              // 半透明背景
              child: Column(
                children: [
                  Row(
                    children: [
                      SizedBox(width: 10),
                      GestureDetector(
                        child: Text("上一章"),
                        onTap: () async {
                          if (_doc.order == epsInfo[0].order) {
                            EasyLoading.showInfo("已经是第一章了");
                            return;
                          }
                          final result = await _bottomButtonDialog(
                            context,
                            '跳转',
                            '是否要跳转到上一章？',
                            epsInfo[_doc.order - 2],
                          );
                          if (result && mounted) {
                            router.popAndPush(
                              ComicReadRoute(
                                comicInfo: comicInfo,
                                epsInfo: epsInfo,
                                doc: epsInfo[_doc.order - 2],
                                comicId: comicInfo.id,
                                type: tempType,
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
                          if (_doc.order == epsInfo[epsInfo.length - 1].order) {
                            EasyLoading.showInfo("已经是最后一章了");
                            return;
                          }

                          final result = await _bottomButtonDialog(
                            context,
                            '跳转',
                            '是否要跳转到下一章？',
                            epsInfo[_doc.order],
                          );
                          if (result) {
                            router.popAndPush(
                              ComicReadRoute(
                                comicInfo: comicInfo,
                                epsInfo: epsInfo,
                                doc: epsInfo[_doc.order],
                                comicId: comicInfo.id,
                                type: tempType,
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
                      width: screenWidth * 48 / 50,
                      color: globalSetting.themeType
                          ? materialColorScheme.secondaryFixedDim
                          : materialColorScheme.secondaryFixedDim,
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
                                                Navigator.of(context)
                                                    .pop(ep.order);
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
                            if (result != null && mounted) {
                              router.popAndPush(
                                ComicReadRoute(
                                  comicInfo: comicInfo,
                                  epsInfo: epsInfo,
                                  doc: epsInfo[result - 1],
                                  comicId: comicInfo.id,
                                  type: tempType,
                                ),
                              );
                            }
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
          ),
        ),
      );
    });
  }

  Widget _sliderWidget() {
    double maxValue = 0;
    if (maxValue == 0) {
      maxValue = _totalSlots.toDouble() - 1;
    }
    return Expanded(
      child: Slider(
        value: _currentSliderValue,
        min: 0,
        max: maxValue,
        label: (_currentSliderValue.toInt() + 1).toString(),
        onChanged: (double newValue) {
          if (_currentSliderValue.toInt() != newValue.toInt()) {
            setState(() {
              _currentSliderValue = newValue;
            });
          }
          _isSliderRolling = true;
          _sliderIsRollingTimer?.cancel();

          // 显示 Overlay 提示框
          _showOverlayToast((newValue.toInt() + 1).toString());

          // 设置新的定时器以防止多次触发
          _sliderIsRollingTimer = Timer(const Duration(milliseconds: 300), () {
            setState(() {
              _isSliderRolling = false;
              displayedSlot = newValue.toInt() + 1;

              _isComicRolling = true;
              _isSliderRolling = true;
              comicRollingTimer = Timer(const Duration(milliseconds: 350), () {
                setState(() {
                  _isComicRolling = false;
                  _isSliderRolling = false;
                });

                // 移除 Overlay 提示框
                _overlayEntry?.remove();
                _overlayEntry = null;
              });

              // 滚动到指定的索引
              _itemScrollController.scrollTo(
                index: _currentSliderValue.toInt() + 1,
                alignment: 0.0,
                duration: const Duration(milliseconds: 300),
              );
            });

            debugPrint('滑块值：$newValue , 显示的槽位：$displayedSlot');
          });
        },
      ),
    );
  }

  void _showOverlayToast(String message) {
    // 移除之前的 Overlay
    _overlayEntry?.remove();

    // 创建新的 OverlayEntry
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // 提示信息
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
                    decoration: BoxDecoration(
                      color: materialColorScheme.surfaceBright
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 60,
                        color: globalSetting.textColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    // 插入 Overlay
    Overlay.of(context).insert(_overlayEntry!);
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
                  child: Text('取消'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // 返回 false
                  },
                ),
                TextButton(
                  child: Text('确定'),
                  onPressed: () {
                    Navigator.of(context).pop(true); // 返回 true
                  },
                ),
              ],
            );
          },
        ) ??
        false; // 处理返回值为空的情况
  }

  Future<void> updateIndex(Iterable<ItemPosition> positions) async {
    if (positions.isEmpty) return;

    // 提前计算屏幕的三分之一位置
    final viewportHeight = MediaQuery.of(context).size.height;
    final topThird = viewportHeight / 3 + statusBarHeight;

    // 找到最接近的项
    final closestPosition = _findClosestPosition(positions, topThird);

    // 更新索引
    if (closestPosition != null &&
        mounted &&
        !_isSliderRolling &&
        pageIndex != closestPosition.index) {
      debugPrint('更新索引：$pageIndex');

      setState(() {
        pageIndex = closestPosition.index;
        if (!_isComicRolling) {
          _currentSliderValue = pageIndex - 2;
        }
      });
    }
  }

  /// 找到最接近屏幕三分之一位置的项
  ItemPosition? _findClosestPosition(
      Iterable<ItemPosition> positions, double topThird) {
    ItemPosition? closestPosition;
    double minDistance = double.infinity;

    for (final position in positions) {
      // 计算项的中心位置
      final itemHeight = position.itemTrailingEdge - position.itemLeadingEdge;
      final itemMiddle = position.itemLeadingEdge + itemHeight / 2;
      final distance = (topThird - itemMiddle).abs();

      // 找到距离最小的项
      if (distance < minDistance) {
        minDistance = distance;
        closestPosition = position;
      }
    }

    return closestPosition;
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
    comicHistory!.order = _doc.order;
    comicHistory!.epPageCount = pageIndex;
    comicHistory!.epTitle = _doc.title;
    await objectbox.bikaHistoryBox.putAsync(comicHistory!);
    _isInserting = false;
    _lastUpdateTime = DateTime.now();
  }

  Future<void> getTopThirdItemIndex(Iterable<ItemPosition> positions) async {
    await updateIndex(positions);
    await writeToDatabase();
  }

  void _detectScrollDirection(Iterable<ItemPosition> positions) {
    if (positions.isNotEmpty) {
      // 获取当前滚动的第一个索引
      final firstItemIndex = positions.first.index;

      // 判断是否有滚动
      if (firstItemIndex != _lastScrollIndex && !_isSliderRolling) {
        debugPrint('滚动检测：隐藏组件');
        setState(() {
          _isVisible = false; // 只要滚动了就隐藏组件
        });
      }

      // 更新记录的滚动索引
      _lastScrollIndex = firstItemIndex;
    }
  }
}
