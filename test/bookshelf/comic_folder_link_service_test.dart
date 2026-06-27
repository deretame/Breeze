import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/service/comic_folder_service.dart';
import 'package:zephyr/page/bookshelf/service/comic_link_service.dart';

import '../test_helper.dart';

void main() {
  setUpAll(TestObjectBoxHelper.setUpTestObjectBox);
  tearDownAll(TestObjectBoxHelper.tearDownTestObjectBox);
  tearDown(TestObjectBoxHelper.cleanComicFolderBoxes);

  group('ComicFolderService', () {
    test('createFolder creates folder at root', () {
      final folder = ComicFolderService.createFolder(
        '',
        'folderA',
        ComicFolderType.favorite,
      );
      expect(folder.name, 'folderA');
      expect(folder.parentSyncId, isNull);
      expect(folder.typeData, ComicFolderType.favorite.name);
      expect(folder.syncId, isNotEmpty);
      expect(folder.deletedAt, isNull);
    });

    test('createFolder creates nested folder', () {
      final parent = ComicFolderService.createFolder(
        '',
        'parent',
        ComicFolderType.favorite,
      );
      final path = ComicFolderService.folderPath(parent);
      final child = ComicFolderService.createFolder(
        path,
        'child',
        ComicFolderType.favorite,
      );
      expect(child.parentSyncId, parent.syncId);
      expect(ComicFolderService.folderPath(child), '/parent/child');
    });

    test('createFolder empty name throws', () {
      expect(
        () => ComicFolderService.createFolder(
          '',
          '   ',
          ComicFolderType.favorite,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createFolder name with slash throws', () {
      expect(
        () => ComicFolderService.createFolder(
          '',
          'a/b',
          ComicFolderType.favorite,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('createFolder duplicate active throws', () {
      ComicFolderService.createFolder('', 'dup', ComicFolderType.favorite);
      expect(
        () => ComicFolderService.createFolder(
          '',
          'dup',
          ComicFolderType.favorite,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('createFolder resurrects tombstone', () {
      final folder = ComicFolderService.createFolder(
        '',
        'res',
        ComicFolderType.favorite,
      );
      final path = ComicFolderService.folderPath(folder);
      ComicFolderService.deleteFolder(path, ComicFolderType.favorite);

      final resurrected = ComicFolderService.createFolder(
        '',
        'res',
        ComicFolderType.favorite,
      );
      expect(resurrected.id, folder.id);
      expect(resurrected.deletedAt, isNull);
      expect(resurrected.syncId, folder.syncId);
    });

    test('renameFolder updates name and uniqueKey', () {
      final folder = ComicFolderService.createFolder(
        '',
        'old',
        ComicFolderType.favorite,
      );
      final path = ComicFolderService.folderPath(folder);
      ComicFolderService.renameFolder(path, 'new', ComicFolderType.favorite);

      final renamed = objectbox.comicFolderBox.get(folder.id);
      expect(renamed!.name, 'new');
      expect(ComicFolderService.folderPath(renamed), '/new');
    });

    test('renameFolder duplicate active throws', () {
      ComicFolderService.createFolder('', 'a', ComicFolderType.favorite);
      final b = ComicFolderService.createFolder(
        '',
        'b',
        ComicFolderType.favorite,
      );
      final bPath = ComicFolderService.folderPath(b);
      expect(
        () => ComicFolderService.renameFolder(
          bPath,
          'a',
          ComicFolderType.favorite,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('renameFolder removes conflicting tombstone', () {
      final a = ComicFolderService.createFolder(
        '',
        'a',
        ComicFolderType.favorite,
      );
      final aPath = ComicFolderService.folderPath(a);
      ComicFolderService.deleteFolder(aPath, ComicFolderType.favorite);

      final b = ComicFolderService.createFolder(
        '',
        'b',
        ComicFolderType.favorite,
      );
      final bPath = ComicFolderService.folderPath(b);
      ComicFolderService.renameFolder(bPath, 'a', ComicFolderType.favorite);

      expect(objectbox.comicFolderBox.get(a.id), isNull);
      expect(objectbox.comicFolderBox.get(b.id)!.name, 'a');
    });

    test('deleteFolder soft deletes folder and descendants', () {
      final parent = ComicFolderService.createFolder(
        '',
        'parent',
        ComicFolderType.favorite,
      );
      final parentPath = ComicFolderService.folderPath(parent);
      final child = ComicFolderService.createFolder(
        parentPath,
        'child',
        ComicFolderType.favorite,
      );

      ComicFolderService.deleteFolder(parentPath, ComicFolderType.favorite);

      expect(objectbox.comicFolderBox.get(parent.id)!.deletedAt, isNotNull);
      expect(objectbox.comicFolderBox.get(child.id)!.deletedAt, isNotNull);
    });

    test('deleteFolder does not delete root', () {
      ComicFolderService.deleteFolder('', ComicFolderType.favorite);
      // No exception and nothing to assert; root has no entity.
      expect(true, isTrue);
    });

    test('batchMoveFolders moves folder to new parent', () {
      final a = ComicFolderService.createFolder(
        '',
        'a',
        ComicFolderType.favorite,
      );
      final aPath = ComicFolderService.folderPath(a);
      final b = ComicFolderService.createFolder(
        '',
        'b',
        ComicFolderType.favorite,
      );
      final bPath = ComicFolderService.folderPath(b);

      ComicFolderService.batchMoveFolders(
        {aPath},
        bPath,
        ComicFolderType.favorite,
      );

      final moved = objectbox.comicFolderBox.get(a.id);
      expect(moved!.parentSyncId, b.syncId);
      expect(ComicFolderService.folderPath(moved), '/b/a');
    });

    test('batchMoveFolders prevents moving into self', () {
      final a = ComicFolderService.createFolder(
        '',
        'a',
        ComicFolderType.favorite,
      );
      final aPath = ComicFolderService.folderPath(a);
      expect(
        () => ComicFolderService.batchMoveFolders(
          {aPath},
          aPath,
          ComicFolderType.favorite,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('batchMoveFolders prevents moving into descendant', () {
      final a = ComicFolderService.createFolder(
        '',
        'a',
        ComicFolderType.favorite,
      );
      final aPath = ComicFolderService.folderPath(a);
      final child = ComicFolderService.createFolder(
        aPath,
        'child',
        ComicFolderType.favorite,
      );
      final childPath = ComicFolderService.folderPath(child);
      expect(
        () => ComicFolderService.batchMoveFolders(
          {aPath},
          childPath,
          ComicFolderType.favorite,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('batchCopyFolders copies folder recursively with links', () {
      final favorite = createTestFavorite('test:comic1');
      objectbox.unifiedFavoriteBox.put(favorite);

      final src = ComicFolderService.createFolder(
        '',
        'src',
        ComicFolderType.favorite,
      );
      final srcPath = ComicFolderService.folderPath(src);
      ComicFolderService.createFolder(
        srcPath,
        'child',
        ComicFolderType.favorite,
      );
      ComicLinkService.addComic(
        'test:comic1',
        srcPath,
        ComicFolderType.favorite,
      );

      ComicFolderService.batchCopyFolders(
        {srcPath},
        '',
        ComicFolderType.favorite,
      );

      final rootFolders = ComicFolderService.listChildFolders(
        '',
        ComicFolderType.favorite,
      );
      expect(rootFolders.length, 2);

      final copied = rootFolders.firstWhere((f) => f.syncId != src.syncId);
      final copiedPath = ComicFolderService.folderPath(copied);
      final copiedLinks = ComicLinkService.listLinks(
        copiedPath,
        ComicFolderType.favorite,
      );
      expect(copiedLinks.length, 1);
      expect(copiedLinks.first.comicUniqueKey, 'test:comic1');
    });
  });

  group('ComicLinkService', () {
    test('addComic creates link at root', () {
      final link = ComicLinkService.addComic(
        'test:comic1',
        null,
        ComicFolderType.favorite,
      );
      expect(link.folderSyncId, isNull);
      expect(link.comicUniqueKey, 'test:comic1');
      expect(link.deletedAt, isNull);
    });

    test('addComic creates link in folder', () {
      final folder = ComicFolderService.createFolder(
        '',
        'f',
        ComicFolderType.favorite,
      );
      final path = ComicFolderService.folderPath(folder);
      final link = ComicLinkService.addComic(
        'test:comic1',
        path,
        ComicFolderType.favorite,
      );
      expect(link.folderSyncId, folder.syncId);
    });

    test('addComic resurrects tombstone', () {
      final folder = ComicFolderService.createFolder(
        '',
        'f',
        ComicFolderType.favorite,
      );
      final path = ComicFolderService.folderPath(folder);
      final link = ComicLinkService.addComic(
        'test:comic1',
        path,
        ComicFolderType.favorite,
      );
      ComicLinkService.removeComic(
        'test:comic1',
        path,
        ComicFolderType.favorite,
      );

      final resurrected = ComicLinkService.addComic(
        'test:comic1',
        path,
        ComicFolderType.favorite,
      );
      expect(resurrected.id, link.id);
      expect(resurrected.deletedAt, isNull);
    });

    test('removeComic soft deletes favorite link', () {
      final link = ComicLinkService.addComic(
        'test:comic1',
        null,
        ComicFolderType.favorite,
      );
      ComicLinkService.removeComic(
        'test:comic1',
        null,
        ComicFolderType.favorite,
      );

      final stored = objectbox.comicLinkBox.get(link.id);
      expect(stored!.deletedAt, isNotNull);
    });

    test('removeComic marks favorite deleted when last link', () {
      final favorite = createTestFavorite('test:comic1');
      objectbox.unifiedFavoriteBox.put(favorite);
      ComicLinkService.addComic('test:comic1', null, ComicFolderType.favorite);

      ComicLinkService.removeComic(
        'test:comic1',
        null,
        ComicFolderType.favorite,
      );

      final stored = objectbox.unifiedFavoriteBox.get(favorite.id);
      expect(stored!.deleted, isTrue);
    });

    test(
      'removeComic does not mark favorite deleted when other links exist',
      () {
        final favorite = createTestFavorite('test:comic1');
        objectbox.unifiedFavoriteBox.put(favorite);
        final f1 = ComicFolderService.createFolder(
          '',
          'f1',
          ComicFolderType.favorite,
        );
        final f2 = ComicFolderService.createFolder(
          '',
          'f2',
          ComicFolderType.favorite,
        );
        ComicLinkService.addComic(
          'test:comic1',
          ComicFolderService.folderPath(f1),
          ComicFolderType.favorite,
        );
        ComicLinkService.addComic(
          'test:comic1',
          ComicFolderService.folderPath(f2),
          ComicFolderType.favorite,
        );

        ComicLinkService.removeComic(
          'test:comic1',
          ComicFolderService.folderPath(f1),
          ComicFolderType.favorite,
        );

        final stored = objectbox.unifiedFavoriteBox.get(favorite.id);
        expect(stored!.deleted, isFalse);
      },
    );

    test('removeComic physical deletes download link', () {
      ComicLinkService.addComic('test:comic1', null, ComicFolderType.download);
      ComicLinkService.removeComic(
        'test:comic1',
        null,
        ComicFolderType.download,
      );

      final remaining = objectbox.comicLinkBox.getAll();
      expect(remaining, isEmpty);
    });

    test('removeComic deletes download files when last link', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'breeze_download_test_',
      );
      final download = createTestDownload(
        'test:comic1',
        storageRoot: tempDir.path,
      );
      objectbox.unifiedDownloadBox.put(download);
      ComicLinkService.addComic('test:comic1', null, ComicFolderType.download);

      ComicLinkService.removeComic(
        'test:comic1',
        null,
        ComicFolderType.download,
      );

      expect(objectbox.unifiedDownloadBox.get(download.id), isNull);
      expect(await tempDir.exists(), isFalse);
    });

    test('moveComic moves link without marking favorite deleted', () {
      final favorite = createTestFavorite('test:comic1');
      objectbox.unifiedFavoriteBox.put(favorite);
      final f1 = ComicFolderService.createFolder(
        '',
        'f1',
        ComicFolderType.favorite,
      );
      final f2 = ComicFolderService.createFolder(
        '',
        'f2',
        ComicFolderType.favorite,
      );
      ComicLinkService.addComic(
        'test:comic1',
        ComicFolderService.folderPath(f1),
        ComicFolderType.favorite,
      );

      ComicLinkService.moveComic(
        'test:comic1',
        ComicFolderService.folderPath(f1),
        ComicFolderService.folderPath(f2),
        ComicFolderType.favorite,
      );

      final links = ComicLinkService.listLinks(
        ComicFolderService.folderPath(f2),
        ComicFolderType.favorite,
      );
      expect(links.length, 1);
      expect(objectbox.unifiedFavoriteBox.get(favorite.id)!.deleted, isFalse);
    });

    test('removeComicFromAll removes all links', () {
      final f1 = ComicFolderService.createFolder(
        '',
        'f1',
        ComicFolderType.favorite,
      );
      final f2 = ComicFolderService.createFolder(
        '',
        'f2',
        ComicFolderType.favorite,
      );
      ComicLinkService.addComic(
        'test:comic1',
        ComicFolderService.folderPath(f1),
        ComicFolderType.favorite,
      );
      ComicLinkService.addComic(
        'test:comic1',
        ComicFolderService.folderPath(f2),
        ComicFolderType.favorite,
      );

      ComicLinkService.removeComicFromAll(
        'test:comic1',
        ComicFolderType.favorite,
      );

      expect(
        ComicLinkService.linksOfComic('test:comic1', ComicFolderType.favorite),
        isEmpty,
      );
    });

    test('removeLinksInFolderTree removes links in subtree', () {
      final parent = ComicFolderService.createFolder(
        '',
        'parent',
        ComicFolderType.favorite,
      );
      final parentPath = ComicFolderService.folderPath(parent);
      final child = ComicFolderService.createFolder(
        parentPath,
        'child',
        ComicFolderType.favorite,
      );
      final childPath = ComicFolderService.folderPath(child);
      ComicLinkService.addComic(
        'test:comic1',
        childPath,
        ComicFolderType.favorite,
      );

      ComicLinkService.removeLinksInFolderTree(
        parentPath,
        ComicFolderType.favorite,
      );

      expect(
        ComicLinkService.linksOfComic('test:comic1', ComicFolderType.favorite),
        isEmpty,
      );
    });
  });

  group('folder deletion link cleanup', () {
    test('deleting a folder removes links inside it and unfavorites comic', () {
      final favorite = createTestFavorite('test:comic1');
      objectbox.unifiedFavoriteBox.put(favorite);
      final folder = ComicFolderService.createFolder(
        '',
        'folder',
        ComicFolderType.favorite,
      );
      final path = ComicFolderService.folderPath(folder);
      ComicLinkService.addComic('test:comic1', path, ComicFolderType.favorite);

      // This mimics what FolderShelfBloc does on folder delete.
      ComicFolderService.deleteFolder(path, ComicFolderType.favorite);
      ComicLinkService.removeLinksInFolderTree(path, ComicFolderType.favorite);

      expect(
        ComicLinkService.linksOfComic('test:comic1', ComicFolderType.favorite),
        isEmpty,
      );
      expect(objectbox.unifiedFavoriteBox.get(favorite.id)!.deleted, isTrue);
    });

    test(
      'deleting a parent folder removes links in nested folders and unfavorites comic',
      () {
        final favorite = createTestFavorite('test:comic1');
        objectbox.unifiedFavoriteBox.put(favorite);
        final parent = ComicFolderService.createFolder(
          '',
          'parent',
          ComicFolderType.favorite,
        );
        final parentPath = ComicFolderService.folderPath(parent);
        final child = ComicFolderService.createFolder(
          parentPath,
          'child',
          ComicFolderType.favorite,
        );
        final childPath = ComicFolderService.folderPath(child);
        ComicLinkService.addComic(
          'test:comic1',
          childPath,
          ComicFolderType.favorite,
        );

        ComicFolderService.deleteFolder(parentPath, ComicFolderType.favorite);
        ComicLinkService.removeLinksInFolderTree(
          parentPath,
          ComicFolderType.favorite,
        );

        expect(
          ComicLinkService.linksOfComic(
            'test:comic1',
            ComicFolderType.favorite,
          ),
          isEmpty,
        );
        expect(objectbox.unifiedFavoriteBox.get(favorite.id)!.deleted, isTrue);
      },
    );
  });

  group('ComicFolderService edge cases', () {
    test('folderPath handles self-referencing cycle gracefully', () {
      final folder = ComicFolderService.createFolder(
        '',
        'loop',
        ComicFolderType.favorite,
      );
      // Manufacture a self-reference cycle.
      folder.parentSyncId = folder.syncId;
      objectbox.comicFolderBox.put(folder);

      // Should not infinite loop; returns partial path.
      final path = ComicFolderService.folderPath(folder);
      expect(path, startsWith('/loop'));
    });

    test('folderPath handles mutual cycle gracefully', () {
      final a = ComicFolderService.createFolder(
        '',
        'a',
        ComicFolderType.favorite,
      );
      final b = ComicFolderService.createFolder(
        '',
        'b',
        ComicFolderType.favorite,
      );
      a.parentSyncId = b.syncId;
      b.parentSyncId = a.syncId;
      objectbox.comicFolderBox.putMany([a, b]);

      // Should not infinite loop.
      final pathA = ComicFolderService.folderPath(a);
      final pathB = ComicFolderService.folderPath(b);
      expect(pathA, isNotEmpty);
      expect(pathB, isNotEmpty);
    });

    test('deleteFolder handles deeply nested tree', () {
      const depth = 100;
      final root = ComicFolderService.createFolder(
        '',
        'root',
        ComicFolderType.favorite,
      );
      var path = ComicFolderService.folderPath(root);
      for (var i = 1; i < depth; i++) {
        final current = ComicFolderService.createFolder(
          path,
          'level$i',
          ComicFolderType.favorite,
        );
        path = ComicFolderService.folderPath(current);
      }

      ComicFolderService.deleteFolder(
        ComicFolderService.folderPath(root),
        ComicFolderType.favorite,
      );

      final all = objectbox.comicFolderBox.getAll();
      expect(all.length, depth);
      expect(all.every((f) => f.deletedAt != null), isTrue);
    });

    test('batchMoveFolders ignores child when parent is also moved', () {
      final parent = ComicFolderService.createFolder(
        '',
        'parent',
        ComicFolderType.favorite,
      );
      final parentPath = ComicFolderService.folderPath(parent);
      final child = ComicFolderService.createFolder(
        parentPath,
        'child',
        ComicFolderType.favorite,
      );
      final childPath = ComicFolderService.folderPath(child);
      final target = ComicFolderService.createFolder(
        '',
        'target',
        ComicFolderType.favorite,
      );
      final targetPath = ComicFolderService.folderPath(target);

      // Move both parent and child to target. Child is already moving with parent.
      ComicFolderService.batchMoveFolders(
        {parentPath, childPath},
        targetPath,
        ComicFolderType.favorite,
      );

      final storedParent = objectbox.comicFolderBox.get(parent.id);
      final storedChild = objectbox.comicFolderBox.get(child.id);
      expect(storedParent!.parentSyncId, target.syncId);
      expect(storedChild!.parentSyncId, parent.syncId);
      expect(
        ComicFolderService.folderPath(storedChild),
        '/target/parent/child',
      );
    });

    test('batchDeleteFolders deletes parent and all descendants', () {
      final parent = ComicFolderService.createFolder(
        '',
        'parent',
        ComicFolderType.favorite,
      );
      final parentPath = ComicFolderService.folderPath(parent);
      final child = ComicFolderService.createFolder(
        parentPath,
        'child',
        ComicFolderType.favorite,
      );
      final childPath = ComicFolderService.folderPath(child);

      ComicFolderService.batchDeleteFolders({
        parentPath,
        childPath,
      }, ComicFolderType.favorite);

      expect(objectbox.comicFolderBox.get(parent.id)!.deletedAt, isNotNull);
      expect(objectbox.comicFolderBox.get(child.id)!.deletedAt, isNotNull);
    });

    test('createFolder under deleted parent falls back to root semantics', () {
      final parent = ComicFolderService.createFolder(
        '',
        'parent',
        ComicFolderType.favorite,
      );
      final parentPath = ComicFolderService.folderPath(parent);
      ComicFolderService.deleteFolder(parentPath, ComicFolderType.favorite);

      // Attempting to create under the deleted parent path cannot find active parent,
      // so it ends up creating at root level with a different uniqueKey.
      final created = ComicFolderService.createFolder(
        parentPath,
        'child',
        ComicFolderType.favorite,
      );
      expect(created.parentSyncId, isNull);
      expect(ComicFolderService.folderPath(created), '/child');
    });
  });

  group('ComicLinkService edge cases', () {
    test('addComic to deleted folder falls back to root', () {
      final folder = ComicFolderService.createFolder(
        '',
        'f',
        ComicFolderType.favorite,
      );
      final path = ComicFolderService.folderPath(folder);
      ComicFolderService.deleteFolder(path, ComicFolderType.favorite);

      final link = ComicLinkService.addComic(
        'test:comic1',
        path,
        ComicFolderType.favorite,
      );
      expect(link.folderSyncId, isNull);
    });

    test('removeComic from deleted folder removes root-level link', () {
      final folder = ComicFolderService.createFolder(
        '',
        'f',
        ComicFolderType.favorite,
      );
      final path = ComicFolderService.folderPath(folder);
      ComicLinkService.addComic('test:comic1', path, ComicFolderType.favorite);
      ComicFolderService.deleteFolder(path, ComicFolderType.favorite);

      // Removing by the deleted path should operate on root-level fallback link.
      ComicLinkService.removeComic(
        'test:comic1',
        path,
        ComicFolderType.favorite,
      );

      expect(
        ComicLinkService.linksOfComic('test:comic1', ComicFolderType.favorite),
        isEmpty,
      );
    });

    test('moveComic to same folder is no-op', () {
      final folder = ComicFolderService.createFolder(
        '',
        'f',
        ComicFolderType.favorite,
      );
      final path = ComicFolderService.folderPath(folder);
      final link = ComicLinkService.addComic(
        'test:comic1',
        path,
        ComicFolderType.favorite,
      );

      ComicLinkService.moveComic(
        'test:comic1',
        path,
        path,
        ComicFolderType.favorite,
      );

      expect(
        ComicLinkService.listLinks(path, ComicFolderType.favorite).length,
        1,
      );
      expect(
        ComicLinkService.listLinks(path, ComicFolderType.favorite).single.id,
        link.id,
      );
    });

    test('batchMoveComics with empty set does nothing', () {
      final folder = ComicFolderService.createFolder(
        '',
        'f',
        ComicFolderType.favorite,
      );
      ComicLinkService.batchMoveComics(
        {},
        ComicFolderService.folderPath(folder),
        '',
        ComicFolderType.favorite,
      );
      expect(true, isTrue);
    });

    test('removeComicFromAll with no links does not throw', () {
      ComicLinkService.removeComicFromAll(
        'nonexistent:comic',
        ComicFolderType.favorite,
      );
      expect(true, isTrue);
    });

    test('links are isolated across folder types', () {
      final folderFav = ComicFolderService.createFolder(
        '',
        'fav',
        ComicFolderType.favorite,
      );
      final folderHist = ComicFolderService.createFolder(
        '',
        'hist',
        ComicFolderType.history,
      );
      ComicLinkService.addComic(
        'test:comic1',
        ComicFolderService.folderPath(folderFav),
        ComicFolderType.favorite,
      );
      ComicLinkService.addComic(
        'test:comic1',
        ComicFolderService.folderPath(folderHist),
        ComicFolderType.history,
      );

      expect(
        ComicLinkService.listLinks(
          ComicFolderService.folderPath(folderFav),
          ComicFolderType.favorite,
        ).length,
        1,
      );
      expect(
        ComicLinkService.listLinks(
          ComicFolderService.folderPath(folderHist),
          ComicFolderType.history,
        ).length,
        1,
      );
    });
  });

  group('download folder edge cases', () {
    test('delete download folder removes nested files', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'breeze_download_nested_',
      );
      final nestedDir = Directory('${tempDir.path}/chapters');
      await nestedDir.create();
      await File('${nestedDir.path}/01.jpg').writeAsString('fake');

      final download = createTestDownload(
        'test:comic1',
        storageRoot: tempDir.path,
      );
      objectbox.unifiedDownloadBox.put(download);

      final folder = ComicFolderService.createFolder(
        '',
        'downloads',
        ComicFolderType.download,
      );
      final path = ComicFolderService.folderPath(folder);
      ComicLinkService.addComic('test:comic1', path, ComicFolderType.download);

      ComicFolderService.deleteFolder(path, ComicFolderType.download);
      ComicLinkService.removeLinksInFolderTree(path, ComicFolderType.download);

      expect(await tempDir.exists(), isFalse);
      expect(objectbox.unifiedDownloadBox.get(download.id), isNull);
    });
  });
}
