import 'dart:io';

import '../../../main.dart';

Future<void> deleteDirectory(String path) async {
  final directory = Directory(path);

  // 检查目录是否存在
  if (await directory.exists()) {
    try {
      // 删除目录及其内容
      await directory.delete(recursive: true);
      logger.d('目录已成功删除: $path');
    } catch (e) {
      logger.e('删除目录时发生错误: $e');
    }
  } else {
    logger.e('目录不存在: $path');
  }
}
