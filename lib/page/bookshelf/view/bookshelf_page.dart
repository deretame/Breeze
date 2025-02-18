import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/mobx/string_select.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart';

import '../../../main.dart';
import '../../../mobx/int_select.dart';
import '../../../util/router/router.gr.dart';
import '../../search_result/models/search_enter.dart' as search_result;

@RoutePage()
class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  int _currentIndex = 0;

  final IntSelectStore indexStore = IntSelectStore();
  final StringSelectStore stringSelectStore = StringSelectStore();
  final SearchStatusStore favoriteStore = SearchStatusStore();
  final SearchStatusStore historyStore = SearchStatusStore();
  final SearchStatusStore downloadStore = SearchStatusStore();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)..addListener(() {
      if (_tabController.index != _currentIndex) {
        _currentIndex = _tabController.index;
        indexStore.setDate(_currentIndex);
        debugPrint('Current index: $_currentIndex');
        if (_currentIndex == 0) {
          eventBus.fire(
            FavoriteEvent(EventType.showInfo, SortType.nullValue, 0),
          );
        } else if (_currentIndex == 1) {
          eventBus.fire(HistoryEvent(EventType.showInfo));
        } else if (_currentIndex == 2) {
          eventBus.fire(DownloadEvent(EventType.showInfo));
        }
      }
    });
    stringSelectStore.setDate("");
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: SideDrawer(
        indexStore: indexStore,
        favoriteStore: favoriteStore,
        historyStore: historyStore,
        downloadStore: downloadStore,
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                title: const Text('书架'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed:
                        () => AutoRouter.of(context).push(
                          SearchResultRoute(
                            searchEnterConst: search_result.SearchEnterConst(),
                          ),
                        ),
                  ),
                ],
                pinned: true,
                floating: true,
                snap: true,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(
                    kMinInteractiveDimension,
                  ),
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
                      Observer(
                        builder:
                            (context) => SizedBox(
                              width: 120,
                              child: Center(
                                child: Text(stringSelectStore.date),
                              ),
                            ),
                      ),
                      Builder(
                        builder: (BuildContext context) {
                          return IconButton(
                            icon: const Icon(Icons.sort),
                            onPressed:
                                () =>
                                    Scaffold.of(
                                      context,
                                    ).openEndDrawer(), // 打开右侧抽屉
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            FavoritePage(
              searchStatusStore: favoriteStore,
              stringSelectStore: stringSelectStore,
              indexStore: indexStore,
            ),
            HistoryPage(
              searchStatusStore: historyStore,
              stringSelectStore: stringSelectStore,
              indexStore: indexStore,
            ),
            DownloadPage(
              searchStatusStore: downloadStore,
              stringSelectStore: stringSelectStore,
              indexStore: indexStore,
            ),
          ],
        ),
      ),
    );
  }
}
