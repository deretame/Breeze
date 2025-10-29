import 'package:flutter/material.dart';
import 'package:zephyr/cubit/int_select.dart';
import 'package:zephyr/page/bookshelf/mobx/search_status.dart';
import 'package:zephyr/cubit/string_select.dart';

class BookshelfStore {
  IntSelectStore indexStore;
  IntSelectStore topBarStore;
  StringSelectStore stringSelectStore;
  SearchStatusStore favoriteStore;
  SearchStatusStore historyStore;
  SearchStatusStore downloadStore;
  SearchStatusStore jmFavoriteStore;
  TabController? tabController;

  BookshelfStore({
    required this.indexStore,
    required this.topBarStore,
    required this.stringSelectStore,
    required this.favoriteStore,
    required this.historyStore,
    required this.downloadStore,
    required this.jmFavoriteStore,
    this.tabController,
  });

  static BookshelfStore init() {
    return BookshelfStore(
      indexStore: IntSelectStore(),
      topBarStore: IntSelectStore(),
      stringSelectStore: StringSelectStore(),
      favoriteStore: SearchStatusStore(),
      historyStore: SearchStatusStore(),
      downloadStore: SearchStatusStore(),
      jmFavoriteStore: SearchStatusStore(),
    );
  }
}
