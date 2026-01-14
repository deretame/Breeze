import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/volume_key_handler.dart';

/// 专门负责处理音量键翻页逻辑的控制器
class ReaderVolumeController {
  // 外部传入的控制器引用
  final ItemScrollController itemScrollController;
  final PageController pageController;

  // 状态获取回调 (从 UI 获取当前状态，因为 Controller 不应该持有这些易变状态)
  final int Function() getReadMode; // 0: 竖向, 1: 横向
  final double Function() getCurrentSliderValue;
  final int Function() getPageIndex;
  final int Function() getTotalSlots;

  // 状态更新回调 (告诉 UI 更新 Slider 的值)
  final Function(double newValue) onSliderValueChanged;

  StreamSubscription<String>? _subscription;
  bool _isInterceptionEnabled = false;

  ReaderVolumeController({
    required this.itemScrollController,
    required this.pageController,
    required this.getReadMode,
    required this.getCurrentSliderValue,
    required this.getPageIndex,
    required this.getTotalSlots,
    required this.onSliderValueChanged,
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
    final currentSlider = getCurrentSliderValue();
    final total = getTotalSlots();

    final newSliderValue = currentSlider + 1;
    final scrollIndex = newSliderValue.toInt() + 1;

    logger.d(
      '音量减 - 竖向: cur=$currentSlider, new=$newSliderValue, idx=$scrollIndex',
    );

    if (newSliderValue < total) {
      _scrollToVertical(scrollIndex);
      onSliderValueChanged(newSliderValue); // 更新 UI 的 Slider 状态
    } else {
      logger.d('已经是最后一页了');
    }
  }

  void _handleVerticalPrev() {
    final currentSlider = getCurrentSliderValue();

    final newSliderValue = currentSlider - 1;
    final scrollIndex = newSliderValue.toInt() + 1;

    logger.d(
      '音量加 - 竖向: cur=$currentSlider, new=$newSliderValue, idx=$scrollIndex',
    );

    if (newSliderValue >= 0) {
      _scrollToVertical(scrollIndex);
      onSliderValueChanged(newSliderValue); // 更新 UI 的 Slider 状态
    }
  }

  void _scrollToVertical(int index) {
    itemScrollController.scrollTo(
      index: index,
      alignment: 0.0,
      duration: const Duration(milliseconds: 300),
    );
  }

  // --- 横向模式逻辑 ---
  void _handleHorizontalNext() {
    final currentPageIndex = getPageIndex();
    _animateToPage(currentPageIndex - 1);
  }

  void _handleHorizontalPrev() {
    final currentPageIndex = getPageIndex();
    _animateToPage(currentPageIndex - 3);
  }

  void _animateToPage(int page) {
    pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
