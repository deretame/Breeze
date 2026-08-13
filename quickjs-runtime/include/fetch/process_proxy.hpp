// fetchcore —— 进程级代理配置与系统代理自动监听
//
// 代理优先级（高 → 低）：
//   1. 请求级：Request::proxy（每次请求配置，见 types.hpp）
//   2. 实例级：Options::proxy（Client 创建时配置）
//   3. 进程级（本模块，再分两档）：
//      a. 手动配置（set_process_proxy，http/socks5 均可）
//      b. 系统自动读取（Windows 注册表监听写入；仅 http 代理；
//         未手动配置过时才生效）
//
// 手动标记（has_manual_proxy）：set_process_proxy / clear_process_proxy 调用后
// 置位；置位期间系统代理监听检测到变化会跳过自动更新（避免覆盖用户手动选择）。
// 调用 clear_manual_proxy() 清除标记并恢复跟随系统。
#pragma once

#include <fetch/types.hpp>
#include <fetch/transport.hpp> // HttpProxy（系统自动代理槽用）

#include <optional>

namespace fetch {

// ---- 进程级手动代理 ----
// 设置进程级代理（http/socks5 均可）；置位手动标记。
void set_process_proxy(std::optional<Proxy> proxy);
// 当前进程级手动代理（未配置 → nullopt）
std::optional<Proxy> process_proxy();
// 是否手动配置过代理（置位后系统自动更新被跳过）
bool has_manual_proxy();
// 清除手动配置与标记（恢复跟随系统自动代理）
void clear_manual_proxy();

// ---- 系统自动代理（仅 http）----
// 由系统代理监听（start_system_proxy_watch）写入；仅当未手动配置过时生效。
void set_system_proxy(std::optional<HttpProxy> proxy);
std::optional<HttpProxy> system_proxy();

// 生效的进程级代理：手动配置优先，否则系统自动（仅 http）；均无 → nullopt
std::optional<Proxy> effective_process_proxy();

// ---- 系统代理监听（平台相关）----
// Windows：监听 HKCU\...\Internet Settings 的 LAST_SET 变化（RegNotifyChangeKeyValue），
//   变化时读取 ProxyEnable/ProxyServer 并写入 set_system_proxy（仅 http 段）。
// macOS：占位（后续用 scutil/SCDynamicStoreCopyProxies 实现）。
// 其他平台：no-op。
// start 幂等（重复调用无副作用）；进程退出前应 stop 回收监听线程。
void start_system_proxy_watch();
void stop_system_proxy_watch();

#ifdef _WIN32
// 解析 Windows ProxyServer 注册表值 → http 代理（自动获取仅做 http，忽略
// socks= 段；"http=a;https=b" 多协议形式取 http 段；失败 → nullopt）。
// 供监听线程与单元测试使用。
std::optional<HttpProxy> parse_windows_proxy_server(const std::wstring& value);
#endif

} // namespace fetch
