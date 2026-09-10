#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

const String _green = '\x1B[32m';
const String _cyan = '\x1B[36m';
const String _yellow = '\x1B[33m';
const String _red = '\x1B[31m';
const String _reset = '\x1B[0m';

void _log(String message, {String color = _cyan}) {
  print('$color$message$_reset');
}

Never _fail(String message, {int code = 1}) {
  _log(message, color: _red);
  exit(code);
}

Future<void> _run(
  String executable,
  List<String> arguments, {
  required String cwd,
  Map<String, String>? environment,
}) async {
  _log('> $executable ${arguments.join(' ')}');
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: cwd,
    environment: environment,
    runInShell: true,
  );

  process.stdout.transform(utf8.decoder).listen(stdout.write);
  process.stderr.transform(utf8.decoder).listen(stderr.write);
  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    _fail(
      'Command failed with exit code $exitCode: $executable ${arguments.join(' ')}',
    );
  }
}

Future<String> _runCapture(
  String executable,
  List<String> arguments, {
  required String cwd,
}) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: cwd,
    runInShell: true,
  );
  if (result.exitCode != 0) {
    _fail(
      'Command failed with exit code ${result.exitCode}: '
      '$executable ${arguments.join(' ')}\n${result.stderr}',
    );
  }
  return (result.stdout as String).trim();
}

String _projectRoot() {
  final scriptFile = File.fromUri(Platform.script);
  return Directory(scriptFile.parent.path).parent.path;
}

Future<String> _readDebVersion(String projectRoot) async {
  final envVersion = Platform.environment['VERSION']?.trim() ?? '';
  if (envVersion.isNotEmpty) {
    return envVersion.replaceAll(RegExp(r'\+.*$'), '');
  }
  final pubspec = await File(
    '$projectRoot${Platform.pathSeparator}pubspec.yaml',
  ).readAsString();
  final match = RegExp(
    r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+)(?:\+(\d+))?',
    multiLine: true,
  ).firstMatch(pubspec);
  if (match == null) {
    _fail('Cannot parse version from pubspec.yaml');
  }
  return match.group(1)!;
}

Future<void> _buildLinuxRelease(String projectRoot) async {
  final env = Map<String, String>.from(Platform.environment);
  final sentryDsn = env['SENTRY_DSN']?.trim() ?? '';

  final args = <String>[
    'build',
    'linux',
    '--release',
    '--split-debug-info=$projectRoot${Platform.pathSeparator}build${Platform.pathSeparator}symbols',
  ];
  if (sentryDsn.isNotEmpty) {
    args.add('--dart-define=sentry_dsn=$sentryDsn');
    _log('Detected SENTRY_DSN, injecting dart-define.', color: _green);
  }

  await _run('flutter', args, cwd: projectRoot);

  final crashpad = File(
    '$projectRoot${Platform.pathSeparator}build${Platform.pathSeparator}linux'
    '${Platform.pathSeparator}x64${Platform.pathSeparator}release'
    '${Platform.pathSeparator}bundle${Platform.pathSeparator}lib'
    '${Platform.pathSeparator}crashpad_handler',
  );
  if (!await crashpad.exists()) {
    _fail('Missing required file: ${crashpad.path}');
  }
  await _run('chmod', ['+x', crashpad.path], cwd: projectRoot);
}

Future<String> _assembleDebRoot({
  required String projectRoot,
  required String bundlePath,
  required String version,
}) async {
  final sep = Platform.pathSeparator;
  final outputDir =
      Platform.environment['OUTPUT_DIR']?.trim().isNotEmpty == true
          ? Platform.environment['OUTPUT_DIR']!.trim()
          : 'build-deb';
  final staging = '$projectRoot$sep$outputDir${sep}package';
  final debRoot = '$staging${sep}opt${sep}breeze';
  final root = Directory(staging);
  if (root.existsSync()) {
    await root.delete(recursive: true);
  }

  final optDir = Directory('$staging${sep}opt');
  await optDir.create(recursive: true);
  await _run('cp', ['-r', bundlePath, debRoot], cwd: projectRoot);
  final binDir = Directory('$staging${sep}usr${sep}bin');
  await binDir.create(recursive: true);
  await Link(
    '$staging${sep}usr${sep}bin${sep}breeze',
  ).create('../../opt/breeze/breeze');
  final appsDir = Directory('$staging${sep}usr${sep}share${sep}applications');
  await appsDir.create(recursive: true);
  await File('$projectRoot${sep}flatpak${sep}io.github.windy.breeze.desktop')
      .copy('${appsDir.path}${sep}io.github.windy.breeze.desktop');
  final iconsDir = Directory(
    '$staging${sep}usr${sep}share${sep}icons${sep}hicolor'
    '${sep}512x512${sep}apps',
  );
  await iconsDir.create(recursive: true);
  await File('$projectRoot${sep}asset${sep}image${sep}app-icon.png').copy(
    '${iconsDir.path}${sep}io.github.windy.breeze.png',
  );

  return staging;
}

Future<void> _writeControl({
  required String debRoot,
  required String version,
  required String architecture,
  required List<String> shlibDeps,
}) async {
  final debianDir = Directory('$debRoot${Platform.pathSeparator}DEBIAN');
  await debianDir.create(recursive: true);

  final depends = shlibDeps.isEmpty ? '' : 'Depends: ${shlibDeps.join(', ')}\n';

  await File('${debianDir.path}${Platform.pathSeparator}control').writeAsString(
    'Package: breeze\n'
    'Version: $version\n'
    'Section: net\n'
    'Priority: optional\n'
    'Architecture: $architecture\n'
    'Maintainer: Breeze Developers <dev@breeze.app>\n'
    'Installed-Size: ${_installedSize(debRoot)}\n'
    '$depends'
    'Description: Third-party client for Bika and JM comics\n'
    ' A modern, feature-rich Flutter client for reading comics from\n'
    ' Bika (哔咔) and JM (禁漫), with built-in upscaling, plugins and\n'
    ' desktop system-tray support.\n'
  );

  final postinst = '''#!/bin/sh
set -e
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t /usr/share/icons/hicolor >/dev/null 2>&1 || true
fi
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q /usr/share/applications || true
fi
exit 0
''';
  await File(
    '${debianDir.path}${Platform.pathSeparator}postinst',
  ).writeAsString(postinst);
  await File(
    '${debianDir.path}${Platform.pathSeparator}postrm',
  ).writeAsString(postinst.replaceFirst('postinst', 'postrm'));
  await _run('chmod', ['755', '${debianDir.path}/postinst'], cwd: debianDir.path);
  await _run('chmod', ['755', '${debianDir.path}/postrm'], cwd: debianDir.path);
}

int _installedSize(String debRoot) {
  var total = 0;
  for (final entity in Directory(debRoot).listSync(recursive: true)) {
    if (entity is File) {
      total += entity.lengthSync() ~/ 1024;
    }
  }
  return total;
}

Future<List<String>> _resolveShlibDeps(String staging, String bundlePath) async {
  final debianDir = Directory('$staging${Platform.pathSeparator}debian');
  try {
    await debianDir.create(recursive: true);
    await File('${debianDir.path}${Platform.pathSeparator}control').writeAsString(
      'Source: breeze\nPackage: breeze\nArchitecture: any\n',
    );

    final mainBinary = '$bundlePath/breeze';
    final soFiles = Directory('$bundlePath/lib')
        .listSync()
        .whereType<File>()
        .map((f) => f.path)
        .where((p) => p.endsWith('.so') || p.contains('.so.'))
        .toList();

    final output = await _runCapture(
      'dpkg-shlibdeps',
      ['-O', mainBinary, ...soFiles],
      cwd: staging,
    );
    final line = output
        .split('\n')
        .firstWhere((l) => l.startsWith('shlibs:Depends='), orElse: () => '');
    if (line.isEmpty) {
      _log('dpkg-shlibdeps produced no Depends line.', color: _yellow);
      return const [];
    }
    return line
        .substring('shlibs:Depends='.length)
        .split(',')
        .map((e) => e.trim())
        .toList();
  } catch (e) {
    _log(
      'dpkg-shlibdeps unavailable, deb will carry no Depends. Detail: $e',
      color: _yellow,
    );
    return const [];
  } finally {
    if (debianDir.existsSync()) {
      await debianDir.delete(recursive: true);
    }
  }
}

Future<void> main(List<String> args) async {
  if (!Platform.isLinux) {
    _fail('This script only supports Linux.');
  }

  final projectRoot = _projectRoot();
  final version = await _readDebVersion(projectRoot);
  final outputDir =
      Platform.environment['OUTPUT_DIR']?.trim().isNotEmpty == true
          ? Platform.environment['OUTPUT_DIR']!.trim()
          : 'build-deb';
  final sep = Platform.pathSeparator;
  final bundlePath =
      '$projectRoot${sep}build${sep}linux${sep}x64${sep}release${sep}bundle';

  final packageOnly = args.contains('--package-only');

  _log('=== Breeze Linux .deb Build ===', color: _green);
  _log('Project root: $projectRoot', color: _green);
  _log('Version: $version', color: _green);

  if (!packageOnly) {
    await _buildLinuxRelease(projectRoot);
  } else {
    _log('--package-only: reuse existing bundle at $bundlePath', color: _yellow);
  }
  if (!Directory(bundlePath).existsSync()) {
    _fail('Build bundle not found: $bundlePath');
  }

  final staging = await _assembleDebRoot(
    projectRoot: projectRoot,
    bundlePath: bundlePath,
    version: version,
  );

  final shlibDeps = await _resolveShlibDeps(staging, bundlePath);
  if (shlibDeps.isNotEmpty) {
    _log('Resolved runtime deps:\n  ${shlibDeps.join('\n  ')}', color: _cyan);
  }

  final archResult = await _runCapture(
    'dpkg',
    ['--print-architecture'],
    cwd: projectRoot,
  );
  final architecture = archResult.isEmpty ? 'amd64' : archResult;

  await _writeControl(
    debRoot: staging,
    version: version,
    architecture: architecture,
    shlibDeps: shlibDeps,
  );

  final debFile = File(
    '$projectRoot$sep$outputDir${sep}breeze_${version}_$architecture.deb',
  );
  await _run(
    'dpkg-deb',
    ['--build', '--root-owner-group', staging, debFile.path],
    cwd: projectRoot,
  );

  final size = (await debFile.length()) / 1024 / 1024;
  _log(
    'deb package created: ${debFile.path} (${size.toStringAsFixed(1)} MB)',
    color: _green,
  );
}
