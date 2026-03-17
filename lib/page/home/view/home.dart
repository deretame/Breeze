import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/bookshelf/models/events.dart';
import 'package:zephyr/page/home/category.dart';
import 'package:zephyr/page/search/cubit/search_cubit.dart';
import 'package:zephyr/type/enum.dart';

import '../../../config/global/global.dart';
import '../../../util/router/router.gr.dart';
import 'home_scheme_renderer.dart';

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final HomeSchemeRenderer _renderer = HomeSchemeRenderer();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final globalSettingState = context.watch<GlobalSettingCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(_renderer.titleForChoice(globalSettingState.comicChoice)),
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
      floatingActionButton: (globalSettingState.disableBika ||
              !_renderer.showSwitchFab(globalSettingState.comicChoice))
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

    return _renderer.buildBody(
      comicChoice: globalSettingState.comicChoice,
      bikaScrollController: scrollControllers['category'],
      bikaKeyword: const KeywordPage(),
      bikaCategory: const CategoryWidget(),
    );
  }

  void _switchComic() {
    final globalSettingCubit = context.read<GlobalSettingCubit>();

    if (globalSettingCubit.state.comicChoice == 1) {
      globalSettingCubit.updateState(
        (current) => current.copyWith(comicChoice: 2),
      );
    } else {
      globalSettingCubit.updateState(
        (current) => current.copyWith(comicChoice: 1),
      );
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
