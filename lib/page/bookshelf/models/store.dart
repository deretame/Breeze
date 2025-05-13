import 'package:zephyr/mobx/int_select.dart';
import 'package:zephyr/page/bookshelf/mobx/search_status.dart';
import 'package:zephyr/mobx/string_select.dart';

class BookshelfStore {
  final IntSelectStore indexStore;
  final IntSelectStore topBarStore;
  final StringSelectStore stringSelectStore;
  final SearchStatusStore favoriteStore;
  final SearchStatusStore historyStore;
  final SearchStatusStore downloadStore;

  BookshelfStore({
    required this.indexStore,
    required this.topBarStore,
    required this.stringSelectStore,
    required this.favoriteStore,
    required this.historyStore,
    required this.downloadStore,
  });

  static BookshelfStore init() {
    return BookshelfStore(
      indexStore: IntSelectStore(),
      topBarStore: IntSelectStore(),
      stringSelectStore: StringSelectStore(),
      favoriteStore: SearchStatusStore(),
      historyStore: SearchStatusStore(),
      downloadStore: SearchStatusStore(),
    );
  }
}
