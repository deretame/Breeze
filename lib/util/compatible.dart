// 用来提供兼容操作的

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/util/get_path.dart';
import 'package:zephyr/util/sundry.dart';

Future<void> compatibleInit() async {
  final basePath = await getFilePath();
  final compatiblePath = p.join(basePath, 'compatible');
  // 检查目录是否存在，如果不存在则创建
  if (!await Directory(compatiblePath).exists()) {
    await Directory(compatiblePath).create(recursive: true);
  }
  final data = {"compatible_version": "v1"}.toJson();
  final compatibleFile = File(p.join(compatiblePath, 'compatible.json'));
  await compatibleFile.writeAsString(data);
}
