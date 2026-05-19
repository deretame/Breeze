import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';

class ReaderActionController {
  final BuildContext context;
  final ScrollController scrollController;
  final ListObserverController observerController;
  final PageController pageController;
  final bool Function(bool isNext)? onBeforeTurnPage;

  ReaderActionController({
    required this.context,
    required this.scrollController,
    required this.observerController,
    required this.pageController,
    this.onBeforeTurnPage,
  });

  ReadSettingState get _readSetting =>
      context.read<GlobalSettingCubit>().state.readSetting;

  int get _readMode => _readSetting.readMode;

  int get _pageIndex => context.read<ReaderCubit>().state.pageIndex;

  int get _totalSlots => context.read<ReaderCubit>().state.totalSlots;

  bool get _noAnimation => _readSetting.noAnimation;

  int get _autoScrollColumnDistancePercent =>
      _readSetting.autoScrollColumnDistancePercent;

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

  void onAutoReadTick() {
    final mode = _readMode;
    if (mode == 0) {
      _scrollVerticalAuto();
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

      final currentPage = _pageIndex + (next ? 1 : -1);

      final targetPage = currentPage.clamp(0, totalSlots - 1);

      logger.d(
        'index: $_pageIndex currentPage: $currentPage targetPage: $targetPage',
      );

      if (_noAnimation) {
        observerController.jumpTo(
          index: targetPage,
          offset: (offset) => (MediaQuery.of(_activeContext).padding.top + 5.0),
        );
      } else {
        observerController.animateTo(
          index: targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          offset: (offset) => (MediaQuery.of(_activeContext).padding.top + 5.0),
        );
      }
    } else {
      if (!scrollController.hasClients) return;

      final double currentOffset = scrollController.offset;
      final double targetOffset = currentOffset + offset;

      scrollController.animateTo(
        targetOffset.clamp(
          scrollController.position.minScrollExtent,
          scrollController.position.maxScrollExtent,
        ),
        duration: Duration(milliseconds: durationMs),
        curve: Curves.easeOutQuad,
      );
    }
  }

  void _scrollVerticalAuto() {
    if (!scrollController.hasClients) return;

    final viewportHeight = MediaQuery.of(_activeContext).size.height;
    final distancePercent = _autoScrollColumnDistancePercent.clamp(10, 100);
    final targetOffset =
        scrollController.offset + viewportHeight * (distancePercent / 100);
    final clamped = targetOffset.clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );

    if (_noAnimation) {
      scrollController.jumpTo(clamped);
    } else {
      scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 260),
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
        duration: const Duration(milliseconds: 260),
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

      final currentPage = _pageIndex;
      final targetPage = (currentPage + (shouldGoForward ? 1 : -1)).clamp(
        0,
        totalSlots - 1,
      );
      pageController.jumpToPage(targetPage);
      return;
    }

    if (shouldGoForward) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
