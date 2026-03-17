import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/debouncer.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_mapper.dart';

class _DesktopDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };
}

class PromoteWidget extends StatelessWidget {
  final Map<String, dynamic> section;

  const PromoteWidget({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final materialColorScheme = context.theme.colorScheme;
    final double itemWidth = (isTabletWithOutContext() ? 200 : 150) * 0.75;
    final double itemHeight = itemWidth / 0.75;
    const double headerHeight = 33.0;
    const double verticalPadding = 10.0;

    return SizedBox(
      height: headerHeight + itemHeight + verticalPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(5),
            child: Container(
              decoration: BoxDecoration(
                color: materialColorScheme.secondaryFixed.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              width: double.infinity,
              child: Row(
                children: [
                  Text(
                    getTitle(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: materialColorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      _handleSectionAction(context);
                    },
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: materialColorScheme.onSurface.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: _buildHorizontalList(itemWidth),
            ),
          ),
        ],
      ),
    );
  }

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  Widget _buildHorizontalList(double itemWidth) {
    final items = _asList(section['items'])
        .map((item) => _asMap(item))
        .toList();
    final list = mapToUnifiedComicSimplifyEntryInfoList(items);

    // 将同一个 itemWidth 传给列表，确保内层卡片高度与外层容器完全一致
    Widget scrollView = ComicFixedSizeHorizontalList(
      entries: list,
      spacing: 10.0,
      itemWidth: itemWidth,
    );

    if (_isDesktop) {
      scrollView = ScrollConfiguration(
        behavior: _DesktopDragScrollBehavior(),
        child: scrollView,
      );
    }

    return scrollView;
  }

  String getTitle() {
    DateTime now = DateTime.now();

    int todayWeekday = now.weekday;
    String weekStr;

    switch (todayWeekday) {
      case 1:
        weekStr = "周一";
        break;
      case 2:
        weekStr = "周二";
        break;
      case 3:
        weekStr = "周三";
        break;
      case 4:
        weekStr = "周四";
        break;
      case 5:
        weekStr = "周五";
        break;
      case 6:
        weekStr = "周六";
        break;
      case 7:
        weekStr = "周日";
        break;
      default:
        weekStr = "";
    }

    String title = section['title']?.toString() ?? '';
    if (title == "连载更新→右滑看更多→") {
      title = "$weekStr连载更新";
    }
    return title;
  }

  void _handleSectionAction(BuildContext context) {
    final action = _asMap(section['action']);
    final type = action['type']?.toString() ?? '';
    if (type != 'openRoute') {
      return;
    }

    final payload = _asMap(action['payload']);
    final route = payload['route']?.toString() ?? '';
    final args = _asMap(payload['args']);

    if (route == 'jmPromoteList') {
      context.pushRoute(
        JmPromoteListRoute(
          id: toInt(args['id']),
          name: args['name']?.toString() ?? getTitle(),
        ),
      );
      return;
    }

    if (route == 'jmWeekRanking') {
      context.pushRoute(JmWeekRankingRoute());
      return;
    }

    if (route == 'timeRanking') {
      context.pushRoute(
        TimeRankingRoute(
          tag: args['tag']?.toString() ?? '',
          title: args['title']?.toString() ?? getTitle(),
        ),
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return Map<String, dynamic>.fromEntries(
        value.entries.map((e) => MapEntry(e.key.toString(), e.value)),
      );
    }
    return const <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const <dynamic>[];
  }
}
