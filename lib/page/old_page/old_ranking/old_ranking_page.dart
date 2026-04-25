import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/plugin_registry_cubit.dart';
import 'package:zephyr/page/comic_list/models/comic_list_scene.dart';
import 'package:zephyr/page/comic_list/view/comic_list_page.dart';

@RoutePage()
class OldRankingPage extends StatefulWidget {
  const OldRankingPage({super.key});

  @override
  State<OldRankingPage> createState() => _OldRankingPageState();
}

class _OldRankingPageState extends State<OldRankingPage> {
  static const String _bikaPluginId = '0a0e5858-a467-4702-994a-79e608a4589d';
  static const String _jmPluginId = 'bf99008d-010b-4f17-ac7c-61a9b57dc3d9';

  late final ComicListScene _bikaRankingScene;
  late final ComicListScene _jmRankingScene;

  int _panelIndex = 0;

  @override
  void initState() {
    super.initState();
    _bikaRankingScene = ComicListScene.fromMap({
      'title': '哔咔排行榜',
      'source': _bikaPluginId,
      'body': {
        'type': 'pluginPagedComicList',
        'request': {
          'fnPath': 'getRankingData',
          'core': {'days': 'H24', 'type': 'comic'},
          'extern': {'source': 'ranking'},
        },
      },
      'filter': {
        'fnPath': 'getRankingFilterBundle',
        'extern': {'source': 'ranking'},
      },
    });

    _jmRankingScene = ComicListScene.fromMap({
      'title': '禁漫排行榜',
      'source': _jmPluginId,
      'list': {
        'fnPath': 'getRankingData',
        'extern': {'source': 'ranking'},
      },
      'filter': {
        'fnPath': 'getRankingFilterBundle',
        'extern': {'source': 'ranking'},
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final pluginStates = context.watch<PluginRegistryCubit>().state;
    final hasBika = pluginStates[_bikaPluginId]?.isActive == true;
    final hasJm = pluginStates[_jmPluginId]?.isActive == true;

    final panels = <Widget>[
      if (hasJm)
        ComicListScaffold(
          key: const PageStorageKey('old_ranking_jm'),
          scene: _jmRankingScene,
          title: _jmRankingScene.title,
        ),
      if (hasBika)
        ComicListScaffold(
          key: const PageStorageKey('old_ranking_bika'),
          scene: _bikaRankingScene,
          title: _bikaRankingScene.title,
        ),
    ];
    final hasAnyPanel = panels.isNotEmpty;
    final effectiveIndex = panels.length <= 1
        ? 0
        : _panelIndex.clamp(0, panels.length - 1);

    return Scaffold(
      body: hasAnyPanel
          ? IndexedStack(index: effectiveIndex, children: panels)
          : const SizedBox.expand(),
      floatingActionButton: panels.length > 1
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _panelIndex = effectiveIndex == 0 ? 1 : 0;
                });
              },
              tooltip: '切换',
              child: const Icon(Icons.swap_horiz),
            )
          : null,
    );
  }
}
