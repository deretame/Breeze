import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';

// 简化的平台判断属性
bool get isDesktop =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// [核心辅助方法]
/// 传入 desktopPathName (桌面端相对 exe 的父级目录名)
/// 传入 mobileBaseDir (移动端基准目录) 和 mobileSubPath (移动端子路径)
/// 自动处理目录创建逻辑
Future<String> _ensureDir({
  required String desktopName,
  required Future<Directory> Function() mobileBaseDirInfo,
  String? mobileSubPath,
}) async {
  String dirPath;

  if (isDesktop) {
    // Desktop: 统一都在可执行文件上级目录的同级创建 (Portable 风格)
    // 结构: /bin/app.exe -> /data/files
    final exeDir = p.dirname(Platform.resolvedExecutable);
    dirPath = p.join(exeDir, '..', desktopName);
  } else {
    // Mobile: 基于 path_provider 获取基准目录
    final baseDir = await mobileBaseDirInfo();
    dirPath = mobileSubPath != null
        ? p.join(baseDir.path, mobileSubPath)
        : baseDir.path;
  }

  // 统一逻辑：如果不存在则创建
  final directory = Directory(dirPath);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return dirPath;
}

// ---------------------------------------------------------

// 获取应用根目录
Future<String> getAppDirectory() async {
  if (isDesktop) {
    return p.dirname(Platform.resolvedExecutable);
  }
  final Directory tempDir = await getApplicationSupportDirectory();
  return p.normalize(p.join(tempDir.path, '..'));
}

// 获取文件存储路径
// Desktop: ../files
// Mobile: appDir/files
Future<String> getFilePath() async {
  if (!isDesktop) {
    final appDir = await getAppDirectory();
    final path = p.join(appDir, "files");
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return path;
  }

  return _ensureDir(
    desktopName: "files",
    mobileBaseDirInfo: getApplicationSupportDirectory,
  );
}

// 获取缓存路径
// Desktop: ../cache
// Mobile: tempDir
Future<String> getCachePath() async {
  return _ensureDir(
    desktopName: "cache",
    mobileBaseDirInfo: getTemporaryDirectory,
    mobileSubPath: null,
  );
}

// 获取文件下载路径
// Desktop: ../downloads
// Mobile: files/downloads
Future<String> getDownloadPath() async {
  if (isDesktop) {
    return _ensureDir(
      desktopName: "downloads",
      mobileBaseDirInfo: getTemporaryDirectory,
    );
  } else {
    final fileDir = await getFilePath();
    final downloadPath = p.join(fileDir, "downloads");
    final dir = Directory(downloadPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return downloadPath;
  }
}

// 获取数据库路径
// Desktop: ../db
// Mobile: appDir/app_flutter
Future<String> getDbPath() async {
  if (isDesktop) {
    return _ensureDir(
      desktopName: "db",
      mobileBaseDirInfo: getApplicationSupportDirectory,
    );
  } else {
    final appDir = await getAppDirectory();
    final dbPath = p.join(appDir, "app_flutter");
    final dir = Directory(dbPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    logger.d(dbPath);
    return dbPath;
  }
}

// 获取日志文件路径
// Desktop: ../log/breeze.log
// Mobile: Documents/log/breeze.log
Future<File> getLogPath() async {
  final String logDir = await _ensureDir(
    desktopName: "log",
    mobileBaseDirInfo: getApplicationDocumentsDirectory,
    mobileSubPath: "log",
  );

  final String logFileName = p.join(logDir, "breeze.log");

  final logFile = File(logFileName);
  if (!await logFile.exists()) {
    await logFile.create();
  }

  return logFile;
}

/// 创建下载目录
Future<String> createDownloadDir() async {
  try {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final downloadDir = await getDownloadsDirectory();
      return p.join(downloadDir!.path, appName);
    }

    // 获取外部存储目录
    Directory? externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      logger.d('downloadPath: ${externalDir.path}');
    }

    // 检查 externalDir 是否为 null
    if (externalDir == null) {
      throw Exception('无法获取外部存储目录');
    }

    // 尝试从路径中提取用户ID
    RegExp regExp = RegExp(r'/(\d+)/');
    Match? match = regExp.firstMatch(externalDir.path);

    // 安全地提取用户ID，如果匹配失败则使用默认值
    String userId = '0';
    if (match != null && match.groupCount >= 1) {
      final extractedUserId = match.group(1);
      if (extractedUserId != null) {
        userId = extractedUserId;
      } else {
        logger.w('无法提取用户ID，使用默认值: 0');
      }
    } else {
      logger.w('路径格式不匹配，使用默认用户ID: 0，路径: ${externalDir.path}');
    }

    String filePath = "/storage/emulated/$userId/Download/$appName";

    // 使用path库来确保路径的正确性
    final dir = Directory(filePath);

    // 检查目录是否存在
    bool dirExists = await dir.exists();
    if (!dirExists) {
      // 如果目录不存在，则创建它
      try {
        await dir.create(recursive: true); // recursive设置为true可以创建所有必要的父目录
        logger.d('Directory created: $filePath');
      } catch (e) {
        logger.e('Failed to create directory: $e');
        rethrow;
      }
    }

    return filePath;
  } catch (e) {
    logger.e(e);
    rethrow;
  }
}
