import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/ranking_list/models/get_info.dart';

import '../bloc/bloc.dart';
import 'comic_ranking.dart';
import 'creator_ranking.dart';

class RankingListPage extends StatefulWidget {
  const RankingListPage({super.key});

  @override
  State<RankingListPage> createState() => _RankingListPageState();
}

class _RankingListPageState extends State<RankingListPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('哔咔排行榜'),
      ),
      body: const HotTabBar(),
    );
  }
}

class HotTabBar extends StatefulWidget {
  const HotTabBar({super.key});

  @override
  State<HotTabBar> createState() => _HotTabBarState();
}

class _HotTabBarState extends State<HotTabBar> with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: '日榜'),
            Tab(text: '周榜'),
            Tab(text: '月榜'),
            Tab(text: '骑士榜'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              SingleChildScrollView(
                child: BlocProvider(
                  create: (_) => ComicListBloc()
                    ..add(FetchComicList(GetInfo(days: "H24", type: "comic"))),
                  child: const ComicRanking(type: "H24"),
                ),
              ),
              SingleChildScrollView(
                child: BlocProvider(
                  create: (_) => ComicListBloc()
                    ..add(FetchComicList(GetInfo(days: "D7", type: "comic"))),
                  child: const ComicRanking(type: "D7"),
                ),
              ),
              SingleChildScrollView(
                child: BlocProvider(
                  create: (_) => ComicListBloc()
                    ..add(FetchComicList(GetInfo(days: "D30", type: "comic"))),
                  child: const ComicRanking(type: "D30"),
                ),
              ),
              SingleChildScrollView(
                child: BlocProvider(
                  create: (_) => CreatorListBloc()
                    ..add(FetchCreatorList(GetInfo(type: "creator"))),
                  child: const CreatorRankingsWidget(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
