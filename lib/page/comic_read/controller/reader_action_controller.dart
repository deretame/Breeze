import 'package:flutter/material.dart';

class ReaderActionController {
  final ScrollController scrollController;
  final PageController pageController;
  final int Function() getReadMode; // 0: 竖向, 其他: 横向
  final void Function(bool next)? onJumpChapter;
  final BuildContext context; // 需要 Context 来获取屏幕高度(用于整页翻页)

  ReaderActionController({
    required this.context,
    required this.scrollController,
    required this.pageController,
    required this.getReadMode,
    this.onJumpChapter,
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
      // 竖向：滚动一整屏高度 (减去一点重叠区域，比如80px，防漏看)
      final screenHeight = MediaQuery.of(context).size.height;
      _scrollVertical(offset: screenHeight - 80, durationMs: 250);
    } else {
      _turnPage(isNext: true);
    }
  }

  void onPageActionPrev() {
    final mode = getReadMode();
    if (mode == 0) {
      final screenHeight = MediaQuery.of(context).size.height;
      _scrollVertical(offset: -(screenHeight - 80), durationMs: 250);
    } else {
      _turnPage(isNext: false);
    }
  }

  // ================= 内部实现 =================

  void _scrollVertical({required double offset, required int durationMs}) {
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

  void _turnPage({required bool isNext}) {
    if (!pageController.hasClients) return;
    if (isNext) {
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
