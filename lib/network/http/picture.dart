import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zephyr/main.dart';

// ignore: unused_import
import '../../config/global_setting.dart';
import '../../util/get_path.dart';

Future<String> getCachePicture({
  String from = '',
  String url = '',
  String path = '',
  String cartoonId = '',
  String pictureType = '',
  String chapterId = '',
}) async {
  if (url == '') {
    return '404';
  }

  // 处理图片的路径
  // 先统一处理路径中的非法字符
  String sanitizedPath = path.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
  String cachePath = await getCachePath();
  // String appPath = await getAppDirectory();
  String filePath = "";
  String imageQuality = bikaSetting.imageQuality;
  int proxy = bikaSetting.proxy;

  if (pictureType == 'comic') {
    filePath =
        "$cachePath/$from/comic/$imageQuality/$cartoonId/$pictureType/$sanitizedPath";
  } else if (pictureType == 'cover') {
    filePath =
        "$cachePath/$from/comic/$imageQuality/$cartoonId/$pictureType/$chapterId/$sanitizedPath";
  } else {
    filePath = "$cachePath/$from/$pictureType/$sanitizedPath";
  }

  // 构造网络请求地址
  if (path.contains("tobeimg/")) {
    path = path.replaceAll("tobeimg/", "");
  } else if (path.contains("tobs/")) {
    path = "static/${path.replaceAll("tobs/", "")}";
  } else if (!path.contains("/") && !url.contains("static")) {
    path = "static/$path";
  }

  debugPrint('构造的图片路径：$filePath');
  // 检查文件是否存在
  final file = File(filePath);

  // 先检查缓存目录中是否存在
  if (await file.exists()) {
    return filePath;
  }

  // 再次检查下载目录是否存在文件
  final downloadPath = await getDownloadPath();
  debugPrint('下载目录：$downloadPath');
  String downloadFilePath =
      "$downloadPath/comic/$cartoonId/$chapterId/$sanitizedPath";
  final downloadFile = File(downloadFilePath);
  if (await downloadFile.exists()) {
    return downloadFilePath;
  }

  // 如果不在
  // 处理url
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

  // 本子搜索界面这两个比较特殊，需要特殊处理
  if (path.contains("picacomic-paint.jpg") ||
      path.contains("picacomic-gift.jpg")) {
    url = proxy == 1
        ? "https://storage.diwodiwo.xyz/static"
        : "https://s3.picacomic.com/static";
  }

  // 构造请求头
  String host = Uri.parse(url).host;
  var headers = {
    'User-Agent': "#",
    'Host': host,
    'Connection': "Keep-Alive",
    'Accept-Encoding': "gzip",
  };

  // 发送GET请求
  var dio = Dio();
  var lastUrl = '$url/$path';
  lastUrl = replaceSubsequentDoubleSlashes(lastUrl);
  // debugPrint('请求地址：$lastUrl');
  // debugPrint('请求头：$headers');

  try {
    Response response = await dio.get(
      lastUrl,
      options: Options(
        headers: headers,
        responseType: ResponseType.bytes, // 确保返回二进制数据
      ),
    );

    // 检查响应状态码
    if (response.statusCode == 200) {
      // 获取响应体（图片数据）
      String? contentType = response.headers.value('content-type');
      debugPrint(contentType); // 例如: "image/jpeg"
      Uint8List imageData = response.data as Uint8List;

      // 临时文件
      String tempPath = "$cachePath/temp/$sanitizedPath";

      var tempFile = File(tempPath);

      // 先写入到临时文件
      try {
        // 如果文件不存在，则创建文件
        if (!await tempFile.exists()) {
          await tempFile.create(recursive: true);
        }

        await tempFile.writeAsBytes(imageData);

        // 写入完成后再移动到目标路径
        if (!await file.exists()) {
          await file.create(recursive: true);
        }
        await tempFile.rename(filePath);
      } catch (e) {
        // 如果发生异常，删除不完整的文件
        await tempFile.delete();
        debugPrint('保存图片时发生错误，已删除不完整的文件');
        throw Exception(e.toString());
      }

      debugPrint('图片已保存到：$filePath');
    } else if (response.statusCode == 404) {
      throw Exception('404 Not Found');
    } else {
      debugPrint('请求失败，状态码：${response.statusCode}');
      // 先检查缓存目录中是否存在
      if (await file.exists()) {
        file.delete();
      }
      throw Exception('请求失败，状态码：${response.statusCode}');
    }
  } catch (e) {
    debugPrint('请求过程中发生错误：$e');
    // 先检查缓存目录中是否存在
    if (await file.exists()) {
      file.delete();
    }

    throw Exception(e.toString());
  }

  return filePath;
}

// // 因为哔咔的部分本子不让下载，所以我直接重写了一套逻辑，实际上就是上面的修改版，只是把缓存目录换成了下载目录。
// Future<String> downloadPicture(
//     String url, String path, String cartoonId, String chapterId) async {
//   // 处理图片的路径
//   // 先统一处理路径中的非法字符
//   String sanitizedPath = path.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
//   String downloadPath = await getDownloadPath();
//   String filePath = "";
//   String imageQuality = bikaSetting.imageQuality;
//
//   filePath =
//       "$downloadPath/comic/$imageQuality/$cartoonId/$chapterId/$sanitizedPath";
//
//   // 构造文件存储路径和网络请求地址
//   if (path.contains("tobeimg/")) {
//     path = path.replaceAll("tobeimg/", "");
//   } else if (path.contains("tobs/")) {
//     path = "static/${path.replaceAll("tobs/", "")}";
//   } else if (!path.contains("/")) {
//     path = "static/$path";
//   }
//
//   debugPrint('构造的图片路径：$filePath');
//   // 检查文件是否存在
//   final file = File(filePath);
//
//   // 先检查缓存目录中是否存在
//   if (await file.exists()) {
//     return filePath;
//   }
//
//   // 再次检查缓存目录是否存在文件
//   final cachePath = await getCachePath();
//   debugPrint('缓存目录：$cachePath');
//   String cacheFilePath =
//       "$cachePath/comic/$imageQuality/$cartoonId/$chapterId/$sanitizedPath";
//   final cacheFile = File(cacheFilePath);
//   if (await cacheFile.exists()) {
//     final file = File(filePath);
//     if (!await file.exists()) {
//       await file.create(recursive: true);
//     }
//     await file.writeAsBytes(await cacheFile.readAsBytes());
//     debugPrint('图片已从缓存目录复制到下载目录：$filePath');
//     return filePath;
//   }
//
//   // 如果不在
//   // 处理url
//   if (url == "https://storage1.picacomic.com") {
//     if (imageQuality != "origin") {
//       url = "https://img.picacomic.com";
//     } else if (shunt == 1) {
//       url = "https://storage.diwodiwo.xyz";
//     } else {
//       url = "https://s3.picacomic.com";
//     }
//   } else if (url == "https://storage-b.picacomic.com") {
//     url = "https://storage-b.diwodiwo.xyz";
//   }
//
//   // 构造请求头
//   String host = Uri.parse(url).host;
//   var headers = {
//     'User-Agent': "#",
//     'Host': host,
//     'Connection': "Keep-Alive",
//     'Accept-Encoding': "gzip",
//   };
//
//   // 发送GET请求
//   var dio = Dio();
//   final lastUrl = '$url/$path';
//   debugPrint('请求地址：$lastUrl');
//   debugPrint('请求头：$headers');
//
//   try {
//     Response response = await dio.get(
//       lastUrl,
//       options: Options(
//         headers: headers,
//         responseType: ResponseType.bytes, // 确保返回二进制数据
//       ),
//     );
//
//     // 检查响应状态码
//     if (response.statusCode == 200) {
//       // 获取响应体（图片数据）
//       String? contentType = response.headers.value('content-type');
//       debugPrint(contentType); // 例如: "image/jpeg"
//       Uint8List imageData = response.data as Uint8List;
//
//       // 如果文件不存在，则创建文件
//       if (!await file.exists()) {
//         await file.create(recursive: true);
//       }
//
//       await file.writeAsBytes(imageData);
//
//       debugPrint('图片已保存到：$filePath');
//     } else {
//       debugPrint('请求失败，状态码：${response.statusCode}');
//     }
//   } catch (e) {
//     debugPrint('请求过程中发生错误：$e');
//     return "error";
//   }
//
//   return filePath;
// }

String replaceSubsequentDoubleSlashes(String input) {
  String target = '//';
  String replacement = '/';

  // 找到第一个'//'的位置
  int firstDoubleSlashIndex = input.indexOf(target);

  // 如果存在第一个'//'，则从其后开始替换所有'//'为'/'
  if (firstDoubleSlashIndex != -1) {
    String firstPart =
        input.substring(0, firstDoubleSlashIndex + target.length);
    String secondPart = input.substring(firstDoubleSlashIndex + target.length);
    String replacedSecondPart = secondPart.replaceAll(target, replacement);
    return '$firstPart$replacedSecondPart';
  } else {
    // 如果没有'//'，则返回原始字符串
    return input;
  }
}
