import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart'; // 引入 compute
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import '../../../network/http/picture.dart';
import '../../download/json/comic_all_info_json/comic_all_info_json.dart';

/// 导出漫画为文件夹
Future<void> exportComicAsFolder(ComicAllInfoJson comicInfo) async {
  var downloadPath = await createDownloadDir();
  var comicDir =
      '$downloadPath/${comicInfo.comic.title.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_')}';

  if (!await Directory(comicDir).exists()) {
    await Directory(comicDir).create(recursive: true);
  }

  // 保存漫画下载信息
  var comicInfoString = comicAllInfoJsonToJson(comicInfo);
  var comicInfoFile = File('$comicDir/info.json');
  if (!await comicInfoFile.exists()) {
    await comicInfoFile.create(recursive: true);
  }
  await comicInfoFile.writeAsString(comicInfoString);

  if (comicInfo.comic.thumb.path.isNotEmpty) {
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
  }

  final List<Future<void>> downloadTasks = [];
  for (var ep in comicInfo.eps.docs) {
    var epDir =
        '$comicDir/eps/${ep.order}.${ep.title.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_')}';
    for (var page in ep.pages.docs) {
      var pageFile =
          '$epDir/${page.media.originalName.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_')}';
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

  debugPrint(
      '漫画${comicInfo.comic.title.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_')}导出为文件夹完成');
  EasyLoading.showSuccess(
      '漫画${comicInfo.comic.title.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_')}导出为文件夹完成');
}

/// 导出漫画为 ZIP
Future<void> exportComicAsZip(ComicAllInfoJson comicInfo) async {
  var downloadPath = await createDownloadDir();
  var comicDir =
      comicInfo.comic.title.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_');

  // 保存漫画下载信息
  var comicInfoString = comicAllInfoJsonToJson(comicInfo);
  var comicInfoBytes = utf8.encode(comicInfoString);

  // 封面图片
  Uint8List? coverBytes;
  if (comicInfo.comic.thumb.path.isNotEmpty) {
    var coverDownloadFile = await downloadPicture(
      from: 'bika',
      url: comicInfo.comic.thumb.fileServer,
      path: comicInfo.comic.thumb.path,
      cartoonId: comicInfo.comic.id,
      pictureType: 'cover',
      chapterId: comicInfo.comic.id,
    );
    coverBytes = await File(coverDownloadFile).readAsBytes();
  }

  // 漫画页面
  final List<Map<String, dynamic>> pages = [];
  for (var ep in comicInfo.eps.docs) {
    var epDir =
        'eps/${ep.order}.${ep.title.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_')}';
    for (var page in ep.pages.docs) {
      var pageDownloadFile = await downloadPicture(
        from: 'bika',
        url: page.media.fileServer,
        path: page.media.path,
        cartoonId: comicInfo.comic.id,
        pictureType: 'comic',
        chapterId: ep.id,
      );
      var pageBytes = await File(pageDownloadFile).readAsBytes();
      var fileName =
          page.media.originalName.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_');
      pages.add({
        'path': join(epDir, fileName),
        'bytes': pageBytes,
      });
    }
  }

  // 将压缩任务放到后台线程中执行
  await compute(
    _compressToZip,
    _CompressToZipParams(
      downloadPath: downloadPath,
      comicDir: comicDir,
      comicInfoBytes: comicInfoBytes,
      coverBytes: coverBytes,
      pages: pages,
    ),
  );

  debugPrint(
      '漫画${comicInfo.comic.title.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_')}导出为ZIP完成');
  EasyLoading.showSuccess(
      '漫画${comicInfo.comic.title.replaceAll(RegExp(r'[<>:"/\\|?* ]'), '_')}导出为ZIP完成');
}

/// 压缩任务参数类
class _CompressToZipParams {
  final String downloadPath;
  final String comicDir;
  final Uint8List comicInfoBytes;
  final Uint8List? coverBytes;
  final List<Map<String, dynamic>> pages;

  _CompressToZipParams({
    required this.downloadPath,
    required this.comicDir,
    required this.comicInfoBytes,
    this.coverBytes,
    required this.pages,
  });
}

/// 压缩任务（在后台线程中执行）
void _compressToZip(_CompressToZipParams params) {
  var archive = Archive();

  // 添加漫画信息文件
  archive.addFile(ArchiveFile(
    'info.json',
    params.comicInfoBytes.length,
    params.comicInfoBytes,
  ));

  // 添加封面图片
  if (params.coverBytes != null) {
    archive.addFile(ArchiveFile(
      'cover/cover.jpg',
      params.coverBytes!.length,
      params.coverBytes!,
    ));
  }

  // 添加漫画页面
  for (var page in params.pages) {
    archive.addFile(ArchiveFile(
      page['path'],
      (page['bytes'] as Uint8List).length,
      page['bytes'],
    ));
  }

  // 将归档写入ZIP文件
  var zipFilePath = '${params.downloadPath}/${params.comicDir}.zip';
  var zipFile = File(zipFilePath);
  var output = ZipEncoder().encode(archive);
  zipFile.writeAsBytesSync(output);
}

/// 创建下载目录
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
