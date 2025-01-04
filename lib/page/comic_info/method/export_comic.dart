import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path_provider/path_provider.dart';

import '../../../network/http/picture.dart';
import '../../download/json/comic_all_info_json/comic_all_info_json.dart';

Future<void> exportComic(ComicAllInfoJson comicInfo) async {
  var downloadPath = await createDownloadDir();
  var comicDir = '$downloadPath/${comicInfo.comic.title}';
  if (await Directory(comicDir).exists()) {
    await Directory(comicDir).create(recursive: true);
  }

  // 保存漫画下载信息
  var comicInfoString = comicAllInfoJsonToJson(comicInfo);
  var comicInfoFile = File('$comicDir/info.json');
  if (!await comicInfoFile.exists()) {
    await comicInfoFile.create(recursive: true);
  }
  await comicInfoFile.writeAsString(comicInfoString);

  var coverDir = '$comicDir/cover';
  var coverFile = File('$coverDir/cover.jpg');
  if (!await coverFile.exists()) {
    await coverFile.create(recursive: true);
  }
  var coverDownloadFile = await downloadPicture(
    from: 'bika',
    url: comicInfo.comic.thumb.fileServer,
    path: comicInfo.comic.thumb.path,
    cartoonId: comicInfo.comic.id,
    pictureType: 'cover',
    chapterId: comicInfo.comic.id,
  );
  await File(coverDownloadFile).copy(coverFile.path);

  final List<Future<void>> downloadTasks = [];
  for (var ep in comicInfo.eps.docs) {
    var epDir = '$comicDir/eps/${ep.title}';
    for (var page in ep.pages.docs) {
      var pageFile = '$epDir/${page.media.originalName}';
      downloadTask() async {
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
          debugPrint('Error downloading ${page.media.fileServer}: $e');
        }
      }

      downloadTasks.add(downloadTask());
    }
  }

  await Future.wait(downloadTasks);

  debugPrint('漫画${comicInfo.comic.title}导出完成');
  EasyLoading.showSuccess('漫画${comicInfo.comic.title}导出完成');
}

Future<String> createDownloadDir() async {
  try {
    // 获取外部存储目录
    Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      String downloadPath = externalDir.path;
      debugPrint('downloadPath: $downloadPath');
    }

    RegExp regExp = RegExp(r'/(\d+)/');
    Match? match = regExp.firstMatch(externalDir!.path);
    String userId = match!.group(1)!; // 提取到的用户ID

    String filePath = "/storage/emulated/$userId/Download/Breeze";

    // 使用path库来确保路径的正确性
    final dir = Directory(filePath);

    // 检查目录是否存在
    bool dirExists = await dir.exists();
    if (!dirExists) {
      // 如果目录不存在，则创建它
      try {
        await dir.create(recursive: true); // recursive设置为true可以创建所有必要的父目录
        debugPrint('Directory created: $filePath');
      } catch (e) {
        debugPrint('Failed to create directory: $e');
        rethrow;
      }
    } else {
      debugPrint('Directory already exists: $filePath');
    }

    return filePath;
  } catch (e) {
    debugPrint(e.toString());
    rethrow;
  }
}
