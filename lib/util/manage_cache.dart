import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';

Future<void> manageCacheSize() async {
  // 获取缓存目录
  final Directory cacheDirectory = await getTemporaryDirectory();

  // 创建一个变量来保存总大小
  int totalSize = 0;

  // 遍历缓存目录中的所有文件
  final List<FileSystemEntity> files = cacheDirectory.listSync(recursive: true);
  for (var file in files) {
    if (file is File) {
      // 如果是文件，则获取其大小并累加
      totalSize += await file.length();
    }
  }

  // 检查总大小是否达到 1GB (1GB = 1024 * 1024 * 1024 bytes)
  const int maxSize = 1 * 1024 * 1024 * 1024; // 1GB
  if (totalSize >= maxSize) {
    debugPrint('Cache size exceeded 1GB, clearing cache...');
    await clearCache(cacheDirectory);
  } else {
    debugPrint(
        'Current cache size: ${totalSize / (1024 * 1024)} MB'); // 转换为 MB 输出
  }
}

Future<void> clearCache(Directory cacheDirectory) async {
  // 遍历并删除缓存目录中的所有文件
  try {
    final List<FileSystemEntity> files =
        cacheDirectory.listSync(recursive: true);
    for (var file in files) {
      if (file is File) {
        await file.delete();
      } else if (file is Directory) {
        await file.delete(recursive: true);
      }
    }
    debugPrint('Cache cleared successfully.');
  } catch (e) {
    debugPrint('Error clearing cache: $e');
  }
}
