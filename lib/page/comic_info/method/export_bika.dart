import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/bookshelf/json/download/comic_all_info_json.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/src/rust/compressed/compressed.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/widgets/toast.dart';

/// 导出漫画为文件夹
Future<void> bikaExportComicAsFolder(String comicId) async {
  var comicDownload = objectbox.bikaDownloadBox
      .query(BikaComicDownload_.comicId.equals(comicId))
      .build()
      .findFirst();

  var comicInfo = comicAllInfoJsonFromJson(comicDownload!.comicInfoAll);

  var processedComicInfo = comicInfoProcess(comicInfo);
  var downloadPath = await createDownloadDir();
  var comicDir = p.join(downloadPath, processedComicInfo.comic.title);

  if (!await Directory(comicDir).exists()) {
    await Directory(comicDir).create(recursive: true);
  } else {
    // 如果存在，则先删除
    await Directory(comicDir).delete(recursive: true);
    await Directory(comicDir).create(recursive: true);
  }

  // 保存漫画下载信息
  var comicInfoString = comicAllInfoJsonToJson(comicInfo);
  var comicInfoFile = File(p.join(comicDir, 'original_comic_info.json'));
  if (!await comicInfoFile.exists()) {
    await comicInfoFile.create(recursive: true);
  }
  await comicInfoFile.writeAsString(comicInfoString);

  var processedComicInfoString = comicAllInfoJsonToJson(processedComicInfo);
  var processedComicInfoFile = File(
    p.join(comicDir, 'processed_comic_info.json'),
  );
  if (!await processedComicInfoFile.exists()) {
    await processedComicInfoFile.create(recursive: true);
  }
  await processedComicInfoFile.writeAsString(processedComicInfoString);

  if (processedComicInfo.comic.thumb.path.isNotEmpty &&
      processedComicInfo.comic.thumb.fileServer.isNotEmpty) {
    try {
      var coverDir = p.join(comicDir, 'cover');
      var coverFile = File(p.join(coverDir, 'cover.jpg'));
      if (!await coverFile.exists()) {
        await coverFile.create(recursive: true);
      }
      var coverDownloadFile = await downloadPicture(
        from: From.bika,
        url: processedComicInfo.comic.thumb.fileServer,
        path: processedComicInfo.comic.thumb.path,
        cartoonId: processedComicInfo.comic.id,
        pictureType: PictureType.cover,
        chapterId: processedComicInfo.comic.id,
      );
      await File(coverDownloadFile).copy(coverFile.path);
    } catch (e) {
      logger.e('Error downloading cover: $e');
    }
  }

  for (var ep in processedComicInfo.eps.docs) {
    var epDir = p.join(comicDir, 'eps', ep.title);
    for (var page in ep.pages.docs) {
      // 跳过空 URL 或路径
      if (page.media.fileServer.isEmpty || page.media.path.isEmpty) {
        logger.w('跳过空 URL 的图片: ${page.media.originalName}');
        continue;
      }

      var pageFile = p.join(epDir, page.media.originalName);
      try {
        var pageDownloadFile = await downloadPicture(
          from: From.bika,
          url: page.media.fileServer,
          path: page.media.path,
          cartoonId: comicInfo.comic.id,
          pictureType: PictureType.comic,
          chapterId: ep.id,
        );
        if (!await File(pageFile).exists()) {
          await File(pageFile).create(recursive: true);
        }
        await File(pageDownloadFile).copy(pageFile);
      } catch (e) {
        logger.e(
          'Error downloading ${page.media.fileServer}/${page.media.path}: $e',
        );
        // 继续处理下一张图片，不中断整个导出过程
      }
    }
  }

  logger.d('漫画${comicInfo.comic.title}导出为文件夹完成');
  showSuccessToast('漫画${comicInfo.comic.title}导出为文件夹完成');
}

Future<void> bikaExportComicAsZip(String comicId) async {
  var comicDownload = objectbox.bikaDownloadBox
      .query(BikaComicDownload_.comicId.equals(comicId))
      .build()
      .findFirst();

  var comicInfo = comicAllInfoJsonFromJson(comicDownload!.comicInfoAll);

  final startTime = DateTime.now().millisecondsSinceEpoch;
  final processedComicInfo = comicInfoProcess(comicInfo);
  final downloadPath = p.join(
    await createDownloadDir(),
    processedComicInfo.comic.title,
  );

  final finalZipPath = '$downloadPath.zip';

  if (!await File(finalZipPath).exists()) {
    await File(finalZipPath).create(recursive: true);
  } else {
    await File(finalZipPath).delete();
    await File(finalZipPath).create(recursive: true);
  }

  final packInfo = PackInfo(
    comicInfoString: comicAllInfoJsonToJson(comicInfo),
    processedComicInfoString: comicAllInfoJsonToJson(processedComicInfo),
    originalImagePaths: [],
    packImagePaths: [],
  );

  // 下载封面
  if (processedComicInfo.comic.thumb.path.isNotEmpty &&
      processedComicInfo.comic.thumb.fileServer.isNotEmpty) {
    try {
      var coverFile = 'cover/cover.jpg';
      var coverDownloadFile = await downloadPicture(
        from: From.bika,
        url: processedComicInfo.comic.thumb.fileServer,
        path: processedComicInfo.comic.thumb.path,
        cartoonId: processedComicInfo.comic.id,
        pictureType: PictureType.cover,
        chapterId: processedComicInfo.comic.id,
      );
      packInfo.originalImagePaths.add(coverDownloadFile);
      packInfo.packImagePaths.add(coverFile);
    } catch (e) {
      logger.e('Error downloading cover: $e');
    }
  }

  // 下载漫画章节
  for (var ep in processedComicInfo.eps.docs) {
    var epDir = p.join('eps', ep.title);
    for (var page in ep.pages.docs) {
      // 跳过空 URL 或路径
      if (page.media.fileServer.isEmpty || page.media.path.isEmpty) {
        logger.w('跳过空 URL 的图片: ${page.media.originalName}');
        continue;
      }

      var pageFile = p.join(epDir, page.media.originalName);
      try {
        var pageDownloadFile = await downloadPicture(
          from: From.bika,
          url: page.media.fileServer,
          path: page.media.path,
          cartoonId: comicInfo.comic.id,
          pictureType: PictureType.comic,
          chapterId: ep.id,
        );
        packInfo.originalImagePaths.add(pageDownloadFile);
        packInfo.packImagePaths.add(pageFile);
      } catch (e) {
        logger.e(
          'Error downloading ${page.media.fileServer}/${page.media.path}: $e',
        );
        // 继续处理下一张图片，不中断整个导出过程
      }
    }
  }

  // 压缩文件夹
  await packFolderZip(destPath: finalZipPath, packInfo: packInfo);

  final endTime = DateTime.now().millisecondsSinceEpoch;
  final duration = endTime - startTime;
  logger.d('漫画${comicInfo.comic.title}导出为压缩包完成，耗时$duration毫秒');

  showSuccessToast('漫画${comicInfo.comic.title}导出为压缩包完成');
}

ComicAllInfoJson comicInfoProcess(ComicAllInfoJson comicInfo) {
  // 修改 comic 的 title
  final updatedComic = comicInfo.comic.copyWith(
    title: comicInfo.comic.title.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_'),
  );

  // 修改 eps 的 docs
  final updatedEpsDocs = comicInfo.eps.docs.map((ep) {
    // 修改 epsDoc 的 title
    final updatedEp = ep.copyWith(
      title:
          "${ep.order}.${ep.title.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_')}",
    );

    // 修改 pages 的 docs
    final updatedPagesDocs = updatedEp.pages.docs.map((page) {
      // 修改 page 的 media
      final updatedMedia = page.media.copyWith(
        originalName: page.media.originalName.replaceAll(
          RegExp(r'[<>:"/\\|?* ]'),
          '_',
        ),
      );

      return page.copyWith(media: updatedMedia);
    }).toList();

    // 更新 epsDoc 的 pages
    return updatedEp.copyWith(pages: Pages(docs: updatedPagesDocs));
  }).toList();

  // 更新 eps 的 docs
  final updatedEps = comicInfo.eps.copyWith(docs: updatedEpsDocs);

  // 返回更新后的 ComicAllInfoJson
  return comicInfo.copyWith(comic: updatedComic, eps: updatedEps);
}
