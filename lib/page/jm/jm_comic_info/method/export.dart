import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

import 'package:path_provider/path_provider.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/jm/jm_download/json/download_info_json.dart';
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/src/rust/compressed/compressed.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/widgets/toast.dart';

/// 导出漫画为文件夹
Future<void> exportComicAsFolder(JmDownload jmDownload) async {
  final comicInfo = jmDownload.allInfo.let(downloadInfoJsonFromJson);
  final downloadedEpIds = jmDownload.epsIds;
  var processedComicInfo = comicInfoProcess(comicInfo);
  var downloadPath = await createDownloadDir();
  var comicDir = '$downloadPath/${processedComicInfo.name}';

  if (!await Directory(comicDir).exists()) {
    await Directory(comicDir).create(recursive: true);
  } else {
    // 如果存在，则先删除
    await Directory(comicDir).delete(recursive: true);
    await Directory(comicDir).create(recursive: true);
  }

  // 保存漫画下载信息
  var comicInfoString = downloadInfoJsonToJson(comicInfo);
  logger.d('$comicDir/processed_comic_info.json'.length);
  var comicInfoFile = File('$comicDir/original_comic_info.json');
  await comicInfoFile.writeAsString(comicInfoString);

  var temp = processedComicInfo.toJson();
  temp['epsIds'] = downloadedEpIds;
  var processedComicInfoString = temp.let(jsonEncode);
  var processedComicInfoFile = File('$comicDir/processed_comic_info.json');
  await processedComicInfoFile.writeAsString(processedComicInfoString);

  var coverDir = '$comicDir/cover';
  var coverFile = File('$coverDir/cover.jpg');
  await coverFile.create(recursive: true);
  try {
    String coverDownloadFile = await downloadPicture(
      from: 'jm',
      url: getJmCoverUrl(processedComicInfo.id.toString()),
      path: "${processedComicInfo.id}.jpg",
      cartoonId: processedComicInfo.id.toString(),
      pictureType: 'cover',
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
    var epDir = '$comicDir/eps/${ep.name}';
    for (var page in ep.info.images) {
      var pageFile = '$epDir/$page';
      if (page == "404") {
        continue;
      }
      try {
        String pageDownloadFile = await downloadPicture(
          from: 'jm',
          url: getJmImagesUrl(comicInfo.id.toString(), page),
          path: page,
          cartoonId: comicInfo.id.toString(),
          pictureType: 'comic',
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

Future<void> exportComicAsZip(JmDownload jmDownload) async {
  final comicInfo = jmDownload.allInfo.let(downloadInfoJsonFromJson);
  final downloadedEpIds = jmDownload.epsIds;
  var processedComicInfo = comicInfoProcess(comicInfo);

  final downloadPath =
      '${await createDownloadDir()}/${processedComicInfo.name.substring(0, min(processedComicInfo.name.length, 90))}';

  final finalZipPath = '$downloadPath.zip';

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
      from: 'jm',
      url: getJmCoverUrl(processedComicInfo.id.toString()),
      path: "${processedComicInfo.id}.jpg",
      cartoonId: processedComicInfo.id.toString(),
      pictureType: 'cover',
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
    var epDir = 'eps/${ep.name}';
    for (var page in ep.info.images) {
      var pageFile = '$epDir/$page';
      if (page == "404") {
        continue;
      }
      try {
        var pageDownloadFile = await downloadPicture(
          from: 'jm',
          url: getJmImagesUrl(comicInfo.id.toString(), page),
          path: page,
          cartoonId: comicInfo.id.toString(),
          pictureType: 'comic',
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

/// 创建下载目录
Future<String> createDownloadDir() async {
  try {
    // 获取外部存储目录
    Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      logger.d('downloadPath: ${externalDir.path}');
    }

    // 检查 externalDir 是否为 null
    if (externalDir == null) {
      throw Exception('无法获取外部存储目录');
    }

    // 尝试从路径中提取用户ID
    RegExp regExp = RegExp(r'/(\d+)/');
    Match? match = regExp.firstMatch(externalDir.path);

    // 安全地提取用户ID，如果匹配失败则使用默认值
    String userId = '0';
    if (match != null && match.groupCount >= 1) {
      final extractedUserId = match.group(1);
      if (extractedUserId != null) {
        userId = extractedUserId;
      } else {
        logger.w('无法提取用户ID，使用默认值: 0');
      }
    } else {
      logger.w('路径格式不匹配，使用默认用户ID: 0，路径: ${externalDir.path}');
    }

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
