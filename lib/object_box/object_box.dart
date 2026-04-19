import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
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
  late final Box<UnifiedComicFavorite> _unifiedComicFavoriteBox;
  late final Box<UnifiedComicHistory> _unifiedComicHistoryBox;
  late final Box<UnifiedComicDownload> _unifiedComicDownloadBox;

  late final Box<UserSetting> _userSettingBox;

  late final Box<DownloadTask> _downloadTaskBox;

  late final Box<PluginConfig> _pluginConfigBox;
  late final Box<PluginInfo> _pluginInfoBox;

  ObjectBox._create(this.store) {
    _bikaComicHistoryBox = store.box<BikaComicHistory>();
    _bikaComicDownloadBox = store.box<BikaComicDownload>();

    _jmFavoriteBox = store.box<JmFavorite>();
    _jmHistoryBox = store.box<JmHistory>();
    _jmDownloadBox = store.box<JmDownload>();
    _unifiedComicFavoriteBox = store.box<UnifiedComicFavorite>();
    _unifiedComicHistoryBox = store.box<UnifiedComicHistory>();
    _unifiedComicDownloadBox = store.box<UnifiedComicDownload>();

    _userSettingBox = store.box<UserSetting>();

    _downloadTaskBox = store.box<DownloadTask>();

    _pluginConfigBox = store.box<PluginConfig>();
    _pluginInfoBox = store.box<PluginInfo>();
  }

  static Future<ObjectBox> create({String? dbRootPath}) async {
    // A. 同 Isolate 保护：如果已经有初始化任务在跑，直接返回同一个 Future
    if (_initFuture != null) return _initFuture!;

    _initFuture = _doInit(dbRootPath: dbRootPath);
    return _initFuture!;
  }

  static Future<ObjectBox> _doInit({String? dbRootPath}) async {
    final dbPath = p.join(dbRootPath ?? await getDbPath(), "breeze_db");

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

  Box<UnifiedComicFavorite> get unifiedFavoriteBox => _unifiedComicFavoriteBox;

  Box<UnifiedComicHistory> get unifiedHistoryBox => _unifiedComicHistoryBox;

  Box<UnifiedComicDownload> get unifiedDownloadBox => _unifiedComicDownloadBox;

  Box<UserSetting> get userSettingBox => _userSettingBox;

  Box<DownloadTask> get downloadTaskBox => _downloadTaskBox;

  Box<PluginConfig> get pluginConfigBox => _pluginConfigBox;

  Box<PluginInfo> get pluginInfoBox => _pluginInfoBox;

  void dumpAllData() {
    logger.d("========= ObjectBox Data Dump Start =========");

    _dumpBoxData<BikaComicHistory>(_bikaComicHistoryBox, "BikaComicHistory");
    _dumpBoxData<BikaComicDownload>(_bikaComicDownloadBox, "BikaComicDownload");

    _dumpBoxData<JmFavorite>(_jmFavoriteBox, "JmFavorite");
    _dumpBoxData<JmHistory>(_jmHistoryBox, "JmHistory");
    _dumpBoxData<JmDownload>(_jmDownloadBox, "JmDownload");

    _dumpBoxData<UnifiedComicFavorite>(
      _unifiedComicFavoriteBox,
      "UnifiedComicFavorite",
    );
    _dumpBoxData<UnifiedComicHistory>(
      _unifiedComicHistoryBox,
      "UnifiedComicHistory",
    );
    _dumpBoxData<UnifiedComicDownload>(
      _unifiedComicDownloadBox,
      "UnifiedComicDownload",
    );

    _dumpBoxData<UserSetting>(_userSettingBox, "UserSetting");
    _dumpBoxData<DownloadTask>(_downloadTaskBox, "DownloadTask");
    _dumpBoxData<PluginConfig>(_pluginConfigBox, "PluginConfig");
    _dumpBoxData<PluginInfo>(_pluginInfoBox, "PluginInfo");

    logger.d("=========  ObjectBox Data Dump End  =========");
  }

  /// 私有辅助方法，用于统一格式化输出
  void _dumpBoxData<T>(Box<T> box, String entityName) {
    final data = box.getAll();
    logger.d("[$entityName] 共有 ${data.length} 条记录");
    // for (var item in data) {
    //   logger.d("  -> $item");
    // }
  }
}
