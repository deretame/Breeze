#!/usr/bin/env dart
// ignore_for_file: constant_identifier_names, avoid_print

import 'dart:async';
import 'dart:io';

// ════════════════════════════════════════════════════════════════
//  ANSI 颜色
// ════════════════════════════════════════════════════════════════
const String _green = '\x1B[32m';
const String _cyan = '\x1B[36m';
const String _red = '\x1B[31m';
const String _yellow = '\x1B[33m';
const String _magenta = '\x1B[35m';
const String _reset = '\x1B[0m';

Process? _currentProcess;

void _printColor(String text, String color) {
  print('$color$text$_reset');
}

// ════════════════════════════════════════════════════════════════
//  进程/命令工具
// ════════════════════════════════════════════════════════════════

Future<int> _runCommand(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  bool runInShell = true,
}) async {
  _printColor('> $executable ${arguments.join(' ')}', _magenta);
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: runInShell,
  );
  _currentProcess = process;

  process.stdout.transform(systemEncoding.decoder).listen(stdout.write);
  process.stderr.transform(systemEncoding.decoder).listen(stderr.write);

  final exitCode = await process.exitCode;
  _currentProcess = null;
  return exitCode;
}

Future<void> _killProcessTree(Process process) async {
  try {
    await Process.run('taskkill', ['/F', '/T', '/PID', '${process.pid}']);
  } catch (e) {
    _printColor('杀进程失败: $e', _red);
  }
}

enum WindowsBuildStage { all, prepare, package }

WindowsBuildStage _parseBuildStage(List<String> args) {
  for (final arg in args) {
    if (arg == '--prepare-only') return WindowsBuildStage.prepare;
    if (arg == '--package-only') return WindowsBuildStage.package;

    if (arg.startsWith('--stage=')) {
      final value = arg.substring('--stage='.length).toLowerCase();
      switch (value) {
        case 'all':
          return WindowsBuildStage.all;
        case 'prepare':
        case 'build':
        case 'release':
          return WindowsBuildStage.prepare;
        case 'package':
        case 'installer':
          return WindowsBuildStage.package;
      }
    }
  }

  return WindowsBuildStage.all;
}

// ════════════════════════════════════════════════════════════════
//  Inno Setup / 版本号
// ════════════════════════════════════════════════════════════════

/// 查找 ISCC.exe。优先级：ISCC 环境变量 → INNO_SETUP_HOME → 常见安装路径 → PATH。
String? _findIscc() {
  final sep = Platform.pathSeparator;
  final env = Platform.environment;

  final candidates = <String>[];

  final explicit = env['ISCC']?.trim();
  if (explicit != null && explicit.isNotEmpty) {
    candidates.add(explicit.replaceAll('"', ''));
  }

  final home = env['INNO_SETUP_HOME']?.trim();
  if (home != null && home.isNotEmpty) {
    candidates.add('${home.replaceAll('"', '')}${sep}ISCC.exe');
  }

  final localAppData = env['LOCALAPPDATA']?.trim();
  if (localAppData != null && localAppData.isNotEmpty) {
    candidates.addAll([
      '$localAppData${sep}Programs${sep}Inno Setup 7${sep}ISCC.exe',
      '$localAppData${sep}Programs${sep}Inno Setup 6${sep}ISCC.exe',
    ]);
  }

  candidates.addAll([
    r'C:\Program Files\Inno Setup 7\ISCC.exe',
    r'C:\Program Files (x86)\Inno Setup 7\ISCC.exe',
    r'C:\Program Files\Inno Setup 6\ISCC.exe',
    r'C:\Program Files (x86)\Inno Setup 6\ISCC.exe',
  ]);

  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }

  try {
    final result = Process.runSync('where', ['ISCC.exe'], runInShell: true);
    if (result.exitCode == 0) {
      for (final line in result.stdout.toString().split(RegExp(r'\r?\n'))) {
        final path = line.trim();
        if (path.isNotEmpty && File(path).existsSync()) return path;
      }
    }
  } catch (_) {
    // 忽略，返回未找到
  }

  return null;
}

/// 从 pubspec.yaml 读取版本号（去掉 +build 部分）。
String _readAppVersion(String projectRoot) {
  final sep = Platform.pathSeparator;
  final pubspec = File('$projectRoot${sep}pubspec.yaml');
  if (!pubspec.existsSync()) {
    throw Exception('未找到 pubspec.yaml: ${pubspec.path}');
  }

  for (final line in pubspec.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.startsWith('version:')) {
      final raw = trimmed.substring('version:'.length).trim();
      final version = raw.split('+').first.trim();
      if (version.isNotEmpty) return version;
    }
  }

  throw Exception('pubspec.yaml 中未找到 version 字段');
}

/// Inno Setup 的 VersionInfoVersion 需要 4 段纯数字。
String _versionQuad(String version) {
  final numeric = RegExp(r'^\d+(?:\.\d+)*').stringMatch(version) ?? '0';
  final parts = numeric.split('.');
  while (parts.length < 4) {
    parts.add('0');
  }
  return parts.take(4).join('.');
}

// ════════════════════════════════════════════════════════════════
//  主流程
// ════════════════════════════════════════════════════════════════

Future<void> main(List<String> args) async {
  int exitCode = 0;
  bool isCleaningUp = false;
  final buildStage = _parseBuildStage(args);
  final bool shouldBuildFlutter = buildStage != WindowsBuildStage.package;
  final bool shouldPackageInstaller = buildStage != WindowsBuildStage.prepare;

  final sep = Platform.pathSeparator;
  final String scriptPath = Platform.script.toFilePath();
  final String scriptDir = Directory(scriptPath).parent.path;
  final String projectRoot = Directory(scriptDir).parent.parent.path;

  const String flutterExecutable = 'flutter';

  final String releaseDirPath =
      '$projectRoot${sep}build${sep}windows${sep}x64${sep}runner${sep}Release';
  final String installerScriptPath =
      '$projectRoot${sep}windows-installer${sep}breeze.iss';
  final String installerOutputDir =
      '$projectRoot${sep}build${sep}windows${sep}installer';
  final String installerExePath =
      '$installerOutputDir${sep}windows-installer.exe';

  // Ctrl+C 监听器
  late final StreamSubscription<ProcessSignal> sigintSubscription;
  sigintSubscription = ProcessSignal.sigint.watch().listen((_) async {
    if (isCleaningUp) return;
    isCleaningUp = true;
    _printColor('\n\n检测到 Ctrl+C，正在停止...', _yellow);
    if (_currentProcess != null) {
      await _killProcessTree(_currentProcess!);
    }
    await sigintSubscription.cancel();
    exit(130);
  });

  try {
    _printColor('═══════════════════════════════════════════', _cyan);
    _printColor('      Breeze Windows 构建脚本', _cyan);
    _printColor('      (Flutter Release + Inno Setup)', _cyan);
    _printColor('═══════════════════════════════════════════\n', _cyan);

    _printColor('Flutter 命令: $flutterExecutable', _green);
    _printColor('项目根目录: $projectRoot', _green);

    final String appVersion = _readAppVersion(projectRoot);
    final String versionQuad = _versionQuad(appVersion);
    _printColor('应用版本: $appVersion ($versionQuad)', _green);

    String? isccPath;
    if (shouldPackageInstaller) {
      isccPath = _findIscc();
      if (isccPath == null) {
        throw Exception(
          '未找到 ISCC.exe。请安装 Inno Setup 7，或设置环境变量 ISCC / INNO_SETUP_HOME。',
        );
      }
      _printColor('Inno Setup: $isccPath', _green);
    }
    print('');

    final releaseDir = Directory(releaseDirPath);

    if (shouldBuildFlutter) {
      final String sentryDsn = Platform.environment['SENTRY_DSN'] ?? '';
      if (sentryDsn.isEmpty) {
        _printColor('提示: 未找到 SENTRY_DSN 环境变量，将使用空字符串', _yellow);
      } else {
        _printColor('已读取 Sentry DSN (长度: ${sentryDsn.length})', _green);
      }

      _printColor('--- 构建 Flutter Windows Release ---', _cyan);

      exitCode = await _runCommand(flutterExecutable, [
        'build',
        'windows',
        '--release',
        '--dart-define=sentry_dsn=$sentryDsn',
        '--split-debug-info=$projectRoot${sep}build${sep}symbols',
      ], workingDirectory: projectRoot);

      if (exitCode != 0) {
        throw Exception('Flutter 构建失败！ (Exit code: $exitCode)');
      }
      _printColor('Flutter 构建完成 ✓\n', _green);
    } else {
      _printColor('跳过 Flutter 构建，直接进入安装器打包阶段。', _yellow);
    }

    if (!await releaseDir.exists()) {
      throw Exception('构建产物不存在: $releaseDirPath');
    }

    if (shouldPackageInstaller) {
      _printColor('--- 编译 Inno Setup 安装器 ---', _cyan);

      if (!await File(installerScriptPath).exists()) {
        throw Exception('安装器脚本不存在: $installerScriptPath');
      }

      final installerDir = Directory(installerOutputDir);
      if (!await installerDir.exists()) {
        await installerDir.create(recursive: true);
      }

      final compileExit = await _runCommand(
        isccPath!,
        [
          '-dAppVersion=$appVersion',
          '-dVersionQuad=$versionQuad',
          '-dStageDir=$releaseDirPath',
          '-dOutputDir=$installerOutputDir',
          installerScriptPath,
        ],
        workingDirectory: projectRoot,
        runInShell: false,
      );

      if (compileExit != 0) {
        throw Exception('Inno Setup 编译失败！ (Exit code: $compileExit)');
      }

      final installerFile = File(installerExePath);
      if (!await installerFile.exists()) {
        throw Exception('安装器未生成: $installerExePath');
      }

      final sizeMb = (await installerFile.length()) / 1024 / 1024;
      _printColor(
        '安装器生成完成 ✓ ${sizeMb.toStringAsFixed(1)} MB',
        _green,
      );
      _printColor('已保存: $installerExePath\n', _green);
    } else {
      _printColor('已跳过安装器打包阶段，等待签名回灌。', _green);
    }
  } catch (e) {
    if (!isCleaningUp) {
      _printColor('\n构建过程中发生错误: $e', _red);
    }
    if (exitCode == 0) exitCode = 1;
  }

  await sigintSubscription.cancel();
  if (exitCode != 0) exit(exitCode);

  _printColor('═══════════════════════════════════════════', _green);
  if (buildStage == WindowsBuildStage.prepare) {
    _printColor('       Windows 第一阶段构建完成！', _green);
  } else if (buildStage == WindowsBuildStage.package) {
    _printColor('       Windows 安装器打包完成！', _green);
  } else {
    _printColor('       全部构建流程完成！', _green);
  }
  _printColor('═══════════════════════════════════════════', _green);
}
