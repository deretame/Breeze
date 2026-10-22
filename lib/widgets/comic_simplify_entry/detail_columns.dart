/// 详情列表多列 helpers：纯函数，无 BuildContext 依赖，可单测.
///
/// 列数只看内容宽度，与滚动位置无关——调用方在 build 期用 MediaQuery
/// 快照宽度后传入。绝不能塞进 SliverLayoutBuilder：SliverConstraints
/// 含 scrollOffset，进去就会滚动每帧重跑（comic_info 的
/// EpisodeSliverMetrics 同款坑）。
library;

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
