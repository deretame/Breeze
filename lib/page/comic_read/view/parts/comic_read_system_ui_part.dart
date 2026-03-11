part of '../comic_read.dart';

extension _ComicReadSystemUiPart on _ComicReadPageState {
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  // 菜单显隐时同时处理系统 UI 与音量键拦截状态。
  void _toggleVisibility() {
    final cubit = context.read<ReaderCubit>();
    cubit.updateMenuVisible();
    _syncVolumeInterception();
    _applySystemUiVisibility(cubit.state.isMenuVisible);
  }

  // Android 下仅在菜单隐藏时拦截音量键用于翻页。
  void _syncVolumeInterception() {
    if (!_isAndroid) return;
    final globalSettingState = context.read<GlobalSettingCubit>().state;
    final isMenuVisible = context.read<ReaderCubit>().state.isMenuVisible;
    final shouldEnable =
        globalSettingState.readSetting.volumeKeyPageTurn && !isMenuVisible;

    if (shouldEnable) {
      _volumeController.enableInterception();
    } else {
      _volumeController.disableInterception();
    }
  }

  // 防抖同步，处理系统栏变化导致的 UI 抢焦问题。
  void _scheduleSystemUiSync({
    Duration delay = const Duration(milliseconds: 24),
  }) {
    _systemUiSyncTimer?.cancel();
    _systemUiSyncTimer = Timer(delay, () {
      if (!mounted) return;
      _syncSystemUi(force: true);
    });
  }

  void _syncSystemUi({bool force = false}) {
    final isMenuVisible = context.read<ReaderCubit>().state.isMenuVisible;
    _applySystemUiVisibility(isMenuVisible, force: force);
  }

  // 根据菜单显隐切换不同平台的系统 UI 模式。
  Future<void> _applySystemUiVisibility(
    bool isMenuVisible, {
    bool force = false,
  }) async {
    if (!force && _lastMenuVisible == isMenuVisible) return;
    _lastMenuVisible = isMenuVisible;

    if (_isAndroid) {
      if (isMenuVisible) {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: <SystemUiOverlay>[],
        );
      }
      return;
    }

    if (isMenuVisible) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    }
  }
}
