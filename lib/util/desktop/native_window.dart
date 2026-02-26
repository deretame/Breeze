import 'dart:ffi';
import 'dart:io';

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

  static void destroy() {
    if (_hwnd != 0) win32.DestroyWindow(_hwnd);
  }

  /// 发送关闭消息，会触发 window_manager 的 onWindowClose 回调
  static void close() {
    if (_hwnd != 0) {
      win32.PostMessage(_hwnd, win32.WM_CLOSE, 0, 0);
    }
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

/// 强制终止进程
void hardKillProcess() {
  if (Platform.isWindows) {
    // Windows: 调用 kernel32.dll 的 ExitProcess
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    final void Function(int) exitProcess = kernel32
        .lookup<NativeFunction<Void Function(Uint32)>>('ExitProcess')
        .asFunction();
    exitProcess(0);
  } else if (Platform.isMacOS || Platform.isLinux) {
    // macOS/Linux: 调用 C 标准库的 _exit
    final dylib = Platform.isMacOS
        ? DynamicLibrary.process()
        : DynamicLibrary.open('libc.so.6');
    final void Function(int) cExit = dylib
        .lookup<NativeFunction<Void Function(Int32)>>('_exit')
        .asFunction();
    cExit(0);
  } else {
    // 兜底方案
    exit(0);
  }
}

// 强杀，不管任何回收的操作
void nuclearKillProcess() {
  if (Platform.isWindows) {
    // Windows: TerminateProcess(GetCurrentProcess(), 0)
    final kernel32 = DynamicLibrary.open('kernel32.dll');

    // 获取当前进程伪句柄 (-1)
    final getCurrentProcess = kernel32
        .lookup<NativeFunction<IntPtr Function()>>('GetCurrentProcess')
        .asFunction<int Function()>();

    final terminateProcess = kernel32
        .lookup<NativeFunction<Int32 Function(IntPtr, Uint32)>>(
          'TerminateProcess',
        )
        .asFunction<int Function(int, int)>();

    terminateProcess(getCurrentProcess(), 0);
  } else if (Platform.isMacOS || Platform.isLinux) {
    // Unix: kill(getpid(), 9)
    final dylib = Platform.isMacOS
        ? DynamicLibrary.process()
        : DynamicLibrary.open('libc.so.6');

    final getpid = dylib
        .lookup<NativeFunction<Int32 Function()>>('getpid')
        .asFunction<int Function()>();

    final kill = dylib
        .lookup<NativeFunction<Int32 Function(Int32, Int32)>>('kill')
        .asFunction<int Function(int, int)>();

    kill(getpid(), 9); // 9 就是 SIGKILL
  } else {
    exit(0);
  }
}
