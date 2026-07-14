part of '../comic_read.dart';

extension _ComicReadSystemUiPart on _ComicReadPageState {
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

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
    _volumeController.sync(globalSettingState.readSetting, isMenuVisible);
  }

  void _scheduleSystemUiSync({
    Duration delay = const Duration(milliseconds: 24),
  }) {
    _systemUiController.scheduleSync(() {
      if (!mounted) return;
      _syncSystemUi(force: true);
    }, delay: delay);
  }

  void _syncSystemUi({bool force = false}) {
    final isMenuVisible = context.read<ReaderCubit>().state.isMenuVisible;
    _applySystemUiVisibility(isMenuVisible, force: force);
  }

  Future<void> _applySystemUiVisibility(
    bool isMenuVisible, {
    bool force = false,
  }) async {
    await _systemUiController.applyVisibility(isMenuVisible, force: force);
  }
}
