import 'package:flutter/material.dart';
import 'package:zephyr/page/search_result/widgets/bottom_loader.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/type/enum.dart';

class PluginComicGridSliver extends StatelessWidget {
  const PluginComicGridSliver({
    super.key,
    required this.entries,
    this.type = ComicEntryType.normal,
    this.refresh,
    this.onDeleteSuccess,
    required this.hasReachedMax,
    required this.isLoadingMore,
    required this.loadMoreFailed,
    required this.onRetryLoadMore,
    required this.onLoadMore,
    this.controller,
    this.physics,
    this.shrinkWrap = false,
    this.onEntryTap,
    this.onEntryLongPress,
    this.isEntrySelected,
    this.selectionMode = false,
  });

  final List<ComicSimplifyEntryInfo> entries;
  final ComicEntryType type;
  final VoidCallback? refresh;
  final ValueChanged<String>? onDeleteSuccess;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final VoidCallback onRetryLoadMore;
  final VoidCallback onLoadMore;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final ValueChanged<ComicSimplifyEntryInfo>? onEntryTap;
  final ValueChanged<ComicSimplifyEntryInfo>? onEntryLongPress;
  final bool Function(ComicSimplifyEntryInfo entry)? isEntrySelected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
      slivers: [
        BaseComicGridSliver(
          entries: entries,
          type: type,
          refresh: refresh,
          onDeleteSuccess: onDeleteSuccess,
          onEntryTap: onEntryTap,
          onEntryLongPress: onEntryLongPress,
          isEntrySelected: isEntrySelected,
          selectionMode: selectionMode,
        ),
        if (hasReachedMax)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Text(
                  t.oldHome.noMore,
                  style: const TextStyle(fontSize: 20.0),
                ),
              ),
            ),
          ),
        if (isLoadingMore)
          const SliverToBoxAdapter(child: Center(child: BottomLoader())),
        if (loadMoreFailed)
          SliverToBoxAdapter(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: onRetryLoadMore,
                    child: Text(t.oldHome.loadMoreFailed),
                  ),
                ],
              ),
            ),
          ),
        if (!hasReachedMax && !isLoadingMore && !loadMoreFailed)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14, top: 6),
                child: TextButton.icon(
                  onPressed: onLoadMore,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  label: Text(t.oldHome.loadMore),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
