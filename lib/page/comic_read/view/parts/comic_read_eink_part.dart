part of '../comic_read.dart';

extension _ComicReadEinkPart on _ComicReadPageState {
  /// 墨水屏按页数自动整屏刷新。
  ///
  /// 局刷攒到一定页数后残影会叠成一片，定期走一次全刷把它清掉。
  void _initEinkAutoRefresh() {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    _einkRefreshSubscription = context.read<ReaderCubit>().stream.listen((
      state,
    ) {
      final slot = state.currentSlot;
      final previous = _einkLastSlot;
      _einkLastSlot = slot;
      if (previous < 0 || slot == previous) return;
      // 长图模式滚动时槽位会连续跳变，只在停下来的那次翻页上计次。
      if (state.isComicRolling || state.isSliderRolling) return;

      final globalState = globalSettingCubit.state;
      final eink = globalState.eInkSetting;
      if (!eink.canFullRefresh || eink.autoRefreshTurns == 0) return;
      _einkTurnCount++;
      if (_einkTurnCount < eink.autoRefreshTurns) return;
      _runEinkRefresh(globalState);
    });
  }

  void _runEinkRefresh(GlobalSettingState globalState) {
    _einkTurnCount = 0;
    unawaited(
      EinkRefresh.run(
        globalState.eInkSetting.refreshMode,
        holdMs: globalState.readSetting.einkDelayMs.clamp(50, 500),
      ),
    );
  }

  void _onEinkRefreshButtonTap() {
    final globalState = context.read<GlobalSettingCubit>().state;
    if (!globalState.eInkSetting.canFullRefresh) return;
    _runEinkRefresh(globalState);
  }

  /// 手动整屏刷新按钮，放在自动阅读按钮的斜对角。
  Widget _einkRefreshControlWidget() {
    return BlocBuilder<GlobalSettingCubit, GlobalSettingState>(
      buildWhen: (previous, current) =>
          previous.eInkSetting.enabled != current.eInkSetting.enabled ||
          previous.eInkSetting.refreshMode != current.eInkSetting.refreshMode ||
          previous.eInkSetting.showRefreshButton !=
              current.eInkSetting.showRefreshButton ||
          previous.leftHandModeEnabled != current.leftHandModeEnabled,
      builder: (context, globalSettingState) {
        final eink = globalSettingState.eInkSetting;
        if (!eink.canFullRefresh || !eink.showRefreshButton) {
          return const Positioned.fill(
            child: IgnorePointer(child: SizedBox.shrink()),
          );
        }

        final leftHandMode = globalSettingState.leftHandModeEnabled;
        return BlocSelector<ReaderCubit, ReaderState, bool>(
          selector: (state) => state.isMenuVisible,
          builder: (context, isMenuVisible) {
            final bottomSafe = context.bottomSafeHeight;
            return Positioned(
              left: leftHandMode ? null : 14,
              right: leftHandMode ? 14 : null,
              bottom: (isMenuVisible ? 122.0 : 14.0) + bottomSafe,
              child: FloatingActionButton.small(
                heroTag: 'comic_eink_refresh',
                tooltip: t.settings.einkRefreshNow,
                onPressed: _onEinkRefreshButtonTap,
                child: const Icon(Icons.refresh),
              ),
            );
          },
        );
      },
    );
  }
}
