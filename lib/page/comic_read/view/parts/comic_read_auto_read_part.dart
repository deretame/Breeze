part of '../comic_read.dart';

extension _ComicReadAutoReadPart on _ComicReadPageState {
  // 每次构建时同步自动阅读状态：开关、模式、间隔变化都会重配。
  void _syncAutoRead({
    required ReadSettingState readSetting,
    required int readMode,
  }) {
    _autoReadController.sync(
      readSetting: readSetting,
      readMode: readMode,
      canTick: () {
        final readerState = context.read<ReaderCubit>().state;
        return !readerState.isMenuVisible &&
            !readerState.isSliderRolling &&
            !readerState.isComicRolling;
      },
      onTick: _actionController.onAutoReadTick,
    );
  }

  // 仅暂停计时，不改动用户设置项本身。
  void _toggleAutoReadPaused() {
    _refreshState(() {});
    _autoReadController.togglePaused(
      readSetting: context.read<GlobalSettingCubit>().state.readSetting,
      readMode: context.read<GlobalSettingCubit>().state.readSetting.readMode,
      canTick: () {
        final readerState = context.read<ReaderCubit>().state;
        return !readerState.isMenuVisible &&
            !readerState.isSliderRolling &&
            !readerState.isComicRolling;
      },
      onTick: _actionController.onAutoReadTick,
    );
  }

  // 自动阅读悬浮控制按钮。
  Widget _autoReadControlWidget() {
    return BlocBuilder<GlobalSettingCubit, GlobalSettingState>(
      buildWhen: (previous, current) =>
          previous.readSetting.autoScroll != current.readSetting.autoScroll,
      builder: (context, globalSettingState) {
        if (!globalSettingState.readSetting.autoScroll) {
          return const Positioned.fill(
            child: IgnorePointer(child: SizedBox.shrink()),
          );
        }

        return BlocSelector<ReaderCubit, ReaderState, bool>(
          selector: (state) => state.isMenuVisible,
          builder: (context, isMenuVisible) {
            final bottomSafe = context.bottomSafeHeight;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              right: 14,
              bottom: (isMenuVisible ? 122.0 : 14.0) + bottomSafe,
              child: FloatingActionButton.small(
                heroTag: 'comic_auto_read_toggle',
                tooltip: _autoReadController.isPaused
                    ? t.reader.resumeAutoRead
                    : t.reader.pauseAutoRead,
                onPressed: _toggleAutoReadPaused,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    _autoReadController.isPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    key: ValueKey(_autoReadController.isPaused),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
