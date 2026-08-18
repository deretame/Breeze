import 'package:zephyr/database/database.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/service/comic_link_service.dart';

/// v5 -> v6: 为所有未删除的本地收藏/下载漫画补一条根目录 ComicLink。
///
/// 旧版本中收藏/下载漫画直接存在 UnifiedComicFavorite / UnifiedComicDownload 里，
/// 没有独立的文件夹/链接关系。v6 引入 ComicFolder + ComicLink 后，需要把已有数据
/// 先挂到根目录，保证新的书架文件夹视图能正常显示。
Future<void> migrateV5ToV6() async {
  var migrated = 0;
  var skipped = 0;

  // 收藏
  final favoriteQuery = database.unifiedFavorites
      .query((item) => !item.deleted)
      .build();
  try {
    final favorites = favoriteQuery.find();
    for (final comic in favorites) {
      final existing = database.comicLinks
          .query(
            (item) =>
                item.comicUniqueKey == comic.uniqueKey &&
                item.typeData == ComicFolderType.favorite.name,
          )
          .build()
          .findFirst();
      if (existing != null) {
        skipped++;
        continue;
      }
      ComicLinkService.addComic(
        comic.uniqueKey,
        null,
        ComicFolderType.favorite,
      );
      migrated++;
    }
  } finally {
    favoriteQuery.close();
  }

  // 下载
  final downloadQuery = database.unifiedDownloads
      .query((item) => !item.deleted)
      .build();
  try {
    final downloads = downloadQuery.find();
    for (final comic in downloads) {
      final existing = database.comicLinks
          .query(
            (item) =>
                item.comicUniqueKey == comic.uniqueKey &&
                item.typeData == ComicFolderType.download.name,
          )
          .build()
          .findFirst();
      if (existing != null) {
        skipped++;
        continue;
      }
      ComicLinkService.addComic(
        comic.uniqueKey,
        null,
        ComicFolderType.download,
      );
      migrated++;
    }
  } finally {
    downloadQuery.close();
  }

  logger.d('[migration_v5_to_v6] migrated=$migrated, skipped=$skipped');
}
