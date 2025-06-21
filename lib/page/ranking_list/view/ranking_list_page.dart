import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/jm/jm_ranking/view/jm_ranking.dart';
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
  String title = '哔咔排行榜';

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder:
          (_) => Scaffold(
            appBar: AppBar(title: Text(title)),
            body:
                globalSetting.comicChoice == 1
                    ? const BikaRankList()
                    : const JmRankingPage(),
            floatingActionButton: FloatingActionButton(
              child: const Icon(Icons.compare_arrows),
              onPressed: () {
                if (globalSetting.comicChoice == 1) {
                  globalSetting.setComicChoice(2);
                } else {
                  globalSetting.setComicChoice(1);
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      title =
                          globalSetting.comicChoice == 1 ? "哔咔排行榜" : "禁漫排行榜";
                    });
                  }
                });
              },
            ),
          ),
    );
  }
}
