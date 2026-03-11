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

  Widget _pageCountWidget() => PageCountWidget(epPages: epInfo.epPages);

  Widget _bottomWidget() {
    final slider = SliderWidget(
      observerController: observerController,
      pageController: _pageController,
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
    if (!shouldScroll) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 延迟到下一事件循环，确保列表/分页容器完成首次布局。
      await Future.delayed(Duration.zero);
      if (!mounted) return;

      final cubit = context.read<ReaderCubit>();
      final globalSettingState = context.read<GlobalSettingCubit>().state;
      final totalSlots = cubit.state.totalSlots;
      if (totalSlots <= 0) return;

      final enableDoublePage = globalSettingState.readSetting.doublePageMode;
      final targetIndex = getSlotIndexFromStoredHistoryPage(
        storedHistoryPage: historyIndex,
        enableDoublePage: enableDoublePage,
      ).clamp(0, totalSlots - 1);
      cubit.updatePageIndex(targetIndex);

      if (isColumnReadMode(globalSettingState.readMode)) {
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
