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
}) async {
  _printColor('> $executable ${arguments.join(' ')}', _magenta);
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    runInShell: true,
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
//  7zr.exe 自动获取
// ════════════════════════════════════════════════════════════════

const String _sevenZipVersion = '26.01';
const String _sevenZipExeName = '7zr.exe';
const String _sevenZipDownloadUrl =
    'https://github.com/ip7z/7zip/releases/download/$_sevenZipVersion/7zr.exe';

Future<String> _ensure7zExe(String binDir) async {
  final sep = Platform.pathSeparator;
  final exePath = '$binDir$sep$_sevenZipExeName';

  if (await File(exePath).exists()) {
    _printColor('使用本地 7zr: $exePath', _green);
    return exePath;
  }

  _printColor('未找到 $_sevenZipExeName，正在自动下载...', _yellow);

  final binDirObj = Directory(binDir);
  if (!await binDirObj.exists()) {
    await binDirObj.create(recursive: true);
  }

  // 下载 7zr.exe（仅支持 7z 格式的独立控制台版本，约 590 KB）
  _printColor('下载: $_sevenZipDownloadUrl', _cyan);
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(_sevenZipDownloadUrl));
    final response = await request.close();

    if (response.statusCode != 200) {
      throw Exception('下载失败，HTTP ${response.statusCode}');
    }

    final file = File(exePath);
    final sink = file.openWrite();
    await response.pipe(sink);
    final fileSize = await file.length();
    _printColor('下载完成: ${(fileSize / 1024).toStringAsFixed(0)} KB', _green);
  } finally {
    client.close();
  }

  _printColor('$_sevenZipExeName 已保存到: $exePath', _green);
  return exePath;
}

// ════════════════════════════════════════════════════════════════
//  7z 打包
// ════════════════════════════════════════════════════════════════

Future<void> _create7zArchive(
  String sevenZipExe,
  String dirPath,
  String output7zPath,
) async {
  final dir = Directory(dirPath);
  final parentDir = dir.parent.path;
  final dirName = dir.path.substring(parentDir.length + 1);

  // 使用独立的 7zr.exe 生成 7z 包。7zr 是 7-Zip 的精简独立控制台版本，
  // 仅支持 7z 格式，无需外部 DLL，能正确处理 Windows 长路径，避免 tar
  // 在 Windows/POSIX 兼容层上的各种坑。
  final result = await Process.run(
    sevenZipExe,
    [
      'a', // add to archive
      '-t7z', // 7z format
      '-m0=lzma2', // LZMA2 method
      '-mx=9', // maximum compression
      '-mfb=64', // word size
      '-md=32m', // dictionary size
      '-ms=on', // solid mode on
      output7zPath,
      dirName,
    ],
    workingDirectory: parentDir,
    runInShell: true,
  );

  if (result.exitCode != 0) {
    final stderr = result.stderr.toString().trim();
    throw Exception('7z 打包失败${stderr.isEmpty ? "" : ": $stderr"}');
  }
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
  // 使用 path 库（p.join）可以更优雅地处理路径，这里保持字符串拼接兼容原代码
  final String scriptPath = Platform.script.toFilePath();
  final String scriptDir = Directory(scriptPath).parent.path;
  final String projectRoot = Directory(scriptDir).parent.path;
  final String binDir = '$scriptDir${sep}bin';

  const String flutterExecutable = 'flutter';

  final String releaseDirPath =
      '$projectRoot${sep}build${sep}windows${sep}x64${sep}runner${sep}Release';
  final String runnerDirPath =
      '$projectRoot${sep}build${sep}windows${sep}x64${sep}runner';
  final String installerRoot = '$projectRoot${sep}windows-installer';
  final String resourcesDir = '$installerRoot${sep}src-tauri${sep}resources';

  final String archiveOutput = '$runnerDirPath${sep}Release.7z';
  final String archiveDestination = '$resourcesDir${sep}Release.7z';

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
    _printColor('      (7zr.exe / LZMA2 极限压缩)', _cyan);
    _printColor('═══════════════════════════════════════════\n', _cyan);

    _printColor('Flutter 命令: $flutterExecutable', _green);
    _printColor('项目根目录: $projectRoot\n', _green);

    // ═══ 第 0 步：确保 7zr.exe 可用 ═══
    _printColor('--- (0/4) 检查 7zr.exe 环境 ---', _cyan);
    final String sevenZipExe = await _ensure7zExe(binDir);
    _printColor('7zr.exe 就绪 (7-Zip v$_sevenZipVersion)', _green);
    print('');

    final releaseDir = Directory(releaseDirPath);
    if (shouldBuildFlutter) {
      final String sentryDsn = Platform.environment['SENTRY_DSN'] ?? '';
      if (sentryDsn.isEmpty) {
        _printColor('提示: 未找到 SENTRY_DSN 环境变量，将使用空字符串', _yellow);
      } else {
        _printColor('已读取 Sentry DSN (长度: ${sentryDsn.length})', _green);
      }

      // ═══ 第 1 步：Flutter build ═══
      _printColor('--- (1/4) 构建 Flutter Windows Release ---', _cyan);

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
      // ═══ 第 2 步：7z 压缩 ═══
      _printColor('--- (2/4) 使用 7zr.exe (LZMA2 极限) 压缩 ---', _cyan);

      final stopwatch = Stopwatch()..start();
      await _create7zArchive(sevenZipExe, releaseDirPath, archiveOutput);
      stopwatch.stop();

      final archiveSize = await File(archiveOutput).length();
      _printColor(
        '压缩完成 ✓ '
        '${(archiveSize / 1024 / 1024).toStringAsFixed(1)} MB '
        '(耗时 ${stopwatch.elapsed.inSeconds}s)\n',
        _green,
      );
      _printColor('已保存: $archiveOutput', _green);

      // ═══ 第 3 步：复制到安装器资源目录 ═══
      _printColor('\n--- (3/4) 复制到安装器资源目录 ---', _cyan);

      final resDirObj = Directory(resourcesDir);
      if (!await resDirObj.exists()) {
        await resDirObj.create(recursive: true);
      }

      for (final oldName in ['Release.tar.xz', 'Release.tar.zst']) {
        final old = File('$resourcesDir$sep$oldName');
        if (await old.exists()) {
          await old.delete();
          _printColor('已删除旧的 $oldName', _yellow);
        }
      }

      await File(archiveOutput).copy(archiveDestination);
      _printColor('已复制到: $archiveDestination ✓\n', _green);

      // ═══ 第 4 步：Tauri 构建 ═══
      _printColor('--- (4/4) 构建 Tauri 安装器 ---', _cyan);

      _printColor('正在安装前端与 Tauri 依赖 (pnpm install)...', _cyan);
      exitCode = await _runCommand('pnpm', [
        'install',
      ], workingDirectory: installerRoot);
      if (exitCode != 0) {
        throw Exception('pnpm install 失败！ (Exit code: $exitCode)');
      }

      exitCode = await _runCommand('pnpm', [
        'tauri',
        'build',
      ], workingDirectory: installerRoot);
      if (exitCode != 0) {
        throw Exception('Tauri 构建失败！ (Exit code: $exitCode)');
      }
      _printColor('Tauri 安装器构建完成 ✓\n', _green);
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
