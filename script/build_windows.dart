#!/usr/bin/env dart
// ignore_for_file: constant_identifier_names, avoid_print

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:ffi/ffi.dart';

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

// ════════════════════════════════════════════════════════════════
//  liblzma (xz) FFI 绑定
// ════════════════════════════════════════════════════════════════

/// lzma_ret 返回值常量
const int LZMA_OK = 0;
const int LZMA_STREAM_END = 1;
const int LZMA_BUF_ERROR = 5;

/// lzma_check 常量
const int LZMA_CHECK_CRC64 = 4;

/// preset 标志
const int LZMA_PRESET_EXTREME = 1 << 31;

// size_t lzma_stream_buffer_bound(size_t uncompressed_size);
typedef LzmaStreamBufferBoundNative = Size Function(Size uncompressedSize);
typedef LzmaStreamBufferBoundDart = int Function(int uncompressedSize);

// lzma_ret lzma_easy_buffer_encode(
//     uint32_t preset,
//     lzma_check check,
//     const lzma_allocator *allocator,
//     const uint8_t *in, size_t in_size,
//     uint8_t *out, size_t *out_pos, size_t out_size);
typedef LzmaEasyBufferEncodeNative =
    Uint32 Function(
      Uint32 preset,
      Uint32 check,
      Pointer<Void> allocator, // NULL
      Pointer<Uint8> inBuf,
      Size inSize,
      Pointer<Uint8> outBuf,
      Pointer<Size> outPos,
      Size outSize,
    );
typedef LzmaEasyBufferEncodeDart =
    int Function(
      int preset,
      int check,
      Pointer<Void> allocator,
      Pointer<Uint8> inBuf,
      int inSize,
      Pointer<Uint8> outBuf,
      Pointer<Size> outPos,
      int outSize,
    );

class LzmaLib {
  final DynamicLibrary _lib;
  late final LzmaStreamBufferBoundDart streamBufferBound;
  late final LzmaEasyBufferEncodeDart easyBufferEncode;

  LzmaLib(String path) : _lib = DynamicLibrary.open(path) {
    streamBufferBound = _lib
        .lookupFunction<LzmaStreamBufferBoundNative, LzmaStreamBufferBoundDart>(
          'lzma_stream_buffer_bound',
        );
    easyBufferEncode = _lib
        .lookupFunction<LzmaEasyBufferEncodeNative, LzmaEasyBufferEncodeDart>(
          'lzma_easy_buffer_encode',
        );
  }

  /// 使用 xz/LZMA2 极限压缩数据
  /// preset: 0-9, 越高压缩率越好（默认 9 | EXTREME）
  Uint8List compress(Uint8List input, {int preset = 9, bool extreme = true}) {
    final srcSize = input.length;
    final dstCapacity = streamBufferBound(srcSize);

    if (dstCapacity == 0) {
      throw Exception('lzma_stream_buffer_bound 返回 0，输入可能太大');
    }

    final srcPtr = calloc<Uint8>(srcSize);
    final dstPtr = calloc<Uint8>(dstCapacity);
    final outPosPtr = calloc<Size>(1);

    try {
      // 复制输入数据到 native 内存
      srcPtr.asTypedList(srcSize).setAll(0, input);
      outPosPtr.value = 0;

      final actualPreset = extreme ? (preset | LZMA_PRESET_EXTREME) : preset;

      final ret = easyBufferEncode(
        actualPreset,
        LZMA_CHECK_CRC64,
        nullptr, // 使用默认 allocator
        srcPtr,
        srcSize,
        dstPtr,
        outPosPtr,
        dstCapacity,
      );

      if (ret != LZMA_OK) {
        throw Exception('lzma_easy_buffer_encode 失败，错误码: $ret');
      }

      final compressedSize = outPosPtr.value;
      return Uint8List.fromList(dstPtr.asTypedList(compressedSize));
    } finally {
      calloc.free(srcPtr);
      calloc.free(dstPtr);
      calloc.free(outPosPtr);
    }
  }
}

// ════════════════════════════════════════════════════════════════
//  liblzma DLL 自动获取
// ════════════════════════════════════════════════════════════════

const String _xzVersion = '5.8.2';
const String _lzmaDllName = 'liblzma.dll';
const String _xzDownloadUrl =
    'https://github.com/tukaani-project/xz/releases/download/v$_xzVersion/xz-$_xzVersion-windows.zip';

Future<String> _ensureLzmaDll(String binDir) async {
  final sep = Platform.pathSeparator;
  final dllPath = '$binDir$sep$_lzmaDllName';

  if (await File(dllPath).exists()) {
    _printColor('使用本地 liblzma: $dllPath', _green);
    return dllPath;
  }

  _printColor('未找到 $_lzmaDllName，正在自动下载...', _yellow);

  final tempDir = await Directory.systemTemp.createTemp('xz_download_');

  try {
    final zipPath = '${tempDir.path}${sep}xz.zip';

    // 下载 zip
    _printColor('下载: $_xzDownloadUrl', _cyan);
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(_xzDownloadUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('下载失败，HTTP ${response.statusCode}');
      }

      final file = File(zipPath);
      final sink = file.openWrite();
      await response.pipe(sink);
      final fileSize = await file.length();
      _printColor('下载完成: ${(fileSize / 1024).toStringAsFixed(0)} KB', _green);
    } finally {
      client.close();
    }

    // 用 archive 包解压 zip
    _printColor('正在解压...', _cyan);
    final zipBytes = await File(zipPath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(zipBytes);

    // 在 zip 中查找 x86-64 版本的 liblzma.dll
    ArchiveFile? dllFile;
    for (final file in archive) {
      final nameLower = file.name.toLowerCase();
      // 优先查找 x86-64 版本
      if (nameLower.contains('x86-64') && nameLower.endsWith('liblzma.dll')) {
        dllFile = file;
        break;
      }
    }

    // 如果没找到 x86-64，找任何 liblzma.dll
    if (dllFile == null) {
      for (final file in archive) {
        if (file.name.toLowerCase().endsWith('liblzma.dll')) {
          dllFile = file;
          break;
        }
      }
    }

    if (dllFile == null) {
      throw Exception('在下载的 zip 中未找到 $_lzmaDllName');
    }

    // 确保 bin 目录存在
    final binDirObj = Directory(binDir);
    if (!await binDirObj.exists()) {
      await binDirObj.create(recursive: true);
    }

    // 写入 DLL
    await File(dllPath).writeAsBytes(dllFile.content as List<int>);
    _printColor('$_lzmaDllName 已保存到: $dllPath', _green);

    return dllPath;
  } finally {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  }
}

// ════════════════════════════════════════════════════════════════
//  TAR 打包
// ════════════════════════════════════════════════════════════════

Future<Uint8List> _createTarArchive(String dirPath) async {
  final archive = Archive();
  final dir = Directory(dirPath);
  final dirPrefix = dir.parent.path;

  await for (final entity in dir.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      var relativePath = entity.path
          .substring(dirPrefix.length + 1)
          .replaceAll('\\', '/');

      final bytes = await entity.readAsBytes();
      final file = ArchiveFile(relativePath, bytes.length, bytes);
      archive.addFile(file);
    }
  }

  final tarData = TarEncoder().encode(archive);
  return Uint8List.fromList(tarData);
}

// ════════════════════════════════════════════════════════════════
//  主流程
// ════════════════════════════════════════════════════════════════

Future<void> main() async {
  int exitCode = 0;
  bool isCleaningUp = false;

  final sep = Platform.pathSeparator;
  final String scriptPath = Platform.script.toFilePath();
  final String scriptDir = Directory(scriptPath).parent.path;
  final String projectRoot = Directory(scriptDir).parent.path;
  final String binDir = '$scriptDir${sep}bin';

  final String flutterExecutable =
      '$projectRoot$sep.fvm${sep}flutter_sdk${sep}bin${sep}flutter.bat';

  final String releaseDirPath =
      '$projectRoot${sep}build${sep}windows${sep}x64${sep}runner${sep}Release';
  final String runnerDirPath =
      '$projectRoot${sep}build${sep}windows${sep}x64${sep}runner';
  final String installerRoot = '$projectRoot${sep}windows-installer';
  final String resourcesDir = '$installerRoot${sep}src-tauri${sep}resources';

  final String archiveOutput = '$runnerDirPath${sep}Release.tar.xz';
  final String archiveDestination = '$resourcesDir${sep}Release.tar.xz';

  // Ctrl+C
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
    _printColor('       Breeze Windows 构建脚本', _cyan);
    _printColor('       (xz/LZMA2 FFI 极限压缩)', _cyan);
    _printColor('═══════════════════════════════════════════\n', _cyan);

    if (!await File(flutterExecutable).exists()) {
      throw Exception('无法找到 Flutter: $flutterExecutable');
    }
    _printColor('Flutter: $flutterExecutable', _green);
    _printColor('项目根目录: $projectRoot\n', _green);

    // ═══ 第 0 步：确保 liblzma 可用 ═══
    _printColor('--- (0/4) 检查 xz/liblzma 环境 ---', _cyan);
    final String dllPath = await _ensureLzmaDll(binDir);
    final lzma = LzmaLib(dllPath);
    _printColor('liblzma 加载成功 (xz v$_xzVersion)', _green);
    print('');

    // ═══ 第 1 步：Flutter build ═══
    _printColor('--- (1/4) 构建 Flutter Windows Release ---', _cyan);
    exitCode = await _runCommand(flutterExecutable, [
      'build',
      'windows',
      '--release',
    ], workingDirectory: projectRoot);
    if (exitCode != 0) {
      throw Exception('Flutter 构建失败！ (Exit code: $exitCode)');
    }
    _printColor('Flutter 构建完成 ✓\n', _green);

    final releaseDir = Directory(releaseDirPath);
    if (!await releaseDir.exists()) {
      throw Exception('构建产物不存在: $releaseDirPath');
    }

    // ═══ 第 2 步：tar + xz 压缩（FFI） ═══
    _printColor('--- (2/4) tar 打包 + xz/LZMA2 极限压缩 (FFI) ---', _cyan);

    _printColor('正在打包 Release 目录...', _cyan);
    final tarData = await _createTarArchive(releaseDirPath);
    _printColor(
      'tar 打包完成: ${(tarData.length / 1024 / 1024).toStringAsFixed(1)} MB',
      _green,
    );

    // xz 极限压缩 (preset 9 | EXTREME)
    _printColor('正在使用 xz -9e (LZMA2 极限) 压缩 (FFI)...', _cyan);
    _printColor('（这可能需要几分钟，请耐心等待）', _yellow);

    final stopwatch = Stopwatch()..start();
    final compressedData = lzma.compress(tarData, preset: 9, extreme: true);
    stopwatch.stop();

    final ratio = (compressedData.length / tarData.length * 100)
        .toStringAsFixed(1);
    _printColor(
      '压缩完成 ✓ '
      '${(tarData.length / 1024 / 1024).toStringAsFixed(1)} MB → '
      '${(compressedData.length / 1024 / 1024).toStringAsFixed(1)} MB '
      '(压缩率 $ratio%, 耗时 ${stopwatch.elapsed.inSeconds}s)\n',
      _green,
    );

    await File(archiveOutput).writeAsBytes(compressedData);
    _printColor('已保存: $archiveOutput', _green);

    // ═══ 第 3 步：复制到安装器资源目录 ═══
    _printColor('\n--- (3/4) 复制到安装器资源目录 ---', _cyan);

    final resDirObj = Directory(resourcesDir);
    if (!await resDirObj.exists()) {
      await resDirObj.create(recursive: true);
    }

    // 删除旧文件
    for (final oldName in ['Release.7z', 'Release.tar.zst']) {
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
    exitCode = await _runCommand('pnpm', [
      'tauri',
      'build',
    ], workingDirectory: installerRoot);
    if (exitCode != 0) {
      throw Exception('Tauri 构建失败！ (Exit code: $exitCode)');
    }
    _printColor('Tauri 安装器构建完成 ✓\n', _green);
  } catch (e) {
    if (!isCleaningUp) {
      _printColor('\n构建过程中发生错误: $e', _red);
    }
    if (exitCode == 0) exitCode = 1;
  }

  await sigintSubscription.cancel();
  if (exitCode != 0) exit(exitCode);

  _printColor('═══════════════════════════════════════════', _green);
  _printColor('       全部构建流程完成！', _green);
  _printColor('═══════════════════════════════════════════', _green);
}
