part of '../comic_read.dart';

extension _ComicReadInteractionPart on _ComicReadPageState {
  // 阅读核心交互：键盘、手势、缩放、多指锁滚动。
  Widget _buildInteractiveViewer() {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final readSetting = globalSettingState.readSetting;
    final isDoubleTapActionEnabled =
        readSetting.doubleTapZoom || readSetting.doubleTapOpenMenu;
    final isDesktop =
        Platform.isWindows || Platform.isLinux || Platform.isMacOS;

    return Focus(
      focusNode: _readerFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        final handled = handleGlobalKeyEvent(event, _actionController);
        return handled ? KeyEventResult.handled : KeyEventResult.ignored;
      },
      child: Listener(
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUpOrCancel,
        onPointerCancel: _onPointerUpOrCancel,
        onPointerSignal: (event) {
          if (event is! PointerScrollEvent || !isDesktop) return;

          final newCtrlPressed =
              HardwareKeyboard.instance.logicalKeysPressed.contains(
                LogicalKeyboardKey.controlLeft,
              ) ||
              HardwareKeyboard.instance.logicalKeysPressed.contains(
                LogicalKeyboardKey.controlRight,
              );

          if (_isCtrlPressed != newCtrlPressed) {
            _refreshState(() {
              _isCtrlPressed = newCtrlPressed;
            });
          }

          if (!newCtrlPressed && globalSettingState.readSetting.readMode != 0) {
            if (event.scrollDelta.dy > 0) {
              _actionController.onPageActionNext();
            } else if (event.scrollDelta.dy < 0) {
              _actionController.onPageActionPrev();
            }
          }
        },
        child: GestureDetector(
          onTap: _onTap,
          onTapDown: (details) => _tapDownDetails = details,
          onDoubleTapDown: isDoubleTapActionEnabled
              ? (details) => _doubleTapDownDetails = details
              : null,
          onDoubleTap: isDoubleTapActionEnabled ? _onDoubleTap : null,
          child: InteractiveViewer(
            transformationController: _transformationController,
            boundaryMargin: EdgeInsets.zero,
            minScale: 1,
            maxScale: 4,
            scaleEnabled:
                !isDesktop ||
                _isCtrlPressed ||
                _activeTouchPointers.length >= 2 ||
                _currentViewerScale > _ComicReadPageState._scaleLockThreshold,
            interactionEndFrictionCoefficient: 0.00001,
            onInteractionUpdate: (_) => _updateMultiTouchScrollLock(),
            onInteractionEnd: (_) => _updateMultiTouchScrollLock(),
            child: isColumnReadMode(globalSettingState.readSetting.readMode)
                ? _columnModeWidget(
                    enableDoublePage: readSetting.doublePageMode,
                  )
                : _rowModeWidget(),
          ),
        ),
      ),
    );
  }

  Future<void> _onTap() async {
    // 延迟一帧处理，减少单击和双击的手势竞争。
    await Future.delayed(Duration.zero);
    if (_tapDownDetails == null || !mounted) return;

    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    ReaderGestureLogic.handleTap(
      actionController: _actionController,
      controller: _pageController,
      context: context,
      details: _tapDownDetails!,
      onToggleMenu: readSetting.doubleTapOpenMenu
          ? () {
              final cubit = context.read<ReaderCubit>();
              if (cubit.state.isMenuVisible) {
                _toggleVisibility();
              }
            }
          : _toggleVisibility,
      onBeforePageTurn: _restoreScaleForPageTurnAction,
    );
    _tapDownDetails = null;
  }

  void _onDoubleTap() {
    if (!mounted) return;
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
    _toggleVisibility();
    _doubleTapDownDetails = null;
  }

  void _onDoubleTapZoom() {
    final details = _doubleTapDownDetails;
    if (details == null) return;

    if (_resetViewerTransformIfNeeded()) {
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
    const targetScale = 2.5;
    final matrix = Matrix4.identity()
      ..translateByDouble(
        renderObject.size.width / 2 - localPosition.dx * targetScale,
        renderObject.size.height / 2 - localPosition.dy * targetScale,
        0,
        1,
      )
      ..scaleByDouble(targetScale, targetScale, 1, 1);

    _transformationController.value = matrix;
    _updateMultiTouchScrollLock();
    _doubleTapDownDetails = null;
  }

  Widget _columnModeWidget({required bool enableDoublePage}) {
    final readSetting = context.read<GlobalSettingCubit>().state.readSetting;
    final seamlessEnabled = _isSeamlessEnabled(readSetting);
    final entries = _buildColumnEntries(readSetting: readSetting);
    final canLoadPrev = seamlessEnabled
        ? _canLoadPreviousChapter()
        : _jumpChapter.havePrev;
    final canLoadNext = seamlessEnabled
        ? _canLoadNextChapter()
        : _jumpChapter.haveNext;

    return VerticalPullNavigator(
      havePrev: canLoadPrev,
      haveNext: canLoadNext,
      onPrev: () async {
        if (!mounted) return;
        if (seamlessEnabled) {
          await _triggerSeamlessBoundary(previous: true);
          return;
        }
        _jumpChapter.jumpToChapter(context, true);
      },
      onNext: () async {
        if (!mounted) return;
        if (seamlessEnabled) {
          await _triggerSeamlessBoundary(previous: false);
          return;
        }
        _jumpChapter.jumpToChapter(context, false);
      },
      builder: (context, physics) {
        return ColumnModeWidget(
          comicId: comicId,
          entries: entries,
          enableDoublePage: enableDoublePage,
          observerController: observerController,
          scrollController: scrollController,
          from: widget.from,
          parentPhysics: physics,
          disableScroll: _isScrollLockedByMultiTouch,
          volumeController: _volumeController,
          onMiddleSlotObserved: seamlessEnabled
              ? _onSeamlessGlobalSlotObserved
              : null,
          onTransitionAction: seamlessEnabled ? _onTransitionAction : null,
        );
      },
    );
  }

  Widget _rowModeWidget() {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;
    final readSetting = globalSettingState.readSetting;
    final seamlessEnabled = _isSeamlessEnabled(readSetting);
    final entries = _buildRowEntries(readSetting: readSetting);
    final canLoadPrev = seamlessEnabled
        ? _canLoadPreviousChapter()
        : _jumpChapter.havePrev;
    final canLoadNext = seamlessEnabled
        ? _canLoadNextChapter()
        : _jumpChapter.haveNext;
    return RowModeWidget(
      key: ValueKey(readSetting.readMode.toString()),
      comicId: comicId,
      entries: entries,
      pageController: _pageController,
      scrollPhysics: _isScrollLockedByMultiTouch
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      onPageDragStart: _restoreScaleForPageDrag,
      from: widget.from,
      jumpChapter: _jumpChapter,
      volumeController: _volumeController,
      havePrev: canLoadPrev,
      haveNext: canLoadNext,
      onSlotChanged: seamlessEnabled ? _onSeamlessGlobalSlotObserved : null,
      onEdgePrevious: seamlessEnabled
          ? () => _triggerSeamlessBoundary(previous: true)
          : null,
      onEdgeNext: seamlessEnabled
          ? () => _triggerSeamlessBoundary(previous: false)
          : null,
      onTransitionAction: seamlessEnabled ? _onTransitionAction : null,
    );
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

  // 多指触控或放大状态下锁定滚动，减少与翻页手势互相干扰。
  void _updateMultiTouchScrollLock() {
    _currentViewerScale = _transformationController.value.getMaxScaleOnAxis();
    final shouldLock =
        _activeTouchPointers.length >= 2 ||
        _currentViewerScale > _ComicReadPageState._scaleLockThreshold;
    if (_isScrollLockedByMultiTouch == shouldLock || !mounted) return;
    _refreshState(() {
      _isScrollLockedByMultiTouch = shouldLock;
    });
  }

  void _onTransformationChanged() {
    _updateMultiTouchScrollLock();
  }

  bool _restoreScaleBeforeTurnPage(bool _) {
    _resetViewerTransformIfNeeded();
    return false;
  }

  void _restoreScaleForPageTurnAction() {
    _resetViewerTransformIfNeeded();
  }

  void _restoreScaleForPageDrag() {
    _resetViewerTransformIfNeeded();
  }

  bool _resetViewerTransformIfNeeded() {
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    final tx = matrix.storage[12].abs();
    final ty = matrix.storage[13].abs();
    final shouldReset =
        scale > _ComicReadPageState._scaleLockThreshold || tx > 0.5 || ty > 0.5;
    if (!shouldReset) return false;

    // 翻页前统一归位缩放与位移，避免跨页后仍停留在局部放大状态。
    _transformationController.value = Matrix4.identity();
    _activeTouchPointers.clear();
    _updateMultiTouchScrollLock();
    return true;
  }
}
