import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zephyr/i18n/strings.g.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/platform/desktop/native_window.dart';

// 常驻引用：native 句柄靠 Dart 对象的 Finalizer 释放，
// Menu/MenuItem/Image 必须一直被引用，否则托盘菜单会被提前回收。
TrayIcon? _trayIcon;
// ignore: unused_element - 常驻引用防 native 菜单被 GC 提前释放，dispose 时置空。
Menu? _trayMenu;
Image? _trayImage;
MenuItem? _showWindowItem;
MenuItem? _exitAppItem;
ListenerId? _trayListenerId;
ListenerId? _showItemListenerId;
ListenerId? _exitItemListenerId;

bool _runningInSandbox() {
  return Platform.environment.containsKey('FLATPAK_ID') ||
      Platform.environment.containsKey('SNAP') ||
      (Platform.environment['container']?.isNotEmpty ?? false) ||
      File('/.dockerenv').existsSync();
}

/// Linux 沙箱下传的是图标名（由 panel 按名查找），沿用旧版的 hicolor 查找逻辑。
Image? _imageFromLinuxIconName(String name) {
  if (name.contains('/')) return null;
  final env = Platform.environment;
  final snap = env['SNAP'];
  final dataDirs = <String>[
    ...?env['XDG_DATA_DIRS']?.split(':'),
    '/app/share',
    if (snap != null) ...['$snap/usr/share', '$snap/share'],
    '/usr/local/share',
    '/usr/share',
  ];
  const sizes = ['48x48', '64x64', '32x32', '128x128', '256x256', '24x24'];
  final candidates = <String>[
    if (snap != null) '$snap/meta/gui/$name.png',
    for (final dir in dataDirs) ...[
      for (final size in sizes) '$dir/icons/hicolor/$size/apps/$name.png',
      '$dir/icons/hicolor/scalable/apps/$name.svg',
      '$dir/pixmaps/$name.png',
    ],
  ];
  for (final candidate in candidates) {
    if (candidate.startsWith('/') && File(candidate).existsSync()) {
      final image = Image.fromFile(candidate);
      if (image != null) {
        return image;
      }
    }
  }
  return null;
}

Future<void> initSystemTray({
  required void Function() onShowWindow,
  required Future<void> Function() onExitApp,
}) async {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;
  if (_trayIcon != null) return;

  // 热重启不会走 dispose，上一次 run 留下的托盘图标还在当前进程里：
  // 先把本进程现有的图标全清掉，否则每次热重启多一个。
  // （C 核心在进程内，getAll 拿到的都是自己的。）
  for (final icon in TrayManager.instance.getAll()) {
    icon.dispose();
  }

  try {
    final trayIcon = TrayIcon.create();
    if (trayIcon == null) {
      logger.w('Failed to create system tray icon');
      return;
    }
    _trayIcon = trayIcon;

    final iconPath = Platform.isWindows
        ? 'asset/image/app_icon.ico'
        : (Platform.isLinux && _runningInSandbox())
        ? 'io.github.windy.breeze'
        : 'asset/image/app-icon.png';
    // 注意：ImageAsset.fromAsset 解析的是打包后的 flutter_assets，
    // debug 下（flutter run）通常解析不到，会降级打 warning，release 正常。
    final image =
        ImageAsset.fromAsset(iconPath) ??
        Image.fromFile(iconPath) ??
        (Platform.isLinux ? _imageFromLinuxIconName(iconPath) : null);
    if (image == null) {
      logger.w('Unable to load tray icon: $iconPath');
    } else {
      _trayImage = image;
      trayIcon.icon = image;
    }
    trayIcon.setVisible(true);

    final menu = Menu.create();
    _showWindowItem = MenuItem.createWithLabelAndType(
      t.settings.showMainWindow,
      MenuItemType.normal,
    );
    _exitAppItem = MenuItem.createWithLabelAndType(
      t.settings.exitApp,
      MenuItemType.normal,
    );
    final showItem = _showWindowItem;
    final exitItem = _exitAppItem;
    if (menu == null || showItem == null || exitItem == null) {
      logger.w('Failed to create system tray menu');
      return;
    }
    menu.addItem(showItem);
    menu.addSeparator();
    menu.addItem(exitItem);
    _trayMenu = menu;
    // 点击监听挂在每个条目上（官方 legacy 桥接同款写法）；
    // MenuItem 没有 key，直接在各自回调里分发，不用比 id。
    _showItemListenerId = showItem.addListener((event) {
      if (event is MenuItemClickedEvent) {
        onShowWindow();
      }
    });
    _exitItemListenerId = exitItem.addListener((event) {
      if (event is MenuItemClickedEvent) {
        onExitApp();
      }
    });
    trayIcon.setContextMenu(menu);

    try {
      trayIcon.setTooltip('Zephyr');
    } catch (e) {
      logger.d('setToolTip is unsupported on this platform: $e');
    }

    _trayListenerId = trayIcon.addListener((event) {
      switch (event) {
        case TrayIconClickedEvent():
          onShowWindow();
        case TrayIconRightClickedEvent():
          // Linux 下点击事件由 panel 接管、菜单由 shell 自己弹出，这里只处理 Win/macOS。
          if (!Platform.isLinux) {
            trayIcon.openContextMenu();
          }
        case TrayIconDoubleClickedEvent():
          break;
      }
    });
    logger.d('System tray initialized successfully');
  } catch (e, stack) {
    logger.e('Failed to init system tray: $e', error: e, stackTrace: stack);
  }
}

void disposeSystemTray() {
  final trayIcon = _trayIcon;
  final trayListenerId = _trayListenerId;
  if (trayListenerId != null) {
    trayIcon?.removeListener(trayListenerId);
    _trayListenerId = null;
  }
  final showItemListenerId = _showItemListenerId;
  if (showItemListenerId != null) {
    _showWindowItem?.removeListener(showItemListenerId);
    _showItemListenerId = null;
  }
  final exitItemListenerId = _exitItemListenerId;
  if (exitItemListenerId != null) {
    _exitAppItem?.removeListener(exitItemListenerId);
    _exitItemListenerId = null;
  }
  _trayMenu = null;
  _showWindowItem = null;
  _exitAppItem = null;
  _trayImage?.dispose();
  _trayImage = null;
  trayIcon?.dispose();
  _trayIcon = null;
}

Future<void> showMainWindow() async {
  if (Platform.isWindows) {
    NativeWindow.show();
  } else {
    await windowManager.show();
    await windowManager.focus();
  }
}
