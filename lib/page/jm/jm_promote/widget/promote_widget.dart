import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/page/jm/jm_promote/json/promote/jm_promote_json.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/context/context_extensions.dart';
import 'package:zephyr/util/debouncer.dart';
import 'package:zephyr/util/router/router.gr.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

class _DesktopDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
  };
}

class PromoteWidget extends StatefulWidget {
  final JmPromoteJson element;

  const PromoteWidget({super.key, required this.element});

  @override
  State<PromoteWidget> createState() => _PromoteWidgetState();
}

class _PromoteWidgetState extends State<PromoteWidget> {
  final ScrollController _horizontalController = ScrollController();

  JmPromoteJson get element => widget.element;

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final materialColorScheme = context.theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
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
                          if (element.title.contains("推荐")) {
                            int id = element.id.toString().let(toInt);
                            context.pushRoute(
                              JmPromoteListRoute(id: id, name: element.title),
                            );
                            return;
                          }
                          if (element.title == "连载更新→右滑看更多→") {
                            context.pushRoute(JmWeekRankingRoute());
                            return;
                          }
                          String tag = "";
                          logger.d(element.title);
                          if (element.title == "禁漫汉化组") {
                            tag = "禁漫汉化组";
                          }
                          if (element.title == "韩漫更新") {
                            tag = "hanManTypeMap";
                          }
                          if (element.title == "其他更新") {
                            tag = "qiTaLeiTypeMap";
                          }
                          context.pushRoute(
                            TimeRankingRoute(tag: tag, title: element.title),
                          );
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
      },
    );
  }

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  Widget _buildHorizontalList(double itemWidth) {
    final list = element.content.map((item) {
      return ComicSimplifyEntryInfo(
        title: item.name,
        id: item.id,
        fileServer: getJmCoverUrl(item.id),
        path: '${item.id}.jpg',
        pictureType: PictureType.cover,
        from: From.jm,
      );
    }).toList();

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

    String title = element.title;
    if (element.title == "连载更新→右滑看更多→") {
      title = "$weekStr连载更新";
    }
    return title;
  }
}
