import 'package:objectbox/objectbox.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/object_box.dart';
import 'package:zephyr/object_box/objectbox.g.dart';

import 'package:zephyr/database/database.dart';

class ObjectBoxDatabase implements AppDatabase {
  ObjectBoxDatabase._(this._objectBox) {
    _bikaHistories = ObjectBoxEntityStore(_objectBox.bikaHistoryBox);
    _bikaDownloads = ObjectBoxEntityStore(_objectBox.bikaDownloadBox);
    _jmFavorites = ObjectBoxEntityStore(_objectBox.jmFavoriteBox);
    _jmHistories = ObjectBoxEntityStore(_objectBox.jmHistoryBox);
    _jmDownloads = ObjectBoxEntityStore(_objectBox.jmDownloadBox);
    _unifiedFavorites = ObjectBoxEntityStore(_objectBox.unifiedFavoriteBox);
    _unifiedHistories = ObjectBoxEntityStore(_objectBox.unifiedHistoryBox);
    _unifiedDownloads = ObjectBoxEntityStore(_objectBox.unifiedDownloadBox);
    _favoriteFolders = ObjectBoxEntityStore(_objectBox.favoriteFolderBox);
    _favoriteFolderItems = ObjectBoxEntityStore(
      _objectBox.favoriteFolderItemBox,
    );
    _downloadFolders = ObjectBoxEntityStore(_objectBox.downloadFolderBox);
    _downloadFolderItems = ObjectBoxEntityStore(
      _objectBox.downloadFolderItemBox,
    );
    _userSettings = ObjectBoxEntityStore(_objectBox.userSettingBox);
    _downloadTasks = ObjectBoxEntityStore(_objectBox.downloadTaskBox);
    _pluginConfigs = ObjectBoxEntityStore(_objectBox.pluginConfigBox);
    _pluginInfos = ObjectBoxEntityStore(_objectBox.pluginInfoBox);
    _comicFolders = ObjectBoxEntityStore(_objectBox.comicFolderBox);
    _comicLinks = ObjectBoxEntityStore(_objectBox.comicLinkBox);
    _comicFollows = ObjectBoxEntityStore(_objectBox.comicFollowBox);
  }

  static Future<ObjectBoxDatabase> create({String? dbRootPath}) async {
    return ObjectBoxDatabase._(await ObjectBox.create(dbRootPath: dbRootPath));
  }

  final ObjectBox _objectBox;

  late final EntityStore<BikaComicHistory> _bikaHistories;
  late final EntityStore<BikaComicDownload> _bikaDownloads;
  late final EntityStore<JmFavorite> _jmFavorites;
  late final EntityStore<JmHistory> _jmHistories;
  late final EntityStore<JmDownload> _jmDownloads;
  late final EntityStore<UnifiedComicFavorite> _unifiedFavorites;
  late final EntityStore<UnifiedComicHistory> _unifiedHistories;
  late final EntityStore<UnifiedComicDownload> _unifiedDownloads;
  late final EntityStore<FavoriteFolder> _favoriteFolders;
  late final EntityStore<FavoriteFolderItem> _favoriteFolderItems;
  late final EntityStore<DownloadFolder> _downloadFolders;
  late final EntityStore<DownloadFolderItem> _downloadFolderItems;
  late final EntityStore<UserSetting> _userSettings;
  late final EntityStore<DownloadTask> _downloadTasks;
  late final EntityStore<PluginConfig> _pluginConfigs;
  late final EntityStore<PluginInfo> _pluginInfos;
  late final EntityStore<ComicFolder> _comicFolders;
  late final EntityStore<ComicLink> _comicLinks;
  late final EntityStore<ComicFollow> _comicFollows;

  @override
  String get storagePath => _objectBox.store.directoryPath;

  @override
  EntityStore<BikaComicHistory> get bikaHistories => _bikaHistories;

  @override
  EntityStore<BikaComicDownload> get bikaDownloads => _bikaDownloads;

  @override
  EntityStore<JmFavorite> get jmFavorites => _jmFavorites;

  @override
  EntityStore<JmHistory> get jmHistories => _jmHistories;

  @override
  EntityStore<JmDownload> get jmDownloads => _jmDownloads;

  @override
  EntityStore<UnifiedComicFavorite> get unifiedFavorites => _unifiedFavorites;

  @override
  EntityStore<UnifiedComicHistory> get unifiedHistories => _unifiedHistories;

  @override
  EntityStore<UnifiedComicDownload> get unifiedDownloads => _unifiedDownloads;

  @override
  EntityStore<FavoriteFolder> get favoriteFolders => _favoriteFolders;

  @override
  EntityStore<FavoriteFolderItem> get favoriteFolderItems =>
      _favoriteFolderItems;

  @override
  EntityStore<DownloadFolder> get downloadFolders => _downloadFolders;

  @override
  EntityStore<DownloadFolderItem> get downloadFolderItems =>
      _downloadFolderItems;

  @override
  EntityStore<UserSetting> get userSettings => _userSettings;

  @override
  EntityStore<DownloadTask> get downloadTasks => _downloadTasks;

  @override
  EntityStore<PluginConfig> get pluginConfigs => _pluginConfigs;

  @override
  EntityStore<PluginInfo> get pluginInfos => _pluginInfos;

  @override
  EntityStore<ComicFolder> get comicFolders => _comicFolders;

  @override
  EntityStore<ComicLink> get comicLinks => _comicLinks;

  @override
  EntityStore<ComicFollow> get comicFollows => _comicFollows;

  @override
  T runInTransaction<T>(DatabaseTransactionMode mode, T Function() action) {
    return _objectBox.store.runInTransaction(
      mode == DatabaseTransactionMode.write ? TxMode.write : TxMode.read,
      action,
    );
  }

  @override
  void close() => _objectBox.close();
}

Future<AppDatabase> createObjectBoxDatabase({String? dbRootPath}) {
  return ObjectBoxDatabase.create(dbRootPath: dbRootPath);
}

void resetObjectBoxDatabaseForTests() => ObjectBox.resetForTests();

class ObjectBoxEntityStore<T> implements EntityStore<T> {
  ObjectBoxEntityStore(this._box);

  final Box<T> _box;

  @override
  T? get(int id) => _box.get(id);

  @override
  List<T> getAll() => _box.getAll();

  @override
  int put(T entity) => _box.put(entity);

  @override
  List<int> putMany(Iterable<T> entities) => _box.putMany(entities.toList());

  @override
  bool remove(int id) => _box.remove(id);

  @override
  int removeMany(Iterable<int> ids) => _box.removeMany(ids.toList());

  @override
  int removeAll() => _box.removeAll();

  @override
  DatabaseQuery<T> query(DatabaseFilter<T> filter) {
    return ObjectBoxDatabaseQuery(_box, filter);
  }
}

class ObjectBoxDatabaseQuery<T> implements DatabaseQuery<T> {
  ObjectBoxDatabaseQuery(this._box, this._filter);

  final Box<T> _box;
  final DatabaseFilter<T> _filter;
  Comparator<T>? _comparator;
  bool _descending = false;
  int _offset = 0;
  int? _limit;

  @override
  List<T> find() {
    final values = _box.getAll().where(_filter).toList();
    final comparator = _comparator;
    if (comparator != null) {
      values.sort(_descending ? (a, b) => comparator(b, a) : comparator);
    }

    final start = _offset.clamp(0, values.length);
    final end = _limit == null
        ? values.length
        : (start + _limit!).clamp(start, values.length);
    return values.sublist(start, end);
  }

  @override
  T? findFirst() {
    final values = find();
    return values.isEmpty ? null : values.first;
  }

  @override
  int count() => _box.getAll().where(_filter).length;

  @override
  Stream<List<T>> watch({bool triggerImmediately = false}) {
    return _box
        .query()
        .watch(triggerImmediately: triggerImmediately)
        .map((_) => find());
  }

  @override
  DatabaseQuery<T> order(Comparator<T> comparator, {bool descending = false}) {
    _comparator = comparator;
    _descending = descending;
    return this;
  }

  @override
  set offset(int value) => _offset = value;

  @override
  set limit(int value) => _limit = value;

  @override
  DatabaseQuery<T> build() => this;

  @override
  void close() {}
}
