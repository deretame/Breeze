import 'package:zephyr/database/database.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/object_box/model.dart';

const String kDownloadFolderAllKey = 'all';
const String _kDownloadFolderSourcePrefix = 'dl-folder:';

class DownloadFolderView {
  const DownloadFolderView({
    required this.key,
    required this.name,
    this.isAll = false,
  });

  final String key;
  final String name;
  final bool isAll;
}

class DownloadFolderService {
  static String sourceToken(String folderKey) =>
      '$_kDownloadFolderSourcePrefix$folderKey';

  static String? parseFolderKeyFromSources(List<String> sources) {
    for (final source in sources) {
      final trimmed = source.trim();
      if (trimmed.startsWith(_kDownloadFolderSourcePrefix)) {
        return trimmed.substring(_kDownloadFolderSourcePrefix.length);
      }
    }
    return null;
  }

  static List<String> stripFolderSourceTokens(List<String> sources) {
    return sources
        .where((item) => !item.trim().startsWith(_kDownloadFolderSourcePrefix))
        .toList();
  }

  static List<DownloadFolderView> listFolders() {
    final query = database.downloadFolders
        .query((item) => !item.deleted)
        .order((a, b) => a.createdAt.compareTo(b.createdAt))
        .build();
    try {
      final folders = <DownloadFolderView>[
        DownloadFolderView(
          key: kDownloadFolderAllKey,
          name: t.common.all,
          isAll: true,
        ),
      ];
      for (final folder in query.find()) {
        folders.add(
          DownloadFolderView(key: folder.folderKey, name: folder.name),
        );
      }
      return folders;
    } finally {
      query.close();
    }
  }

  static DownloadFolderView createFolder(String name) {
    final safeName = name.trim();
    if (safeName.isEmpty) {
      throw ArgumentError(t.bookshelf.downloadFolderNameEmpty);
    }
    final existed = database.downloadFolders
        .query((item) => item.name == safeName && !item.deleted)
        .build()
        .findFirst();
    if (existed != null) {
      throw StateError(t.bookshelf.downloadFolderNameExists);
    }

    final now = DateTime.now().toUtc();
    final folderKey = 'd_${now.millisecondsSinceEpoch}';
    database.downloadFolders.put(
      DownloadFolder(
        folderKey: folderKey,
        name: safeName,
        createdAt: now,
        updatedAt: now,
        deleted: false,
      ),
    );
    return DownloadFolderView(key: folderKey, name: safeName);
  }

  static void deleteFolder(String folderKey) {
    final safeKey = folderKey.trim();
    if (safeKey.isEmpty || safeKey == kDownloadFolderAllKey) {
      return;
    }
    final now = DateTime.now().toUtc();
    final folder = database.downloadFolders
        .query((item) => item.folderKey == safeKey)
        .build()
        .findFirst();
    if (folder != null && folder.deleted == false) {
      folder.deleted = true;
      folder.updatedAt = now;
      database.downloadFolders.put(folder);
    }
    final itemQuery = database.downloadFolderItems
        .query((item) => item.folderKey == safeKey && !item.deleted)
        .build();
    try {
      final items = itemQuery.find();
      for (final item in items) {
        item.deleted = true;
        item.updatedAt = now;
      }
      if (items.isNotEmpty) {
        database.downloadFolderItems.putMany(items);
      }
    } finally {
      itemQuery.close();
    }
  }

  static void renameFolder(String folderKey, String name) {
    final safeKey = folderKey.trim();
    final safeName = name.trim();
    if (safeKey.isEmpty ||
        safeKey == kDownloadFolderAllKey ||
        safeName.isEmpty) {
      return;
    }
    final duplicated = database.downloadFolders
        .query((item) => item.name == safeName && !item.deleted)
        .build()
        .findFirst();
    if (duplicated != null && duplicated.folderKey != safeKey) {
      throw StateError(t.bookshelf.downloadFolderNameExists);
    }
    final folder = database.downloadFolders
        .query((item) => item.folderKey == safeKey && !item.deleted)
        .build()
        .findFirst();
    if (folder == null) {
      return;
    }
    folder.name = safeName;
    folder.updatedAt = DateTime.now().toUtc();
    database.downloadFolders.put(folder);
  }

  static Set<String> membersOf(String folderKey) {
    if (folderKey == kDownloadFolderAllKey) {
      return const <String>{};
    }
    final query = database.downloadFolderItems
        .query((item) => item.folderKey == folderKey && !item.deleted)
        .build();
    try {
      return query.find().map((item) => item.downloadUniqueKey).toSet();
    } finally {
      query.close();
    }
  }

  static Set<String> folderKeysOfDownload(String downloadUniqueKey) {
    final safeKey = downloadUniqueKey.trim();
    if (safeKey.isEmpty) {
      return const <String>{};
    }
    final query = database.downloadFolderItems
        .query((item) => item.downloadUniqueKey == safeKey && !item.deleted)
        .build();
    try {
      return query.find().map((item) => item.folderKey).toSet();
    } finally {
      query.close();
    }
  }

  static void addMembers(String folderKey, Iterable<String> uniqueKeys) {
    if (folderKey == kDownloadFolderAllKey) {
      return;
    }
    final now = DateTime.now().toUtc();
    final normalized = uniqueKeys
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final downloadUniqueKey in normalized) {
      final uniqueKey = _itemUniqueKey(folderKey, downloadUniqueKey);
      final existing = database.downloadFolderItems
          .query((item) => item.uniqueKey == uniqueKey)
          .build()
          .findFirst();
      if (existing != null) {
        if (existing.deleted) {
          existing.deleted = false;
          existing.updatedAt = now;
          database.downloadFolderItems.put(existing);
        }
        continue;
      }
      database.downloadFolderItems.put(
        DownloadFolderItem(
          uniqueKey: uniqueKey,
          folderKey: folderKey,
          downloadUniqueKey: downloadUniqueKey,
          createdAt: now,
          updatedAt: now,
          deleted: false,
        ),
      );
    }
  }

  static void removeMembers(String folderKey, Iterable<String> uniqueKeys) {
    if (folderKey == kDownloadFolderAllKey) {
      return;
    }
    final now = DateTime.now().toUtc();
    final normalized = uniqueKeys
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final downloadUniqueKey in normalized) {
      final uniqueKey = _itemUniqueKey(folderKey, downloadUniqueKey);
      final existing = database.downloadFolderItems
          .query((item) => item.uniqueKey == uniqueKey)
          .build()
          .findFirst();
      if (existing == null || existing.deleted) {
        continue;
      }
      existing.deleted = true;
      existing.updatedAt = now;
      database.downloadFolderItems.put(existing);
    }
  }

  static void removeMemberFromAllFolders(String uniqueKey) {
    final safeKey = uniqueKey.trim();
    if (safeKey.isEmpty) {
      return;
    }
    final now = DateTime.now().toUtc();
    final query = database.downloadFolderItems
        .query((item) => item.downloadUniqueKey == safeKey && !item.deleted)
        .build();
    try {
      final items = query.find();
      for (final item in items) {
        item.deleted = true;
        item.updatedAt = now;
      }
      if (items.isNotEmpty) {
        database.downloadFolderItems.putMany(items);
      }
    } finally {
      query.close();
    }
  }

  static String _itemUniqueKey(String folderKey, String downloadUniqueKey) {
    return '$folderKey::$downloadUniqueKey';
  }
}
