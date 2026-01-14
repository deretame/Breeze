import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_read/comic_read.dart';
import 'package:zephyr/page/comic_read/method/history_writer.dart';
import 'package:zephyr/page/comic_read/method/jump_chapter.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/settings_hive_utils.dart';
import 'package:zephyr/util/volume_key_handler.dart';

@RoutePage()
class ComicReadPage extends StatelessWidget {
  final String comicId;
  final int order;
  final int epsNumber;
  final From from;
  final ComicEntryType type;
  final dynamic comicInfo;
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
          create: (_) => PageBloc()..add(PageEvent(comicId, order, from, type)),
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

  late final ComicEntryType _type;
  late bool isSkipped = false; // 是否跳转过
  late final ItemScrollController _itemScrollController;
  late final ItemPositionsListener _itemPositionsListener;
  final PageController _pageController = PageController(initialPage: 0);
  int pageIndex = 0; // 当前页数
  bool _isVisible = true; // 控制 AppBar 和 BottomAppBar 的可见性
  late int _lastScrollIndex = -1; // 用于记录上次滚动的索引
  double _currentSliderValue = 0; // 当前滑块的值
  int _totalSlots = 0; // 总槽位数量
  int displayedSlot = 1; // 显示的当前槽位
  bool _isSliderRolling = false; // 滑块是否在滑动
  bool _isComicRolling = false; // 漫画本身是否在滚动
  TapDownDetails? _tapDownDetails; // 保存点击信息
  Timer? _cleanTimer; // 用来清理图片缓存的定时器
  late JumpChapter _jumpChapter; // 用来跳转章节的通用类
  late final ReaderVolumeController _volumeController; // 音量键翻页控制器
  late final ReaderHistoryManager _historyManager; // 历史记录管理器
  NormalComicEpInfo epInfo = NormalComicEpInfo(); // 通用漫画章节信息

  bool get _isHistory =>
      _type == ComicEntryType.history ||
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

    // === 初始化音量控制器 ===
    _volumeController = ReaderVolumeController(
      itemScrollController: _itemScrollController,
      pageController: _pageController,
      getReadMode: () => context.read<GlobalSettingCubit>().state.readMode,
      getCurrentSliderValue: () => _currentSliderValue,
      getPageIndex: () => pageIndex,
      getTotalSlots: () => _totalSlots,
      onSliderValueChanged: (newValue) {
        _currentSliderValue = newValue;
      },
    );

    // 开始监听
    _volumeController.listen();

    // === 初始化历史记录管理器 ===
    _historyManager = ReaderHistoryManager(
      comicId: comicId,
      order: widget.order,
      from: widget.from,
      comicInfo: widget.comicInfo,
      historyWriter: HistoryWriter(), // 或者这里 new 一个新的
      stringSelectCubit: context.read<StringSelectCubit>(), // 传入 Cubit
      getPageIndex: () => pageIndex,
      getEpInfo: () => epInfo,
    );

    // 执行异步初始化（查询数据库）
    _historyManager.init();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final globalSettingState = context.read<GlobalSettingCubit>().state;
      if (globalSettingState.readMode != 0) {
        await Future.delayed(Duration(milliseconds: 200));
        setState(() => _isVisible = false);
        // 横版模式下自动隐藏 AppBar 后启用音量键拦截
        VolumeKeyHandler.enableVolumeKeyInterception();
      }

      await Future.delayed(Duration(seconds: 1));
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
  }

  @override
  void dispose() {
    _cleanTimer?.cancel();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _itemPositionsListener.itemPositions.removeListener(() {});
    _historyManager.stop();
    _volumeController.dispose();
    PaintingBinding.instance.imageCache.maximumSizeBytes = 300 * 1024 * 1024;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocBuilder<PageBloc, PageState>(
      builder: (context, state) {
        switch (state.status) {
          case PageStatus.initial:
            return const Center(child: CircularProgressIndicator());
          case PageStatus.failure:
            return ComicErrorWidget(
              state: state,
              event: PageEvent(comicId, widget.order, widget.from, widget.type),
            );
          case PageStatus.success:
            epInfo = state.epInfo!;
            return _successWidget(state);
        }
      },
    ),
  );

  Widget _successWidget(PageState state) {
    _historyManager.markLoaded();

    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    if (_isVisible == false && globalSettingState.readMode == 0) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }

    _handleMediaData(state);

    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            bottom: _isVisible ? 0 : MediaQuery.of(context).padding.bottom,
            child: _buildInteractiveViewer(),
          ),
          _comicReadAppBar(),
          _pageCountWidget(),
          _bottomWidget(),
        ],
      ),
    );
  }

  Widget _comicReadAppBar() => ComicReadAppBar(
    title: epInfo.epName,
    isVisible: _isVisible,
    changePageIndex: (int value) => setState(() {
      _currentSliderValue = 1.0;
      pageIndex = value;
    }),
  );

  Widget _pageCountWidget() =>
      PageCountWidget(pageIndex: pageIndex, epPages: epInfo.epPages);

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
        if (!mounted) return;
        ReaderGestureLogic.handleTap(
          context: context,
          details: _tapDownDetails!,
          pageIndex: pageIndex,
          onJump: (int page) => _jumpToPage(page),
          onToggleMenu: _toggleVisibility,
        );
        _tapDownDetails = null;
      }
    } else {
      // 点击事件处理
      _toggleVisibility();
    }
  }

  final offset = 8;
  Widget _columnModeWidget() {
    return VerticalPullNavigator(
      havePrev: _jumpChapter.havePrev,
      haveNext: _jumpChapter.haveNext,

      onPrev: () async {
        if (!mounted) return;
        _jumpChapter.jumpToChapter(context, true);
      },

      onNext: () async {
        if (!mounted) return;
        _jumpChapter.jumpToChapter(context, false);
      },

      builder: (context, physics) {
        return ColumnModeWidget(
          comicId: comicId,
          epsId: epInfo.epId,
          length: epInfo.length,
          docs: epInfo.docs,
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          from: widget.from,
          parentPhysics: physics,
        );
      },
    );
  }

  Widget _rowModeWidget() {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    return RowModeWidget(
      key: ValueKey(globalSettingState.readMode.toString()),
      comicId: comicId,
      epsId: epInfo.epId,
      docs: epInfo.docs,
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
      jumpChapter: _jumpChapter,
    );
  }

  /// 切换UI可见性
  void _toggleVisibility() {
    setState(() => _isVisible = !_isVisible);
    if (_isVisible) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _volumeController.disableInterception();
    } else {
      _volumeController.enableInterception();
    }
  }

  void _jumpToPage(int page) => _pageController.animateToPage(
    page,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );

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
        _volumeController.enableInterception();
      }

      // 更新记录的滚动索引
      _lastScrollIndex = firstItemIndex;
    }
  }

  /// 处理媒体数据加载
  void _handleMediaData(PageState state) {
    _totalSlots = state.epInfo!.length;
    _handleHistoryScroll();
  }

  /// 处理历史记录滚动
  void _handleHistoryScroll() {
    var shouldScroll = _isHistory && !isSkipped;

    // 获取历史页码
    final historyIndex = _historyManager.getHistoryPageIndex();

    if (shouldScroll) {
      shouldScroll &= (historyIndex - 1 != 0);
    }

    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => pageIndex = historyIndex);

        final globalSettingState = context.read<GlobalSettingCubit>().state;
        if (globalSettingState.readMode == 0) {
          _itemScrollController.jumpTo(index: historyIndex - 1, alignment: 0.0);
        } else {
          _pageController.jumpToPage(historyIndex - 2);
        }
        isSkipped = true;
      });
    }
  }
}
