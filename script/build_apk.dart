#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:async'; // 导入 'dart:async'
import 'dart:convert';
import 'dart:io';

// ... (ANSI 颜色代码 ...
const String _green = '\x1B[32m';
const String _cyan = '\x1B[36m';
const String _red = '\x1B[31m';
const String _yellow = '\x1B[33m';
const String _magenta = '\x1B[35m';
const String _reset = '\x1B[0m';

Process? _currentProcess; // 用于跟踪当前运行的子进程

bool _isRestored = false;

/// 彩色打印
void _printColor(String text, String color) {
  print('$color$text$_reset');
}

/// 帮助函数：运行一个进程并流式传输其输出
///
/// [runInShell: true] 对于在 Windows 上正确执行 .bat 文件至关重要
/// 返回进程的退出代码
Future<int> _runCommand(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: true, // 确保 .bat 文件能正确执行
  );
  _currentProcess = process; // 存储当前进程

  // 实时转发子进程的标准输出和错误
  process.stdout.transform(utf8.decoder).listen(stdout.write);
  process.stderr.transform(utf8.decoder).listen(stderr.write);

  final exitCode = await process.exitCode;
  _currentProcess = null; // 进程结束后清除
  return exitCode;
}

/// 跨平台强力杀进程函数
Future<void> _killProcessTree(Process process) async {
  final pid = process.pid;

  if (Platform.isWindows) {
    // Windows: 使用 taskkill 杀进程树
    try {
      await Process.run('taskkill', ['/F', '/T', '/PID', pid.toString()]);
    } catch (e) {
      _printColor('Windows 杀进程失败: $e', _red);
    }
  } else {
    // Unix (Linux/macOS):
    // runInShell: true 会启动一个 shell (sh/bash/zsh) 作为父进程。
    // 我们不仅要杀掉 shell，还要杀掉 shell 启动的子进程 (如 java/gradle)。
    try {
      // 1. 尝试使用 pkill -P <pid> 杀掉该 PID 的所有子进程
      await Process.run('pkill', ['-P', pid.toString()]);
    } catch (e) {
      // pkill 可能不存在或失败，忽略
      print('pkill 失败: $e');
    }

    // 2. 杀掉当前的 Shell 进程本身
    process.kill(ProcessSignal.sigkill);

    // 3. (可选保险措施) 如果知道 gradlew 会启动 java，
    // 有时候在极端情况下可能需要 killall java，但这样做太暴力，容易误伤，
    // 通常 pkill -P 配合 sigkill 已经足够。
  }
}

/// --- 1. 初始化路径 ---
Future<Map<String, dynamic>> _initializePaths() async {
  final sep = Platform.pathSeparator;
  // 假定此脚本位于 project_root/tool/build.dart
  final String scriptPath = Platform.script.toFilePath();
  final String scriptDir = Directory(scriptPath).parent.path;
  // 项目根目录 (tool 目录的上一级)
  final String projectRoot = Directory(scriptDir).parent.path;

  const String flutterExecutable = 'flutter';

  // AndroidManifest.xml 路径
  final String manifestPath =
      "$projectRoot${sep}android${sep}app${sep}src${sep}main${sep}AndroidManifest.xml";

  // 备份文件路径
  final String backupPath = "$manifestPath.bak";

  // 输出目录
  final String releaseDirPath =
      "$projectRoot${sep}build${sep}app${sep}outputs${sep}apk${sep}release";
  final String skiaDirPath =
      "$projectRoot${sep}build${sep}app${sep}outputs${sep}apk${sep}skia";

  // 符号脚本路径
  final String symbolsScriptFolderPath = "$projectRoot${sep}symbols";
  // --- 修改 ---
  // 将脚本从 .ps1 更改为 .dart
  // 假设你已经将 `update_symbols.dart` (在右侧编辑器中) 放在了 `project_root/symbols/` 目录下
  final String symbolsScriptPath =
      "$symbolsScriptFolderPath${sep}update_symbols.dart";

  return {
    'sep': sep,
    'projectRoot': projectRoot,
    'flutterExecutable': flutterExecutable,
    'manifestFile': File(manifestPath),
    'backupFile': File(backupPath),
    'releaseDir': Directory(releaseDirPath),
    'skiaDir': Directory(skiaDirPath),
    'symbolsScriptFolderPath': symbolsScriptFolderPath,
    'symbolsScriptPath': symbolsScriptPath,
  };
}

/// 核心修复：幂等恢复函数
/// 这个函数可以被安全地调用多次，但只会执行一次恢复操作
Future<void> _performRestore(
  bool backupExists,
  File backupFile,
  File manifestFile,
) async {
  // 如果已经恢复过，直接返回
  if (_isRestored) return;

  if (backupExists && await backupFile.exists()) {
    _printColor('\n--- 正在恢复原始 AndroidManifest.xml 文件... ---', _magenta);
    try {
      // 关键点：在杀进程后，文件系统可能短暂锁定
      // 如果第一次失败，稍微等待后重试一次
      try {
        await backupFile.rename(manifestFile.path);
      } catch (e) {
        print('文件可能被锁定，等待 500ms 后重试...');
        await Future.delayed(Duration(milliseconds: 500));
        // 再次尝试，如果这次失败就真的失败了
        // 使用 copy + delete 作为 rename 的备选方案，在跨分区或权限复杂时更稳
        await backupFile.copy(manifestFile.path);
        await backupFile.delete();
      }

      print('已从备份恢复原始配置文件。');
      _isRestored = true; // 标记为已恢复
    } catch (e) {
      _printColor('恢复 Manifest 文件失败: $e', _red);
      _printColor('请手动检查: ${backupFile.path}', _red);
    }
  }
}

/// --- 2. 主流程 ---
Future<void> main() async {
  late final Map<String, dynamic> paths;
  late final File manifestFile;
  late final File backupFile;
  bool backupExists = false;
  int exitCode = 0; // 初始化 exitCode

  bool isCleaningUp = false; // 防止重复清理

  // 设置 SIGINT (Ctrl+C) 监听器
  late final StreamSubscription<ProcessSignal> sigintSubscription;
  sigintSubscription = ProcessSignal.sigint.watch().listen((_) async {
    if (isCleaningUp) return;
    isCleaningUp = true;

    _printColor('\n\n检测到 Ctrl+C。正在停止并清理...', _yellow);

    if (_currentProcess != null) {
      _printColor('正在强制终止子进程...', _yellow);
      await _killProcessTree(_currentProcess!);
      // 给文件系统一点喘息时间，释放 gradle 占用的锁
      await Future.delayed(Duration(milliseconds: 200));
    }

    // 2. 立即在信号处理器中尝试恢复
    // 此时我们不依赖 finally，因为 OS 可能会马上杀掉我们
    if (backupExists) {
      await _performRestore(backupExists, backupFile, manifestFile);
    }

    _printColor('退出脚本。', _magenta);
    // 取消监听，防止多次触发
    await sigintSubscription.cancel();
    exit(130);
  });

  try {
    paths = await _initializePaths();
    manifestFile = paths['manifestFile'] as File;
    backupFile = paths['backupFile'] as File;

    final String projectRoot = paths['projectRoot'];
    final String flutterExecutable = paths['flutterExecutable'];
    final Directory releaseDir = paths['releaseDir'] as Directory;
    final Directory skiaDir = paths['skiaDir'] as Directory;
    final String sep = paths['sep'];

    _printColor('将使用 Flutter 命令: $flutterExecutable', _green);
    _printColor('当前工作目录: $projectRoot', _yellow);

    if (!await manifestFile.exists()) {
      throw Exception('无法找到 AndroidManifest.xml: ${manifestFile.path}');
    }

    // 备份原始的 AndroidManifest.xml 文件
    print('--- 正在备份 AndroidManifest.xml ---');
    await manifestFile.copy(backupFile.path);
    backupExists = true;
    print('已创建备份文件: ${backupFile.path}');

    // --- 第一次构建：使用 Skia 渲染引擎 ---
    _printColor('\n--- (1/4) 开始第一次构建：使用 Skia 渲染引擎 ---', _cyan);
    exitCode = await _runCommand(flutterExecutable, [
      'build',
      'apk',
      '--split-per-abi',
      '--dart-define=use_skia=true',
    ], workingDirectory: projectRoot);
    if (exitCode != 0) {
      throw Exception('第一次构建 (Skia) 失败！ (Exit code: $exitCode)');
    }

    // --- 整理第一次构建的产物到 skia 目录 ---
    _printColor('\n--- (2/4) 正在整理 Skia 构建产物 ---', _cyan);
    if (await releaseDir.exists()) {
      // 确保 skia 目录存在且为空
      if (await skiaDir.exists()) {
        print('正在清空旧的 Skia 产物目录...');
        await skiaDir.delete(recursive: true);
      }
      await skiaDir.create(recursive: true);

      // 遍历 release 目录下的所有 apk 文件并重命名复制
      await for (final entity in releaseDir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File && entity.path.endsWith('.apk')) {
          // 获取纯文件名 (例如: app-armeabi-v7a-release)
          final baseName = entity.path.split(sep).last.replaceAll('.apk', '');
          final newName = '$baseName-skia.apk';
          final destinationPath = '${skiaDir.path}$sep$newName';

          await entity.copy(destinationPath);
          print('已处理: $newName');
        }
      }
      _printColor("已将 Skia 构建的 APK 复制到: ${skiaDir.path}", _green);
    } else {
      _printColor('未找到第一次构建的输出目录: ${releaseDir.path}', _yellow);
    }

    // --- 修改配置文件以启用 Impeller ---
    _printColor('\n--- (3/4) 正在修改配置以启用 Impeller 引擎 ---', _cyan);
    // Dart 默认使用 UTF-8 (无 BOM)，完美解决 PowerShell 的问题
    String content = await manifestFile.readAsString();

    // 匹配禁用 Impeller 的 meta-data 标签
    final pattern = RegExp(
      r'<meta-data\s+android:name="io\.flutter\.embedding\.android\.EnableImpeller"\s+android:value="false"\s*/>',
      caseSensitive: false,
    );

    // 准备替换为注释掉的内容
    // 修复：确保注释格式正确，避免 XML 解析错误
    const String replacement = '''<!-- 
        <meta-data
            android:name="io.flutter.embedding.android.EnableImpeller"
            android:value="false"/>
    -->''';

    if (content.contains(pattern)) {
      final modifiedContent = content.replaceAll(pattern, replacement);
      // Dart 默认使用 UTF-8 (无 BOM) 写入
      await manifestFile.writeAsString(modifiedContent);
      print('已注释 AndroidManifest.xml 中的 EnableImpeller=false 配置。');
    } else {
      _printColor(
        '在 AndroidManifest.xml 中未找到 Impeller 配置项，将继续使用默认配置构建。',
        _yellow,
      );
    }

    // --- 第二次构建：使用 Impeller (默认) ---
    _printColor('\n--- (4/4) 开始第二次构建：使用 Impeller 渲染引擎 ---', _cyan);
    exitCode = await _runCommand(flutterExecutable, [
      'build',
      'apk',
      '--split-per-abi',
      '--split-debug-info=$projectRoot${sep}symbols',
    ], workingDirectory: projectRoot);
    if (exitCode != 0) {
      throw Exception('第二次构建 (Impeller) 失败！ (Exit code: $exitCode)');
    }

    // --- 可选：运行符号更新脚本 ---
    final String symbolsScriptPath = paths['symbolsScriptPath'];
    if (await File(symbolsScriptPath).exists()) {
      stdout.write('\n是否要运行符号更新脚本 \'$symbolsScriptPath\'? (y/N) ');
      final String? choice = stdin.readLineSync()?.toLowerCase();

      if (choice == 'y' || choice == 'yes') {
        _printColor('--- 正在执行符号更新脚本... ---', _cyan);

        // --- 修改 ---
        // 之前：'powershell.exe', ['-File', symbolsScriptPath]
        // 现在：使用 'dart run' 来执行 .dart 脚本
        exitCode = await _runCommand('dart', [
          'run',
          symbolsScriptPath,
        ], workingDirectory: projectRoot);

        if (exitCode != 0) {
          throw Exception('符号更新脚本执行失败！ (Exit code: $exitCode)');
        }
      } else {
        _printColor('已跳过执行符号更新脚本。', _yellow);
      }
    } else {
      _printColor('找不到符号更新脚本: $symbolsScriptPath (已跳过)', _yellow);
    }
  } catch (e) {
    // 只有当不是用户主动 Ctrl+C 导致的错误时，才打印红色错误
    // 如果 _isRestored 为 true，说明可能是 Ctrl+C 已经处理过了，或者正在处理
    if (!_isRestored) {
      _printColor('\n构建过程中发生错误！: $e', _red);
    }
    if (exitCode == 0) exitCode = 1;
  } finally {
    // 无论上面发生了什么：
    // 1. 正常跑完
    // 2. 报错进入 catch
    // 3. Ctrl+C 触发，但在 kill 之后主线程抛错进入这里
    // 我们都尝试恢复。如果 SIGINT 已经恢复过了，_performRestore 内部会直接返回。
    if (backupExists) {
      await _performRestore(backupExists, backupFile, manifestFile);
    }
  }

  await sigintSubscription.cancel();
  if (exitCode != 0) exit(exitCode);
  _printColor('\n构建流程全部完成！', _green);
}
