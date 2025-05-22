import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/bookshelf/mobx/search_status.dart';
import 'package:zephyr/page/bookshelf/models/events.dart';
import 'package:zephyr/page/bookshelf/view/bookshelf_page.dart';

class TopTabBar extends StatelessWidget {
  const TopTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomSlidingSegmentedControl<int>(
      // fromMax: true,
      children: const {
        1: Text('哔咔', textAlign: TextAlign.center),
        2: Text('禁漫', textAlign: TextAlign.center),
      },
      dividerSettings: DividerSettings(
        thickness: 2,
        endIndent: 8,
        indent: 8,
        decoration: BoxDecoration(
          color: materialColorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      isShowDivider: true,
      decoration: BoxDecoration(
        color: materialColorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      thumbDecoration: BoxDecoration(
        color: materialColorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: materialColorScheme.surface.withValues(alpha: .3),
            blurRadius: 4.0,
            spreadRadius: 1.0,
            offset: const Offset(0.0, 2.0),
          ),
        ],
      ),
      onValueChanged: (int value) async {
        bookshelfStore.topBarStore.setDate(value);
        bookshelfStore.favoriteStore = SearchStatusStore();
        bookshelfStore.historyStore = SearchStatusStore();
        bookshelfStore.downloadStore = SearchStatusStore();
        bookshelfStore.jmFavoriteStore = SearchStatusStore();
        eventBus.fire(FavoriteEvent(EventType.refresh, SortType.dd, 0));
        eventBus.fire(HistoryEvent(EventType.refresh));
        eventBus.fire(DownloadEvent(EventType.refresh));
        eventBus.fire(JmFavoriteEvent(EventType.refresh));
        bookshelfStore.tabController!.animateTo(0);
        Future.delayed(const Duration(milliseconds: 100), () {
          if (bookshelfStore.topBarStore.date == 2) {
            eventBus.fire(JmFavoriteEvent(EventType.showInfo));
          }
        });
      },
    );
  }
}
