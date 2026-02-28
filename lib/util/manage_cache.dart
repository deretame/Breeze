import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/get_path.dart';

Future<void> manageCacheSize(BuildContext context) async {
  final String cachePath = await getCachePath();
  int totalSize = 0;

  try {
    final directory = Directory(cachePath);
    if (!await directory.exists()) return;

    // 1. 使用 listSync 获取文件，并立即过滤掉 sentry 目录
    final List<FileSystemEntity> entities = directory.listSync(recursive: true);

    for (var entity in entities) {
      // 检查路径是否包含 'sentry'（不区分大小写）
      final bool isSentryFile = entity.path
          .split(Platform.pathSeparator)
          .contains('sentry');

      if (entity is File && !isSentryFile) {
        try {
          totalSize += await entity.length();
        } on FileSystemException {
          continue;
        }
      }
    }
  } catch (e) {
    logger.e('Error calculating cache size: $e');
  }

  if (!context.mounted) return;
  final settinCubit = context.read<GlobalSettingCubit>();

  const int maxSize = 1 * 1024 * 1024 * 1024; // 1GB
  if (totalSize >= maxSize) {
    logger.d('Cache size exceeded 1GB, clearing cache...');
    settinCubit.updateNeedCleanCache(true);
  } else {
    logger.d(
      'Current cache size (excluding Sentry): ${totalSize / (1024 * 1024)} MB',
    );
    settinCubit.updateNeedCleanCache(false);
  }
}

Future<void> clearCache(String cachePath) async {
  try {
    final directory = Directory(cachePath);
    if (!await directory.exists()) return;

    // 2. 清理时不能直接 delete(recursive: true)，否则 sentry 文件夹也会被删
    // 我们需要遍历并删除非 sentry 的内容
    final List<FileSystemEntity> entities = directory.listSync(
      recursive: false,
    );

    for (var entity in entities) {
      final String name = entity.path.split(Platform.pathSeparator).last;
      if (name != 'sentry') {
        // 删除文件或文件夹（递归）
        await entity.delete(recursive: true);
      }
    }
    logger.d('Cache cleared successfully (Sentry folder preserved).');
  } catch (e) {
    logger.e('Error clearing cache: $e');
  }
}
