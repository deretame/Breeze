import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/ranking_list/view/filtered_comic_ranking_view.dart';

@RoutePage()
class JmRankingPage extends StatelessWidget {
  final String categoryId;
  final String sortId;

  const JmRankingPage({super.key, this.categoryId = '0', this.sortId = 'new'});

  @override
  Widget build(BuildContext context) {
    final uniqueKey = ValueKey('$categoryId-$sortId');

    return FilteredComicRankingView(
      key: uniqueKey,
      type: categoryId,
      order: sortId,
    );
  }
}
