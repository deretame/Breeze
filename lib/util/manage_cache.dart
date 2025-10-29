import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';

Future<void> manageCacheSize(Cubit setting) async {
  // 获取缓存目录
  final Directory cacheDirectory = await getTemporaryDirectory();
  // logger.d('Cache directory: ${cacheDirectory.path}');

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
    logger.d('Cache size exceeded 1GB, clearing cache...');
    setting.state.setNeedCleanCache(true);
  } else {
    logger.d(
      'Current cache size: ${totalSize / (1024 * 1024)} MB',
    ); // 转换为 MB 输出
    setting.state.setNeedCleanCache(false);
  }
}

Future<void> clearCache(Directory cacheDirectory) async {
  try {
    // 直接删除缓存目录及其所有内容
    await cacheDirectory.delete(recursive: true);
    logger.d('Cache cleared successfully.');
  } catch (e) {
    logger.e('Error clearing cache: $e');
  }
}
