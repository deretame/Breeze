import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/cs/application/cs_runtime_context.dart';
import 'package:zephyr/cs/data/cs_remote_database.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';

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
  static bool get _useRemote =>
      CsRuntimeContext.I.isServerDownload &&
      CsRuntimeContext.I.database != null;

  static CsRemoteDatabase get _remote => CsRuntimeContext.I.database!;

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
    if (_useRemote) {
      final folders = <DownloadFolderView>[
        DownloadFolderView(
          key: kDownloadFolderAllKey,
          name: t.common.all,
          isAll: true,
        ),
      ];
      final remoteFolders = _remote.listDownloadFolders()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      folders.addAll(
        remoteFolders.map(
          (folder) =>
              DownloadFolderView(key: folder.folderKey, name: folder.name),
        ),
      );
      return folders;
    }
    final query = objectbox.downloadFolderBox
        .query(DownloadFolder_.deleted.equals(false))
        .order(DownloadFolder_.createdAt)
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
    if (_useRemote) {
      if (_remote.listDownloadFolders().any(
        (folder) => folder.name == safeName,
      )) {
        throw StateError(t.bookshelf.downloadFolderNameExists);
      }
      final now = DateTime.now().toUtc();
      final folderKey = 'd_${now.millisecondsSinceEpoch}';
      _remote.saveDownloadFolder(
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
    final existed = objectbox.downloadFolderBox
        .query(
          DownloadFolder_.name
              .equals(safeName)
              .and(DownloadFolder_.deleted.equals(false)),
        )
        .build()
        .findFirst();
    if (existed != null) {
      throw StateError(t.bookshelf.downloadFolderNameExists);
    }

    final now = DateTime.now().toUtc();
    final folderKey = 'd_${now.millisecondsSinceEpoch}';
    objectbox.downloadFolderBox.put(
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
    if (_useRemote) {
      final now = DateTime.now().toUtc();
      final folder = _remote.findDownloadFolder(safeKey);
      if (folder != null && !folder.deleted) {
        folder
          ..deleted = true
          ..updatedAt = now;
        _remote.saveDownloadFolder(folder);
      }
      for (final item in _remote.listDownloadFolderItems().where(
        (item) => item.folderKey == safeKey,
      )) {
        item
          ..deleted = true
          ..updatedAt = now;
        _remote.saveDownloadFolderItem(item);
      }
      return;
    }
    final now = DateTime.now().toUtc();
    final folder = objectbox.downloadFolderBox
        .query(DownloadFolder_.folderKey.equals(safeKey))
        .build()
        .findFirst();
    if (folder != null && folder.deleted == false) {
      folder.deleted = true;
      folder.updatedAt = now;
      objectbox.downloadFolderBox.put(folder);
    }
    final itemQuery = objectbox.downloadFolderItemBox
        .query(
          DownloadFolderItem_.folderKey
              .equals(safeKey)
              .and(DownloadFolderItem_.deleted.equals(false)),
        )
        .build();
    try {
      final items = itemQuery.find();
      for (final item in items) {
        item.deleted = true;
        item.updatedAt = now;
      }
      if (items.isNotEmpty) {
        objectbox.downloadFolderItemBox.putMany(items);
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
    if (_useRemote) {
      if (_remote.listDownloadFolders().any(
        (folder) => folder.name == safeName && folder.folderKey != safeKey,
      )) {
        throw StateError(t.bookshelf.downloadFolderNameExists);
      }
      final folder = _remote.findDownloadFolder(safeKey);
      if (folder == null || folder.deleted) return;
      folder
        ..name = safeName
        ..updatedAt = DateTime.now().toUtc();
      _remote.saveDownloadFolder(folder);
      return;
    }
    final duplicated = objectbox.downloadFolderBox
        .query(
          DownloadFolder_.name
              .equals(safeName)
              .and(DownloadFolder_.deleted.equals(false)),
        )
        .build()
        .findFirst();
    if (duplicated != null && duplicated.folderKey != safeKey) {
      throw StateError(t.bookshelf.downloadFolderNameExists);
    }
    final folder = objectbox.downloadFolderBox
        .query(
          DownloadFolder_.folderKey
              .equals(safeKey)
              .and(DownloadFolder_.deleted.equals(false)),
        )
        .build()
        .findFirst();
    if (folder == null) {
      return;
    }
    folder.name = safeName;
    folder.updatedAt = DateTime.now().toUtc();
    objectbox.downloadFolderBox.put(folder);
  }

  static Set<String> membersOf(String folderKey) {
    if (folderKey == kDownloadFolderAllKey) {
      return const <String>{};
    }
    if (_useRemote) {
      return _remote
          .listDownloadFolderItems()
          .where((item) => item.folderKey == folderKey)
          .map((item) => item.downloadUniqueKey)
          .toSet();
    }
    final query = objectbox.downloadFolderItemBox
        .query(
          DownloadFolderItem_.folderKey
              .equals(folderKey)
              .and(DownloadFolderItem_.deleted.equals(false)),
        )
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
    if (_useRemote) {
      return _remote
          .listDownloadFolderItems()
          .where((item) => item.downloadUniqueKey == safeKey)
          .map((item) => item.folderKey)
          .toSet();
    }
    final query = objectbox.downloadFolderItemBox
        .query(
          DownloadFolderItem_.downloadUniqueKey
              .equals(safeKey)
              .and(DownloadFolderItem_.deleted.equals(false)),
        )
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
    if (_useRemote) {
      final now = DateTime.now().toUtc();
      for (final downloadUniqueKey
          in uniqueKeys.map((e) => e.trim()).where((e) => e.isNotEmpty)) {
        final uniqueKey = _itemUniqueKey(folderKey, downloadUniqueKey);
        final existing = _remote.findDownloadFolderItem(uniqueKey);
        if (existing != null) {
          if (existing.deleted) {
            existing
              ..deleted = false
              ..updatedAt = now;
            _remote.saveDownloadFolderItem(existing);
          }
          continue;
        }
        _remote.saveDownloadFolderItem(
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
      return;
    }
    final now = DateTime.now().toUtc();
    final normalized = uniqueKeys
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final downloadUniqueKey in normalized) {
      final uniqueKey = _itemUniqueKey(folderKey, downloadUniqueKey);
      final existing = objectbox.downloadFolderItemBox
          .query(DownloadFolderItem_.uniqueKey.equals(uniqueKey))
          .build()
          .findFirst();
      if (existing != null) {
        if (existing.deleted) {
          existing.deleted = false;
          existing.updatedAt = now;
          objectbox.downloadFolderItemBox.put(existing);
        }
        continue;
      }
      objectbox.downloadFolderItemBox.put(
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
    if (_useRemote) {
      final now = DateTime.now().toUtc();
      for (final downloadUniqueKey
          in uniqueKeys.map((e) => e.trim()).where((e) => e.isNotEmpty)) {
        final existing = _remote.findDownloadFolderItem(
          _itemUniqueKey(folderKey, downloadUniqueKey),
        );
        if (existing == null || existing.deleted) continue;
        existing
          ..deleted = true
          ..updatedAt = now;
        _remote.saveDownloadFolderItem(existing);
      }
      return;
    }
    final now = DateTime.now().toUtc();
    final normalized = uniqueKeys
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty);
    for (final downloadUniqueKey in normalized) {
      final uniqueKey = _itemUniqueKey(folderKey, downloadUniqueKey);
      final existing = objectbox.downloadFolderItemBox
          .query(DownloadFolderItem_.uniqueKey.equals(uniqueKey))
          .build()
          .findFirst();
      if (existing == null || existing.deleted) {
        continue;
      }
      existing.deleted = true;
      existing.updatedAt = now;
      objectbox.downloadFolderItemBox.put(existing);
    }
  }

  static void removeMemberFromAllFolders(String uniqueKey) {
    final safeKey = uniqueKey.trim();
    if (safeKey.isEmpty) {
      return;
    }
    if (_useRemote) {
      final now = DateTime.now().toUtc();
      for (final item in _remote.listDownloadFolderItems().where(
        (item) => item.downloadUniqueKey == safeKey,
      )) {
        item
          ..deleted = true
          ..updatedAt = now;
        _remote.saveDownloadFolderItem(item);
      }
      return;
    }
    final now = DateTime.now().toUtc();
    final query = objectbox.downloadFolderItemBox
        .query(
          DownloadFolderItem_.downloadUniqueKey
              .equals(safeKey)
              .and(DownloadFolderItem_.deleted.equals(false)),
        )
        .build();
    try {
      final items = query.find();
      for (final item in items) {
        item.deleted = true;
        item.updatedAt = now;
      }
      if (items.isNotEmpty) {
        objectbox.downloadFolderItemBox.putMany(items);
      }
    } finally {
      query.close();
    }
  }

  static String _itemUniqueKey(String folderKey, String downloadUniqueKey) {
    return '$folderKey::$downloadUniqueKey';
  }
}
