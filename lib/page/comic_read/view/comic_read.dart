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
  final int epsNumber;
  final String from;
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
          create: (_) => PageBloc()
            ..add(PageEvent(comicId, order, from, type, comicInfo: comicInfo)),
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
  final String from;
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
    _type = widget.type;
    final cubit = context.read<ReaderCubit>();

    _initMenuVisibilitySubscription(cubit);
    _initActionController();
    _initVolumeController();
    _initHistoryManager();
    _postFrameBootstrap(cubit);
    _initJumpChapter(cubit.state.isMenuVisible);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeReaderResources();
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
              event: PageEvent(
                comicId,
                widget.order,
                widget.from,
                widget.type,
                comicInfo: comicInfo,
              ),
            );
          case PageStatus.success:
            epInfo = state.epInfo!;
            return ComicReadSuccessWidget(
              comicId: comicId,
              from: widget.from,
              epInfo: epInfo,
              buildInteractiveViewer: (_) => _buildInteractiveViewer(),
              buildPageCount: (_) => _pageCountWidget(),
              buildAppBar: (_) => _comicReadAppBar(),
              buildBottom: (_) => _bottomWidget(),
              buildAutoReadControl: (_) => _autoReadControlWidget(),
              onReady: (innerContext, readSetting, readMode) {
                _syncAutoRead(readSetting: readSetting, readMode: readMode);
                _imageSizeContext = innerContext;
                _historyManager.markLoaded();
                _handleHistoryScroll();
              },
            );
        }
      },
    ),
  );
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
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      final imageContext = _imageSizeContext;
      if (imageContext != null && imageContext.mounted) {
        unawaited(imageContext.read<ImageSizeCubit>().flushNow());
      }
    }
  }

  void _refreshState(VoidCallback fn) {
    // 统一走这里触发刷新，避免在异步回调中误调用 setState。
    if (!mounted) return;
    setState(fn);
  }
}
