import 'package:flutter/material.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/debouncer.dart';

import 'comic_simplify_entry.dart';
import 'comic_simplify_entry_info.dart';

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

class ComicSimplifyEntrySliverGrid extends StatelessWidget {
  final List<ComicSimplifyEntryInfo> entries;
  final ComicEntryType type;
  final VoidCallback? refresh;
  final bool roundedCorner;
  final EdgeInsetsGeometry padding;

  const ComicSimplifyEntrySliverGrid({
    super.key,
    required this.entries,
    required this.type,
    this.refresh,
    this.roundedCorner = true,
    this.padding = const EdgeInsets.all(10),
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: buildComicSimplifyEntryGridDelegate(),
        delegate: SliverChildBuilderDelegate((context, index) {
          return ComicSimplifyEntry(
            key: ValueKey(entries[index].id),
            info: entries[index],
            type: type,
            refresh: refresh,
            roundedCorner: roundedCorner,
          );
        }, childCount: entries.length),
      ),
    );
  }
}

class ComicSimplifyEntryGridView extends StatelessWidget {
  final List<ComicSimplifyEntryInfo> entries;
  final ComicEntryType type;
  final VoidCallback? refresh;
  final bool roundedCorner;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const ComicSimplifyEntryGridView({
    super.key,
    required this.entries,
    required this.type,
    this.refresh,
    this.roundedCorner = true,
    this.shrinkWrap = false,
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: buildComicSimplifyEntryGridDelegate(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        return ComicSimplifyEntry(
          key: ValueKey(entries[index].id),
          info: entries[index],
          type: type,
          refresh: refresh,
          roundedCorner: roundedCorner,
        );
      },
    );
  }
}
