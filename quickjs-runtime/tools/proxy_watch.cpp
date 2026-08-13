// proxy_watch.cpp — Windows 系统代理变化监听（实验用独立小工具）
//
// 监听 HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings
// 的 LAST_SET 通知（RegNotifyChangeKeyValue），变化时打印新的代理状态。
//
// 编译（MSVC x64 环境）:
//   cl /nologo /std:c++20 /EHsc /utf-8 /O2 tools\proxy_watch.cpp /Fe:build\proxy_watch.exe advapi32.lib
//
// 运行:
//   build\proxy_watch.exe

#include <windows.h>

#include <cstdio>
#include <string>

static const wchar_t* kInternetSettings =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings";

static bool read_dword(HKEY hKey, const wchar_t* name, DWORD& out) {
    DWORD size = sizeof(DWORD);
    return RegQueryValueExW(hKey, name, nullptr, nullptr,
                            reinterpret_cast<LPBYTE>(&out), &size) == ERROR_SUCCESS;
}

static std::wstring read_string(HKEY hKey, const wchar_t* name) {
    DWORD size = 0;
    if (RegQueryValueExW(hKey, name, nullptr, nullptr, nullptr, &size) != ERROR_SUCCESS ||
        size == 0) {
        return L"";
    }
    std::wstring buf(size / sizeof(wchar_t), L'\0');
    DWORD type = 0;
    if (RegQueryValueExW(hKey, name, nullptr, &type,
                         reinterpret_cast<LPBYTE>(buf.data()), &size) != ERROR_SUCCESS) {
        return L"";
    }
    if (!buf.empty() && buf.back() == L'\0') {
        buf.pop_back();
    }
    return buf;
}

static std::string utf8_of(const std::wstring& ws) {
    if (ws.empty()) {
        return "";
    }
    int n = WideCharToMultiByte(CP_UTF8, 0, ws.c_str(), (int)ws.size(), nullptr, 0, nullptr, nullptr);
    std::string out(n, '\0');
    WideCharToMultiByte(CP_UTF8, 0, ws.c_str(), (int)ws.size(), out.data(), n, nullptr, nullptr);
    return out;
}

static void print_proxy_state(HKEY hKey, const char* tag) {
    DWORD enable = 0;
    read_dword(hKey, L"ProxyEnable", enable);
    std::string server = utf8_of(read_string(hKey, L"ProxyServer"));
    std::string auto_url = utf8_of(read_string(hKey, L"AutoConfigURL"));

    SYSTEMTIME st;
    GetLocalTime(&st);
    printf("[%02u:%02u:%02u.%03u] %s: ProxyEnable=%u  ProxyServer=\"%s\"  AutoConfigURL=\"%s\"\n",
           st.wHour, st.wMinute, st.wSecond, st.wMilliseconds, tag, enable,
           server.c_str(), auto_url.c_str());
    fflush(stdout);
}

static HANDLE g_exit_evt = nullptr;

static BOOL WINAPI on_ctrl(DWORD type) {
    if (type == CTRL_C_EVENT || type == CTRL_BREAK_EVENT || type == CTRL_CLOSE_EVENT) {
        if (g_exit_evt) {
            SetEvent(g_exit_evt);  // Ctrl+C 处理里 SetEvent 是安全的
        }
        return TRUE;
    }
    return FALSE;
}

int wmain() {
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCtrlHandler(on_ctrl, TRUE);

    HKEY hKey = nullptr;
    LONG r = RegOpenKeyExW(HKEY_CURRENT_USER, kInternetSettings, 0,
                           KEY_NOTIFY | KEY_READ, &hKey);
    if (r != ERROR_SUCCESS) {
        printf("RegOpenKeyExW failed: %ld (0x%lX)\n", r, r);
        return 1;
    }

    HANDLE change_evt = CreateEventW(nullptr, FALSE /* auto-reset */, FALSE, nullptr);
    g_exit_evt = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    if (!change_evt || !g_exit_evt) {
        printf("CreateEventW failed\n");
        return 1;
    }

    print_proxy_state(hKey, "初始状态");

    HANDLE handles[2] = {change_evt, g_exit_evt};

    for (;;) {
        r = RegNotifyChangeKeyValue(hKey, FALSE /* 只监听本键，不递归 */,
                                    REG_NOTIFY_CHANGE_LAST_SET, change_evt, TRUE);
        if (r != ERROR_SUCCESS) {
            printf("RegNotifyChangeKeyValue failed: %ld (0x%lX)\n", r, r);
            break;
        }

        DWORD wr = WaitForMultipleObjects(2, handles, FALSE, INFINITE);
        if (wr == WAIT_OBJECT_0 + 1) {
            break;  // Ctrl+C 退出
        }
        if (wr != WAIT_OBJECT_0) {
            printf("WaitForMultipleObjects failed: %lu\n", wr);
            break;
        }
        print_proxy_state(hKey, "检测到变化");
    }

    CloseHandle(change_evt);
    CloseHandle(g_exit_evt);
    RegCloseKey(hKey);
    printf("退出。\n");
    return 0;
}
