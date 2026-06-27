import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/network/sync/comic_sync_core.dart';
import 'package:zephyr/network/sync/sync_device_id.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';

void main() {
  late Directory tempDir;
  late Store store;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('breeze_sync_test_');
    store = await openStore(directory: tempDir.path);
    syncDeviceId = 'device_local';
  });

  tearDown(() async {
    store.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });
  Future<void> runMerge(
    Store store,
    Map<String, dynamic> data, {
    String deviceId = 'device_local',
  }) async {
    syncDeviceId = deviceId;
    await store.runInTransactionAsync<int, Map<String, dynamic>>(
      TxMode.write,
      ComicSyncCore.mergeUnifiedDataInIsolate,
      {'_data': data, '_deviceId': deviceId},
    );
  }

  group('ComicSyncCore.mergeUnifiedData', () {
    test('merges favorites by LWW', () async {
      final localUpdated = DateTime.utc(2024, 1, 1, 12, 0);
      final cloudUpdated = DateTime.utc(2024, 1, 1, 13, 0);

      final local = createFavorite(
        'test:comic1',
        title: 'Local Title',
        updatedAt: localUpdated,
      );
      final cloud = createFavorite(
        'test:comic1',
        title: 'Cloud Title',
        updatedAt: cloudUpdated,
      );

      final data = buildPayload(favorites: [cloud.toJson()]);
      putAll(store, favorites: [local]);

      await runMerge(store, data);

      final box = store.box<UnifiedComicFavorite>();
      final merged = box.getAll().single;
      expect(merged.title, 'Cloud Title');
    });

    test('merges histories by LWW', () async {
      final local = createHistory('test:comic1', pageIndex: 10);
      final cloud = createHistory(
        'test:comic1',
        pageIndex: 20,
        updatedAt: local.updatedAt.add(const Duration(hours: 1)),
      );

      final data = buildPayload(histories: [cloud.toJson()]);
      putAll(store, histories: [local]);

      await runMerge(store, data);

      final merged = store.box<UnifiedComicHistory>().getAll().single;
      expect(merged.pageIndex, 20);
    });

    test('merges folders by version vector when cloud dominates', () async {
      final local = createFolder('folderA', versionVector: {'device_local': 1});
      final cloud = createFolder('folderA', versionVector: {'device_cloud': 2});

      final data = buildPayload(folders: [cloud.toJson()]);
      putAll(store, folders: [local]);

      await runMerge(store, data);

      final merged = store.box<ComicFolder>().getAll().single;
      expect(merged.syncId, cloud.syncId);
    });

    test('keeps local folder when local dominates', () async {
      final local = createFolder('folderA', versionVector: {'device_local': 2});
      final cloud = createFolder('folderA', versionVector: {'device_cloud': 1});

      final data = buildPayload(folders: [cloud.toJson()]);
      putAll(store, folders: [local]);

      await runMerge(store, data);

      final merged = store.box<ComicFolder>().getAll().single;
      expect(merged.syncId, local.syncId);
    });

    test('resolves folder uniqueKey conflict with active winner', () async {
      // Two devices created a folder with same parent/name/type but different syncIds.
      final localFolder = createFolder(
        'conflict',
        syncId: 'sync_local',
        versionVector: {'device_local': 2},
      );
      localFolder.updatedAt = 2000;
      final cloudFolder = createFolder(
        'conflict',
        syncId: 'sync_cloud',
        versionVector: {'device_cloud': 1},
      );
      cloudFolder.updatedAt = 1000;
      final child = createFolder(
        'child',
        syncId: 'child_sync',
        parentSyncId: cloudFolder.syncId,
        versionVector: {'device_cloud': 1},
      );
      final link = createLink(
        'test:comic1',
        folderSyncId: cloudFolder.syncId,
        versionVector: {'device_cloud': 1},
      );

      final data = buildPayload(
        folders: [cloudFolder.toJson(), child.toJson()],
        links: [link.toJson()],
      );
      putAll(store, folders: [localFolder]);

      await runMerge(store, data);

      final folders = store.box<ComicFolder>().getAll();
      final links = store.box<ComicLink>().getAll();

      // Only one active folder remains for the uniqueKey.
      final activeFolders = folders.where((f) => f.deletedAt == null).toList();
      expect(activeFolders.length, 2); // winner + child
      final winner = activeFolders.firstWhere((f) => f.name == 'conflict');
      expect(winner.syncId, localFolder.syncId);

      // Child's parent should be migrated to winner.
      final storedChild = activeFolders.firstWhere((f) => f.name == 'child');
      expect(storedChild.parentSyncId, winner.syncId);

      // Link should point to winner.
      expect(links.single.folderSyncId, winner.syncId);
    });

    test('resolves folder uniqueKey conflict with tombstone winner', () async {
      final localFolder = createFolder(
        'conflict',
        syncId: 'sync_local',
        versionVector: {'device_local': 2},
        deletedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
      );
      final cloudFolder = createFolder(
        'conflict',
        syncId: 'sync_cloud',
        versionVector: {'device_cloud': 1},
      );
      final cloudChild = createFolder(
        'child',
        syncId: 'child_sync',
        parentSyncId: cloudFolder.syncId,
        versionVector: {'device_cloud': 1},
      );
      final link = createLink(
        'test:comic1',
        folderSyncId: cloudFolder.syncId,
        versionVector: {'device_cloud': 1},
      );

      final data = buildPayload(
        folders: [cloudFolder.toJson(), cloudChild.toJson()],
        links: [link.toJson()],
      );
      putAll(store, folders: [localFolder]);

      await runMerge(store, data);

      final folders = store.box<ComicFolder>().getAll();
      final links = store.box<ComicLink>().getAll();

      expect(folders.every((f) => f.deletedAt != null), isTrue);
      expect(links.single.deletedAt, isNotNull);
    });

    test(
      'repairs orphan links by moving to root when folder syncId is missing',
      () async {
        // Cloud has a link pointing to a non-existent folder syncId.
        final link = createLink(
          'test:comic1',
          folderSyncId: 'missing_sync',
          versionVector: {'device_cloud': 1},
        );

        final data = buildPayload(links: [link.toJson()]);
        await runMerge(store, data);

        final folders = store.box<ComicFolder>().getAll();
        final links = store.box<ComicLink>().getAll();

        // No folders are created because the syncId cannot be resolved to a path.
        expect(folders, isEmpty);
        // The orphan link is repaired to point to the root folder.
        expect(links.single.deletedAt, isNull);
        expect(links.single.folderSyncId, isNull);
        expect(links.single.uniqueKey, 'test:comic1||favorite');
      },
    );

    test(
      'repairs orphan links by resurrecting tombstone folder when link dominates',
      () async {
        final folder = createFolder(
          'folderA',
          syncId: 'folder_sync',
          versionVector: {'device_local': 1},
          deletedAt: DateTime.now().toUtc().millisecondsSinceEpoch,
        );
        final link = createLink(
          'test:comic1',
          folderSyncId: 'folder_sync',
          versionVector: {'device_cloud': 2},
        );

        final data = buildPayload(links: [link.toJson()]);
        putAll(store, folders: [folder]);

        await runMerge(store, data);

        final storedFolder = store.box<ComicFolder>().getAll().single;
        final storedLink = store.box<ComicLink>().getAll().single;
        expect(storedFolder.deletedAt, isNull);
        expect(storedLink.deletedAt, isNull);
        expect(storedLink.folderSyncId, storedFolder.syncId);
      },
    );

    test('handles old path-based folder uniqueKey migration', () async {
      // Simulate old data: uniqueKey is "/parent/child|favorite" and no parentSyncId.
      final oldChild = ComicFolder(
        syncId: 'old_child',
        parentSyncId: null,
        uniqueKey: '/parent/child|favorite',
        name: 'child',
        typeData: ComicFolderType.favorite.name,
        versionVectorJson: '{"device_cloud": 1}',
        createdAt: 1,
        updatedAt: 1,
      );
      final oldParent = ComicFolder(
        syncId: 'old_parent',
        parentSyncId: null,
        uniqueKey: '/parent|favorite',
        name: 'parent',
        typeData: ComicFolderType.favorite.name,
        versionVectorJson: '{"device_cloud": 1}',
        createdAt: 1,
        updatedAt: 1,
      );

      final data = buildPayload(
        folders: [oldParent.toJson(), oldChild.toJson()],
      );
      await runMerge(store, data);

      final folders = store.box<ComicFolder>().getAll();
      final parent = folders.firstWhere((f) => f.name == 'parent');
      final child = folders.firstWhere((f) => f.name == 'child');

      expect(child.parentSyncId, parent.syncId);
      expect(parent.uniqueKey, '|parent|favorite');
      expect(child.uniqueKey, '${parent.syncId}|child|favorite');
    });

    test('handles concurrent folder rename conflict', () async {
      // Both devices renamed the same original folder differently.
      final localFolder = createFolder(
        'renamed_local',
        syncId: 'sync_original',
        versionVector: {'device_local': 2, 'device_cloud': 1},
      );
      final cloudFolder = createFolder(
        'renamed_cloud',
        syncId: 'sync_original',
        versionVector: {'device_cloud': 1},
      );

      final data = buildPayload(folders: [cloudFolder.toJson()]);
      putAll(store, folders: [localFolder]);

      await runMerge(store, data);

      final merged = store.box<ComicFolder>().getAll().single;
      // Local dominates by version vector.
      expect(merged.name, 'renamed_local');
      expect(merged.uniqueKey, '|renamed_local|favorite');
    });

    test('handles delete vs active conflict: delete dominates', () async {
      // Local deleted the folder; cloud created an active folder with same uniqueKey.
      final deletedFolder = createFolder(
        'folderA',
        syncId: 'sync_local',
        versionVector: {'device_local': 2, 'device_cloud': 1},
        deletedAt: 1000,
      );
      final cloudFolder = createFolder(
        'folderA',
        syncId: 'sync_cloud',
        versionVector: {'device_cloud': 1},
      );
      final cloudChild = createFolder(
        'child',
        syncId: 'sync_child',
        parentSyncId: cloudFolder.syncId,
        versionVector: {'device_cloud': 1},
      );

      final data = buildPayload(
        folders: [cloudFolder.toJson(), cloudChild.toJson()],
      );
      putAll(store, folders: [deletedFolder]);

      await runMerge(store, data);

      final folders = store.box<ComicFolder>().getAll();
      expect(folders.every((f) => f.deletedAt != null), isTrue);
    });

    test('handles equal version vectors by picking higher updatedAt', () async {
      final localFolder = createFolder(
        'folderA',
        syncId: 'sync_local',
        versionVector: {'device_local': 1, 'device_cloud': 1},
      );
      localFolder.updatedAt = 1000;
      final cloudFolder = createFolder(
        'folderA',
        syncId: 'sync_cloud',
        versionVector: {'device_local': 1, 'device_cloud': 1},
      );
      cloudFolder.updatedAt = 2000;

      final data = buildPayload(folders: [cloudFolder.toJson()]);
      putAll(store, folders: [localFolder]);

      await runMerge(store, data);

      // 向量相等时按 updatedAt 更大的选，确保多端 converge。
      final merged = store.box<ComicFolder>().getAll().single;
      expect(merged.syncId, cloudFolder.syncId);
    });

    test(
      'handles equal version vectors and updatedAt by syncId tie-break',
      () async {
        final localFolder = createFolder(
          'folderA',
          syncId: 'sync_zzz',
          versionVector: {'device_local': 1, 'device_cloud': 1},
        );
        localFolder.updatedAt = 1000;
        final cloudFolder = createFolder(
          'folderA',
          syncId: 'sync_aaa',
          versionVector: {'device_local': 1, 'device_cloud': 1},
        );
        cloudFolder.updatedAt = 1000;

        final data = buildPayload(folders: [cloudFolder.toJson()]);
        putAll(store, folders: [localFolder]);

        await runMerge(store, data);

        // updatedAt 也相同时按 syncId 字典序更大者胜出。
        final merged = store.box<ComicFolder>().getAll().single;
        expect(merged.syncId, localFolder.syncId);
      },
    );

    test('handles same comic added to same folder on two devices', () async {
      final folder = createFolder('folderA', syncId: 'sync_folder');
      final localLink = createLink(
        'test:comic1',
        folderSyncId: 'sync_folder',
        versionVector: {'device_local': 1},
      );
      final cloudLink = createLink(
        'test:comic1',
        folderSyncId: 'sync_folder',
        versionVector: {'device_cloud': 1},
      );

      final data = buildPayload(
        folders: [folder.toJson()],
        links: [cloudLink.toJson()],
      );
      putAll(store, folders: [folder], links: [localLink]);

      await runMerge(store, data);

      final links = store.box<ComicLink>().getAll();
      expect(links.length, 1);
      expect(links.single.deletedAt, isNull);
    });

    test('handles folder deleted and recreated with same name', () async {
      // Old folder was deleted; new folder with same name created.
      final oldFolder = createFolder(
        'sameName',
        syncId: 'sync_old',
        versionVector: {'device_local': 1},
        deletedAt: 1000,
      );
      oldFolder.updatedAt = 1000;
      final newFolder = createFolder(
        'sameName',
        syncId: 'sync_new',
        versionVector: {'device_cloud': 1},
      );

      final data = buildPayload(folders: [newFolder.toJson()]);
      putAll(store, folders: [oldFolder]);

      await runMerge(store, data);

      final folders = store.box<ComicFolder>().getAll();
      expect(folders.length, 1);
      expect(folders.single.deletedAt, isNull);
      expect(folders.single.syncId, newFolder.syncId);
    });

    test('handles old link uniqueKey with nested path migration', () async {
      // Old link uniqueKey format: comic|/parent/child|favorite
      final oldParent = ComicFolder(
        syncId: 'old_parent',
        parentSyncId: null,
        uniqueKey: '/parent|favorite',
        name: 'parent',
        typeData: ComicFolderType.favorite.name,
        versionVectorJson: '{"device_cloud": 1}',
        createdAt: 1,
        updatedAt: 1,
      );
      final oldChild = ComicFolder(
        syncId: 'old_child',
        parentSyncId: null,
        uniqueKey: '/parent/child|favorite',
        name: 'child',
        typeData: ComicFolderType.favorite.name,
        versionVectorJson: '{"device_cloud": 1}',
        createdAt: 1,
        updatedAt: 1,
      );
      final oldLink = ComicLink(
        uniqueKey: 'test:comic1|/parent/child|favorite',
        comicUniqueKey: 'test:comic1',
        folderSyncId: null,
        typeData: ComicFolderType.favorite.name,
        versionVectorJson: '{"device_cloud": 1}',
        createdAt: 1,
        updatedAt: 1,
      );

      final data = buildPayload(
        folders: [oldParent.toJson(), oldChild.toJson()],
        links: [oldLink.toJson()],
      );
      await runMerge(store, data);

      final folders = store.box<ComicFolder>().getAll();
      final child = folders.firstWhere((f) => f.name == 'child');
      final link = store.box<ComicLink>().getAll().single;
      expect(link.folderSyncId, child.syncId);
      expect(link.uniqueKey, 'test:comic1|${child.syncId}|favorite');
    });

    test('handles mixed old and new folder/link data', () async {
      // New-style folder, old-style link without folderSyncId.
      final newFolder = createFolder('folderA', syncId: 'sync_folder');
      final oldLink = ComicLink(
        uniqueKey: 'test:comic1|/folderA|favorite',
        comicUniqueKey: 'test:comic1',
        folderSyncId: null,
        typeData: ComicFolderType.favorite.name,
        versionVectorJson: '{"device_cloud": 1}',
        createdAt: 1,
        updatedAt: 1,
      );

      final data = buildPayload(
        folders: [newFolder.toJson()],
        links: [oldLink.toJson()],
      );
      await runMerge(store, data);

      final link = store.box<ComicLink>().getAll().single;
      expect(link.folderSyncId, newFolder.syncId);
    });

    test('preserves local data when cloud is empty', () async {
      final localFolder = createFolder('folderA');
      final localFavorite = createFavorite('test:comic1');
      putAll(store, folders: [localFolder], favorites: [localFavorite]);

      await runMerge(store, buildPayload());

      expect(store.box<ComicFolder>().getAll().length, 1);
      expect(store.box<UnifiedComicFavorite>().getAll().length, 1);
    });

    test('applies cloud data when local is empty', () async {
      final cloudFolder = createFolder('folderA');
      final cloudFavorite = createFavorite('test:comic1');

      final data = buildPayload(
        folders: [cloudFolder.toJson()],
        favorites: [cloudFavorite.toJson()],
      );
      await runMerge(store, data);

      expect(store.box<ComicFolder>().getAll().length, 1);
      expect(store.box<UnifiedComicFavorite>().getAll().length, 1);
    });

    test('handles large number of folders and links', () async {
      const count = 500;
      final folders = <ComicFolder>[];
      final links = <ComicLink>[];
      for (var i = 0; i < count; i++) {
        final folder = createFolder('folder$i', syncId: 'sync_folder_$i');
        folders.add(folder);
        links.add(createLink('test:comic$i', folderSyncId: folder.syncId));
      }

      final data = buildPayload(
        folders: folders.map((f) => f.toJson()).toList(),
        links: links.map((l) => l.toJson()).toList(),
      );
      await runMerge(store, data);

      expect(store.box<ComicFolder>().getAll().length, count);
      expect(store.box<ComicLink>().getAll().length, count);
    });
  });
}

// ==================== 测试工具函数 ====================

Map<String, dynamic> buildPayload({
  List<Map<String, dynamic>> favorites = const [],
  List<Map<String, dynamic>> histories = const [],
  List<Map<String, dynamic>> folders = const [],
  List<Map<String, dynamic>> links = const [],
}) {
  return {
    'version': 'v1',
    'favorites': favorites,
    'histories': histories,
    'folders': folders,
    'links': links,
  };
}

void putAll(
  Store store, {
  List<UnifiedComicFavorite> favorites = const [],
  List<UnifiedComicHistory> histories = const [],
  List<ComicFolder> folders = const [],
  List<ComicLink> links = const [],
}) {
  store.box<UnifiedComicFavorite>().putMany(favorites);
  store.box<UnifiedComicHistory>().putMany(histories);
  store.box<ComicFolder>().putMany(folders);
  store.box<ComicLink>().putMany(links);
}

UnifiedComicFavorite createFavorite(
  String uniqueKey, {
  String title = 'Test',
  DateTime? updatedAt,
  bool deleted = false,
}) {
  final now = updatedAt ?? DateTime.now().toUtc();
  return UnifiedComicFavorite(
    uniqueKey: uniqueKey,
    source: 'test',
    comicId: uniqueKey,
    title: title,
    description: '',
    cover: '',
    creator: '',
    titleMeta: '',
    metadata: '',
    createdAt: now,
    updatedAt: now,
    deleted: deleted,
    schemaVersion: 1,
  );
}

UnifiedComicHistory createHistory(
  String uniqueKey, {
  int pageIndex = 0,
  DateTime? updatedAt,
}) {
  final now = updatedAt ?? DateTime.now().toUtc();
  return UnifiedComicHistory(
    uniqueKey: uniqueKey,
    source: 'test',
    comicId: uniqueKey,
    title: 'Test',
    description: '',
    cover: '',
    creator: '',
    titleMeta: '',
    metadata: '',
    chapterId: '',
    chapterTitle: '',
    chapterOrder: 0,
    pageIndex: pageIndex,
    createdAt: now,
    lastReadAt: now,
    updatedAt: now,
    deleted: false,
    schemaVersion: 1,
  );
}

ComicFolder createFolder(
  String name, {
  String? syncId,
  String? parentSyncId,
  Map<String, int>? versionVector,
  int? deletedAt,
}) {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  return ComicFolder(
    syncId: syncId ?? '${name}_sync',
    parentSyncId: parentSyncId,
    uniqueKey: '${parentSyncId ?? ''}|$name|favorite',
    name: name,
    typeData: ComicFolderType.favorite.name,
    versionVectorJson: versionVector != null
        ? jsonMap(versionVector)
        : '{"device_local": 1}',
    deletedAt: deletedAt,
    createdAt: now,
    updatedAt: now,
  );
}

ComicLink createLink(
  String comicUniqueKey, {
  required String folderSyncId,
  Map<String, int>? versionVector,
}) {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  return ComicLink(
    uniqueKey: '$comicUniqueKey|$folderSyncId|favorite',
    comicUniqueKey: comicUniqueKey,
    folderSyncId: folderSyncId,
    typeData: ComicFolderType.favorite.name,
    versionVectorJson: versionVector != null
        ? jsonMap(versionVector)
        : '{"device_local": 1}',
    createdAt: now,
    updatedAt: now,
  );
}

String jsonMap(Map<String, int> map) {
  final buffer = StringBuffer('{');
  var first = true;
  map.forEach((key, value) {
    if (!first) buffer.write(',');
    buffer.write('"$key":$value');
    first = false;
  });
  buffer.write('}');
  return buffer.toString();
}
