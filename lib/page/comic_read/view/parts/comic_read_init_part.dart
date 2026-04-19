part of '../comic_read.dart';

extension _ComicReadInitPart on _ComicReadPageState {
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
      scrollController: scrollController,
      observerController: observerController,
      pageController: _pageController,
      getReadMode: () =>
          context.read<GlobalSettingCubit>().state.readSetting.readMode,
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
        final slotIndex = _isSeamlessEnabled(setting)
            ? _mapGlobalToCurrentChapterLocalSlot(globalSlotIndex)
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
      _syncSystemUi(force: true);
      await Future.delayed(const Duration(milliseconds: 200));
      cubit.updateMenuVisible(visible: false);
      _syncVolumeInterception();
    });
  }

  // 章节跳转器集中初始化，后续查找和替换更快。
  void _initJumpChapter(bool isMenuVisible) {
    _jumpChapter = JumpChapter.create(
      _type,
      isMenuVisible,
      comicInfo,
      widget.order,
      widget.epsNumber,
      comicId,
      widget.from,
    );
    if (_chapterRefs.isEmpty && _jumpChapter.chapters.isNotEmpty) {
      _chapterRefs = List<UnifiedComicChapterRef>.from(_jumpChapter.chapters);
      _chapterOrderToCatalogIndex
        ..clear()
        ..addEntries(
          _chapterRefs.asMap().entries.map(
            (entry) => MapEntry(entry.value.order, entry.key),
          ),
        );
    }
  }

  // 集中释放资源，避免退出后残留订阅和计时器。
  void _disposeReaderResources() {
    _cleanTimer?.cancel();
    _autoReadTimer?.cancel();
    _menuVisibleSubscription?.cancel();
    _volumeKeyPageTurnSubscription?.cancel();
    _systemUiSyncTimer?.cancel();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    _historyManager.stop();
    _volumeController.dispose();
    _readerFocusNode.dispose();
    _transformationController
      ..removeListener(_onTransformationChanged)
      ..dispose();
  }
}
