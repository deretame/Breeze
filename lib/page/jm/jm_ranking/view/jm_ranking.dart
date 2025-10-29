import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/jm/jm_ranking/widget/widget.dart';

@RoutePage()
class JmRankingPage extends StatefulWidget {
  final String type;

  const JmRankingPage({super.key, this.type = ''});

  @override
  State<JmRankingPage> createState() => _JmRankingPageState();
}

class _JmRankingPageState extends State<JmRankingPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  final List<String> tabs = [
    '最新a漫',
    '同人',
    '单本',
    '短篇',
    '其他类',
    '韩漫',
    'English Manga',
    'Cosplay',
    '3D',
    '禁漫汉化组',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
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
            children: tabs.map((String tab) {
              return Center(child: TimeRankingPage(tag: tab));
            }).toList(),
          ),
        ),
      ],
    );
  }
}
