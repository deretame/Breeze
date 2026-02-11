import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/widgets/slider.dart';
import 'package:zephyr/util/volume_key_handler.dart';

/// 专门负责处理音量键翻页逻辑的控制器
class ReaderVolumeController {
  // 外部传入的控制器引用
  final ListObserverController observerController;
  final PageController pageController;

  // 状态获取回调 (从 UI 获取当前状态，因为 Controller 不应该持有这些易变状态)
  final int Function() getReadMode; // 0: 竖向, 1: 横向
  final int Function() getPageIndex;
  final int Function() getTotalSlots;
  final BuildContext Function() getContext;

  StreamSubscription<String>? _subscription;
  bool _isInterceptionEnabled = false;

  ReaderVolumeController({
    required this.observerController,
    required this.pageController,
    required this.getReadMode,
    required this.getPageIndex,
    required this.getTotalSlots,
    required this.getContext,
  });

  /// 开始监听
  void listen() {
    _subscription?.cancel();
    _subscription = VolumeKeyHandler.volumeKeyEvents.listen(_handleEvent);
  }

  /// 停止监听并释放资源
  void dispose() {
    disableInterception();
    _subscription?.cancel();
  }

  /// 开启拦截（通常在 UI 隐藏时调用）
  void enableInterception() {
    if (!_isInterceptionEnabled) {
      VolumeKeyHandler.enableVolumeKeyInterception();
      _isInterceptionEnabled = true;
    }
  }

  /// 关闭拦截（通常在 UI 显示时调用）
  void disableInterception() {
    if (_isInterceptionEnabled) {
      VolumeKeyHandler.disableVolumeKeyInterception();
      _isInterceptionEnabled = false;
    }
  }

  void _handleEvent(String event) {
    final readMode = getReadMode();

    if (event == 'volume_down') {
      // === 音量减键：下一页 ===
      if (readMode == 0) {
        _handleVerticalNext();
      } else {
        _handleHorizontalNext();
      }
    } else if (event == 'volume_up') {
      // === 音量加键：上一页 ===
      if (readMode == 0) {
        _handleVerticalPrev();
      } else {
        _handleHorizontalPrev();
      }
    }
  }

  // --- 竖向模式逻辑 ---

  void _handleVerticalNext() {
    final total = getTotalSlots();

    final scrollIndex = getPageIndex();
    final newScrollIndex = scrollIndex;

    logger.d(
      '音量减 - 竖向: cur=$scrollIndex, new=$newScrollIndex, idx=$scrollIndex',
    );

    if (newScrollIndex < total) {
      _scrollToVertical(newScrollIndex);
    } else {
      logger.d('已经是最后一页了');
    }
  }

  void _handleVerticalPrev() {
    final scrollIndex = getPageIndex();
    final newScrollIndex = scrollIndex - 2;

    logger.d(
      '音量加 - 竖向: cur=$scrollIndex, new=$newScrollIndex, idx=$scrollIndex',
    );

    if (newScrollIndex >= 0) {
      _scrollToVertical(newScrollIndex);
    } else {
      logger.d('已经是第一页了');
    }
  }

  void _scrollToVertical(int index) {
    final context = getContext();
    final offset = getOffset(context, index);
    observerController.controller?.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // --- 横向模式逻辑 ---
  void _handleHorizontalNext() {
    final currentPageIndex = getPageIndex();
    _animateToPage(currentPageIndex);
  }

  void _handleHorizontalPrev() {
    final currentPageIndex = getPageIndex();
    _animateToPage(currentPageIndex - 2);
  }

  void _animateToPage(int page) {
    pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
