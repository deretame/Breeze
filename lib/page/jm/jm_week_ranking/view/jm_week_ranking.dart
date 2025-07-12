import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:zephyr/page/jm/jm_week_ranking/jm_week_ranking.dart';

@RoutePage()
class JmWeekRankingPage extends StatefulWidget {
  const JmWeekRankingPage({super.key});

  @override
  State<JmWeekRankingPage> createState() => _JmWeekRankingPageState();
}

class _JmWeekRankingPageState extends State<JmWeekRankingPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  final weekMap = {
    "周一": 1,
    "周二": 2,
    "周三": 3,
    "周四": 4,
    "周五": 5,
    "周六": 6,
    "周日": 7,
    "以完结": 0,
  };
  late final List<String> tags;
  int initialTabIndex = DateTime.now().weekday - 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    tags = weekMap.keys.toList();
    _tabController = TabController(
      length: tags.length,
      vsync: this,
      initialIndex: initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('每周连载更新'),
        bottom: TabBar(
          isScrollable: true,
          controller: _tabController,
          tabs: tags.map((e) => Tab(text: e)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            tags.map((e) {
              return CategoryRankingWidget(week: weekMap[e]!);
            }).toList(),
      ),
    );
  }
}

class CategoryRankingWidget extends StatefulWidget {
  final int week;
  const CategoryRankingWidget({super.key, required this.week});

  @override
  State<CategoryRankingWidget> createState() => _CategoryRankingWidgetState();
}

class _CategoryRankingWidgetState extends State<CategoryRankingWidget>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final TabController _tabController;
  final categoryMap = {"全部": "all", "日漫": "manga", "韩漫": "hanman"};
  late final List<String> tags;

  @override
  void initState() {
    super.initState();
    tags = categoryMap.keys.toList();
    _tabController = TabController(length: tags.length, vsync: this);
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
          tabs: tags.map((e) => Tab(text: e)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children:
                tags.map((e) {
                  return RankingWidget(tag: categoryMap[e]!, week: widget.week);
                }).toList(),
          ),
        ),
      ],
    );
  }
}
