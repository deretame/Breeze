/// 详情列表多列 helpers：纯函数，可单测.
///
/// 列数只看内容宽度，与滚动位置无关——调用方在 build 期用 MediaQuery
/// 快照宽度后传入。绝不能塞进 SliverLayoutBuilder：SliverConstraints
/// 含 scrollOffset，进去就会滚动每帧重跑（comic_info 的
/// EpisodeSliverMetrics 同款坑）。
/// 行高用 TextPainter 实测（无需 BuildContext），与 _DetailedRowBody 逐项对应。
library;

import 'package:flutter/material.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

/// 详情列表列数：每列最小 340、列间距 10；窄屏 1 列，宽屏 2/3/4 列。
int detailColumnCount(double contentWidth) =>
    ((contentWidth + 10) / 350).floor().clamp(1, 4);

/// 第 [column] 列在共 [columns] 列、总数 [itemCount] 时应有的行数。
///
/// 按 `index = row * columns + column` 交错分列，前面的列至多多一行。
/// 各列行数之和恒等于 [itemCount]。
int detailColumnItemCount(int itemCount, int columns, int column) {
  assert(columns >= 1);
  assert(column >= 0 && column < columns);
  if (itemCount <= column) return 0;
  return (itemCount - 1 - column) ~/ columns + 1;
}

/// 单个详情行的精确高度：与 `_DetailedRowBody` 的布局逐项对应。
///
/// 行高 = padding(6*2) + max(封面 153, 右侧文字区)，
/// 右侧 = 标题(≤3 行) + 作者(0/2 行 + 6) + pills(0/1 行 + 6)。
/// 用 [TextPainter] 按实际文字宽度量，分支与 build 里完全一致：
/// 无作者/无 pills 时整段（含前面的 SizedBox）都不占高。
/// [textWidth] 为右侧文字区宽度（列宽 - 封面 114 - 间距 10 - padding 12）。
double detailRowHeight(
  ComicSimplifyEntryInfo info,
  double textWidth, {
  required TextStyle titleStyle,
  required TextStyle subtitleStyle,
}) {
  double measure(String text, TextStyle style, int maxLines) {
    if (text.trim().isEmpty || textWidth <= 0) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textWidth);
    return painter.height;
  }

  var right = measure(info.title, titleStyle, 3);
  if (info.author.trim().isNotEmpty) {
    right += 6 + measure(info.author, subtitleStyle, 2);
  }
  final pills = info.metadata
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .take(3)
      .toList();
  if (pills.isNotEmpty) {
    right += 6 + measure(pills.join('  '), subtitleStyle, 1) + 12;
  }
  return 12 + (right > 153 ? right : 153);
}
