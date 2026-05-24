import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/util/get_path.dart';

Future<void> manageCacheSize(BuildContext context) async {
  if (!context.mounted) return;
  final settinCubit = context.read<GlobalSettingCubit>();
  final currentState = settinCubit.state;

  if (!currentState.cacheSetting.autoCleanCache) {
    logger.d('Auto clean cache disabled, skipping.');
    return;
  }

  final String cachePath = await getCachePath();
  int totalSize = 0;

  try {
    final directory = Directory(cachePath);
    if (!await directory.exists()) return;

    final List<FileSystemEntity> entities = directory.listSync(recursive: true);

    for (var entity in entities) {
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

  final maxSize = currentState.cacheSetting.cacheSizeLimit;
  if (totalSize >= maxSize) {
    logger.d(
      'Cache size exceeded ${maxSize / (1024 * 1024)} MB, clearing cache...',
    );
    settinCubit.updateState(
      (current) => current.copyWith(needCleanCache: true),
    );
  } else {
    logger.d(
      'Current cache size (excluding Sentry): ${totalSize / (1024 * 1024)} MB',
    );
    settinCubit.updateState(
      (current) => current.copyWith(needCleanCache: false),
    );
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
