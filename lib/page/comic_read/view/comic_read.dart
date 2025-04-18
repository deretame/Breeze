import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_info/json/eps/eps.dart' as eps;
import 'package:zephyr/page/comic_read/comic_read.dart';

import '../../../object_box/model.dart';
import '../../../object_box/objectbox.g.dart';
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

class _ComicReadPageState extends State<_ComicReadPage> {
  Comic get comicInfo => widget.comicInfo;

  String get comicId => widget.comicId;

  String _epId = ""; // 用来存储当前观看的章节id
  late final ComicEntryType _type;
  late final comic_all_info_json.Eps _downloadEpsInfo;
  late eps.Doc _doc;
  late bool isSkipped = false; // 是否跳转过
  late final ItemScrollController _itemScrollController;
  late final ItemPositionsListener _itemPositionsListener;
  final PageController _pageController = PageController(initialPage: 0);
  late BikaComicHistory? comicHistory; // 记录阅读记录
  DateTime? _lastUpdateTime; // 记录上次更新时间
  bool _isInserting = false; // 检测数据插入状态
  int pageIndex = 0; // 当前页数
  String epPages = ""; // 章节总页数
  bool _isVisible = true; // 控制 AppBar 和 BottomAppBar 的可见性
  late int _lastScrollIndex = -1; // 用于记录上次滚动的索引
  double _currentSliderValue = 0; // 当前滑块的值
  int _totalSlots = 0; // 总槽位数量
  int displayedSlot = 1; // 显示的当前槽位
  bool _isSliderRolling = false; // 滑块是否在滑动
  bool _isComicRolling = false; // 漫画本身是否在滚动
  late Timer _timer; // 定时器，定时存储阅读记录
  TapDownDetails? _tapDownDetails; // 保存点击信息

  bool get _isHistory =>
      _type == ComicEntryType.history ||
      _type == ComicEntryType.historyAndDownload;

  bool get _isDownload =>
      _type == ComicEntryType.download ||
      _type == ComicEntryType.historyAndDownload;

  @override
  void initState() {
    super.initState();
    if (globalSetting.readMode != 0) {
      pageIndex = 2;
    }
    _currentSliderValue = 0;
    _type = widget.type ?? ComicEntryType.normal;
    _doc = widget.doc;
    _epId = widget.epsInfo.firstWhere((doc) => doc.title == _doc.title).id;
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
    comicHistory =
        objectbox.bikaHistoryBox
            .query(BikaComicHistory_.comicId.equals(comicId))
            .build()
            .findFirst();
    // 如果没有记录就先插入一条记录
    if (comicHistory == null) {
      comicHistory = comicToBikaComicHistory(comicInfo, _doc.order);
      objectbox.bikaHistoryBox.put(comicHistory!);
    }

    if (_isDownload) {
      // 首先查询一下有没有记录
      var temp =
          objectbox.bikaDownloadBox
              .query(BikaComicDownload_.comicId.equals(comicId))
              .build()
              .findFirst()!
              .comicInfoAll;
      var temp2 = comic_all_info_json.comicAllInfoJsonFromJson(temp);
      _downloadEpsInfo = temp2.eps;
    }

    logger.d(_type.toString().split('.').last);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (globalSetting.readMode != 0) {
        await Future.delayed(Duration(milliseconds: 200));
        setState(() => _isVisible = false);
      }

      await Future.delayed(Duration(seconds: 1));
      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        writeToDatabase();
      });
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _itemPositionsListener.itemPositions.removeListener(() {});
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body:
        _isDownload
            ? _successWidget(null)
            : BlocBuilder<PageBloc, PageState>(
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
  );

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

  var length = 0;
  List<Media> medias = [];

  Widget _successWidget(PageState? state) {
    // logger.d(_currentSliderValue.toString());
    if (_isVisible == false && globalSetting.readMode == 0) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }

    try {
      _handleMediaData(state);
    } catch (e) {
      logger.e(e);
      return _showDownloadError();
    }

    return Container(
      color: Colors.black,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          children: [
            _buildInteractiveViewer(),
            _comicReadAppBar(),
            _pageCountWidget(),
            _bottomWidget(),
          ],
        ),
      ),
    );
  }

  Widget _comicReadAppBar() => ComicReadAppBar(
    title: _doc.title,
    isVisible: _isVisible,
    changePageIndex:
        (int value) => setState(() {
          _currentSliderValue = 1.0;
          pageIndex = value;
        }),
  );

  Widget _pageCountWidget() =>
      PageCountWidget(pageIndex: pageIndex, epPages: epPages);

  Widget _bottomWidget() => BottomWidget(
    type: _type,
    isVisible: _isVisible,
    doc: _doc,
    epsInfo: widget.epsInfo,
    comicInfo: comicInfo,
    sliderWidget: SliderWidget(
      totalSlots: _totalSlots,
      currentSliderValue: _currentSliderValue,
      changeSliderValue: (double newValue) {
        setState(() => _currentSliderValue = newValue);
      },
      changeSliderRollState: (bool newValue) {
        setState(() => _isSliderRolling = newValue);
      },
      changeComicRollState: (bool newValue) {
        setState(() => _isComicRolling = newValue);
      },
      itemScrollController: _itemScrollController,
      pageController: _pageController,
    ),
  );

  /// 构建交互式查看器
  Widget _buildInteractiveViewer() {
    return GestureDetector(
      onTap: _onTap,
      onTapDown: (TapDownDetails details) => _tapDownDetails = details,
      child: InteractiveViewer(
        boundaryMargin: EdgeInsets.zero,
        minScale: 1.0,
        maxScale: 4.0,
        child: Observer(
          builder: (context) {
            return globalSetting.readMode == 0
                ? _columnModeWidget()
                : _rowModeWidget();
          },
        ),
      ),
    );
  }

  Future<void> _onTap() async {
    if (globalSetting.readMode != 0) {
      // 延迟到下一个循环中执行，避免点击事件冲突
      await Future.delayed(Duration.zero);
      if (_tapDownDetails != null) {
        // 使用保存的details执行处理逻辑
        _handleTap(_tapDownDetails!);
        _tapDownDetails = null;
      }
    } else {
      // 点击事件处理
      _toggleVisibility();
    }
  }

  Widget _columnModeWidget() => ColumnModeWidget(
    comicId: comicId,
    epsId: _doc.id,
    chapterId: _epId,
    length: length,
    medias: medias,
    itemScrollController: _itemScrollController,
    itemPositionsListener: _itemPositionsListener,
  );

  Widget _rowModeWidget() => RowModeWidget(
    key: ValueKey(globalSetting.readMode.toString()),
    comicId: comicId,
    epsId: _doc.id,
    chapterId: _epId,
    medias: medias,
    pageController: _pageController,
    onPageChanged: (int index) {
      setState(() {
        pageIndex = index + 2;
        // logger.d('当前页数：${pageIndex - 1}');
        if (!_isComicRolling) {
          _currentSliderValue =
              (pageIndex).clamp(0, _totalSlots - 1).toDouble() - 1;
          _isVisible = false;
        }
      });
    },
    isSliderRolling: _isSliderRolling,
  );

  /// 切换UI可见性
  void _toggleVisibility() {
    setState(() => _isVisible = !_isVisible);
    if (_isVisible) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _handleTap(TapDownDetails details) {
    // 获取点击的全局坐标
    final Offset tapPosition = details.globalPosition;
    // 将屏幕宽度分为三等份
    final double thirdWidth = MediaQuery.of(context).size.width / 3;
    // 将中间区域的高度分为三等份
    final double middleTopHeight =
        MediaQuery.of(context).size.height / 3; // 上三分之一
    final double middleBottomHeight =
        MediaQuery.of(context).size.height * 2 / 3; // 下三分之一

    final readMode = globalSetting.readMode == 1 ? true : false;

    // 判断点击区域
    if (tapPosition.dx < thirdWidth) {
      // 点击左边三分之一
      _jumpToPage(readMode ? pageIndex - 3 : pageIndex - 1);
    } else if (tapPosition.dx < 2 * thirdWidth) {
      // 点击中间三分之一
      if (tapPosition.dy < middleTopHeight) {
        // 点击中间区域的上三分之一
        _jumpToPage(pageIndex - 3);
      } else if (tapPosition.dy < middleBottomHeight) {
        // 点击中间区域的中三分之一
        _toggleVisibility();
      } else {
        // 点击中间区域的下三分之一
        _jumpToPage(pageIndex - 1);
      }
    } else {
      // 点击右边三分之一
      _jumpToPage(readMode ? pageIndex - 1 : pageIndex - 3);
    }
  }

  void _jumpToPage(int page) => _pageController.animateToPage(
    page,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );

  Future<void> writeToDatabase() async {
    if (_isInserting ||
        _lastUpdateTime != null &&
            DateTime.now().difference(_lastUpdateTime!).inMilliseconds < 100) {
      return;
    }
    // 更新记录
    _isInserting = true;
    comicHistory!
      ..thumbFileServer = comicInfo.thumb.fileServer
      ..thumbPath = comicInfo.thumb.path
      ..thumbOriginalName = comicInfo.thumb.originalName
      ..history = DateTime.now().toUtc()
      ..order = _doc.order
      ..epPageCount = pageIndex
      ..epTitle = _doc.title
      ..epId = _epId
      ..deleted = false;
    await objectbox.bikaHistoryBox.putAsync(comicHistory!);
    _isInserting = false;
    _lastUpdateTime = DateTime.now();
  }

  Future<void> getTopThirdItemIndex(Iterable<ItemPosition> positions) async {
    if (globalSetting.readMode != 0) return;
    ScrollPositionHelper.handleUpdate(
      context: context,
      positions: positions,
      isSliderRolling: _isSliderRolling,
      isMounted: mounted,
      onPageIndexChanged: (newIndex) {
        if (pageIndex != newIndex) {
          // logger.d('更新索引：$newIndex');
          setState(() {
            pageIndex = newIndex;
            if (!_isComicRolling) {
              _currentSliderValue =
                  (pageIndex - 2).clamp(0, _totalSlots - 1).toDouble();
            }
          });
        }
      },
    );
  }

  void _detectScrollDirection(Iterable<ItemPosition> positions) {
    if (positions.isNotEmpty) {
      // 获取当前滚动的第一个索引
      final firstItemIndex = positions.first.index;

      // 判断是否有滚动
      if (firstItemIndex != _lastScrollIndex && !_isSliderRolling) {
        // logger.d('滚动检测：隐藏组件');
        setState(() {
          _isVisible = false; // 只要滚动了就隐藏组件
        });
      }

      // 更新记录的滚动索引
      _lastScrollIndex = firstItemIndex;
    }
  }

  /// 处理媒体数据加载
  void _handleMediaData(PageState? state) {
    if (state != null) {
      _loadOnlineData(state);
    } else {
      try {
        _loadDownloadedData();
      } catch (e) {
        _showDownloadError();
      }
    }
    _updateTotalSlots();
    _handleHistoryScroll();
  }

  /// 加载在线数据
  void _loadOnlineData(PageState state) {
    length = state.medias!.length;
    epPages = state.result!;
    medias = state.medias!;
  }

  /// 加载下载数据
  void _loadDownloadedData() {
    final temp = _downloadEpsInfo.docs.firstWhere((e) => e.order == _doc.order);

    _doc = eps.Doc(
      id: temp.id,
      title: temp.title,
      order: temp.order,
      updatedAt: temp.updatedAt,
      docId: temp.docId,
    );

    medias =
        temp.pages.docs
            .map(
              (e) => Media(
                originalName: e.media.originalName,
                path: e.media.path,
                fileServer: e.media.fileServer,
              ),
            )
            .toList();

    length = temp.pages.docs.length;
    epPages = temp.pages.docs.length.toString();
  }

  /// 显示下载错误
  Widget _showDownloadError() {
    return Center(child: Text('章节未下载', style: TextStyle(fontSize: 20)));
  }

  /// 更新总页数
  void _updateTotalSlots() {
    _totalSlots == 0 ? _totalSlots = length : 0;
  }

  /// 处理历史记录滚动
  void _handleHistoryScroll() {
    final shouldScroll =
        _isHistory && (comicHistory!.epPageCount - 1 != 0) && !isSkipped;

    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => pageIndex = comicHistory!.epPageCount);
        // logger.d('历史记录：${comicHistory!.epPageCount}');
        if (globalSetting.readMode == 0) {
          _itemScrollController.scrollTo(
            index: comicHistory!.epPageCount - 1,
            alignment: 0.0,
            duration: const Duration(milliseconds: 500),
          );
        } else {
          _pageController.animateToPage(
            comicHistory!.epPageCount - 2,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
        isSkipped = true;
      });
    }
  }
}
