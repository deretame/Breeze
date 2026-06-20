import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';
import 'package:path/path.dart' as p;

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) {
      return;
    }

    final extraCargoEnvironmentVariables = _extraCargoEnvironmentVariables(
      input.config.code,
      input.packageRoot.toFilePath(),
    );

    await RustBuilder(
      assetName: 'src/rust/frb_generated.dart',
      extraCargoEnvironmentVariables: extraCargoEnvironmentVariables,
    ).run(input: input, output: output);
  });
}

Map<String, String> _extraCargoEnvironmentVariables(
  CodeConfig codeConfig,
  String projectRoot,
) {
  if (codeConfig.targetOS == OS.iOS) {
    return _iosEnvironmentVariables(codeConfig);
  }
  if (codeConfig.targetOS == OS.android) {
    return _androidEnvironmentVariables(codeConfig, projectRoot);
  }
  return const <String, String>{};
}

// ────────────────────────── iOS ──────────────────────────

Map<String, String> _iosEnvironmentVariables(CodeConfig codeConfig) {
  final sdk = switch (codeConfig.iOS.targetSdk) {
    IOSSdk.iPhoneOS => 'iphoneos',
    IOSSdk.iPhoneSimulator => 'iphonesimulator',
    final other => throw UnsupportedError('Unsupported iOS SDK: $other'),
  };

  final targetTriple = switch ((codeConfig.targetArchitecture, sdk)) {
    (Architecture.arm64, 'iphoneos') => 'aarch64-apple-ios',
    (Architecture.arm64, 'iphonesimulator') => 'aarch64-apple-ios-sim',
    (Architecture.x64, 'iphonesimulator') => 'x86_64-apple-ios',
    final other => throw UnsupportedError(
      'Unsupported iOS target combination: $other',
    ),
  };

  final linker = _runXcrun(['--sdk', sdk, '--find', 'clang']);
  final sdkRoot = _runXcrun(['--sdk', sdk, '--show-sdk-path']);
  final targetTripleEnv = targetTriple.replaceAll('-', '_').toUpperCase();
  final deploymentTarget = codeConfig.iOS.targetVersion.toString();
  final minimumVersionFlag = switch (sdk) {
    'iphoneos' => '-miphoneos-version-min=$deploymentTarget',
    'iphonesimulator' => '-mios-simulator-version-min=$deploymentTarget',
    final other => throw UnsupportedError('Unsupported iOS SDK: $other'),
  };
  final cFlags = '$minimumVersionFlag -isysroot $sdkRoot';
  final rustFlags = '-C link-arg=$minimumVersionFlag';

  final env = <String, String>{
    'SDKROOT': sdkRoot,
    'IPHONEOS_DEPLOYMENT_TARGET': deploymentTarget,
    'CARGO_TARGET_${targetTripleEnv}_LINKER': linker,
    'CARGO_TARGET_${targetTripleEnv}_RUSTFLAGS': rustFlags,
    'RUSTFLAGS': rustFlags,
    'CFLAGS_$targetTripleEnv': cFlags,
    'CXXFLAGS_$targetTripleEnv': cFlags,
    'CC': linker,
    'CXX': linker,
    'LD': linker,
  };

  // rquickjs-sys 的 bindgen 会把 Rust target triple 直接传给 clang；
  // aarch64-apple-ios-sim 不被 clang 识别，需要额外指定它能识别的 triple。
  if (targetTriple == 'aarch64-apple-ios-sim') {
    env['BINDGEN_EXTRA_CLANG_ARGS'] = '--target=aarch64-apple-ios-simulator';
  }

  return env;
}

String _runXcrun(List<String> arguments) {
  final result = Process.runSync('xcrun', arguments);
  if (result.exitCode != 0) {
    throw ProcessException(
      'xcrun',
      arguments,
      '${result.stdout}\n${result.stderr}',
      result.exitCode,
    );
  }

  return (result.stdout as String).trim();
}

// ────────────────────────── Android ──────────────────────────

Map<String, String> _androidEnvironmentVariables(
  CodeConfig codeConfig,
  String projectRoot,
) {
  final ndkVersion = _readNdkVersion(projectRoot);
  final ndkPath = _findNdkPath(ndkVersion);
  final hostPlatform = _hostPlatform();
  final llvmBase = p.join(
    ndkPath,
    'toolchains',
    'llvm',
    'prebuilt',
    hostPlatform,
  );
  final clangBinary = p.join(llvmBase, 'bin', 'clang${_exeSuffix()}');
  final sysroot = p.join(llvmBase, 'sysroot');
  final ndkTargetTriple = _ndkTargetTriple(codeConfig.targetArchitecture);
  final clangVersion = _detectClangVersion(llvmBase);

  final bindgenArgs = [
    '--sysroot=${sysroot.replaceAll('\\', '/')}',
    '-isystem ${p.join(sysroot, 'usr', 'include').replaceAll('\\', '/')}',
    if (ndkTargetTriple case final t?)
      '-isystem ${p.join(sysroot, 'usr', 'include', t).replaceAll('\\', '/')}',
    if (clangVersion case final v?)
      '-isystem ${p.join(llvmBase, 'lib', 'clang', v, 'include').replaceAll('\\', '/')}',
  ].join(' ');

  return <String, String>{
    'CLANG_PATH': clangBinary.replaceAll('\\', '/'),
    'LIBCLANG_PATH': _libClangPath(llvmBase).replaceAll('\\', '/'),
    'BINDGEN_EXTRA_CLANG_ARGS': bindgenArgs,
    'PATH':
        '${p.join(llvmBase, 'bin')}${_pathSep()}${Platform.environment['PATH'] ?? ''}',
  };
}

String _libClangPath(String llvmBase) {
  if (Platform.isWindows) {
    return p.join(llvmBase, 'bin');
  }
  final lib64 = Directory(p.join(llvmBase, 'lib64'));
  if (lib64.existsSync()) {
    return p.join(llvmBase, 'lib64');
  }
  return p.join(llvmBase, 'lib');
}

String _pathSep() => Platform.isWindows ? ';' : ':';

String? _readNdkVersion(String projectRoot) {
  final gradleFile = File(
    p.join(projectRoot, 'android', 'app', 'build.gradle.kts'),
  );
  if (!gradleFile.existsSync()) return null;
  final match = RegExp(
    r'ndkVersion\s*=\s*"([^"]+)"',
  ).firstMatch(gradleFile.readAsStringSync());
  return match?.group(1);
}

String _findNdkPath(String? ndkVersion) {
  if (ndkVersion != null) {
    final envNdk = Platform.environment['ANDROID_NDK_HOME'];
    if (envNdk != null && Directory(envNdk).existsSync()) return envNdk;

    final sdkRoot =
        Platform.environment['ANDROID_SDK_ROOT'] ??
        Platform.environment['ANDROID_HOME'];
    if (sdkRoot != null) {
      final path = p.join(sdkRoot, 'ndk', ndkVersion);
      if (Directory(path).existsSync()) return path;
    }

    final localAppData = Platform.environment['LOCALAPPDATA'];
    if (Platform.isWindows && localAppData != null) {
      final path = p.join(localAppData, 'Android', 'Sdk', 'ndk', ndkVersion);
      if (Directory(path).existsSync()) return path;
    }

    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null) {
      final path = p.join(home, 'Android', 'Sdk', 'ndk', ndkVersion);
      if (Directory(path).existsSync()) return path;
    }
  }

  throw StateError(
    'Cannot find Android NDK. '
    'Set ANDROID_NDK_HOME or ANDROID_HOME environment variable.',
  );
}

String _hostPlatform() {
  if (Platform.isWindows) return 'windows-x86_64';
  if (Platform.isMacOS) return 'darwin-x86_64';
  return 'linux-x86_64';
}

String? _ndkTargetTriple(Architecture arch) {
  return switch (arch) {
    Architecture.arm64 => 'aarch64-linux-android',
    Architecture.arm => 'arm-linux-androideabi',
    Architecture.x64 => 'x86_64-linux-android',
    Architecture.ia32 => 'i686-linux-android',
    _ => null,
  };
}

String? _detectClangVersion(String llvmBase) {
  final clangDir = Directory(p.join(llvmBase, 'lib', 'clang'));
  if (!clangDir.existsSync()) return null;
  for (final entity in clangDir.listSync()) {
    if (entity is Directory &&
        RegExp(r'^\d+').hasMatch(p.basename(entity.path))) {
      return p.basename(entity.path);
    }
  }
  return null;
}

String _exeSuffix() => Platform.isWindows ? '.exe' : '';
