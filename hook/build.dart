import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final extraCargoEnvironmentVariables = _extraCargoEnvironmentVariables(
      input.config.code,
    );

    await RustBuilder(
      assetName: 'src/rust/frb_generated.dart',
      extraCargoEnvironmentVariables: extraCargoEnvironmentVariables,
    ).run(input: input, output: output);
  });
}

Map<String, String> _extraCargoEnvironmentVariables(CodeConfig codeConfig) {
  if (codeConfig.targetOS != OS.iOS) {
    return const <String, String>{};
  }

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

  return <String, String>{
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
