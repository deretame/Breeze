import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as file_path;
import 'package:zephyr/main.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/settings_hive_utils.dart';

import '../../../config/jm/config.dart';
import '../../../src/rust/api/simple.dart';
import '../../../src/rust/decode/decode.dart';
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
  if (url.contains("nopic-Male.gif")) return "nopic-Male.gif";

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
    "original",
  );

  // 检查文件是否存在
  String existingFilePath = await checkFileExists(
    cacheFilePath,
    downloadFilePath,
  );
  if (existingFilePath.isNotEmpty) {
    // 双重检查文件确实存在且可读
    final file = File(existingFilePath);
    if (await file.exists()) {
      try {
        // 尝试读取文件大小以确保文件可访问
        await file.length();
        return existingFilePath;
      } catch (e) {
        // 文件存在但无法访问，删除并重新下载
        logger.w(
          'getCachePicture: 文件存在但无法访问，删除并重新下载: $existingFilePath',
          error: e,
        );
        try {
          await file.delete();
        } catch (deleteError) {
          logger.e(
            'getCachePicture: 删除损坏文件失败: $existingFilePath',
            error: deleteError,
          );
        }
        // 继续下载流程
      }
    }
  }

  // 处理 URL
  String finalUrl = from == 'jm'
      ? url
      : buildImageUrl(
          url,
          path,
          pictureType,
          SettingsHiveUtils.bikaImageQuality,
          SettingsHiveUtils.bikaProxy,
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
    // 验证文件已成功保存
    if (await File(cacheFilePath).exists()) {
      return cacheFilePath;
    } else {
      throw Exception('图片保存失败');
    }
  }

  // 保存图片
  await saveImage(imageData, cacheFilePath);

  // 验证文件已成功保存
  if (await File(cacheFilePath).exists()) {
    return cacheFilePath;
  } else {
    throw Exception('图片保存失败');
  }
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
  if (url.contains("404") && from == "jm") {
    return "404";
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
    // 双重检查文件确实存在且可读
    final file = File(existingFilePath);
    if (await file.exists()) {
      try {
        // 尝试读取文件大小以确保文件可访问
        await file.length();
        if (existingFilePath != downloadFilePath) {
          await copyFile(cacheFilePath, downloadFilePath);
        }
        return downloadFilePath;
      } catch (e) {
        // 文件存在但无法访问，删除并重新下载
        logger.w(
          'downloadPicture: 文件存在但无法访问，删除并重新下载: $existingFilePath',
          error: e,
        );
        try {
          await file.delete();
        } catch (deleteError) {
          logger.e(
            'downloadPicture: 删除损坏文件失败: $existingFilePath',
            error: deleteError,
          );
        }
        // 继续下载流程
      }
    }
  }

  // 处理 URL
  String finalUrl = from == 'jm'
      ? url
      : buildImageUrl(
          url,
          path,
          pictureType,
          "original",
          SettingsHiveUtils.bikaProxy,
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
    // 验证文件已成功保存
    if (await File(downloadFilePath).exists()) {
      return downloadFilePath;
    } else {
      throw Exception('图片保存失败');
    }
  }

  // 保存图片
  await saveImage(imageData, downloadFilePath);

  // 验证文件已成功保存
  if (await File(downloadFilePath).exists()) {
    return downloadFilePath;
  } else {
    throw Exception('图片保存失败');
  }
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
  String sanitizedPath, [
  String? quality,
]) {
  String quality1 = '';
  if (from == 'bika') {
    quality1 = quality ?? SettingsHiveUtils.bikaImageQuality;
  }
  if (pictureType == 'comic') {
    return file_path.join(
      basePath,
      from,
      quality1,
      cartoonId,
      pictureType,
      chapterId,
      sanitizedPath,
    );
  } else if (pictureType == 'cover') {
    return file_path.join(
      basePath,
      from,
      quality1,
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
      url = proxy == 1
          ? "https://storage.diwodiwo.xyz"
          : "https://s3.picacomic.com";
    } else {
      if (imageQuality != "original") {
        url = "https://img.picacomic.com";
      } else {
        url = proxy == 1
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
    url = proxy == 1
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
      Response response = await pictureDio
          .get(
            url,
            options: Options(
              headers: headers,
              responseType: ResponseType.bytes,
            ),
          )
          .timeout(Duration(seconds: 30));
      return response.data as Uint8List;
    } catch (e) {
      if (e is TimeoutException) {
        logger.e('下载图片超时: $url, 准备重试...');
      } else if (e is DioException && e.toString().contains('422')) {
        logger.e('下载图片遇到 422 错误 (当作 404 处理): $url');
        throw Exception('404');
      } else {
        logger.e('下载图片失败: $e, URL: $url');
        if (!retry) {
          throw Exception('下载图片失败: $e');
        }
      }
      if (retry && !(e is DioException && e.toString().contains('422'))) {
        await Future.delayed(Duration(seconds: 1));
      } else if (!retry) {
        throw Exception('下载图片失败: $e');
      }
    }
  }
}

Future<void> saveImage(Uint8List imageData, String filePath) async {
  // logger.d('开始保存图片到：$filePath');
  final targetFile = File(filePath);

  try {
    // 验证图片数据不为空
    if (imageData.isEmpty) {
      throw Exception('图片数据为空');
    }

    // 基本的图片格式验证（检查文件头）
    if (!_isValidImageData(imageData)) {
      logger.w('警告：图片数据可能无效，但仍尝试保存: $filePath');
    }

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

/// 验证图片数据是否有效（检查常见图片格式的文件头）
bool _isValidImageData(Uint8List data) {
  if (data.length < 4) return false;

  // JPEG: FF D8 FF
  if (data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF) {
    return true;
  }

  // PNG: 89 50 4E 47
  if (data[0] == 0x89 &&
      data[1] == 0x50 &&
      data[2] == 0x4E &&
      data[3] == 0x47) {
    return true;
  }

  // GIF: 47 49 46 38
  if (data[0] == 0x47 &&
      data[1] == 0x49 &&
      data[2] == 0x46 &&
      data[3] == 0x38) {
    return true;
  }

  // WebP: 52 49 46 46 (RIFF)
  if (data[0] == 0x52 &&
      data[1] == 0x49 &&
      data[2] == 0x46 &&
      data[3] == 0x46) {
    return true;
  }

  return false;
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

String getUserCover(String imageName) {
  return '$baseUrl/media/users/$imageName';
}

Future<void> decodeAndSaveImage(
  Uint8List imgData,
  int chapterId,
  int scrambleId,
  String fileName,
  String url,
) async {
  if (imgData.isEmpty) {
    throw Exception('404');
  }

  try {
    await antiObfuscationPicture(
      imageInfo: ImageInfo(
        imgData: imgData,
        chapterId: chapterId,
        scrambleId: scrambleId,
        fileName: fileName,
        url: url,
      ),
    );
  } catch (e, s) {
    logger.e(e, stackTrace: s);
    rethrow;
  }
}
