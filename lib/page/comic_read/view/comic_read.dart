import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/comic_info/models/all_info.dart';
import 'package:zephyr/page/comic_read/comic_read.dart';
import 'package:zephyr/page/comic_read/method/history_writer.dart';
import 'package:zephyr/page/comic_read/method/jump_chapter.dart';
import 'package:zephyr/page/jm/jm_comic_info/json/jm_comic_info_json.dart'
    show JmComicInfoJson;
import 'package:zephyr/page/jm/jm_download/json/download_info_json.dart'
    show downloadInfoJsonFromJson, DownloadInfoJsonSeries;
import 'package:zephyr/util/memory/memory_overlay_widget.dart';
import 'package:zephyr/util/settings_hive_utils.dart';
import 'package:zephyr/util/volume_key_handler.dart';

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
  final int epsNumber;
  final From from;
  final ComicEntryType type;
  final dynamic comicInfo;
  // 这个 Cubit 仍然需要从路由参数中接收
  final StringSelectCubit stringSelectCubit;

  const ComicReadPage({
    super.key,
    required this.comicId,
    required this.order,
    required this.epsNumber,
    required this.from,
    required this.stringSelectCubit, // 仍然是必需的
    required this.type,
    required this.comicInfo,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PageBloc()..add(PageEvent(comicId, order, from)),
        ),
        BlocProvider.value(value: stringSelectCubit),
      ],
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

class _ComicReadPageState extends State<_ComicReadPage>
    with WidgetsBindingObserver {
  dynamic get comicInfo => widget.comicInfo;

  String get comicId => widget.comicId;

  String epId = '';
  String epName = '';
  late final ComicEntryType _type;
  late final dynamic _downloadEpsInfo;
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
  bool _loading = true; // 加载状态
  final _historyWriter = HistoryWriter();
  Timer? _cleanTimer;
  late JumpChapter _jumpChapter;

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
    _cleanTimer = Timer(const Duration(seconds: 5), () {
      // 腾出空间供阅读器使用
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.maximumSizeBytes = 1024 * 1024 * 1024;
    });

    if (SettingsHiveUtils.readMode != 0) {
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
      comicHistory = objectbox.bikaHistoryBox
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
        var temp = objectbox.bikaDownloadBox
            .query(BikaComicDownload_.comicId.equals(comicId))
            .build()
            .findFirst()!
            .comicInfoAll;
        _downloadEpsInfo = comicAllInfoJsonFromJson(temp).eps;
      }

      // logger.d(_type.toString().split('.').last);
    } else if (widget.from == From.jm) {
      var jmComic = comicInfo as JmComicInfoJson;
      // 首先查询一下有没有记录
      jmHistory = objectbox.jmHistoryBox
          .query(JmHistory_.comicId.equals(comicId))
          .build()
          .findFirst();
      // 如果没有记录就先插入一条记录
      if (jmHistory == null) {
        jmHistory = jmToJmHistory(jmComic);
        objectbox.jmHistoryBox.put(jmHistory!);
      }

      if (_isDownload) {
        var temp = objectbox.jmDownloadBox
            .query(JmDownload_.comicId.equals(comicId))
            .build()
            .findFirst()!
            .allInfo;
        _downloadEpsInfo = downloadInfoJsonFromJson(temp).series;

        jmComic = jmComic;
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final globalSettingState = context.read<GlobalSettingCubit>().state;
      if (globalSettingState.readMode != 0) {
        await Future.delayed(Duration(milliseconds: 200));
        setState(() => _isVisible = false);
        // 横版模式下自动隐藏 AppBar 后启用音量键拦截
        VolumeKeyHandler.enableVolumeKeyInterception();
      }

      await Future.delayed(Duration(seconds: 1));
      await _historyWriter.start();
      _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        if (!_loading && comicInfo != null) writeToDatabase();
      });
    });

    _jumpChapter = JumpChapter.create(
      _type,
      _isVisible,
      comicInfo,
      widget.order,
      widget.epsNumber,
      comicId,
      widget.from,
    );

    // 设置音量键监听
    _setupVolumeKeyListener();
  }

  void _setupVolumeKeyListener() {
    VolumeKeyHandler.volumeKeyEvents.listen((event) {
      if (!mounted) return;

      final globalSettingState = context.read<GlobalSettingCubit>().state;

      if (event == 'volume_down') {
        // 音量减键：下一页
        if (globalSettingState.readMode == 0) {
          // 纵向模式：滚动到下一页
          // 使用 _currentSliderValue 来计算，与 slider 逻辑保持一致
          final newSliderValue = _currentSliderValue + 1;
          final scrollIndex = newSliderValue.toInt() + 1;
          logger.d(
            '音量减键 - pageIndex: $pageIndex, _currentSliderValue: $_currentSliderValue, newSliderValue: $newSliderValue, scrollIndex: $scrollIndex, length: $length',
          );
          // 检查是否还有下一页
          if (newSliderValue < _totalSlots) {
            _itemScrollController.scrollTo(
              index: scrollIndex,
              alignment: 0.0,
              duration: const Duration(milliseconds: 300),
            );
          } else {
            logger.d('已经是最后一页了');
          }
        } else {
          // 横向模式：翻到下一页
          _jumpToPage(pageIndex - 1);
        }
      } else if (event == 'volume_up') {
        // 音量加键：上一页
        if (globalSettingState.readMode == 0) {
          // 纵向模式：滚动到上一页
          // 使用 _currentSliderValue 来计算
          final newSliderValue = _currentSliderValue - 1;
          final scrollIndex = newSliderValue.toInt() + 1;
          logger.d(
            '音量加键 - pageIndex: $pageIndex, _currentSliderValue: $_currentSliderValue, newSliderValue: $newSliderValue, scrollIndex: $scrollIndex',
          );
          if (newSliderValue >= 0) {
            _itemScrollController.scrollTo(
              index: scrollIndex,
              alignment: 0.0,
              duration: const Duration(milliseconds: 300),
            );
          }
        } else {
          // 横向模式：翻到上一页
          _jumpToPage(pageIndex - 3);
        }
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _itemPositionsListener.itemPositions.removeListener(() {});
    _timer?.cancel();
    _historyWriter.stop();
    _cleanTimer?.cancel();
    VolumeKeyHandler.disableVolumeKeyInterception();
    PaintingBinding.instance.imageCache.maximumSizeBytes = 300 * 1024 * 1024;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: _isDownload
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
    if (_loading) _loading = false;

    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    if (_isVisible == false && globalSettingState.readMode == 0) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }

    if (epName == '') {
      try {
        _handleMediaData(state);
      } catch (e, s) {
        logger.e(e, stackTrace: s);
        return _showDownloadError();
      }
    }

    return MemoryOverlayWidget(
      enabled: false,
      updateInterval: Duration(seconds: 1),
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            // 主内容区域，当UI隐藏时留出底部系统手势区域
            Positioned.fill(
              bottom: _isVisible ? 0 : MediaQuery.of(context).padding.bottom,
              child: _buildInteractiveViewer(),
            ),
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
    changePageIndex: (int value) => setState(() {
      _currentSliderValue = 1.0;
      pageIndex = value;
    }),
  );

  Widget _pageCountWidget() =>
      PageCountWidget(pageIndex: pageIndex, epPages: epPages);

  Widget _bottomWidget() {
    final silder = SliderWidget(
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
    );

    return BottomWidget(
      type: _type,
      isVisible: _isVisible,
      comicInfo: comicInfo,
      sliderWidget: silder,
      order: widget.order,
      epsNumber: widget.epsNumber,
      comicId: comicId,
      from: widget.from,
      jumpChapter: _jumpChapter,
    );
  }

  /// 构建交互式查看器
  Widget _buildInteractiveViewer() {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    return GestureDetector(
      onTap: _onTap,
      onTapDown: (TapDownDetails details) => _tapDownDetails = details,
      child: InteractiveViewer(
        boundaryMargin: EdgeInsets.zero,
        minScale: 1.0,
        maxScale: 4.0,
        child: globalSettingState.readMode == 0
            ? _columnModeWidget()
            : _rowModeWidget(),
      ),
    );
  }

  Future<void> _onTap() async {
    final globalSettingState = context.read<GlobalSettingCubit>().state;

    if (globalSettingState.readMode != 0) {
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

  Widget _columnModeWidget() {
    final haveNext = _jumpChapter.haveNext;
    final havePrev = _jumpChapter.havePrev;

    logger.d('是否有上一章：$havePrev, 是否有下一章：$haveNext');

    // 1. 定义正常的 Header（保持你之前的防误触和样式配置）
    const activeHeader = ClassicHeader(
      dragText: '下拉上一章',
      armedText: '松手跳转上一章',
      readyText: '',
      processingText: '',
      processedText: '',
      showText: true,
      showMessage: false,
      iconDimension: 0,
      spacing: 0,
      processedDuration: Duration.zero,
      textStyle: TextStyle(color: Colors.white),
    );

    // 2. 定义正常的 Footer
    const activeFooter = ClassicFooter(
      dragText: '上拉下一章',
      armedText: '松手跳转下一章',
      readyText: '',
      processingText: '',
      processedText: '',
      showText: true,
      showMessage: false,
      iconDimension: 0,
      spacing: 0,
      processedDuration: Duration.zero,
      infiniteOffset: null,
      textStyle: TextStyle(color: Colors.white),
    );

    return EasyRefresh.builder(
      header: activeHeader,
      footer: activeFooter,

      onRefresh: havePrev
          ? () async {
              final result = await _bottomButtonDialog('跳转', '是否要跳转到上一章？');
              if (!result) return;
              if (!mounted) return;
              _jumpChapter.jumpToChapter(context, true);
            }
          : null,

      onLoad: haveNext
          ? () async {
              final result = await _bottomButtonDialog('跳转', '是否要跳转到下一章？');
              if (!result) return;
              if (!mounted) return;
              _jumpChapter.jumpToChapter(context, false);
            }
          : null,

      triggerAxis: Axis.vertical,

      notRefreshHeader: const NotRefreshHeader(
        clamping: false,
        hitOver: true,
        position: IndicatorPosition.locator,
      ),

      notLoadFooter: const NotLoadFooter(
        clamping: false,
        hitOver: true,
        position: IndicatorPosition.locator,
      ),

      // 保持之前的 childBuilder 写法
      childBuilder: (context, physics) {
        return ColumnModeWidget(
          comicId: comicId,
          epsId: epId,
          length: length,
          docs: docs,
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          from: widget.from,
          parentPhysics: physics,
        );
      },
    );
  }

  Future<bool> _bottomButtonDialog(String title, String content) async {
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

  Widget _rowModeWidget() {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    return RowModeWidget(
      key: ValueKey(globalSettingState.readMode.toString()),
      comicId: comicId,
      epsId: epId,
      docs: docs,
      pageController: _pageController,
      onPageChanged: (int index) {
        setState(() {
          pageIndex = index + 2;

          // logger.d('当前页数：${pageIndex - 1}');
          if (!_isComicRolling) {
            // 确保 clamp 的最大值不小于最小值，避免 Invalid argument 错误
            final maxSlot = (_totalSlots - 1).clamp(
              0,
              double.maxFinite.toInt(),
            );
            _currentSliderValue = (pageIndex).clamp(0, maxSlot).toDouble() - 1;
            _isVisible = false;
          }
        });
      },
      isSliderRolling: _isSliderRolling,
      from: widget.from,
    );
  }

  /// 切换UI可见性
  void _toggleVisibility() {
    setState(() => _isVisible = !_isVisible);
    if (_isVisible) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      VolumeKeyHandler.disableVolumeKeyInterception();
    } else {
      VolumeKeyHandler.enableVolumeKeyInterception();
    }
  }

  void _handleTap(TapDownDetails details) {
    final globalSettingState = context.read<GlobalSettingCubit>().state;

    // 获取点击的全局坐标
    final Offset tapPosition = details.globalPosition;
    // 将屏幕宽度分为三等份
    final double thirdWidth = MediaQuery.of(context).size.width / 3;
    // 将中间区域的高度分为三等份
    final double middleTopHeight =
        MediaQuery.of(context).size.height / 3; // 上三分之一
    final double middleBottomHeight =
        MediaQuery.of(context).size.height * 2 / 3; // 下三分之一

    final readMode = globalSettingState.readMode == 1 ? true : false;

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
    if (!mounted) {
      return;
    }

    if (_isInserting ||
        _lastUpdateTime != null &&
            DateTime.now().difference(_lastUpdateTime!).inMilliseconds < 100) {
      return;
    }

    final currentTime = DateTime.now().toLocal().toString().substring(0, 19);

    final isJmAndSeriesEmpty =
        widget.from == From.jm && (comicInfo as JmComicInfoJson).series.isEmpty;

    final historyPrefix = isJmAndSeriesEmpty ? '历史：第1话' : '历史：$epName';

    final stringSelectCubit = context.read<StringSelectCubit>();

    stringSelectCubit.setDate(
      '$historyPrefix / ${pageIndex - 1} / $currentTime',
    );

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
      _historyWriter.updateBikaHistory(comicHistory!);
    } else if (widget.from == From.jm) {
      // logger.d(pageIndex);
      // 更新记录
      _isInserting = true;
      jmHistory!
        ..history = DateTime.now().toUtc()
        ..order = widget.order
        ..epPageCount = pageIndex
        ..epTitle = isJmAndSeriesEmpty ? '' : epName
        ..epId = epId
        ..deleted = false;
      _historyWriter.updateJmHistory(jmHistory!);
    }
    _isInserting = false;
    _lastUpdateTime = DateTime.now();
  }

  Future<void> getTopThirdItemIndex(Iterable<ItemPosition> positions) async {
    final globalSettingState = context.read<GlobalSettingCubit>().state;

    if (globalSettingState.readMode != 0) return;
    // 在数据加载完成前不处理滚动位置更新
    if (_totalSlots == 0) return;

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
            // logger.d('当前页数：${pageIndex - 1}');
            if (!_isComicRolling) {
              // 确保 clamp 的最大值不小于最小值，避免 Invalid argument 错误
              final maxSlot = (_totalSlots - 1).clamp(
                0,
                double.maxFinite.toInt(),
              );
              _currentSliderValue = (pageIndex - 2)
                  .clamp(0, maxSlot)
                  .toDouble();
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
        VolumeKeyHandler.enableVolumeKeyInterception();
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
    if (widget.from == From.bika) {
      final temp = (_downloadEpsInfo as Eps).docs.firstWhere(
        (e) => e.order == widget.order,
      );

      epId = temp.id;
      epName = temp.title;

      docs = temp.pages.docs
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
    } else {
      final temp = (_downloadEpsInfo as List<DownloadInfoJsonSeries>)
          .firstWhere((e) => e.id == jmHistory!.order.toString());

      epId = temp.id;
      epName = temp.info.name;

      docs = temp.info.images
          .map(
            (e) => Doc(
              originalName: e,
              path: e,
              fileServer: getJmImagesUrl(temp.id.toString(), e),
              id: epId,
            ),
          )
          .toList();

      length = temp.info.images.length;
      epPages = temp.info.images.length.toString();
    }
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

    final index = widget.from == From.bika
        ? comicHistory!.epPageCount
        : jmHistory!.epPageCount;

    // logger.d('历史记录：$index');

    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => pageIndex = index);
        // logger.d('历史记录：$index');
        final globalSettingState = context.read<GlobalSettingCubit>().state;
        if (globalSettingState.readMode == 0) {
          _itemScrollController.jumpTo(index: index - 1, alignment: 0.0);
        } else {
          _pageController.jumpToPage(index - 2);
        }
        isSkipped = true;
      });
    }
  }
}
