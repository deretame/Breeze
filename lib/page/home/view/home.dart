import 'package:auto_route/auto_route.dart';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/home/category.dart';
import 'package:zephyr/page/jm/jm_promote/view/jm_promote.dart';

import '../../../config/global/global.dart';
import '../../../util/router/router.gr.dart';
import '../../jm/jm_search_result/bloc/jm_search_result_bloc.dart';
import '../../search_result/models/search_enter.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: Text(globalSetting.comicChoice == 1 ? "哔咔漫画" : "禁漫首页"),
            actions: [
              IconButton(icon: const Icon(Icons.search), onPressed: search),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async => eventBus.fire(RefreshCategories()),
            child: _buildBody(),
          ),
          floatingActionButton:
              globalSetting.disableBika
                  ? null
                  : FloatingActionButton(
                    heroTag: const ValueKey('switch_comic'),
                    onPressed: _switchComic,
                    child: const Icon(Icons.compare_arrows),
                  ),
        );
      },
    );
  }

  Widget _buildBody() {
    // 使用 Key 确保完全重建
    if (globalSetting.comicChoice == 1) {
      return ListView(
        key: const ValueKey('bika_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        controller: scrollControllers['category']!,
        children: const [KeywordPage(), CategoryWidget()],
      );
    } else {
      return const JmPromotePage(key: ValueKey('jm_promote'));
    }
  }

  void _switchComic() {
    if (globalSetting.comicChoice == 1) {
      globalSetting.setComicChoice(2);
    } else {
      globalSetting.setComicChoice(1);
    }
  }

  void search() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: [
            if (!globalSetting.disableBika)
              SimpleDialogOption(
                onPressed: () {
                  context.pop();
                  context.pushRoute(
                    SearchResultRoute(searchEnter: SearchEnter.initial()),
                  );
                },
                child: const Chip(
                  label: Text("哔咔漫画"),
                  backgroundColor: Colors.pink,
                  labelStyle: TextStyle(color: Colors.white),
                ),
              ),
            SimpleDialogOption(
              onPressed: () {
                context.pop();
                context.pushRoute(
                  JmSearchResultRoute(event: JmSearchResultEvent()),
                );
              },
              child: const Chip(
                label: Text("禁漫天堂"),
                backgroundColor: Colors.orange,
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
