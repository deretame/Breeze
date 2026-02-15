import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/object_box/objectbox.g.dart';
import 'package:zephyr/page/jm/jm_download/json/download_info_json.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/src/rust/compressed/compressed.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/widgets/toast.dart';

/// 导出漫画为文件夹
Future<void> jmExportComicAsFolder(String comicId, {String? exportPath}) async {
  final jmDownload = objectbox.jmDownloadBox
      .query(JmDownload_.comicId.equals(comicId))
      .build()
      .findFirst()!;
  final comicInfo = jmDownload.allInfo.let(downloadInfoJsonFromJson);
  final downloadedEpIds = jmDownload.epsIds;
  var processedComicInfo = comicInfoProcess(comicInfo);
  var downloadPath = exportPath ?? await createDownloadDir();
  var comicDir = p.join(downloadPath, processedComicInfo.name);

  if (!await Directory(comicDir).exists()) {
    await Directory(comicDir).create(recursive: true);
  } else {
    // 如果存在，则先删除
    await Directory(comicDir).delete(recursive: true);
    await Directory(comicDir).create(recursive: true);
  }

  // 保存漫画下载信息
  var comicInfoString = downloadInfoJsonToJson(comicInfo);
  logger.d(p.join(comicDir, 'processed_comic_info.json').length);
  var comicInfoFile = File(p.join(comicDir, 'original_comic_info.json'));
  await comicInfoFile.writeAsString(comicInfoString);

  var temp = processedComicInfo.toJson();
  temp['epsIds'] = downloadedEpIds;
  var processedComicInfoString = temp.let(jsonEncode);
  var processedComicInfoFile = File(
    p.join(comicDir, 'processed_comic_info.json'),
  );
  await processedComicInfoFile.writeAsString(processedComicInfoString);

  var coverDir = p.join(comicDir, 'cover');
  var coverFile = File(p.join(coverDir, 'cover.jpg'));
  await coverFile.create(recursive: true);
  try {
    String coverDownloadFile = await downloadPicture(
      from: From.jm,
      url: getJmCoverUrl(processedComicInfo.id.toString()),
      path: "${processedComicInfo.id}.jpg",
      cartoonId: processedComicInfo.id.toString(),
      pictureType: PictureType.cover,
      chapterId: processedComicInfo.id.toString(),
    );
    await File(coverDownloadFile).copy(coverFile.path);
  } catch (e) {
    logger.e('Error downloading cover: $e');
  }

  final series = processedComicInfo.series.where(
    (ep) => downloadedEpIds.contains(ep.id),
  );

  for (var ep in series) {
    var epDir = p.join(comicDir, 'eps', ep.name);
    for (var page in ep.info.images) {
      var pageFile = p.join(epDir, page);
      if (page == "404") {
        continue;
      }
      try {
        String pageDownloadFile = await downloadPicture(
          from: From.jm,
          url: getJmImagesUrl(comicInfo.id.toString(), page),
          path: page,
          cartoonId: comicInfo.id.toString(),
          pictureType: PictureType.comic,
          chapterId: ep.id,
        );
        if (!await File(pageFile).exists()) {
          await File(pageFile).create(recursive: true);
        }
        await File(pageDownloadFile).copy(pageFile);
      } catch (e) {
        logger.e('Error downloading $page: $e');
      }
    }
  }

  logger.d('漫画${comicInfo.name}导出为文件夹完成');
  showSuccessToast('漫画${comicInfo.name}导出为文件夹完成');
}

Future<void> jmExportComicAsZip(String comicId, {String? exportPath}) async {
  final jmDownload = objectbox.jmDownloadBox
      .query(JmDownload_.comicId.equals(comicId))
      .build()
      .findFirst()!;
  final comicInfo = jmDownload.allInfo.let(downloadInfoJsonFromJson);
  final downloadedEpIds = jmDownload.epsIds;
  var processedComicInfo = comicInfoProcess(comicInfo);

  String finalZipPath;

  if (exportPath != null) {
    finalZipPath = exportPath;
  } else {
    final downloadPath = p.join(
      await createDownloadDir(),
      processedComicInfo.name.substring(
        0,
        min(processedComicInfo.name.length, 90),
      ),
    );
    finalZipPath = '$downloadPath.zip';
  }

  var processedComicInfoString = processedComicInfo.toJson();
  processedComicInfoString['epsIds'] = downloadedEpIds;

  final packInfo = PackInfo(
    comicInfoString: downloadInfoJsonToJson(comicInfo),
    processedComicInfoString: processedComicInfoString.let(jsonEncode),
    originalImagePaths: [],
    packImagePaths: [],
  );

  // 下载封面
  if (processedComicInfo.name.isNotEmpty) {
    var coverFile = 'cover/cover.jpg';
    var coverDownloadFile = await downloadPicture(
      from: From.jm,
      url: getJmCoverUrl(processedComicInfo.id.toString()),
      path: "${processedComicInfo.id}.jpg",
      cartoonId: processedComicInfo.id.toString(),
      pictureType: PictureType.cover,
      chapterId: processedComicInfo.id.toString(),
    );
    packInfo.originalImagePaths.add(coverDownloadFile);
    packInfo.packImagePaths.add(coverFile);
  }

  // 下载漫画章节
  for (var ep in processedComicInfo.series) {
    if (!downloadedEpIds.contains(ep.id)) {
      continue;
    }
    var epDir = p.join('eps', ep.name);
    for (var page in ep.info.images) {
      var pageFile = p.join(epDir, page);
      if (page == "404") {
        continue;
      }
      try {
        var pageDownloadFile = await downloadPicture(
          from: From.jm,
          url: getJmImagesUrl(comicInfo.id.toString(), page),
          path: page,
          cartoonId: comicInfo.id.toString(),
          pictureType: PictureType.comic,
          chapterId: ep.id,
        );

        if (pageDownloadFile == "404") {
          logger.w("跳过 404 页面: $page");
          continue;
        }

        packInfo.originalImagePaths.add(pageDownloadFile);
        packInfo.packImagePaths.add(pageFile);
      } catch (e, s) {
        logger.e('Error downloading $page: $e', stackTrace: s);
      }
    }
  }

  // 压缩文件夹
  await packFolderZip(destPath: finalZipPath, packInfo: packInfo);

  showSuccessToast('漫画${comicInfo.name}导出为压缩包完成');
  logger.d('漫画${comicInfo.name}导出为压缩包完成');
}

DownloadInfoJson comicInfoProcess(DownloadInfoJson comicInfo) {
  // 修改 comic 的 title
  String originalComicName =
      'jm_${comicInfo.name.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_')}';
  final updatedComic = originalComicName.substring(
    0,
    min(originalComicName.length, 90),
  );

  int i = 1;
  // 修改 eps 的 docs
  final updatedSeries = comicInfo.series.map((ep) {
    // 修改 epsDoc 的 title
    String originalEpName =
        "$i.${ep.info.name.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_')}";
    final updatedEp = ep.copyWith(
      name: originalEpName.substring(0, min(originalEpName.length, 90)),
    );

    i++;

    // 更新 epsDoc 的 pages
    return updatedEp;
  }).toList();

  // 返回更新后的 ComicAllInfoJson
  return comicInfo.copyWith(name: updatedComic, series: updatedSeries);
}
