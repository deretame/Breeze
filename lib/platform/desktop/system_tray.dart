import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:zephyr/main.dart';

Future<void> initSystemTray() async {
  if (!Platform.isWindows) return;

  try {
    await trayManager.setIcon('asset/image/app_icon.ico');
    await trayManager.setToolTip('Zephyr');

    Menu menu = Menu(
      items: [
        MenuItem(key: 'show_window', label: '显示主界面'),
        MenuItem.separator(),
        MenuItem(key: 'exit_app', label: '退出'),
      ],
    );

    await trayManager.setContextMenu(menu);
    logger.d('System tray initialized successfully');
  } catch (e, stack) {
    logger.e('Failed to init system tray: $e', error: e, stackTrace: stack);
  }
}
