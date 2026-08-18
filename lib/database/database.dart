import 'dart:async';

import 'package:zephyr/database/objectbox_database.dart';
import 'package:zephyr/object_box/model.dart';

typedef DatabaseFilter<T> = bool Function(T value);

enum DatabaseTransactionMode { read, write }

AppDatabase? _database;
AppDatabase get database => _database!;
set database(AppDatabase value) => _database = value;

/// 数据库查询的通用结果对象。
///
/// 该类型只描述应用需要的查询能力，不暴露具体数据库的查询构造器。
abstract interface class DatabaseQuery<T> {
  List<T> find();

  T? findFirst();

  int count();

  Stream<List<T>> watch({bool triggerImmediately = false});

  DatabaseQuery<T> order(Comparator<T> comparator, {bool descending = false});

  set offset(int value);

  set limit(int value);

  /// 兼容数据库查询常见的 build 语义；中间层查询本身已经是可执行对象。
  DatabaseQuery<T> build();

  /// 释放查询资源。纯 Dart 实现可以是空操作。
  void close();
}

/// 通用实体仓储。
///
/// [T] 是应用层实体类，可以直接在业务层使用；实现类不得将底层数据库
/// 的 Box、Query 或其他专用类型泄漏到这个接口之外。
abstract interface class EntityStore<T> {
  T? get(int id);

  List<T> getAll();

  int put(T entity);

  List<int> putMany(Iterable<T> entities);

  bool remove(int id);

  int removeMany(Iterable<int> ids);

  int removeAll();

  DatabaseQuery<T> query(DatabaseFilter<T> filter);
}

/// 应用使用的本地数据库入口。
///
/// 业务层只依赖这个接口和实体类。具体使用 ObjectBox、SQLite 或其他数据库
/// 由 [createDatabase] 的实现决定。
abstract interface class AppDatabase {
  String get storagePath;

  EntityStore<BikaComicHistory> get bikaHistories;

  EntityStore<BikaComicDownload> get bikaDownloads;

  EntityStore<JmFavorite> get jmFavorites;

  EntityStore<JmHistory> get jmHistories;

  EntityStore<JmDownload> get jmDownloads;

  EntityStore<UnifiedComicFavorite> get unifiedFavorites;

  EntityStore<UnifiedComicHistory> get unifiedHistories;

  EntityStore<UnifiedComicDownload> get unifiedDownloads;

  EntityStore<FavoriteFolder> get favoriteFolders;

  EntityStore<FavoriteFolderItem> get favoriteFolderItems;

  EntityStore<DownloadFolder> get downloadFolders;

  EntityStore<DownloadFolderItem> get downloadFolderItems;

  EntityStore<UserSetting> get userSettings;

  EntityStore<DownloadTask> get downloadTasks;

  EntityStore<PluginConfig> get pluginConfigs;

  EntityStore<PluginInfo> get pluginInfos;

  EntityStore<ComicFolder> get comicFolders;

  EntityStore<ComicLink> get comicLinks;

  EntityStore<ComicFollow> get comicFollows;

  T runInTransaction<T>(DatabaseTransactionMode mode, T Function() action);

  void close();
}

extension DatabaseFilterExtension<T> on DatabaseFilter<T> {
  DatabaseFilter<T> and(DatabaseFilter<T> other) {
    return (value) => this(value) && other(value);
  }

  DatabaseFilter<T> or(DatabaseFilter<T> other) {
    return (value) => this(value) || other(value);
  }
}

/// 创建应用数据库。
///
/// 当前实现位于 ObjectBox 适配层；调用方不需要依赖适配类。
Future<AppDatabase> createDatabase({String? dbRootPath}) async {
  return createObjectBoxDatabase(dbRootPath: dbRootPath);
}

/// 仅供测试在关闭数据库后重新创建另一份临时数据库。
void resetDatabaseForTests() => resetObjectBoxDatabaseForTests();
