part of '../comic_read.dart';

extension _ComicReadViewPart on _ComicReadPageState {
  Widget _comicReadAppBar() {
    final cubit = context.read<ReaderCubit>();
    return ComicReadAppBar(
      title: epInfo.epName,
      isDesktopFullscreen: _isDesktopFullscreen,
      onToggleFullscreen: _isDesktopPlatform
          ? () => unawaited(_toggleDesktopFullscreen())
          : null,
      changePageIndex: (int value) {
        cubit.updatePageIndex(value);
        cubit.updateSliderChanged(0.0);
      },
    );
  }

  Widget _pageCountWidget() {
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    final seamlessCubit = context.read<ReaderSeamlessCubit>();
    final seamlessEnabled = seamlessCubit.isSeamlessEnabled();
    return PageCountWidget(
      epPages: epInfo.epPages,
      getCurrentChapterStartSlot: seamlessEnabled
          ? () => seamlessCubit.currentChapterStartSlot
          : null,
      getCurrentChapterSlotCount: seamlessEnabled
          ? () => seamlessCubit.effectiveCurrentChapterSlotCount()
          : null,
      isTransitionSlot: seamlessEnabled
          ? (globalSlot) =>
                seamlessCubit.isTransitionSlot(globalSlot, readSetting)
          : null,
    );
  }

  Widget _bottomWidget() {
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    final seamlessCubit = context.read<ReaderSeamlessCubit>();
    final seamlessEnabled = seamlessCubit.isSeamlessEnabled();
    final slider = SliderWidget(
      observerController: observerController,
      pageController: _pageController,
      getCurrentChapterSlotCount: seamlessEnabled
          ? () => seamlessCubit.effectiveCurrentChapterSlotCount()
          : null,
      mapGlobalToLocalSlot: seamlessEnabled
          ? seamlessCubit.mapGlobalToLocalSlot
          : null,
      mapLocalToGlobalSlot: seamlessEnabled
          ? seamlessCubit.mapLocalToGlobalSlot
          : null,
      isTransitionSlot: seamlessEnabled
          ? (globalSlot) =>
                seamlessCubit.isTransitionSlot(globalSlot, readSetting)
          : null,
      estimateColumnOffset: seamlessEnabled
          ? (globalSlot) {
              final imageSizeCubit = context.read<ImageSizeCubit>();
              final viewportWidth = MediaQuery.sizeOf(context).width;
              final contentWidth = getConstrainedImageWidth(
                containerWidth: viewportWidth,
                enableSidePadding: readSetting.sidePaddingEnabled,
                sidePaddingPercent: readSetting.sidePaddingPercent,
              );
              final height = seamlessCubit.estimateColumnHeightBeforeGlobalSlot(
                globalSlot,
                readSetting,
                imageSizeCubit,
                contentWidth,
              );
              return height + MediaQuery.of(context).padding.top + 5.0;
            }
          : null,
    );

    return BottomWidget(
      type: _type,
      comicInfo: comicInfo,
      sliderWidget: slider,
      order: widget.order,
      epsNumber: widget.epsNumber,
      comicId: comicId,
      from: widget.from,
      jumpChapter: _jumpChapter,
    );
  }

  // 章节成功加载后恢复历史阅读位置，仅执行一次。
  void _handleHistoryScroll() {
    var shouldScroll = _isHistory && !isSkipped;
    final historyIndex = _historyManager.getHistoryPageIndex();
    if (shouldScroll) {
      shouldScroll &= (historyIndex - 1 != 0);
    }
    if (!shouldScroll) {
      if (_isHistory || isSkipped) return;
      final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
      final seamlessCubit = context.read<ReaderSeamlessCubit>();
      if (!seamlessCubit.isSeamlessEnabled()) {
        isSkipped = true;
        return;
      }

      final totalSlots = context.read<ReaderCubit>().state.totalSlots;
      if (totalSlots <= 0) return;
      final targetIndex = seamlessCubit
          .resolveEntryDefaultGlobalSlot(readSetting)
          .clamp(0, totalSlots - 1);
      if (targetIndex == 0) {
        isSkipped = true;
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(Duration.zero);
        if (!mounted) return;
        await _jumpToGlobalSlot(targetIndex);
        isSkipped = true;
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 延迟到下一事件循环，确保列表/分页容器完成首次布局。
      await Future.delayed(Duration.zero);
      if (!mounted) return;

      final globalSettingState = context.read<GlobalSettingCubit>().state;
      final cubit = context.read<ReaderCubit>();
      final totalSlots = cubit.state.totalSlots;
      if (totalSlots <= 0) return;

      final enableDoublePage = globalSettingState.readSetting.doublePageMode;
      var targetIndex = getSlotIndexFromStoredHistoryPage(
        storedHistoryPage: historyIndex,
        enableDoublePage: enableDoublePage,
      );
      final seamlessCubit = context.read<ReaderSeamlessCubit>();
      if (seamlessCubit.isSeamlessEnabled()) {
        targetIndex = seamlessCubit.resolveHistoryGlobalSlot(
          targetIndex,
          globalSettingState.readSetting,
        );
      }
      targetIndex = targetIndex.clamp(0, totalSlots - 1);
      await _jumpToGlobalSlot(targetIndex);
      isSkipped = true;
    });
  }
}
