import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:zephyr/src/rust/frb_generated.dart';

Future<void> initRustLib({bool silent = false}) async {
  try {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      final name = Platform.isWindows
          ? 'windcore.dll'
          : Platform.isMacOS
              ? 'libwindcore.dylib'
              : 'libwindcore.so';
      await RustLib.init(externalLibrary: ExternalLibrary.open(name));
    } else {
      await RustLib.init();
    }
  } catch (_) {
    if (!silent) rethrow;
  }
}
