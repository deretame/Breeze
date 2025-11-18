#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

// --- ANSI 颜色代码 ---
const String _green = '\x1B[32m';
const String _cyan = '\x1B[36m';
const String _red = '\x1B[31m';
const String _yellow = '\x1B[33m';
const String _magenta = '\x1B[35m';
const String _reset = '\x1B[0m';

Process? _currentProcess; // 跟踪当前子进程

/// 彩色打印
void _printColor(String text, String color) {
  print('$color$text$_reset');
}

/// 跨平台强力杀进程函数
Future<void> _killProcessTree(Process process) async {
  final pid = process.pid;
  if (Platform.isWindows) {
    try {
      await Process.run('taskkill', ['/F', '/T', '/PID', pid.toString()]);
    } catch (e) {
      print(e);
      /* 忽略错误 */
    }
  } else {
    try {
      await Process.run('pkill', ['-P', pid.toString()]);
    } catch (e) {
      print(e);
      /* 忽略错误 */
    }
    process.kill(ProcessSignal.sigkill);
  }
}

/// 帮助函数：运行一个进程并流式传输其输出
Future<int> _runCommand(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  bool throwOnError = true,
}) async {
  _printColor('\n> $executable ${arguments.join(' ')}', _yellow);

  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: true,
  );
  _currentProcess = process;

  process.stdout.transform(utf8.decoder).listen(stdout.write);
  process.stderr.transform(utf8.decoder).listen(stderr.write);

  final exitCode = await process.exitCode;
  _currentProcess = null;

  if (exitCode != 0 && throwOnError) {
    _printColor('命令执行失败 (Exit code: $exitCode)', _red);
    throw Exception('命令 $executable 执行失败');
  }
  return exitCode;
}

/// 检查命令是否存在 (通过尝试运行 --version)
Future<bool> _isCommandAvailable(String executable) async {
  try {
    final result = await Process.run(executable, [
      '--version',
    ], runInShell: true);
    return result.exitCode == 0;
  } catch (e) {
    print(e);
    return false;
  }
}

/// --- 主流程 ---
Future<void> main() async {
  final stopwatch = Stopwatch()..start();
  late final StreamSubscription<ProcessSignal> sigintSubscription;
  int exitCode = 0;

  // 设置 Ctrl+C 监听
  sigintSubscription = ProcessSignal.sigint.watch().listen((_) async {
    _printColor('\n\n检测到 Ctrl+C。正在强制停止当前任务...', _red);
    if (_currentProcess != null) {
      await _killProcessTree(_currentProcess!);
    }
    exit(130);
  });

  try {
    // --- 1. 初始化路径 ---
    final sep = Platform.pathSeparator;
    final String scriptPath = Platform.script.toFilePath();
    final String scriptDir = Directory(scriptPath).parent.path;
    final String projectRoot = Directory(scriptDir).parent.path;

    // 自动适配 FVM Dart 路径
    final dartBinName = Platform.isWindows ? 'dart.bat' : 'dart';
    final dartExecutable =
        "$projectRoot$sep.fvm${sep}flutter_sdk${sep}bin$sep$dartBinName";

    _printColor('项目根目录: $projectRoot', _cyan);
    _printColor('Dart 路径: $dartExecutable', _cyan);

    // --- 2. 运行 build_runner ---
    _printColor('--- (1/4) 正在运行 build_runner ---', _green);
    // 使用 --delete-conflicting-outputs 自动解决冲突
    await _runCommand(dartExecutable, [
      'run',
      'build_runner',
      'build',
      '--delete-conflicting-outputs',
    ], workingDirectory: projectRoot);

    // --- 3. 智能安装/检查 flutter_rust_bridge_codegen ---
    _printColor('--- (2/4) 检查 flutter_rust_bridge_codegen ---', _green);
    const codegenTool = 'flutter_rust_bridge_codegen';

    // 优化：先检查是否存在，避免每次都运行 cargo install
    if (await _isCommandAvailable(codegenTool)) {
      _printColor('检测到工具已安装，跳过安装步骤。', _magenta);
    } else {
      _printColor('未检测到工具，正在通过 cargo 安装...', _yellow);
      await _runCommand('cargo', [
        'install',
        'flutter_rust_bridge_codegen',
      ], workingDirectory: projectRoot);
    }

    // --- 4. 运行 codegen ---
    _printColor('--- (3/4) 正在生成 Rust Bridge 代码 ---', _green);
    await _runCommand(codegenTool, ['generate'], workingDirectory: projectRoot);

    // --- 5. 格式化代码 ---
    _printColor('--- (4/4) 正在格式化代码 ---', _green);
    await _runCommand(
      dartExecutable,
      ['format', './lib/'], // 只格式化 lib 目录，节省时间
      workingDirectory: projectRoot,
    );
  } catch (e) {
    _printColor('\n❌ 流程发生错误: $e', _red);
    exitCode = 1;
  } finally {
    await sigintSubscription.cancel();
    stopwatch.stop();
    final time = stopwatch.elapsed.toString().split('.').first; // 格式化时间
    if (exitCode == 0) {
      _printColor('\n✅ 所有任务完成！耗时: $time', _green);
    } else {
      _printColor('\n任务失败。耗时: $time', _red);
    }
    exit(exitCode);
  }
}
