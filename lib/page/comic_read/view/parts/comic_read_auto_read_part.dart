part of '../comic_read.dart';

extension _ComicReadAutoReadPart on _ComicReadPageState {
  // 每次构建时同步自动阅读状态：开关、模式、间隔变化都会重配。
  void _syncAutoRead({
    required ReadSettingState readSetting,
    required int readMode,
  }) {
    final enabled = readSetting.autoScroll;
    final intervalMs =
        (readMode == 0
                ? readSetting.autoScrollColumnIntervalMs
                : readSetting.autoScrollPageIntervalMs)
            .clamp(300, 10000);
    final wasEnabled = _lastAutoScrollEnabled;
    final configChanged =
        _lastAutoScrollEnabled != enabled ||
        _lastAutoReadIntervalMs != intervalMs ||
        _lastAutoReadMode != readMode;

    _lastAutoScrollEnabled = enabled;
    _lastAutoReadIntervalMs = intervalMs;
    _lastAutoReadMode = readMode;

    if (!enabled) {
      _autoReadTimer?.cancel();
      return;
    }

    if (!wasEnabled) {
      _isAutoReadPaused = false;
    }

    if (_isAutoReadPaused) {
      _autoReadTimer?.cancel();
      return;
    }

    if (configChanged || _autoReadTimer == null || !_autoReadTimer!.isActive) {
      _startAutoReadTimer(intervalMs);
    }
  }

  // 自动阅读 tick 仅在页面静止且菜单隐藏时推进。
  void _startAutoReadTimer(int intervalMs) {
    _autoReadTimer?.cancel();
    _autoReadTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      if (!mounted) return;
      final readerState = context.read<ReaderCubit>().state;
      if (readerState.isMenuVisible ||
          readerState.isSliderRolling ||
          readerState.isComicRolling) {
        return;
      }
      _actionController.onAutoReadTick();
    });
  }

  // 仅暂停计时，不改动用户设置项本身。
  void _toggleAutoReadPaused() {
    _refreshState(() {
      _isAutoReadPaused = !_isAutoReadPaused;
    });

    if (_isAutoReadPaused) {
      _autoReadTimer?.cancel();
      return;
    }

    final globalSettingState = context.read<GlobalSettingCubit>().state;
    final intervalMs =
        (globalSettingState.readSetting.readMode == 0
                ? globalSettingState.readSetting.autoScrollColumnIntervalMs
                : globalSettingState.readSetting.autoScrollPageIntervalMs)
            .clamp(300, 10000);
    _startAutoReadTimer(intervalMs);
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
                tooltip: _isAutoReadPaused ? '继续自动阅读' : '暂停自动阅读',
                onPressed: _toggleAutoReadPaused,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    _isAutoReadPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    key: ValueKey(_isAutoReadPaused),
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
