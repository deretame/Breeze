import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/page/bookshelf/bookshelf.dart' hide SearchEnter;
import 'package:zephyr/page/search_result/models/models.dart' show SearchEnter;

import '../../../main.dart';
import '../../../util/router/router.gr.dart';
import '../../jm/jm_search_result/bloc/jm_search_result_bloc.dart';

final bookshelfStore = BookshelfStore.init();

@RoutePage()
class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    bookshelfStore.tabController = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (bookshelfStore.tabController!.index != _currentIndex) {
          _currentIndex = bookshelfStore.tabController!.index;
          bookshelfStore.indexStore.setDate(_currentIndex);
          // logger.d('Current index: $_currentIndex');
          if (_currentIndex == 0) {
            if (bookshelfStore.topBarStore.date == 1) {
              eventBus.fire(
                FavoriteEvent(EventType.showInfo, SortType.nullValue, 0),
              );
            } else {
              eventBus.fire(JmFavoriteEvent(EventType.showInfo));
            }
          } else if (_currentIndex == 1) {
            eventBus.fire(HistoryEvent(EventType.showInfo));
          } else if (_currentIndex == 2) {
            eventBus.fire(DownloadEvent(EventType.showInfo));
          }
        }
      });
    bookshelfStore.stringSelectStore.setDate("");
    bookshelfStore.topBarStore.setDate(globalSetting.comicChoice);
  }

  @override
  void dispose() {
    bookshelfStore.tabController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: SideDrawer(),
      appBar: _appBar(),
      body: _body(),
      floatingActionButton: _floatingActionButton(),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    title: Observer(
      builder:
          (context) => Text(globalSetting.comicChoice == 1 ? "哔咔漫画" : "禁漫天堂"),
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
              controller: bookshelfStore.tabController,
              tabs: const [Tab(text: "收藏"), Tab(text: "历史"), Tab(text: "下载")],
            ),
          ),
          Observer(
            builder:
                (context) => SizedBox(
                  width: 120,
                  child: Center(
                    child: Text(bookshelfStore.stringSelectStore.date),
                  ),
                ),
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
          controller: bookshelfStore.tabController,
          children: [const FavoritesTabPage(), HistoryPage(), DownloadPage()],
        ),
      ),
    ],
  );

  Widget _floatingActionButton() => FloatingActionButton(
    child: const Icon(Icons.compare_arrows),
    onPressed: () {
      if (globalSetting.comicChoice == 1) {
        globalSetting.setComicChoice(2);
      } else {
        globalSetting.setComicChoice(1);
      }

      bookshelfStore.topBarStore.setDate(globalSetting.comicChoice);
      bookshelfStore.favoriteStore = SearchStatusStore();
      bookshelfStore.historyStore = SearchStatusStore();
      bookshelfStore.downloadStore = SearchStatusStore();
      bookshelfStore.jmFavoriteStore = SearchStatusStore();
      eventBus.fire(FavoriteEvent(EventType.refresh, SortType.dd, 0));
      eventBus.fire(HistoryEvent(EventType.refresh));
      eventBus.fire(DownloadEvent(EventType.refresh));
      eventBus.fire(JmFavoriteEvent(EventType.refresh));
      bookshelfStore.tabController!.animateTo(
        0,
        duration: const Duration(milliseconds: 0),
      );
      if (bookshelfStore.topBarStore.date == 2) {
        eventBus.fire(JmFavoriteEvent(EventType.showInfo));
      }
    },
  );
}

class FavoritesTabPage extends StatelessWidget {
  const FavoritesTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Observer 监听全局设置的变化
    return Observer(
      builder: (_) {
        // 根据 comicChoice 决定显示哪个页面的内容
        if (globalSetting.comicChoice == 1) {
          return FavoritePage();
        } else {
          return JmFavoritePage();
        }
      },
    );
  }
}
