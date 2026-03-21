import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:zephyr/page/ranking_list/view/plugin_paged_comic_list_view.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/jm_url_set.dart';

@RoutePage()
class JmPromoteListPage extends StatelessWidget {
  final int id;
  final String name;

  const JmPromoteListPage({super.key, required this.id, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: PluginPagedComicListView(
        key: ValueKey('promote_list_${id}_$name'),
        from: From.jm,
        fnPath: 'getPromoteListData',
        coreBuilder: (page) => {
          'id': id,
          'page': page,
          'path': '$currentJmBaseUrl/promote_list',
        },
        externBuilder: (_) => const {'source': 'promoteList'},
        itemMapper: (item) => item,
      ),
    );
  }
}
