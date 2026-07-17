import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/page/comic_read/comic_read.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_seamless_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_seamless_state.dart';
import 'package:zephyr/page/comic_read/cubit/reader_state.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/comic_read/type/chapter_extern.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/type/enum.dart';

// 自动阅读相关：计时器、暂停/继续、悬浮按钮。
part 'parts/comic_read_auto_read_part.dart';
// 初始化与释放：控制器、订阅、历史记录、启动收尾。
part 'parts/comic_read_init_part.dart';
// 交互相关：手势、缩放、指针事件、阅读模式容器。
part 'parts/comic_read_interaction_part.dart';
// 系统 UI 与音量键拦截相关。
part 'parts/comic_read_system_ui_part.dart';
// 页面拼装与历史定位相关。
part 'parts/comic_read_view_part.dart';

@RoutePage()
class ComicReadPage extends StatelessWidget {
  final String comicId;
  final int order;
  final String chapterId;
  final String requestId;
  final String storageChapterId;
  final String logicalKey;
  final ChapterExtern chapterExtern;
  final int epsNumber;
  final String from;
  final ComicEntryType type;
  final dynamic comicInfo;
  final StringSelectCubit stringSelectCubit;

  const ComicReadPage({
    super.key,
    required this.comicId,
    required this.order,
    this.chapterId = '',
    this.requestId = '',
    this.storageChapterId = '',
    this.logicalKey = '',
    this.chapterExtern = const <String, dynamic>{},
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
          create: (_) => PageBloc()
            ..add(
              PageEvent(
                comicId,
                order,
                chapterId,
                requestId,
                storageChapterId,
                logicalKey,
                chapterExtern,
                from,
                type,
                comicInfo: comicInfo,
              ),
            ),
        ),
        BlocProvider.value(value: stringSelectCubit),
        BlocProvider(create: (_) => ReaderCubit()),
        BlocProvider(
          create: (_) => ReaderSeamlessCubit(
            comicId: comicId,
            from: from,
            type: type,
            comicInfo: comicInfo,
            initialOrder: order,
          ),
        ),
      ],
      child: _ComicReadPage(
        comicId: comicId,
        order: order,
        chapterId: chapterId,
        requestId: requestId,
        storageChapterId: storageChapterId,
        logicalKey: logicalKey,
        chapterExtern: chapterExtern,
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
  final String chapterId;
  final String requestId;
  final String storageChapterId;
  final String logicalKey;
  final ChapterExtern chapterExtern;
  final int epsNumber; // 这个的意思是一共有多少章
  final String from;
  final ComicEntryType type;
  final dynamic comicInfo;

  const _ComicReadPage({
    required this.comicId,
    required this.order,
    this.chapterId = '',
    this.requestId = '',
    this.storageChapterId = '',
    this.logicalKey = '',
    this.chapterExtern = const <String, dynamic>{},
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
  late JumpChapter _jumpChapter; // 用来跳转章节的通用类
  late final ReaderActionController _actionController; // 统一动作控制器
  late final ReaderVolumeController _volumeController; // 音量键翻页控制器
  late final ReaderHistoryController _historyController; // 历史记录控制器
  late final ReaderAutoReadController _autoReadController; // 自动阅读控制器
  late final ReaderSystemUiController _systemUiController; // 系统 UI 控制器
  late final ReaderLifecycleController _lifecycleController; // 生命周期控制器
  late final ReaderInputController _inputController; // 输入控制器
  NormalComicEpInfo epInfo = NormalComicEpInfo(); // 通用漫画章节信息
  NormalComicEpInfo _initialEpInfo = NormalComicEpInfo();
  late final ListObserverController observerController; // 列表观察控制器
  final scrollController = ScrollController(); // 列表滚动控制器
  BuildContext? _imageSizeContext;
  final TransformationController _transformationController =
      TransformationController();
  StreamSubscription<bool>? _volumeKeyPageTurnSubscription;
  bool _isScrollLockedByMultiTouch = false;
  bool _isUserScrollActive = false; // 用户是否正在拖拽/惯性滚动列表

  bool get _isHistory =>
      _type == ComicEntryType.history ||
      _type == ComicEntryType.historyAndDownload;

  @override
  void initState() {
    super.initState();
    observerController = ListObserverController(controller: scrollController);
    _type = widget.type;

    _initAutoReadController();
    _initSystemUiController();
    _initHistoryController();
    _initVolumeController();
    _initLifecycleController();
    _initInputController();
    _initActionController();
    _setVolumeControllerAction();
    _inputController.setActionController(_actionController);
    _inputController.init();
    _initVolumeKeyPageTurnSubscription();

    WidgetsBinding.instance.addObserver(this);
    _lifecycleController.init();
    _initJumpChapter(context.read<ReaderCubit>().state.isMenuVisible);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_lifecycleController.dispose());
    _volumeKeyPageTurnSubscription?.cancel();
    _inputController.dispose();
    _volumeController.dispose();
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: BlocListener<ReaderSeamlessCubit, ReaderSeamlessState>(
      listener: (context, seamlessState) {
        final order = seamlessState.currentChapterOrder;
        if (order != null && order != _jumpChapter.order) {
          _syncJumpChapterState(order: order);
        }
        // 章节加载/卸载会改变总槽位和条目，触发重建以同步 ReaderCubit.totalSlots。
        setState(() {});
      },
      child: BlocBuilder<PageBloc, PageState>(
        builder: (context, state) {
          switch (state.status) {
            case PageStatus.initial:
              return const Center(child: CircularProgressIndicator());
            case PageStatus.failure:
              return ComicErrorWidget(
                state: state,
                event: PageEvent(
                  comicId,
                  widget.order,
                  widget.chapterId,
                  widget.requestId,
                  widget.storageChapterId,
                  widget.logicalKey,
                  widget.chapterExtern,
                  widget.from,
                  widget.type,
                  comicInfo: comicInfo,
                ),
              );
            case PageStatus.success:
              if (!_lifecycleController.hasBootstrappedReadState) {
                _lifecycleController.markReadStateBootstrapped();
                epInfo = state.epInfo!;
                _initialEpInfo = state.epInfo!;
                final readSetting = context
                    .read<GlobalSettingCubit>()
                    .state
                    .readSetting;
                context.read<ReaderSeamlessCubit>().bootstrap(
                  epInfo,
                  widget.order,
                  readSetting,
                );
              }
              return ComicReadSuccessWidget(
                comicId: comicId,
                from: widget.from,
                epInfo: _initialEpInfo,
                chapterOrder: widget.order,
                resolveTotalSlots: (readSetting) => context
                    .read<ReaderSeamlessCubit>()
                    .resolveTotalSlots(readSetting),
                buildInteractiveViewer: (_) =>
                    _inputController.buildInteractiveViewer(),
                buildPageCount: (_) => _pageCountWidget(),
                buildAppBar: (_) => _comicReadAppBar(),
                buildBottom: (innerContext) => _bottomWidget(innerContext),
                buildAutoReadControl: (_) => _autoReadControlWidget(),
                onReady: (innerContext, readSetting, readMode) {
                  _syncAutoRead(readSetting: readSetting, readMode: readMode);
                  _imageSizeContext = innerContext;
                  _historyController.markLoaded();
                  unawaited(
                    _historyController.handleHistoryScroll(innerContext),
                  );
                },
              );
          }
        },
      ),
    ),
  );
  @override
  void didChangeMetrics() {
    _lifecycleController.didChangeMetrics();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleController.didChangeAppLifecycleState(state);
  }

  void _refreshState(VoidCallback fn) {
    // 统一走这里触发刷新，避免在异步回调中误调用 setState。
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _jumpToGlobalSlot(
    int targetGlobalSlot, {
    int prependedSlotCount = 0,
  }) async {
    if (!mounted) return;
    final cubit = context.read<ReaderCubit>();
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    final seamlessCubit = context.read<ReaderSeamlessCubit>();
    final totalSlots = seamlessCubit.resolveTotalSlots(readSetting);
    final maxSlot = (totalSlots - 1).clamp(0, 999999999);
    final safeTarget = targetGlobalSlot.clamp(0, maxSlot);
    cubit.updateCurrentSlot(safeTarget);
    cubit.updateSliderChanged(safeTarget.toDouble());
    seamlessCubit.applyCurrentChapterByGlobalSlot(safeTarget, readSetting);

    final readMode = readSetting.readMode;
    if (isColumnReadMode(readMode)) {
      if (!scrollController.hasClients) return;

      // 列模式：先根据已缓存/默认尺寸做粗略同步偏移，
      // 再由 observerController.jumpTo 在 postFrame 做精确修正，
      // 减弱历史恢复、滑动条跳转、章节拼接等场景的视觉跳变。
      final imageContext = _imageSizeContext;
      if (imageContext != null && imageContext.mounted) {
        final imageSizeCubit = imageContext.read<ImageSizeCubit>();
        final containerWidth = MediaQuery.of(context).size.width;
        final contentWidth = getConstrainedImageWidth(
          containerWidth: containerWidth,
          enableSidePadding: readSetting.sidePaddingEnabled,
          sidePaddingPercent: readSetting.sidePaddingPercent,
        );
        final estimatedHeight = seamlessCubit
            .estimateColumnHeightBeforeGlobalSlot(
              safeTarget,
              readSetting,
              imageSizeCubit,
              contentWidth,
            );
        if (estimatedHeight > 0) {
          final newOffset = estimatedHeight + getReaderTopOffset(context);
          scrollController.jumpTo(
            newOffset.clamp(
              scrollController.position.minScrollExtent,
              scrollController.position.maxScrollExtent,
            ),
          );
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !scrollController.hasClients) return;
        observerController.jumpTo(
          index: safeTarget,
          offset: (offset) => getReaderTopOffset(context),
        );
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(safeTarget);
      }
    });
  }
}
