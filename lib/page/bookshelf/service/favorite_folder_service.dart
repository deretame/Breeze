import 'package:zephyr/database/database.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/object_box/model.dart';

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
    final query = database.favoriteFolders
        .query((item) => !item.deleted)
        .order((a, b) => a.createdAt.compareTo(b.createdAt))
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
    final existed = database.favoriteFolders
        .query((item) => item.name == safeName && !item.deleted)
        .build()
        .findFirst();
    if (existed != null) {
      throw StateError(t.bookshelf.favoriteFolderNameExists);
    }

    final now = DateTime.now().toUtc();
    final folderKey = 'f_${now.millisecondsSinceEpoch}';
    database.favoriteFolders.put(
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
    final now = DateTime.now().toUtc();
    final folder = database.favoriteFolders
        .query((item) => item.folderKey == safeKey)
        .build()
        .findFirst();
    if (folder != null && folder.deleted == false) {
      folder.deleted = true;
      folder.updatedAt = now;
      database.favoriteFolders.put(folder);
    }
    final itemQuery = database.favoriteFolderItems
        .query((item) => item.folderKey == safeKey && !item.deleted)
        .build();
    try {
      final items = itemQuery.find();
      for (final item in items) {
        item.deleted = true;
        item.updatedAt = now;
      }
      if (items.isNotEmpty) {
        database.favoriteFolderItems.putMany(items);
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
    final duplicated = database.favoriteFolders
        .query((item) => item.name == safeName && !item.deleted)
        .build()
        .findFirst();
    if (duplicated != null && duplicated.folderKey != safeKey) {
      throw StateError(t.bookshelf.favoriteFolderNameExists);
    }
    final folder = database.favoriteFolders
        .query((item) => item.folderKey == safeKey && !item.deleted)
        .build()
        .findFirst();
    if (folder == null) {
      return;
    }
    folder.name = safeName;
    folder.updatedAt = DateTime.now().toUtc();
    database.favoriteFolders.put(folder);
  }

  static Set<String> membersOf(String folderKey) {
    if (folderKey == kFavoriteFolderAllKey) {
      return const <String>{};
    }
    final query = database.favoriteFolderItems
        .query((item) => item.folderKey == folderKey && !item.deleted)
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
    final query = database.favoriteFolderItems
        .query((item) => item.favoriteUniqueKey == safeKey && !item.deleted)
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
    final now = DateTime.now().toUtc();
    final normalized = uniqueKeys
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final favoriteUniqueKey in normalized) {
      final uniqueKey = _itemUniqueKey(folderKey, favoriteUniqueKey);
      final existing = database.favoriteFolderItems
          .query((item) => item.uniqueKey == uniqueKey)
          .build()
          .findFirst();
      if (existing != null) {
        if (existing.deleted) {
          existing.deleted = false;
          existing.updatedAt = now;
          database.favoriteFolderItems.put(existing);
        }
        continue;
      }
      database.favoriteFolderItems.put(
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
    final now = DateTime.now().toUtc();
    final normalized = uniqueKeys
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final favoriteUniqueKey in normalized) {
      final uniqueKey = _itemUniqueKey(folderKey, favoriteUniqueKey);
      final existing = database.favoriteFolderItems
          .query((item) => item.uniqueKey == uniqueKey)
          .build()
          .findFirst();
      if (existing == null || existing.deleted) {
        continue;
      }
      existing.deleted = true;
      existing.updatedAt = now;
      database.favoriteFolderItems.put(existing);
    }
  }

  static void removeMemberFromAllFolders(String uniqueKey) {
    final safeKey = uniqueKey.trim();
    if (safeKey.isEmpty) {
      return;
    }
    final now = DateTime.now().toUtc();
    final query = database.favoriteFolderItems
        .query((item) => item.favoriteUniqueKey == safeKey && !item.deleted)
        .build();
    try {
      final items = query.find();
      for (final item in items) {
        item.deleted = true;
        item.updatedAt = now;
      }
      if (items.isNotEmpty) {
        database.favoriteFolderItems.putMany(items);
      }
    } finally {
      query.close();
    }
  }

  static String _itemUniqueKey(String folderKey, String favoriteUniqueKey) {
    return '$folderKey::$favoriteUniqueKey';
  }
}
