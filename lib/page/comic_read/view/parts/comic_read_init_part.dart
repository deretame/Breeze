part of '../comic_read.dart';

extension _ComicReadInitPart on _ComicReadPageState {
  bool get _isDesktopPlatform =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  // 监听菜单显隐，并同步系统状态栏/导航栏。
  void _initMenuVisibilitySubscription(ReaderCubit cubit) {
    _menuVisibleSubscription = cubit.stream
        .map((state) => state.isMenuVisible)
        .distinct()
        .listen((isMenuVisible) {
          _applySystemUiVisibility(isMenuVisible);
        });
  }

  // 初始化阅读动作控制器：键盘、点击、自动阅读、音量键共用入口。
  void _initActionController() {
    _actionController = ReaderActionController(
      context: context,
      scrollController: scrollController,
      observerController: observerController,
      pageController: _pageController,
      onBeforeTurnPage: _restoreScaleBeforeTurnPage,
    );
  }

  // 初始化自动阅读控制器。
  void _initAutoReadController() {
    _autoReadController = ReaderAutoReadController();
  }

  // 初始化系统 UI 控制器。
  void _initSystemUiController() {
    _systemUiController = ReaderSystemUiController();
  }

  // 初始化音量键翻页控制，并监听设置项热更新。
  void _initVolumeController() {
    _volumeController = ReaderVolumeController(
      actionController: _actionController,
    );
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
  }

  // 初始化历史记录管理器，处理进度恢复与落盘。
  void _initHistoryManager() {
    _historyManager = ReaderHistoryManager(
      comicId: comicId,
      order: widget.order,
      from: widget.from,
      comicInfo: widget.comicInfo,
      historyWriter: HistoryWriter(),
      stringSelectCubit: context.read<StringSelectCubit>(),
      getCurrentChapterOrder: () => _jumpChapter.order,
      getPageIndex: () {
        final setting = context.read<GlobalSettingCubit>().state.readSetting;
        final globalSlotIndex = context.read<ReaderCubit>().state.pageIndex;
        final seamlessCubit = context.read<ReaderSeamlessCubit>();
        final slotIndex = seamlessCubit.isSeamlessEnabled()
            ? seamlessCubit.mapGlobalToLocalSlot(globalSlotIndex)
            : globalSlotIndex;
        final enableDoublePage = setting.doublePageMode;
        return getStoredHistoryPageIndex(
          slotIndex: slotIndex,
          enableDoublePage: enableDoublePage,
        );
      },
      getEpInfo: () => epInfo,
    );

    _historyManager.init();
  }

  // 首帧后执行一次 UI 同步，避免页面进入时菜单状态闪烁。
  void _postFrameBootstrap(ReaderCubit cubit) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (_isDesktopPlatform) {
        final isFullscreen = await windowManager.isFullScreen();
        _refreshState(() {
          _isDesktopFullscreen = isFullscreen;
        });
        setDesktopReaderFullscreen(isFullscreen);
      }
      _syncSystemUi(force: true);
      await Future.delayed(const Duration(milliseconds: 200));
      cubit.updateMenuVisible(visible: false);
      _applySystemUiVisibility(false, force: true);
      _syncVolumeInterception();
    });
  }

  // 根据当前章节 order 同步 JumpChapter 和 epInfo，供章节选择器/上下章跳转使用。
  void _syncJumpChapterState({required int order}) {
    final seamlessCubit = context.read<ReaderSeamlessCubit>();
    final ref = seamlessCubit.chapterRefByOrder(order);
    final chapter = seamlessCubit.state.loadedChapters.firstWhere(
      (item) => item.order == order,
      orElse: () => seamlessCubit.state.loadedChapters.first,
    );
    if (ref != null) {
      _jumpChapter.order = order;
      _jumpChapter.chapterId = ref.id;
      _jumpChapter.requestId = ref.requestId;
      _jumpChapter.storageChapterId = ref.storageChapterId;
      _jumpChapter.logicalKey = ref.logicalKey;
      _jumpChapter.chapterExtern = Map<String, dynamic>.from(ref.extern);
      final index = seamlessCubit.catalogIndexByOrder(order);
      _jumpChapter.havePrev = index > 0;
      _jumpChapter.haveNext = index < seamlessCubit.catalogLength - 1;
    }
    epInfo = chapter.epInfo;
  }

  // 章节跳转器集中初始化，后续查找和替换更快。
  void _initJumpChapter(bool isMenuVisible) {
    _jumpChapter = JumpChapter.create(
      _type,
      isMenuVisible,
      comicInfo,
      widget.order,
      widget.chapterId,
      widget.requestId,
      widget.storageChapterId,
      widget.logicalKey,
      Map<String, dynamic>.from(widget.chapterExtern),
      widget.epsNumber,
      comicId,
      widget.from,
    );
  }

  // 集中释放资源，避免退出后残留订阅和计时器。
  Future<void> _disposeReaderResources() async {
    _menuVisibleSubscription?.cancel();
    _volumeKeyPageTurnSubscription?.cancel();
    _autoReadController.dispose();
    _systemUiController.dispose();
    await _systemUiController.restoreSystemBars();
    if (_isDesktopPlatform) {
      unawaited(_restoreDesktopFullscreen());
    }
    _pageController.dispose();
    _historyManager.stop();
    _volumeController.dispose();
    _readerFocusNode.dispose();
    _transformationController
      ..removeListener(_onTransformationChanged)
      ..dispose();
  }

  Future<void> _toggleDesktopFullscreen() async {
    if (!_isDesktopPlatform) return;
    final target = !_isDesktopFullscreen;
    await windowManager.setFullScreen(target);
    if (!mounted) return;
    _refreshState(() {
      _isDesktopFullscreen = target;
    });
    setDesktopReaderFullscreen(target);
    _scheduleSystemUiSync();
  }

  Future<void> _restoreDesktopFullscreen() async {
    setDesktopReaderFullscreen(false);
    if (!_isDesktopPlatform) return;
    if (_isDesktopFullscreen) {
      await windowManager.setFullScreen(false);
    }
  }
}
