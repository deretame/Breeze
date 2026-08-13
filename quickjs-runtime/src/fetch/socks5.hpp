// SOCKS5 代理：握手 / 隧道建立（设计文档 §3.4）
#pragma once

#include <fetch/task.hpp>
#include <fetch/transport.hpp>
#include <fetch/dns_resolver.hpp>

#include <boost/asio/ip/tcp.hpp>
#include <stdexec/execution.hpp>

#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <string_view>

namespace fetch {

// Socks5Proxy 类型定义见 fetch/transport.hpp（纯值类型）

// 建立经 SOCKS5 到目标的 TCP 隧道：greeting（方法协商）→（可选）RFC 1929 子协商
// → CONNECT（ATYP = 域名 / IPv4 / IPv6）→ 校验 REP=0x00。
// 失败抛 boost::system::system_error（含 REP 错误码，category=socks5）。
// 目标地址：IP 字面量 → 对应 ATYP；域名 → ATYP=0x03 交给代理解析。
// 注意：仅"解析代理地址"一步走 resolver（目标 host 仍由代理远端解析，§1.3）。
// 取消：stop_token 注册期间 socket cancel()（connect/握手阶段可取消 → stopped；
// resolve 阶段的取消由 DnsResolver 实现内化，见 dns_resolver.hpp）。
// 超时：TCP 连接建立后的握手全程 30s 上限，超时抛 errc::timed_out。
// 注：返回 shared_ptr——与 BeastBodySource / stop_callback 的 shared_ptr
//    生命周期模型一致（隧道 socket 移交 body 阶段继续用）。
std_exec::task<std::shared_ptr<boost::asio::ip::tcp::socket>>
socks5_connect(boost::asio::io_context& io, const Socks5Proxy& proxy,
               std::string_view target_host, uint16_t target_port, std::stop_token st,
               const std::shared_ptr<DnsResolver>& resolver);

} // namespace fetch
