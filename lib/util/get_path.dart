import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';

// =========================================================
// 平台策略判断
// =========================================================

/// 是否采用“便携式/绿色版”路径策略
bool get _isPortableStrategy => Platform.isWindows;

/// 是否为需要遵循 XDG 或沙盒规范的桌面系统
bool get _isStandardDesktop => Platform.isLinux || Platform.isMacOS;

// =========================================================
// 核心路径获取
// =========================================================

/// 获取应用“逻辑”根目录
Future<String> getAppDirectory() async {
  if (_isPortableStrategy) {
    // Windows: 保持原样 (exe 所在目录)
    return p.dirname(Platform.resolvedExecutable);
  } else if (Platform.isAndroid) {
    // Android: ⚠️ 严禁修改，维持旧逻辑
    final Directory tempDir = await getApplicationSupportDirectory();
    return p.normalize(p.join(tempDir.path, '..'));
  } else {
    // Linux/macOS:
    // macOS: ~/Library/Application Support/com.example.app/
    // Linux: ~/.local/share/com.example.app/
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }
}

/// 获取数据库路径
Future<String> getDbPath() async {
  String dbDirPath;

  if (_isPortableStrategy) {
    final appDir = await getAppDirectory();
    dbDirPath = p.join(appDir, '..', 'db');
  } else if (Platform.isAndroid) {
    // Android: ⚠️ 严禁修改
    final appDir = await getAppDirectory();
    dbDirPath = p.join(appDir, "app_flutter");
  } else {
    // Linux/macOS: 放在 AppSupport/db 下，符合规范
    final appDir = await getAppDirectory();
    dbDirPath = p.join(appDir, "db");
  }

  await _ensureDirExists(dbDirPath);
  return dbDirPath;
}

/// 获取文件存储路径
Future<String> getFilePath() async {
  String path;
  if (_isPortableStrategy) {
    final appDir = await getAppDirectory();
    path = p.join(appDir, '..', 'files');
  } else {
    final appDir = await getAppDirectory();
    path = p.join(appDir, "files");
  }

  await _ensureDirExists(path);
  return path;
}

/// 获取缓存路径
Future<String> getCachePath() async {
  if (_isPortableStrategy) {
    final appDir = await getAppDirectory();
    final path = p.join(appDir, '..', 'cache');
    await _ensureDirExists(path);
    return path;
  } else if (_isStandardDesktop) {
    // macOS/Linux: 使用官方 API 获取专属缓存目录
    // macOS -> ~/Library/Caches/bundle_id
    // Linux -> ~/.cache/bundle_id
    // 避免使用 AppSupport 导致被 Time Machine 备份
    final cacheDir = await getApplicationCacheDirectory();
    await _ensureDirExists(cacheDir.path);
    return cacheDir.path;
  } else {
    // Android/iOS: 使用系统缓存目录
    final tempDir = await getTemporaryDirectory();
    return tempDir.path;
  }
}

/// 获取应用内部下载路径
Future<String> getDownloadPath() async {
  final fileDir = await getFilePath();
  final downloadPath = p.join(fileDir, "downloads");
  await _ensureDirExists(downloadPath);
  return downloadPath;
}

/// 获取日志文件路径
Future<File> getLogPath() async {
  String logDirPath;

  if (_isPortableStrategy) {
    final appDir = await getAppDirectory();
    logDirPath = p.join(appDir, '..', 'log');
  } else if (Platform.isAndroid) {
    final docDir = await getApplicationDocumentsDirectory();
    logDirPath = p.join(docDir.path, 'log');
  } else {
    // macOS/Linux: AppSupport/log 是安全的做法。
    // 注：macOS 极致原生可以放在 ~/Library/Logs/bundle_id，但 path_provider 未直接提供，此处保持原逻辑亦可。
    final appDir = await getAppDirectory();
    logDirPath = p.join(appDir, 'log');
  }

  await _ensureDirExists(logDirPath);

  final logFile = File(p.join(logDirPath, "breeze.log"));
  if (!await logFile.exists()) {
    await logFile.create();
  }
  return logFile;
}

// =========================================================
// 用户导出/下载目录 (createDownloadDir)
// =========================================================

/// 创建/获取用户可见的公开下载目录
Future<String> createDownloadDir() async {
  try {
    // 1. Desktop (Windows/Linux/macOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir != null) {
        final path = p.join(downloadDir.path, appName);
        await _ensureDirExists(path);
        return path;
      }

      // 回退逻辑：避免强解包导致异常
      final home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      if (home != null && home.isNotEmpty) {
        return p.join(home, 'Downloads', appName);
      } else {
        // 如果实在获取不到 HOME 目录，回退到内部文件存储路径
        final fallbackDir = await getFilePath();
        return p.join(fallbackDir, 'Downloads', appName);
      }
    }

    // 2. Android
    if (Platform.isAndroid) {
      const String standardPath = "/storage/emulated/0/Download";
      final String savePath = p.join(standardPath, appName);

      try {
        await _ensureDirExists(savePath);
        return savePath;
      } catch (e) {
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          return externalDir.path;
        }
        rethrow;
      }
    }

    // 3. iOS
    final docDir = await getApplicationDocumentsDirectory();
    return docDir.path;
  } catch (e) {
    logger.e('Create download dir failed: $e');
    rethrow;
  }
}

// =========================================================
// 辅助方法
// =========================================================

Future<void> _ensureDirExists(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}
