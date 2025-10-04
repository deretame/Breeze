import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/config/jm/config.dart';
import 'package:zephyr/page/jm/jm_ranking/widget/widget.dart';

@RoutePage()
class TimeRankingPage extends StatefulWidget {
  final String? title;
  final String tag;

  const TimeRankingPage({super.key, required this.tag, this.title});

  @override
  State<TimeRankingPage> createState() => _TimeRankingPageState();
}

class _TimeRankingPageState extends State<TimeRankingPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  late final List<String> tabs;
  String get tag => widget.tag;

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
    if (widget.title != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title!)),
        body: _body(),
      );
    }
    return _body();
  }

  Widget _body() => Column(
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
                if (JmConfig.categoryMap[tag] is Map) {
                  return CategoryRankingWidget(
                    tag: tag,
                    time: JmConfig.rankingTypeMap[tab]!,
                  );
                }
                return RankingWidget(
                  tag: JmConfig.categoryMap[tag] as String,
                  time: JmConfig.rankingTypeMap[tab]!,
                );
              }).toList(),
        ),
      ),
    ],
  );
}
