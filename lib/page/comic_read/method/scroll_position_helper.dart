import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ScrollPositionHelper {
  /// 处理滚动位置更新
  static void handleUpdate({
    required BuildContext context,
    required Iterable<ItemPosition> positions,
    required bool isSliderRolling,
    required bool isMounted,
    required ValueChanged<int> onPageIndexChanged,
    double topOffsetFactor = 1 / 3,
  }) {
    if (positions.isEmpty) return;

    final closestPosition = _findClosestPosition(
      context: context,
      positions: positions,
      topOffsetFactor: topOffsetFactor,
    );

    if (closestPosition != null && isMounted && !isSliderRolling) {
      onPageIndexChanged(closestPosition.index);
    }
  }

  /// 查找最接近的滚动位置
  static ItemPosition? _findClosestPosition({
    required BuildContext context,
    required Iterable<ItemPosition> positions,
    required double topOffsetFactor,
  }) {
    final viewport = MediaQuery.of(context).size;
    final topOffset = viewport.height * topOffsetFactor;

    ItemPosition? closestPosition;
    double minDistance = double.infinity;

    for (final position in positions) {
      final itemMiddle = _calculateItemMiddle(position);
      final distance = (topOffset - itemMiddle).abs();

      if (distance < minDistance) {
        minDistance = distance;
        closestPosition = position;
      }
    }

    return closestPosition;
  }

  /// 计算项目中间位置
  static double _calculateItemMiddle(ItemPosition position) {
    final itemHeight = position.itemTrailingEdge - position.itemLeadingEdge;
    return position.itemLeadingEdge + itemHeight / 2;
  }
}
