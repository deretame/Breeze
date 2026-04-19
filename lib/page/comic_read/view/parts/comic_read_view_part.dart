part of '../comic_read.dart';

extension _ComicReadViewPart on _ComicReadPageState {
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

  Widget _pageCountWidget() {
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    final seamlessEnabled = _isSeamlessEnabled(readSetting);
    return PageCountWidget(
      epPages: epInfo.epPages,
      getCurrentChapterStartSlot: seamlessEnabled
          ? () => _currentChapterStartSlot
          : null,
      getCurrentChapterSlotCount: seamlessEnabled
          ? _effectiveCurrentChapterSlotCount
          : null,
      isTransitionSlot: seamlessEnabled
          ? (globalSlot) => _isTransitionGlobalSlot(globalSlot, readSetting)
          : null,
    );
  }

  Widget _bottomWidget() {
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    final seamlessEnabled = _isSeamlessEnabled(readSetting);
    final slider = SliderWidget(
      observerController: observerController,
      pageController: _pageController,
      getCurrentChapterSlotCount: seamlessEnabled
          ? _effectiveCurrentChapterSlotCount
          : null,
      mapGlobalToLocalSlot: seamlessEnabled
          ? _mapGlobalToCurrentChapterLocalSlot
          : null,
      mapLocalToGlobalSlot: seamlessEnabled
          ? _mapCurrentChapterLocalToGlobalSlot
          : null,
      isTransitionSlot: seamlessEnabled
          ? (globalSlot) => _isTransitionGlobalSlot(globalSlot, readSetting)
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
      if (!_isSeamlessEnabled(readSetting)) {
        isSkipped = true;
        return;
      }

      final totalSlots = context.read<ReaderCubit>().state.totalSlots;
      if (totalSlots <= 0) return;
      final targetIndex = _resolveEntryDefaultGlobalSlot(
        readSetting,
      ).clamp(0, totalSlots - 1);
      if (targetIndex == 0) {
        isSkipped = true;
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future.delayed(Duration.zero);
        if (!mounted) return;
        final cubit = context.read<ReaderCubit>();
        cubit.updatePageIndex(targetIndex);
        cubit.updateSliderChanged(targetIndex.toDouble());

        if (isColumnReadMode(readSetting.readMode)) {
          observerController.jumpTo(
            index: targetIndex,
            offset: (offset) => MediaQuery.of(context).padding.top + 5.0,
          );
        } else {
          _pageController.jumpToPage(targetIndex);
        }
        isSkipped = true;
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 延迟到下一事件循环，确保列表/分页容器完成首次布局。
      await Future.delayed(Duration.zero);
      if (!mounted) return;

      final cubit = context.read<ReaderCubit>();
      final globalSettingState = context.read<GlobalSettingCubit>().state;
      final totalSlots = cubit.state.totalSlots;
      if (totalSlots <= 0) return;

      final enableDoublePage = globalSettingState.readSetting.doublePageMode;
      var targetIndex = getSlotIndexFromStoredHistoryPage(
        storedHistoryPage: historyIndex,
        enableDoublePage: enableDoublePage,
      );
      if (_isSeamlessEnabled(globalSettingState.readSetting)) {
        targetIndex = _resolveHistoryGlobalSlotWithTransitions(
          baseGlobalSlot: targetIndex,
          readSetting: globalSettingState.readSetting,
        );
      }
      targetIndex = targetIndex.clamp(0, totalSlots - 1);
      cubit.updatePageIndex(targetIndex);

      if (isColumnReadMode(globalSettingState.readSetting.readMode)) {
        observerController.jumpTo(
          index: targetIndex,
          offset: (offset) => MediaQuery.of(context).padding.top + 5.0,
        );
      } else {
        _pageController.jumpToPage(targetIndex);
      }
      isSkipped = true;
    });
  }
}
