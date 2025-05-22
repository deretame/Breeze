import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:zephyr/config/global/global.dart';
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
    bookshelfStore.topBarStore.setDate(1);
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
      appBar: AppBar(
        title: const Text('书架'),
        flexibleSpace: Column(
          children: [
            SizedBox(height: statusBarHeight),
            const Spacer(),
            Row(children: [const Spacer(), TopTabBar(), const Spacer()]),
            const Spacer(),
            const SizedBox(height: 48),
          ],
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
                            SearchResultRoute(
                              searchEnter: SearchEnter.initial(),
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
                        child: Text(bookshelfStore.stringSelectStore.date),
                      ),
                    ),
              ),
              Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: const Icon(Icons.sort),
                    onPressed:
                        () => Scaffold.of(context).openEndDrawer(), // 打开右侧抽屉
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: Observer(
        builder:
            (context) => Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: bookshelfStore.tabController,
                    children: [
                      bookshelfStore.topBarStore.date == 1
                          ? FavoritePage()
                          : JmFavoritePage(),
                      HistoryPage(),
                      DownloadPage(),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
