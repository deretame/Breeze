import 'package:material_ui/material_ui.dart';
import 'package:zephyr/util/debouncer.dart';

import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
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
    if (detailed) {
      return SliverPadding(
        padding: padding,
        sliver: SliverLayoutBuilder(
          builder: (context, constraints) {
            // 列数按可用宽度动态算：每列最小 340，间距 10。
            // 窄屏 1 列，宽屏 2/3/4 列，窗口拖动自动切换。
            final columns = ((constraints.crossAxisExtent + 10) / 350)
                .floor()
                .clamp(1, 4);
            if (columns <= 1) {
              return SliverList.separated(
                itemCount: entries.length,
                itemBuilder: (context, index) => _buildEntry(context, index),
                separatorBuilder: (context, index) => const SizedBox(height: 8),
              );
            }
            return _DetailColumnsSliver(
              columns: columns,
              entries: entries,
              itemBuilder: _buildEntry,
            );
          },
        ),
      );
    }
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
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
          final columns = ((constraints.maxWidth + 10) / 350).floor().clamp(
            1,
            4,
          );
          if (columns <= 1) {
            return ListView.separated(
              padding: padding,
              shrinkWrap: shrinkWrap,
              physics: physics,
              itemCount: entries.length,
              itemBuilder: itemBuilder,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
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
                    child: _DetailColumn(
                      start: c,
                      step: columns,
                      entries: entries,
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

/// 详情多列：N 列各一个 Column，卡片按内容自然高度排列。
///
/// 不用 SliverGrid：childAspectRatio 会把矮卡片拉高，底部留白。
class _DetailColumnsSliver extends StatelessWidget {
  const _DetailColumnsSliver({
    required this.columns,
    required this.entries,
    required this.itemBuilder,
  });

  final int columns;
  final List<ComicSimplifyEntryInfo> entries;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var c = 0; c < columns; c++) ...[
            if (c > 0) const SizedBox(width: 10),
            Expanded(
              child: _DetailColumn(
                start: c,
                step: columns,
                entries: entries,
                itemBuilder: itemBuilder,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailColumn extends StatelessWidget {
  const _DetailColumn({
    required this.start,
    required this.step,
    required this.entries,
    required this.itemBuilder,
  });

  final int start;
  final int step;
  final List<ComicSimplifyEntryInfo> entries;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = start; i < entries.length; i += step) ...[
          if (i >= step) const SizedBox(height: 8),
          itemBuilder(context, i),
        ],
      ],
    );
  }
}
