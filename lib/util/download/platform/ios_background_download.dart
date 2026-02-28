import 'dart:io';

import 'package:background_downloader/background_downloader.dart' as bd;
import 'package:flutter/foundation.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/picture/picture.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';

import '../../../config/jm/config.dart';
import '../../../util/get_path.dart';

/// 使用 background_downloader 下载图片（iOS 后台 URLSession）
///
/// 与 [downloadImageWithRetry] 相同的功能，但使用 iOS 原生 URLSession
/// 后台传输，即使 App 进入后台也能继续下载。
Future<Uint8List> downloadImageWithRetryIOS(
  String url, {
  bool retry = false,
}) async {
  final uniqueId =
      '${DateTime.now().millisecondsSinceEpoch}_${url.hashCode.abs()}';

  final task = bd.DownloadTask(
    url: url,
    headers: {
      'User-Agent': '#',
      'Connection': 'Keep-Alive',
      'Accept-Encoding': 'gzip',
    },
    baseDirectory: bd.BaseDirectory.temporary,
    filename: 'bg_dl_$uniqueId.tmp',
    retries: retry ? 3 : 0,
  );

  int attempts = 0;
  const maxAttempts = 5;

  while (true) {
    attempts++;

    final result = await bd.FileDownloader().download(task);

    if (result.status == bd.TaskStatus.complete) {
      final filePath = await task.filePath();
      final file = File(filePath);

      try {
        final bytes = await file.readAsBytes();
        // 清理临时文件
        try {
          await file.delete();
        } catch (_) {}
        return bytes;
      } catch (e) {
        logger.e('读取下载文件失败: $e');
        try {
          await file.delete();
        } catch (_) {}
        rethrow;
      }
    } else if (result.status == bd.TaskStatus.notFound) {
      // 404 错误
      throw Exception('404');
    } else {
      // 下载失败
      if (retry && attempts < maxAttempts) {
        logger.w('iOS 后台下载失败 (尝试 $attempts/$maxAttempts): $url');
        await Future.delayed(Duration(seconds: 1));
        continue;
      }
      throw Exception('iOS 后台下载失败: ${result.status}, URL: $url');
    }
  }
}

/// iOS 专用的图片下载函数
///
/// 与 [downloadPicture] 功能完全相同，但内部使用 [downloadImageWithRetryIOS]
/// 通过 iOS URLSession 后台传输 API 进行下载，支持 App 在后台继续下载。
Future<String> downloadPictureIOS({
  From from = From.bika,
  String url = '',
  String path = '',
  String cartoonId = '',
  PictureType pictureType = PictureType.comic,
  String chapterId = '',
  int? proxy,
}) async {
  if (url.isEmpty) {
    throw Exception('URL 不能为空 404');
  }
  if (url.contains("404") && from == From.jm) {
    return "404";
  }

  // 清理路径 (复用 picture.dart 的公共函数)
  String sanitizedPath = sanitizePath(path);

  // 获取下载路径
  String downloadPath = await getDownloadPath();
  String cachePath = await getCachePath();

  String cacheFilePath = buildFilePath(
    cachePath,
    from,
    pictureType,
    cartoonId,
    chapterId,
    sanitizedPath,
    "original",
  );

  String downloadFilePath = buildFilePath(
    downloadPath,
    from,
    pictureType,
    cartoonId,
    chapterId,
    sanitizedPath,
    "original",
  );

  // 检查文件是否存在
  String existingFilePath = await checkFileExists(
    cacheFilePath,
    downloadFilePath,
  );

  if (existingFilePath.isNotEmpty) {
    final file = File(existingFilePath);
    if (await file.exists()) {
      try {
        await file.length();
        if (existingFilePath != downloadFilePath) {
          await copyFile(cacheFilePath, downloadFilePath);
        }
        return downloadFilePath;
      } catch (e) {
        logger.w(
          'downloadPictureIOS: 文件存在但无法访问，删除并重新下载: $existingFilePath',
          error: e,
        );
        try {
          await file.delete();
        } catch (deleteError) {
          logger.e(
            'downloadPictureIOS: 删除损坏文件失败: $existingFilePath',
            error: deleteError,
          );
        }
      }
    }
  }

  // 处理 URL
  String finalUrl = from == From.jm
      ? url
      : buildImageUrl(
          url,
          path,
          pictureType,
          "original",
          proxy ?? objectbox.userSettingBox.get(1)!.bikaSetting.proxy,
        );

  // 使用 background_downloader 下载图片
  Uint8List imageData = await downloadImageWithRetryIOS(finalUrl, retry: true);

  if (from == From.jm && pictureType == PictureType.comic) {
    await decodeAndSaveImage(
      imageData,
      chapterId.let(toInt),
      JmConfig.scrambleId.let(toInt),
      downloadFilePath,
      url,
    );
    if (await File(downloadFilePath).exists()) {
      return downloadFilePath;
    } else {
      throw Exception('图片保存失败');
    }
  }

  // 保存图片
  await saveImage(imageData, downloadFilePath);

  if (await File(downloadFilePath).exists()) {
    return downloadFilePath;
  } else {
    throw Exception('图片保存失败');
  }
}
