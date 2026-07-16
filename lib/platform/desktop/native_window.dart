import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win32;
import 'package:window_manager/window_manager.dart';

// win32 包没有导出部分 API，用 dart:ffi 补充
final _user32 = DynamicLibrary.open('user32.dll');
final _kernel32 = DynamicLibrary.open('kernel32.dll');

final _isZoomed = _user32
    .lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
      'IsZoomed',
    );

final _isWindow = _user32
    .lookupFunction<Int32 Function(IntPtr hWnd), int Function(int hWnd)>(
      'IsWindow',
    );

final _getWindowThreadProcessId = _user32
    .lookupFunction<
      Uint32 Function(IntPtr hWnd, Pointer<Uint32> lpdwProcessId),
      int Function(int hWnd, Pointer<Uint32> lpdwProcessId)
    >('GetWindowThreadProcessId');

final _getClassName = _user32
    .lookupFunction<
      Int32 Function(IntPtr hWnd, Pointer<Utf16> lpClassName, Int32 nMaxCount),
      int Function(int hWnd, Pointer<Utf16> lpClassName, int nMaxCount)
    >('GetClassNameW');

final _enumWindows = _user32
    .lookupFunction<
      Int32 Function(
        Pointer<NativeFunction<Int32 Function(IntPtr, IntPtr)>> lpEnumFunc,
        IntPtr lParam,
      ),
      int Function(
        Pointer<NativeFunction<Int32 Function(IntPtr, IntPtr)>> lpEnumFunc,
        int lParam,
      )
    >('EnumWindows');

final _getCurrentProcessId = _kernel32
    .lookupFunction<Uint32 Function(), int Function()>('GetCurrentProcessId');

const _flutterWindowClass = 'FLUTTER_RUNNER_WIN32_WINDOW';

/// 枚举回调：只接受属于当前进程、且类名为 Flutter 主窗口的 HWND。
/// 不能只用 FindWindowW(class, null)：所有 Flutter 应用共用同一类名，
/// 会误拿到其他进程（如 clipshare）的窗口。
int _enumWindowsProc(int hWnd, int lParam) {
  final targetPid = Pointer<Uint32>.fromAddress(lParam).value;
  final pidPtr = calloc<Uint32>();
  try {
    _getWindowThreadProcessId(hWnd, pidPtr);
    if (pidPtr.value != targetPid) {
      return 1; // continue
    }

    final className = calloc<Uint16>(256).cast<Utf16>();
    try {
      final len = _getClassName(hWnd, className, 256);
      if (len > 0 && className.toDartString() == _flutterWindowClass) {
        NativeWindow._hwnd = hWnd;
        return 0; // stop
      }
    } finally {
      calloc.free(className);
    }
  } finally {
    calloc.free(pidPtr);
  }
  return 1;
}

final _enumWindowsProcNative = NativeCallable<Int32 Function(IntPtr, IntPtr)>
    .isolateLocal(_enumWindowsProc, exceptionalReturn: 0);

/// Win32 窗口操作的同步封装，避免 method channel 延迟
class NativeWindow {
  NativeWindow._();

  static int _hwnd = 0;
  static bool _shouldMaximizeOnShow = false;
  static win32.HWND get _windowHandle => win32.HWND(Pointer.fromAddress(_hwnd));

  /// 初始化，缓存本进程窗口句柄（在 window ready 之后调用一次）
  static void init() {
    _hwnd = 0;
    final pidPtr = calloc<Uint32>();
    try {
      pidPtr.value = _getCurrentProcessId();
      _enumWindows(_enumWindowsProcNative.nativeFunction, pidPtr.address);
    } finally {
      calloc.free(pidPtr);
    }
    if (_hwnd != 0) {
      _shouldMaximizeOnShow = _isZoomed(_hwnd) != 0;
    }
  }

  static bool _belongsToCurrentProcess(int hWnd) {
    final pidPtr = calloc<Uint32>();
    try {
      _getWindowThreadProcessId(hWnd, pidPtr);
      return pidPtr.value == _getCurrentProcessId();
    } finally {
      calloc.free(pidPtr);
    }
  }

  /// 句柄失效或属于其他进程时重新查找。
  static void _ensureValidHwnd() {
    if (_hwnd != 0 &&
        _isWindow(_hwnd) != 0 &&
        _belongsToCurrentProcess(_hwnd)) {
      return;
    }
    init();
  }

  static bool get isReady {
    _ensureValidHwnd();
    return _hwnd != 0;
  }

  /// 同步最小化
  static void minimize() {
    _ensureValidHwnd();
    if (_hwnd != 0) win32.ShowWindow(_windowHandle, win32.SW_MINIMIZE);
  }

  /// 同步最大化
  static void maximize() {
    _ensureValidHwnd();
    if (_hwnd != 0) {
      _shouldMaximizeOnShow = true;
      win32.ShowWindow(_windowHandle, win32.SW_MAXIMIZE);
    }
  }

  /// 同步还原
  static void restore() {
    _ensureValidHwnd();
    if (_hwnd != 0) {
      _shouldMaximizeOnShow = false;
      win32.ShowWindow(_windowHandle, win32.SW_RESTORE);
    }
  }

  /// 同步隐藏，缓存当前最大化状态
  static void hide() {
    _ensureValidHwnd();
    if (_hwnd != 0) {
      _shouldMaximizeOnShow = _isZoomed(_hwnd) != 0;
      win32.ShowWindow(_windowHandle, win32.SW_HIDE);
    }
  }

  static void destroy() {
    _ensureValidHwnd();
    if (_hwnd != 0) win32.DestroyWindow(_windowHandle);
  }

  /// 发送关闭消息，会触发 window_manager 的 onWindowClose 回调
  static void close() {
    _ensureValidHwnd();
    if (_hwnd != 0) {
      win32.PostMessage(
        _windowHandle,
        win32.WM_CLOSE,
        win32.WPARAM(0),
        win32.LPARAM(0),
      );
    }
  }

  /// 同步判断是否最大化
  static bool get isMaximized {
    _ensureValidHwnd();
    return _hwnd != 0 && _isZoomed(_hwnd) != 0;
  }

  /// 同步切换最大化/还原（通过调用 maximize/restore 自动维护状态）
  static void toggleMaximize() {
    if (isMaximized) {
      restore();
    } else {
      maximize();
    }
  }

  /// 显示窗口并获得焦点，自动恢复隐藏前的最大化状态
  static void show() {
    _ensureValidHwnd();
    if (_hwnd != 0) {
      if (_shouldMaximizeOnShow) {
        win32.ShowWindow(_windowHandle, win32.SW_MAXIMIZE);
      } else {
        win32.ShowWindow(_windowHandle, win32.SW_RESTORE);
      }
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
