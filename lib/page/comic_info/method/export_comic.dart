import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/src/rust/compressed/compressed.dart';

import '../../../main.dart';
import '../../../network/http/picture/picture.dart';
import '../../../widgets/toast.dart';
import '../../download/json/comic_all_info_json/comic_all_info_json.dart';

/// 导出漫画为文件夹
Future<void> exportComicAsFolder(ComicAllInfoJson comicInfo) async {
  var processedComicInfo = comicInfoProcess(comicInfo);
  var downloadPath = await createDownloadDir();
  var comicDir = '$downloadPath/${processedComicInfo.comic.title}';

  if (!await Directory(comicDir).exists()) {
    await Directory(comicDir).create(recursive: true);
  } else {
    // 如果存在，则先删除
    await Directory(comicDir).delete(recursive: true);
    await Directory(comicDir).create(recursive: true);
  }

  // 保存漫画下载信息
  var comicInfoString = comicAllInfoJsonToJson(comicInfo);
  var comicInfoFile = File('$comicDir/original_comic_info.json');
  if (!await comicInfoFile.exists()) {
    await comicInfoFile.create(recursive: true);
  }
  await comicInfoFile.writeAsString(comicInfoString);

  var processedComicInfoString = comicAllInfoJsonToJson(processedComicInfo);
  var processedComicInfoFile = File('$comicDir/processed_comic_info.json');
  if (!await processedComicInfoFile.exists()) {
    await processedComicInfoFile.create(recursive: true);
  }
  await processedComicInfoFile.writeAsString(processedComicInfoString);

  if (processedComicInfo.comic.thumb.path.isNotEmpty) {
    var coverDir = '$comicDir/cover';
    var coverFile = File('$coverDir/cover.jpg');
    if (!await coverFile.exists()) {
      await coverFile.create(recursive: true);
    }
    var coverDownloadFile = await downloadPicture(
      from: 'bika',
      url: processedComicInfo.comic.thumb.fileServer,
      path: processedComicInfo.comic.thumb.path,
      cartoonId: processedComicInfo.comic.id,
      pictureType: 'cover',
      chapterId: processedComicInfo.comic.id,
    );
    await File(coverDownloadFile).copy(coverFile.path);
  }

  for (var ep in processedComicInfo.eps.docs) {
    var epDir = '$comicDir/eps/${ep.title}';
    for (var page in ep.pages.docs) {
      var pageFile = '$epDir/${page.media.originalName}';
      try {
        var pageDownloadFile = await downloadPicture(
          from: 'bika',
          url: page.media.fileServer,
          path: page.media.path,
          cartoonId: comicInfo.comic.id,
          pictureType: 'comic',
          chapterId: ep.id,
        );
        if (!await File(pageFile).exists()) {
          await File(pageFile).create(recursive: true);
        }
        await File(pageDownloadFile).copy(pageFile);
      } catch (e) {
        logger.e('Error downloading ${page.media.fileServer}: $e');
      }
    }
  }

  logger.d('漫画${comicInfo.comic.title}导出为文件夹完成');
  showSuccessToast('漫画${comicInfo.comic.title}导出为文件夹完成');
}

Future<void> exportComicAsZip(ComicAllInfoJson comicInfo) async {
  final startTime = DateTime.now().millisecondsSinceEpoch;
  final processedComicInfo = comicInfoProcess(comicInfo);
  final downloadPath =
      '${await createDownloadDir()}/${processedComicInfo.comic.title}';

  final finalZipPath = '$downloadPath.tar';

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
  if (processedComicInfo.comic.thumb.path.isNotEmpty) {
    var coverFile = 'cover/cover.jpg';
    var coverDownloadFile = await downloadPicture(
      from: 'bika',
      url: processedComicInfo.comic.thumb.fileServer,
      path: processedComicInfo.comic.thumb.path,
      cartoonId: processedComicInfo.comic.id,
      pictureType: 'cover',
      chapterId: processedComicInfo.comic.id,
    );
    packInfo.originalImagePaths.add(coverDownloadFile);
    packInfo.packImagePaths.add(coverFile);
  }

  // 下载漫画章节
  for (var ep in processedComicInfo.eps.docs) {
    var epDir = 'eps/${ep.title}';
    for (var page in ep.pages.docs) {
      var pageFile = '$epDir/${page.media.originalName}';
      try {
        var pageDownloadFile = await downloadPicture(
          from: 'bika',
          url: page.media.fileServer,
          path: page.media.path,
          cartoonId: comicInfo.comic.id,
          pictureType: 'comic',
          chapterId: ep.id,
        );
        packInfo.originalImagePaths.add(pageDownloadFile);
        packInfo.packImagePaths.add(pageFile);
      } catch (e) {
        logger.e('Error downloading ${page.media.fileServer}: $e');
      }
    }
  }

  // 压缩文件夹
  await packFolder(destPath: finalZipPath, packInfo: packInfo);

  final endTime = DateTime.now().millisecondsSinceEpoch;
  final duration = endTime - startTime;
  logger.d('漫画${comicInfo.comic.title}导出为压缩包完成，耗时$duration毫秒');

  showSuccessToast('漫画${comicInfo.comic.title}导出为压缩包完成');
}

/// 创建下载目录
Future<String> createDownloadDir() async {
  try {
    // 获取外部存储目录
    Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      logger.d('downloadPath: ${externalDir.path}');
    }

    RegExp regExp = RegExp(r'/(\d+)/');
    Match? match = regExp.firstMatch(externalDir!.path);
    String userId = match!.group(1)!; // 提取到的用户ID

    String filePath = "/storage/emulated/$userId/Download/$appName";

    // 使用path库来确保路径的正确性
    final dir = Directory(filePath);

    // 检查目录是否存在
    bool dirExists = await dir.exists();
    if (!dirExists) {
      // 如果目录不存在，则创建它
      try {
        await dir.create(recursive: true); // recursive设置为true可以创建所有必要的父目录
        logger.d('Directory created: $filePath');
      } catch (e) {
        logger.e('Failed to create directory: $e');
        rethrow;
      }
    }

    return filePath;
  } catch (e) {
    logger.e(e);
    rethrow;
  }
}

ComicAllInfoJson comicInfoProcess(ComicAllInfoJson comicInfo) {
  // 修改 comic 的 title
  final updatedComic = comicInfo.comic.copyWith(
    title: comicInfo.comic.title.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_'),
  );

  // 修改 eps 的 docs
  final updatedEpsDocs =
      comicInfo.eps.docs.map((ep) {
        // 修改 epsDoc 的 title
        final updatedEp = ep.copyWith(
          title:
              "${ep.order}.${ep.title.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_')}",
        );

        // 修改 pages 的 docs
        final updatedPagesDocs =
            updatedEp.pages.docs.map((page) {
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
