import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/comic_read/comic_read.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_state.dart';
import 'package:zephyr/page/comic_read/method/key.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/context/context_extensions.dart';

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
    required this.stringSelectCubit,
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
  TapDownDetails? _doubleTapDownDetails;
  Timer? _cleanTimer; // 用来清理图片缓存的定时器
  Timer? _autoReadTimer;
  late JumpChapter _jumpChapter; // 用来跳转章节的通用类
  late final ReaderActionController _actionController; // 统一动作控制器
  late final ReaderVolumeController _volumeController; // 音量键翻页控制器
  late final ReaderHistoryManager _historyManager; // 历史记录管理器
  NormalComicEpInfo epInfo = NormalComicEpInfo(); // 通用漫画章节信息
  late final ListObserverController observerController; // 列表观察控制器
  final scrollController = ScrollController(); // 列表滚动控制器
  BuildContext? _imageSizeContext;
  bool _isCtrlPressed = false; // 记录有没有按下 Ctrl 键
  final FocusNode _readerFocusNode = FocusNode(); // 阅读器焦点节点
  StreamSubscription<bool>? _menuVisibleSubscription;
  StreamSubscription<bool>? _volumeKeyPageTurnSubscription;
  Timer? _systemUiSyncTimer;
  bool? _lastMenuVisible;
  bool _isAutoReadPaused = false;
  bool _lastAutoScrollEnabled = false;
  int _lastAutoReadIntervalMs = 0;
  int _lastAutoReadMode = -1;
  final TransformationController _transformationController =
      TransformationController();
  final Set<int> _activeTouchPointers = <int>{};
  bool _isScrollLockedByMultiTouch = false;
  double _currentViewerScale = 1.0;

  static const double _scaleLockThreshold = 1.01;

  bool get _isHistory =>
      _type == ComicEntryType.history ||
      _type == ComicEntryType.historyAndDownload;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _transformationController.addListener(_onTransformationChanged);
    observerController = ListObserverController(controller: scrollController);
    final cubit = context.read<ReaderCubit>();
    _type = widget.type;

    _menuVisibleSubscription = cubit.stream
        .map((state) => state.isMenuVisible)
        .distinct()
        .listen((isMenuVisible) {
          _applySystemUiVisibility(isMenuVisible);
        });

    //初始化核心逻辑控制器
    _actionController = ReaderActionController(
      scrollController: scrollController,
      observerController: observerController,
      pageController: _pageController,
      getReadMode: () => context.read<GlobalSettingCubit>().state.readMode,
      getPageIndex: () => context.read<ReaderCubit>().state.pageIndex,
      getTotalSlots: () => context.read<ReaderCubit>().state.totalSlots,
      getNoAnimation: () =>
          context.read<GlobalSettingCubit>().state.readSetting.noAnimation,
      getAutoScrollColumnDistancePercent: () => context
          .read<GlobalSettingCubit>()
          .state
          .readSetting
          .autoScrollColumnDistancePercent,
      getVolumeKeyPageTurnEnabled: () => context
          .read<GlobalSettingCubit>()
          .state
          .readSetting
          .volumeKeyPageTurn,
      getVolumeKeyPageTurnDistancePercent: () => context
          .read<GlobalSettingCubit>()
          .state
          .readSetting
          .volumeKeyPageTurnDistancePercent,
      getContext: () => _imageSizeContext ?? context,
      onBeforeTurnPage: _restoreScaleBeforeTurnPage,
    );

    // === 初始化音量控制器 ===
    _volumeController = ReaderVolumeController(
      actionController: _actionController,
    );

    // 开始监听
    _volumeController.listen();

    _volumeKeyPageTurnSubscription = context
        .read<GlobalSettingCubit>()
        .stream
        .map((state) => state.readSetting.volumeKeyPageTurn)
        .distinct()
        .listen((_) {
          if (!mounted) return;
          _syncVolumeInterception();
        });

    // === 初始化历史记录管理器 ===
    _historyManager = ReaderHistoryManager(
      comicId: comicId,
      order: widget.order,
      from: widget.from,
      comicInfo: widget.comicInfo,
      historyWriter: HistoryWriter(),
      stringSelectCubit: context.read<StringSelectCubit>(),
      getPageIndex: () => context.read<ReaderCubit>().state.pageIndex + 2,
      getEpInfo: () => epInfo,
    );

    // 执行异步初始化（查询数据库）
    _historyManager.init();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      _syncSystemUi(force: true);

      await Future.delayed(Duration(milliseconds: 200));
      cubit.updateMenuVisible(visible: false);
      _syncVolumeInterception();
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
    _autoReadTimer?.cancel();
    _menuVisibleSubscription?.cancel();
    _volumeKeyPageTurnSubscription?.cancel();
    _systemUiSyncTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _historyManager.stop();
    _volumeController.dispose();
    _readerFocusNode.dispose();
    _transformationController
      ..removeListener(_onTransformationChanged)
      ..dispose();
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

    return BlocProvider(
      create: (context) => ImageSizeCubit.create(
        defaultWidth: width,
        count: epInfo.length,
        historyCount: _historyManager.getHistoryPageIndex(),
      ),
      child: Builder(
        builder: (innerContext) {
          final cubit = innerContext.read<ReaderCubit>();
          final readMode = innerContext.select(
            (GlobalSettingCubit c) => c.state.readMode,
          );
          final readSetting = innerContext.select(
            (GlobalSettingCubit c) => c.state.readSetting,
          );
          final backgroundColor = readSetting.resolveReaderBackgroundColor(
            Theme.of(innerContext).brightness,
          );
          final isDarkMode =
              Theme.of(innerContext).brightness == Brightness.dark;
          final filterOpacityPercent = readSetting.readFilterOpacityPercent
              .clamp(0, 100)
              .toDouble();
          final enableReaderFilter =
              isDarkMode &&
              readSetting.readFilterEnabled &&
              filterOpacityPercent > 0;

          _syncAutoRead(readSetting: readSetting, readMode: readMode);

          _imageSizeContext = innerContext;
          _historyManager.markLoaded();

          cubit.updateTotalSlots(state.epInfo!.length);
          _handleHistoryScroll();

          return Container(
            color: backgroundColor,
            child: Stack(
              children: [
                Positioned.fill(child: _buildInteractiveViewer()),
                if (enableReaderFilter)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: true,
                      child: Container(
                        color: Colors.black.withValues(
                          alpha: filterOpacityPercent / 100,
                        ),
                      ),
                    ),
                  ),
                _pageCountWidget(),
                _comicReadAppBar(),
                _bottomWidget(),
                _autoReadControlWidget(),
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
        cubit.updateSliderChanged(0.0);
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
    final readSetting = globalSettingState.readSetting;
    final isDoubleTapActionEnabled =
        readSetting.doubleTapZoom || readSetting.doubleTapOpenMenu;

    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Focus(
      focusNode: _readerFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        final handled = handleGlobalKeyEvent(event, _actionController);
        return handled ? KeyEventResult.handled : KeyEventResult.ignored;
      },
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUpOrCancel,
        onPointerCancel: _onPointerUpOrCancel,
        onPointerSignal: (event) {
          if (event is PointerScrollEvent && isDesktop) {
            final newCtrlPressed =
                HardwareKeyboard.instance.logicalKeysPressed.contains(
                  LogicalKeyboardKey.controlLeft,
                ) ||
                HardwareKeyboard.instance.logicalKeysPressed.contains(
                  LogicalKeyboardKey.controlRight,
                );

            if (_isCtrlPressed != newCtrlPressed) {
              setState(() {
                _isCtrlPressed = newCtrlPressed;
              });
            }

            // 横版模式下：滚轮翻页
            if (!newCtrlPressed && globalSettingState.readMode != 0) {
              if (event.scrollDelta.dy > 0) {
                _actionController.onPageActionNext();
              } else if (event.scrollDelta.dy < 0) {
                _actionController.onPageActionPrev();
              }
            }
          }
        },
        child: GestureDetector(
          onTap: _onTap,
          onTapDown: (TapDownDetails details) => _tapDownDetails = details,
          onDoubleTapDown: isDoubleTapActionEnabled
              ? (details) => _doubleTapDownDetails = details
              : null,
          onDoubleTap: isDoubleTapActionEnabled ? _onDoubleTap : null,
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: EdgeInsets.zero,
            minScale: 1.0,
            maxScale: 4.0,
            scaleEnabled:
                !isDesktop ||
                _isCtrlPressed ||
                _activeTouchPointers.length >= 2 ||
                _currentViewerScale > _scaleLockThreshold,
            interactionEndFrictionCoefficient: 0.00001,
            onInteractionUpdate: (_) => _updateMultiTouchScrollLock(),
            onInteractionEnd: (_) => _updateMultiTouchScrollLock(),
            child: globalSettingState.readMode == 0
                ? _columnModeWidget()
                : _rowModeWidget(),
          ),
        ),
      ),
    );
  }

  Future<void> _onTap() async {
    // 延迟到下一个循环中执行，避免点击事件冲突
    await Future.delayed(Duration.zero);
    if (_tapDownDetails != null) {
      if (!mounted) return;
      final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
      // 使用保存的details执行处理逻辑
      ReaderGestureLogic.handleTap(
        actionController: _actionController,
        controller: _pageController,
        context: context,
        details: _tapDownDetails!,
        onToggleMenu: readSetting.doubleTapOpenMenu
            ? () {
                final cubit = context.read<ReaderCubit>();
                if (cubit.state.isMenuVisible) {
                  _toggleVisibility();
                }
              }
            : _toggleVisibility,
        onBeforePageTurn: _restoreScaleForPageTurnAction,
      );
      _tapDownDetails = null;
    }
  }

  void _onDoubleTap() {
    if (!mounted) return;
    _tapDownDetails = null;
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;

    if (readSetting.doubleTapZoom) {
      _onDoubleTapZoom();
      return;
    }

    if (readSetting.doubleTapOpenMenu) {
      _onDoubleTapOpenMenu();
    }
  }

  void _onDoubleTapOpenMenu() {
    _toggleVisibility();
    _doubleTapDownDetails = null;
  }

  void _onDoubleTapZoom() {
    final details = _doubleTapDownDetails;
    if (details == null) return;

    if (_resetViewerTransformIfNeeded()) {
      _doubleTapDownDetails = null;
      return;
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      _doubleTapDownDetails = null;
      return;
    }

    final localPosition = renderObject.globalToLocal(details.globalPosition);
    const targetScale = 2.5;
    final matrix = Matrix4.identity()
      ..translateByDouble(
        renderObject.size.width / 2 - localPosition.dx * targetScale,
        renderObject.size.height / 2 - localPosition.dy * targetScale,
        0,
        1,
      )
      ..scaleByDouble(targetScale, targetScale, 1, 1);

    _transformationController.value = matrix;
    _updateMultiTouchScrollLock();
    _doubleTapDownDetails = null;
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
          disableScroll: _isScrollLockedByMultiTouch,
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
      scrollPhysics: _isScrollLockedByMultiTouch
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      onPageDragStart: _restoreScaleForPageDrag,
      from: widget.from,
      jumpChapter: _jumpChapter,
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_isTouchPointer(event.kind)) return;
    _activeTouchPointers.add(event.pointer);
    _updateMultiTouchScrollLock();
  }

  void _onPointerUpOrCancel(PointerEvent event) {
    if (!_isTouchPointer(event.kind)) return;
    _activeTouchPointers.remove(event.pointer);
    _updateMultiTouchScrollLock();
  }

  bool _isTouchPointer(PointerDeviceKind kind) {
    return kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus;
  }

  void _updateMultiTouchScrollLock() {
    _currentViewerScale = _transformationController.value.getMaxScaleOnAxis();
    final shouldLock =
        _activeTouchPointers.length >= 2 ||
        _currentViewerScale > _scaleLockThreshold;
    if (_isScrollLockedByMultiTouch == shouldLock || !mounted) return;
    setState(() {
      _isScrollLockedByMultiTouch = shouldLock;
    });
  }

  void _onTransformationChanged() {
    _updateMultiTouchScrollLock();
  }

  bool _restoreScaleBeforeTurnPage(bool _) {
    _resetViewerTransformIfNeeded();
    return false;
  }

  void _restoreScaleForPageTurnAction() {
    _resetViewerTransformIfNeeded();
  }

  void _restoreScaleForPageDrag() {
    _resetViewerTransformIfNeeded();
  }

  bool _resetViewerTransformIfNeeded() {
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final tx = matrix.storage[12].abs();
    final ty = matrix.storage[13].abs();
    final shouldReset = scale > _scaleLockThreshold || tx > 0.5 || ty > 0.5;

    if (!shouldReset) return false;

    _transformationController.value = Matrix4.identity();
    _activeTouchPointers.clear();
    _updateMultiTouchScrollLock();
    return true;
  }

  /// 切换UI可见性
  void _toggleVisibility() {
    final cubit = context.read<ReaderCubit>();
    cubit.updateMenuVisible();
    _syncVolumeInterception();
    _applySystemUiVisibility(cubit.state.isMenuVisible);
  }

  void _syncVolumeInterception() {
    if (!_isAndroid) return;

    final globalSettingState = context.read<GlobalSettingCubit>().state;
    final isMenuVisible = context.read<ReaderCubit>().state.isMenuVisible;
    final shouldEnable =
        globalSettingState.readSetting.volumeKeyPageTurn && !isMenuVisible;

    if (shouldEnable) {
      _volumeController.enableInterception();
    } else {
      _volumeController.disableInterception();
    }
  }

  @override
  void didChangeMetrics() {
    if (!_isAndroid || !mounted) return;

    if (!context.read<ReaderCubit>().state.isMenuVisible) {
      _scheduleSystemUiSync();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleSystemUiSync(delay: const Duration(milliseconds: 80));
    }
  }

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  void _scheduleSystemUiSync({
    Duration delay = const Duration(milliseconds: 24),
  }) {
    _systemUiSyncTimer?.cancel();
    _systemUiSyncTimer = Timer(delay, () {
      if (!mounted) return;
      _syncSystemUi(force: true);
    });
  }

  void _syncSystemUi({bool force = false}) {
    final isMenuVisible = context.read<ReaderCubit>().state.isMenuVisible;
    _applySystemUiVisibility(isMenuVisible, force: force);
  }

  void _syncAutoRead({
    required ReadSettingState readSetting,
    required int readMode,
  }) {
    final enabled = readSetting.autoScroll;
    final intervalMs =
        (readMode == 0
                ? readSetting.autoScrollColumnIntervalMs
                : readSetting.autoScrollPageIntervalMs)
            .clamp(300, 10000);
    final wasEnabled = _lastAutoScrollEnabled;
    final configChanged =
        _lastAutoScrollEnabled != enabled ||
        _lastAutoReadIntervalMs != intervalMs ||
        _lastAutoReadMode != readMode;

    _lastAutoScrollEnabled = enabled;
    _lastAutoReadIntervalMs = intervalMs;
    _lastAutoReadMode = readMode;

    if (!enabled) {
      _autoReadTimer?.cancel();
      return;
    }

    if (!wasEnabled) {
      _isAutoReadPaused = false;
    }

    if (_isAutoReadPaused) {
      _autoReadTimer?.cancel();
      return;
    }

    if (configChanged || _autoReadTimer == null || !_autoReadTimer!.isActive) {
      _startAutoReadTimer(intervalMs);
    }
  }

  void _startAutoReadTimer(int intervalMs) {
    _autoReadTimer?.cancel();
    _autoReadTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (!mounted) return;
      final readerState = context.read<ReaderCubit>().state;
      if (readerState.isMenuVisible ||
          readerState.isSliderRolling ||
          readerState.isComicRolling) {
        return;
      }
      _actionController.onAutoReadTick();
    });
  }

  void _toggleAutoReadPaused() {
    setState(() {
      _isAutoReadPaused = !_isAutoReadPaused;
    });

    if (_isAutoReadPaused) {
      _autoReadTimer?.cancel();
      return;
    }

    final globalSettingState = context.read<GlobalSettingCubit>().state;
    final intervalMs =
        (globalSettingState.readMode == 0
                ? globalSettingState.readSetting.autoScrollColumnIntervalMs
                : globalSettingState.readSetting.autoScrollPageIntervalMs)
            .clamp(300, 10000);
    _startAutoReadTimer(intervalMs);
  }

  Widget _autoReadControlWidget() {
    return BlocBuilder<GlobalSettingCubit, GlobalSettingState>(
      buildWhen: (previous, current) =>
          previous.readSetting.autoScroll != current.readSetting.autoScroll,
      builder: (context, globalSettingState) {
        if (!globalSettingState.readSetting.autoScroll) {
          return const Positioned.fill(
            child: IgnorePointer(child: SizedBox.shrink()),
          );
        }

        return BlocSelector<ReaderCubit, ReaderState, bool>(
          selector: (state) => state.isMenuVisible,
          builder: (context, isMenuVisible) {
            final bottomSafe = context.bottomSafeHeight;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              right: 14,
              bottom: (isMenuVisible ? 122.0 : 14.0) + bottomSafe,
              child: FloatingActionButton.small(
                heroTag: 'comic_auto_read_toggle',
                tooltip: _isAutoReadPaused ? '继续自动阅读' : '暂停自动阅读',
                onPressed: _toggleAutoReadPaused,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    _isAutoReadPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    key: ValueKey(_isAutoReadPaused),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _applySystemUiVisibility(
    bool isMenuVisible, {
    bool force = false,
  }) async {
    if (!force && _lastMenuVisible == isMenuVisible) return;
    _lastMenuVisible = isMenuVisible;

    if (_isAndroid) {
      if (isMenuVisible) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: <SystemUiOverlay>[],
        );
      }
      return;
    }

    if (isMenuVisible) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // 推迟到下一个事件循环
        await Future.delayed(const Duration(milliseconds: 0));
        if (!mounted) return;
        final cubit = context.read<ReaderCubit>();
        cubit.updatePageIndex(historyIndex);

        final globalSettingState = context.read<GlobalSettingCubit>().state;
        if (globalSettingState.readMode == 0) {
          observerController.jumpTo(
            index: historyIndex - 2,
            offset: (offset) {
              return MediaQuery.of(context).padding.top + 5.0;
            },
          );
        } else {
          _pageController.jumpToPage(historyIndex - 2);
        }
        isSkipped = true;
      });
    }
  }
}
