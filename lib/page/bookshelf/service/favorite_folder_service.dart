import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/cs/application/cs_runtime_context.dart';
import 'package:zephyr/cs/data/cs_remote_database.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';

const String kFavoriteFolderAllKey = 'all';
const String _kFolderSourcePrefix = 'fav-folder:';

class FavoriteFolderView {
  const FavoriteFolderView({
    required this.key,
    required this.name,
    this.isAll = false,
  });

  final String key;
  final String name;
  final bool isAll;
}

class FavoriteFolderService {
  static bool get _useRemote =>
      CsRuntimeContext.I.isCsMode && CsRuntimeContext.I.database != null;

  static CsRemoteDatabase get _remote => CsRuntimeContext.I.database!;

  static String sourceToken(String folderKey) =>
      '$_kFolderSourcePrefix$folderKey';

  static String? parseFolderKeyFromSources(List<String> sources) {
    for (final source in sources) {
      final trimmed = source.trim();
      if (trimmed.startsWith(_kFolderSourcePrefix)) {
        return trimmed.substring(_kFolderSourcePrefix.length);
      }
    }
    return null;
  }

  static List<String> stripFolderSourceTokens(List<String> sources) {
    return sources
        .where((item) => !item.trim().startsWith(_kFolderSourcePrefix))
        .toList();
  }

  static List<FavoriteFolderView> listFolders() {
    if (_useRemote) {
      final folders = <FavoriteFolderView>[
        FavoriteFolderView(
          key: kFavoriteFolderAllKey,
          name: t.common.all,
          isAll: true,
        ),
      ];
      final remoteFolders = _remote.listFavoriteFolders()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      folders.addAll(
        remoteFolders.map(
          (folder) =>
              FavoriteFolderView(key: folder.folderKey, name: folder.name),
        ),
      );
      return folders;
    }
    final query = objectbox.favoriteFolderBox
        .query(FavoriteFolder_.deleted.equals(false))
        .order(FavoriteFolder_.createdAt)
        .build();
    try {
      final folders = <FavoriteFolderView>[
        FavoriteFolderView(
          key: kFavoriteFolderAllKey,
          name: t.common.all,
          isAll: true,
        ),
      ];
      for (final folder in query.find()) {
        folders.add(
          FavoriteFolderView(key: folder.folderKey, name: folder.name),
        );
      }
      return folders;
    } finally {
      query.close();
    }
  }

  static FavoriteFolderView createFolder(String name) {
    final safeName = name.trim();
    if (safeName.isEmpty) {
      throw ArgumentError(t.bookshelf.favoriteFolderNameEmpty);
    }
    if (_useRemote) {
      final existed = _remote.listFavoriteFolders().any(
        (folder) => folder.name == safeName,
      );
      if (existed) throw StateError(t.bookshelf.favoriteFolderNameExists);
      final now = DateTime.now().toUtc();
      final folderKey = 'f_${now.millisecondsSinceEpoch}';
      _remote.saveFavoriteFolder(
        FavoriteFolder(
          folderKey: folderKey,
          name: safeName,
          createdAt: now,
          updatedAt: now,
          deleted: false,
        ),
      );
      return FavoriteFolderView(key: folderKey, name: safeName);
    }
    final existed = objectbox.favoriteFolderBox
        .query(
          FavoriteFolder_.name
              .equals(safeName)
              .and(FavoriteFolder_.deleted.equals(false)),
        )
        .build()
        .findFirst();
    if (existed != null) {
      throw StateError(t.bookshelf.favoriteFolderNameExists);
    }

    final now = DateTime.now().toUtc();
    final folderKey = 'f_${now.millisecondsSinceEpoch}';
    objectbox.favoriteFolderBox.put(
      FavoriteFolder(
        folderKey: folderKey,
        name: safeName,
        createdAt: now,
        updatedAt: now,
        deleted: false,
      ),
    );
    return FavoriteFolderView(key: folderKey, name: safeName);
  }

  static void deleteFolder(String folderKey) {
    final safeKey = folderKey.trim();
    if (safeKey.isEmpty || safeKey == kFavoriteFolderAllKey) {
      return;
    }
    if (_useRemote) {
      final now = DateTime.now().toUtc();
      final folder = _remote.findFavoriteFolder(safeKey);
      if (folder != null && !folder.deleted) {
        folder
          ..deleted = true
          ..updatedAt = now;
        _remote.saveFavoriteFolder(folder);
      }
      for (final item in _remote.listFavoriteFolderItems().where(
        (item) => item.folderKey == safeKey,
      )) {
        item
          ..deleted = true
          ..updatedAt = now;
        _remote.saveFavoriteFolderItem(item);
      }
      return;
    }
    final now = DateTime.now().toUtc();
    final folder = objectbox.favoriteFolderBox
        .query(FavoriteFolder_.folderKey.equals(safeKey))
        .build()
        .findFirst();
    if (folder != null && folder.deleted == false) {
      folder.deleted = true;
      folder.updatedAt = now;
      objectbox.favoriteFolderBox.put(folder);
    }
    final itemQuery = objectbox.favoriteFolderItemBox
        .query(
          FavoriteFolderItem_.folderKey
              .equals(safeKey)
              .and(FavoriteFolderItem_.deleted.equals(false)),
        )
        .build();
    try {
      final items = itemQuery.find();
      for (final item in items) {
        item.deleted = true;
        item.updatedAt = now;
      }
      if (items.isNotEmpty) {
        objectbox.favoriteFolderItemBox.putMany(items);
      }
    } finally {
      itemQuery.close();
    }
  }

  static void renameFolder(String folderKey, String name) {
    final safeKey = folderKey.trim();
    final safeName = name.trim();
    if (safeKey.isEmpty ||
        safeKey == kFavoriteFolderAllKey ||
        safeName.isEmpty) {
      return;
    }
    if (_useRemote) {
      final duplicated = _remote.listFavoriteFolders().any(
        (folder) => folder.name == safeName && folder.folderKey != safeKey,
      );
      if (duplicated) throw StateError(t.bookshelf.favoriteFolderNameExists);
      final folder = _remote.findFavoriteFolder(safeKey);
      if (folder == null || folder.deleted) return;
      folder
        ..name = safeName
        ..updatedAt = DateTime.now().toUtc();
      _remote.saveFavoriteFolder(folder);
      return;
    }
    final duplicated = objectbox.favoriteFolderBox
        .query(
          FavoriteFolder_.name
              .equals(safeName)
              .and(FavoriteFolder_.deleted.equals(false)),
        )
        .build()
        .findFirst();
    if (duplicated != null && duplicated.folderKey != safeKey) {
      throw StateError(t.bookshelf.favoriteFolderNameExists);
    }
    final folder = objectbox.favoriteFolderBox
        .query(
          FavoriteFolder_.folderKey
              .equals(safeKey)
              .and(FavoriteFolder_.deleted.equals(false)),
        )
        .build()
        .findFirst();
    if (folder == null) {
      return;
    }
    folder.name = safeName;
    folder.updatedAt = DateTime.now().toUtc();
    objectbox.favoriteFolderBox.put(folder);
  }

  static Set<String> membersOf(String folderKey) {
    if (folderKey == kFavoriteFolderAllKey) {
      return const <String>{};
    }
    if (_useRemote) {
      return _remote
          .listFavoriteFolderItems()
          .where((item) => item.folderKey == folderKey)
          .map((item) => item.favoriteUniqueKey)
          .toSet();
    }
    final query = objectbox.favoriteFolderItemBox
        .query(
          FavoriteFolderItem_.folderKey
              .equals(folderKey)
              .and(FavoriteFolderItem_.deleted.equals(false)),
        )
        .build();
    try {
      return query.find().map((item) => item.favoriteUniqueKey).toSet();
    } finally {
      query.close();
    }
  }

  static Set<String> folderKeysOfFavorite(String favoriteUniqueKey) {
    final safeKey = favoriteUniqueKey.trim();
    if (safeKey.isEmpty) {
      return const <String>{};
    }
    if (_useRemote) {
      return _remote
          .listFavoriteFolderItems()
          .where((item) => item.favoriteUniqueKey == safeKey)
          .map((item) => item.folderKey)
          .toSet();
    }
    final query = objectbox.favoriteFolderItemBox
        .query(
          FavoriteFolderItem_.favoriteUniqueKey
              .equals(safeKey)
              .and(FavoriteFolderItem_.deleted.equals(false)),
        )
        .build();
    try {
      return query.find().map((item) => item.folderKey).toSet();
    } finally {
      query.close();
    }
  }

  static void addMembers(String folderKey, Iterable<String> uniqueKeys) {
    if (folderKey == kFavoriteFolderAllKey) {
      return;
    }
    if (_useRemote) {
      final now = DateTime.now().toUtc();
      for (final favoriteUniqueKey
          in uniqueKeys.map((e) => e.trim()).where((e) => e.isNotEmpty)) {
        final uniqueKey = _itemUniqueKey(folderKey, favoriteUniqueKey);
        final existing = _remote.findFavoriteFolderItem(uniqueKey);
        if (existing != null) {
          if (existing.deleted) {
            existing
              ..deleted = false
              ..updatedAt = now;
            _remote.saveFavoriteFolderItem(existing);
          }
          continue;
        }
        _remote.saveFavoriteFolderItem(
          FavoriteFolderItem(
            uniqueKey: uniqueKey,
            folderKey: folderKey,
            favoriteUniqueKey: favoriteUniqueKey,
            createdAt: now,
            updatedAt: now,
            deleted: false,
          ),
        );
      }
      return;
    }
    final now = DateTime.now().toUtc();
    final normalized = uniqueKeys
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final favoriteUniqueKey in normalized) {
      final uniqueKey = _itemUniqueKey(folderKey, favoriteUniqueKey);
      final existing = objectbox.favoriteFolderItemBox
          .query(FavoriteFolderItem_.uniqueKey.equals(uniqueKey))
          .build()
          .findFirst();
      if (existing != null) {
        if (existing.deleted) {
          existing.deleted = false;
          existing.updatedAt = now;
          objectbox.favoriteFolderItemBox.put(existing);
        }
        continue;
      }
      objectbox.favoriteFolderItemBox.put(
        FavoriteFolderItem(
          uniqueKey: uniqueKey,
          folderKey: folderKey,
          favoriteUniqueKey: favoriteUniqueKey,
          createdAt: now,
          updatedAt: now,
          deleted: false,
        ),
      );
    }
  }

  static void removeMembers(String folderKey, Iterable<String> uniqueKeys) {
    if (folderKey == kFavoriteFolderAllKey) {
      return;
    }
    if (_useRemote) {
      final now = DateTime.now().toUtc();
      for (final favoriteUniqueKey
          in uniqueKeys.map((e) => e.trim()).where((e) => e.isNotEmpty)) {
        final existing = _remote.findFavoriteFolderItem(
          _itemUniqueKey(folderKey, favoriteUniqueKey),
        );
        if (existing == null || existing.deleted) continue;
        existing
          ..deleted = true
          ..updatedAt = now;
        _remote.saveFavoriteFolderItem(existing);
      }
      return;
    }
    final now = DateTime.now().toUtc();
    final normalized = uniqueKeys
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final favoriteUniqueKey in normalized) {
      final uniqueKey = _itemUniqueKey(folderKey, favoriteUniqueKey);
      final existing = objectbox.favoriteFolderItemBox
          .query(FavoriteFolderItem_.uniqueKey.equals(uniqueKey))
          .build()
          .findFirst();
      if (existing == null || existing.deleted) {
        continue;
      }
      existing.deleted = true;
      existing.updatedAt = now;
      objectbox.favoriteFolderItemBox.put(existing);
    }
  }

  static void removeMemberFromAllFolders(String uniqueKey) {
    final safeKey = uniqueKey.trim();
    if (safeKey.isEmpty) {
      return;
    }
    if (_useRemote) {
      final now = DateTime.now().toUtc();
      for (final item in _remote.listFavoriteFolderItems().where(
        (item) => item.favoriteUniqueKey == safeKey,
      )) {
        item
          ..deleted = true
          ..updatedAt = now;
        _remote.saveFavoriteFolderItem(item);
      }
      return;
    }
    final now = DateTime.now().toUtc();
    final query = objectbox.favoriteFolderItemBox
        .query(
          FavoriteFolderItem_.favoriteUniqueKey
              .equals(safeKey)
              .and(FavoriteFolderItem_.deleted.equals(false)),
        )
        .build();
    try {
      final items = query.find();
      for (final item in items) {
        item.deleted = true;
        item.updatedAt = now;
      }
      if (items.isNotEmpty) {
        objectbox.favoriteFolderItemBox.putMany(items);
      }
    } finally {
      query.close();
    }
  }

  static String _itemUniqueKey(String folderKey, String favoriteUniqueKey) {
    return '$folderKey::$favoriteUniqueKey';
  }
}
