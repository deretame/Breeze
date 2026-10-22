import 'package:material_ui/material_ui.dart';
import 'package:zephyr/util/debouncer.dart';

import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import 'package:zephyr/widgets/comic_simplify_entry/detail_columns.dart';
import 'package:zephyr/type/enum.dart';

SliverGridDelegate buildComicSimplifyEntryGridDelegate({
  double mainAxisSpacing = 15,
  double crossAxisSpacing = 15,
  double childAspectRatio = 0.75,
}) {
  return SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: isTabletWithOutContext() ? 200.0 : 150.0,
    mainAxisSpacing: mainAxisSpacing,
    crossAxisSpacing: crossAxisSpacing,
    childAspectRatio: childAspectRatio,
  );
}

class BaseComicGridSliver extends StatelessWidget {
  final List<ComicSimplifyEntryInfo> entries;
  final ComicEntryType type;
  final VoidCallback? refresh;
  final ValueChanged<String>? onDeleteSuccess;
  final ValueChanged<ComicSimplifyEntryInfo>? onEntryTap;
  final void Function(
    ComicSimplifyEntryInfo info,
    LongPressStartDetails details,
  )?
  onEntryLongPress;
  final void Function(ComicSimplifyEntryInfo info, TapDownDetails details)?
  onEntrySecondaryTapDown;
  final bool Function(ComicSimplifyEntryInfo entry)? isEntrySelected;
  final bool selectionMode;
  final bool roundedCorner;
  final EdgeInsetsGeometry padding;
  final bool detailed;
  final String? collectionTargetId;
  final String? collectionTargetName;

  const BaseComicGridSliver({
    super.key,
    required this.entries,
    required this.type,
    this.refresh,
    this.onDeleteSuccess,
    this.onEntryTap,
    this.onEntryLongPress,
    this.onEntrySecondaryTapDown,
    this.isEntrySelected,
    this.selectionMode = false,
    this.roundedCorner = true,
    this.padding = const EdgeInsets.all(10),
    this.detailed = false,
    this.collectionTargetId,
    this.collectionTargetName,
  });

  @override
  Widget build(BuildContext context) {
    // 列数只与视口宽有关，MediaQuery 在 build 期快照一次。
    // SliverConstraints 含 scrollOffset，进 SliverLayoutBuilder 会滚动每帧重跑。
    final contentWidth = MediaQuery.sizeOf(context).width - padding.horizontal;
    final columns = detailed ? detailColumnCount(contentWidth) : 1;
    return SliverPadding(
      padding: padding,
      sliver: detailed
          ? DetailColumnsSliver(
              columns: columns,
              itemCount: entries.length,
              itemBuilder: _buildEntry,
            )
          : SliverGrid(
              gridDelegate: buildComicSimplifyEntryGridDelegate(),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildEntry(context, index),
                childCount: entries.length,
              ),
            ),
    );
  }

  Widget _buildEntry(BuildContext context, int index) {
    return ComicSimplifyEntry(
      key: ValueKey(entries[index].id),
      info: entries[index],
      type: type,
      refresh: refresh,
      onDeleteSuccess: onDeleteSuccess,
      onTapOverride: onEntryTap,
      onLongPressOverride: onEntryLongPress,
      onSecondaryTapDown: onEntrySecondaryTapDown,
      isSelected: isEntrySelected?.call(entries[index]) ?? false,
      selectionMode: selectionMode,
      roundedCorner: roundedCorner,
      detailed: detailed,
      collectionTargetId: collectionTargetId,
      collectionTargetName: collectionTargetName,
    );
  }
}

class ComicSimplifyEntryGridView extends StatelessWidget {
  final List<ComicSimplifyEntryInfo> entries;
  final ComicEntryType type;
  final VoidCallback? refresh;
  final ValueChanged<String>? onDeleteSuccess;
  final ValueChanged<ComicSimplifyEntryInfo>? onEntryTap;
  final void Function(
    ComicSimplifyEntryInfo info,
    LongPressStartDetails details,
  )?
  onEntryLongPress;
  final void Function(ComicSimplifyEntryInfo info, TapDownDetails details)?
  onEntrySecondaryTapDown;
  final bool Function(ComicSimplifyEntryInfo entry)? isEntrySelected;
  final bool selectionMode;
  final bool roundedCorner;
  final bool detailed;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const ComicSimplifyEntryGridView({
    super.key,
    required this.entries,
    required this.type,
    this.refresh,
    this.onDeleteSuccess,
    this.onEntryTap,
    this.onEntryLongPress,
    this.onEntrySecondaryTapDown,
    this.isEntrySelected,
    this.selectionMode = false,
    this.roundedCorner = true,
    this.detailed = false,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget itemBuilder(BuildContext context, int index) {
      return ComicSimplifyEntry(
        key: ValueKey(entries[index].id),
        info: entries[index],
        type: type,
        refresh: refresh,
        onDeleteSuccess: onDeleteSuccess,
        onTapOverride: onEntryTap,
        onLongPressOverride: onEntryLongPress,
        isSelected: isEntrySelected?.call(entries[index]) ?? false,
        selectionMode: selectionMode,
        roundedCorner: roundedCorner,
        detailed: detailed,
      );
    }

    if (detailed) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Box 约束无 scrollOffset，进 LayoutBuilder 安全（sliver 版不行）。
          final columns = detailColumnCount(constraints.maxWidth);
          if (columns <= 1) {
            return ListView.separated(
              padding: padding,
              shrinkWrap: shrinkWrap,
              physics: physics,
              itemCount: entries.length,
              itemBuilder: itemBuilder,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: kDetailRowSpacing),
            );
          }
          // 不自己滚：多列拼好交给外层滚动。
          return Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) const SizedBox(width: 10),
                  Expanded(
                    child: DetailBoxColumn(
                      column: c,
                      columns: columns,
                      itemCount: entries.length,
                      itemBuilder: itemBuilder,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    }
    return GridView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: buildComicSimplifyEntryGridDelegate(),
      itemCount: entries.length,
      itemBuilder: itemBuilder,
    );
  }
}

/// 详情多列行间距：行/列统一视觉节奏。
const double kDetailRowSpacing = 8.0;

/// 详情多列：N 列各一个懒加载 SliverList，卡片按内容自然高度排列。
///
/// 不用 SliverGrid：childAspectRatio 会把矮卡片拉高，底部留白。
/// 不用 SliverToBoxAdapter 包 Row+Column：整表全量构建，
/// 首屏只显示十几张却要建几百个行 widget + 封面 Bloc + FFI 转换。
///
/// 书架混排（文件夹+漫画）复用本组件，只需传自己的 itemBuilder。
class DetailColumnsSliver extends StatelessWidget {
  const DetailColumnsSliver({
    super.key,
    required this.columns,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int columns;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (columns <= 1) {
      return SliverList.separated(
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: (context, index) =>
            const SizedBox(height: kDetailRowSpacing),
      );
    }
    return SliverCrossAxisGroup(
      slivers: [
        for (var c = 0; c < columns; c++) ...[
          if (c > 0) const _DetailColumnGutter(),
          SliverCrossAxisExpanded(
            flex: 1,
            sliver: SliverList.separated(
              itemCount: detailColumnItemCount(itemCount, columns, c),
              itemBuilder: (context, row) =>
                  itemBuilder(context, row * columns + c),
              separatorBuilder: (context, index) =>
                  const SizedBox(height: kDetailRowSpacing),
            ),
          ),
        ],
      ],
    );
  }
}

/// 列间 gutter：flex 0 只占 10 宽，主轴高度 0 不影响组高度。
class _DetailColumnGutter extends StatelessWidget {
  const _DetailColumnGutter();

  @override
  Widget build(BuildContext context) {
    return const SliverConstrainedCrossAxis(
      maxExtent: 10,
      sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
    );
  }
}

/// Box 版分列：只建自己列的行，不再整列全量 for 循环。
///
/// 注意：shrinkWrap 场景（discover 嵌套滚动）仍会全量布局，
/// 与原来的 Column 语义一致；真懒加载只在 sliver 路径。
class DetailBoxColumn extends StatelessWidget {
  const DetailBoxColumn({
    super.key,
    required this.column,
    required this.columns,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int column;
  final int columns;
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    final count = detailColumnItemCount(itemCount, columns, column);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (context, row) =>
          itemBuilder(context, row * columns + column),
      separatorBuilder: (context, index) =>
          const SizedBox(height: kDetailRowSpacing),
    );
  }
}
