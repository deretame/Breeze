import 'package:zephyr/util/ui/fluent_compat.dart';
import 'package:scrollview_observer/scrollview_observer.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/widgets/layout/read_layout.dart';

class ReaderActionController {
  final ScrollController scrollController;
  final ListObserverController observerController;
  final PageController pageController;
  final int Function() getReadMode; // 0: 竖向, 其他: 横向
  final BuildContext Function() getContext; // 需要 Context 来获取屏幕高度(用于整页翻页)
  final int Function() getPageIndex;
  final int Function() getTotalSlots;
  final bool Function() getNoAnimation;
  final int Function() getAutoScrollColumnDistancePercent;
  final bool Function() getVolumeKeyPageTurnEnabled;
  final int Function() getVolumeKeyPageTurnDistancePercent;
  final bool Function(bool isNext)? onBeforeTurnPage;

  ReaderActionController({
    required this.scrollController,
    required this.observerController,
    required this.pageController,
    required this.getReadMode,
    required this.getContext,
    required this.getPageIndex,
    required this.getTotalSlots,
    required this.getNoAnimation,
    required this.getAutoScrollColumnDistancePercent,
    required this.getVolumeKeyPageTurnEnabled,
    required this.getVolumeKeyPageTurnDistancePercent,
    this.onBeforeTurnPage,
  });

  // ================= 1. 键盘专用逻辑 (桌面体验) =================
  // 特点：竖向模式下是“微调/平滑滚动”，模拟滚轮效果

  void onKeyScrollNext() {
    final mode = getReadMode();
    if (mode == 0) {
      // 竖向：只滚 200px (平滑小步)
      _scrollVertical(offset: 200.0, durationMs: 100);
    } else {
      // 横向：翻下一页
      _turnPage(isNext: true);
    }
  }

  void onKeyScrollPrev() {
    final mode = getReadMode();
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
    final mode = getReadMode();
    if (mode == 0) {
      _scrollVertical(page: true, next: true);
    } else {
      _turnPage(isNext: true);
    }
  }

  void onPageActionPrev() {
    final mode = getReadMode();
    if (mode == 0) {
      _scrollVertical(page: true, next: false);
    } else {
      _turnPage(isNext: false);
    }
  }

  void onVolumeActionNext() {
    if (!getVolumeKeyPageTurnEnabled()) return;
    final mode = getReadMode();
    if (mode == 0) {
      _scrollVerticalByPercent(
        percent: getVolumeKeyPageTurnDistancePercent(),
        next: true,
      );
    } else {
      _turnPage(isNext: true);
    }
  }

  void onVolumeActionPrev() {
    if (!getVolumeKeyPageTurnEnabled()) return;
    final mode = getReadMode();
    if (mode == 0) {
      _scrollVerticalByPercent(
        percent: getVolumeKeyPageTurnDistancePercent(),
        next: false,
      );
    } else {
      _turnPage(isNext: false);
    }
  }

  void onAutoReadTick() {
    final mode = getReadMode();
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
      final totalSlots = getTotalSlots();
      if (totalSlots <= 0 || !scrollController.hasClients) return;

      final currentPage = getPageIndex() + (next ? 1 : -1);

      final targetPage = currentPage.clamp(0, totalSlots - 1);

      logger.d(
        'index: ${getPageIndex()} currentPage: $currentPage targetPage: $targetPage',
      );

      if (getNoAnimation()) {
        observerController.jumpTo(
          index: targetPage,
          offset: (offset) => (MediaQuery.of(getContext()).padding.top + 5.0),
        );
      } else {
        observerController.animateTo(
          index: targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          offset: (offset) => (MediaQuery.of(getContext()).padding.top + 5.0),
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

    final context = getContext();
    final viewportHeight = MediaQuery.of(context).size.height;
    final distancePercent = getAutoScrollColumnDistancePercent().clamp(10, 100);
    final targetOffset =
        scrollController.offset + viewportHeight * (distancePercent / 100);
    final clamped = targetOffset.clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );

    if (getNoAnimation()) {
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

    final context = getContext();
    final viewportHeight = MediaQuery.of(context).size.height;
    final distancePercent = percent.clamp(10, 100);
    final direction = next ? 1.0 : -1.0;
    final targetOffset =
        scrollController.offset +
        viewportHeight * (distancePercent / 100) * direction;
    final clamped = targetOffset.clamp(
      scrollController.position.minScrollExtent,
      scrollController.position.maxScrollExtent,
    );

    if (getNoAnimation()) {
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

    final readMode = getReadMode();
    final shouldGoForward = isReverseRowReadMode(readMode) ? !isNext : isNext;
    final noAnimation = getNoAnimation();

    if (noAnimation) {
      final totalSlots = getTotalSlots();
      if (totalSlots <= 0) return;

      final currentPage = getPageIndex();
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


