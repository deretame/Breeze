import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_grid.dart';

class BookshelfGridShimmer extends StatelessWidget {
  const BookshelfGridShimmer({super.key, this.itemCount = 12});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final shimmerColor = Theme.of(context).colorScheme.surface;

    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: buildComicSimplifyEntryGridDelegate(),
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        return Container(
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
              ),
            )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(
              duration: 1200.ms,
              color: shimmerColor.withValues(alpha: 0.4),
            );
      },
    );
  }
}
