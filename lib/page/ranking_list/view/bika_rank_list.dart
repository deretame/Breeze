import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/ranking_list/ranking_list.dart';

class BikaRankList extends StatefulWidget {
  const BikaRankList({super.key});

  @override
  State<BikaRankList> createState() => _BikaRankListState();
}

class _BikaRankListState extends State<BikaRankList>
    with TickerProviderStateMixin {
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
              BlocProvider(
                create: (_) => ComicListBloc()
                  ..add(FetchComicList(GetInfo(days: "H24", type: "comic"))),
                child: const ComicRanking(type: "H24"),
              ),
              BlocProvider(
                create: (_) =>
                    ComicListBloc()
                      ..add(FetchComicList(GetInfo(days: "D7", type: "comic"))),
                child: const ComicRanking(type: "D7"),
              ),
              BlocProvider(
                create: (_) => ComicListBloc()
                  ..add(FetchComicList(GetInfo(days: "D30", type: "comic"))),
                child: const ComicRanking(type: "D30"),
              ),
              BlocProvider(
                create: (_) =>
                    CreatorListBloc()
                      ..add(FetchCreatorList(GetInfo(type: "creator"))),
                child: const CreatorRankingsWidget(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
