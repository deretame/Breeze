import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/model/unified_comic_list_item_mapper.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/debouncer.dart';

import '../../../widgets/comic_simplify_entry/comic_simplify_entry.dart';
import '../../../widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';

class _DesktopDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };
}

class RecommendWidget extends StatelessWidget {
  final List<Recommend> comicList;

  const RecommendWidget({
    super.key,
    required this.comicList,
  });

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    if (comicList.isEmpty) {
      return SizedBox.shrink();
    }
    final comicInfoList = mapToUnifiedComicSimplifyEntryInfoList(
      comicList.map(unifiedComicFromRecommend),
    );

    Widget scrollView = ComicFixedSizeHorizontalList(
      entries: comicInfoList,
      spacing: 0,
      roundedCorner: false,
      itemWidth: (isTabletWithOutContext() ? 200 : 150) * 0.75,
    );

    if (_isDesktop) {
      scrollView = ScrollConfiguration(
        behavior: _DesktopDragScrollBehavior(),
        child: scrollView,
      );
    }

    return Padding(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: context.theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: scrollView,
        ),
      ),
    );
  }
}
