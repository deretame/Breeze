import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/ranking_list/view/plugin_paged_comic_list_view.dart';
import 'package:zephyr/type/enum.dart';

@RoutePage()
class JmRankingPage extends StatelessWidget {
  final String categoryId;
  final String sortId;

  const JmRankingPage({super.key, this.categoryId = '0', this.sortId = 'new'});

  @override
  Widget build(BuildContext context) {
    final uniqueKey = ValueKey('$categoryId-$sortId');

    return PluginPagedComicListView(
      key: uniqueKey,
      from: From.jm,
      fnPath: 'getRankingData',
      coreBuilder: (page) => {'page': page},
      externBuilder: (_) => {
        'type': categoryId,
        'order': sortId,
        'source': 'ranking',
      },
      itemMapper: (item) => item,
    );
  }
}
