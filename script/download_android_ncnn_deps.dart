#!/usr/bin/env dart
// ignore_for_file: unintended_html_in_doc_comment, avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;

/// Downloads the prebuilt ncnn Android Vulkan shared libraries from
/// `deretame/breeze-binary` and installs them to:
///   - third_party/android_ncnn_deps/ncnn-android-vulkan-shared/<abi>/
///   - android/app/src/main/jniLibs/<abi>/
///
/// This is faster than building from source with `script/build_ncnn_android.py`.
/// The downloaded archive must contain the ABI layout used by ncnn official
/// releases, e.g.:
///   ncnn-android-vulkan-shared/
///     arm64-v8a/
///       lib/libncnn.so
///       include/ncnn/...
///       lib/cmake/ncnn/...
const String _archiveUrl =
    'https://github.com/deretame/breeze-binary/raw/main/ncnn-android-vulkan-shared.7z';

final List<String> _abis = ['arm64-v8a', 'armeabi-v7a', 'x86', 'x86_64'];

final int _terminalWidth = () {
  try {
    return stdout.hasTerminal ? stdout.terminalColumns : 80;
  } catch (_) {
    return 80;
  }
}();

String _pad(String text) {
  final width = _terminalWidth;
  if (text.length >= width) return text;
  return text.padRight(width);
}

void _clearLine() {
  stdout.write('\r${_pad('')}\r');
}

Future<void> main(List<String> args) async {
  final projectRoot = _projectRoot();
  final cacheDir = Directory(p.join(projectRoot, 'build', 'ncnn_deps_cache'));
  final depsDir = Directory(
    p.join(
      projectRoot,
      'third_party',
      'android_ncnn_deps',
      'ncnn-android-vulkan-shared',
    ),
  );
  final jniLibsDir = Directory(
    p.join(projectRoot, 'android', 'app', 'src', 'main', 'jniLibs'),
  );

  cacheDir.createSync(recursive: true);
  depsDir.createSync(recursive: true);
  jniLibsDir.createSync(recursive: true);

  final archiveFile = File(
    p.join(cacheDir.path, 'ncnn-android-vulkan-shared.7z'),
  );

  await _download(_archiveUrl, archiveFile);

  final extractDir = Directory(p.join(cacheDir.path, 'extracted'));
  if (extractDir.existsSync()) {
    extractDir.deleteSync(recursive: true);
  }
  extractDir.createSync(recursive: true);

  await _extract7z(archiveFile, extractDir);

  final sourceRoot = _findNcnnRoot(extractDir);
  if (sourceRoot == null) {
    throw StateError(
      'Could not find ncnn-android-vulkan-shared root in extracted archive',
    );
  }

  for (final abi in _abis) {
    final sourceAbi = Directory(p.join(sourceRoot.path, abi));
    if (!sourceAbi.existsSync()) {
      print('⚠️  ABI $abi not found in archive, skipping');
      continue;
    }

    final targetAbi = Directory(p.join(depsDir.path, abi));
    if (targetAbi.existsSync()) {
      targetAbi.deleteSync(recursive: true);
    }
    await _copyDirectory(sourceAbi, targetAbi);

    final sourceLib = File(p.join(sourceAbi.path, 'lib', 'libncnn.so'));
    if (sourceLib.existsSync()) {
      final jniAbi = Directory(p.join(jniLibsDir.path, abi));
      jniAbi.createSync(recursive: true);
      sourceLib.copySync(p.join(jniAbi.path, 'libncnn.so'));
    }

    print('✅ $abi installed');
  }

  print('\n🎉 ncnn Android prebuilt libraries installed.');
  print('   deps: ${depsDir.path}');
  print('   jniLibs: ${jniLibsDir.path}');
}

String _projectRoot() {
  final script = Platform.script.toFilePath();
  return p.normalize(p.join(p.dirname(script), '..'));
}

Future<void> _download(String url, File dest) async {
  if (dest.existsSync()) {
    print('Using cached archive: ${dest.path}');
    return;
  }

  print('Downloading ncnn prebuilt archive...');
  print('  $url');

  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.followRedirects = true;
    final response = await request.close();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Download failed with status ${response.statusCode}: $url',
      );
    }

    final total = response.contentLength;
    var received = 0;
    final sink = dest.openWrite();

    await for (final chunk in response) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) {
        final percent = (received * 100 / total).toStringAsFixed(1);
        final mb = received / 1024 / 1024;
        final totalMb = total / 1024 / 1024;
        stdout.write(
          '\r${_pad('  progress: $percent% (${mb.toStringAsFixed(2)} / ${totalMb.toStringAsFixed(2)} MB)')}',
        );
      }
    }
    await sink.close();
    _clearLine();
    print('  saved: ${dest.path}');
  } finally {
    client.close();
  }
}

Future<void> _extract7z(File archive, Directory outDir) async {
  final sevenZip = _find7z();
  if (sevenZip == null) {
    throw StateError(
      '7-Zip executable not found. Please install 7-Zip and add it to PATH, '
      'or set the SEVENZIP environment variable.',
    );
  }
  print('Extracting with: $sevenZip');

  final result = await Process.run(sevenZip, [
    'x',
    archive.path,
    '-o${outDir.path}',
    '-y',
  ], runInShell: true);

  if (result.exitCode != 0) {
    stderr.writeln(result.stdout);
    stderr.writeln(result.stderr);
    throw StateError('7-Zip extraction failed (exit ${result.exitCode})');
  }
}

String? _find7z() {
  final env = Platform.environment['SEVENZIP'];
  if (env != null && env.isNotEmpty && File(env).existsSync()) {
    return env;
  }

  final candidates = [
    if (Platform.isWindows) r'C:\Program Files\7-Zip\7z.exe',
    if (Platform.isWindows) r'C:\Program Files (x86)\7-Zip\7z.exe',
    '7zz',
    '7z',
    '7za',
  ];
  for (final candidate in candidates) {
    if (FileSystemEntity.isFileSync(candidate)) {
      return candidate;
    }
    final path = _which(candidate);
    if (path != null) return path;
  }
  return null;
}

String? _which(String command) {
  try {
    final result = Process.runSync(Platform.isWindows ? 'where' : 'which', [
      command,
    ], runInShell: true);
    if (result.exitCode == 0) {
      final line = (result.stdout as String).trim().split('\n').first.trim();
      if (line.isNotEmpty && File(line).existsSync()) return line;
    }
  } catch (_) {}
  return null;
}

Directory? _findNcnnRoot(Directory extractDir) {
  final expected = Directory(
    p.join(extractDir.path, 'ncnn-android-vulkan-shared'),
  );
  if (expected.existsSync()) return expected;

  // Fallback: search one level deep.
  for (final entity in extractDir.listSync()) {
    if (entity is Directory) {
      final name = p.basename(entity.path);
      if (name.contains('ncnn') && name.contains('android')) {
        return entity;
      }
    }
  }
  return null;
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  destination.createSync(recursive: true);
  await for (final entity in source.list(recursive: false)) {
    final name = p.basename(entity.path);
    final destPath = p.join(destination.path, name);
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(destPath));
    } else if (entity is File) {
      entity.copySync(destPath);
    }
  }
}
