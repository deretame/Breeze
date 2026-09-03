import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as file_path;
import 'package:zephyr/main.dart';
import 'package:zephyr/network/http/plugin/qjs_download_runtime.dart';
import 'package:zephyr/service/download/download_asset_store.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/type/pipe.dart';
import 'package:zephyr/service/download/download_cancel_signal.dart';
import 'package:zephyr/page/setting/real_sr/service/real_sr_super_resolution.dart';

import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/src/rust/decode/decode.dart';
import 'package:zephyr/util/get_path.dart';

export 'package:zephyr/service/download/download_asset_store.dart'
    show normalizeStoredAssetPath;

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
  bool applyRealSr = true,
  bool usePlugin = true,
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
        if (await directFile.length() > 0) return directPath;
      } catch (_) {}
    }
    return '404';
  }
  if (directPath.isEmpty) {
    return '404';
  }

  final assetStore = DownloadAssetStore(
    from: resolvedFrom,
    path: directPath,
    cartoonId: cartoonId,
    chapterId: chapterId,
    pictureType: pictureType,
  );
  final existing = await assetStore.findExisting();

  if (existing != null) {
    try {
      // 超分 + WebP 转换统一封装，内部会判断分辨率并保留原文件名。
      if (pictureType == PictureType.page && applyRealSr) {
        await RealSrSuperResolution.upscaleAndConvertToWebp(existing.path);
      }
      return existing.path;
    } catch (e) {
      logger.w(
        'getCachePicture: 文件存在但无法访问，删除并重新下载: ${existing.path}',
        error: e,
      );
      try {
        await File(existing.path).delete();
      } catch (deleteError) {
        logger.e(
          'getCachePicture: 删除损坏文件失败: ${existing.path}',
          error: deleteError,
        );
      }
    }
  }

  if (url.isEmpty) {
    throw Exception('404');
  }

  final newCacheFilePath = await assetStore.canonicalCachePath();

  extern = {...?extern};
  extern['priority'] ??= 0;

  final Uint8List imageData;
  if (usePlugin) {
    imageData = await downloadImageWithRetry(
      url,
      source: resolvedFrom,
      extern: extern,
    );
  } else {
    // 插件图标在未安装或禁用插件时也需要加载，不依赖插件运行时。
    final response = await fetch(
      url,
      headers: const {'User-Agent': 'Breeze/1.0'},
    );
    if (!response.ok) {
      throw DownloadPictureHttpException(
        url,
        response.statusText,
        statusCode: response.status,
        responseBodyLength: response.body.length,
      );
    }
    imageData = response.body;
  }

  if (resolvedFrom == _kJmPluginUuid && pictureType == PictureType.page) {
    await decodeAndSaveImage(
      imageData,
      chapterId.let(toInt),
      newCacheFilePath,
      url,
    );
    // 验证文件已成功保存
    if (await File(newCacheFilePath).exists()) {
      if (pictureType == PictureType.page && applyRealSr) {
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
  if (await File(newCacheFilePath).exists() &&
      await File(newCacheFilePath).length() > 0) {
    // 超分 + WebP 转换统一封装，内部会判断分辨率并保留原文件名
    if (pictureType == PictureType.page && applyRealSr) {
      await RealSrSuperResolution.upscaleAndConvertToWebp(newCacheFilePath);
    }
    return newCacheFilePath;
  } else {
    throw Exception('图片保存失败');
  }
}

/// 在不触发下载的前提下，解析图片已存在的本地路径。
///
/// 查找顺序与 [getCachePicture] 的缓存命中分支一致：
/// 绝对路径直查 → 新（编码）缓存/下载路径 → 旧（未编码）缓存/下载路径。
/// 找不到时返回空字符串。用于阅读器预解析图片尺寸等只需要本地文件的场景。
Future<String> findCachedPicturePath({
  required String from,
  String path = '',
  String cartoonId = '1',
  String chapterId = '',
  PictureType pictureType = PictureType.page,
}) async {
  final resolvedFrom = normalizePluginId(from);
  if (resolvedFrom.isEmpty) {
    return '';
  }

  final directPath = path.trim();
  if (directPath.isEmpty) {
    return '';
  }
  final existing = await DownloadAssetStore(
    from: resolvedFrom,
    path: directPath,
    cartoonId: cartoonId,
    chapterId: chapterId,
    pictureType: pictureType,
  ).findExisting();
  return existing?.path ?? '';
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
  bool Function()? shouldRetryUntilSuccess,
  Map<String, dynamic> extern = const <String, dynamic>{},
}) async {
  final result = await downloadPictureResult(
    from: from,
    url: url,
    path: path,
    cartoonId: cartoonId,
    chapterId: chapterId,
    pictureType: pictureType,
    qjsName: qjsName,
    qjsTaskGroupKey: qjsTaskGroupKey,
    retry: retry,
    shouldRetryUntilSuccess: shouldRetryUntilSuccess,
    extern: extern,
  );
  if (result.status == DownloadPictureResultStatus.notFound ||
      result.status == DownloadPictureResultStatus.emptyData ||
      result.status == DownloadPictureResultStatus.failed) {
    return '404';
  }
  return result.path;
}

Future<DownloadPictureResult> downloadPictureResult({
  required String from,
  String url = '',
  String path = '',
  String cartoonId = '1',
  String chapterId = '',
  PictureType pictureType = PictureType.page,
  String? qjsName,
  String qjsTaskGroupKey = '',
  bool retry = false,
  bool Function()? shouldRetryUntilSuccess,
  Map<String, dynamic> extern = const <String, dynamic>{},
}) async {
  final resolvedFrom = normalizePluginId(from);
  if (resolvedFrom.isEmpty) {
    throw StateError('downloadPicture missing pluginId');
  }
  if (url.isEmpty) {
    return const DownloadPictureResult(
      status: DownloadPictureResultStatus.notFound,
    );
  }
  if (url.contains("404")) {
    return const DownloadPictureResult(
      status: DownloadPictureResultStatus.notFound,
    );
  }

  if (path.trim().isEmpty) {
    return const DownloadPictureResult(
      status: DownloadPictureResultStatus.notFound,
    );
  }

  final assetStore = DownloadAssetStore(
    from: resolvedFrom,
    path: path,
    cartoonId: cartoonId,
    chapterId: chapterId,
    pictureType: pictureType,
  );
  final existing = await assetStore.findExisting();
  if (existing != null) {
    try {
      if (existing.location == DownloadAssetLocation.canonicalCache) {
        final canonicalDownloadPath = await assetStore.canonicalDownloadPath();
        await assetStore.copyFileAtomically(
          sourcePath: existing.path,
          finalPath: canonicalDownloadPath,
          taskId: qjsTaskGroupKey,
        );
        return DownloadPictureResult(
          status: DownloadPictureResultStatus.downloaded,
          path: canonicalDownloadPath,
          location: DownloadAssetLocation.canonicalDownload,
        );
      }
      return DownloadPictureResult(
        status: DownloadPictureResultStatus.existing,
        path: existing.path,
        location: existing.location,
      );
    } catch (e) {
      logger.w('downloadPicture: 已存在文件不可复用，准备重新下载: ${existing.path}', error: e);
      try {
        await File(existing.path).delete();
      } catch (deleteError) {
        logger.e(
          'downloadPicture: 删除不可复用文件失败: ${existing.path}',
          error: deleteError,
        );
      }
    }
  }

  Uint8List imageData;
  try {
    imageData = await downloadImageWithRetry(
      url,
      source: resolvedFrom,
      retry: retry,
      shouldRetryUntilSuccess: shouldRetryUntilSuccess,
      qjsName: qjsName,
      qjsTaskGroupKey: qjsTaskGroupKey,
      extern: extern,
      maxRetries: 10,
    );
  } catch (e) {
    if (_isDownloadTaskCancelledError(e) || _isQjsRuntimeCancelledError(e)) {
      rethrow;
    }
    if (e is DownloadPictureNotFoundException) {
      logger.w('下载图片资源不存在: source=$resolvedFrom url=$url');
      return DownloadPictureResult(
        status: DownloadPictureResultStatus.notFound,
        error: e,
      );
    }
    if (e is DownloadPictureEmptyDataException) {
      logger.w('下载图片返回空数据: source=$resolvedFrom url=$url');
      return DownloadPictureResult(
        status: DownloadPictureResultStatus.emptyData,
        error: e,
      );
    }
    logger.w('downloadPicture failed source=$resolvedFrom url=$url', error: e);
    return DownloadPictureResult(
      status: DownloadPictureResultStatus.failed,
      error: e,
    );
  }

  _throwIfDownloadCancelled(qjsTaskGroupKey);

  final downloadFilePath = await assetStore.canonicalDownloadPath();

  try {
    if (resolvedFrom == _kJmPluginUuid && pictureType == PictureType.page) {
      await decodeAndSaveImage(
        imageData,
        chapterId.let(toInt),
        downloadFilePath,
        url,
        taskId: qjsTaskGroupKey,
      );
    } else {
      await saveImage(imageData, downloadFilePath, taskId: qjsTaskGroupKey);
    }
  } catch (e) {
    if (_isDownloadTaskCancelledError(e) || _isQjsRuntimeCancelledError(e)) {
      rethrow;
    }
    logger.w(
      'downloadPicture save failed source=$resolvedFrom url=$url',
      error: e,
    );
    return DownloadPictureResult(
      status: DownloadPictureResultStatus.failed,
      error: e,
    );
  }

  _throwIfDownloadCancelled(qjsTaskGroupKey);
  final finalFile = File(downloadFilePath);
  if (!await finalFile.exists() || await finalFile.length() <= 0) {
    return const DownloadPictureResult(
      status: DownloadPictureResultStatus.failed,
    );
  }
  if (pictureType == PictureType.page) {
    await RealSrSuperResolution.upscaleAndConvertToWebp(downloadFilePath);
  }
  return DownloadPictureResult(
    status: DownloadPictureResultStatus.downloaded,
    path: downloadFilePath,
    location: DownloadAssetLocation.canonicalDownload,
  );
}

/// 删除漫画下载根目录。
///
/// 为兼容新旧下载布局，先尝试删除编码后的路径，再尝试删除原始路径。
Future<void> deleteComicDownloadDirectory(
  String from,
  String comicId, {
  String? legacyStorageRoot,
}) async {
  final legacyRoot = legacyStorageRoot?.trim() ?? '';
  if (legacyRoot.isNotEmpty && file_path.isAbsolute(legacyRoot)) {
    try {
      final legacyDirectory = Directory(legacyRoot);
      if (legacyDirectory.existsSync()) {
        legacyDirectory.deleteSync(recursive: true);
      }
    } catch (e) {
      logger.w('同步删除历史下载目录失败: $legacyRoot', error: e);
    }
  }

  final downloadRoot = await getDownloadPath();
  String? encodedRoot;
  try {
    encodedRoot = await _buildComicDownloadRoot(from, comicId, encoded: true);
  } catch (e) {
    // 删除历史原始路径不应依赖 Rust bridge；这也让纯 Dart 测试和
    // 尚未初始化 Rust 的早期生命周期仍能清理旧下载目录。
    logger.d('生成编码下载目录失败，继续清理原始目录: $comicId, error=$e');
  }
  final rawRoot = await _buildComicDownloadRoot(from, comicId, encoded: false);

  if (encodedRoot != null &&
      DownloadAssetStore.isWithinRoot(downloadRoot, encodedRoot)) {
    await _tryDeleteDirectory(encodedRoot);
  }
  if (DownloadAssetStore.isWithinRoot(downloadRoot, rawRoot)) {
    await _tryDeleteDirectory(rawRoot);
  } else {
    logger.w('跳过越界的历史下载目录删除: $rawRoot');
  }

  // 旧记录可能保存了当前平台之外的绝对 storageRoot。正常读取不依赖它；
  // 删除下载记录时，如果调用方明确传入且该目录仍存在，则兼容清理这个
  // 历史目录，避免旧版本导入的数据留下孤立文件。
}

Future<String> _buildComicDownloadRoot(
  String from,
  String comicId, {
  required bool encoded,
}) async {
  return file_path.join(
    await getDownloadPath(),
    normalizePluginId(from),
    'original',
    encoded ? encodePath(path: comicId.trim()) : comicId.trim(),
  );
}

Future<void> _tryDeleteDirectory(String path) async {
  final dir = Directory(path);
  if (await dir.exists()) {
    try {
      await dir.delete(recursive: true);
    } catch (e) {
      logger.w('删除目录失败: $path, error: $e');
    }
  }
}

Future<Uint8List> downloadImageWithRetry(
  String url, {
  required String source,
  bool retry = false,
  int maxRetries = 10,
  bool Function()? shouldRetryUntilSuccess,
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
      final result = await executeQjsFetchImageResult(
        pluginId: pluginId,
        runtimeName: runtimeName,
        fnPath: 'fetchImageBytes',
        argsJson: jsonEncode(args),
        taskGroupKey: qjsTaskGroupKey.isEmpty ? null : qjsTaskGroupKey,
      );

      if (result.error != null) {
        throw DownloadPictureHttpException(
          url,
          result.error!,
          statusCode: result.statusCode,
          responseBodyLength: result.responseBodyLength,
        );
      }

      final statusCode = result.statusCode;
      if (statusCode == 404 || statusCode == 422) {
        throw DownloadPictureNotFoundException(
          url,
          DownloadPictureHttpException(
            url,
            'HTTP $statusCode',
            statusCode: statusCode,
            responseBodyLength: result.responseBodyLength,
          ),
        );
      }
      if (statusCode != null && (statusCode < 200 || statusCode >= 300)) {
        throw DownloadPictureHttpException(
          url,
          'HTTP $statusCode',
          statusCode: statusCode,
          responseBodyLength: result.responseBodyLength,
        );
      }

      final bytes = result.bytes;
      if (bytes.isEmpty) {
        throw DownloadPictureEmptyDataException(url);
      }

      return bytes;
    } catch (e) {
      if (_isDownloadTaskCancelledError(e)) {
        throw const DownloadTaskCancelledException();
      }
      if (_isQjsRuntimeCancelledError(e)) {
        throw const DownloadTaskCancelledException();
      }
      if (e is DownloadPictureEmptyDataException) {
        logger.w('下载图片返回空数据，停止重试: $url');
        rethrow;
      }
      if (e is DownloadPictureHttpException) {
        if (e.statusCode == 404 || e.statusCode == 422) {
          logger.w('下载图片资源不存在，跳过: $url');
          throw DownloadPictureNotFoundException(url, e);
        }
        logger.w(
          '图片请求失败，将按重试策略处理: $url '
          '(status=${e.statusCode}, bodyLength=${e.responseBodyLength})',
          error: e,
        );
      }
      logger.w('fetchImageBytes failed source=$source url=$url error=$e');
      final errText = e.toString();
      final isNotFound = e is DownloadPictureHttpException
          ? e.statusCode == 404 || e.statusCode == 422
          : errText.contains('422') || errText.contains('404');
      if (isNotFound) {
        logger.w('下载图片资源不存在，跳过: $url');
        throw DownloadPictureNotFoundException(url, e);
      }

      if (e is TimeoutException) {
        logger.e('下载图片超时: $url, 准备重试...($attempts/$maxRetries)');
      } else {
        logger.e('下载图片失败: $e, URL: $url, 准备重试...($attempts/$maxRetries)');
      }

      final retryForever = shouldRetryUntilSuccess?.call() ?? false;
      if ((!retry && !retryForever) ||
          (!retryForever && attempts >= maxRetries)) {
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

enum DownloadPictureResultStatus {
  existing,
  downloaded,
  notFound,
  emptyData,
  failed,
}

class DownloadPictureResult {
  const DownloadPictureResult({
    required this.status,
    this.path = '',
    this.location,
    this.error,
  });

  final DownloadPictureResultStatus status;
  final String path;
  final DownloadAssetLocation? location;
  final Object? error;

  bool get isSuccess =>
      status == DownloadPictureResultStatus.existing ||
      status == DownloadPictureResultStatus.downloaded;
}

class DownloadPictureNotFoundException implements Exception {
  const DownloadPictureNotFoundException(this.url, [this.cause]);

  final String url;
  final Object? cause;

  @override
  String toString() => '图片资源不存在: $url';
}

class DownloadPictureHttpException implements Exception {
  const DownloadPictureHttpException(
    this.url,
    this.message, {
    this.statusCode,
    this.responseBodyLength,
  });

  final String url;
  final String message;
  final int? statusCode;
  final int? responseBodyLength;

  @override
  String toString() {
    final status = statusCode == null ? '' : ' HTTP $statusCode';
    final bodyLength = responseBodyLength?.toString() ?? '未知';
    return '图片请求失败$status (响应体 $bodyLength 字节): $url: $message';
  }
}

class DownloadPictureEmptyDataException implements Exception {
  const DownloadPictureEmptyDataException(this.url);

  final String url;

  @override
  String toString() => '图片下载返回空数据: $url';
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

Future<void> saveImage(
  Uint8List imageData,
  String filePath, {
  String taskId = '',
}) async {
  try {
    await DownloadAssetStore.writeBytesAtomically(
      imageData,
      finalPath: filePath,
      taskId: taskId,
    );
  } catch (e) {
    logger.e('保存图片失败: $filePath', error: e);
    rethrow;
  }
}

Future<void> ensureDirectoryExists(String filePath) async {
  await DownloadAssetStore.ensureParentDirectory(filePath);
}

Future<void> decodeAndSaveImage(
  Uint8List imgData,
  int chapterId,
  String fileName,
  String url, {
  String taskId = '',
}) async {
  if (imgData.isEmpty) {
    throw StateError('图片数据为空');
  }

  final temporaryPath = DownloadAssetStore.temporaryPathFor(
    fileName,
    taskId: taskId,
  );
  final imageInfo = ImageInfo(
    imgData: imgData,
    chapterId: chapterId,
    fileName: temporaryPath,
    url: url,
  );

  try {
    await antiObfuscationPicture(imageInfo: imageInfo);
    await DownloadAssetStore.commitTemporaryFile(temporaryPath, fileName);
  } catch (e, s) {
    try {
      final temporaryFile = File(temporaryPath);
      if (await temporaryFile.exists()) await temporaryFile.delete();
    } catch (_) {}
    logger.e(e, stackTrace: s);
    rethrow;
  }
}
