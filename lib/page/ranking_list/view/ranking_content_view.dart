import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/page/ranking_list/ranking_list.dart';

class RankingContentView extends StatelessWidget {
  const RankingContentView({
    super.key,
    required this.days,
    required this.rankingType,
    required this.card,
  });

  final String days;
  final String rankingType;
  final String card;

  @override
  Widget build(BuildContext context) {
    if (card == 'creator' || rankingType == 'creator') {
      return BlocProvider(
        key: ValueKey('creator_$rankingType'),
        create: (_) =>
            CreatorListBloc()..add(FetchCreatorList(GetInfo(type: 'creator'))),
        child: const CreatorRankingsWidget(),
      );
    }

    return BlocProvider(
      key: ValueKey('comic_${days}_$rankingType'),
      create: (_) => ComicListBloc()
        ..add(FetchComicList(GetInfo(days: days, type: rankingType))),
      child: ComicRanking(type: days),
    );
  }
}
