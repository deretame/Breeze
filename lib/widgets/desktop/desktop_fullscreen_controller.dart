import 'package:flutter/foundation.dart';

final ValueNotifier<bool> desktopReaderFullscreenNotifier = ValueNotifier<bool>(
  false,
);

void setDesktopReaderFullscreen(bool value) {
  if (desktopReaderFullscreenNotifier.value == value) return;
  desktopReaderFullscreenNotifier.value = value;
}
