import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as file_path;
import 'package:zephyr/main.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/util/download/download_cancel_signal.dart';
import 'package:zephyr/util/download/qjs_download_runtime.dart';

import '../../../src/rust/api/simple.dart';
import '../../../src/rust/decode/decode.dart';
import '../../../util/get_path.dart';

final pictureDio = Dio();
const _kQjsRuntimeCancelled = '__QJS_RUNTIME_CANCELLED__';
const _kDownloadTaskCancelled = '__DOWNLOAD_TASK_CANCELLED__';
const _kJmScrambleId = 220980;
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
  PictureType pictureType = PictureType.comic,
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
  final storedChapterId = _resolveStoredChapterId(chapterId, pictureType);

  final cacheFilePath = _buildStoredFilePath(
    cachePath,
    resolvedFrom,
    path,
    cartoonId,
    storedChapterId,
  );

  final downloadFilePath = _buildStoredFilePath(
    downloadPath,
    resolvedFrom,
    path,
    cartoonId,
    storedChapterId,
    rootFolder: 'original',
  );

  // logger.d(
  //   'getCachePicture: cacheFilePath=$cacheFilePath, downloadFilePath=$downloadFilePath',
  // );

  final existingFilePath = await checkFileExists(
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

  if (url.isEmpty) {
    throw Exception('404');
  }

  final imageData = await downloadImageWithRetry(url, source: resolvedFrom);

  if (resolvedFrom == _kJmPluginUuid && pictureType == PictureType.page) {
    await decodeAndSaveImage(
      imageData,
      int.tryParse(chapterId) ?? 0,
      _kJmScrambleId,
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
  required String from,
  String url = '',
  String cartoonId = '',
  String chapterId = '',
  String path = '',
  PictureType pictureType = PictureType.comic,
  String? qjsName,
  String qjsTaskGroupKey = '',
}) async {
  final resolvedFrom = normalizePluginId(from);
  if (resolvedFrom.isEmpty) {
    throw StateError('downloadPicture missing pluginId');
  }
  if (url.isEmpty) {
    throw Exception('URL 不能为空 404');
  }
  if (url.contains("404")) {
    return "404";
  }
  final directPath = path.trim();
  if (directPath.isEmpty) {
    return '404';
  }

  final downloadPath = await getDownloadPath();
  final cachePath = await getCachePath();
  final storedChapterId = _resolveStoredChapterId(chapterId, pictureType);

  final cacheFilePath = _buildStoredFilePath(
    cachePath,
    resolvedFrom,
    path,
    cartoonId,
    storedChapterId,
    rootFolder: 'original',
  );

  final downloadFilePath = _buildStoredFilePath(
    downloadPath,
    resolvedFrom,
    path,
    cartoonId,
    storedChapterId,
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

  Uint8List imageData = await downloadImageWithRetry(
    url,
    source: resolvedFrom,
    qjsName: qjsName,
    qjsTaskGroupKey: qjsTaskGroupKey,
  );

  _throwIfDownloadCancelled(qjsTaskGroupKey);

  if (resolvedFrom == _kJmPluginUuid && pictureType == PictureType.page) {
    await decodeAndSaveImage(
      imageData,
      int.tryParse(chapterId) ?? 0,
      _kJmScrambleId,
      downloadFilePath,
      url,
    );

    _throwIfDownloadCancelled(qjsTaskGroupKey);

    // 验证文件已成功保存
    if (await File(downloadFilePath).exists()) {
      return downloadFilePath;
    } else {
      throw Exception('图片保存失败');
    }
  }

  // 保存图片
  _throwIfDownloadCancelled(qjsTaskGroupKey);
  await saveImage(imageData, downloadFilePath);

  // 验证文件已成功保存
  if (await File(downloadFilePath).exists()) {
    return downloadFilePath;
  } else {
    throw Exception('图片保存失败');
  }
}

String _resolveStoredChapterId(String chapterId, PictureType pictureType) {
  if (pictureType == PictureType.cover) {
    return '';
  }
  return chapterId;
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

Future<String?> getStoredPicturePathById({
  required String from,
  required String cartoonId,
  String chapterId = '',
  required String imageId,
  String rootFolder = 'original',
}) async {
  if (imageId.trim().isEmpty) {
    return null;
  }

  final basePath = await getDownloadPath();
  final pluginId = normalizePluginId(from);
  final baseSegments = <String>[basePath, pluginId];
  final legacyBaseSegments = <String>[basePath, from];
  if (rootFolder.trim().isNotEmpty) {
    baseSegments.add(rootFolder.trim());
  }
  if (cartoonId.trim().isNotEmpty) {
    baseSegments.add(cartoonId.trim());
  }

  final candidateDirs = <Directory>[];
  if (chapterId.trim().isNotEmpty) {
    candidateDirs.add(
      Directory(file_path.joinAll([...baseSegments, chapterId.trim()])),
    );
    candidateDirs.add(
      Directory(file_path.joinAll([...legacyBaseSegments, chapterId.trim()])),
    );
    candidateDirs.add(
      Directory(
        file_path.joinAll([...baseSegments, 'comic', chapterId.trim()]),
      ),
    );
    candidateDirs.add(
      Directory(
        file_path.joinAll([...legacyBaseSegments, 'comic', chapterId.trim()]),
      ),
    );
  } else {
    candidateDirs.add(Directory(file_path.joinAll(baseSegments)));
    candidateDirs.add(Directory(file_path.joinAll(legacyBaseSegments)));
  }

  for (final dir in candidateDirs) {
    if (!await dir.exists()) {
      continue;
    }
    final entries = await dir
        .list()
        .where((e) => e is File)
        .cast<File>()
        .toList();
    entries.sort((a, b) => a.path.compareTo(b.path));
    for (final file in entries) {
      if (file_path.basenameWithoutExtension(file.path) == imageId) {
        return file.path;
      }
    }
  }
  return null;
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
  String? qjsName,
  String qjsTaskGroupKey = '',
}) async {
  while (true) {
    try {
      final pluginId = source.trim();
      if (pluginId.isEmpty) {
        throw StateError('downloadImageWithRetry missing plugin id');
      }
      final runtimeName = qjsName?.trim().isNotEmpty == true
          ? qjsName!.trim()
          : pluginId;
      final bytes = await executeQjsFetchImageBytes(
        pluginId: pluginId,
        runtimeName: runtimeName,
        fnPath: 'fetchImageBytes',
        argsJson: jsonEncode({"url": url, "timeoutMs": 30000}),
        taskGroupKey: qjsTaskGroupKey.isEmpty ? null : qjsTaskGroupKey,
      );

      return bytes;
    } catch (e) {
      logger.w('fetchImageBytes failed source=$source url=$url error=$e');
      if (_isQjsRuntimeCancelledError(e)) {
        throw Exception(_kDownloadTaskCancelled);
      }
      if (e is TimeoutException) {
        logger.e('下载图片超时: $url, 准备重试...');
      } else if (e is DioException && e.toString().contains('422')) {
        logger.e('下载图片遇到 422 错误 (当作 404 处理): $url');
        throw Exception('404');
      } else {
        logger.e('下载图片失败: $e, URL: $url');
        if (!retry) {
          rethrow;
        }
      }
      if (retry && !(e is DioException && e.toString().contains('422'))) {
        await Future.delayed(const Duration(seconds: 1));
      } else if (!retry) {
        rethrow;
      }
    }
  }
}

bool _isQjsRuntimeCancelledError(Object error) {
  return error.toString().contains(_kQjsRuntimeCancelled);
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
    throw Exception('保存图片失败: $e 404');
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
