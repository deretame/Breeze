import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:zephyr/config/global/global.dart';
import 'package:zephyr/main.dart';
// import 'package:zephyr/main.dart'; // 确保 logger 和 appName 可用

// =========================================================
// 平台策略判断
// =========================================================

/// 是否采用“便携式/绿色版”路径策略
/// 仅 Windows 保持此策略，文件生成在 exe 同级或上级目录
bool get _isPortableStrategy => Platform.isWindows;

/// 是否为需要遵循 XDG 或沙盒规范的桌面系统
/// Linux (Flatpak/Deb) 和 macOS (Sandbox)
bool get _isStandardDesktop => Platform.isLinux || Platform.isMacOS;

// =========================================================
// 核心路径获取
// =========================================================

/// 获取应用“逻辑”根目录
/// Windows: exe 所在目录
/// Android: (旧逻辑保持不变) AppSupport 的上一级
/// Linux/macOS: (新逻辑) AppSupport 目录本身
Future<String> getAppDirectory() async {
  if (_isPortableStrategy) {
    // Windows: 保持原样
    return p.dirname(Platform.resolvedExecutable);
  } else if (Platform.isAndroid) {
    // Android: ⚠️ 严禁修改，维持旧逻辑，否则老用户路径会变
    final Directory tempDir = await getApplicationSupportDirectory();
    return p.normalize(p.join(tempDir.path, '..'));
  } else {
    // Linux/macOS: 使用标准的 AppSupport 目录
    // macOS: ~/Library/Application Support/com.example.app/
    // Linux: ~/.local/share/com.example.app/ (或 Flatpak 对应沙盒路径)
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  }
}

/// 获取数据库路径 (⚠️ 核心兼容项)
/// Windows: ../db
/// Android: appDir/app_flutter (保持旧逻辑)
/// Linux/macOS: AppSupport/db (新标准逻辑)
Future<String> getDbPath() async {
  String dbDirPath;

  if (_isPortableStrategy) {
    // Windows: exe -> ../db
    final appDir = await getAppDirectory(); // Windows 下是 exe 目录
    dbDirPath = p.join(appDir, '..', 'db');
  } else if (Platform.isAndroid) {
    // Android: ⚠️ 严禁修改，这是 Flutter 默认旧版路径结构
    final appDir = await getAppDirectory();
    dbDirPath = p.join(appDir, "app_flutter");
  } else {
    // Linux/macOS: 放在 AppSupport/db 下
    // 这样不会污染 Home 目录，且符合 Flatpak/Sandbox 规范
    final appDir = await getAppDirectory();
    dbDirPath = p.join(appDir, "db");
  }

  // 确保目录存在
  await _ensureDirExists(dbDirPath);

  // 仅供调试
  // logger.d("DB Path: $dbDirPath");

  return dbDirPath;
}

/// 获取文件存储路径
/// Windows: ../files
/// Android: appDir/files
/// Linux/macOS: AppSupport/files
Future<String> getFilePath() async {
  String path;
  if (_isPortableStrategy) {
    final appDir = await getAppDirectory();
    path = p.join(appDir, '..', 'files');
  } else {
    // Android/Linux/macOS 统一逻辑：在各自的根目录下创建 files
    // 注意：Android 的 getAppDirectory 已经处理了特殊性
    final appDir = await getAppDirectory();
    path = p.join(appDir, "files");
  }

  await _ensureDirExists(path);
  return path;
}

/// 获取缓存路径
/// Windows: ../cache
/// Android/Linux/macOS: 系统临时目录
Future<String> getCachePath() async {
  if (_isPortableStrategy) {
    final appDir = await getAppDirectory();
    final path = p.join(appDir, '..', 'cache');
    await _ensureDirExists(path);
    return path;
  } else if (_isStandardDesktop) {
    // Linux/macOS: 使用 AppSupport/cache，避免直接用 /tmp 导致遍历权限问题
    final appDir = await getAppDirectory();
    final path = p.join(appDir, 'cache');
    await _ensureDirExists(path);
    return path;
  } else {
    // Android/iOS: 使用系统缓存目录（应用私有，不会有权限问题）
    final tempDir = await getTemporaryDirectory();
    return tempDir.path;
  }
}

/// 获取应用内部下载路径
Future<String> getDownloadPath() async {
  // 统一策略：都在 getFilePath 下建立 downloads 文件夹
  // Windows: ../files/downloads
  // Android: appDir/files/downloads
  // Linux/macOS: AppSupport/files/downloads
  final fileDir = await getFilePath();
  final downloadPath = p.join(fileDir, "downloads");
  await _ensureDirExists(downloadPath);
  return downloadPath;
}

/// 获取日志文件路径
Future<File> getLogPath() async {
  String logDirPath;

  if (_isPortableStrategy) {
    // Windows: ../log
    final appDir = await getAppDirectory();
    logDirPath = p.join(appDir, '..', 'log');
  } else if (Platform.isAndroid) {
    // Android: 文档目录/log (保持原逻辑，方便用户找日志)
    final docDir = await getApplicationDocumentsDirectory();
    logDirPath = p.join(docDir.path, 'log');
  } else {
    // Linux/macOS: AppSupport/log
    // 避免在用户文档目录(Documents)里拉屎，放在 AppSupport 更规范
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
    // 使用 path_provider 的 getDownloadsDirectory，全平台通用且规范
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final downloadDir = await getDownloadsDirectory();
      if (downloadDir != null) {
        final path = p.join(downloadDir.path, appName);
        await _ensureDirExists(path);
        return path;
      }
      // 如果获取失败（极少见），回退到 Home/Downloads
      final home =
          Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
      return p.join(home!, 'Downloads', appName);
    }

    // 2. Android
    // 移除了不稳定的正则解析，直接指向标准路径
    if (Platform.isAndroid) {
      // 标准 Android 下载路径
      const String standardPath = "/storage/emulated/0/Download";
      final String savePath = p.join(standardPath, appName);

      // 尝试创建
      try {
        await _ensureDirExists(savePath);
        return savePath;
      } catch (e) {
        // 如果标准路径失败（极少数魔改ROM），尝试使用 getExternalStorageDirectory 回退
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // 这里的路径通常是 /storage/emulated/0/Android/data/包名/files
          // 虽然不是公开的 Download，但至少能存
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

/// 简化版的目录创建检查
Future<void> _ensureDirExists(String path) async {
  final dir = Directory(path);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
}
