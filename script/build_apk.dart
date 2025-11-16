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

/// --- 1. 初始化路径 ---
Future<Map<String, dynamic>> _initializePaths() async {
  final sep = Platform.pathSeparator;
  // 假定此脚本位于 project_root/tool/build.dart
  final String scriptPath = Platform.script.toFilePath();
  final String scriptDir = Directory(scriptPath).parent.path;
  // 项目根目录 (tool 目录的上一级)
  final String projectRoot = Directory(scriptDir).parent.path;

  // Flutter 执行路径
  final String flutterExecutable =
      "$projectRoot$sep.fvm${sep}flutter_sdk${sep}bin${sep}flutter.bat";

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

/// 帮助函数：恢复 Manifest 文件
/// 无论成功、失败还是中断，都应调用此函数
Future<void> _performCleanup(
  bool backupExists,
  File backupFile,
  File manifestFile,
) async {
  if (backupExists && await backupFile.exists()) {
    _printColor('\n--- 正在恢复原始 AndroidManifest.xml 文件... ---', _magenta);
    try {
      // 'rename' 在 Dart:io 中就是 'move' 的意思
      await backupFile.rename(manifestFile.path);
      print('已从备份恢复原始配置文件。');
    } catch (e) {
      _printColor('恢复 Manifest 文件失败: $e', _red);
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
      _printColor('正在停止当前运行的命令...', _yellow);
      _currentProcess?.kill(ProcessSignal.sigint); // 终止子进程
    }

    // 立即执行清理
    // 此时 late final 变量可能未初始化，但 backupExists 会保护我们
    if (backupExists) {
      await _performCleanup(backupExists, backupFile, manifestFile);
    }

    _printColor('清理完成。退出。', _magenta);
    await sigintSubscription.cancel();
    exit(130); // Ctrl+C 的标准退出代码
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

    _printColor('将使用 Flutter 执行路径: $flutterExecutable', _green);
    _printColor('当前工作目录: $projectRoot', _yellow);

    // 验证文件
    if (!await File(flutterExecutable).exists()) {
      throw Exception('无法找到 Flutter 执行文件: $flutterExecutable');
    }
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
        ], workingDirectory: paths['symbolsScriptFolderPath']); // 工作目录保持不变

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
    _printColor('\n构建过程中发生错误！', _red);
    _printColor('错误信息: ${e.toString()}', _red);
    // 发生错误时，设置退出代码为 1
    if (exitCode == 0) {
      exitCode = 1; // 确保错误被捕获
    }
  } finally {
    // 无论成功还是失败（非 Ctrl+C），都恢复 Manifest 文件
    // 如果是 Ctrl+C，isCleaningUp 会为 true，避免重复执行
    if (!isCleaningUp) {
      await _performCleanup(backupExists, backupFile, manifestFile);
    }
  }

  // 正常退出前取消监听
  await sigintSubscription.cancel();

  if (exitCode == 0) {
    _printColor('\n构建流程全部完成！', _green);
  } else {
    _printColor('\n构建流程失败。 (Exit code: $exitCode)', _red);
    // 传播错误，以便CI/CD工具可以捕获
    exit(exitCode);
  }
}
