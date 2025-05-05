import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart';
import 'package:path/path.dart' as file_path;
import 'package:zephyr/main.dart';
import 'package:zephyr/type/pipe.dart';

// ignore: unused_import
import '../../../config/global/global_setting.dart';
import '../../../config/jm/config.dart';
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
    imageData = await antiObfuscationPicture(imageData, chapterId, url);
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
      path.isEmpty
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
    imageData = await antiObfuscationPicture(imageData, chapterId, url);
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

// 用来给compute传输图片数据
class JmPictureData {
  TransferableTypedData imgData;
  int epsId;
  int scrambleId;
  String pictureName;

  JmPictureData(this.imgData, this.epsId, this.scrambleId, this.pictureName);
}

int getSegmentationNum(int epsId, int scrambleId, String pictureName) {
  int num = 0;

  if (epsId < scrambleId) {
    num = 0;
  } else if (epsId < 268850) {
    num = 10;
  } else if (epsId > 421926) {
    String string = epsId.toString() + pictureName;
    List<int> bytes = utf8.encode(string);
    String hash = md5.convert(bytes).toString();
    int charCode = hash.codeUnitAt(hash.length - 1);
    int remainder = charCode % 8;
    num = remainder * 2 + 2;
  } else {
    String string = epsId.toString() + pictureName;
    List<int> bytes = utf8.encode(string);
    String hash = md5.convert(bytes).toString();
    int charCode = hash.codeUnitAt(hash.length - 1);
    int remainder = charCode % 10;
    num = remainder * 2 + 2;
  }

  return num;
}

Uint8List segmentationPictureToDisk(JmPictureData pictureData) {
  Uint8List imgData = pictureData.imgData.materialize().asUint8List();
  int epsId = pictureData.epsId;
  int scrambleId = pictureData.scrambleId;
  String pictureName = pictureData.pictureName;

  final num = getSegmentationNum(epsId, scrambleId, pictureName);

  if (num <= 1) {
    return imgData;
  }

  Image srcImg;
  try {
    srcImg = decodeImage(imgData)!;
  } catch (e) {
    throw Exception(
      "Failed to decode image: Data length is ${imgData.length} bytes",
    );
  }

  int blockSize = (srcImg.height / num).floor();
  int remainder = srcImg.height % num;

  List<Map<String, int>> blocks = [];

  for (int i = 0; i < num; i++) {
    int start = i * blockSize;
    int end = start + blockSize + ((i != num - 1) ? 0 : remainder);
    blocks.add({'start': start, 'end': end});
  }

  Image desImg = Image(width: srcImg.width, height: srcImg.height);

  int y = 0;
  for (int i = blocks.length - 1; i >= 0; i--) {
    var block = blocks[i];
    int currBlockHeight = block['end']! - block['start']!;
    var range = srcImg.getRange(
      0,
      block['start']!,
      srcImg.width,
      currBlockHeight,
    );
    var desRange = desImg.getRange(0, y, srcImg.width, currBlockHeight);
    while (range.moveNext() && desRange.moveNext()) {
      desRange.current.r = range.current.r;
      desRange.current.g = range.current.g;
      desRange.current.b = range.current.b;
      desRange.current.a = range.current.a;
    }
    y += currBlockHeight;
  }

  return encodeJpg(desImg);
}

Future<Uint8List> antiObfuscationPicture(
  Uint8List imgData,
  String chapterId,
  String url,
) async {
  // 因为获取到的数据最后会多一位没有用的字节，所以需要移除掉，不然图片无法处理，image库会报错
  final transferable = TransferableTypedData.fromList([
    imgData.sublist(0, imgData.length - 1),
  ]);
  var data = JmPictureData(transferable, 0, 0, '');
  data.epsId = chapterId.let(toInt);
  data.scrambleId = JmConfig.scrambleId.let(toInt);
  data.pictureName = url.split('/').last.split('.').first;
  return await compute(segmentationPictureToDisk, data);
}
