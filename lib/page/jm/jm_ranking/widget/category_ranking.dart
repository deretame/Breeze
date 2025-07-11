import 'package:flutter/material.dart';
import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/page/jm/jm_ranking/widget/ranking.dart';

class CategoryRankingWidget extends StatefulWidget {
  final String title;
  final String time;

  const CategoryRankingWidget({
    super.key,
    required this.title,
    required this.time,
  });

  @override
  State<CategoryRankingWidget> createState() => _CategoryRankingWidgetState();
}

class _CategoryRankingWidgetState extends State<CategoryRankingWidget>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  Map<String, String> categoryMap = {};
  late final List<String> tabs;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    categoryMap = JmConfig.categoryMap[widget.title]! as Map<String, String>;
    tabs = categoryMap.keys.toList();
    super.initState();
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
                  return RankingWidget(
                    title: categoryMap[tab]!,
                    time: categoryMap[tab]! + widget.time,
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }
}
