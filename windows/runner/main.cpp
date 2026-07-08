#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Check whether the window rectangle is at least partially visible
// on any monitor. Uses the rectangle center point for simplicity.
bool IsWindowRectOnScreen(const RECT& rect) {
  LONG cx = (rect.left + rect.right) / 2;
  LONG cy = (rect.top + rect.bottom) / 2;
  POINT pt = {cx, cy};
  return ::MonitorFromPoint(pt, MONITOR_DEFAULTTONULL) != nullptr;
}

// Aggressively restore an existing window. This is used when the user
// launches a second instance: we find the first instance's window and
// force it back into the visible area, clearing any stale minimized or
// off-screen state that a plain ShowWindow(SW_RESTORE) cannot recover.
void RestoreExistingWindow(HWND hwnd) {
  if (!::IsWindow(hwnd)) {
    return;
  }

  // Clear minimize/maximize styles and force the visible flag.
  LONG style = ::GetWindowLong(hwnd, GWL_STYLE);
  style &= ~(WS_MINIMIZE | WS_MAXIMIZE);
  style |= WS_VISIBLE;
  ::SetWindowLong(hwnd, GWL_STYLE, style);

  // Ask Windows to recompute the frame based on the updated styles.
  ::SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                 SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER |
                     SWP_FRAMECHANGED | SWP_SHOWWINDOW);

  // If the window is outside all monitors, move it to the primary monitor.
  RECT rect{};
  ::GetWindowRect(hwnd, &rect);
  if (!IsWindowRectOnScreen(rect)) {
    HMONITOR primary = ::MonitorFromWindow(hwnd, MONITOR_DEFAULTTOPRIMARY);
    MONITORINFO info = {sizeof(info)};
    if (::GetMonitorInfo(primary, &info)) {
      LONG work_width = info.rcWork.right - info.rcWork.left;
      LONG work_height = info.rcWork.bottom - info.rcWork.top;
      LONG win_width = rect.right - rect.left;
      LONG win_height = rect.bottom - rect.top;
      if (win_width < 200) win_width = 1280;
      if (win_height < 100) win_height = 720;
      LONG x = info.rcWork.left + (work_width - win_width) / 2;
      LONG y = info.rcWork.top + (work_height - win_height) / 2;
      ::SetWindowPos(hwnd, HWND_TOP, x, y, win_width, win_height,
                     SWP_SHOWWINDOW);
    }
  }

  // Show normally and activate.
  ::ShowWindow(hwnd, SW_SHOWNORMAL);
  ::SetForegroundWindow(hwnd);
  ::BringWindowToTop(hwnd);
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t* command_line, _In_ int show_command) {
  HWND hwnd = ::FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"zephyr");
  if (hwnd != NULL) {
    RestoreExistingWindow(hwnd);
    return EXIT_FAILURE;
  }
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments = GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"zephyr", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
