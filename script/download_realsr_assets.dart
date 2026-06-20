import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

/// 下载并解压 RealSR 运行时资源。
///
/// 支持两种资源包格式：
/// - `.tgz` / `.tar.gz`（npm 包格式，默认）
/// - `.zip`
///
/// 会自动去掉顶层单目录前缀（如 npm 的 `package/`）。
///
/// 使用方式：
///   dart script/download_realsr_assets.dart --url=https://registry.npmjs.org/breeze-realsr-assets/-/breeze-realsr-assets-1.0.1.tgz
///
/// 或设置环境变量：
///   BREEZE_REALSR_URL=https://registry.npmjs.org/breeze-realsr-assets/-/breeze-realsr-assets-1.0.1.tgz
///   dart script/download_realsr_assets.dart
const _defaultUrl =
    'https://registry.npmjs.org/breeze-realsr-assets/-/breeze-realsr-assets-1.0.1.tgz';

final _expectedFiles = [
  p.join('asset', 'realsr', 'colors.xml'),
  p.join('asset', 'realsr', 'delegates.xml'),
  p.join('asset', 'realsr', 'models-pro', 'up2x-conservative.bin'),
  p.join('asset', 'realsr', 'models-pro', 'up2x-conservative.param'),
  p.join(
    'android',
    'app',
    'src',
    'main',
    'jniLibs',
    'arm64-v8a',
    'libc++_shared.so',
  ),
  p.join('android', 'app', 'src', 'main', 'jniLibs', 'arm64-v8a', 'libncnn.so'),
  p.join('android', 'app', 'src', 'main', 'jniLibs', 'arm64-v8a', 'libomp.so'),
  p.join(
    'android',
    'app',
    'src',
    'main',
    'jniLibs',
    'arm64-v8a',
    'librealcugan_ncnn.so',
  ),
];

void main(List<String> args) async {
  var url = _parseUrl(args);
  final force = args.contains('--force');

  if (url == null || url.isEmpty) {
    url = _defaultUrl;
  }

  final scriptFile = Platform.script.toFilePath();
  final projectRoot = p.normalize(p.join(p.dirname(scriptFile), '..'));
  final ext = _archiveExtension(url);
  final packagePath = p.join(
    Directory.systemTemp.path,
    'breeze_realsr_assets.$ext',
  );
  final packageFile = File(packagePath);

  if (packageFile.existsSync() && !force) {
    stdout.writeln('检测到本地临时包：$packagePath，加 --force 可重新下载');
  } else {
    stdout.writeln('开始下载 RealSR 资源包...');
    stdout.writeln('URL: $url');
    await _downloadFile(url, packagePath);
    stdout.writeln('下载完成：${await packageFile.length()} bytes');
  }

  stdout.writeln('解压到项目根目录：$projectRoot');
  await _extractArchive(packagePath, projectRoot);

  if (!force) {
    await packageFile.delete();
    stdout.writeln('已清理临时包');
  }

  _verifyFiles(projectRoot);
  stdout.writeln('RealSR 资源准备完成');
}

String? _parseUrl(List<String> args) {
  for (final arg in args) {
    if (arg.startsWith('--url=')) {
      return arg.substring('--url='.length);
    }
  }
  return Platform.environment['BREEZE_REALSR_URL'];
}

String _archiveExtension(String url) {
  final lower = url.toLowerCase();
  if (lower.endsWith('.tar.gz')) return 'tar.gz';
  if (lower.endsWith('.tgz')) return 'tgz';
  return 'zip';
}

Future<void> _downloadFile(String url, String destPath) async {
  final uri = Uri.parse(url);

  if (uri.scheme == 'file') {
    final source = File(uri.toFilePath());
    if (!source.existsSync()) {
      throw Exception('本地文件不存在：${source.path}');
    }
    await source.copy(destPath);
    return;
  }

  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();

    if (response.statusCode != 200) {
      throw Exception('下载失败：HTTP ${response.statusCode}');
    }

    final total = response.headers.contentLength;
    var received = 0;
    final file = File(destPath).openWrite();

    await for (final chunk in response) {
      received += chunk.length;
      file.add(chunk);
      if (total > 0) {
        final percent = (received / total * 100).toStringAsFixed(1);
        stdout.write(
          '\r进度：$percent% (${_formatBytes(received)} / ${_formatBytes(total)})',
        );
      }
    }
    stdout.writeln();
    await file.close();
  } finally {
    client.close();
  }
}

Future<void> _extractArchive(String archivePath, String destDir) async {
  final bytes = await File(archivePath).readAsBytes();
  final ext = _archiveExtension(archivePath);

  late final Archive archive;
  if (ext == 'zip') {
    archive = ZipDecoder().decodeBytes(bytes);
  } else {
    final tarBytes = GZipDecoder().decodeBytes(bytes);
    archive = TarDecoder().decodeBytes(tarBytes);
  }

  final prefix = _detectTopLevelPrefix(archive);
  stdout.writeln('检测到顶层目录前缀：${prefix ?? '(无)'}');

  for (final file in archive.files) {
    var name = file.name;
    if (prefix != null && name.startsWith(prefix)) {
      name = name.substring(prefix.length);
    }
    if (name.isEmpty || name.endsWith('/')) continue;

    final filePath = p.join(destDir, name);
    final data = file.content as List<int>;
    await File(filePath).create(recursive: true);
    await File(filePath).writeAsBytes(data);
  }
}

/// 如果所有文件都在同一个顶层目录下，返回该目录前缀（如 `realsr-assets-npm/`）。
/// 否则返回 null。
String? _detectTopLevelPrefix(Archive archive) {
  String? prefix;
  for (final file in archive.files) {
    if (file.isFile || file.name.endsWith('/')) {
      final parts = file.name.split('/');
      if (parts.length < 2) return null;
      final top = '${parts.first}/';
      if (prefix == null) {
        prefix = top;
      } else if (prefix != top) {
        return null;
      }
    }
  }
  return prefix;
}

void _verifyFiles(String projectRoot) {
  var allOk = true;
  for (final relativePath in _expectedFiles) {
    final file = File(p.join(projectRoot, relativePath));
    if (file.existsSync()) {
      stdout.writeln('  ✓ $relativePath (${_formatBytes(file.lengthSync())})');
    } else {
      stderr.writeln('  ✗ 缺失：$relativePath');
      allOk = false;
    }
  }
  if (!allOk) {
    throw Exception('部分必要文件未找到，请检查资源包内容');
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}
