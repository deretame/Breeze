import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/int_select.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart' hide SearchEnter;
import 'package:zephyr/page/search_result/models/models.dart' show SearchEnter;
import 'package:zephyr/util/settings_hive_utils.dart';

import '../../../main.dart';
import '../../../util/router/router.gr.dart';
import '../../jm/jm_search_result/bloc/jm_search_result_bloc.dart';

@RoutePage()
class BookshelfPage extends StatelessWidget {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<IntSelectCubit>(create: (context) => IntSelectCubit()),
        BlocProvider<StringSelectCubit>(
          create: (context) => StringSelectCubit(),
        ),

        BlocProvider<FavoriteCubit>(create: (context) => FavoriteCubit()),
        BlocProvider<HistoryCubit>(create: (context) => HistoryCubit()),
        BlocProvider<DownloadCubit>(create: (context) => DownloadCubit()),
        BlocProvider<JmFavoriteCubit>(create: (context) => JmFavoriteCubit()),
      ],
      child: const _BookshelfPageContent(),
    );
  }
}

class _BookshelfPageContent extends StatefulWidget {
  const _BookshelfPageContent();

  @override
  State<_BookshelfPageContent> createState() => _BookshelfPageContentState();
}

class _BookshelfPageContentState extends State<_BookshelfPageContent>
    with TickerProviderStateMixin {
  late final TabController _tabController; // TabController 现在是本地变量
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (_tabController.index != _currentIndex) {
          _currentIndex = _tabController.index;

          final indexCubit = context.read<IntSelectCubit>();
          final comicChoice = context
              .read<GlobalSettingCubit>()
              .state
              .comicChoice; // 直接读取状态

          indexCubit.setDate(_currentIndex);

          if (_currentIndex == 0) {
            if (comicChoice == 1) {
              eventBus.fire(
                FavoriteEvent(EventType.showInfo, SortType.nullValue, 0),
              );
            } else {
              eventBus.fire(JmFavoriteEvent(EventType.showInfo));
            }
          } else if (_currentIndex == 1) {
            eventBus.fire(HistoryEvent(EventType.showInfo, false));
          } else if (_currentIndex == 2) {
            eventBus.fire(DownloadEvent(EventType.showInfo, false));
          }
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: SideDrawer(),
      appBar: _appBar(),
      body: _body(),
      floatingActionButton: SettingsHiveUtils.disableBika
          ? null
          : _floatingActionButton(),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    title: Text(
      context.watch<GlobalSettingCubit>().state.comicChoice == 1
          ? "哔咔漫画"
          : "禁漫天堂",
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              final router = AutoRouter.of(context);
              return SimpleDialog(
                children: [
                  if (!SettingsHiveUtils.disableBika)
                    SimpleDialogOption(
                      onPressed: () {
                        router.popAndPush(
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
                      router.popAndPush(
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
        },
      ),
    ],

    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(kMinInteractiveDimension),
      child: Row(
        children: [
          Expanded(
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "收藏"),
                Tab(text: "历史"),
                Tab(text: "下载"),
              ],
            ),
          ),
          BlocBuilder<StringSelectCubit, String>(
            builder: (context, selectedString) {
              // selectedString 就是 Cubit 的 state (即之前的 .date)
              return SizedBox(
                width: 120,
                child: Center(child: Text(selectedString)),
              );
            },
          ),
          Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.sort),
                onPressed: () => Scaffold.of(context).openEndDrawer(), // 打开右侧抽屉
              );
            },
          ),
        ],
      ),
    ),
  );

  Widget _body() => Column(
    children: [
      Expanded(
        child: TabBarView(
          controller: _tabController,
          children: [const FavoritesTabPage(), HistoryPage(), DownloadPage()],
        ),
      ),
    ],
  );

  Widget _floatingActionButton() => FloatingActionButton(
    child: const Icon(Icons.compare_arrows),
    onPressed: () {
      final globalSettingCubit = context.read<GlobalSettingCubit>();

      final int newChoice = globalSettingCubit.state.comicChoice == 1 ? 2 : 1;

      globalSettingCubit.updateComicChoice(newChoice);

      context.read<GlobalSettingCubit>().updateComicChoice(newChoice);

      context.read<FavoriteCubit>().resetSearch();
      context.read<HistoryCubit>().resetSearch();
      context.read<DownloadCubit>().resetSearch();
      context.read<JmFavoriteCubit>().resetSearch();

      eventBus.fire(FavoriteEvent(EventType.refresh, SortType.dd, 0));
      eventBus.fire(JmFavoriteEvent(EventType.refresh));
      eventBus.fire(HistoryEvent(EventType.refresh, true));
      eventBus.fire(DownloadEvent(EventType.refresh, true));

      _tabController.animateTo(0, duration: const Duration(milliseconds: 0));

      if (context.read<GlobalSettingCubit>().state.comicChoice == 2) {
        eventBus.fire(JmFavoriteEvent(EventType.showInfo));
      }
    },
  );
}

class FavoritesTabPage extends StatefulWidget {
  const FavoritesTabPage({super.key});

  @override
  State<FavoritesTabPage> createState() => _FavoritesTabPageState();
}

class _FavoritesTabPageState extends State<FavoritesTabPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final comicChoice = context.select(
      (GlobalSettingCubit cubit) => cubit.state.comicChoice,
    );

    final int pageIndex = (comicChoice == 1) ? 0 : 1;

    return IndexedStack(
      index: pageIndex,
      children: <Widget>[FavoritePage(), JmFavoritePage()],
    );
  }
}
