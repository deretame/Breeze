part of '../comic_read.dart';

extension _ComicReadViewPart on _ComicReadPageState {
  Widget _comicReadAppBar() {
    final cubit = context.read<ReaderCubit>();
    return ComicReadAppBar(
      title: epInfo.epName,
      isDesktopFullscreen: _lifecycleController.isDesktopFullscreen,
      onToggleFullscreen: _isDesktopPlatform
          ? () => unawaited(_lifecycleController.toggleDesktopFullscreen())
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

  Widget _bottomWidget(BuildContext innerContext) {
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
          ? (context, globalSlot) {
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
              return height + getReaderTopOffset(context);
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
}
