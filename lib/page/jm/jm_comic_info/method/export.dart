import 'dart:convert';
import 'dart:io';
import 'dart:math' show min;

import 'package:path_provider/path_provider.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/jm/download/json/download_info_json.dart';
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
    var coverDownloadFile = await downloadPicture(
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
      try {
        var pageDownloadFile = await downloadPicture(
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
  final updatedSeries =
      comicInfo.series.map((ep) {
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
