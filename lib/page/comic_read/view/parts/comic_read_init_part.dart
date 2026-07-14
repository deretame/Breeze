part of '../comic_read.dart';

extension _ComicReadInitPart on _ComicReadPageState {
  bool get _isDesktopPlatform =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  // 初始化输入控制器：键盘、手势、缩放。
  void _initInputController() {
    _inputController = ReaderInputController(
      context: context,
      readerCubit: context.read<ReaderCubit>(),
      pageController: _pageController,
      transformationController: _transformationController,
      onToggleMenu: _toggleVisibility,
      onToggleDesktopFullscreen: _lifecycleController.toggleDesktopFullscreen,
      onRefreshState: () => _refreshState(() {}),
      isScrollLockedByMultiTouch: () => _isScrollLockedByMultiTouch,
      onUpdateScrollLock: (locked) {
        _refreshState(() {
          _isScrollLockedByMultiTouch = locked;
        });
      },
      buildColumnMode: (enableDoublePage) =>
          _columnModeWidget(enableDoublePage: enableDoublePage),
      buildRowMode: () => _rowModeWidget(),
    );
  }

  // 初始化阅读动作控制器：键盘、点击、自动阅读、音量键共用入口。
  void _initActionController() {
    _actionController = ReaderActionController(
      context: context,
      scrollController: scrollController,
      observerController: observerController,
      pageController: _pageController,
      onBeforeTurnPage: _inputController.restoreScaleBeforeTurnPage,
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
    _volumeController = ReaderVolumeController();
    _volumeController.listen();
  }

  void _setVolumeControllerAction() {
    _volumeController.setActionController(_actionController);
  }

  void _initVolumeKeyPageTurnSubscription() {
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

  // 初始化历史记录控制器，处理进度恢复与落盘。
  void _initHistoryController() {
    // 周期性保存的回调可能在 widget 卸载后仍被触发一次，
    // 因此在这里直接拿到 cubit 引用，避免闭包中继续使用 BuildContext。
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final readerCubit = context.read<ReaderCubit>();
    final seamlessCubit = context.read<ReaderSeamlessCubit>();

    _historyController = ReaderHistoryController(
      comicId: comicId,
      order: widget.order,
      from: widget.from,
      comicInfo: widget.comicInfo,
      stringSelectCubit: context.read<StringSelectCubit>(),
      getPageIndex: () {
        final setting = globalSettingCubit.state.readSetting;
        final globalSlotIndex = readerCubit.state.pageIndex;
        final slotIndex = seamlessCubit.isSeamlessEnabled()
            ? seamlessCubit.mapGlobalToLocalSlot(globalSlotIndex)
            : globalSlotIndex;
        final enableDoublePage = setting.doublePageMode;
        return getStoredHistoryPageIndex(
          slotIndex: slotIndex,
          enableDoublePage: enableDoublePage,
        );
      },
      getCurrentChapterOrder: () => _jumpChapter.order,
      getEpInfo: () => epInfo,
      isHistoryEntry: () => _isHistory,
      jumpToGlobalSlot: (target) => _jumpToGlobalSlot(target),
    );

    unawaited(_historyController.init());
  }

  // 初始化生命周期控制器，订阅菜单/设置变化并执行首帧同步。
  void _initLifecycleController() {
    _lifecycleController = ReaderLifecycleController(
      context: context,
      readerCubit: context.read<ReaderCubit>(),
      systemUiController: _systemUiController,
      volumeController: _volumeController,
      autoReadController: _autoReadController,
      historyController: _historyController,
      onRefreshState: () => _refreshState(() {}),
      onSyncSystemUi: ({force = false}) => _syncSystemUi(force: force),
      onFlushImageSizeCache: () {
        final imageContext = _imageSizeContext;
        if (imageContext != null && imageContext.mounted) {
          unawaited(imageContext.read<ImageSizeCubit>().flushNow());
        }
      },
      isDesktopPlatform: () => _isDesktopPlatform,
    );
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
}
