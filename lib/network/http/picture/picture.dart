import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as file_path;
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/qjs_download_runtime.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/util/download/download_cancel_signal.dart';
import 'package:zephyr/util/real_sr/real_sr_super_resolution.dart';

import '../../../src/rust/api/simple.dart';
import '../../../src/rust/decode/decode.dart';
import '../../../util/get_path.dart';

final pictureDio = Dio();
const _kQjsRuntimeCancelled = '__QJS_RUNTIME_CANCELLED__';
const _kDownloadTaskCancelled = '__DOWNLOAD_TASK_CANCELLED__';
const _kJmPluginUuid = 'bf99008d-010b-4f17-ac7c-61a9b57dc3d9';

void _throwIfDownloadCancelled(String taskGroupKey) {
  if (taskGroupKey.isNotEmpty && isDownloadCancelSignaled(taskGroupKey)) {
    throw const DownloadTaskCancelledException();
  }
}

Future<String> getCachePicture({
  required String from,
  String url = '',
  String path = '',
  String cartoonId = '1',
  String chapterId = '',
  PictureType pictureType = PictureType.page,
  Map<String, dynamic>? extern,
  int index = 0,
}) async {
  final resolvedFrom = normalizePluginId(from);
  if (resolvedFrom.isEmpty) {
    throw StateError('getCachePicture missing pluginId');
  }
  if (url.contains("nopic-Male.gif")) return "nopic-Male.gif";

  final directPath = path.trim();
  if (directPath.isNotEmpty && file_path.isAbsolute(directPath)) {
    final directFile = File(directPath);
    if (await directFile.exists()) {
      try {
        await directFile.length();
        return directPath;
      } catch (_) {}
    }
  }
  if (directPath.isEmpty) {
    return '404';
  }

  final cachePath = await getCachePath();
  final downloadPath = await getDownloadPath();

  final encodePicturePath = path.trim().let((path) => encodePath(path: path));
  final encodeCartoonId = cartoonId.trim().let(
    (path) => encodePath(path: path),
  );
  final encodeChapterId = chapterId.trim().let(
    (path) => encodePath(path: path),
  );

  final newCacheFilePath = _buildStoredFilePath(
    cachePath,
    resolvedFrom,
    encodePicturePath,
    encodeCartoonId,
    pictureType == PictureType.cover ? '' : encodeChapterId,
  );

  final newDownloadFilePath = _buildStoredFilePath(
    downloadPath,
    resolvedFrom,
    encodePicturePath,
    encodeCartoonId,
    pictureType == PictureType.cover ? '' : encodeChapterId,
    rootFolder: 'original',
  );

  final oldCacheFilePath = _buildStoredFilePath(
    cachePath,
    resolvedFrom,
    path,
    cartoonId,
    pictureType == PictureType.cover ? '' : chapterId,
  );

  final oldDownloadFilePath = _buildStoredFilePath(
    downloadPath,
    resolvedFrom,
    path,
    cartoonId,
    pictureType == PictureType.cover ? '' : chapterId,
    rootFolder: 'original',
  );

  // 优先使用新（编码后）路径查找
  String existingFilePath = await checkFileExists(
    newCacheFilePath,
    newDownloadFilePath,
  );

  if (existingFilePath.isEmpty) {
    // 未找到，回退到旧（未编码）路径
    existingFilePath = await checkFileExists(
      oldCacheFilePath,
      oldDownloadFilePath,
    );
  }

  if (existingFilePath.isNotEmpty) {
    // 双重检查文件确实存在且可读
    final file = File(existingFilePath);
    if (await file.exists()) {
      try {
        // 尝试读取文件大小以确保文件可访问
        await file.length();
        // 超分 + WebP 转换统一封装，内部会判断分辨率并保留原文件名
        if (pictureType == PictureType.page) {
          await RealSrSuperResolution.upscaleAndConvertToWebp(existingFilePath);
        }
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

  if (url.isEmpty) {
    throw Exception('404');
  }

  extern = {...?extern};
  extern['priority'] ??= 0;

  final imageData = await downloadImageWithRetry(
    url,
    source: resolvedFrom,
    extern: extern,
  );

  if (resolvedFrom == _kJmPluginUuid && pictureType == PictureType.page) {
    await decodeAndSaveImage(
      imageData,
      chapterId.let(toInt),
      newCacheFilePath,
      url,
    );
    // 验证文件已成功保存
    if (await File(newCacheFilePath).exists()) {
      if (pictureType == PictureType.page) {
        await RealSrSuperResolution.upscaleAndConvertToWebp(newCacheFilePath);
      }
      return newCacheFilePath;
    } else {
      throw Exception('图片保存失败');
    }
  }

  // 保存图片
  await saveImage(imageData, newCacheFilePath);

  // 验证文件已成功保存
  if (await File(newCacheFilePath).exists()) {
    // 超分 + WebP 转换统一封装，内部会判断分辨率并保留原文件名
    if (pictureType == PictureType.page) {
      await RealSrSuperResolution.upscaleAndConvertToWebp(newCacheFilePath);
    }
    return newCacheFilePath;
  } else {
    throw Exception('图片保存失败');
  }
}

Future<String> downloadPicture({
  required String from,
  String url = '',
  String path = '',
  String cartoonId = '1',
  String chapterId = '',
  PictureType pictureType = PictureType.page,
  String? qjsName,
  String qjsTaskGroupKey = '',
  bool retry = false,
  Map<String, dynamic> extern = const <String, dynamic>{},
}) async {
  final resolvedFrom = normalizePluginId(from);
  if (resolvedFrom.isEmpty) {
    throw StateError('downloadPicture missing pluginId');
  }
  if (url.isEmpty) {
    return '404';
  }
  if (url.contains("404")) {
    return "404";
  }

  if (path.trim().isEmpty) {
    return '404';
  }

  final encodePicturePath = path
      .let((path) => _sanitizeStoredPath(path))
      .trim()
      .let((path) => encodePath(path: path));
  final encodeCartoonId = cartoonId.trim().let(
    (path) => encodePath(path: path),
  );
  final encodeChapterId = chapterId.trim().let(
    (path) => encodePath(path: path),
  );

  final downloadPath = await getDownloadPath();
  final cachePath = await getCachePath();
  final cacheFilePath = _buildStoredFilePath(
    cachePath,
    resolvedFrom,
    encodePicturePath,
    encodeCartoonId,
    pictureType == PictureType.cover ? '' : encodeChapterId,
    rootFolder: 'original',
  );

  final downloadFilePath = _buildStoredFilePath(
    downloadPath,
    resolvedFrom,
    encodePicturePath,
    encodeCartoonId,
    pictureType == PictureType.cover ? '' : encodeChapterId,
    rootFolder: 'original',
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

  Uint8List imageData;
  try {
    imageData = await downloadImageWithRetry(
      url,
      source: resolvedFrom,
      retry: retry,
      qjsName: qjsName,
      qjsTaskGroupKey: qjsTaskGroupKey,
      extern: extern,
      maxRetries: 10,
    );
  } catch (e) {
    if (_isDownloadTaskCancelledError(e) || _isQjsRuntimeCancelledError(e)) {
      rethrow;
    }
    logger.w('downloadPicture skip source=$resolvedFrom url=$url error=$e');
    return '404';
  }

  _throwIfDownloadCancelled(qjsTaskGroupKey);

  if (resolvedFrom == _kJmPluginUuid && pictureType == PictureType.page) {
    await decodeAndSaveImage(
      imageData,
      chapterId.let(toInt),
      downloadFilePath,
      url,
    );

    _throwIfDownloadCancelled(qjsTaskGroupKey);

    // 验证文件已成功保存
    if (await File(downloadFilePath).exists()) {
      return downloadFilePath;
    } else {
      return '404';
    }
  }

  // 保存图片
  _throwIfDownloadCancelled(qjsTaskGroupKey);
  await saveImage(imageData, downloadFilePath);

  // 验证文件已成功保存
  if (await File(downloadFilePath).exists()) {
    return downloadFilePath;
  } else {
    return '404';
  }
}

String _buildStoredFilePath(
  String basePath,
  String from,
  String path,
  String cartoonId,
  String chapterId, {
  String? rootFolder,
}) {
  final fileName = _sanitizeStoredPath(path);
  final segments = <String>[basePath, (from).trim()];
  if (rootFolder != null && rootFolder.isNotEmpty) {
    segments.add(rootFolder);
  }
  if (cartoonId.trim().isNotEmpty) {
    segments.add(cartoonId.trim());
  }
  if (chapterId.trim().isNotEmpty) {
    segments.add(chapterId.trim());
  }
  segments.add(fileName);
  return file_path.joinAll(segments);
}

String _sanitizeStoredPath(String path) {
  return normalizeStoredAssetPath(path);
}

String normalizeStoredAssetPath(String rawPath, {bool allowEmpty = false}) {
  final raw = rawPath.trim();
  if (raw.isEmpty) {
    if (allowEmpty) {
      return '';
    }
    throw StateError('normalizeStoredAssetPath requires non-empty path');
  }
  final candidate = file_path.isAbsolute(raw) ? file_path.basename(raw) : raw;
  final sanitized = candidate.replaceAll(RegExp(r'[^a-zA-Z0-9_\-.]'), '_');
  if (sanitized.isNotEmpty) {
    return sanitized;
  }
  throw StateError('normalizeStoredAssetPath received invalid path: $rawPath');
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

Future<Uint8List> downloadImageWithRetry(
  String url, {
  required String source,
  bool retry = false,
  int maxRetries = 10,
  String? qjsName,
  String qjsTaskGroupKey = '',
  Map<String, dynamic> extern = const <String, dynamic>{},
}) async {
  var attempts = 0;
  while (true) {
    try {
      attempts += 1;
      _throwIfDownloadCancelled(qjsTaskGroupKey);
      final pluginId = source.trim();
      if (pluginId.isEmpty) {
        throw StateError('downloadImageWithRetry missing plugin id');
      }
      final runtimeName = qjsName?.trim().isNotEmpty == true
          ? qjsName!.trim()
          : pluginId;
      final args = <String, dynamic>{"url": url, "timeoutMs": 30000};
      if (qjsTaskGroupKey.isNotEmpty) {
        args["taskGroupKey"] = qjsTaskGroupKey;
      }
      final externPayload = <String, dynamic>{...extern};
      if (qjsTaskGroupKey.isNotEmpty) {
        externPayload["taskGroupKey"] = qjsTaskGroupKey;
      }
      if (externPayload.isNotEmpty) {
        args["extern"] = externPayload;
      }
      final bytes = await executeQjsFetchImageBytes(
        pluginId: pluginId,
        runtimeName: runtimeName,
        fnPath: 'fetchImageBytes',
        argsJson: jsonEncode(args),
        taskGroupKey: qjsTaskGroupKey.isEmpty ? null : qjsTaskGroupKey,
      );

      return bytes;
    } catch (e) {
      if (_isDownloadTaskCancelledError(e)) {
        throw const DownloadTaskCancelledException();
      }
      if (_isQjsRuntimeCancelledError(e)) {
        throw const DownloadTaskCancelledException();
      }
      logger.w('fetchImageBytes failed source=$source url=$url error=$e');
      final isNotFound =
          (e is DioException && e.toString().contains('422')) ||
          e.toString().contains('404');
      if (isNotFound) {
        logger.w('下载图片资源不存在，跳过: $url');
        rethrow;
      }

      if (e is TimeoutException) {
        logger.e('下载图片超时: $url, 准备重试...($attempts/$maxRetries)');
      } else {
        logger.e('下载图片失败: $e, URL: $url, 准备重试...($attempts/$maxRetries)');
      }

      if (!retry || attempts >= maxRetries) {
        rethrow;
      }

      await _delayWithCancel(
        taskGroupKey: qjsTaskGroupKey,
        duration: const Duration(seconds: 1),
      );
    }
  }
}

bool _isQjsRuntimeCancelledError(Object error) {
  return error.toString().contains(_kQjsRuntimeCancelled);
}

bool _isDownloadTaskCancelledError(Object error) {
  return error.toString().contains(_kDownloadTaskCancelled) ||
      error.toString().contains(downloadTaskCancelledMessage);
}

Future<void> _delayWithCancel({
  required String taskGroupKey,
  required Duration duration,
}) async {
  if (taskGroupKey.isEmpty) {
    await Future.delayed(duration);
    return;
  }
  await raceWithDownloadCancel(taskGroupKey, Future<void>.delayed(duration));
}

Future<void> saveImage(Uint8List imageData, String filePath) async {
  // logger.d('开始保存图片到：$filePath');
  final targetFile = File(filePath);

  try {
    // 验证图片数据不为空
    if (imageData.isEmpty) {
      throw Exception('图片数据为空');
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
    throw Exception('保存图片失败: $e 404');
  }
}

Future<void> ensureDirectoryExists(String filePath) async {
  final directory = Directory(file_path.dirname(filePath));
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
}

Future<void> decodeAndSaveImage(
  Uint8List imgData,
  int chapterId,
  String fileName,
  String url,
) async {
  if (imgData.isEmpty) {
    throw Exception('404');
  }

  final imageInfo = ImageInfo(
    imgData: imgData,
    chapterId: chapterId,
    fileName: fileName,
    url: url,
  );

  try {
    await antiObfuscationPicture(imageInfo: imageInfo);
  } catch (e, s) {
    logger.e(e, stackTrace: s);
    rethrow;
  }
}
