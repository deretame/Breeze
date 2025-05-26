import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_info/models/all_info.dart';
import 'package:zephyr/page/comic_read/comic_read.dart';
import 'package:zephyr/page/jm/jm_comic_info/json/jm_comic_info/jm_comic_info_json.dart'
    show JmComicInfoJson;

import '../../../object_box/model.dart';
import '../../../object_box/objectbox.g.dart';
import '../../../type/enum.dart';
import '../../download/json/comic_all_info_json/comic_all_info_json.dart'
    show Eps, comicAllInfoJsonFromJson;
import '../json/common_ep_info_json/common_ep_info_json.dart';

@RoutePage()
class ComicReadPage extends StatelessWidget {
  final String comicId;
  final int order;
  final int epsNumber; // 这个的意思是一共有多少章
  final From from;
  final ComicEntryType type;
  final dynamic comicInfo; // 这个是比较方便的让禁漫和哔咔把漫画的数据传输过来，到时候强制转换类型就行了

  const ComicReadPage({
    super.key,
    required this.comicId,
    required this.order,
    required this.epsNumber,
    required this.from,
    required this.type,
    required this.comicInfo,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PageBloc()..add(PageEvent(comicId, order, from)),
      child: _ComicReadPage(
        comicId: comicId,
        order: order,
        epsNumber: epsNumber,
        from: from,
        type: type,
        comicInfo: comicInfo,
      ),
    );
  }
}

class _ComicReadPage extends StatefulWidget {
  final String comicId;
  final int order;
  final int epsNumber; // 这个的意思是一共有多少章
  final From from;
  final ComicEntryType type;
  final dynamic comicInfo;

  const _ComicReadPage({
    required this.comicId,
    required this.order,
    required this.epsNumber,
    required this.from,
    required this.type,
    required this.comicInfo,
  });

  @override
  State<_ComicReadPage> createState() => _ComicReadPageState();
}

class _ComicReadPageState extends State<_ComicReadPage> {
  dynamic get comicInfo => widget.comicInfo;

  String get comicId => widget.comicId;

  String epId = '';
  String epName = '';
  late final ComicEntryType _type;
  late final Eps _downloadEpsInfo;
  late bool isSkipped = false; // 是否跳转过
  late final ItemScrollController _itemScrollController;
  late final ItemPositionsListener _itemPositionsListener;
  final PageController _pageController = PageController(initialPage: 0);
  late BikaComicHistory? comicHistory; // 记录阅读记录
  late JmHistory? jmHistory; // 记录阅读记录
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
  Timer? _timer; // 定时器，定时存储阅读记录
  TapDownDetails? _tapDownDetails; // 保存点击信息
  var length = 0; // 组件总数
  List<Doc> docs = []; // 图片信息
  bool _loading = false; // 加载状态

  bool get _isHistory =>
      _type == ComicEntryType.history ||
      _type == ComicEntryType.historyAndDownload;

  bool get _isDownload =>
      _type == ComicEntryType.download ||
      _type == ComicEntryType.historyAndDownload;

  @override
  void initState() {
    super.initState();
    // logger.d(widget.epsNumber.toString());
    if (globalSetting.readMode != 0) {
      pageIndex = 2;
    }
    _currentSliderValue = 0;
    _type = widget.type;
    _itemScrollController = ItemScrollController();
    _itemPositionsListener = ItemPositionsListener.create();

    _itemPositionsListener.itemPositions.addListener(() {
      if (_itemPositionsListener.itemPositions.value.isNotEmpty) {
        final positions = _itemPositionsListener.itemPositions.value;
        getTopThirdItemIndex(positions);
        _detectScrollDirection(positions);
      }
    });

    if (widget.from == From.bika) {
      var allInfo = comicInfo as AllInfo;
      // 首先查询一下有没有记录
      comicHistory =
          objectbox.bikaHistoryBox
              .query(BikaComicHistory_.comicId.equals(comicId))
              .build()
              .findFirst();
      // 如果没有记录就先插入一条记录
      if (comicHistory == null) {
        comicHistory = comicToBikaComicHistory(allInfo.comicInfo);
        objectbox.bikaHistoryBox.put(comicHistory!);
      }

      if (_isDownload) {
        // 再查询一下有没有下载记录
        var temp =
            objectbox.bikaDownloadBox
                .query(BikaComicDownload_.comicId.equals(comicId))
                .build()
                .findFirst()!
                .comicInfoAll;
        var temp2 = comicAllInfoJsonFromJson(temp);
        _downloadEpsInfo = temp2.eps;
      }

      // logger.d(_type.toString().split('.').last);
    } else if (widget.from == From.jm) {
      var jmComic = comicInfo as JmComicInfoJson;
      // 首先查询一下有没有记录
      jmHistory =
          objectbox.jmHistoryBox
              .query(JmHistory_.comicId.equals(comicId))
              .build()
              .findFirst();
      // 如果没有记录就先插入一条记录
      if (jmHistory == null) {
        jmHistory = jmToJmHistory(jmComic);
        objectbox.jmHistoryBox.put(jmHistory!);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (globalSetting.readMode != 0) {
        await Future.delayed(Duration(milliseconds: 200));
        setState(() => _isVisible = false);
      }

      await Future.delayed(Duration(seconds: 1));
      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (_loading) writeToDatabase();
      });
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _itemPositionsListener.itemPositions.removeListener(() {});
    _timer?.cancel();
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
              context.read<PageBloc>().add(
                PageEvent(comicId, widget.order, widget.from),
              );
            },
            child: Text('点击重试'),
          ),
        ],
      ),
    );
  }

  Widget _successWidget(PageState? state) {
    // logger.d(_currentSliderValue.toString());
    if (!_loading) _loading = true;

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
    title: epName,
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
    order: widget.order,
    epsNumber: widget.epsNumber,
    comicId: comicId,
    from: widget.from,
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
    epsId: epId,
    length: length,
    docs: docs,
    itemScrollController: _itemScrollController,
    itemPositionsListener: _itemPositionsListener,
    from: widget.from,
  );

  Widget _rowModeWidget() => RowModeWidget(
    key: ValueKey(globalSetting.readMode.toString()),
    comicId: comicId,
    epsId: epId,
    docs: docs,
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
    from: widget.from,
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
    if (widget.from == From.bika) {
      // 更新记录
      _isInserting = true;
      final temp = (comicInfo as AllInfo).comicInfo;
      // 有的时候漫画的封面会变动，所以这里干脆每次都更新一下
      comicHistory!
        ..thumbFileServer = temp.thumb.fileServer
        ..thumbPath = temp.thumb.path
        ..thumbOriginalName = temp.thumb.originalName
        ..history = DateTime.now().toUtc()
        ..order = widget.order
        ..epPageCount = pageIndex
        ..epTitle = epName
        ..epId = epId
        ..deleted = false;
      await objectbox.bikaHistoryBox.putAsync(comicHistory!);
    } else if (widget.from == From.jm) {
      // 更新记录
      _isInserting = true;
      jmHistory!
        ..history = DateTime.now().toUtc()
        ..order = widget.order
        ..epPageCount = pageIndex
        ..epTitle = epName
        ..epId = epId
        ..deleted = false;
      await objectbox.jmHistoryBox.putAsync(jmHistory!);
    }
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
      _loadDownloadedData();
    }
    _updateTotalSlots();
    _handleHistoryScroll();
  }

  /// 加载在线数据
  void _loadOnlineData(PageState state) {
    length = state.epInfo!.docs.length;
    epPages = length.toString();
    docs = state.epInfo!.docs;
    epId = state.epInfo!.epId;
    epName = state.epInfo!.epName;
  }

  /// 加载下载数据
  void _loadDownloadedData() {
    final temp = _downloadEpsInfo.docs.firstWhere(
      (e) => e.order == widget.order,
    );

    epId = temp.id;
    epName = temp.title;

    docs =
        temp.pages.docs
            .map(
              (e) => Doc(
                originalName: e.media.originalName,
                path: e.media.path,
                fileServer: e.media.fileServer,
                id: epId,
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
    var shouldScroll = _isHistory && !isSkipped;

    if (widget.from == From.bika) {
      shouldScroll &= (comicHistory!.epPageCount - 1 != 0);
    } else {
      shouldScroll &= (jmHistory!.epPageCount - 1 != 0);
    }

    final index =
        widget.from == From.bika
            ? comicHistory!.epPageCount
            : jmHistory!.epPageCount;

    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => pageIndex = index);
        // logger.d('历史记录：${comicHistory!.epPageCount}');
        if (globalSetting.readMode == 0) {
          _itemScrollController.jumpTo(index: index - 1, alignment: 0.0);
        } else {
          _pageController.jumpTo(index - 2);
        }
        isSkipped = true;
      });
    }
  }
}
