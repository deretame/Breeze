import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win32;
import 'package:window_manager/window_manager.dart';

// win32 包没有导出 FindWindowW 和 IsZoomed，所以用 dart:ffi 补充
final _user32 = DynamicLibrary.open('user32.dll');

final _findWindow = _user32
    .lookupFunction<
      IntPtr Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName),
      int Function(Pointer<Utf16> lpClassName, Pointer<Utf16> lpWindowName)
    >('FindWindowW');

final _isZoomed = _user32
    .lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
      'IsZoomed',
    );

/// Win32 窗口操作的同步封装，避免 method channel 延迟
class NativeWindow {
  NativeWindow._();

  static int _hwnd = 0;

  /// 初始化，缓存窗口句柄（在 window ready 之后调用一次）
  static void init() {
    final className = 'FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf16();
    _hwnd = _findWindow(className, nullptr);
    calloc.free(className);
  }

  static bool get isReady => _hwnd != 0;

  /// 同步最小化
  static void minimize() {
    if (_hwnd != 0) win32.ShowWindow(_hwnd, win32.SW_MINIMIZE);
  }

  /// 同步最大化
  static void maximize() {
    if (_hwnd != 0) win32.ShowWindow(_hwnd, win32.SW_MAXIMIZE);
  }

  /// 同步还原
  static void restore() {
    if (_hwnd != 0) win32.ShowWindow(_hwnd, win32.SW_RESTORE);
  }

  /// 同步隐藏
  static void hide() {
    if (_hwnd != 0) win32.ShowWindow(_hwnd, win32.SW_HIDE);
  }

  /// 同步判断是否最大化
  static bool get isMaximized => _hwnd != 0 && _isZoomed(_hwnd) != 0;

  /// 同步切换最大化/还原
  static void toggleMaximize() {
    if (isMaximized) {
      restore();
    } else {
      maximize();
    }
  }

  /// 显示窗口并获得焦点
  static void show() {
    if (_hwnd != 0) {
      win32.ShowWindow(_hwnd, win32.SW_RESTORE);
      windowManager.focus();
    }
  }
}
