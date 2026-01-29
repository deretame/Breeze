import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/jm/jm_setting.dart';
import 'package:zephyr/cubit/int_select.dart';
import 'package:zephyr/cubit/list_select.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart' hide SearchEnter;
import 'package:zephyr/page/bookshelf/widgets/jm/jm_tab_bar.dart';
import 'package:zephyr/util/settings_hive_utils.dart';

import '../../../main.dart';
import '../json/jm_cloud_favorite/jm_cloud_favorite_json.dart' show FolderList;

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
        BlocProvider<ListSelectCubit<FolderList>>(
          create: (context) => ListSelectCubit<FolderList>(),
        ),
        BlocProvider<FavoriteCubit>(create: (context) => FavoriteCubit()),
        BlocProvider<HistoryCubit>(create: (context) => HistoryCubit()),
        BlocProvider<DownloadCubit>(create: (context) => DownloadCubit()),
        BlocProvider<JmFavoriteCubit>(create: (context) => JmFavoriteCubit()),
        BlocProvider<JmCloudFavoriteCubit>(
          create: (context) => JmCloudFavoriteCubit(),
        ),
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
  late final TabController _tabController;
  int _currentIndex = 0;
  late final StreamSubscription _eventSubscription;

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

    _eventSubscription = eventBus.on<BookShelfEvent>().listen((event) {
      refreshBookShelf(event.switchComicChoice);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _eventSubscription.cancel();
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
    toolbarHeight: 0,
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
    onPressed: () => eventBus.fire(BookShelfEvent(switchComicChoice: true)),
  );

  void refreshBookShelf(bool switchComicChoice) {
    final globalSettingCubit = context.read<GlobalSettingCubit>();
    final jmSettingCubit = context.read<JmSettingCubit>();

    if (switchComicChoice) {
      final int newChoice = globalSettingCubit.state.comicChoice == 1 ? 2 : 1;

      globalSettingCubit.updateComicChoice(newChoice);
    }
    jmSettingCubit.updateFavoriteSet(0);

    context.read<FavoriteCubit>().resetSearch();
    context.read<HistoryCubit>().resetSearch();
    context.read<DownloadCubit>().resetSearch();
    context.read<JmFavoriteCubit>().resetSearch();
    context.read<JmCloudFavoriteCubit>().resetSearch();

    eventBus.fire(FavoriteEvent(EventType.refresh, SortType.dd, 0));
    eventBus.fire(JmFavoriteEvent(EventType.refresh));
    eventBus.fire(HistoryEvent(EventType.refresh, true));
    eventBus.fire(DownloadEvent(EventType.refresh, true));
    eventBus.fire(JmCloudFavoriteEvent(EventType.refresh));

    _tabController.animateTo(0, duration: const Duration(milliseconds: 0));

    if (context.read<GlobalSettingCubit>().state.comicChoice == 2) {
      eventBus.fire(JmFavoriteEvent(EventType.showInfo));
    }
  }
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

    var pageIndex = (comicChoice == 1) ? 0 : 1;

    final globalState = context.read<GlobalSettingCubit>().state;

    var widgets = <Widget>[];

    if (!globalState.disableBika) {
      widgets.add(FavoritePage());
    } else {
      pageIndex = 0;
    }
    widgets.add(JmTabBar());

    return IndexedStack(index: pageIndex, children: widgets);
  }

  void refreshBookShelf() {}
}
