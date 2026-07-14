import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/page/comic_read/controller/reader_action_controller.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/method/key.dart';
import 'package:zephyr/page/comic_read/method/reader_gesture_logic.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';

/// 阅读器输入控制器。
///
/// 负责键盘、手势、滚轮、缩放交互的识别与分发，
/// 把具体动作委托给 [ReaderActionController]，把页面级回调交回 State。
class ReaderInputController {
  ReaderInputController({
    required this.context,
    required this.readerCubit,
    required this.pageController,
    required this.transformationController,
    required this.onToggleMenu,
    required Future<void> Function() onToggleDesktopFullscreen,
    required this.onRefreshState,
    required this.isScrollLockedByMultiTouch,
    required this.onUpdateScrollLock,
    required this.buildColumnMode,
    required this.buildRowMode,
  }) : _onToggleDesktopFullscreen = onToggleDesktopFullscreen;

  final BuildContext context;
  final ReaderCubit readerCubit;
  late ReaderActionController actionController;
  final PageController pageController;
  final TransformationController transformationController;
  final VoidCallback onToggleMenu;
  final Future<void> Function() _onToggleDesktopFullscreen;
  final VoidCallback onRefreshState;
  final bool Function() isScrollLockedByMultiTouch;
  final void Function(bool locked) onUpdateScrollLock;
  final Widget Function(bool enableDoublePage) buildColumnMode;
  final Widget Function() buildRowMode;

  final FocusNode focusNode = FocusNode();
  final Set<int> _activeTouchPointers = <int>{};

  TapDownDetails? _tapDownDetails;
  TapDownDetails? _doubleTapDownDetails;
  bool _isCtrlPressed = false;

  bool get _isDesktopPlatform =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  void setActionController(ReaderActionController controller) {
    actionController = controller;
  }

  void init() {
    transformationController.addListener(_onTransformationChanged);
  }

  void dispose() {
    focusNode.dispose();
  }

  /// 构建阅读核心交互层：键盘、手势、缩放、多指锁滚动。
  Widget buildInteractiveViewer() {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final readSetting = globalSettingState.readSetting;
    final isDoubleTapActionEnabled =
        readSetting.doubleTapZoom || readSetting.doubleTapOpenMenu;

    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUpOrCancel,
        onPointerCancel: _onPointerUpOrCancel,
        onPointerSignal: _onPointerSignal,
        child: GestureDetector(
          onTap: _onTap,
          onTapDown: (details) => _tapDownDetails = details,
          onDoubleTapDown: isDoubleTapActionEnabled
              ? (details) => _doubleTapDownDetails = details
              : null,
          onDoubleTap: isDoubleTapActionEnabled ? _onDoubleTap : null,
          child: InteractiveViewer(
            transformationController: transformationController,
            boundaryMargin: EdgeInsets.zero,
            minScale: kMinReaderScale,
            maxScale: kMaxReaderScale,
            scaleEnabled:
                !_isDesktopPlatform ||
                _isCtrlPressed ||
                _activeTouchPointers.length >= 2 ||
                transformationController.value.getMaxScaleOnAxis() >
                    kScaleLockThreshold,
            interactionEndFrictionCoefficient: kReaderPanFriction,
            onInteractionUpdate: (_) => _updateMultiTouchScrollLock(),
            onInteractionEnd: (_) => _updateMultiTouchScrollLock(),
            child: isColumnReadMode(readSetting.readMode)
                ? buildColumnMode(readSetting.doublePageMode)
                : buildRowMode(),
          ),
        ),
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f11) {
      unawaited(_onToggleDesktopFullscreen());
      return KeyEventResult.handled;
    }
    final handled = handleGlobalKeyEvent(event, actionController);
    return handled ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  Future<void> _onTap() async {
    // 延迟一帧处理，减少单击和双击的手势竞争。
    await Future.delayed(Duration.zero);
    if (_tapDownDetails == null || !context.mounted) return;

    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    ReaderGestureLogic.handleTap(
      actionController: actionController,
      controller: pageController,
      context: context,
      details: _tapDownDetails!,
      onToggleMenu: readSetting.doubleTapOpenMenu
          ? () {
              final cubit = context.read<ReaderCubit>();
              if (cubit.state.isMenuVisible) {
                onToggleMenu();
              }
            }
          : onToggleMenu,
      onBeforePageTurn: restoreScaleForPageTurnAction,
    );
    _tapDownDetails = null;
  }

  void _onDoubleTap() {
    if (!context.mounted) return;
    _tapDownDetails = null;
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    if (readSetting.doubleTapZoom) {
      _onDoubleTapZoom();
      return;
    }
    if (readSetting.doubleTapOpenMenu) {
      _onDoubleTapOpenMenu();
    }
  }

  void _onDoubleTapOpenMenu() {
    onToggleMenu();
    _doubleTapDownDetails = null;
  }

  void _onDoubleTapZoom() {
    final details = _doubleTapDownDetails;
    if (details == null) return;

    if (resetViewerTransformIfNeeded()) {
      _doubleTapDownDetails = null;
      return;
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      _doubleTapDownDetails = null;
      return;
    }

    // 以双击点为锚点放大，手感更自然。
    final localPosition = renderObject.globalToLocal(details.globalPosition);
    const targetScale = kDoubleTapZoomScale;
    final matrix = Matrix4.identity()
      ..translateByDouble(
        renderObject.size.width / 2 - localPosition.dx * targetScale,
        renderObject.size.height / 2 - localPosition.dy * targetScale,
        0,
        1,
      )
      ..scaleByDouble(targetScale, targetScale, 1, 1);

    transformationController.value = matrix;
    _updateMultiTouchScrollLock();
    _doubleTapDownDetails = null;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_isTouchPointer(event.kind)) return;
    _activeTouchPointers.add(event.pointer);
    _updateMultiTouchScrollLock();
  }

  void _onPointerUpOrCancel(PointerEvent event) {
    if (!_isTouchPointer(event.kind)) return;
    _activeTouchPointers.remove(event.pointer);
    _updateMultiTouchScrollLock();
  }

  bool _isTouchPointer(PointerDeviceKind kind) {
    return kind == PointerDeviceKind.touch ||
        kind == PointerDeviceKind.stylus ||
        kind == PointerDeviceKind.invertedStylus;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_isDesktopPlatform) return;

    final newCtrlPressed =
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.controlLeft,
        ) ||
        HardwareKeyboard.instance.logicalKeysPressed.contains(
          LogicalKeyboardKey.controlRight,
        );

    if (_isCtrlPressed != newCtrlPressed) {
      _isCtrlPressed = newCtrlPressed;
      onRefreshState();
    }

    final readMode = context
        .read<GlobalSettingCubit>()
        .state
        .readSetting
        .readMode;
    if (!newCtrlPressed && readMode != 0) {
      if (event.scrollDelta.dy > 0) {
        actionController.onPageActionNext();
      } else if (event.scrollDelta.dy < 0) {
        actionController.onPageActionPrev();
      }
    }
  }

  void _onTransformationChanged() {
    _updateMultiTouchScrollLock();
  }

  // 多指触控或放大状态下锁定滚动，减少与翻页手势互相干扰。
  void _updateMultiTouchScrollLock() {
    final currentScale = transformationController.value.getMaxScaleOnAxis();
    final shouldLock =
        _activeTouchPointers.length >= 2 || currentScale > kScaleLockThreshold;
    if (isScrollLockedByMultiTouch() == shouldLock || !context.mounted) return;
    onUpdateScrollLock(shouldLock);
  }

  /// 翻页前统一归位缩放与位移，避免跨页后仍停留在局部放大状态。
  bool resetViewerTransformIfNeeded() {
    final matrix = transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final tx = matrix.storage[12].abs();
    final ty = matrix.storage[13].abs();
    final shouldReset = scale > kScaleLockThreshold || tx > 0.5 || ty > 0.5;
    if (!shouldReset) return false;

    transformationController.value = Matrix4.identity();
    _activeTouchPointers.clear();
    _updateMultiTouchScrollLock();
    return true;
  }

  /// 供 [ReaderActionController] 翻页前调用。
  bool restoreScaleBeforeTurnPage(bool _) {
    resetViewerTransformIfNeeded();
    return false;
  }

  /// 供 State 在点击翻页前调用。
  void restoreScaleForPageTurnAction() {
    resetViewerTransformIfNeeded();
  }

  /// 供 State 在拖拽翻页前调用。
  void restoreScaleForPageDrag() {
    resetViewerTransformIfNeeded();
  }
}
