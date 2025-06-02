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
  late final Box<JmDownload> _jmDownloadBox;

  ObjectBox._create(this.store) {
    _bikaComicHistoryBox = store.box<BikaComicHistory>();
    _bikaComicDownloadBox = store.box<BikaComicDownload>();

    _jmFavoriteBox = store.box<JmFavorite>();
    _jmHistoryBox = store.box<JmHistory>();
    _jmDownloadBox = store.box<JmDownload>();
  }

  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    // 确保这个路径和你的项目一致，之前是 "breeze_db"
    final dbPath = p.join(docsDir.path, "breeze_db");

    Store storeInstance; // 用来接收 Store 实例

    if (Store.isOpen(dbPath)) {
      // 如果底层 Store 已经通过其他实例打开了 (比如主 Isolate，或者另一个后台 Isolate)
      // 我们就安全地 "attach" 到它上面
      storeInstance = Store.attach(getObjectBoxModel(), dbPath);
    } else {
      // 如果底层 Store 还没有打开，那我们就正常地打开它
      // 这通常发生在应用第一次启动，或者所有之前的实例都已关闭后
      storeInstance = await openStore(
        directory: dbPath,
      ); // openStore 是 objectbox.g.dart 中生成的
    }

    return ObjectBox._create(storeInstance);
  }

  Box<BikaComicHistory> get bikaHistoryBox => _bikaComicHistoryBox;

  Box<BikaComicDownload> get bikaDownloadBox => _bikaComicDownloadBox;

  Box<JmFavorite> get jmFavoriteBox => _jmFavoriteBox;

  Box<JmHistory> get jmHistoryBox => _jmHistoryBox;

  Box<JmDownload> get jmDownloadBox => _jmDownloadBox;
}
