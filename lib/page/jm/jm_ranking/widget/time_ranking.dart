import 'package:flutter/material.dart';
import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/page/jm/jm_ranking/widget/widget.dart';

class TimeRankingWidget extends StatefulWidget {
  final String title;

  const TimeRankingWidget({super.key, required this.title});

  @override
  State<TimeRankingWidget> createState() => _TimeRankingWidgetState();
}

class _TimeRankingWidgetState extends State<TimeRankingWidget>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  late final List<String> tabs;
  String get title => widget.title;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    tabs = JmConfig.rankingTypeMap.keys.toList();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        TabBar(
          isScrollable: true,
          controller: _tabController,
          tabs: tabs.map((e) => Tab(text: e)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children:
                tabs.map((String tab) {
                  if (JmConfig.categoryMap[title] is Map) {
                    return CategoryRankingWidget(
                      title: title,
                      time: JmConfig.rankingTypeMap[tab]!,
                    );
                  }
                  return RankingWidget(
                    title: title,
                    time: JmConfig.rankingTypeMap[tab]!,
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
