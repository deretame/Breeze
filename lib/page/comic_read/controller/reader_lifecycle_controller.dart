import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/controller/reader_auto_read_controller.dart';
import 'package:zephyr/page/comic_read/controller/reader_history_controller.dart';
import 'package:zephyr/page/comic_read/controller/reader_system_ui_controller.dart';
import 'package:zephyr/page/comic_read/controller/reader_volume_controller.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/widgets/desktop/desktop_fullscreen_controller.dart';

/// 阅读器生命周期控制器。
///
/// 负责页面初始化、dispose、首帧同步、生命周期回调转发、桌面全屏状态维护。
class ReaderLifecycleController {
  ReaderLifecycleController({
    required this.context,
    required this.readerCubit,
    required this.systemUiController,
    required this.volumeController,
    required this.autoReadController,
    required this.historyController,
    required this.onRefreshState,
    required this.onSyncSystemUi,
    required this.onFlushImageSizeCache,
    required this.isDesktopPlatform,
  });

  final BuildContext context;
  final ReaderCubit readerCubit;
  final ReaderSystemUiController systemUiController;
  final ReaderVolumeController volumeController;
  final ReaderAutoReadController autoReadController;
  final ReaderHistoryController historyController;
  final VoidCallback onRefreshState;
  final void Function({bool force}) onSyncSystemUi;
  final VoidCallback onFlushImageSizeCache;
  final bool Function() isDesktopPlatform;

  StreamSubscription<bool>? _menuVisibleSubscription;

  bool _hasBootstrappedReadState = false;
  bool _isDesktopFullscreen = false;

  bool get hasBootstrappedReadState => _hasBootstrappedReadState;
  bool get isDesktopFullscreen => _isDesktopFullscreen;

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _mounted => context.mounted;

  /// 在 [State.initState] 中调用，完成除各子控制器创建外的初始化工作。
  void init() {
    _initMenuVisibilitySubscription();
    _postFrameBootstrap();
  }

  /// 在 [State.dispose] 中调用，释放本控制器及协调相关资源。
  Future<void> dispose() async {
    await _menuVisibleSubscription?.cancel();
    autoReadController.dispose();
    systemUiController.dispose();
    await systemUiController.restoreSystemBars();
    if (isDesktopPlatform()) {
      await _restoreDesktopFullscreen();
    }
    historyController.stop();
  }

  /// 标记页面已成功 bootstrap 初始阅读状态。
  void markReadStateBootstrapped() => _hasBootstrappedReadState = true;

  /// 桌面端切换全屏。
  Future<void> toggleDesktopFullscreen() async {
    if (!isDesktopPlatform()) return;
    final target = !_isDesktopFullscreen;
    await windowManager.setFullScreen(target);
    if (!_mounted) return;
    onRefreshState();
    _isDesktopFullscreen = target;
    setDesktopReaderFullscreen(target);
    _scheduleSystemUiSync();
  }

  /// 转发 [WidgetsBindingObserver.didChangeMetrics]。
  void didChangeMetrics() {
    if (!_isAndroid || !_mounted) return;
    if (!readerCubit.state.isMenuVisible) {
      _scheduleSystemUiSync();
    }
  }

  /// 转发 [WidgetsBindingObserver.didChangeAppLifecycleState]。
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleSystemUiSync(delay: const Duration(milliseconds: 80));
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      onFlushImageSizeCache();
    }
  }

  void _initMenuVisibilitySubscription() {
    _menuVisibleSubscription = readerCubit.stream
        .map((state) => state.isMenuVisible)
        .distinct()
        .listen((isMenuVisible) {
          systemUiController.applyVisibility(isMenuVisible);
        });
  }

  void _postFrameBootstrap() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_mounted) return;
      if (isDesktopPlatform()) {
        final isFullscreen = await windowManager.isFullScreen();
        onRefreshState();
        _isDesktopFullscreen = isFullscreen;
        setDesktopReaderFullscreen(isFullscreen);
      }
      onSyncSystemUi(force: true);
      await Future.delayed(const Duration(milliseconds: 200));
      if (!_mounted) return;
      readerCubit.updateMenuVisible(visible: false);
      await systemUiController.applyVisibility(false, force: true);
      if (!context.mounted) return;
      final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
      volumeController.sync(readSetting, readerCubit.state.isMenuVisible);
    });
  }

  void _scheduleSystemUiSync({
    Duration delay = const Duration(milliseconds: 24),
  }) {
    systemUiController.scheduleSync(() {
      if (!_mounted) return;
      onSyncSystemUi(force: true);
    }, delay: delay);
  }

  Future<void> _restoreDesktopFullscreen() async {
    setDesktopReaderFullscreen(false);
    if (!isDesktopPlatform()) return;
    if (_isDesktopFullscreen) {
      await windowManager.setFullScreen(false);
    }
  }
}
