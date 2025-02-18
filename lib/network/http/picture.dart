import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as file_path;
import 'package:zephyr/main.dart';

// ignore: unused_import
import '../../config/global_setting.dart';
import '../../util/get_path.dart';

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
  String finalUrl = buildImageUrl(
    url,
    path,
    pictureType,
    bikaSetting.imageQuality,
    bikaSetting.proxy,
  );

  // 下载图片
  Uint8List imageData = await downloadImageWithRetry(finalUrl);

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
    return existingFilePath;
  }

  // 处理 URL
  String finalUrl = buildImageUrl(
    url,
    path,
    pictureType,
    "original",
    bikaSetting.proxy,
  );

  // 下载图片
  Uint8List imageData = await downloadImageWithRetry(finalUrl);

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
      bikaSetting.imageQuality,
      cartoonId,
      pictureType,
      chapterId,
      sanitizedPath,
    );
  } else if (pictureType == 'cover') {
    return file_path.join(
      basePath,
      from,
      bikaSetting.imageQuality,
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
    debugPrint('检查文件存在性时出错: $e');
    return false;
  }
}

Future<void> copyFile(String sourcePath, String targetPath) async {
  try {
    await ensureDirectoryExists(targetPath);
    await File(sourcePath).copy(targetPath);
  } catch (e) {
    debugPrint('复制文件失败: $e');
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

  return replaceSubsequentDoubleSlashes('$url/$path');
}

Future<Uint8List> downloadImageWithRetry(String url) async {
  var dio = Dio();
  var headers = {
    'User-Agent': '#',
    'Host': Uri.parse(url).host,
    'Connection': 'Keep-Alive',
    'Accept-Encoding': 'gzip',
  };

  while (true) {
    try {
      Response response = await dio.get(
        url,
        options: Options(headers: headers, responseType: ResponseType.bytes),
      );
      return response.data as Uint8List;
    } catch (e) {
      debugPrint('下载图片失败: $e, URL: $url');
      await Future.delayed(Duration(seconds: 1)); // 延迟 1 秒后重试
    }
  }
}

Future<void> saveImage(Uint8List imageData, String filePath) async {
  final targetFile = File(filePath);

  try {
    // 确保目录存在
    await ensureDirectoryExists(filePath);

    // 直接写入目标文件
    await targetFile.writeAsBytes(imageData);

    debugPrint('图片已保存到：$filePath');
  } catch (e) {
    // 如果发生异常，删除不完整的文件
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    debugPrint('保存图片失败: $e');
    throw Exception('保存图片失败: $e');
  }
}

Future<void> ensureDirectoryExists(String filePath) async {
  final directory = Directory(file_path.dirname(filePath));
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
}

String replaceSubsequentDoubleSlashes(String input) {
  String target = '//';
  String replacement = '/';

  // 找到第一个'//'的位置
  int firstDoubleSlashIndex = input.indexOf(target);

  // 如果存在第一个'//'，则从其后开始替换所有'//'为'/'
  if (firstDoubleSlashIndex != -1) {
    String firstPart = input.substring(
      0,
      firstDoubleSlashIndex + target.length,
    );
    String secondPart = input.substring(firstDoubleSlashIndex + target.length);
    String replacedSecondPart = secondPart.replaceAll(target, replacement);
    return '$firstPart$replacedSecondPart';
  } else {
    // 如果没有'//'，则返回原始字符串
    return input;
  }
}
