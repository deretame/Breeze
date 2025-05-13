import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'model.dart';
import 'objectbox.g.dart';

class ObjectBox {
  late final Store store;

  late final Box<BikaComicHistory> _bikaComicHistoryBox;
  late final Box<BikaComicDownload> _bikaComicDownloadBox;

  late final Box<JmFavorite> _jmFavoriteBox;
  late final Box<JmHistory> _jmHistoryBox;

  ObjectBox._create(this.store) {
    _bikaComicHistoryBox = store.box<BikaComicHistory>();
    _bikaComicDownloadBox = store.box<BikaComicDownload>();

    _jmFavoriteBox = store.box<JmFavorite>();
    _jmHistoryBox = store.box<JmHistory>();
  }

  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store = await openStore(directory: p.join(docsDir.path, "breeze_db"));
    return ObjectBox._create(store);
  }

  Box<BikaComicHistory> get bikaHistoryBox => _bikaComicHistoryBox;

  Box<BikaComicDownload> get bikaDownloadBox => _bikaComicDownloadBox;

  Box<JmFavorite> get jmFavoriteBox => _jmFavoriteBox;

  Box<JmHistory> get jmHistoryBox => _jmHistoryBox;
}
