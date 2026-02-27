import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/util/get_path.dart';

import 'model.dart';
import 'objectbox.g.dart';

class ObjectBox {
  late final Store store;

  late final Box<BikaComicHistory> _bikaComicHistoryBox;
  late final Box<BikaComicDownload> _bikaComicDownloadBox;

  late final Box<JmFavorite> _jmFavoriteBox;
  late final Box<JmHistory> _jmHistoryBox;
  late final Box<JmDownload> _jmDownloadBox;

  late final Box<UserSetting> _userSettingBox;

  late final Box<DownloadTask> _downloadTaskBox;

  ObjectBox._create(this.store) {
    _bikaComicHistoryBox = store.box<BikaComicHistory>();
    _bikaComicDownloadBox = store.box<BikaComicDownload>();

    _jmFavoriteBox = store.box<JmFavorite>();
    _jmHistoryBox = store.box<JmHistory>();
    _jmDownloadBox = store.box<JmDownload>();

    _userSettingBox = store.box<UserSetting>();

    _downloadTaskBox = store.box<DownloadTask>();
  }

  static Future<ObjectBox> create() async {
    final dbPath = p.join(await getDbPath(), "breeze_db");

    Store storeInstance;

    if (Store.isOpen(dbPath)) {
      storeInstance = Store.attach(getObjectBoxModel(), dbPath);
    } else {
      storeInstance = await openStore(directory: dbPath);
    }

    return ObjectBox._create(storeInstance);
  }

  Box<BikaComicHistory> get bikaHistoryBox => _bikaComicHistoryBox;

  Box<BikaComicDownload> get bikaDownloadBox => _bikaComicDownloadBox;

  Box<JmFavorite> get jmFavoriteBox => _jmFavoriteBox;

  Box<JmHistory> get jmHistoryBox => _jmHistoryBox;

  Box<JmDownload> get jmDownloadBox => _jmDownloadBox;

  Box<UserSetting> get userSettingBox => _userSettingBox;

  Box<DownloadTask> get downloadTaskBox => _downloadTaskBox;
}
