part of '../comic_read.dart';

extension _ComicReadInteractionPart on _ComicReadPageState {
  Widget _columnModeWidget({required bool enableDoublePage}) {
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    final isRtl = isReverseRowReadMode(readSetting.readMode);
    final seamlessCubit = context.read<ReaderSeamlessCubit>();
    final seamlessEnabled = seamlessCubit.isSeamlessEnabled();
    final entries = seamlessCubit.buildColumnEntries(readSetting);
    final canLoadPrev = seamlessEnabled
        ? seamlessCubit.canLoadPreviousChapter()
        : _jumpChapter.havePrev;
    final canLoadNext = seamlessEnabled
        ? seamlessCubit.canLoadNextChapter()
        : _jumpChapter.haveNext;

    return VerticalPullNavigator(
      havePrev: canLoadPrev,
      haveNext: canLoadNext,
      onPrev: () async {
        if (!mounted) return;
        if (seamlessEnabled) {
          final result = await seamlessCubit.triggerBoundary(
            previous: true,
            readSetting: readSetting,
          );
          if (result.targetGlobalSlot != null && mounted) {
            await _jumpToGlobalSlot(
              result.targetGlobalSlot!,
              prependedSlotCount: result.prependedSlotCount,
            );
          }
          return;
        }
        _jumpChapter.jumpToChapter(context, true);
      },
      onNext: () async {
        if (!mounted) return;
        if (seamlessEnabled) {
          final result = await seamlessCubit.triggerBoundary(
            previous: false,
            readSetting: readSetting,
          );
          if (result.targetGlobalSlot != null && mounted) {
            await _jumpToGlobalSlot(
              result.targetGlobalSlot!,
              prependedSlotCount: result.prependedSlotCount,
            );
          }
          return;
        }
        _jumpChapter.jumpToChapter(context, false);
      },
      builder: (context, physics) {
        return ColumnModeWidget(
          comicId: comicId,
          entries: entries,
          enableDoublePage: enableDoublePage,
          isRtl: isRtl,
          observerController: observerController,
          scrollController: scrollController,
          from: widget.from,
          parentPhysics: physics,
          disableScroll: _isScrollLockedByMultiTouch,
          volumeController: _volumeController,
          onGlobalSlotChanged: seamlessEnabled
              ? (globalSlot) async {
                  final result = await seamlessCubit.onGlobalSlotObserved(
                    globalSlot,
                    readSetting,
                  );
                  if (result.targetGlobalSlot != null && mounted) {
                    await _jumpToGlobalSlot(
                      result.targetGlobalSlot!,
                      prependedSlotCount: result.prependedSlotCount,
                    );
                  }
                }
              : (_) {},
          onTransitionAction: seamlessEnabled
              ? (nextOrder) async {
                  final result = await seamlessCubit.onTransitionAction(
                    nextOrder,
                    readSetting,
                    context.read<ReaderCubit>().state.currentSlot,
                  );
                  if (result.targetGlobalSlot != null && mounted) {
                    await _jumpToGlobalSlot(
                      result.targetGlobalSlot!,
                      prependedSlotCount: result.prependedSlotCount,
                    );
                  }
                }
              : (_) {},
        );
      },
    );
  }

  Widget _rowModeWidget() {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final readSetting = globalSettingState.readSetting;
    final seamlessCubit = context.read<ReaderSeamlessCubit>();
    final seamlessEnabled = seamlessCubit.isSeamlessEnabled();
    final entries = seamlessCubit.buildRowEntries(readSetting);
    final canLoadPrev = seamlessEnabled
        ? seamlessCubit.canLoadPreviousChapter()
        : _jumpChapter.havePrev;
    final canLoadNext = seamlessEnabled
        ? seamlessCubit.canLoadNextChapter()
        : _jumpChapter.haveNext;
    return RowModeWidget(
      key: ValueKey(readSetting.readMode.toString()),
      comicId: comicId,
      entries: entries,
      pageController: _pageController,
      scrollPhysics: _isScrollLockedByMultiTouch
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      onPageDragStart: _inputController.restoreScaleForPageDrag,
      from: widget.from,
      jumpChapter: _jumpChapter,
      volumeController: _volumeController,
      havePrev: canLoadPrev,
      haveNext: canLoadNext,
      onGlobalSlotChanged: seamlessEnabled
          ? (globalSlot) async {
              final result = await seamlessCubit.onGlobalSlotObserved(
                globalSlot,
                readSetting,
              );
              if (result.targetGlobalSlot != null && mounted) {
                await _jumpToGlobalSlot(
                  result.targetGlobalSlot!,
                  prependedSlotCount: result.prependedSlotCount,
                );
              }
            }
          : (_) {},
      onEdgePrevious: seamlessEnabled
          ? () async {
              final result = await seamlessCubit.triggerBoundary(
                previous: true,
                readSetting: readSetting,
              );
              if (result.targetGlobalSlot != null && mounted) {
                await _jumpToGlobalSlot(
                  result.targetGlobalSlot!,
                  prependedSlotCount: result.prependedSlotCount,
                );
              }
            }
          : null,
      onEdgeNext: seamlessEnabled
          ? () async {
              final result = await seamlessCubit.triggerBoundary(
                previous: false,
                readSetting: readSetting,
              );
              if (result.targetGlobalSlot != null && mounted) {
                await _jumpToGlobalSlot(
                  result.targetGlobalSlot!,
                  prependedSlotCount: result.prependedSlotCount,
                );
              }
            }
          : null,
      onTransitionAction: seamlessEnabled
          ? (nextOrder) async {
              final result = await seamlessCubit.onTransitionAction(
                nextOrder,
                readSetting,
                context.read<ReaderCubit>().state.currentSlot,
              );
              if (result.targetGlobalSlot != null && mounted) {
                await _jumpToGlobalSlot(
                  result.targetGlobalSlot!,
                  prependedSlotCount: result.prependedSlotCount,
                );
              }
            }
          : (_) {},
    );
  }
}
