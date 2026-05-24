import 'package:zephyr/src/rust/frb_generated.dart';

Future<void> initRustLib({bool silent = false}) async {
  try {
    await RustLib.init();
  } catch (_) {
    if (!silent) rethrow;
  }
}
