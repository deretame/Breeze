import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/bookshelf/models/events.dart';
import 'package:zephyr/page/jm/jm_ranking/view/jm_ranking.dart';
import 'package:zephyr/page/jm/jm_ranking/widget/comic_filter_dialog.dart';
import 'package:zephyr/page/ranking_list/cubit/comic_filter_cubit.dart';
import 'package:zephyr/page/ranking_list/ranking_list.dart';

@RoutePage()
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
    return const HotTabBar();
  }
}

class HotTabBar extends StatefulWidget {
  const HotTabBar({super.key});

  @override
  State<HotTabBar> createState() => _HotTabBarState();
}

class _HotTabBarState extends State<HotTabBar> {
  List<String> _currentFilter = ['0', 'new'];

  @override
  Widget build(BuildContext context) {
    final globlalSettingCubit = context.read<GlobalSettingCubit>();
    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(globalSettingState.comicChoice == 1 ? "哔咔排行榜" : "禁漫排行榜"),
        actions: [
          if (globalSettingState.comicChoice == 2)
            IconButton(
              icon: const Icon(Icons.filter_alt),
              onPressed: () async {
                final List<String>? result = await showDialog<List<String>>(
                  context: context,
                  builder: (context) {
                    return BlocProvider(
                      create: (context) => ComicFilterCubit(_currentFilter),
                      child: const ComicFilterDialog(),
                    );
                  },
                );

                if (result != null) {
                  setState(() => _currentFilter = result);
                }
              },
            ),
        ],
      ),
      body: globalSettingState.comicChoice == 1
          ? const BikaRankList()
          : JmRankingPage(
              categoryId: _currentFilter[0],
              sortId: _currentFilter[1],
            ),
      floatingActionButton: globalSettingState.disableBika
          ? null
          : FloatingActionButton(
              heroTag: Uuid().v4(),
              child: const Icon(Icons.compare_arrows),
              onPressed: () {
                if (globalSettingState.comicChoice == 1) {
                  globlalSettingCubit.updateComicChoice(2);
                } else {
                  globlalSettingCubit.updateComicChoice(1);
                }

                eventBus.fire(BookShelfEvent());
              },
            ),
    );
  }
}
