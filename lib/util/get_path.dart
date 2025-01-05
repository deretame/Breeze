import 'dart:io';

import 'package:path_provider/path_provider.dart';

// 获取应用目录
Future<String> getAppDirectory() async {
  // 获取临时目录
  final Directory tempDir = await getTemporaryDirectory();
  // 去掉末尾的cache
  final String filePath = tempDir.path.replaceAll("/cache", "");
  return filePath;
}

// 获取文件路径
Future<String> getFilePath() async {
  // 拼接文件路径
  final String filePath = "${await getAppDirectory()}/files";
  return filePath;
}

// 获取缓存路径
Future<String> getCachePath() async {
  // 拼接文件路径
  final String appCacheDir = "${await getAppDirectory()}/cache";
  return appCacheDir;
}

// 获取文件下载路径
Future<String> getDownloadPath() async {
  // 获取下载目录
  final downloadsDir = "${await getFilePath()}/downloads";
  return downloadsDir; // 返回空字符串或者合适的错误信息
}

// 获取日志目录
Future<File> getLogPath() async {
  String dir = (await getApplicationDocumentsDirectory()).path;
  final String logFileName = "$dir/breeze.log";
  var logFile = File(logFileName);
  if (!await logFile.exists()) {
    await logFile.create(recursive: true);
  }
  final String screenDirName = "$dir/screens";
  final Directory screenDir = Directory(screenDirName);
  if (!await screenDir.exists()) {
    await screenDir.create(recursive: true);
  }
  return logFile;
}
