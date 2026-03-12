import 'package:path/path.dart' as p;
import 'package:zephyr/util/get_path.dart';

import 'model.dart';
import 'objectbox.g.dart';

class ObjectBox {
  late final Store store;

  static Future<ObjectBox>? _initFuture; // 用于内存锁定的 Future

  late final Box<BikaComicHistory> _bikaComicHistoryBox;
  late final Box<BikaComicDownload> _bikaComicDownloadBox;

  late final Box<JmFavorite> _jmFavoriteBox;
  late final Box<JmHistory> _jmHistoryBox;
  late final Box<JmDownload> _jmDownloadBox;

  late final Box<UserSetting> _userSettingBox;

  late final Box<DownloadTask> _downloadTaskBox;

  late final Box<FlushPersistentStore> _flushPersistentStoreBox;

  ObjectBox._create(this.store) {
    _bikaComicHistoryBox = store.box<BikaComicHistory>();
    _bikaComicDownloadBox = store.box<BikaComicDownload>();

    _jmFavoriteBox = store.box<JmFavorite>();
    _jmHistoryBox = store.box<JmHistory>();
    _jmDownloadBox = store.box<JmDownload>();

    _userSettingBox = store.box<UserSetting>();

    _downloadTaskBox = store.box<DownloadTask>();

    _flushPersistentStoreBox = store.box<FlushPersistentStore>();
  }

  static Future<ObjectBox> create() async {
    // A. 同 Isolate 保护：如果已经有初始化任务在跑，直接返回同一个 Future
    if (_initFuture != null) return _initFuture!;

    _initFuture = _doInit();
    return _initFuture!;
  }

  static Future<ObjectBox> _doInit() async {
    final dbPath = p.join(await getDbPath(), "breeze_db");

    // 尝试次数限制，防止死循环
    int retryCount = 0;
    while (retryCount < 3) {
      try {
        // 1. 尝试直接 Attach (这是最快且最轻量的)
        final store = Store.attach(getObjectBoxModel(), dbPath);
        return ObjectBox._create(store);
      } catch (e) {
        // 2. 如果 Attach 失败，尝试 Open
        try {
          final store = await openStore(directory: dbPath);
          return ObjectBox._create(store);
        } catch (innerError) {
          // 3. 并发核心处理：如果是由于锁冲突导致的 10199 错误
          if (innerError.toString().contains('10199') ||
              innerError.toString().contains('Input/output error')) {
            retryCount++;
            // 稍微等一下（给另一个线程一点时间完成 Open）
            await Future.delayed(Duration(milliseconds: 200 * retryCount));
            // 进入下一轮 while 循环再次尝试 attach
            continue;
          }
          // 其他严重错误（如路径不可写、磁盘已满）直接抛出
          rethrow;
        }
      }
    }
    throw Exception("ObjectBox 初始化失败：在多次尝试后仍无法获取数据库锁。");
  }

  Box<BikaComicHistory> get bikaHistoryBox => _bikaComicHistoryBox;

  Box<BikaComicDownload> get bikaDownloadBox => _bikaComicDownloadBox;

  Box<JmFavorite> get jmFavoriteBox => _jmFavoriteBox;

  Box<JmHistory> get jmHistoryBox => _jmHistoryBox;

  Box<JmDownload> get jmDownloadBox => _jmDownloadBox;

  Box<UserSetting> get userSettingBox => _userSettingBox;

  Box<DownloadTask> get downloadTaskBox => _downloadTaskBox;

  Box<FlushPersistentStore> get flushPersistentBox => _flushPersistentStoreBox;
}
