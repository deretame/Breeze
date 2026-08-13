// fetchcore —— 进程级代理全局状态 + 系统代理监听（Windows 实现 / macOS 占位）
#include <fetch/process_proxy.hpp>

#include <mutex>
#include <optional>
#include <string>
#include <string_view>
#include <thread>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

namespace fetch {
namespace {

std::mutex g_mu;
std::optional<Proxy> g_manual;      // 进程级手动代理
bool g_manual_flag = false;         // 手动配置过（含手动清除）
std::optional<HttpProxy> g_system;  // 系统自动代理（仅 http）

#ifdef _WIN32
// 监听生命周期锁：保护 g_watch_* 全局（创建/join/清理串行化）。
// 注意：watch_loop 从不取此锁（只短暂取 g_mu），stop 持锁 join 不会死锁。
std::mutex g_watch_mu;
// Windows 监听线程状态（stop 时 join 后再关闭句柄，无并发竞争）
std::thread g_watch_thread;
HANDLE g_stop_evt = nullptr; // manual-reset：停止信号
HANDLE g_reg_evt = nullptr;  // auto-reset：注册表变化
HKEY g_reg_key = nullptr;
bool g_watch_running = false;
#endif

} // namespace

// 内部：重新读取系统代理并写入（Windows 实现；非 Windows no-op）。
// 供 clear_manual_proxy 恢复"跟随系统"时立即刷新，避免提供过期值。
void refresh_system_proxy();

void set_process_proxy(std::optional<Proxy> proxy)
{
    std::lock_guard lk(g_mu);
    g_manual = std::move(proxy);
    g_manual_flag = true;
}

std::optional<Proxy> process_proxy()
{
    std::lock_guard lk(g_mu);
    return g_manual;
}

bool has_manual_proxy()
{
    std::lock_guard lk(g_mu);
    return g_manual_flag;
}

void clear_manual_proxy()
{
    {
        std::lock_guard lk(g_mu);
        g_manual.reset();
        g_manual_flag = false;
    }
    // 恢复跟随系统：立即重新读取一次系统代理（避免继续提供过期值）
    refresh_system_proxy();
}

void set_system_proxy(std::optional<HttpProxy> proxy)
{
    std::lock_guard lk(g_mu);
    if (g_manual_flag)
        return; // 手动配置过 → 跳过系统自动更新
    g_system = std::move(proxy);
}

std::optional<HttpProxy> system_proxy()
{
    std::lock_guard lk(g_mu);
    return g_system;
}

std::optional<Proxy> effective_process_proxy()
{
    std::lock_guard lk(g_mu);
    if (g_manual)
        return g_manual;
    if (g_system) {
        Proxy p;
        p.kind = Proxy::Kind::Http; // 系统自动仅 http
        p.host = g_system->host;
        p.port = g_system->port;
        p.auth = g_system->auth;
        return p;
    }
    return std::nullopt;
}

#ifdef _WIN32

namespace {

const wchar_t* kInternetSettings =
    L"Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings";

// ProxyServer 值只含 ASCII（host:port）；宽→窄直接窄化，含非 ASCII → 解析失败
std::optional<std::string> to_ascii(const std::wstring& ws)
{
    std::string out;
    out.reserve(ws.size());
    for (wchar_t c : ws) {
        if (c > 0x7F)
            return std::nullopt;
        out.push_back(static_cast<char>(c));
    }
    return out;
}

} // namespace

// 解析 Windows 的 ProxyServer 值 → http 代理（自动获取仅做 http，忽略 socks 段）：
//   "host:port"                                → http 代理
//   "http=host:port;https=host:port"           → 取 http 段
//   "socks=host:port"                          → 无 http 段 → nullopt（不用代理）
//   IPv6 形如 "[::1]:8080"。解析失败 → nullopt。
std::optional<HttpProxy> parse_windows_proxy_server(const std::wstring& value)
{
    auto ascii = to_ascii(value);
    if (!ascii || ascii->empty())
        return std::nullopt;

    std::string http_part;
    if (ascii->find('=') != std::string::npos) {
        // 多协议形式：逐段找 "http="（协议名大小写不敏感）
        std::string_view v = *ascii;
        size_t pos = 0;
        for (;;) {
            const size_t semi = v.find(';', pos);
            std::string_view item =
                v.substr(pos, semi == std::string_view::npos ? std::string_view::npos : semi - pos);
            const size_t eq = item.find('=');
            if (eq != std::string_view::npos) {
                std::string_view proto = item.substr(0, eq);
                bool is_http = proto.size() == 4 &&
                               (proto[0] | 32) == 'h' && (proto[1] | 32) == 't' &&
                               (proto[2] | 32) == 't' && (proto[3] | 32) == 'p';
                if (is_http) {
                    http_part.assign(item.substr(eq + 1));
                    break;
                }
            }
            if (semi == std::string_view::npos)
                break;
            pos = semi + 1;
        }
        if (http_part.empty())
            return std::nullopt; // 只有 socks= 等段 → 自动获取不用代理
    } else {
        http_part = *ascii;
    }

    // 解析 host[:port]（端口缺失用 8080；IPv6 带方括号）
    HttpProxy p;
    std::string_view s = http_part;
    const uint16_t def_port = 8080;
    if (s.empty())
        return std::nullopt;
    if (s.front() == '[') {
        const size_t close = s.find(']');
        if (close == std::string_view::npos)
            return std::nullopt;
        p.host.assign(s.substr(1, close - 1));
        s.remove_prefix(close + 1);
        if (s.empty()) {
            p.port = def_port;
            return p;
        }
        if (s.front() != ':')
            return std::nullopt;
        s.remove_prefix(1);
    } else {
        const size_t pc = s.rfind(':');
        if (pc == std::string_view::npos) {
            p.host.assign(s);
            p.port = def_port;
            return p;
        }
        p.host.assign(s.substr(0, pc));
        s.remove_prefix(pc + 1);
    }
    // 剩余必须是纯数字端口（1-65535）
    if (s.empty())
        return std::nullopt;
    unsigned long v = 0;
    for (char c : s) {
        if (c < '0' || c > '9')
            return std::nullopt;
        v = v * 10 + static_cast<unsigned long>(c - '0');
        if (v > 65535)
            return std::nullopt;
    }
    if (v == 0 || p.host.empty())
        return std::nullopt;
    p.port = static_cast<uint16_t>(v);
    return p;
}

// 读取当前系统代理状态 → set_system_proxy
void read_and_apply_system_proxy(HKEY hKey)
{
    DWORD enable = 0;
    DWORD size = sizeof(enable);
    if (RegQueryValueExW(hKey, L"ProxyEnable", nullptr, nullptr,
                         reinterpret_cast<LPBYTE>(&enable), &size) != ERROR_SUCCESS ||
        enable != 1) {
        set_system_proxy(std::nullopt); // 未开启/读取失败 → 无系统代理
        return;
    }
    DWORD vsize = 0;
    if (RegQueryValueExW(hKey, L"ProxyServer", nullptr, nullptr, nullptr, &vsize) !=
            ERROR_SUCCESS ||
        vsize == 0) {
        set_system_proxy(std::nullopt);
        return;
    }
    std::wstring val(vsize / sizeof(wchar_t), L'\0');
    if (RegQueryValueExW(hKey, L"ProxyServer", nullptr, nullptr,
                         reinterpret_cast<LPBYTE>(val.data()), &vsize) != ERROR_SUCCESS) {
        return;
    }
    if (!val.empty() && val.back() == L'\0')
        val.pop_back();
    set_system_proxy(parse_windows_proxy_server(val));
}

void watch_loop()
{
    // 启动即读取一次初始状态（进程启动时系统代理可能已开启）
    read_and_apply_system_proxy(g_reg_key);
    for (;;) {
        const LONG r = RegNotifyChangeKeyValue(g_reg_key, FALSE /* 不递归 */,
                                               REG_NOTIFY_CHANGE_LAST_SET, g_reg_evt, TRUE);
        if (r != ERROR_SUCCESS)
            break; // 监听失败（键被删等）→ 退出线程
        const HANDLE hs[2] = {g_reg_evt, g_stop_evt};
        const DWORD wr = WaitForMultipleObjects(2, hs, FALSE, INFINITE);
        if (wr == WAIT_OBJECT_0 + 1 || wr == WAIT_FAILED)
            break; // 停止信号
        if (wr == WAIT_OBJECT_0)
            read_and_apply_system_proxy(g_reg_key);
    }
}

// 重新读取一次系统代理并写入（监听线程未运行时 no-op）。
// 供 clear_manual_proxy 恢复"跟随系统"时立即刷新，避免提供过期值。
void refresh_system_proxy()
{
    std::lock_guard lk(g_watch_mu);
    if (g_reg_key)
        read_and_apply_system_proxy(g_reg_key);
}

void start_system_proxy_watch()
{
    std::lock_guard lk(g_watch_mu);
    if (g_watch_running)
        return; // 幂等：已在监听
    g_stop_evt = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    g_reg_evt = CreateEventW(nullptr, FALSE, FALSE, nullptr);
    if (!g_stop_evt || !g_reg_evt) {
        // 事件创建失败（资源耗尽等）：放弃监听
        if (g_stop_evt)
            CloseHandle(g_stop_evt);
        if (g_reg_evt)
            CloseHandle(g_reg_evt);
        g_stop_evt = nullptr;
        g_reg_evt = nullptr;
        return;
    }
    const LONG r = RegOpenKeyExW(HKEY_CURRENT_USER, kInternetSettings, 0,
                                 KEY_NOTIFY | KEY_READ, &g_reg_key);
    if (r != ERROR_SUCCESS) {
        // 无法打开键（权限/注册表不可用）：放弃监听，复位状态
        CloseHandle(g_stop_evt);
        CloseHandle(g_reg_evt);
        g_stop_evt = nullptr;
        g_reg_evt = nullptr;
        return;
    }
    g_watch_running = true;
    try {
        g_watch_thread = std::thread(watch_loop);
    } catch (...) {
        // 线程创建失败（资源耗尽等）：复位状态并清理，放弃监听
        g_watch_running = false;
        RegCloseKey(g_reg_key);
        CloseHandle(g_stop_evt);
        CloseHandle(g_reg_evt);
        g_reg_key = nullptr;
        g_stop_evt = nullptr;
        g_reg_evt = nullptr;
    }
}

void stop_system_proxy_watch()
{
    // 持 watch_mu join：watch_loop 从不取此锁（只短暂取 g_mu），不会死锁；
    // start/stop 因此完全串行，杜绝 start-during-join / stop-during-start 竞态。
    std::lock_guard lk(g_watch_mu);
    if (!g_watch_running)
        return;
    g_watch_running = false;
    if (g_stop_evt)
        SetEvent(g_stop_evt);
    if (g_watch_thread.joinable())
        g_watch_thread.join();
    if (g_reg_key) {
        RegCloseKey(g_reg_key);
        g_reg_key = nullptr;
    }
    if (g_stop_evt) {
        CloseHandle(g_stop_evt);
        g_stop_evt = nullptr;
    }
    if (g_reg_evt) {
        CloseHandle(g_reg_evt);
        g_reg_evt = nullptr;
    }
}

#else // 非 Windows（macOS 占位 / 其他平台 no-op）

void refresh_system_proxy() {}

void start_system_proxy_watch()
{
    // TODO(macOS): 用 scutil --stream 或 SCDynamicStoreCopyProxies 监听系统代理，
    // 变化时读取 http 段并经 set_system_proxy 写入（仅 http；语义与 Windows 一致）。
    // 其他平台无需系统代理自动获取。
}

void stop_system_proxy_watch() {}

#endif

} // namespace fetch
