import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/bookshelf/models/events.dart';
import 'package:zephyr/page/home/category.dart';
import 'package:zephyr/page/jm/jm_promote/view/jm_promote.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/type/enum.dart';

import '../../../config/global/global.dart';
import '../../../util/router/router.gr.dart';

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
    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(globalSettingState.comicChoice == 1 ? "哔咔漫画" : "禁漫首页"),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => search()),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'downloads') {
                context.pushRoute(DownloadTaskRoute());
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'downloads',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text("下载任务"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: RefreshIndicator(
        onRefresh: () async => eventBus.fire(RefreshCategories()),
        child: _buildBody(),
      ),
      floatingActionButton: globalSettingState.disableBika
          ? null
          : FloatingActionButton(
              heroTag: const ValueKey('switch_comic'),
              onPressed: _switchComic,
              child: const Icon(Icons.compare_arrows),
            ),
    );
  }

  Widget _buildBody() {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    // 使用 Key 确保完全重建
    if (globalSettingState.comicChoice == 1) {
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
    final globalSettingCubit = context.read<GlobalSettingCubit>();

    if (globalSettingCubit.state.comicChoice == 1) {
      globalSettingCubit.updateComicChoice(2);
    } else {
      globalSettingCubit.updateComicChoice(1);
    }

    eventBus.fire(BookShelfEvent());
  }

  void search() {
    final globalSettingState = context.read<GlobalSettingCubit>().state;

    if (globalSettingState.disableBika) {
      context.pushRoute(
        SearchRoute(
          searchState: SearchStates.initial(context).copyWith(from: From.jm),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: [
            SimpleDialogOption(
              onPressed: () {
                context.pop();
                context.pushRoute(
                  SearchRoute(
                    searchState: SearchStates.initial(
                      context,
                    ).copyWith(from: From.bika),
                  ),
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
                  SearchRoute(
                    searchState: SearchStates.initial(
                      context,
                    ).copyWith(from: From.jm),
                  ),
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
