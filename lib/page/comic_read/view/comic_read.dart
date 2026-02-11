import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_read/comic_read.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';
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
        BlocProvider(create: (_) => ReaderCubit()),
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
  final _pageController = PageController(initialPage: 0); // 横版阅读器
  TapDownDetails? _tapDownDetails; // 保存点击信息
  Timer? _cleanTimer; // 用来清理图片缓存的定时器
  late JumpChapter _jumpChapter; // 用来跳转章节的通用类
  late final ReaderVolumeController _volumeController; // 音量键翻页控制器
  late final ReaderHistoryManager _historyManager; // 历史记录管理器
  NormalComicEpInfo epInfo = NormalComicEpInfo(); // 通用漫画章节信息
  late final ListObserverController observerController; // 列表观察控制器
  final scrollController = ScrollController(); // 列表滚动控制器
  BuildContext? _imageSizeContext;

  bool get _isHistory =>
      _type == ComicEntryType.history ||
      _type == ComicEntryType.historyAndDownload;

  @override
  void initState() {
    super.initState();
    observerController = ListObserverController(controller: scrollController);
    _cleanTimer = Timer(const Duration(seconds: 5), () {
      // 腾出空间供阅读器使用
      PaintingBinding.instance.imageCache.clear();
    });
    final cubit = context.read<ReaderCubit>();
    _type = widget.type;

    // === 初始化音量控制器 ===
    _volumeController = ReaderVolumeController(
      observerController: observerController,
      pageController: _pageController,
      getReadMode: () => context.read<GlobalSettingCubit>().state.readMode,
      getPageIndex: () => cubit.state.pageIndex,
      getTotalSlots: () => cubit.state.totalSlots,
      getContext: () => _imageSizeContext!,
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
      getPageIndex: () => context.read<ReaderCubit>().state.pageIndex + 1,
      getEpInfo: () => epInfo,
    );

    // 执行异步初始化（查询数据库）
    _historyManager.init();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final globalSettingState = context.read<GlobalSettingCubit>().state;
      await Future.delayed(Duration(milliseconds: 200));
      cubit.updateMenuVisible(visible: false);
      if (globalSettingState.readMode == 0) {
        VolumeKeyHandler.enableVolumeKeyInterception();
      }

      await Future.delayed(Duration(seconds: 1));
    });

    _jumpChapter = JumpChapter.create(
      _type,
      cubit.state.isMenuVisible,
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
    _historyManager.stop();
    _volumeController.dispose();
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
    final width = context.screenWidth;
    final statusBarHeight = context.statusBarHeight;

    return BlocProvider(
      create: (context) => ImageSizeCubit.create(
        statusBarHeight: statusBarHeight,
        defaultWidth: width,
        count: epInfo.length + 2,
      ),
      child: Builder(
        builder: (innerContext) {
          final cubit = innerContext.read<ReaderCubit>();
          _imageSizeContext = innerContext;

          final isMenuVisible = innerContext.select(
            (ReaderCubit c) => c.state.isMenuVisible,
          );

          _historyManager.markLoaded();

          final readMode = innerContext.select(
            (GlobalSettingCubit c) => c.state.readMode,
          );

          if (isMenuVisible == false && readMode == 0) {
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
          }

          cubit.updateTotalSlots(state.epInfo!.length);
          _handleHistoryScroll();

          return Container(
            color: Colors.black,
            child: Stack(
              children: [
                Positioned.fill(
                  bottom: isMenuVisible
                      ? 0
                      : MediaQuery.of(innerContext).padding.bottom,
                  child: _buildInteractiveViewer(),
                ),
                _comicReadAppBar(),
                _pageCountWidget(),
                _bottomWidget(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _comicReadAppBar() {
    final cubit = context.read<ReaderCubit>();
    return ComicReadAppBar(
      title: epInfo.epName,
      changePageIndex: (int value) {
        cubit.updatePageIndex(value);
        cubit.updateSliderChanged(1.0);
      },
    );
  }

  Widget _pageCountWidget() => PageCountWidget(epPages: epInfo.epPages);

  Widget _bottomWidget() {
    final silder = SliderWidget(
      observerController: observerController,
      pageController: _pageController,
    );

    return BottomWidget(
      type: _type,
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
        if (!mounted) return;
        final cubit = context.read<ReaderCubit>();
        // 使用保存的details执行处理逻辑
        ReaderGestureLogic.handleTap(
          context: context,
          details: _tapDownDetails!,
          pageIndex: cubit.state.pageIndex,
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
          observerController: observerController,
          scrollController: scrollController,
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
      from: widget.from,
      jumpChapter: _jumpChapter,
    );
  }

  /// 切换UI可见性
  void _toggleVisibility() {
    final cubit = context.read<ReaderCubit>();
    cubit.updateMenuVisible();
    if (cubit.state.isMenuVisible) {
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

  /// 处理历史记录滚动
  void _handleHistoryScroll() {
    var shouldScroll = _isHistory && !isSkipped;

    // 获取历史页码
    final historyIndex = _historyManager.getHistoryPageIndex();

    if (shouldScroll) {
      shouldScroll &= (historyIndex - 1 != 0);
    }

    if (shouldScroll) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // 推迟到下一个事件循环
        await Future.delayed(const Duration(milliseconds: 0));
        if (!mounted) return;
        final cubit = context.read<ReaderCubit>();
        cubit.updatePageIndex(historyIndex);

        final globalSettingState = context.read<GlobalSettingCubit>().state;
        if (globalSettingState.readMode == 0) {
          observerController.controller?.animateTo(
            getOffset(_imageSizeContext!, historyIndex - 1),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.jumpToPage(historyIndex - 2);
        }
        isSkipped = true;
      });
    }
  }
}
