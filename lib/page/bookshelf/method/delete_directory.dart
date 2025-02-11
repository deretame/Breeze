import 'dart:io';

import 'package:flutter/material.dart';

Future<void> deleteDirectory(String path) async {
  final directory = Directory(path);

  // 检查目录是否存在
  if (await directory.exists()) {
    try {
      // 删除目录及其内容
      await directory.delete(recursive: true);
      debugPrint('目录已成功删除: $path');
    } catch (e) {
      debugPrint('删除目录时发生错误: $e');
    }
  } else {
    debugPrint('目录不存在: $path');
  }
}
