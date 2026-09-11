import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/platform/desktop/native_window.dart';

bool _runningInSandbox() {
  return Platform.environment.containsKey('FLATPAK_ID') ||
      Platform.environment.containsKey('SNAP') ||
      (Platform.environment['container']?.isNotEmpty ?? false) ||
      File('/.dockerenv').existsSync();
}

Future<void> initSystemTray() async {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;

  try {
    final iconPath = Platform.isWindows
        ? 'asset/image/app_icon.ico'
        : (Platform.isLinux && _runningInSandbox())
        ? 'io.github.windy.breeze'
        : 'asset/image/app-icon.png';
    await trayManager.setIcon(iconPath);

    final Menu menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: t.settings.showMainWindow),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: t.settings.exitApp),
      ],
    );
    await trayManager.setContextMenu(menu);

    try {
      await trayManager.setToolTip('Zephyr');
    } catch (e) {
      logger.d('setToolTip is unsupported on this platform: $e');
    }
    logger.d('System tray initialized successfully');
  } catch (e, stack) {
    logger.e('Failed to init system tray: $e', error: e, stackTrace: stack);
  }
}

Future<void> showMainWindow() async {
  if (Platform.isWindows) {
    NativeWindow.show();
  } else {
    await windowManager.show();
    await windowManager.focus();
  }
}
