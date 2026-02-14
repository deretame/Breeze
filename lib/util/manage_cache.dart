import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';

import '../main.dart';
import 'get_path.dart';

Future<void> manageCacheSize(BuildContext context) async {
  // 获取缓存目录
  final String cachePath = await getCachePath();
  // logger.d('Cache directory: ${cacheDirectory.path}');

  // 创建一个变量来保存总大小
  int totalSize = 0;

  // 遍历缓存目录中的所有文件
  final List<FileSystemEntity> files = Directory(
    cachePath,
  ).listSync(recursive: true);
  for (var file in files) {
    if (file is File) {
      // 如果是文件，则获取其大小并累加
      totalSize += await file.length();
    }
  }

  if (!context.mounted) return;

  final settinCubit = context.read<GlobalSettingCubit>();

  // 检查总大小是否达到 1GB (1GB = 1024 * 1024 * 1024 bytes)
  const int maxSize = 1 * 1024 * 1024 * 1024; // 1GB
  if (totalSize >= maxSize) {
    logger.d('Cache size exceeded 1GB, clearing cache...');
    settinCubit.updateNeedCleanCache(true);
  } else {
    logger.d(
      'Current cache size: ${totalSize / (1024 * 1024)} MB',
    ); // 转换为 MB 输出
    settinCubit.updateNeedCleanCache(false);
  }
}

Future<void> clearCache(String cachePath) async {
  try {
    // 直接删除缓存目录及其所有内容
    await Directory(cachePath).delete(recursive: true);
    logger.d('Cache cleared successfully.');
  } catch (e) {
    logger.e('Error clearing cache: $e');
  }
}
