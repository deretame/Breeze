import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';

class ReaderActionController {
  final BuildContext context;
  final ScrollController scrollController;
  final ListObserverController observerController;
  final PageController pageController;
  final bool Function(bool isNext)? onBeforeTurnPage;

  /// 用户是否正在触摸拖拽/惯性滚动列表（由列表侧的滚动通知维护）。
  final bool Function()? isUserScrolling;

  ReaderActionController({
    required this.context,
    required this.scrollController,
    required this.observerController,
    required this.pageController,
    this.onBeforeTurnPage,
    this.isUserScrolling,
  });

  ReadSettingState get _readSetting =>
      context.read<GlobalSettingCubit>().state.readSetting;

  int get _readMode => _readSetting.readMode;

  int get _currentSlot => context.read<ReaderCubit>().state.currentSlot;

  int get _totalSlots => context.read<ReaderCubit>().state.totalSlots;

  bool get _noAnimation => _readSetting.noAnimation;

  int get _autoScrollColumnDistancePercent =>
      _readSetting.autoScrollColumnDistancePercent;

  bool get _autoScrollSmooth => _readSetting.autoScrollSmooth;

  int get _autoScrollColumnIntervalMs =>
      _readSetting.autoScrollColumnIntervalMs;

  bool get _volumeKeyPageTurnEnabled => _readSetting.volumeKeyPageTurn;

  int get _volumeKeyPageTurnDistancePercent =>
      _readSetting.volumeKeyPageTurnDistancePercent;

  BuildContext get _activeContext => context;

  // ================= 1. 键盘专用逻辑 (桌面体验) =================
  // 特点：竖向模式下是“微调/平滑滚动”，模拟滚轮效果

  void onKeyScrollNext() {
    final mode = _readMode;
    if (mode == 0) {
      // 竖向：只滚 200px (平滑小步)
      _scrollVertical(offset: 200.0, durationMs: 100);
    } else {
      // 横向：翻下一页
      _turnPage(isNext: true);
    }
  }

  void onKeyScrollPrev() {
    final mode = _readMode;
    if (mode == 0) {
      // 竖向：回滚 200px
      _scrollVertical(offset: -200.0, durationMs: 100);
    } else {
      // 横向：翻上一页
      _turnPage(isNext: false);
    }
  }

  // ================= 2. 音量键/点击专用逻辑 (手机体验) =================
  // 特点：竖向模式下是“整页/大幅跳转”，保持快速阅读体验

  void onPageActionNext() {
    final mode = _readMode;
    if (mode == 0) {
      _scrollVertical(page: true, next: true);
    } else {
      _turnPage(isNext: true);
    }
  }

  void onPageActionPrev() {
    final mode = _readMode;
    if (mode == 0) {
      _scrollVertical(page: true, next: false);
    } else {
      _turnPage(isNext: false);
    }
  }

  void onVolumeActionNext() {
    if (!_volumeKeyPageTurnEnabled) return;
    final mode = _readMode;
    if (mode == 0) {
      _scrollVerticalByPercent(
        percent: _volumeKeyPageTurnDistancePercent,
        next: true,
      );
    } else {
      _turnPage(isNext: true);
    }
  }

  void onVolumeActionPrev() {
    if (!_volumeKeyPageTurnEnabled) return;
    final mode = _readMode;
    if (mode == 0) {
      _scrollVerticalByPercent(
        percent: _volumeKeyPageTurnDistancePercent,
        next: false,
      );
    } else {
      _turnPage(isNext: false);
    }
  }

  void onAutoReadTick({double? deltaMs}) {
    final mode = _readMode;
    if (mode == 0) {
      _scrollVerticalAuto(deltaMs: deltaMs);
    } else {
      _turnPage(isNext: true);
    }
  }

  // ================= 内部实现 =================

  void _scrollVertical({
    double offset = 0,
    int durationMs = 0,
    bool page = false,
    bool next = true,
  }) {
    if (page) {
      final totalSlots = _totalSlots;
      if (totalSlots <= 0 || !scrollController.hasClients) return;

      final currentSlot = _currentSlot + (next ? 1 : -1);

      final targetSlot = currentSlot.clamp(0, totalSlots - 1);

      logger.d(
        'index: $_currentSlot currentSlot: $currentSlot targetSlot: $targetSlot',
      );

      if (_noAnimation) {
        observerController.jumpTo(
          index: targetSlot,
          offset: (offset) => getReaderTopOffset(_activeContext),
        );
      } else {
        observerController.animateTo(
          index: targetSlot,
          duration: kReaderAnimationDuration,
          curve: Curves.easeInOut,
          offset: (offset) => getReaderTopOffset(_activeContext),
        );
      }
    } else {
      if (!scrollController.hasClients) return;

      final double currentOffset = scrollController.offset;
      final double targetOffset = currentOffset + offset;
      final clampedOffset = targetOffset.clamp(
        scrollController.position.minScrollExtent,
        scrollController.position.maxScrollExtent,
      );

      if (_noAnimation) {
        scrollController.jumpTo(clampedOffset);
      } else {
        scrollController.animateTo(
          clampedOffset,
          duration: Duration(milliseconds: durationMs),
          curve: Curves.easeOutQuad,
        );
      }
    }
  }

  void _scrollVerticalAuto({double? deltaMs}) {
    if (!scrollController.hasClients) return;

    // 用户触摸拖拽/惯性滚动期间让位，避免自动滚动与手势打架。
    if (isUserScrolling?.call() ?? false) return;

    final viewportHeight = MediaQuery.of(_activeContext).size.height;
    final distancePercent = _autoScrollColumnDistancePercent.clamp(10, 100);
    final stepDistance = viewportHeight * (distancePercent / 100);

    // 平滑模式：速度 = 步距/间隔，按真实帧间隔位移（与 vsync 对齐）。
    if (_autoScrollSmooth && deltaMs != null && deltaMs > 0) {
      final intervalMs = _autoScrollColumnIntervalMs.clamp(300, 5000);
      final delta = stepDistance * (deltaMs / intervalMs);
      final position = scrollController.position;
      final clamped = (position.pixels + delta).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (clamped == position.pixels) return;
      position.jumpTo(clamped);
      return;
    }

    final targetOffset = scrollController.offset + stepDistance;
    final clamped = targetOffset.clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );

    if (_noAnimation) {
      scrollController.jumpTo(clamped);
    } else {
      scrollController.animateTo(
        clamped,
        duration: kReaderSmoothScrollDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollVerticalByPercent({required int percent, required bool next}) {
    if (!scrollController.hasClients) return;

    final viewportHeight = MediaQuery.of(_activeContext).size.height;
    final distancePercent = percent.clamp(10, 100);
    final direction = next ? 1.0 : -1.0;
    final targetOffset =
        scrollController.offset +
        viewportHeight * (distancePercent / 100) * direction;
    final clamped = targetOffset.clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );

    if (_noAnimation) {
      scrollController.jumpTo(clamped);
    } else {
      scrollController.animateTo(
        clamped,
        duration: kReaderSmoothScrollDuration,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _turnPage({required bool isNext}) {
    if (onBeforeTurnPage?.call(isNext) ?? false) return;
    if (!pageController.hasClients) return;

    final shouldGoForward = isNext;
    final noAnimation = _noAnimation;

    if (noAnimation) {
      final totalSlots = _totalSlots;
      if (totalSlots <= 0) return;

      final currentSlot = _currentSlot;
      final targetSlot = (currentSlot + (shouldGoForward ? 1 : -1)).clamp(
        0,
        totalSlots - 1,
      );
      pageController.jumpToPage(targetSlot);
      return;
    }

    if (shouldGoForward) {
      pageController.nextPage(
        duration: kReaderAnimationDuration,
        curve: Curves.easeInOut,
      );
    } else {
      pageController.previousPage(
        duration: kReaderAnimationDuration,
        curve: Curves.easeInOut,
      );
    }
  }
}
