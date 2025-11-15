// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

// --- ANSI 颜色代码 ---
const String _green = '\x1B[32m';
const String _cyan = '\x1B[36m';
const String _red = '\x1B[31m';
const String _yellow = '\x1B[33m';
const String _reset = '\x1B[0m';

/// 彩色打印
void _printColor(String text, String color) {
  print('$color$text$_reset');
}

/// 帮助函数：运行一个进程并流式传输其输出
///
/// [runInShell: true] 对于在 Windows 上正确执行 .bat 和 PATH 中的命令至关重要
/// 返回进程的退出代码
Future<int> _runCommand(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  // 打印将要执行的命令
  _printColor('\n> $executable ${arguments.join(' ')}', _yellow);

  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: true, // 确保 .bat 和 PATH 中的命令能正确执行
  );

  // 实时转发子进程的标准输出和错误
  process.stdout.transform(utf8.decoder).listen(stdout.write);
  process.stderr.transform(utf8.decoder).listen(stderr.write);

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    _printColor('命令执行失败 (Exit code: $exitCode)', _red);
  }
  return exitCode;
}

/// --- 主流程 ---
Future<void> main() async {
  int exitCode = 0;
  late final String projectRoot;
  late final String dartExecutable;

  try {
    // --- 1. 初始化路径 ---
    final sep = Platform.pathSeparator;
    // 假定此脚本位于 project_root/tool/run_codegen.dart
    final String scriptPath = Platform.script.toFilePath();
    final String scriptDir = Directory(scriptPath).parent.path;
    projectRoot = Directory(scriptDir).parent.path;

    // FVM Dart 执行路径
    // 自动处理 Windows (.bat) 和 Linux/macOS (无后缀) 的情况
    final dartExecutableName = Platform.isWindows ? 'dart.bat' : 'dart';
    dartExecutable =
        "$projectRoot$sep.fvm${sep}flutter_sdk${sep}bin$sep$dartExecutableName";

    _printColor('项目根目录: $projectRoot', _cyan);
    _printColor('将使用 Dart: $dartExecutable', _cyan);

    // --- 2. 运行 build_runner ---
    _printColor('--- (1/4) 正在运行 build_runner... ---', _green);
    exitCode = await _runCommand(
      dartExecutable,
      [
        'run',
        'build_runner',
        'build',
        '--delete-conflicting-outputs',
      ], // 增加--delete-conflicting-outputs以防万一
      workingDirectory: projectRoot,
    );
    if (exitCode != 0) throw Exception('build_runner 失败！');

    // --- 3. 安装 flutter_rust_bridge_codegen ---
    _printColor('--- (2/4) 正在安装 flutter_rust_bridge_codegen... ---', _green);
    // 'cargo' 假定在系统 PATH 中
    exitCode = await _runCommand('cargo', [
      'install',
      'flutter_rust_bridge_codegen',
    ], workingDirectory: projectRoot);
    // cargo install 如果已经安装，可能会返回非0代码，这里暂时不严格检查
    if (exitCode != 0) {
      _printColor('cargo install 返回非 0 代码，可能已安装。继续执行...', _yellow);
    }

    // --- 4. 运行 codegen ---
    _printColor('--- (3/4) 正在运行 flutter_rust_bridge_codegen... ---', _green);
    // 'flutter_rust_bridge_codegen' 假定在系统 PATH 中
    exitCode = await _runCommand('flutter_rust_bridge_codegen', [
      'generate',
    ], workingDirectory: projectRoot);
    if (exitCode != 0) throw Exception('codegen generate 失败！');

    // --- 5. 格式化代码 ---
    _printColor('--- (4/4) 正在格式化 lib 目录... ---', _green);
    exitCode = await _runCommand(dartExecutable, [
      'format',
      './lib/',
    ], workingDirectory: projectRoot);
    if (exitCode != 0) throw Exception('dart format 失败！');
  } catch (e) {
    _printColor('\n脚本执行过程中发生错误！', _red);
    _printColor('错误信息: ${e.toString()}', _red);
    exitCode = 1; // 标记失败
  }

  if (exitCode == 0) {
    _printColor('\nRust Bridge Codegen 流程全部完成！', _green);
  }

  // 退出脚本并返回最终的退出代码
  exit(exitCode);
}
