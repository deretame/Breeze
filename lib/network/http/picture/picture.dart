import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as file_path;
import 'package:zephyr/main.dart';
import 'package:zephyr/type/pipe.dart';

// ignore: unused_import
import '../../../config/global/global_setting.dart';
import '../../../config/jm/config.dart';
import '../../../src/rust/api/simple.dart';
import '../../../util/get_path.dart';

final pictureDio = Dio();

Future<String> getCachePicture({
  String from = '',
  String url = '',
  String path = '',
  String cartoonId = '1',
  String pictureType = '',
  String chapterId = '',
}) async {
  if (url.isEmpty) {
    throw Exception('URL 不能为空 404');
  }

  // 清理路径
  String sanitizedPath = sanitizePath(path);

  // 获取缓存和下载路径
  String cachePath = await getCachePath();
  String downloadPath = await getDownloadPath();

  // 构建文件路径
  String cacheFilePath = buildFilePath(
    cachePath,
    from,
    pictureType,
    cartoonId,
    chapterId,
    sanitizedPath,
  );

  String downloadFilePath = buildFilePath(
    downloadPath,
    from,
    pictureType,
    cartoonId,
    chapterId,
    sanitizedPath,
  );

  // 检查文件是否存在
  String existingFilePath = await checkFileExists(
    cacheFilePath,
    downloadFilePath,
  );
  if (existingFilePath.isNotEmpty) {
    return existingFilePath;
  }
  // logger.d('开始下载图片: $url');

  // 处理 URL
  String finalUrl =
      from == 'jm'
          ? url
          : buildImageUrl(
            url,
            path,
            pictureType,
            bikaSetting.imageQuality,
            bikaSetting.proxy,
          );

  // 下载图片
  Uint8List imageData = await downloadImageWithRetry(finalUrl);

  if (from == 'jm' && pictureType == 'comic') {
    await decodeAndSaveImage(
      imageData,
      chapterId.let(toInt),
      JmConfig.scrambleId.let(toInt),
      cacheFilePath,
      url,
    );
    return cacheFilePath;
  }

  // 保存图片
  await saveImage(imageData, cacheFilePath);

  return cacheFilePath;
}

Future<String> downloadPicture({
  String from = '',
  String url = '',
  String path = '',
  String cartoonId = '',
  String pictureType = '',
  String chapterId = '',
}) async {
  if (url.isEmpty) {
    throw Exception('URL 不能为空 404');
  }

  // 清理路径
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
  );

  String downloadFilePath = buildFilePath(
    downloadPath,
    from,
    pictureType,
    cartoonId,
    chapterId,
    sanitizedPath,
  );

  // 检查文件是否存在
  String existingFilePath = await checkFileExists(
    cacheFilePath,
    downloadFilePath,
  );

  if (existingFilePath.isNotEmpty) {
    if (existingFilePath != downloadFilePath) {
      await copyFile(cacheFilePath, downloadFilePath);
    }
    return downloadFilePath;
  }

  // 处理 URL
  String finalUrl =
      from == 'jm'
          ? url
          : buildImageUrl(
            url,
            path,
            pictureType,
            "original",
            bikaSetting.proxy,
          );

  // 下载图片
  Uint8List imageData = await downloadImageWithRetry(finalUrl, retry: true);

  if (from == 'jm' && pictureType == 'comic') {
    await decodeAndSaveImage(
      imageData,
      chapterId.let(toInt),
      JmConfig.scrambleId.let(toInt),
      downloadFilePath,
      url,
    );
    return downloadFilePath;
  }

  // 保存图片
  await saveImage(imageData, downloadFilePath);

  return downloadFilePath;
}

String sanitizePath(String path) {
  return path.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
}

String buildFilePath(
  String basePath,
  String from,
  String pictureType,
  String cartoonId,
  String chapterId,
  String sanitizedPath,
) {
  if (pictureType == 'comic') {
    return file_path.join(
      basePath,
      from,
      from == 'bika' ? bikaSetting.imageQuality : '',
      cartoonId,
      pictureType,
      chapterId,
      sanitizedPath,
    );
  } else if (pictureType == 'cover') {
    return file_path.join(
      basePath,
      from,
      from == 'bika' ? bikaSetting.imageQuality : '',
      cartoonId,
      pictureType,
      sanitizedPath,
    );
  } else {
    return file_path.join(basePath, from, pictureType, sanitizedPath);
  }
}

Future<String> checkFileExists(String cachePath, String downloadPath) async {
  if (await fileExists(downloadPath)) {
    return downloadPath;
  }

  if (await fileExists(cachePath)) {
    return cachePath;
  }

  return '';
}

Future<bool> fileExists(String filePath) async {
  try {
    return await File(filePath).exists();
  } catch (e) {
    logger.e('检查文件存在性时出错: $e');
    return false;
  }
}

Future<void> copyFile(String sourcePath, String targetPath) async {
  try {
    await ensureDirectoryExists(targetPath);
    await File(sourcePath).copy(targetPath);
  } catch (e) {
    logger.e('复制文件失败: $e');
    throw Exception('复制文件失败: $e');
  }
}

String buildImageUrl(
  String url,
  String path,
  String pictureType,
  String imageQuality,
  int proxy,
) {
  if (url == "https://storage1.picacomic.com") {
    if (pictureType == "cover") {
      url = "https://img.picacomic.com";
    } else if (pictureType == "creator" || pictureType == "favourite") {
      url =
          proxy == 1
              ? "https://storage.diwodiwo.xyz"
              : "https://s3.picacomic.com";
    } else {
      if (imageQuality != "original") {
        url = "https://img.picacomic.com";
      } else {
        url =
            proxy == 1
                ? "https://storage.diwodiwo.xyz"
                : "https://s3.picacomic.com";
      }
    }
  } else if (url == "https://storage-b.picacomic.com") {
    if (pictureType == "creator") {
      url = "https://storage-b.picacomic.com";
    } else if (pictureType == "cover") {
      url = "https://img.picacomic.com";
    } else if (imageQuality == "original") {
      url = "https://storage-b.diwodiwo.xyz";
    } else if (imageQuality != "original") {
      url = "https://img.picacomic.com";
    }
  }

  if (path.contains("picacomic-paint.jpg") ||
      path.contains("picacomic-gift.jpg")) {
    url =
        proxy == 1
            ? "https://storage.diwodiwo.xyz/static"
            : "https://s3.picacomic.com/static";
  }

  if (path.contains("tobeimg/")) {
    path = path.replaceAll("tobeimg/", "");
  } else if (path.contains("tobs/")) {
    path = "static/${path.replaceAll("tobs/", "")}";
  } else if (!path.contains("/") && !url.contains("static")) {
    path = "static/$path";
  }

  return '$url/$path';
}

Future<Uint8List> downloadImageWithRetry(
  String url, {
  bool retry = false,
}) async {
  var headers = {
    'User-Agent': '#',
    'Host': Uri.parse(url).host,
    'Connection': 'Keep-Alive',
    'Accept-Encoding': 'gzip',
  };

  while (true) {
    try {
      Response response = await pictureDio.get(
        url,
        options: Options(headers: headers, responseType: ResponseType.bytes),
      );
      return response.data as Uint8List;
    } catch (e) {
      if (e.toString().contains('422')) {
        throw Exception('404');
      }
      logger.e('下载图片失败: $e, URL: $url');
      if (!retry) {
        throw Exception('下载图片失败: $e');
      }
      await Future.delayed(Duration(seconds: 1)); // 延迟 1 秒后重试
    }
  }
}

Future<void> saveImage(Uint8List imageData, String filePath) async {
  // logger.d('开始保存图片到：$filePath');
  final targetFile = File(filePath);

  try {
    // 确保目录存在
    await ensureDirectoryExists(filePath);

    // 直接写入目标文件
    await targetFile.writeAsBytes(imageData);

    // logger.d('图片已保存到：$filePath');
  } catch (e) {
    // 如果发生异常，删除不完整的文件
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    logger.e('保存图片失败: $e');
    throw Exception('保存图片失败: $e');
  }
}

Future<void> ensureDirectoryExists(String filePath) async {
  final directory = Directory(file_path.dirname(filePath));
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
}

String get baseUrl => JmConfig.imagesUrl;

String getJmCoverUrl(String id) {
  return '$baseUrl/media/albums/${id}_3x4.jpg';
}

String getJmImagesUrl(String id, String imageName) {
  return '$baseUrl/media/photos/$id/$imageName';
}

Future<void> decodeAndSaveImage(
  Uint8List imgData,
  int chapterId,
  int scrambleId,
  String fileName,
  String url,
) async {
  if (imgData.isEmpty) {
    throw Exception('该图片已失效');
  }

  try {
    await antiObfuscationPicture(
      imgData: imgData,
      chapterId: chapterId,
      scrambleId: scrambleId,
      fileName: fileName,
      url: url,
    );
  } catch (e, s) {
    logger.e(e, stackTrace: s);
    rethrow;
  }
}
