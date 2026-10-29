import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/bookshelf/service/comic_folder_service.dart';
import 'package:zephyr/page/bookshelf/service/comic_link_service.dart';
import 'package:zephyr/page/comic_info/json/normal/normal_comic_all_info.dart';
import 'package:zephyr/page/comic_info/models/collect_comic.dart';

import '../test_helper.dart';

NormalComicAllInfo _fakeNormalInfo(String comicId) {
  return NormalComicAllInfo(
    comicInfo: ComicInfo(
      id: comicId,
      title: 'title-$comicId',
      titleMeta: const [],
      description: '',
      cover: const ComicImage(id: 'c', url: 'u', name: 'n'),
      metadata: const [],
    ),
    eps: const [],
    recommend: const [],
  );
}

void main() {
  setUpAll(TestObjectBoxHelper.setUpTestObjectBox);
  tearDownAll(TestObjectBoxHelper.tearDownTestObjectBox);
  tearDown(TestObjectBoxHelper.cleanComicFolderBoxes);

  group('setLocalComicFavoriteFolders', () {
    test('未收藏时长按建收藏并挂到所选文件夹，不只挂根目录', () async {
      const from = 'test';
      const comicId = 'c1';
      final folder = ComicFolderService.createFolder(
        '',
        'f',
        ComicFolderType.favorite,
      );
      final path = ComicFolderService.folderPath(folder);
      final normalInfo = _fakeNormalInfo(comicId);

      final result = await setLocalComicFavoriteFolders(
        from: from,
        normalInfo: normalInfo,
        targetPaths: {path},
      );

      expect(result, isTrue);
      expect(await isLocalComicCollected(from: from, comicId: comicId), isTrue);
      expect(
        localComicFavoriteFolderPaths(from: from, comicId: comicId),
        {path},
      );
    });

    test('已收藏时重设为不相交文件夹：先加后删，本体不被误删', () async {
      const from = 'test';
      const comicId = 'c2';
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
      final p1 = ComicFolderService.folderPath(f1);
      final p2 = ComicFolderService.folderPath(f2);
      final normalInfo = _fakeNormalInfo(comicId);

      await setLocalComicFavoriteFolders(
        from: from,
        normalInfo: normalInfo,
        targetPaths: {p1},
      );
      await setLocalComicFavoriteFolders(
        from: from,
        normalInfo: normalInfo,
        targetPaths: {p2},
      );

      // 本体仍在：中间态不能触发“最后一个链接删除→本体标记删除”。
      final stored = objectbox.unifiedFavoriteBox
          .query(UnifiedComicFavorite_.uniqueKey.equals('test:c2'))
          .build()
          .findFirst();
      expect(stored, isNotNull);
      expect(stored!.deleted, isFalse);
      expect(
        localComicFavoriteFolderPaths(from: from, comicId: comicId),
        {p2},
      );
      expect(
        ComicLinkService.linksOfComic(
          'test:c2',
          ComicFolderType.favorite,
        ).length,
        1,
      );
    });

    test('空集合不做任何改动', () async {
      const from = 'test';
      const comicId = 'c3';
      final folder = ComicFolderService.createFolder(
        '',
        'f',
        ComicFolderType.favorite,
      );
      final path = ComicFolderService.folderPath(folder);
      final normalInfo = _fakeNormalInfo(comicId);

      await setLocalComicFavoriteFolders(
        from: from,
        normalInfo: normalInfo,
        targetPaths: {path},
      );
      await setLocalComicFavoriteFolders(
        from: from,
        normalInfo: normalInfo,
        targetPaths: const {},
      );

      expect(await isLocalComicCollected(from: from, comicId: comicId), isTrue);
      expect(
        localComicFavoriteFolderPaths(from: from, comicId: comicId),
        {path},
      );
    });
  });

  group('autoCloudCollectOnLocalFavorite 开关', () {
    test('默认关闭', () {
      expect(const GlobalSettingState().autoCloudCollectOnLocalFavorite, isFalse);
    });

    test('旧版 JSON 缺字段回落 false，且往返保持', () {
      final restored = GlobalSettingState.fromJson(
        const GlobalSettingState().toJson()
          ..remove('autoCloudCollectOnLocalFavorite'),
      );
      expect(restored.autoCloudCollectOnLocalFavorite, isFalse);

      const enabled = GlobalSettingState(autoCloudCollectOnLocalFavorite: true);
      expect(
        GlobalSettingState.fromJson(enabled.toJson())
            .autoCloudCollectOnLocalFavorite,
        isTrue,
      );
    });
  });
}
