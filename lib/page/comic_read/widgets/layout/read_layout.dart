import 'dart:math' as math;

import 'package:flutter/material.dart';

const int kReadModeColumn = 0;
const int kReadModeRowLtr = 1;
const int kReadModeRowRtl = 2;

/// 双页模式下左右页之间的间距。
const double kDoublePageGap = 6.0;

bool isColumnReadMode(int readMode) => readMode == kReadModeColumn;

bool isReverseRowReadMode(int readMode) => readMode == kReadModeRowRtl;

int getReadModeSlotCount({
  required int imageCount,
  required bool enableDoublePage,
}) {
  if (imageCount <= 0) return 0;
  if (!enableDoublePage) return imageCount;
  return (imageCount + 1) ~/ 2;
}

int getDisplayPageNumber({
  required int slotIndex,
  required bool enableDoublePage,
}) {
  final normalizedSlot = slotIndex < 0 ? 0 : slotIndex;
  final page = normalizedSlot + 1;
  return enableDoublePage ? (page * 2 - 1) : page;
}

int getStoredHistoryPageIndex({
  required int slotIndex,
  required bool enableDoublePage,
}) {
  return getDisplayPageNumber(
        slotIndex: slotIndex,
        enableDoublePage: enableDoublePage,
      ) +
      1;
}

int getSlotIndexFromStoredHistoryPage({
  required int storedHistoryPage,
  required bool enableDoublePage,
}) {
  if (storedHistoryPage <= 1) return 0;
  final normalized = storedHistoryPage - 2;
  if (!enableDoublePage) {
    return normalized;
  }
  return normalized ~/ 2;
}

/// 阅读器内容顶部偏移。
///
/// 在状态栏下方留出 5.0 的呼吸边距。
double getReaderTopOffset(BuildContext context) {
  return MediaQuery.of(context).padding.top + 5.0;
}

/// 生成稳定的图片尺寸缓存索引。
///
/// 不同章节的同一 localPageIndex 会落到不同 bucket，避免缓存冲突。
int resolveStableSizeCacheIndex({
  required int chapterOrder,
  required int localPageIndex,
}) {
  return 100000 + (Object.hash(chapterOrder, localPageIndex) & 0x3FFFFFFF);
}

double getConstrainedImageWidth({
  required double containerWidth,
  required bool enableSidePadding,
  required int sidePaddingPercent,
}) {
  if (!enableSidePadding) {
    return containerWidth;
  }

  final clampedPercent = sidePaddingPercent.clamp(0, 30).toDouble();
  final widthFactor = (1 - (clampedPercent * 2 / 100)).clamp(0.4, 1.0);
  final targetWidth = containerWidth * widthFactor;
  return math.max(1, targetWidth);
}
