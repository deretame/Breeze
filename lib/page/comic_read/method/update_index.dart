import 'package:flutter/cupertino.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../config/global.dart';

Future<void> updateIndex(
  BuildContext context,
  Iterable<ItemPosition> positions,
  bool isSliderRolling,
  int pageIndex,
  bool isComicRolling,
  double currentSliderValue,
  ValueChanged<double> changeChanged,
) async {
  if (positions.isEmpty) return;

  // 提前计算屏幕的三分之一位置
  final viewportHeight = MediaQuery.of(context).size.height;
  final topThird = viewportHeight + statusBarHeight;

  // 找到最接近的项
  final closestPosition = _findClosestPosition(positions, topThird);

  // 更新索引
  if (closestPosition != null &&
      isSliderRolling &&
      pageIndex != closestPosition.index) {
    debugPrint('更新索引：$pageIndex');

    changeChanged(closestPosition.index.toDouble());
  }
}

ItemPosition? _findClosestPosition(
  Iterable<ItemPosition> positions,
  double topThird,
) {
  ItemPosition? closestPosition;
  double minDistance = double.infinity;

  for (final position in positions) {
    // 计算项的中心位置
    final itemHeight = position.itemTrailingEdge - position.itemLeadingEdge;
    final itemMiddle = position.itemLeadingEdge + itemHeight / 2;
    final distance = (topThird - itemMiddle).abs();

    // 找到距离最小的项
    if (distance < minDistance) {
      minDistance = distance;
      closestPosition = position;
    }
  }

  return closestPosition;
}
