part of '../comic_read.dart';

extension _ComicReadSystemUiPart on _ComicReadPageState {
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  static const _systemUiChannel = MethodChannel('system_ui_control');

  void _toggleVisibility() {
    final cubit = context.read<ReaderCubit>();
    cubit.updateMenuVisible();
    _syncVolumeInterception();
    _applySystemUiVisibility(cubit.state.isMenuVisible, force: true);
  }

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

  Future<void> _applySystemUiVisibility(
    bool isMenuVisible, {
    bool force = false,
  }) async {
    if (!force && _lastMenuVisible == isMenuVisible) return;
    _lastMenuVisible = isMenuVisible;

    if (isMenuVisible) {
      if (_isAndroid) {
        await _systemUiChannel.invokeMethod('showSystemBars');
      } else {
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );
      }
    } else {
      if (_isAndroid) {
        await _systemUiChannel.invokeMethod('hideSystemBars');
      } else {
        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      }
    }
  }
}
